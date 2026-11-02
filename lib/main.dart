import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'camera_screen.dart';
import 'media_library.dart';
import 'studio_pages.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const JermanCameraStudioApp());
}

class JermanCameraStudioApp extends StatelessWidget {
  const JermanCameraStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jerman Camera Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: studioBackground,
        colorScheme: const ColorScheme.dark(
          primary: studioGreen,
          secondary: Color(0xFF81E89A),
          surface: studioSurface,
          onPrimary: studioBackground,
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: studioGreen,
          inactiveTrackColor: Color(0xFF314334),
          thumbColor: Colors.white,
          overlayColor: Color(0x3300E85A),
          trackHeight: 2,
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF19251B),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF07100A),
          indicatorColor: Color(0xFF16351D),
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      home: const StudioEntry(),
    );
  }
}

class StudioEntry extends StatefulWidget {
  const StudioEntry({super.key});

  @override
  State<StudioEntry> createState() => _StudioEntryState();
}

class _StudioEntryState extends State<StudioEntry> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _showSplash = false);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _showSplash ? const StudioSplashScreen() : const StudioShell();
  }
}

class StudioSplashScreen extends StatelessWidget {
  const StudioSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: studioBackground,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -.2),
                    radius: 1.05,
                    colors: [
                      const Color(0xFF103D17).withValues(alpha: .42),
                      studioBackground,
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _SplashLens(),
                    const SizedBox(height: 27),
                    const Text(
                      'JERMAN',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const Text(
                      'CAMERA STUDIO',
                      style: TextStyle(
                        color: studioGreen,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Capture  •  Edit  •  Create',
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                    const Text(
                      'Like a Pro',
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                    const SizedBox(height: 62),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Powered by',
                          style: TextStyle(color: studioMuted, fontSize: 10),
                        ),
                        SizedBox(width: 8),
                        StudioBrandMark(size: 30),
                        SizedBox(width: 5),
                        Text(
                          'JERMAN\nTECHNOLOGY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .7,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 29),
                    const SizedBox(
                      width: 110,
                      child: LinearProgressIndicator(
                        minHeight: 4,
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        backgroundColor: studioLine,
                        color: studioGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashLens extends StatelessWidget {
  const _SplashLens();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      height: 190,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFF1F7435), Color(0xFF0B2913), Color(0xFF030704)],
        ),
        border: Border.all(color: studioGreen.withValues(alpha: .75), width: 2),
        boxShadow: [
          BoxShadow(
            color: studioGreen.withValues(alpha: .32),
            blurRadius: 42,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.camera_rounded,
          color: Color(0xFF83FF9C),
          size: 96,
          shadows: [Shadow(color: studioGreen, blurRadius: 28)],
        ),
      ),
    );
  }
}

class StudioShell extends StatefulWidget {
  const StudioShell({super.key});

  @override
  State<StudioShell> createState() => _StudioShellState();
}

class _StudioShellState extends State<StudioShell> {
  int _selectedTab = 0;
  List<StudioMedia> _media = [];
  List<StudioProject> _projects = [];
  String? _libraryError;
  bool _didShowLoadError = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadLibrary());
  }

  Future<void> _loadLibrary() async {
    try {
      final media = await MediaLibrary.loadCaptures();
      final projects = await MediaLibrary.loadProjects();
      if (!mounted) return;
      setState(() {
        _media = media;
        _projects = projects;
        _libraryError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _libraryError = 'Could not load your saved media: $error';
      });
    }
  }

  void _onCaptureSaved(StudioMedia media) {
    if (!mounted) return;
    setState(() {
      _media = [
        media,
        ..._media.where((existing) => existing.path != media.path),
      ];
    });
  }

  void _onProjectSaved(StudioProject project) {
    if (!mounted) return;
    setState(() {
      _projects = [
        project,
        ..._projects.where((existing) => existing.id != project.id),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_libraryError != null && !_didShowLoadError) {
      _didShowLoadError = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_libraryError!),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () {
                _didShowLoadError = false;
                unawaited(_loadLibrary());
              },
            ),
          ),
        );
      });
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: studioBackground,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF07100A),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: studioBackground,
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _selectedTab,
            children: [
              StudioHomePage(media: _media, onAction: _handleAction),
              StudioGalleryPage(
                media: _media,
                onOpen: _openEditor,
                onDelete: _deleteMedia,
              ),
              StudioProjectsPage(
                projects: _projects,
                media: _media,
                onOpen: _openProject,
                onCreate: () => _openCamera(CameraCaptureMode.photo),
              ),
              StudioProfilePage(
                media: _media,
                projects: _projects,
                onAction: _handleAction,
              ),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedTab,
          onDestinationSelected: (index) {
            setState(() => _selectedTab = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.photo_library_outlined),
              selectedIcon: Icon(Icons.photo_library_rounded),
              label: 'Gallery',
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_open_outlined),
              selectedIcon: Icon(Icons.folder_rounded),
              label: 'Projects',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(StudioAction action) {
    switch (action) {
      case StudioAction.photo:
        _openCamera(CameraCaptureMode.photo);
      case StudioAction.video:
        _openCamera(CameraCaptureMode.video);
      case StudioAction.autoEdit:
        _openRecentForEditing();
      case StudioAction.gallery:
        setState(() => _selectedTab = 1);
      case StudioAction.projects:
      case StudioAction.templates:
        setState(() => _selectedTab = 2);
      case StudioAction.profile:
        setState(() => _selectedTab = 3);
      case StudioAction.settings:
        _pushPage(const StudioSettingsPage());
      case StudioAction.about:
        _pushPage(const StudioAboutPage());
      case StudioAction.filters:
      case StudioAction.effects:
        _openRecentPhoto();
    }
  }

  void _openCamera(CameraCaptureMode mode) {
    _pushPage(
      CameraCaptureScreen(initialMode: mode, onCaptureSaved: _onCaptureSaved),
    );
  }

  void _pushPage(Widget page) {
    unawaited(
      Navigator.of(context)
          .push<void>(MaterialPageRoute<void>(builder: (_) => page)),
    );
  }

  void _openEditor(StudioMedia media) {
    if (media.isVideo) {
      _pushPage(
        StudioVideoEditorPage(media: media, onProjectSaved: _onProjectSaved),
      );
    } else {
      _pushPage(StudioPhotoEditorPage(media: media, onSaved: _onCaptureSaved));
    }
  }

  void _openProject(StudioProject project) {
    final media = _media.where((item) => item.path == project.mediaPath);
    if (media.isEmpty) {
      _showMessage('The media for this project is no longer available.');
      return;
    }
    _openEditor(media.first);
  }

  void _openRecentForEditing() {
    if (_media.isEmpty) {
      _showMessage('Capture a photo or video before starting an edit.');
      return;
    }
    _openEditor(_media.first);
  }

  void _openRecentPhoto() {
    final photos = _media.where((item) => !item.isVideo);
    if (photos.isEmpty) {
      _showMessage('Capture a photo before opening the photo editor.');
      return;
    }
    _openEditor(photos.first);
  }

  Future<void> _deleteMedia(StudioMedia media) async {
    try {
      await MediaLibrary.deleteCapture(media);
      if (!mounted) return;
      setState(() => _media.removeWhere((item) => item.path == media.path));
    } on FileSystemException catch (error) {
      _showMessage('Could not remove capture: ${error.message}');
    } catch (error) {
      _showMessage('Could not remove capture: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
