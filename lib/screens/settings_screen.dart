import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/permission_status.dart';
import '../providers/file_explorer_provider.dart';
import '../providers/general_settings_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import 'about_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  StoragePermissionStatus? _status;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final service = ref.read(platformServiceProvider);
    final status = await service.checkPermissions();
    if (mounted) {
      setState(() {
        _status = status;
        _loading = false;
      });
    }
  }

  void _showHomeFolderPicker(BuildContext context, String currentHome, GeneralSettingsNotifier notifier, AppThemeColor theme) {
    const defaultPaths = [
      '/storage/emulated/0',
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Documents',
      '/storage/emulated/0/DCIM',
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text('Select Home Folder', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: defaultPaths.map((p) {
            final isSelected = p == currentHome;
            final label = p == '/storage/emulated/0'
                ? 'Internal Storage (/sdcard)'
                : p.split('/').last;

            return ListTile(
              dense: true,
              leading: Icon(Icons.folder_rounded, color: isSelected ? theme.primary : AppColors.textSecondary),
              title: Text(label, style: TextStyle(color: isSelected ? theme.primary : AppColors.textPrimary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
              subtitle: Text(p, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              trailing: isSelected ? Icon(Icons.check_rounded, color: theme.primary, size: 18) : null,
              onTap: () {
                notifier.setHomeFolder(p);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showBackButtonActionDialog(BuildContext context, BackButtonAction current, GeneralSettingsNotifier notifier, AppThemeColor theme) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text('Back Button Action', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: BackButtonAction.values.map((action) {
            final isSelected = action == current;
            return ListTile(
              dense: true,
              leading: Icon(
                isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                color: isSelected ? theme.primary : AppColors.textSecondary,
              ),
              title: Text(
                action.label,
                style: TextStyle(
                  color: isSelected ? theme.primary : AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                action.description,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              onTap: () {
                notifier.setBackButtonAction(action);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final generalSettings = ref.watch(generalSettingsProvider);
    final generalNotifier = ref.read(generalSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: theme.primary))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Section 1: Permission & Access
                _buildSectionLabel('PERMISSIONS & ACCESS'),
                const SizedBox(height: 8),

                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'File Access',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (_status?.hasAllFilesAccess ?? false)
                        _buildStatusBadge(true, theme.primary)
                      else
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () async {
                            final service = ref.read(platformServiceProvider);
                            await service.requestAllFilesAccess();
                            _loadStatus();
                          },
                          child: const Text('Grant', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Section 2: General Settings
                _buildSectionLabel('GENERAL SETTINGS'),
                const SizedBox(height: 8),

                GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Home Folder', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                        subtitle: Text(generalSettings.homeFolder, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                        onTap: () => _showHomeFolderPicker(context, generalSettings.homeFolder, generalNotifier, theme),
                      ),
                      const Divider(color: AppColors.border, height: 1, indent: 16, endIndent: 16),
                      SwitchListTile(
                        activeThumbColor: theme.primary,
                        title: const Text('Overwrite Confirmation', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                        subtitle: const Text('Confirm before replacing files', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        value: generalSettings.confirmOverwrite,
                        onChanged: (val) => generalNotifier.setConfirmOverwrite(val),
                      ),
                      const Divider(color: AppColors.border, height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        title: const Text('Back Button Action', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                        subtitle: Text(generalSettings.backButtonAction.label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                        onTap: () => _showBackButtonActionDialog(context, generalSettings.backButtonAction, generalNotifier, theme),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Section 3: Interface Settings
                _buildSectionLabel('INTERFACE SETTINGS'),
                const SizedBox(height: 8),

                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: theme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Color Theme',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<AppThemeColor>(
                          value: theme,
                          dropdownColor: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(12),
                          icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
                          items: AppThemeColor.values.map((t) {
                            return DropdownMenuItem<AppThemeColor>(
                              value: t,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: t.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    t.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: t == theme ? t.light : AppColors.textPrimary,
                                      fontWeight: t == theme ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (newTheme) {
                            if (newTheme != null) {
                              themeNotifier.setTheme(newTheme);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Section 4: About Page Link
                _buildSectionLabel('APPLICATION'),
                const SizedBox(height: 8),

                GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: Icon(Icons.info_outline_rounded, color: theme.primary),
                    title: const Text('About Xplorer Manager', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('v1.4.0 • Introduction & Architecture', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textSecondary),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool granted, Color activeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: granted
            ? AppColors.success.withValues(alpha: 0.15)
            : AppColors.danger.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: granted
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.danger.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        granted ? 'GRANTED' : 'NOT GRANTED',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: granted ? AppColors.success : AppColors.danger,
        ),
      ),
    );
  }
}
