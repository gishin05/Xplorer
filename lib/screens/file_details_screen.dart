import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/file_item.dart';
import '../theme/colors.dart';
import '../utils/file_utils.dart';
import '../widgets/glass_card.dart';

class FileDetailsScreen extends StatelessWidget {
  final FileItem item;

  const FileDetailsScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('File Details'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.accentTeal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.accentTeal.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  item.isDirectory ? Icons.folder_rounded : Icons.insert_drive_file_rounded,
                  size: 38,
                  color: item.isDirectory ? AppColors.folderGold : AppColors.accentTeal,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              item.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              FileUtils.getCategory(item.extension, item.isDirectory),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.accentTeal,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDetailRow(
                    context,
                    'Location',
                    item.path,
                    allowCopy: true,
                  ),
                  const Divider(color: AppColors.divider, height: 24),
                  _buildDetailRow(
                    context,
                    'Size',
                    item.isDirectory
                        ? '${item.childCount} items'
                        : '${FileUtils.formatBytes(item.size)} (${item.size} bytes)',
                  ),
                  const Divider(color: AppColors.divider, height: 24),
                  _buildDetailRow(
                    context,
                    'Modified',
                    FileUtils.formatDate(item.lastModified),
                  ),
                  const Divider(color: AppColors.divider, height: 24),
                  _buildDetailRow(
                    context,
                    'Type / MIME',
                    item.mimeType,
                  ),
                  if (item.extension.isNotEmpty) ...[
                    const Divider(color: AppColors.divider, height: 24),
                    _buildDetailRow(
                      context,
                      'Extension',
                      '.${item.extension}',
                    ),
                  ],
                  const Divider(color: AppColors.divider, height: 24),
                  _buildDetailRow(
                    context,
                    'Permissions',
                    '${item.canRead ? "R" : "-"}${item.canWrite ? "W" : "-"}',
                  ),
                  if (item.md5 != null) ...[
                    const Divider(color: AppColors.divider, height: 24),
                    _buildDetailRow(
                      context,
                      'MD5 Hash',
                      item.md5!,
                      allowCopy: true,
                    ),
                  ],
                  if (item.sha256 != null) ...[
                    const Divider(color: AppColors.divider, height: 24),
                    _buildDetailRow(
                      context,
                      'SHA-256',
                      item.sha256!,
                      allowCopy: true,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentTeal,
                      side: const BorderSide(color: AppColors.accentTeal),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: item.path));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Path copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy Path'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool allowCopy = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (allowCopy)
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label copied to clipboard'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: const Padding(
              padding: EdgeInsets.only(left: 6.0),
              child: Icon(Icons.copy_rounded, size: 16, color: AppColors.accentTeal),
            ),
          ),
      ],
    );
  }
}
