import 'package:flutter/material.dart';
import '../models/storage_volume.dart';
import '../theme/colors.dart';
import '../utils/file_utils.dart';
import 'glass_card.dart';

class StorageIndicator extends StatelessWidget {
  final StorageVolume? volume;
  final VoidCallback? onTap;

  const StorageIndicator({
    super.key,
    this.volume,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final vol = volume;
    final usedStr = vol != null ? FileUtils.formatBytes(vol.usedBytes) : '...';
    final totalStr = vol != null ? FileUtils.formatBytes(vol.totalBytes) : '...';
    final percent = vol?.usagePercent ?? 0.0;
    final percentStr = '${(percent * 100).toStringAsFixed(0)}%';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentTeal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.accentTeal.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.storage_rounded,
                    size: 20,
                    color: AppColors.accentTeal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vol?.description ?? 'Primary Storage',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$usedStr used of $totalStr',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.glassBorder, width: 1),
                  ),
                  child: Text(
                    percentStr,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentTeal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 6,
                backgroundColor: AppColors.surfaceDark,
                valueColor: AlwaysStoppedAnimation<Color>(
                  percent > 0.9 ? AppColors.danger : AppColors.accentTeal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
