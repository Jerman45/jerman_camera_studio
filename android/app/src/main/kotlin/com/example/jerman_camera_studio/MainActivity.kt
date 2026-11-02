package com.example.jerman_camera_studio

import android.media.MediaExtractor
import android.media.MediaCodec
import android.media.MediaFormat
import android.media.MediaMuxer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.nio.ByteBuffer

class MainActivity : FlutterActivity() {
    private val mediaChannelName = "jerman.camera/media"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            mediaChannelName,
        ).setMethodCallHandler { call, result ->
            if (call.method != "trimVideo") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val sourcePath = call.argument<String>("path")
            val startMs = call.argument<Number>("startMs")?.toLong()
            val endMs = call.argument<Number>("endMs")?.toLong()
            if (sourcePath == null || startMs == null || endMs == null || startMs < 0 || endMs <= startMs) {
                result.error("invalid_arguments", "A valid source and trim range are required.", null)
                return@setMethodCallHandler
            }

            Thread {
                try {
                    val output = trimVideo(sourcePath, startMs * 1000, endMs * 1000)
                    runOnUiThread { result.success(output.absolutePath) }
                } catch (error: Exception) {
                    runOnUiThread {
                        result.error("video_export_failed", error.message, null)
                    }
                }
            }.start()
        }
    }

    private fun trimVideo(sourcePath: String, startUs: Long, endUs: Long): File {
        val source = File(sourcePath)
        require(source.isFile) { "The source video could not be found." }

        val output = File(cacheDir, "studio-${System.nanoTime()}.mp4")
        val extractor = MediaExtractor()
        var muxer: MediaMuxer? = null
        try {
            extractor.setDataSource(source.absolutePath)
            val trackMap = mutableMapOf<Int, Int>()
            var videoTrack = -1
            var rotation = 0
            var bufferCapacity = 4 * 1024 * 1024
            for (index in 0 until extractor.trackCount) {
                val format = extractor.getTrackFormat(index)
                val mime = format.getString(MediaFormat.KEY_MIME) ?: continue
                if (!mime.startsWith("video/") && !mime.startsWith("audio/")) continue
                if (format.containsKey(MediaFormat.KEY_MAX_INPUT_SIZE)) {
                    bufferCapacity = maxOf(
                        bufferCapacity,
                        format.getInteger(MediaFormat.KEY_MAX_INPUT_SIZE),
                    )
                }
                val outputTrack = trackMap[index]
                    ?: run {
                        val muxerInstance = muxer ?: MediaMuxer(
                            output.absolutePath,
                            MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4,
                        ).also { muxer = it }
                        muxerInstance.addTrack(format).also { trackMap[index] = it }
                    }
                if (mime.startsWith("video/") && videoTrack == -1) {
                    videoTrack = index
                    if (format.containsKey(MediaFormat.KEY_ROTATION)) {
                        rotation = format.getInteger(MediaFormat.KEY_ROTATION)
                    }
                }
                extractor.selectTrack(index)
            }
            require(videoTrack != -1) { "The selected file has no video track." }
            require(bufferCapacity <= 64 * 1024 * 1024) {
                "The source video requires an unsupported media buffer size."
            }
            val outputMuxer = muxer ?: error("No supported media tracks were found.")
            if (rotation != 0) outputMuxer.setOrientationHint(rotation)

            extractor.seekTo(startUs, MediaExtractor.SEEK_TO_PREVIOUS_SYNC)
            var keyframeUs = -1L
            while (extractor.sampleTrackIndex != -1) {
                if (
                    extractor.sampleTrackIndex == videoTrack &&
                    extractor.sampleTime >= 0 &&
                    extractor.sampleFlags and MediaExtractor.SAMPLE_FLAG_SYNC != 0
                ) {
                    keyframeUs = extractor.sampleTime
                    break
                }
                if (!extractor.advance()) break
            }
            require(keyframeUs >= 0 && keyframeUs < endUs) {
                "No video frames are available in the selected trim range."
            }

            extractor.seekTo(keyframeUs, MediaExtractor.SEEK_TO_PREVIOUS_SYNC)
            outputMuxer.start()
            val buffer = ByteBuffer.allocate(bufferCapacity)
            val bufferInfo = MediaCodec.BufferInfo()
            while (extractor.sampleTrackIndex != -1) {
                val sampleTime = extractor.sampleTime
                if (sampleTime >= endUs) break
                val inputTrack = extractor.sampleTrackIndex
                val outputTrack = trackMap[inputTrack]
                if (sampleTime >= keyframeUs && outputTrack != null) {
                    buffer.clear()
                    val sampleSize = extractor.readSampleData(buffer, 0)
                    if (sampleSize < 0) break
                    bufferInfo.set(
                        0,
                        sampleSize,
                        sampleTime - keyframeUs,
                        extractor.sampleFlags,
                    )
                    outputMuxer.writeSampleData(outputTrack, buffer, bufferInfo)
                }
                if (!extractor.advance()) break
            }
            outputMuxer.stop()
            require(output.length() > 0) { "The selected range produced no video." }
            return output
        } catch (error: Exception) {
            output.delete()
            throw error
        } finally {
            try {
                muxer?.release()
            } finally {
                extractor.release()
            }
        }
    }
}
