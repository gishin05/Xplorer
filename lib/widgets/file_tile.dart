import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/file_item.dart';
import '../providers/file_explorer_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/colors.dart';
import '../utils/file_utils.dart';

class FileTile extends ConsumerWidget {
  final FileItem item;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onMoreOptions;

  const FileTile({
    super.key,
    required this.item,
    this.isSelected = false,
    this.isSelectionMode = false,
    required this.onTap,
    this.onLongPress,
    this.onMoreOptions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconTheme = _getIconTheme(item);
    final activeTheme = ref.watch(themeProvider);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      splashColor: activeTheme.primary.withValues(alpha: 0.15),
      highlightColor: activeTheme.primary.withValues(alpha: 0.08),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? activeTheme.primary.withValues(alpha: 0.18)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: AppColors.border.withValues(alpha: 0.4),
              width: 0.5,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        child: Row(
          children: [
            if (isSelectionMode) ...[
              Checkbox(
                value: isSelected,
                activeColor: activeTheme.primary,
                checkColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                onChanged: (_) => onTap(),
              ),
              const SizedBox(width: 8),
            ],
            // File / Folder / APK Icon
            if (item.isApk)
              _ApkIconWidget(
                path: item.path,
                fallbackColor: iconTheme.color,
              )
            else
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconTheme.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  iconTheme.icon,
                  color: iconTheme.color,
                  size: 22,
                ),
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: item.isHidden ? AppColors.textMuted : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        item.isDirectory
                            ? '${item.childCount} items'
                            : FileUtils.formatBytes(item.size),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '•',
                        style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        FileUtils.formatDate(item.lastModified),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!isSelectionMode && onMoreOptions != null) ...[
              IconButton(
                icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textSecondary),
                onPressed: onMoreOptions,
                splashRadius: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }

  _IconThemeData _getIconTheme(FileItem item) {
    if (item.isDirectory) {
      return const _IconThemeData(
        icon: Icons.folder_rounded,
        color: AppColors.folderGold,
      );
    }
    if (item.isArchive) {
      return const _IconThemeData(
        icon: Icons.folder_zip_rounded,
        color: AppColors.archivePurple,
      );
    }
    if (item.isApk) {
      return const _IconThemeData(
        icon: Icons.android_rounded,
        color: AppColors.packageAmber,
      );
    }
    if (item.isImage) {
      return const _IconThemeData(
        icon: Icons.image_rounded,
        color: AppColors.imageBlue,
      );
    }
    if (item.isVideo) {
      return const _IconThemeData(
        icon: Icons.movie_rounded,
        color: AppColors.videoRed,
      );
    }
    if (item.isAudio) {
      return const _IconThemeData(
        icon: Icons.music_note_rounded,
        color: AppColors.audioViolet,
      );
    }
    if (item.isPdf) {
      return const _IconThemeData(
        icon: Icons.picture_as_pdf_rounded,
        color: Color(0xFFE53935),
      );
    }
    if (item.isText) {
      return const _IconThemeData(
        icon: Icons.article_rounded,
        color: Color(0xFF5C6BC0),
      );
    }
    if (item.isCode) {
      return const _IconThemeData(
        icon: Icons.code_rounded,
        color: AppColors.codeGreen,
      );
    }
    if (item.isFont) {
      return const _IconThemeData(
        icon: Icons.font_download_rounded,
        color: AppColors.fontCyan,
      );
    }
    if (item.isDocument) {
      return const _IconThemeData(
        icon: Icons.description_rounded,
        color: AppColors.documentOrange,
      );
    }
    if (item.isBinary) {
      return const _IconThemeData(
        icon: Icons.memory_rounded,
        color: AppColors.fileGrey,
      );
    }
    return const _IconThemeData(
      icon: Icons.insert_drive_file_rounded,
      color: AppColors.fileGrey,
    );
  }
}

class _IconThemeData {
  final IconData icon;
  final Color color;

  const _IconThemeData({required this.icon, required this.color});
}

class _ApkIconWidget extends ConsumerStatefulWidget {
  final String path;
  final Color fallbackColor;

  const _ApkIconWidget({
    required this.path,
    required this.fallbackColor,
  });

  static final Map<String, Uint8List?> _iconCache = {};

  @override
  ConsumerState<_ApkIconWidget> createState() => _ApkIconWidgetState();
}

class _ApkIconWidgetState extends ConsumerState<_ApkIconWidget> {
  Uint8List? _iconBytes;

  @override
  void initState() {
    super.initState();
    _loadIcon();
  }

  @override
  void didUpdateWidget(covariant _ApkIconWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _loadIcon();
    }
  }

  Future<void> _loadIcon() async {
    if (_ApkIconWidget._iconCache.containsKey(widget.path)) {
      if (mounted) {
        setState(() {
          _iconBytes = _ApkIconWidget._iconCache[widget.path];
        });
      }
      return;
    }

    final bytes = await ref.read(platformServiceProvider).getApkIcon(widget.path);
    _ApkIconWidget._iconCache[widget.path] = bytes;

    if (mounted) {
      setState(() {
        _iconBytes = bytes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_iconBytes != null) {
      return Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.memory(
          _iconBytes!,
          width: 38,
          height: 38,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallback(),
        ),
      );
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: widget.fallbackColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.android_rounded,
        color: widget.fallbackColor,
        size: 22,
      ),
    );
  }
}
