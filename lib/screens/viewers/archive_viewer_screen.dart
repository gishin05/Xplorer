import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/archive_entry_item.dart';
import '../../models/file_item.dart';
import '../../providers/file_explorer_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/colors.dart';
import '../../utils/file_utils.dart';
import '../../widgets/archive_dialogs.dart';
import 'archive_image_viewer_screen.dart';
import 'pdf_viewer_screen.dart';
import 'text_editor_screen.dart';

class ArchiveViewerScreen extends ConsumerStatefulWidget {
  final FileItem archiveItem;

  const ArchiveViewerScreen({
    super.key,
    required this.archiveItem,
  });

  @override
  ConsumerState<ArchiveViewerScreen> createState() => _ArchiveViewerScreenState();
}

class _ArchiveViewerScreenState extends ConsumerState<ArchiveViewerScreen> {
  List<ArchiveEntryItem> _allEntries = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _password;
  bool _isEncrypted = false;
  String _currentSubdir = '';

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries({String? password}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final entries = await ref.read(platformServiceProvider).listArchiveEntries(
            widget.archiveItem.path,
            password: password ?? _password,
          );
      if (mounted) {
        setState(() {
          _allEntries = entries;
          _isLoading = false;
          _isEncrypted = entries.any((e) => e.isEncrypted);
        });
      }
    } catch (e) {
      if (mounted) {
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('password') || errStr.contains('encrypted')) {
          setState(() {
            _isEncrypted = true;
            _isLoading = false;
          });
          _promptPassword();
        } else {
          setState(() {
            _errorMessage = e.toString();
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _promptPassword() async {
    final enteredPass = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ArchivePasswordDialog(archiveName: widget.archiveItem.name),
    );
    if (enteredPass != null) {
      _password = enteredPass;
      _loadEntries(password: enteredPass);
    }
  }

  void _extractAll() {
    final path = widget.archiveItem.path;
    final parentDir = path.contains('/') ? path.substring(0, path.lastIndexOf('/')) : '/storage/emulated/0';
    final folderName = widget.archiveItem.name.split('.').first;
    final dest = '$parentDir/$folderName';

    ref.read(fileExplorerProvider.notifier).extractArchive(
          archivePath: widget.archiveItem.path,
          destinationPath: dest,
          password: _password,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Extracting to $dest...'),
        backgroundColor: AppColors.surfaceGlass,
      ),
    );
  }

  Future<void> _openEntry(ArchiveEntryItem entry) async {
    if (entry.isDirectory) {
      setState(() {
        _currentSubdir = entry.name.endsWith('/') ? entry.name : '${entry.name}/';
      });
      return;
    }

    const imageExts = {'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp', 'svg', 'heic', 'avif', 'ico', 'tiff'};
    final ext = entry.name.split('.').last.toLowerCase();

    if (imageExts.contains(ext)) {
      final allImages = _allEntries.where((e) {
        if (e.isDirectory) return false;
        final eExt = e.name.split('.').last.toLowerCase();
        return imageExts.contains(eExt);
      }).toList();

      final idx = allImages.indexWhere((e) => e.name == entry.name);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ArchiveImageViewerScreen(
            archivePath: widget.archiveItem.path,
            archiveName: widget.archiveItem.name,
            imageEntries: allImages.isNotEmpty ? allImages : [entry],
            initialIndex: idx != -1 ? idx : 0,
            password: _password,
          ),
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('Extracting preview for ${entry.name.split('/').last}...')),
          ],
        ),
        duration: const Duration(seconds: 4),
        backgroundColor: AppColors.surfaceGlass,
      ),
    );

    try {
      final cacheDir = await getTemporaryDirectory();
      final safeName = entry.name.replaceAll('/', '_');
      final destPath = '${cacheDir.path}/archive_preview_$safeName';

      final extractedPath = await ref.read(platformServiceProvider).extractArchiveEntry(
            archivePath: widget.archiveItem.path,
            entryName: entry.name,
            destinationPath: destPath,
            password: _password,
          );

      messenger.hideCurrentSnackBar();

      if (extractedPath != null && mounted) {
        final ext = destPath.split('.').last.toLowerCase();
        final previewFile = File(extractedPath);
        final fileItem = FileItem(
          path: extractedPath,
          name: entry.name.split('/').last,
          size: entry.uncompressedSize,
          isDirectory: false,
          lastModified: DateTime.fromMillisecondsSinceEpoch(entry.lastModified),
          extension: ext,
        );

        const textExts = {
          'txt', 'md', 'json', 'log', 'xml', 'yaml', 'yml', 'dart', 'kt', 'java',
          'py', 'js', 'ts', 'html', 'css', 'csv', 'ini', 'conf', 'sh', 'gradle',
          'kts', 'properties', 'c', 'cpp', 'h', 'hpp', 'cs', 'go', 'rs', 'php', 'sql'
        };

        if (textExts.contains(ext)) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TextEditorScreen(item: fileItem),
            ),
          );
        } else if (ext == 'pdf') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PdfViewerScreen(item: fileItem),
            ),
          );
        } else {
          // Open via system apps
          final success = await ref.read(platformServiceProvider).openFileWithSystemApp(previewFile.path);
          if (!success && mounted) {
            messenger.showSnackBar(
              SnackBar(
                content: Text('No application found to open ${fileItem.name}'),
                backgroundColor: AppColors.surfaceGlass,
              ),
            );
          }
        }
      } else if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to preview entry'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (e) {
      messenger.hideCurrentSnackBar();
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Preview error: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  List<ArchiveEntryItem> _getVisibleEntries() {
    if (_currentSubdir.isEmpty) {
      return _allEntries;
    }
    return _allEntries.where((e) => e.name.startsWith(_currentSubdir)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(themeProvider);
    final visibleEntries = _getVisibleEntries();

    return PopScope(
      canPop: _currentSubdir.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentSubdir.isNotEmpty) {
          // Navigate up within archive
          final parts = _currentSubdir.split('/').where((s) => s.isNotEmpty).toList();
          setState(() {
            if (parts.length <= 1) {
              _currentSubdir = '';
            } else {
              parts.removeLast();
              _currentSubdir = '${parts.join('/')}/';
            }
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceDark,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            onPressed: () {
              if (_currentSubdir.isNotEmpty) {
                final parts = _currentSubdir.split('/').where((s) => s.isNotEmpty).toList();
                setState(() {
                  if (parts.length <= 1) {
                    _currentSubdir = '';
                  } else {
                    parts.removeLast();
                    _currentSubdir = '${parts.join('/')}/';
                  }
                });
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.archiveItem.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _currentSubdir.isEmpty
                    ? '${_allEntries.length} items (${FileUtils.formatBytes(_allEntries.fold(0, (sum, e) => sum + e.uncompressedSize))})'
                    : 'Archive > $_currentSubdir',
                style: TextStyle(
                  fontSize: 11,
                  color: _currentSubdir.isEmpty ? AppColors.textSecondary : currentTheme.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            if (_isEncrypted)
              IconButton(
                tooltip: 'Set Password',
                icon: const Icon(Icons.lock_outline_rounded, color: AppColors.warning),
                onPressed: _promptPassword,
              ),
            TextButton.icon(
              onPressed: _allEntries.isEmpty ? null : _extractAll,
              icon: Icon(Icons.unarchive_rounded, size: 18, color: currentTheme.primary),
              label: Text(
                'Extract All',
                style: TextStyle(color: currentTheme.primary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: currentTheme.primary),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: currentTheme.primary),
                            onPressed: () => _loadEntries(),
                            child: const Text('Retry', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  )
                : visibleEntries.isEmpty
                    ? Center(
                        child: Text(
                          _allEntries.isEmpty ? 'Archive is empty' : 'Directory is empty',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        itemCount: visibleEntries.length,
                        separatorBuilder: (_, _) => const Divider(
                          height: 1,
                          thickness: 0.5,
                          color: AppColors.border,
                        ),
                        itemBuilder: (context, index) {
                          final entry = visibleEntries[index];
                          final isDir = entry.isDirectory || entry.name.endsWith('/');
                          final displayName = entry.name.trimEnd('/');
                          final basename = displayName.split('/').last;

                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            leading: Icon(
                              isDir ? Icons.folder_rounded : Icons.insert_drive_file_rounded,
                              color: isDir ? currentTheme.primary : AppColors.textSecondary,
                              size: 24,
                            ),
                            title: Text(
                              basename,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: isDir
                                ? Text(
                                    displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  )
                                : Row(
                                    children: [
                                      Text(
                                        FileUtils.formatBytes(entry.uncompressedSize),
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                      if (entry.compressedSize > 0) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          '(compressed: ${FileUtils.formatBytes(entry.compressedSize)})',
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                            trailing: entry.isEncrypted
                                ? const Icon(Icons.lock_rounded, size: 16, color: AppColors.warning)
                                : const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
                            onTap: () => _openEntry(entry),
                          );
                        },
                      ),
      ),
    );
  }
}

extension on String {
  String trimEnd(String char) {
    var s = this;
    while (s.endsWith(char)) {
      s = s.substring(0, s.length - char.length);
    }
    return s;
  }
}
