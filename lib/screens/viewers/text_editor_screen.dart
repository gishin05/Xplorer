import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/file_item.dart';
import '../../providers/file_explorer_provider.dart';
import '../../theme/colors.dart';

class TextEditorScreen extends ConsumerStatefulWidget {
  final FileItem item;
  final String? initialContent;

  const TextEditorScreen({
    super.key,
    required this.item,
    this.initialContent,
  });

  @override
  ConsumerState<TextEditorScreen> createState() => _TextEditorScreenState();
}

class _TextEditorScreenState extends ConsumerState<TextEditorScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _linesController = ScrollController();

  bool _loading = true;
  bool _saving = false;
  bool _isEditing = false;
  bool _isSearching = false;
  bool _wordWrap = true;
  bool _isDirty = false;
  double _fontSize = 13.0;
  String? _error;
  String _initialContent = '';
  int _searchCount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialContent != null) {
      _initialContent = widget.initialContent!;
      _textController.text = widget.initialContent!;
      _loading = false;
    } else {
      _loadFileContent();
    }
    _scrollController.addListener(_syncScroll);
  }

  void _syncScroll() {
    if (_linesController.hasClients && _linesController.offset != _scrollController.offset) {
      _linesController.jumpTo(_scrollController.offset);
    }
  }

  Future<void> _loadFileContent() async {
    final service = ref.read(platformServiceProvider);
    try {
      final content = await service.readFile(widget.item.path);
      if (mounted) {
        setState(() {
          _initialContent = content;
          _textController.text = content;
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

  Future<void> _saveFile() async {
    if (_saving) return;
    setState(() => _saving = true);
    final service = ref.read(platformServiceProvider);
    try {
      final ok = await service.writeFile(widget.item.path, _textController.text);
      if (mounted) {
        setState(() {
          _saving = false;
          if (ok) {
            _isDirty = false;
            _initialContent = _textController.text;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: ok ? AppColors.accentTeal.withValues(alpha: 0.9) : AppColors.danger,
            content: Text(
              ok ? 'File saved successfully' : 'Failed to save file',
              style: TextStyle(color: ok ? Colors.black : Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Save error: $e'),
          ),
        );
      }
    }
  }

  void _onTextChanged(String text) {
    final dirty = text != _initialContent;
    if (dirty != _isDirty) {
      setState(() => _isDirty = dirty);
    }
    if (_isSearching && _searchController.text.isNotEmpty) {
      _calculateSearchCount(_searchController.text);
    }
  }

  void _calculateSearchCount(String query) {
    if (query.isEmpty) {
      setState(() => _searchCount = 0);
      return;
    }
    final lowerText = _textController.text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    int count = 0;
    int index = 0;
    while ((index = lowerText.indexOf(lowerQuery, index)) != -1) {
      count++;
      index += lowerQuery.length;
    }
    setState(() => _searchCount = count);
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceGlass,
        title: const Text('Unsaved Changes', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'You have unsaved changes. Do you want to discard them?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Editing', style: TextStyle(color: AppColors.accentTeal)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Discard', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _linesController.dispose();
    _textController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lines = _textController.text.split('\n');
    final lineCount = lines.length;

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceDark,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            onPressed: () async {
              if (!_isDirty) {
                Navigator.of(context).pop();
              } else {
                final pop = await _onWillPop();
                if (pop && context.mounted) Navigator.of(context).pop();
              }
            },
          ),
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Find in text...',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    border: InputBorder.none,
                    suffixText: _searchCount > 0 ? '$_searchCount matches' : null,
                    suffixStyle: const TextStyle(color: AppColors.accentTeal, fontSize: 11),
                  ),
                  onChanged: _calculateSearchCount,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.item.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        ),
                        if (_isDirty) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.accentTeal,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '${widget.item.formattedSize} • $lineCount lines',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
          actions: [
            if (_isSearching)
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchController.clear();
                    _searchCount = 0;
                  });
                },
              )
            else
              IconButton(
                icon: const Icon(Icons.search_rounded, color: AppColors.textPrimary),
                onPressed: () => setState(() => _isSearching = true),
              ),
            IconButton(
              icon: Icon(
                _isEditing ? Icons.visibility_rounded : Icons.edit_rounded,
                color: _isEditing ? AppColors.accentTeal : AppColors.textPrimary,
              ),
              tooltip: _isEditing ? 'View Mode' : 'Edit Mode',
              onPressed: () => setState(() => _isEditing = !_isEditing),
            ),
            if (_isDirty)
              IconButton(
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentTeal),
                      )
                    : const Icon(Icons.save_rounded, color: AppColors.accentTeal),
                tooltip: 'Save',
                onPressed: _saveFile,
              ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
              color: AppColors.surfaceDark,
              onSelected: (val) {
                if (val == 'wrap') {
                  setState(() => _wordWrap = !_wordWrap);
                } else if (val == 'zoom_in') {
                  setState(() => _fontSize = (_fontSize + 1).clamp(9.0, 24.0));
                } else if (val == 'zoom_out') {
                  setState(() => _fontSize = (_fontSize - 1).clamp(9.0, 24.0));
                } else if (val == 'copy_all') {
                  Clipboard.setData(ClipboardData(text: _textController.text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Content copied to clipboard')),
                  );
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'wrap',
                  child: Text(_wordWrap ? 'Disable Word Wrap' : 'Enable Word Wrap'),
                ),
                const PopupMenuItem(value: 'zoom_in', child: Text('Zoom In Text')),
                const PopupMenuItem(value: 'zoom_out', child: Text('Zoom Out Text')),
                const PopupMenuItem(value: 'copy_all', child: Text('Copy All Text')),
              ],
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.accentTeal))
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text('Error reading file: $_error', style: const TextStyle(color: AppColors.danger)),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Line Numbers Gutter
                      Container(
                        width: 42,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        color: AppColors.surfaceDark.withValues(alpha: 0.5),
                        child: ListView.builder(
                          controller: _linesController,
                          itemCount: lineCount,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, i) {
                            return SizedBox(
                              height: _fontSize * 1.5,
                              child: Text(
                                '${i + 1}',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: _fontSize * 0.85,
                                  fontFamily: 'monospace',
                                  color: AppColors.textMuted.withValues(alpha: 0.6),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const VerticalDivider(width: 1, color: AppColors.divider),

                      // Text Content Area
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          scrollDirection: Axis.vertical,
                          child: _isEditing
                              ? TextField(
                                  controller: _textController,
                                  maxLines: null,
                                  keyboardType: TextInputType.multiline,
                                  onChanged: _onTextChanged,
                                  style: TextStyle(
                                    fontSize: _fontSize,
                                    fontFamily: 'monospace',
                                    color: AppColors.textPrimary,
                                    height: 1.5,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                )
                              : SelectableText(
                                  _textController.text,
                                  style: TextStyle(
                                    fontSize: _fontSize,
                                    fontFamily: 'monospace',
                                    color: AppColors.textPrimary,
                                    height: 1.5,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
