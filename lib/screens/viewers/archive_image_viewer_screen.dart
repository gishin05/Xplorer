import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/archive_entry_item.dart';
import '../../providers/file_explorer_provider.dart';
import '../../theme/colors.dart';
import '../../utils/file_utils.dart';

class ArchiveImageViewerScreen extends ConsumerStatefulWidget {
  final String archivePath;
  final String archiveName;
  final List<ArchiveEntryItem> imageEntries;
  final int initialIndex;
  final String? password;

  const ArchiveImageViewerScreen({
    super.key,
    required this.archivePath,
    required this.archiveName,
    required this.imageEntries,
    required this.initialIndex,
    this.password,
  });

  @override
  ConsumerState<ArchiveImageViewerScreen> createState() => _ArchiveImageViewerScreenState();
}

class _ArchiveImageViewerScreenState extends ConsumerState<ArchiveImageViewerScreen> {
  late int _currentIndex;
  late PageController _pageController;
  final Map<int, String> _extractedCache = {};
  final Map<int, bool> _loadingMap = {};
  final Map<int, String?> _errorMap = {};
  final TransformationController _transformController = TransformationController();
  int _quarterTurns = 0;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.imageEntries.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
    _extractEntryIfNeeded(_currentIndex);
    _prefetchAdjacent(_currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  ArchiveEntryItem get _currentEntry => widget.imageEntries[_currentIndex];

  void _prefetchAdjacent(int index) {
    if (index + 1 < widget.imageEntries.length) {
      _extractEntryIfNeeded(index + 1);
    }
    if (index - 1 >= 0) {
      _extractEntryIfNeeded(index - 1);
    }
  }

  Future<void> _extractEntryIfNeeded(int index) async {
    if (_extractedCache.containsKey(index) || _loadingMap[index] == true) {
      return;
    }

    final entry = widget.imageEntries[index];
    _loadingMap[index] = true;

    try {
      final cacheDir = await getTemporaryDirectory();
      final safeArchive = widget.archiveName.replaceAll(RegExp(r'[^\w.-]'), '_');
      final safeName = entry.name.replaceAll(RegExp(r'[^\w.-]'), '_');
      final destPath = '${cacheDir.path}/zip_img_${safeArchive}_$safeName';

      final file = File(destPath);
      if (await file.exists() && await file.length() > 0) {
        if (mounted) {
          setState(() {
            _extractedCache[index] = destPath;
            _loadingMap[index] = false;
          });
        }
        return;
      }

      final extracted = await ref.read(platformServiceProvider).extractArchiveEntry(
            archivePath: widget.archivePath,
            entryName: entry.name,
            destinationPath: destPath,
            password: widget.password,
          );

      if (mounted) {
        setState(() {
          if (extracted != null) {
            _extractedCache[index] = extracted;
          } else {
            _errorMap[index] = 'Failed to extract entry';
          }
          _loadingMap[index] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMap[index] = e.toString();
          _loadingMap[index] = false;
        });
      }
    }
  }

  void _rotate() {
    setState(() {
      _quarterTurns = (_quarterTurns + 1) % 4;
    });
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
    _quarterTurns = 0;
  }

  void _showInfoSheet() {
    final entry = _currentEntry;
    final basename = entry.name.split('/').last;
    final ext = basename.split('.').last.toUpperCase();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Archive Image Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 14),
            _infoRow('File Name', basename),
            _infoRow('Archive', widget.archiveName),
            _infoRow('Entry Path', entry.name),
            _infoRow('Size', FileUtils.formatBytes(entry.uncompressedSize)),
            _infoRow('Format', ext),
            _infoRow('Position', '${_currentIndex + 1} of ${widget.imageEntries.length}'),
            if (entry.isEncrypted) _infoRow('Security', 'Encrypted (Password Protected)'),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final basename = _currentEntry.name.split('/').last;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageEntries.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
                _resetZoom();
              });
              _extractEntryIfNeeded(index);
              _prefetchAdjacent(index);
            },
            itemBuilder: (context, index) {
              final cachedPath = _extractedCache[index];
              final isLoading = _loadingMap[index] ?? false;
              final error = _errorMap[index];

              if (isLoading || (cachedPath == null && error == null)) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white70, strokeWidth: 2.5),
                      SizedBox(height: 14),
                      Text(
                        'Extracting image from archive...',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }

              if (error != null || cachedPath == null) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.broken_image_rounded, size: 64, color: AppColors.textMuted),
                      const SizedBox(height: 10),
                      Text(
                        error ?? 'Unable to extract image',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.surfaceGlass),
                        onPressed: () => _extractEntryIfNeeded(index),
                        child: const Text('Retry', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              }

              final file = File(cachedPath);
              return GestureDetector(
                onTap: () => setState(() => _showControls = !_showControls),
                onDoubleTap: _resetZoom,
                child: Center(
                  child: RotatedBox(
                    quarterTurns: index == _currentIndex ? _quarterTurns : 0,
                    child: InteractiveViewer(
                      transformationController: index == _currentIndex ? _transformController : null,
                      minScale: 0.5,
                      maxScale: 6.0,
                      clipBehavior: Clip.none,
                      child: Image.file(
                        file,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.broken_image_rounded, size: 64, color: AppColors.textMuted),
                              SizedBox(height: 8),
                              Text('Unable to render image', style: TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Top App Bar Controls
          if (_showControls)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 4,
                  left: 8,
                  right: 8,
                  bottom: 8,
                ),
                color: Colors.black.withValues(alpha: 0.75),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            basename,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                          Text(
                            '${_currentIndex + 1} / ${widget.imageEntries.length}  •  ${widget.archiveName}',
                            style: const TextStyle(fontSize: 11, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.rotate_right_rounded, color: Colors.white),
                      tooltip: 'Rotate 90°',
                      onPressed: _rotate,
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
                      tooltip: 'Image Info',
                      onPressed: _showInfoSheet,
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_new_rounded, color: Colors.white),
                      tooltip: 'Open with App',
                      onPressed: () {
                        final cached = _extractedCache[_currentIndex];
                        if (cached != null) {
                          ref.read(platformServiceProvider).openFileWithSystemApp(cached);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

          // Bottom Position Indicator
          if (_showControls && widget.imageEntries.length > 1)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.imageEntries.length}',
                    style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
