import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

class StudioMedia {
  const StudioMedia({
    required this.path,
    required this.isVideo,
    required this.createdAt,
  });

  final String path;
  final bool isVideo;
  final DateTime createdAt;

  String get title => '${isVideo ? 'Video' : 'Photo'} ${_dateLabel(createdAt)}';

  static String _dateLabel(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

class StudioProject {
  const StudioProject({
    required this.id,
    required this.mediaPath,
    required this.isVideo,
    required this.filter,
    required this.speed,
    required this.title,
    required this.savedAt,
  });

  final String id;
  final String mediaPath;
  final bool isVideo;
  final String filter;
  final double speed;
  final String title;
  final DateTime savedAt;

  Map<String, Object> toJson() => {
    'id': id,
    'mediaPath': mediaPath,
    'isVideo': isVideo,
    'filter': filter,
    'speed': speed,
    'title': title,
    'savedAt': savedAt.toIso8601String(),
  };

  factory StudioProject.fromJson(Map<String, dynamic> json) => StudioProject(
    id: json['id'] as String,
    mediaPath: json['mediaPath'] as String,
    isVideo: json['isVideo'] as bool,
    filter: json['filter'] as String,
    speed: (json['speed'] as num).toDouble(),
    title: json['title'] as String,
    savedAt: DateTime.parse(json['savedAt'] as String),
  );
}

abstract final class MediaLibrary {
  static Future<Directory> _mediaDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory('${documents.path}/JermanCameraStudio/Media');
    await directory.create(recursive: true);
    return directory;
  }

  static Future<File> _uniqueFile(String extension) async {
    final directory = await _mediaDirectory();
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return File('${directory.path}/$timestamp$extension');
  }

  static Future<StudioMedia> addCapture(
    String sourcePath, {
    required bool isVideo,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw FileSystemException(
        'Captured media file does not exist.',
        sourcePath,
      );
    }
    final sourceName = source.uri.pathSegments.last;
    final dotIndex = sourceName.lastIndexOf('.');
    final extension = dotIndex >= 0
        ? sourceName.substring(dotIndex).toLowerCase()
        : isVideo
        ? '.mp4'
        : '.jpg';
    final file = await _uniqueFile(extension);
    await source.copy(file.path);
    return StudioMedia(
      path: file.path,
      isVideo: isVideo,
      createdAt: DateTime.now(),
    );
  }

  static Future<StudioMedia> addEditedPhoto(Uint8List bytes) async {
    final file = await _uniqueFile('.jpg');
    await file.writeAsBytes(bytes, flush: true);
    return StudioMedia(
      path: file.path,
      isVideo: false,
      createdAt: DateTime.now(),
    );
  }

  static Future<List<StudioMedia>> loadCaptures() async {
    final directory = await _mediaDirectory();
    final media = <StudioMedia>[];
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) continue;
      final path = entity.path;
      final dotIndex = path.lastIndexOf('.');
      final extension = dotIndex >= 0
          ? path.substring(dotIndex).toLowerCase()
          : '';
      final isVideo = const {
        '.mp4',
        '.mov',
        '.m4v',
        '.3gp',
        '.webm',
      }.contains(extension);
      if (!isVideo &&
          !const {'.jpg', '.jpeg', '.png', '.webp'}.contains(extension)) {
        continue;
      }
      media.add(
        StudioMedia(
          path: path,
          isVideo: isVideo,
          createdAt: await entity.lastModified(),
        ),
      );
    }
    media.sort((first, second) => second.createdAt.compareTo(first.createdAt));
    return media;
  }

  static Future<void> deleteCapture(StudioMedia media) async {
    final file = File(media.path);
    if (await file.exists()) await file.delete();
  }

  static Future<List<StudioProject>> loadProjects() async {
    final documents = await getApplicationDocumentsDirectory();
    final file = File('${documents.path}/JermanCameraStudio/projects.json');
    if (!await file.exists()) return [];
    final data = jsonDecode(await file.readAsString());
    if (data is! List) {
      throw const FormatException('Project library must contain a list.');
    }
    return data
        .map((entry) => StudioProject.fromJson(entry as Map<String, dynamic>))
        .toList()
      ..sort((first, second) => second.savedAt.compareTo(first.savedAt));
  }

  static Future<void> saveProject(StudioProject project) async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory('${documents.path}/JermanCameraStudio');
    await directory.create(recursive: true);
    final file = File('${directory.path}/projects.json');
    final projects = await loadProjects();
    final updated = [
      project,
      ...projects.where((existing) => existing.id != project.id),
    ];
    await file.writeAsString(
      jsonEncode(updated.map((entry) => entry.toJson()).toList()),
      flush: true,
    );
  }
}
