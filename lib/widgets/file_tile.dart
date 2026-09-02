import 'package:flutter/material.dart';
import '../models/file_item.dart';
import '../theme/colors.dart';
import '../utils/file_utils.dart';
import 'glass_card.dart';

class FileTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = _getIconTheme(item);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: GlassCard(
        onTap: onTap,
        onLongPress: onLongPress,
        isSelected: isSelected,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        borderRadius: 12,
        child: Row(
          children: [
            if (isSelectionMode) ...[
              Checkbox(
                value: isSelected,
                activeColor: AppColors.accentTeal,
                checkColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                onChanged: (_) => onTap(),
              ),
              const SizedBox(width: 4),
            ],
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: theme.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.color.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                theme.icon,
                color: theme.color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
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
