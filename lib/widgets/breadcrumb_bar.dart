import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../utils/file_utils.dart';

class BreadcrumbBar extends StatelessWidget {
  final String currentPath;
  final ValueChanged<String> onNavigate;

  const BreadcrumbBar({
    super.key,
    required this.currentPath,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final breadcrumbs = FileUtils.buildBreadcrumbs(currentPath);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceGlass,
        border: Border(
          bottom: BorderSide(color: AppColors.glassBorder.withValues(alpha: 0.5), width: 1),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: breadcrumbs.length,
        separatorBuilder: (context, index) => const Icon(
          Icons.chevron_right_rounded,
          size: 18,
          color: AppColors.textMuted,
        ),
        itemBuilder: (context, index) {
          final item = breadcrumbs[index];
          final isLast = index == breadcrumbs.length - 1;

          return Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: isLast ? null : () => onNavigate(item.path),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: isLast
                    ? BoxDecoration(
                        color: AppColors.accentTeal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.accentTeal.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      )
                    : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (index == 0) ...[
                      Icon(
                        item.path == '/' ? Icons.storage_rounded : Icons.phone_android_rounded,
                        size: 16,
                        color: isLast ? AppColors.accentTeal : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isLast ? FontWeight.w600 : FontWeight.w400,
                        color: isLast ? AppColors.accentTeal : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
