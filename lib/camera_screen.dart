import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';

import 'media_library.dart';
import 'photo_processing.dart';

const _background = Color(0xFF030704);
const _panel = Color(0xFF101A12);
const _accent = Color(0xFF00E85A);

enum CameraCaptureMode { photo, video }

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({
    super.key,
    required this.initialMode,
    required this.onCaptureSaved,
  });

  final CameraCaptureMode initialMode;
  final ValueChanged<StudioMedia> onCaptureSaved;

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  CameraDescription? _camera;
  String? _cameraError;
  String? _lastCapturePath;
  bool _isLoading = true;
  bool _isBusy = false;
  bool _showGrid = false;
  bool _showPortraitGuide = false;
  bool _isRecording = false;
  StudioCaptureSettings _captureSettings = const StudioCaptureSettings();
  late CameraCaptureMode _mode = widget.initialMode;
  FlashMode _flashMode = FlashMode.off;
  double _minZoom = 1;
  double _maxZoom = 1;
  double _zoom = 1;
  double _minExposure = 0;
  double _maxExposure = 0;
  double _exposure = 0;
  Offset? _focusPoint;
  Timer? _focusIndicatorTimer;
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;
  int _initializationToken = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initializeCamera());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusIndicatorTimer?.cancel();
    _recordingTimer?.cancel();
    unawaited(_controller?.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _initializationToken++;
      final controller = _controller;
      _controller = null;
      if (mounted) {
        setState(() => _isLoading = false);
      }
      unawaited(controller?.dispose());
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      unawaited(_initializeCamera(preferredCamera: _camera));
    }
  }

  Future<void> _initializeCamera({CameraDescription? preferredCamera}) async {
    final token = ++_initializationToken;
    final oldController = _controller;
    _controller = null;
    await oldController?.dispose();
    if (!mounted || token != _initializationToken) return;

    setState(() {
      _isLoading = true;
      _cameraError = null;
    });

    CameraController? candidate;
    try {
      final settings = await MediaLibrary.loadSettings();
      if (!mounted || token != _initializationToken) return;
      _captureSettings = settings;
      setState(() => _showGrid = settings.showCompositionGrid);

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw StateError('No cameras were found on this device.');
      }
      final selectedCamera =
          preferredCamera != null &&
              cameras.any((camera) => camera.name == preferredCamera.name)
          ? cameras.firstWhere((camera) => camera.name == preferredCamera.name)
          : cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.back,
              orElse: () => cameras.first,
            );
      final resolution = settings.resolution == 'High'
          ? ResolutionPreset.high
          : ResolutionPreset.max;
      final fps = settings.framesPerSecond == 60 ? 60 : null;
      var activeController = CameraController(
        selectedCamera,
        resolution,
        enableAudio: true,
        fps: fps,
      );
      candidate = activeController;
      try {
        await activeController.initialize();
      } on CameraException {
        if (fps == null) rethrow;
        await activeController.dispose();
        activeController = CameraController(
          selectedCamera,
          resolution,
          enableAudio: true,
        );
        candidate = activeController;
        await activeController.initialize();
      }
      final minZoom = await activeController.getMinZoomLevel();
      final maxZoom = await activeController.getMaxZoomLevel();
      final minExposure = await activeController.getMinExposureOffset();
      final maxExposure = await activeController.getMaxExposureOffset();

      if (!mounted || token != _initializationToken) {
        await candidate.dispose();
        return;
      }

      _controller = activeController;
      _camera = selectedCamera;
      setState(() {
        _minZoom = minZoom;
        _maxZoom = maxZoom;
        _zoom = 1.clamp(minZoom, maxZoom).toDouble();
        _minExposure = minExposure;
        _maxExposure = maxExposure;
        _exposure = 0.clamp(minExposure, maxExposure).toDouble();
        _isLoading = false;
      });
    } on CameraException catch (error) {
      await candidate?.dispose();
      _setCameraError(_cameraExceptionMessage(error));
    } catch (error) {
      await candidate?.dispose();
      _setCameraError('Camera unavailable: $error');
    }
  }

  void _setCameraError(String message) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _cameraError = message;
    });
  }

  String _cameraExceptionMessage(CameraException error) {
    switch (error.code) {
      case 'CameraAccessDenied':
        return 'Camera permission is needed to use the live preview.';
      case 'AudioAccessDenied':
        return 'Microphone permission is needed to record video with sound.';
      default:
        return error.description == null
            ? 'Camera error: ${error.code}'
            : 'Camera error: ${error.description}';
    }
  }

  Future<void> _switchCamera() async {
    if (_isBusy || _isRecording) return;
    final cameras = await availableCameras();
    final nextDirection = _camera?.lensDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    final matchingCameras = cameras
        .where((camera) => camera.lensDirection == nextDirection)
        .toList();
    if (matchingCameras.isEmpty) {
      _showMessage(
        nextDirection == CameraLensDirection.front
            ? 'A front camera is not available on this device.'
            : 'A rear camera is not available on this device.',
      );
      return;
    }
    await _initializeCamera(preferredCamera: matchingCameras.first);
  }

  Future<void> _cycleFlashMode() async {
    final nextMode = switch (_flashMode) {
      FlashMode.off => FlashMode.auto,
      FlashMode.auto => FlashMode.always,
      _ => FlashMode.off,
    };
    await _performCameraAction(() async {
      await _controller!.setFlashMode(nextMode);
      if (mounted) setState(() => _flashMode = nextMode);
    });
  }

  Future<void> _focusAt(TapDownDetails details, Size size) async {
    final point = Offset(
      (details.localPosition.dx / size.width).clamp(0, 1),
      (details.localPosition.dy / size.height).clamp(0, 1),
    );
    setState(() => _focusPoint = point);
    _focusIndicatorTimer?.cancel();
    _focusIndicatorTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _focusPoint = null);
    });

    await _performCameraAction(() async {
      final controller = _controller!;
      await controller.setFocusMode(FocusMode.auto);
      await controller.setFocusPoint(point);
      await controller.setExposureMode(ExposureMode.auto);
      await controller.setExposurePoint(point);
    });
  }

  Future<void> _performCameraAction(Future<void> Function() action) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      await action();
    } on CameraException catch (error) {
      _showMessage(_cameraExceptionMessage(error));
    } catch (error) {
      _showMessage('Camera action failed: $error');
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _isBusy || !controller.value.isInitialized) {
      return;
    }
    if (_isRecording) {
      await _stopRecording(controller);
      return;
    }
    if (_mode == CameraCaptureMode.video) {
      await _startRecording(controller);
      return;
    }

    setState(() => _isBusy = true);
    try {
      final image = await controller.takePicture();
      await _saveCapture(image.path, isVideo: false);
    } on CameraException catch (error) {
      _showMessage(_cameraExceptionMessage(error));
    } catch (error) {
      _showMessage('Photo could not be saved: $error');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _startRecording(CameraController controller) async {
    setState(() {
      _isBusy = true;
      _recordingDuration = Duration.zero;
    });
    try {
      await controller.startVideoRecording();
      if (!mounted) return;
      setState(() {
        _isRecording = true;
        _isBusy = false;
      });
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() => _recordingDuration += const Duration(seconds: 1));
        }
      });
    } on CameraException catch (error) {
      _showMessage(_cameraExceptionMessage(error));
      if (mounted) setState(() => _isBusy = false);
    } catch (error) {
      _showMessage('Video recording could not start: $error');
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _stopRecording(CameraController controller) async {
    setState(() => _isBusy = true);
    _recordingTimer?.cancel();
    try {
      final video = await controller.stopVideoRecording();
      if (mounted) setState(() => _isRecording = false);
      await _saveCapture(video.path, isVideo: true);
    } on CameraException catch (error) {
      _showMessage(_cameraExceptionMessage(error));
    } catch (error) {
      _showMessage('Video could not be saved: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _saveCapture(String path, {required bool isVideo}) async {
    StudioMedia media;
    try {
      if (!isVideo && _captureSettings.autoEnhanceCaptures) {
        final bytes = await compute<Map<String, Object>, Uint8List>(
          processPhoto,
          {
            'path': path,
            'brightness': 1.0,
            'contrast': 1.0,
            'saturation': 1.0,
            'hue': 0.0,
            'rotation': 0,
            'cropRatio': -1.0,
            'watermark': _captureSettings.addWatermark,
            'mode': 'smart',
          },
        );
        media = await MediaLibrary.addEditedPhoto(bytes);
      } else {
        media = await MediaLibrary.addCapture(path, isVideo: isVideo);
      }
      if (mounted) setState(() => _lastCapturePath = media.path);
      widget.onCaptureSaved(media);
    } catch (error) {
      _showMessage('Capture created, but app library save failed: $error');
      return;
    }

    try {
      var hasAccess = await Gal.hasAccess();
      if (!hasAccess) hasAccess = await Gal.requestAccess();
      if (!hasAccess) {
        _showMessage(
          'Capture saved in Jerman Gallery. Gallery access was denied.',
        );
        return;
      }
      if (isVideo) {
        await Gal.putVideo(media.path);
      } else {
        await Gal.putImage(media.path);
      }
      _showMessage(
        isVideo
            ? 'Video saved to your gallery.'
            : 'Photo saved to your gallery.',
      );
    } catch (error) {
      _showMessage(
        'Capture saved in Jerman Gallery, but device gallery save failed: $error',
      );
    }
  }

  Future<void> _openGallery() async {
    try {
      await Gal.open();
    } catch (error) {
      _showMessage('Could not open the gallery: $error');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String get _flashName => switch (_flashMode) {
    FlashMode.off => 'OFF',
    FlashMode.auto => 'AUTO',
    FlashMode.always => 'ON',
    FlashMode.torch => 'TORCH',
  };

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              Expanded(child: _buildViewfinder()),
              const SizedBox(height: 16),
              _buildModeSelector(),
              const SizedBox(height: 18),
              _buildCaptureControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'JERMAN',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.2,
                    height: 1.1,
                  ),
                ),
                Text(
                  'CAMERA STUDIO',
                  style: TextStyle(
                    color: Color(0xFF8F9AAA),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          if (_isRecording) ...[
            const Icon(Icons.circle, size: 9, color: Color(0xFFFF4E54)),
            const SizedBox(width: 7),
            Text(
              _formatDuration(_recordingDuration),
              style: const TextStyle(
                fontFeatures: [FontFeature.tabularFigures()],
                fontWeight: FontWeight.w700,
              ),
            ),
          ] else
            const Icon(Icons.hd_rounded, color: Color(0xFF9AA7B7), size: 22),
        ],
      ),
    );
  }

  Widget _buildViewfinder() {
    final controller = _controller;
    final isReady = controller != null && controller.value.isInitialized;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        color: const Color(0xFF111721),
        child: isReady
            ? _buildLivePreview(controller)
            : _buildPreviewPlaceholder(),
      ),
    );
  }

  Widget _buildLivePreview(CameraController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final previewSize = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(controller),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) => _focusAt(details, previewSize),
            ),
            if (_showGrid)
              const IgnorePointer(child: CustomPaint(painter: _GridPainter())),
            if (_showPortraitGuide && _mode == CameraCaptureMode.photo)
              const IgnorePointer(
                child: CustomPaint(painter: _PortraitGuidePainter()),
              ),
            if (_focusPoint case final point?)
              Positioned(
                left: point.dx * previewSize.width - 22,
                top: point.dy * previewSize.height - 22,
                child: const IgnorePointer(
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.fromBorderSide(
                          BorderSide(color: _accent, width: 1.5),
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(11)),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 14,
              right: 14,
              top: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _PreviewIconButton(
                    icon: _flashMode == FlashMode.off
                        ? Icons.flash_off_rounded
                        : Icons.flash_on_rounded,
                    label: 'Flash $_flashName',
                    onPressed: _cycleFlashMode,
                  ),
                  if (_mode == CameraCaptureMode.photo)
                    _PreviewIconButton(
                      icon: _showPortraitGuide
                          ? Icons.accessibility_new_rounded
                          : Icons.accessibility_new_outlined,
                      label: _showPortraitGuide
                          ? 'Hide full-body portrait guide'
                          : 'Show full-body portrait guide',
                      onPressed: () => setState(
                        () => _showPortraitGuide = !_showPortraitGuide,
                      ),
                    ),
                  _PreviewIconButton(
                    icon: _showGrid ? Icons.grid_on_rounded : Icons.grid_3x3,
                    label: _showGrid ? 'Hide grid' : 'Show grid',
                    onPressed: () => setState(() => _showGrid = !_showGrid),
                  ),
                ],
              ),
            ),
            if (_isRecording)
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.62),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'RECORDING',
                      style: TextStyle(
                        color: Color(0xFFFF6469),
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 8,
              child: _buildZoomControl(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPreviewPlaceholder() {
    final error = _cameraError;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading)
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: _accent,
                ),
              )
            else
              const Icon(
                Icons.no_photography_outlined,
                color: Color(0xFF748194),
                size: 40,
              ),
            const SizedBox(height: 16),
            Text(
              _isLoading ? 'Starting camera' : 'Camera unavailable',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF9AA7B7),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => unawaited(_initializeCamera()),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildZoomControl() {
    final canZoom = _maxZoom > _minZoom;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 3),
        child: Row(
          children: [
            const Icon(Icons.zoom_out_rounded, size: 18, color: Colors.white70),
            Expanded(
              child: Slider(
                min: _minZoom,
                max: canZoom ? _maxZoom : _minZoom + 1,
                value: canZoom ? _zoom.clamp(_minZoom, _maxZoom) : _minZoom,
                onChanged: canZoom
                    ? (value) => setState(() => _zoom = value)
                    : null,
                onChangeEnd: canZoom
                    ? (value) => unawaited(
                        _performCameraAction(
                          () => _controller!.setZoomLevel(value),
                        ),
                      )
                    : null,
              ),
            ),
            SizedBox(
              width: 42,
              child: Text(
                '${_zoom.toStringAsFixed(1)}x',
                textAlign: TextAlign.end,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeButton(
            label: 'PHOTO',
            selected: _mode == CameraCaptureMode.photo,
            onPressed: () => setState(() => _mode = CameraCaptureMode.photo),
          ),
          _ModeButton(
            label: 'VIDEO',
            selected: _mode == CameraCaptureMode.video,
            onPressed: () => setState(() => _mode = CameraCaptureMode.video),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureControls() {
    final isReady = _controller?.value.isInitialized ?? false;
    return Column(
      children: [
        if (_maxExposure > _minExposure)
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
            child: Row(
              children: [
                const Icon(
                  Icons.exposure_rounded,
                  size: 19,
                  color: Color(0xFF9AA7B7),
                ),
                Expanded(
                  child: Slider(
                    min: _minExposure,
                    max: _maxExposure,
                    value: _exposure.clamp(_minExposure, _maxExposure),
                    onChanged: (value) => setState(() => _exposure = value),
                    onChangeEnd: (value) => unawaited(
                      _performCameraAction(
                        () => _controller!.setExposureOffset(value),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 42,
                  child: Text(
                    '${_exposure >= 0 ? '+' : ''}${_exposure.toStringAsFixed(1)}',
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: Color(0xFFB8C2CE),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _GalleryButton(path: _lastCapturePath, onPressed: _openGallery),
            Semantics(
              label: _isRecording
                  ? 'Stop recording'
                  : _mode == CameraCaptureMode.photo
                  ? 'Take photo'
                  : 'Start recording',
              button: true,
              child: GestureDetector(
                onTap: isReady && !_isBusy ? () => unawaited(_capture()) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _mode == CameraCaptureMode.video || _isRecording
                        ? const Color(0xFFFF4E54)
                        : Colors.white,
                    border: Border.all(
                      color: _isRecording
                          ? const Color(0xFFFF9A9D)
                          : const Color(0xFF9AA7B7),
                      width: 5,
                    ),
                  ),
                  child: Center(
                    child: _isBusy
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _background,
                            ),
                          )
                        : Icon(
                            _isRecording
                                ? Icons.stop_rounded
                                : _mode == CameraCaptureMode.video
                                ? Icons.videocam_rounded
                                : Icons.camera_alt_rounded,
                            color:
                                _mode == CameraCaptureMode.photo &&
                                    !_isRecording
                                ? _background
                                : Colors.white,
                            size: _isRecording ? 31 : 27,
                          ),
                  ),
                ),
              ),
            ),
            _RoundControlButton(
              icon: Icons.cameraswitch_rounded,
              label: 'Switch camera',
              onPressed: isReady && !_isBusy && !_isRecording
                  ? () => unawaited(_switchCamera())
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.42)
      ..strokeWidth = 0.7;
    for (var index = 1; index < 3; index++) {
      final x = size.width * index / 3;
      final y = size.height * index / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}

class _PortraitGuidePainter extends CustomPainter {
  const _PortraitGuidePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final guideWidth = size.width * .72;
    final guideHeight = size.height * .82;
    final left = (size.width - guideWidth) / 2;
    final top = (size.height - guideHeight) / 2;
    final guide = Rect.fromLTWH(left, top, guideWidth, guideHeight);
    final line = Paint()
      ..color = Colors.white.withValues(alpha: .72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final softLine = Paint()
      ..color = Colors.white.withValues(alpha: .48)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRRect(
      RRect.fromRectAndRadius(guide, const Radius.circular(18)),
      line,
    );

    final centerX = guide.center.dx;
    final headRadius = guideWidth * .105;
    final headCenter = Offset(centerX, top + guideHeight * .19);
    canvas.drawOval(
      Rect.fromCircle(center: headCenter, radius: headRadius),
      softLine,
    );

    final shouldersY = headCenter.dy + headRadius * 1.5;
    final waistY = top + guideHeight * .57;
    final hipsY = top + guideHeight * .69;
    final figure = Path()
      ..moveTo(centerX - headRadius * 1.9, shouldersY)
      ..quadraticBezierTo(
        centerX,
        shouldersY - headRadius * .55,
        centerX + headRadius * 1.9,
        shouldersY,
      )
      ..lineTo(centerX + headRadius * 1.45, waistY)
      ..lineTo(centerX + headRadius * 1.55, hipsY)
      ..lineTo(centerX + headRadius * .63, hipsY)
      ..lineTo(centerX + headRadius * .42, guide.bottom - guideHeight * .07)
      ..moveTo(centerX - headRadius * .42, guide.bottom - guideHeight * .07)
      ..lineTo(centerX - headRadius * .63, hipsY)
      ..lineTo(centerX - headRadius * 1.55, hipsY)
      ..lineTo(centerX - headRadius * 1.45, waistY)
      ..close();
    canvas.drawPath(figure, softLine);

    final thirdsY = top + guideHeight / 3;
    final thirdsPaint = Paint()
      ..color = Colors.white.withValues(alpha: .23)
      ..strokeWidth = .7;
    canvas.drawLine(
      Offset(left + 8, thirdsY),
      Offset(guide.right - 8, thirdsY),
      thirdsPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left + 8, top + 8, guideWidth - 16, 24),
        const Radius.circular(12),
      ),
      Paint()..color = Colors.black.withValues(alpha: .42),
    );
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'FULL BODY  ·  HEADS ABOVE TOP THIRD',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: .35,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: guideWidth - 24);
    textPainter.paint(
      canvas,
      Offset(guide.center.dx - textPainter.width / 2, top + 15),
    );
  }

  @override
  bool shouldRepaint(covariant _PortraitGuidePainter oldDelegate) => false;
}

class _PreviewIconButton extends StatelessWidget {
  const _PreviewIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.56),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: label,
        onPressed: onPressed,
        icon: Icon(icon, size: 21, color: Colors.white),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: selected
            ? const Color(0xFF233446)
            : Colors.transparent,
        foregroundColor: selected ? _accent : const Color(0xFF9AA7B7),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        minimumSize: const Size(84, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 1.4,
        ),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

class _GalleryButton extends StatelessWidget {
  const _GalleryButton({required this.path, required this.onPressed});

  final String? path;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF29313D)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: SizedBox(
          width: 52,
          height: 52,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: path == null
                ? const Icon(
                    Icons.photo_library_outlined,
                    color: Color(0xFFB7C2D0),
                    size: 22,
                  )
                : Image.file(
                    File(path!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.movie_outlined,
                      color: Color(0xFFB7C2D0),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _RoundControlButton extends StatelessWidget {
  const _RoundControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _panel,
      shape: const CircleBorder(side: BorderSide(color: Color(0xFF29313D))),
      child: IconButton(
        tooltip: label,
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 24),
        constraints: const BoxConstraints.tightFor(width: 52, height: 52),
      ),
    );
  }
}
