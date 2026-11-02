import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import 'media_library.dart';
import 'photo_processing.dart';

const studioBackground = Color(0xFF030704);
const studioSurface = Color(0xFF0D160F);
const studioSurfaceLight = Color(0xFF142318);
const studioGreen = Color(0xFF00E85A);
const studioMuted = Color(0xFF9AAF9E);
const studioLine = Color(0xFF1E3423);
const _studioMediaChannel = MethodChannel('jerman.camera/media');

enum StudioAction {
  photo,
  video,
  autoEdit,
  importMedia,
  gallery,
  projects,
  profile,
  filters,
  effects,
  templates,
  settings,
  about,
}

class StudioBrandMark extends StatelessWidget {
  const StudioBrandMark({super.key, this.size = 46});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * .34),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF183D1D), Color(0xFF07100A)],
        ),
        border: Border.all(color: const Color(0xFF276A34)),
        boxShadow: [
          BoxShadow(color: studioGreen.withValues(alpha: .12), blurRadius: 16),
        ],
      ),
      child: Icon(
        Icons.camera_alt_rounded,
        color: studioGreen,
        size: size * .5,
      ),
    );
  }
}

class StudioHeader extends StatelessWidget {
  const StudioHeader({
    super.key,
    required this.title,
    this.showBack = false,
    this.trailing,
  });

  final String title;
  final bool showBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Row(
        children: [
          if (showBack)
            IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded),
            )
          else
            const StudioBrandMark(size: 40),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: .2,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class StudioSectionTitle extends StatelessWidget {
  const StudioSectionTitle(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: studioGreen,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: const Size(44, 34),
            ),
            child: Text(action!),
          ),
      ],
    );
  }
}

class StudioHomePage extends StatelessWidget {
  const StudioHomePage({
    super.key,
    required this.media,
    required this.onAction,
  });

  final List<StudioMedia> media;
  final ValueChanged<StudioAction> onAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: studioBackground,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(17, 7, 17, 22),
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Menu',
                  onPressed: () => _showMenu(context),
                  icon: const Icon(Icons.menu_rounded),
                ),
                const Spacer(),
                const Column(
                  children: [
                    Text(
                      'JERMAN',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 1.4,
                      ),
                    ),
                    Text(
                      'CAMERA STUDIO',
                      style: TextStyle(
                        color: studioGreen,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Settings',
                  onPressed: () => onAction(StudioAction.settings),
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _HeroCard(onTap: () => onAction(StudioAction.photo)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _FeatureCard(
                    icon: Icons.camera_alt_rounded,
                    title: 'Camera',
                    subtitle: 'Take Photos',
                    color: studioGreen,
                    onTap: () => onAction(StudioAction.photo),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FeatureCard(
                    icon: Icons.videocam_rounded,
                    title: 'Video',
                    subtitle: 'Record Videos',
                    color: const Color(0xFF8AF6A0),
                    onTap: () => onAction(StudioAction.video),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _FeatureCard(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Auto Edit',
                    subtitle: 'Enhance Media',
                    color: const Color(0xFFB8F66D),
                    onTap: () => onAction(StudioAction.autoEdit),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FeatureCard(
                    icon: Icons.photo_library_rounded,
                    title: 'My Gallery',
                    subtitle: 'View & Manage',
                    color: const Color(0xFF90E8C3),
                    onTap: () => onAction(StudioAction.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 17),
            StudioSectionTitle(
              'Quick Tools',
              action: 'See All',
              onAction: () => onAction(StudioAction.effects),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _QuickTool(
                  icon: Icons.palette_outlined,
                  label: 'Filters',
                  onTap: () => onAction(StudioAction.filters),
                ),
                _QuickTool(
                  icon: Icons.auto_awesome_outlined,
                  label: 'Effects',
                  onTap: () => onAction(StudioAction.effects),
                ),
                _QuickTool(
                  icon: Icons.dashboard_customize_outlined,
                  label: 'Templates',
                  onTap: () => onAction(StudioAction.templates),
                ),
                _QuickTool(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () => onAction(StudioAction.settings),
                ),
              ],
            ),
            if (media.isNotEmpty) ...[
              const SizedBox(height: 14),
              StudioSectionTitle(
                'Recent',
                action: 'See All',
                onAction: () => onAction(StudioAction.gallery),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 112,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: media.length.clamp(0, 8),
                  separatorBuilder: (_, _) => const SizedBox(width: 9),
                  itemBuilder: (context, index) =>
                      _MediaThumbnail(media: media[index], width: 92),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: studioSurface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MenuTile(
              icon: Icons.photo_library_outlined,
              label: 'My Gallery',
              onTap: () {
                Navigator.pop(context);
                onAction(StudioAction.gallery);
              },
            ),
            _MenuTile(
              icon: Icons.add_photo_alternate_outlined,
              label: 'Import photos or videos',
              onTap: () {
                Navigator.pop(context);
                onAction(StudioAction.importMedia);
              },
            ),
            _MenuTile(
              icon: Icons.folder_open_outlined,
              label: 'Projects',
              onTap: () {
                Navigator.pop(context);
                onAction(StudioAction.projects);
              },
            ),
            _MenuTile(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () {
                Navigator.pop(context);
                onAction(StudioAction.settings);
              },
            ),
            _MenuTile(
              icon: Icons.info_outline_rounded,
              label: 'About Jerman Camera Studio',
              onTap: () {
                Navigator.pop(context);
                onAction(StudioAction.about);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(23),
      onTap: onTap,
      child: Ink(
        height: 155,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: const Color(0xFF28613A)),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF17341B), Color(0xFF07100A), Color(0xFF0D2411)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -14,
              bottom: -34,
              child: Icon(
                Icons.camera_alt_rounded,
                size: 176,
                color: studioGreen.withValues(alpha: .12),
              ),
            ),
            Positioned(
              right: 12,
              top: 8,
              bottom: 8,
              child: Icon(
                Icons.camera_alt_rounded,
                size: 125,
                color: studioGreen.withValues(alpha: .86),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 17, 120, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Capture',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                  ),
                  const Text(
                    'Amazing Moments',
                    style: TextStyle(
                      color: Color(0xFFDCEBDD),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'With Professional Quality',
                    style: TextStyle(color: studioMuted, fontSize: 10),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: studioGreen,
                      foregroundColor: const Color(0xFF061007),
                      minimumSize: const Size(92, 31),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Explore',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded, size: 15),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: studioSurface,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        borderRadius: BorderRadius.circular(19),
        onTap: onTap,
        child: SizedBox(
          height: 89,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 27, color: color),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: studioMuted, fontSize: 9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickTool extends StatelessWidget {
  const _QuickTool({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: studioSurfaceLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: studioGreen, size: 21),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFD4DED5),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StudioGalleryPage extends StatefulWidget {
  const StudioGalleryPage({
    super.key,
    required this.media,
    required this.onOpen,
    required this.onDelete,
    required this.onImport,
  });

  final List<StudioMedia> media;
  final ValueChanged<StudioMedia> onOpen;
  final ValueChanged<StudioMedia> onDelete;
  final VoidCallback onImport;

  @override
  State<StudioGalleryPage> createState() => _StudioGalleryPageState();
}

class _StudioGalleryPageState extends State<StudioGalleryPage> {
  int _selectedFilter = 0;

  @override
  Widget build(BuildContext context) {
    final visibleMedia = switch (_selectedFilter) {
      1 => widget.media.where((media) => !media.isVideo).toList(),
      2 => widget.media.where((media) => media.isVideo).toList(),
      _ => widget.media,
    };

    return Scaffold(
      backgroundColor: studioBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 6),
              child: StudioHeader(
                title: 'My Gallery',
                trailing: IconButton(
                  tooltip: 'Import photo or video',
                  onPressed: widget.onImport,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 4, 17, 12),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _selectedFilter == 0,
                    onTap: () => setState(() => _selectedFilter = 0),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Photos',
                    selected: _selectedFilter == 1,
                    onTap: () => setState(() => _selectedFilter = 1),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Videos',
                    selected: _selectedFilter == 2,
                    onTap: () => setState(() => _selectedFilter = 2),
                  ),
                ],
              ),
            ),
            Expanded(
              child: visibleMedia.isEmpty
                  ? _EmptyState(
                      icon: Icons.photo_library_outlined,
                      title: 'Your gallery is ready',
                      message:
                          'Photos and videos you capture will appear here.',
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(17, 0, 17, 22),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: .82,
                          ),
                      itemCount: visibleMedia.length,
                      itemBuilder: (context, index) {
                        final item = visibleMedia[index];
                        return _GalleryTile(
                          media: item,
                          onTap: () => widget.onOpen(item),
                          onLongPress: () => _confirmDelete(item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(StudioMedia media) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: studioSurface,
        title: const Text('Remove capture?'),
        content: const Text(
          'This removes this copy from Jerman Gallery. It will not remove a copy already saved in your device gallery.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (shouldDelete == true) widget.onDelete(media);
  }
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({
    required this.media,
    required this.onTap,
    required this.onLongPress,
  });

  final StudioMedia media;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: studioSurface,
      borderRadius: BorderRadius.circular(15),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MediaPreview(media: media),
            if (media.isVideo)
              const Center(
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  size: 34,
                  color: Colors.white,
                ),
              ),
            Positioned(
              left: 7,
              right: 7,
              bottom: 7,
              child: Text(
                _clockLabel(media.createdAt),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  shadows: [Shadow(blurRadius: 5, color: Colors.black)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StudioProjectsPage extends StatelessWidget {
  const StudioProjectsPage({
    super.key,
    required this.projects,
    required this.media,
    required this.onOpen,
    required this.onCreate,
  });

  final List<StudioProject> projects;
  final List<StudioMedia> media;
  final ValueChanged<StudioProject> onOpen;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: studioBackground,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 17, vertical: 6),
              child: StudioHeader(title: 'Projects'),
            ),
            Expanded(
              child: projects.isEmpty
                  ? _EmptyState(
                      icon: Icons.folder_open_outlined,
                      title: 'Start a new project',
                      message:
                          'Your saved photo and video edits will be kept here.',
                      action: FilledButton.icon(
                        onPressed: onCreate,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Create project'),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(17, 4, 17, 24),
                      children: [
                        FilledButton.icon(
                          onPressed: onCreate,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('New project'),
                          style: FilledButton.styleFrom(
                            backgroundColor: studioGreen,
                            foregroundColor: studioBackground,
                          ),
                        ),
                        const SizedBox(height: 12),
                        for (final project in projects)
                          _ProjectCard(
                            project: project,
                            media: media,
                            onTap: () => onOpen(project),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.media,
    required this.onTap,
  });

  final StudioProject project;
  final List<StudioMedia> media;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final matchingMedia = media.where((item) => item.path == project.mediaPath);
    final source = matchingMedia.isEmpty ? null : matchingMedia.first;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: studioSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: const BorderSide(color: studioLine),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(9),
        leading: SizedBox(
          width: 58,
          height: 58,
          child: source == null
              ? const StudioBrandMark(size: 58)
              : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: MediaPreview(media: source),
                ),
        ),
        title: Text(
          project.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
        subtitle: Text(
          '${project.isVideo ? 'Video' : 'Photo'} · ${project.filter}',
          style: const TextStyle(color: studioMuted, fontSize: 11),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: studioGreen),
        onTap: onTap,
      ),
    );
  }
}

class StudioProfilePage extends StatelessWidget {
  const StudioProfilePage({
    super.key,
    required this.media,
    required this.projects,
    required this.onAction,
  });

  final List<StudioMedia> media;
  final List<StudioProject> projects;
  final ValueChanged<StudioAction> onAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: studioBackground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const StudioHeader(title: 'Profile'),
            const SizedBox(height: 24),
            const Center(child: StudioBrandMark(size: 92)),
            const SizedBox(height: 14),
            const Text(
              'Jerman Creator',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            const Text(
              'Create. Capture. Tell your story.',
              textAlign: TextAlign.center,
              style: TextStyle(color: studioMuted, fontSize: 13),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                _ProfileStat(label: 'CAPTURES', value: '${media.length}'),
                _ProfileStat(label: 'PROJECTS', value: '${projects.length}'),
              ],
            ),
            const SizedBox(height: 18),
            _MenuTile(
              icon: Icons.photo_library_outlined,
              label: 'My Gallery',
              onTap: () => onAction(StudioAction.gallery),
            ),
            _MenuTile(
              icon: Icons.folder_open_outlined,
              label: 'My Projects',
              onTap: () => onAction(StudioAction.projects),
            ),
            _MenuTile(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () => onAction(StudioAction.settings),
            ),
            _MenuTile(
              icon: Icons.info_outline_rounded,
              label: 'About Jerman Technology',
              onTap: () => onAction(StudioAction.about),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: studioSurface,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 21,
                color: studioGreen,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: studioMuted,
                letterSpacing: .7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StudioSettingsPage extends StatefulWidget {
  const StudioSettingsPage({super.key});

  @override
  State<StudioSettingsPage> createState() => _StudioSettingsPageState();
}

class _StudioSettingsPageState extends State<StudioSettingsPage> {
  String _quality = 'High';
  int _framesPerSecond = 30;
  bool _grid = true;
  bool _watermark = false;
  bool _notifications = true;
  bool _autoEnhance = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPreferences());
  }

  Future<void> _loadPreferences() async {
    try {
      final settings = await MediaLibrary.loadSettings();
      if (!mounted) return;
      setState(() {
        _quality = settings.resolution;
        _framesPerSecond = settings.framesPerSecond;
        _grid = settings.showCompositionGrid;
        _watermark = settings.addWatermark;
        _autoEnhance = settings.autoEnhanceCaptures;
      });
    } catch (error) {
      if (mounted) _showSettingsMessage('Settings could not be loaded: $error');
    }
  }

  Future<void> _savePreferences() async {
    try {
      await MediaLibrary.saveSettings(
        StudioCaptureSettings(
          resolution: _quality,
          framesPerSecond: _framesPerSecond,
          addWatermark: _watermark,
          autoEnhanceCaptures: _autoEnhance,
          showCompositionGrid: _grid,
        ),
      );
    } catch (error) {
      if (mounted) _showSettingsMessage('Settings could not be saved: $error');
    }
  }

  void _showSettingsMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: studioBackground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(17, 7, 17, 24),
          children: [
            const StudioHeader(title: 'Settings', showBack: true),
            const SizedBox(height: 13),
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: studioLine),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D2612), Color(0xFF07100A)],
                ),
              ),
              child: const Row(
                children: [
                  StudioBrandMark(size: 56),
                  SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'JERMAN',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.6,
                        ),
                      ),
                      Text(
                        'CAMERA STUDIO',
                        style: TextStyle(
                          color: studioGreen,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        'Version 1.0.0',
                        style: TextStyle(color: studioMuted, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 19),
            _SettingsGroup(
              title: 'CAMERA',
              children: [
                _SettingsTile(
                  icon: Icons.high_quality_outlined,
                  title: 'Photo quality',
                  subtitle: 'Maximum is limited by your phone camera',
                  trailing: DropdownButton<String>(
                    value: _quality,
                    underline: const SizedBox.shrink(),
                    dropdownColor: studioSurface,
                    style: const TextStyle(
                      color: studioGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'High', child: Text('High')),
                      DropdownMenuItem(
                        value: 'Maximum supported',
                        child: Text('Maximum'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _quality = value);
                        unawaited(_savePreferences());
                      }
                    },
                  ),
                ),
                _SettingsTile(
                  icon: Icons.speed_rounded,
                  title: 'Video frame rate',
                  subtitle: '60 fps falls back automatically if unsupported',
                  trailing: DropdownButton<int>(
                    value: _framesPerSecond,
                    underline: const SizedBox.shrink(),
                    dropdownColor: studioSurface,
                    style: const TextStyle(
                      color: studioGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    items: const [
                      DropdownMenuItem(value: 30, child: Text('30 fps')),
                      DropdownMenuItem(value: 60, child: Text('60 fps')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _framesPerSecond = value);
                      unawaited(_savePreferences());
                    },
                  ),
                ),
                _SettingsTile(
                  icon: Icons.grid_on_rounded,
                  title: 'Composition grid',
                  subtitle: 'Show rule-of-thirds guides in the camera',
                  trailing: Switch.adaptive(
                    value: _grid,
                    activeTrackColor: studioGreen,
                    onChanged: (value) {
                      setState(() => _grid = value);
                      unawaited(_savePreferences());
                    },
                  ),
                ),
                _SettingsTile(
                  icon: Icons.branding_watermark_outlined,
                  title: 'Jerman watermark',
                  subtitle: 'Add your brand to exported photos',
                  trailing: Switch.adaptive(
                    value: _watermark,
                    activeTrackColor: studioGreen,
                    onChanged: (value) {
                      setState(() => _watermark = value);
                      unawaited(_savePreferences());
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SettingsGroup(
              title: 'STUDIO',
              children: [
                _SettingsTile(
                  icon: Icons.auto_awesome_outlined,
                  title: 'Automatic enhancement',
                  subtitle: 'Enhance photos after capture',
                  trailing: Switch.adaptive(
                    value: _autoEnhance,
                    activeTrackColor: studioGreen,
                    onChanged: (value) {
                      setState(() => _autoEnhance = value);
                      unawaited(_savePreferences());
                    },
                  ),
                ),
                _SettingsTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  subtitle: 'Tips and product updates',
                  trailing: Switch.adaptive(
                    value: _notifications,
                    activeTrackColor: studioGreen,
                    onChanged: (value) =>
                        setState(() => _notifications = value),
                  ),
                ),
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'About app',
                  subtitle: 'Version, help and Jerman Technology',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const StudioAboutPage(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              color: studioGreen,
              letterSpacing: 1.1,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Material(
          color: studioSurface,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: studioGreen, size: 21),
      title: Text(
        title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 9, color: studioMuted),
      ),
      trailing:
          trailing ??
          (onTap == null
              ? null
              : const Icon(
                  Icons.chevron_right_rounded,
                  color: studioMuted,
                  size: 19,
                )),
    );
  }
}

class StudioAboutPage extends StatelessWidget {
  const StudioAboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: studioBackground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            const StudioHeader(title: 'About', showBack: true),
            const SizedBox(height: 20),
            Container(
              height: 270,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: studioLine),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF102717), Color(0xFF030704)],
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    bottom: -20,
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 230,
                      color: studioGreen.withValues(alpha: .13),
                    ),
                  ),
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StudioBrandMark(size: 94),
                      SizedBox(height: 14),
                      Text(
                        'JERMAN',
                        style: TextStyle(
                          fontSize: 29,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.2,
                        ),
                      ),
                      Text(
                        'CAMERA STUDIO',
                        style: TextStyle(
                          color: studioGreen,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .8,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Innovating Today, Creating Tomorrow',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const _AboutTile(
              icon: Icons.language_rounded,
              title: 'JERMAN TECHNOLOGY',
              subtitle: 'www.jermantechnology.co.tz',
            ),
            const _AboutTile(
              icon: Icons.camera_alt_outlined,
              title: 'Made for moments',
              subtitle: 'A camera and creative studio for capturing and editing on Android.',
            ),
            const _AboutTile(
              icon: Icons.info_outline_rounded,
              title: 'Version',
              subtitle: 'Jerman Camera Studio 1.0.0',
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutTile extends StatelessWidget {
  const _AboutTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: studioSurface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(icon, color: studioGreen),
        title: Text(
          title,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: studioMuted, fontSize: 10),
        ),
      ),
    );
  }
}

class StudioPhotoEditorPage extends StatefulWidget {
  const StudioPhotoEditorPage({
    super.key,
    required this.media,
    required this.onSaved,
  });

  final StudioMedia media;
  final ValueChanged<StudioMedia> onSaved;

  @override
  State<StudioPhotoEditorPage> createState() => _StudioPhotoEditorPageState();
}

class _StudioPhotoEditorPageState extends State<StudioPhotoEditorPage> {
  static const _graphicsModes = [
    _GraphicsMode('smart', 'Smart', Icons.auto_awesome_rounded),
    _GraphicsMode('hd', 'HD 2×', Icons.hd_rounded),
    _GraphicsMode('restore', 'Restore', Icons.healing_rounded),
    _GraphicsMode('cinematic', 'Cinema', Icons.movie_filter_rounded),
  ];

  String _selectedMode = 'smart';
  double _brightness = 1;
  double _contrast = 1;
  double _saturation = 1;
  double _cropRatio = -1;
  int _rotation = 0;
  String _adjustment = 'Brightness';
  bool _isShowingOriginal = false;
  bool _watermark = false;
  bool _defaultWatermark = false;
  bool _isSaving = false;
  bool _isAnalyzing = true;
  bool _isPreviewProcessing = true;
  Map<String, Object>? _analysis;
  Uint8List? _previewBytes;
  String? _previewError;
  Timer? _previewTimer;
  int _previewRevision = 0;

  double get _adjustmentValue => switch (_adjustment) {
    'Brightness' => _brightness,
    'Contrast' => _contrast,
    _ => _saturation,
  };

  @override
  void initState() {
    super.initState();
    unawaited(_loadPhotoSettings());
    unawaited(_analyzeCurrentPhoto());
    _queuePreview();
  }

  Future<void> _analyzeCurrentPhoto() async {
    setState(() => _isAnalyzing = true);
    try {
      final analysis = await compute<Map<String, Object>, Map<String, Object>>(
        analyzePhoto,
        {'path': widget.media.path},
      );
      if (!mounted) return;
      setState(() {
        _analysis = analysis;
        _isAnalyzing = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      _showEditorMessage('Photo analysis failed: $error');
    }
  }

  void _selectGraphicsMode(String mode) {
    setState(() {
      _selectedMode = mode;
      if (mode == 'cinematic') _adjustment = 'Contrast';
    });
    _queuePreview();
  }

  Map<String, Object> _processingSettings({int? previewMaxDimension}) {
    final settings = <String, Object>{
      'path': widget.media.path,
      'mode': _selectedMode,
      'brightness': _brightness,
      'contrast': _contrast,
      'saturation': _saturation,
      'hue': 0.0,
      'rotation': _rotation,
      'cropRatio': _cropRatio,
      'watermark': _watermark,
    };
    if (previewMaxDimension case final dimension?) {
      settings['previewMaxDimension'] = dimension;
    }
    return settings;
  }

  void _queuePreview() {
    _previewTimer?.cancel();
    final revision = ++_previewRevision;
    setState(() {
      _isPreviewProcessing = true;
      _previewError = null;
    });
    _previewTimer = Timer(const Duration(milliseconds: 220), () {
      unawaited(_renderPreview(revision));
    });
  }

  Future<void> _renderPreview(int revision) async {
    try {
      final bytes = await compute<Map<String, Object>, Uint8List>(
        processPhoto,
        _processingSettings(previewMaxDimension: 900),
      );
      if (!mounted || revision != _previewRevision) return;
      setState(() {
        _previewBytes = bytes;
        _isPreviewProcessing = false;
      });
    } catch (error) {
      if (!mounted || revision != _previewRevision) return;
      setState(() {
        _previewError = '$error';
        _isPreviewProcessing = false;
      });
    }
  }

  Widget _buildAnalysisSummary() {
    final analysis = _analysis;
    final luminance = analysis?['averageLuminance'] as double?;
    final recommendedMode = analysis?['recommendation'] as String?;
    final imageSize = analysis == null
        ? 'Analyzing image…'
        : '${analysis['width']} × ${analysis['height']}';
    final lighting = luminance == null
        ? ''
        : luminance < 95
        ? 'Low light'
        : luminance > 178
        ? 'Bright'
        : 'Balanced light';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: studioSurface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: studioLine),
      ),
      child: Row(
        children: [
          if (_isAnalyzing)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: studioGreen,
              ),
            )
          else
            const Icon(Icons.analytics_outlined, color: studioGreen, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              [
                imageSize,
                if (lighting.isNotEmpty) lighting,
                if (recommendedMode != null)
                  'Suggested: ${_modeLabel(recommendedMode)}',
              ].join('  ·  '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: studioMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPhotoSettings() async {
    try {
      final settings = await MediaLibrary.loadSettings();
      if (mounted) {
        setState(() {
          _watermark = settings.addWatermark;
          _defaultWatermark = settings.addWatermark;
        });
        _queuePreview();
      }
    } catch (error) {
      if (mounted) _showEditorMessage('Settings could not be loaded: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: studioBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 5, 14, 12),
          child: Column(
            children: [
              StudioHeader(
                title: 'Photo Editor',
                showBack: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Reset edits',
                      onPressed: _isSaving ? null : _resetEdits,
                      icon: const Icon(Icons.undo_rounded),
                    ),
                    FilledButton(
                      onPressed: _isSaving ? null : _saveEditedPhoto,
                      style: FilledButton.styleFrom(
                        backgroundColor: studioGreen,
                        foregroundColor: studioBackground,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        minimumSize: const Size(52, 36),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Save',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 7),
              Expanded(
                child: GestureDetector(
                  onLongPressStart: (_) =>
                      setState(() => _isShowingOriginal = true),
                  onLongPressEnd: (_) =>
                      setState(() => _isShowingOriginal = false),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: double.infinity,
                      color: studioSurface,
                      alignment: Alignment.center,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_cropRatio > 0 && !_isShowingOriginal)
                            AspectRatio(
                              aspectRatio: _cropRatio,
                              child: _photoPreview(),
                            )
                          else
                            _photoPreview(),
                          Positioned(
                            left: 12,
                            top: 12,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                child: Text(
                                  _isShowingOriginal
                                      ? 'ORIGINAL'
                                      : 'EDITED · ${_modeLabel(_selectedMode).toUpperCase()}',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (_isPreviewProcessing)
                            const Positioned(
                              right: 12,
                              top: 12,
                              child: SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: studioGreen,
                                ),
                              ),
                            ),
                          if (_previewError != null)
                            Positioned(
                              left: 12,
                              right: 12,
                              bottom: 12,
                              child: Text(
                                'Preview could not be processed: $_previewError',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildAnalysisSummary(),
              const SizedBox(height: 7),
              SizedBox(
                height: 68,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _graphicsModes.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 9),
                  itemBuilder: (context, index) {
                    final mode = _graphicsModes[index];
                    return _GraphicsModeCard(
                      mode: mode,
                      selected: _selectedMode == mode.id,
                      onTap: () => _selectGraphicsMode(mode.id),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 1),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _modeDescription(_selectedMode),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: studioMuted, fontSize: 9),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  DropdownButton<String>(
                    value: _adjustment,
                    underline: const SizedBox.shrink(),
                    dropdownColor: studioSurface,
                    style: const TextStyle(color: studioMuted, fontSize: 10),
                    items: const [
                      DropdownMenuItem(
                        value: 'Brightness',
                        child: Text('Bright'),
                      ),
                      DropdownMenuItem(
                        value: 'Contrast',
                        child: Text('Contrast'),
                      ),
                      DropdownMenuItem(
                        value: 'Saturation',
                        child: Text('Color'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _adjustment = value);
                    },
                  ),
                  Expanded(
                    child: Slider(
                      value: _adjustmentValue,
                      min: _adjustment == 'Brightness' ? .5 : .5,
                      max: _adjustment == 'Brightness' ? 1.5 : 1.7,
                      onChanged: (value) {
                        setState(() {
                          switch (_adjustment) {
                            case 'Brightness':
                              _brightness = value;
                            case 'Contrast':
                              _contrast = value;
                            case 'Saturation':
                              _saturation = value;
                          }
                        });
                        _queuePreview();
                      },
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _EditorTool(
                    icon: Icons.crop_rounded,
                    label: 'Crop',
                    onTap: _chooseCropRatio,
                  ),
                  _EditorTool(
                    icon: Icons.rotate_right_rounded,
                    label: 'Rotate',
                    onTap: () {
                      setState(() => _rotation = (_rotation + 1) % 4);
                      _queuePreview();
                    },
                  ),
                  _EditorTool(
                    icon: Icons.tune_rounded,
                    label: 'Adjust',
                    selected: true,
                    onTap: _chooseAdjustment,
                  ),
                  _EditorTool(
                    icon: Icons.auto_awesome_outlined,
                    label: 'Analyze',
                    onTap: _analyzeCurrentPhoto,
                  ),
                  _EditorTool(
                    icon: Icons.branding_watermark_outlined,
                    label: 'Watermark',
                    selected: _watermark,
                    onTap: () {
                      setState(() => _watermark = !_watermark);
                      _queuePreview();
                    },
                  ),
                ],
              ),
              const Text(
                'HD and Restore are offline filters, not AI models. AI portrait masking is not available yet.',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: studioMuted, fontSize: 9),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveEditedPhoto() async {
    setState(() => _isSaving = true);
    try {
      final bytes = await compute<Map<String, Object>, Uint8List>(
        processPhoto,
        _processingSettings(),
      );
      final saved = await MediaLibrary.addEditedPhoto(bytes);
      widget.onSaved(saved);
      try {
        var hasAccess = await Gal.hasAccess();
        if (!hasAccess) hasAccess = await Gal.requestAccess();
        if (hasAccess) {
          await Gal.putImage(saved.path);
        }
      } catch (error) {
        if (mounted) {
          _showEditorMessage(
            'Edited photo is saved in Jerman Gallery; device gallery save failed: $error',
          );
        }
        return;
      }
      if (mounted) _showEditorMessage('Edited photo saved to your gallery.');
    } catch (error) {
      if (mounted) _showEditorMessage('Could not save edited photo: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _photoPreview() {
    if (_isShowingOriginal || _previewBytes == null) {
      return Image.file(
        File(widget.media.path),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const _EmptyState(
          icon: Icons.broken_image_outlined,
          title: 'Photo unavailable',
          message: 'This image could not be opened.',
        ),
      );
    }
    return Image.memory(
      _previewBytes!,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) => const _EmptyState(
        icon: Icons.broken_image_outlined,
        title: 'Preview unavailable',
        message: 'The processed preview could not be displayed.',
      ),
    );
  }

  Future<void> _chooseCropRatio() async {
    const ratios = <String, double>{
      'Original': -1,
      'Square': 1,
      'Portrait 4:5': .8,
      'Landscape 16:9': 16 / 9,
    };
    final selected = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: studioSurface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in ratios.entries)
              ListTile(
                title: Text(entry.key),
                trailing: _cropRatio == entry.value
                    ? const Icon(Icons.check_rounded, color: studioGreen)
                    : null,
                onTap: () => Navigator.pop(context, entry.value),
              ),
          ],
        ),
      ),
    );
    if (selected != null) {
      setState(() => _cropRatio = selected);
      _queuePreview();
    }
  }

  void _chooseAdjustment() {
    setState(() => _adjustment = 'Brightness');
  }

  void _resetEdits() {
    setState(() {
      _selectedMode = 'smart';
      _brightness = 1;
      _contrast = 1;
      _saturation = 1;
      _cropRatio = -1;
      _rotation = 0;
      _watermark = _defaultWatermark;
      _isShowingOriginal = false;
    });
    _queuePreview();
  }

  void _showEditorMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _GraphicsMode {
  const _GraphicsMode(this.id, this.label, this.icon);

  final String id;
  final String label;
  final IconData icon;
}

String _modeLabel(String id) => switch (id) {
  'smart' => 'Smart Enhance',
  'hd' => 'HD 2×',
  'restore' => 'Restore',
  'cinematic' => 'Cinematic',
  _ => id,
};

String _modeDescription(String id) => switch (id) {
  'smart' => 'Balances exposure, contrast and color from image analysis.',
  'hd' => 'Cubic resize up to 2×; no AI detail reconstruction.',
  'restore' => 'Mild offline denoise and sharpening for apparent clarity.',
  'cinematic' => 'Adds contrast and a restrained cinematic color grade.',
  _ => '',
};

class _GraphicsModeCard extends StatelessWidget {
  const _GraphicsModeCard({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final _GraphicsMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(13),
    child: Container(
      width: 82,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF15351F) : studioSurface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: selected ? studioGreen : studioLine),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            mode.icon,
            color: selected ? studioGreen : studioMuted,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            mode.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? studioGreen : Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}

class StudioVideoEditorPage extends StatefulWidget {
  const StudioVideoEditorPage({
    super.key,
    required this.media,
    required this.onProjectSaved,
    required this.onMediaExported,
  });

  final StudioMedia media;
  final ValueChanged<StudioProject> onProjectSaved;
  final ValueChanged<StudioMedia> onMediaExported;

  @override
  State<StudioVideoEditorPage> createState() => _StudioVideoEditorPageState();
}

class _StudioVideoEditorPageState extends State<StudioVideoEditorPage> {
  VideoPlayerController? _controller;
  String? _playerError;
  bool _loading = true;
  double _speed = 1;
  String _transition = 'None';
  String _titleText = '';
  String _musicTrack = 'Original audio';
  RangeValues _trimRange = const RangeValues(0, 1);
  int? _splitPointMs;
  int _lastTimelineRefreshMs = -1000;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initializePlayer());
  }

  @override
  void dispose() {
    unawaited(_controller?.dispose());
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    final controller = VideoPlayerController.file(File(widget.media.path));
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      _trimRange = RangeValues(
        0,
        controller.value.duration.inMilliseconds.toDouble(),
      );
      controller.addListener(_onPlaybackPositionChanged);
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (error) {
      await controller.dispose();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _playerError = 'This video could not be played: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: studioBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 5, 14, 10),
          child: Column(
            children: [
              StudioHeader(
                title: 'Video Editor',
                showBack: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Save project',
                      onPressed: _isExporting ? null : _saveProject,
                      icon: const Icon(Icons.bookmark_add_outlined),
                    ),
                    FilledButton(
                      onPressed: _isExporting ? null : _exportVideo,
                      style: FilledButton.styleFrom(
                        backgroundColor: studioGreen,
                        foregroundColor: studioBackground,
                        padding: const EdgeInsets.symmetric(horizontal: 13),
                        minimumSize: const Size(56, 36),
                      ),
                      child: _isExporting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Export',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 7),
              Expanded(flex: 5, child: _buildVideoPreview(controller)),
              const SizedBox(height: 11),
              _buildPlaybackControls(controller),
              const SizedBox(height: 11),
              _buildTimeline(controller),
              const SizedBox(height: 10),
              _buildEditTools(),
              const SizedBox(height: 9),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Transitions  ›  $_transition',
                  style: const TextStyle(
                    color: studioMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 51,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final transition in const [
                      'None',
                      'Fade',
                      'Slide',
                      'Zoom',
                      'Spin',
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _TransitionChip(
                          transition: transition,
                          selected: _transition == transition,
                          onTap: () => setState(() => _transition = transition),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Export renders trimmed MP4 clips. Music, titles, speed and transitions remain project settings.',
                textAlign: TextAlign.center,
                style: TextStyle(color: studioMuted, fontSize: 9),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onPlaybackPositionChanged() {
    final controller = _controller;
    if (!mounted || controller == null) return;
    final positionMs = controller.value.position.inMilliseconds;
    if (positionMs - _lastTimelineRefreshMs < 150 &&
        positionMs >= _lastTimelineRefreshMs) {
      return;
    }
    _lastTimelineRefreshMs = positionMs;
    setState(() {});
  }

  Widget _buildVideoPreview(VideoPlayerController? controller) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: studioGreen));
    }
    if (_playerError != null || controller == null) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: studioSurface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: _EmptyState(
          icon: Icons.video_file_outlined,
          title: 'Preview unavailable',
          message: _playerError ?? 'Video could not be opened.',
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),
            if (_titleText.isNotEmpty)
              Positioned(
                left: 12,
                right: 12,
                bottom: 15,
                child: Text(
                  _titleText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    shadows: [Shadow(blurRadius: 6, color: Colors.black)],
                  ),
                ),
              ),
            IconButton.filled(
              onPressed: () => setState(
                () => controller.value.isPlaying
                    ? controller.pause()
                    : controller.play(),
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: .6),
                foregroundColor: Colors.white,
                fixedSize: const Size(54, 54),
              ),
              icon: Icon(
                controller.value.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaybackControls(VideoPlayerController? controller) {
    final position = controller?.value.position ?? Duration.zero;
    final duration = controller?.value.duration ?? Duration.zero;
    return Row(
      children: [
        IconButton(
          tooltip: 'Previous clip',
          onPressed: () => _showMessage('This project has one video clip.'),
          icon: const Icon(Icons.skip_previous_rounded),
        ),
        IconButton(
          tooltip: 'Play or pause',
          onPressed: controller == null || !controller.value.isInitialized
              ? null
              : () => setState(
                  () => controller.value.isPlaying
                      ? controller.pause()
                      : controller.play(),
                ),
          icon: Icon(
            controller?.value.isPlaying == true
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            color: studioGreen,
          ),
        ),
        IconButton(
          tooltip: 'Split clip',
          onPressed: _splitClipAtPlayhead,
          icon: const Icon(Icons.content_cut_rounded),
        ),
        const Spacer(),
        Text(
          '${_formatVideoTime(position)} / ${_formatVideoTime(duration)}',
          style: const TextStyle(color: studioMuted, fontSize: 10),
        ),
        const Spacer(),
        Text(
          '${_speed.toStringAsFixed(_speed == 1 ? 0 : 1)}x',
          style: const TextStyle(
            color: studioGreen,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline(VideoPlayerController? controller) {
    final duration = controller?.value.duration ?? Duration.zero;
    final totalMilliseconds = duration.inMilliseconds;
    final position = controller?.value.position ?? Duration.zero;
    final progress = totalMilliseconds > 0
        ? position.inMilliseconds / totalMilliseconds
        : 0.0;
    final rangeStart = _trimRange.start
        .clamp(0, totalMilliseconds.toDouble())
        .toDouble();
    final rangeEnd = _trimRange.end
        .clamp(rangeStart, totalMilliseconds.toDouble())
        .toDouble();
    return Column(
      children: [
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: studioSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: studioLine),
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              const Icon(
                Icons.movie_creation_outlined,
                color: studioGreen,
                size: 17,
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: CustomPaint(
                        painter: _TimelinePainter(progress: progress),
                        child: const SizedBox.expand(),
                      ),
                    ),
                    Slider(
                      value: progress.clamp(0, 1),
                      onChanged: totalMilliseconds <= 0 || controller == null
                          ? null
                          : (value) => controller.seekTo(
                              Duration(
                                milliseconds: (value * totalMilliseconds)
                                    .round(),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              if (_splitPointMs != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '1',
                    style: const TextStyle(color: studioGreen, fontSize: 10),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Text(
              'Trim range',
              style: TextStyle(color: studioMuted, fontSize: 9),
            ),
            Expanded(
              child: RangeSlider(
                values: RangeValues(rangeStart, rangeEnd),
                min: 0,
                max: totalMilliseconds > 0 ? totalMilliseconds.toDouble() : 1,
                onChanged: totalMilliseconds < 500
                    ? null
                    : (values) {
                        setState(() {
                          _trimRange = values;
                          final split = _splitPointMs;
                          if (split != null &&
                              (split <= values.start || split >= values.end)) {
                            _splitPointMs = null;
                          }
                        });
                      },
              ),
            ),
            Text(
              '${_formatVideoTime(Duration(milliseconds: rangeStart.round()))}–'
              '${_formatVideoTime(Duration(milliseconds: rangeEnd.round()))}',
              style: const TextStyle(color: studioMuted, fontSize: 9),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatVideoTime(position),
              style: const TextStyle(color: studioMuted, fontSize: 9),
            ),
            Text(
              _formatVideoTime(duration),
              style: const TextStyle(color: studioMuted, fontSize: 9),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditTools() {
    return Row(
      children: [
        _EditorTool(
          icon: Icons.content_cut_rounded,
          label: 'Trim',
          selected: true,
          onTap: () =>
              _showMessage('Set the trim start and end on the range slider.'),
        ),
        _EditorTool(
          icon: Icons.call_split_rounded,
          label: 'Split',
          onTap: _splitClipAtPlayhead,
        ),
        _EditorTool(
          icon: Icons.speed_rounded,
          label: 'Speed',
          onTap: _chooseSpeed,
        ),
        _EditorTool(
          icon: Icons.music_note_rounded,
          label: 'Music',
          onTap: _chooseMusic,
        ),
        _EditorTool(
          icon: Icons.title_rounded,
          label: 'Text',
          onTap: _editTitle,
        ),
      ],
    );
  }

  void _splitClipAtPlayhead() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final positionMs = controller.value.position.inMilliseconds;
    final startMs = _trimRange.start.round();
    final endMs = _trimRange.end.round();
    if (positionMs - startMs < 500 || endMs - positionMs < 500) {
      _showMessage(
        'Move the playhead inside the selected trim range to split.',
      );
      return;
    }
    setState(() {
      _splitPointMs = _splitPointMs == positionMs ? null : positionMs;
    });
  }

  Future<void> _exportVideo() async {
    final startMs = _trimRange.start.round();
    final endMs = _trimRange.end.round();
    if (endMs - startMs < 500) {
      _showMessage('Choose a trim range of at least half a second.');
      return;
    }

    final splitPoint = _splitPointMs;
    final boundaries = <int>[
      startMs,
      if (splitPoint != null && splitPoint > startMs && splitPoint < endMs)
        splitPoint,
      endMs,
    ];
    setState(() => _isExporting = true);
    var exportedCount = 0;
    var deviceGalleryCount = 0;
    String? gallerySaveError;
    try {
      for (var index = 0; index < boundaries.length - 1; index++) {
        final outputPath = await _studioMediaChannel.invokeMethod<String>(
          'trimVideo',
          {
            'path': widget.media.path,
            'startMs': boundaries[index],
            'endMs': boundaries[index + 1],
          },
        );
        if (outputPath == null || outputPath.isEmpty) {
          throw StateError('The video exporter returned no output file.');
        }
        try {
          final media = await MediaLibrary.addCapture(
            outputPath,
            isVideo: true,
          );
          widget.onMediaExported(media);
          exportedCount++;
          try {
            var hasAccess = await Gal.hasAccess();
            if (!hasAccess) hasAccess = await Gal.requestAccess();
            if (!hasAccess) {
              gallerySaveError ??= 'gallery access was denied';
            } else {
              await Gal.putVideo(media.path);
              deviceGalleryCount++;
            }
          } catch (error) {
            gallerySaveError = '$error';
          }
        } finally {
          final temporaryOutput = File(outputPath);
          if (await temporaryOutput.exists()) {
            await temporaryOutput.delete();
          }
        }
      }
      if (mounted) {
        final gallerySaveFailures = exportedCount - deviceGalleryCount;
        final deviceMessage = gallerySaveFailures == 0
            ? ' and device gallery'
            : ', but $gallerySaveFailures could not be copied to the device gallery (${gallerySaveError ?? 'gallery save failed'})';
        _showMessage(
          'Exported $exportedCount clip${exportedCount == 1 ? '' : 's'} to Jerman Gallery$deviceMessage.',
        );
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          exportedCount == 0
              ? 'Video export failed: $error'
              : 'Export stopped after $exportedCount clip${exportedCount == 1 ? '' : 's'}: $error',
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _chooseSpeed() async {
    const speeds = [0.5, 0.75, 1.0, 1.5, 2.0];
    final selected = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: studioSurface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Playback speed',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            for (final speed in speeds)
              ListTile(
                title: Text('${speed}x'),
                trailing: _speed == speed
                    ? const Icon(Icons.check_rounded, color: studioGreen)
                    : null,
                onTap: () => Navigator.pop(context, speed),
              ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    setState(() => _speed = selected);
    await _controller?.setPlaybackSpeed(selected);
  }

  Future<void> _chooseMusic() async {
    final selection = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: studioSurface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final track in const [
              'Original audio',
              'Ambient',
              'Cinematic',
              'Upbeat',
            ])
              ListTile(
                leading: const Icon(
                  Icons.music_note_rounded,
                  color: studioGreen,
                ),
                title: Text(track),
                trailing: _musicTrack == track
                    ? const Icon(Icons.check_rounded, color: studioGreen)
                    : null,
                onTap: () => Navigator.pop(context, track),
              ),
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 0, 18, 14),
              child: Text(
                'Music is saved in your project settings. Audio mixing is not available yet.',
                style: TextStyle(color: studioMuted, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
    if (selection != null) setState(() => _musicTrack = selection);
  }

  Future<void> _editTitle() async {
    final input = TextEditingController(text: _titleText);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: studioSurface,
        title: const Text('Add a title'),
        content: TextField(
          controller: input,
          maxLength: 48,
          decoration: const InputDecoration(hintText: 'Type your title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, input.text.trim()),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    input.dispose();
    if (result != null) setState(() => _titleText = result);
  }

  Future<void> _saveProject() async {
    try {
      final project = StudioProject(
        id: '${widget.media.path}:${DateTime.now().microsecondsSinceEpoch}',
        mediaPath: widget.media.path,
        isVideo: true,
        filter:
            '$_transition · $_musicTrack · ${_splitPointMs == null ? 0 : 1} split',
        speed: _speed,
        title: _titleText.isEmpty ? 'Video Project' : _titleText,
        savedAt: DateTime.now(),
      );
      await MediaLibrary.saveProject(project);
      widget.onProjectSaved(project);
      if (mounted) {
        _showMessage('Project saved. Open Projects to continue editing.');
      }
    } catch (error) {
      if (mounted) _showMessage('Project could not be saved: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _TimelinePainter extends CustomPainter {
  const _TimelinePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0xFF36523B)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final activeLine = Paint()
      ..color = studioGreen
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    canvas.drawLine(Offset(0, y), Offset(size.width * progress, y), activeLine);
    for (var index = 0; index < 14; index++) {
      final x = size.width * index / 13;
      canvas.drawCircle(
        Offset(x, y),
        2.5,
        Paint()..color = const Color(0xFF9BBC9F),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _TransitionChip extends StatelessWidget {
  const _TransitionChip({
    required this.transition,
    required this.selected,
    required this.onTap,
  });

  final String transition;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 62,
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: studioSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? studioGreen : studioLine),
        ),
        child: Column(
          children: [
            Icon(
              switch (transition) {
                'Fade' => Icons.gradient_rounded,
                'Slide' => Icons.swap_horiz_rounded,
                'Zoom' => Icons.zoom_in_rounded,
                'Spin' => Icons.rotate_right_rounded,
                _ => Icons.block_rounded,
              },
              color: selected ? studioGreen : studioMuted,
              size: 19,
            ),
            const SizedBox(height: 2),
            Text(transition, style: const TextStyle(fontSize: 8)),
          ],
        ),
      ),
    );
  }
}

class _EditorTool extends StatelessWidget {
  const _EditorTool({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? studioGreen : const Color(0xFFE1E9E2),
                size: 19,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: selected ? studioGreen : studioMuted,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? studioGreen : studioSurface,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? studioBackground : studioMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _MediaThumbnail extends StatelessWidget {
  const _MediaThumbnail({required this.media, required this.width});

  final StudioMedia media;
  final double width;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: width,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MediaPreview(media: media),
            if (media.isVideo)
              const Center(
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class MediaPreview extends StatelessWidget {
  const MediaPreview({super.key, required this.media});

  final StudioMedia media;

  @override
  Widget build(BuildContext context) {
    if (media.isVideo) {
      return Container(
        color: const Color(0xFF13231A),
        child: const Center(
          child: Icon(Icons.movie_outlined, color: studioGreen, size: 28),
        ),
      );
    }
    return Image.file(
      File(media.path),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: studioSurfaceLight,
        child: const Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: studioMuted,
            size: 25,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: studioGreen, size: 42),
            const SizedBox(height: 13),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: studioMuted,
                fontSize: 11,
                height: 1.45,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 14), action!],
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: studioGreen),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: studioMuted),
      onTap: onTap,
    );
  }
}

String _clockLabel(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:'
    '${date.minute.toString().padLeft(2, '0')}';

String _formatVideoTime(Duration duration) {
  final minutes = duration.inMinutes.toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
