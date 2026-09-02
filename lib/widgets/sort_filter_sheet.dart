import 'package:flutter/material.dart';
import '../theme/colors.dart';

enum SortBy { name, date, size, type }

class SortFilterSheet extends StatelessWidget {
  final SortBy currentSort;
  final bool ascending;
  final bool showHidden;
  final Function(SortBy sort, bool ascending, bool showHidden) onApply;

  const SortFilterSheet({
    super.key,
    required this.currentSort,
    required this.ascending,
    required this.showHidden,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    var selectedSort = currentSort;
    var isAsc = ascending;
    var hidden = showHidden;

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          decoration: const BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Sort & Filter',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'SORT BY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildSortChip('Name', SortBy.name, selectedSort, (s) {
                    setState(() => selectedSort = s);
                  }),
                  _buildSortChip('Date Modified', SortBy.date, selectedSort, (s) {
                    setState(() => selectedSort = s);
                  }),
                  _buildSortChip('Size', SortBy.size, selectedSort, (s) {
                    setState(() => selectedSort = s);
                  }),
                  _buildSortChip('Type', SortBy.type, selectedSort, (s) {
                    setState(() => selectedSort = s);
                  }),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'ORDER',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Ascending (A-Z, 0-9)')),
                      selected: isAsc,
                      selectedColor: AppColors.accentTeal.withValues(alpha: 0.2),
                      backgroundColor: AppColors.surfaceGlass,
                      side: BorderSide(
                        color: isAsc ? AppColors.accentTeal : AppColors.glassBorder,
                      ),
                      labelStyle: TextStyle(
                        color: isAsc ? AppColors.accentTeal : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => isAsc = true);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Descending (Z-A, 9-0)')),
                      selected: !isAsc,
                      selectedColor: AppColors.accentTeal.withValues(alpha: 0.2),
                      backgroundColor: AppColors.surfaceGlass,
                      side: BorderSide(
                        color: !isAsc ? AppColors.accentTeal : AppColors.glassBorder,
                      ),
                      labelStyle: TextStyle(
                        color: !isAsc ? AppColors.accentTeal : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => isAsc = false);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Show hidden files & folders',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                ),
                subtitle: const Text(
                  'Files starting with a dot (e.g. .nomedia)',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                activeThumbColor: AppColors.accentTeal,
                value: hidden,
                onChanged: (val) {
                  setState(() => hidden = val);
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentTeal,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    onApply(selectedSort, isAsc, hidden);
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Apply Changes',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortChip(
    String label,
    SortBy sort,
    SortBy current,
    ValueChanged<SortBy> onSelect,
  ) {
    final isSelected = sort == current;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.accentTeal.withValues(alpha: 0.2),
      backgroundColor: AppColors.surfaceGlass,
      side: BorderSide(
        color: isSelected ? AppColors.accentTeal : AppColors.glassBorder,
      ),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.accentTeal : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        fontSize: 13,
      ),
      onSelected: (val) {
        if (val) onSelect(sort);
      },
    );
  }
}
