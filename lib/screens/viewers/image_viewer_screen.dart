import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/file_item.dart';
import '../../providers/file_explorer_provider.dart';
import '../../theme/colors.dart';

class ImageViewerScreen extends ConsumerStatefulWidget {
  final FileItem item;
  final List<FileItem>? galleryItems;
  final int initialIndex;

  const ImageViewerScreen({
    super.key,
    required this.item,
    this.galleryItems,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends ConsumerState<ImageViewerScreen> {
  late List<FileItem> _items;
  late int _currentIndex;
  late PageController _pageController;
  final TransformationController _transformController = TransformationController();
  int _quarterTurns = 0;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _items = widget.galleryItems != null && widget.galleryItems!.isNotEmpty
        ? List<FileItem>.from(widget.galleryItems!)
        : [widget.item];

    final foundIndex = _items.indexWhere((e) => e.path == widget.item.path);
    _currentIndex = foundIndex != -1 ? foundIndex : widget.initialIndex.clamp(0, _items.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  FileItem get _currentItem => _items[_currentIndex];

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
    final item = _currentItem;
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
              'Image Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 14),
            _infoRow('File Name', item.name),
            _infoRow('Size', item.formattedSize),
            _infoRow('Path', item.path),
            _infoRow('Format', item.extension.toUpperCase()),
            _infoRow('Position', '${_currentIndex + 1} of ${_items.length}'),
            _infoRow('Last Modified', item.lastModified.toString().split('.').first),
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Swipeable PageView with Interactive Zoom per image
          PageView.builder(
            controller: _pageController,
            itemCount: _items.length,
            onPageChanged: (idx) {
              setState(() {
                _currentIndex = idx;
                _resetZoom();
              });
            },
            itemBuilder: (context, index) {
              final item = _items[index];
              final file = File(item.path);

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
                              Text('Unable to load image', style: TextStyle(color: AppColors.textSecondary)),
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
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: 8, right: 8, bottom: 8),
                color: Colors.black.withValues(alpha: 0.7),
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
                            _currentItem.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                          Text(
                            '${_currentIndex + 1} / ${_items.length}  •  ${_currentItem.formattedSize}',
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
                        ref.read(platformServiceProvider).openFileWithSystemApp(
                          _currentItem.path,
                          mimeType: _currentItem.mimeType,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
