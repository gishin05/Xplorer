import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/file_item.dart';
import '../../providers/file_explorer_provider.dart';
import '../../theme/colors.dart';

class PdfViewerScreen extends ConsumerStatefulWidget {
  final FileItem item;

  const PdfViewerScreen({super.key, required this.item});

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  final PageController _pageController = PageController();
  final Map<int, Uint8List> _pageCache = {};
  final Map<int, String> _pageNotes = {};

  int _pageCount = 0;
  int _currentPage = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPdfInfo();
  }

  Future<void> _loadPdfInfo() async {
    final service = ref.read(platformServiceProvider);
    try {
      final count = await service.getPdfPageCount(widget.item.path);
      if (mounted) {
        setState(() {
          _pageCount = count;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<Uint8List?> _getPageBytes(int pageIndex) async {
    if (_pageCache.containsKey(pageIndex)) {
      return _pageCache[pageIndex];
    }
    final service = ref.read(platformServiceProvider);
    final bytes = await service.renderPdfPage(widget.item.path, pageIndex);
    if (bytes != null) {
      _pageCache[pageIndex] = bytes;
    }
    return bytes;
  }

  void _jumpToPageDialog() {
    final controller = TextEditingController(text: '${_currentPage + 1}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceGlass,
        title: const Text('Jump to Page', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Page number (1 - $_pageCount)',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.accentTeal),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentTeal, foregroundColor: Colors.black),
            onPressed: () {
              final target = int.tryParse(controller.text.trim());
              if (target != null && target >= 1 && target <= _pageCount) {
                _pageController.jumpToPage(target - 1);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  void _addNoteDialog() {
    final controller = TextEditingController(text: _pageNotes[_currentPage] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceGlass,
        title: Text('Page ${_currentPage + 1} Note', style: const TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          maxLines: 4,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Add an annotation or bookmark note...',
            hintStyle: TextStyle(color: AppColors.textMuted),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentTeal, foregroundColor: Colors.black),
            onPressed: () {
              setState(() {
                if (controller.text.trim().isEmpty) {
                  _pageNotes.remove(_currentPage);
                } else {
                  _pageNotes[_currentPage] = controller.text.trim();
                }
              });
              Navigator.of(ctx).pop();
            },
            child: const Text('Save Note'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.item.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            Text(
              _pageCount > 0 ? 'Page ${_currentPage + 1} of $_pageCount' : widget.item.formattedSize,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          if (_pageCount > 0) ...[
            IconButton(
              icon: const Icon(Icons.pin_invoke_rounded, color: AppColors.textPrimary),
              tooltip: 'Jump to Page',
              onPressed: _jumpToPageDialog,
            ),
            IconButton(
              icon: Icon(
                _pageNotes.containsKey(_currentPage) ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined,
                color: _pageNotes.containsKey(_currentPage) ? AppColors.accentTeal : AppColors.textPrimary,
              ),
              tooltip: 'Page Note',
              onPressed: _addNoteDialog,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded, color: AppColors.textSecondary),
            tooltip: 'Open with PDF App',
            onPressed: () {
              ref.read(platformServiceProvider).openFileWithSystemApp(
                widget.item.path,
                mimeType: 'application/pdf',
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentTeal))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 48),
                        const SizedBox(height: 12),
                        Text('Failed to open PDF: $_error', style: const TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                )
              : _pageCount == 0
                  ? const Center(
                      child: Text('This PDF document has 0 pages', style: TextStyle(color: AppColors.textMuted)),
                    )
                  : Column(
                      children: [
                        if (_pageNotes.containsKey(_currentPage))
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            color: AppColors.accentTeal.withValues(alpha: 0.12),
                            child: Row(
                              children: [
                                const Icon(Icons.bookmark_rounded, size: 16, color: AppColors.accentTeal),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _pageNotes[_currentPage]!,
                                    style: const TextStyle(fontSize: 12, color: AppColors.accentTealLight),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _pageCount,
                            onPageChanged: (idx) => setState(() => _currentPage = idx),
                            itemBuilder: (context, index) {
                              return FutureBuilder<Uint8List?>(
                                future: _getPageBytes(index),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(color: AppColors.accentTeal, strokeWidth: 2),
                                    );
                                  }
                                  final bytes = snapshot.data;
                                  if (bytes == null) {
                                    return const Center(
                                      child: Text('Failed to render page', style: TextStyle(color: AppColors.textMuted)),
                                    );
                                  }

                                  return InteractiveViewer(
                                    minScale: 1.0,
                                    maxScale: 4.0,
                                    child: Center(
                                      child: Container(
                                        margin: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.4),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Image.memory(
                                          bytes,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),

                        // Bottom Navigation Bar
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark,
                            border: Border(top: BorderSide(color: AppColors.glassBorder)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left_rounded),
                                color: _currentPage > 0 ? AppColors.textPrimary : AppColors.textMuted,
                                onPressed: _currentPage > 0
                                    ? () => _pageController.previousPage(
                                          duration: const Duration(milliseconds: 250),
                                          curve: Curves.easeInOut,
                                        )
                                    : null,
                              ),
                              Text(
                                '${_currentPage + 1} / $_pageCount',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right_rounded),
                                color: _currentPage < _pageCount - 1 ? AppColors.textPrimary : AppColors.textMuted,
                                onPressed: _currentPage < _pageCount - 1
                                    ? () => _pageController.nextPage(
                                          duration: const Duration(milliseconds: 250),
                                          curve: Curves.easeInOut,
                                        )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }
}
