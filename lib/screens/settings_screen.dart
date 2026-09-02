import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/permission_status.dart';
import '../providers/adb_bridge_provider.dart';
import '../providers/file_explorer_provider.dart';
import '../theme/colors.dart';
import '../widgets/glass_card.dart';
import 'adb_setup_screen.dart';

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
    await ref.read(adbBridgeProvider.notifier).checkDeveloperOptionsAndBridge();
    if (mounted) {
      setState(() {
        _status = status;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const dpmCommand =
        'adb shell dpm set-device-owner com.antigravity.file_manager/.DeviceAdminReceiver';
    final adbState = ref.watch(adbBridgeProvider);

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
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentTeal))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                _buildSectionLabel('STORAGE & ELEVATED ACCESS'),
                const SizedBox(height: 8),

                // Card 1: All Files Access (MANAGE_EXTERNAL_STORAGE)
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'All Files Access',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          _buildStatusBadge(_status?.hasAllFilesAccess ?? false),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Full filesystem browsing on /sdcard and external storage media without requiring device root.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                      ),
                      if (!(_status?.hasAllFilesAccess ?? false)) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentTeal,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () async {
                              final service = ref.read(platformServiceProvider);
                              await service.requestAllFilesAccess();
                              _loadStatus();
                            },
                            child: const Text('Grant All Files Permission', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Card 2: Wireless ADB Helper Bridge
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Wireless ADB Helper Bridge',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          _buildStatusBadge(
                            adbState.isConnected,
                            activeText: 'ACTIVE',
                            inactiveText: 'STANDBY',
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Automatically activates elevated access to /Android/data and installed APK packages when Developer Options is turned on.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: AppColors.divider, height: 1),
                      const SizedBox(height: 8),

                      // Auto-Bridge Toggle
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Auto-Bridge on Developer Options',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Connects automatically when debugging is enabled',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                  softWrap: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch.adaptive(
                            value: adbState.isAutoBridgeEnabled,
                            activeTrackColor: AppColors.accentTeal,
                            activeThumbColor: Colors.black,
                            onChanged: (val) {
                              ref.read(adbBridgeProvider.notifier).toggleAutoBridge(val);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Developer Options row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Developer Options: ${adbState.isDevOptionsEnabled ? 'Enabled' : 'Disabled'}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: adbState.isDevOptionsEnabled ? AppColors.success : AppColors.textSecondary,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                ref.read(adbBridgeProvider.notifier).openDeveloperSettings();
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                child: Text(
                                  'System Settings',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accentTeal,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Manual Bridge Link
                      Align(
                        alignment: Alignment.centerLeft,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AdbSetupScreen()),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              'Configure Manual Network Port...',
                              style: TextStyle(fontSize: 12, color: AppColors.accentTealLight),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Card 3: Enterprise Device Owner Mode (DPM)
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Enterprise Device Owner Mode',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          _buildStatusBadge(_status?.isDeviceOwner ?? false),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Enrolls Xplorer as an Android Device Owner via enterprise administration commands, unlocking device storage policies.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: SelectableText(
                                dpmCommand,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: AppColors.accentTealLight,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              borderRadius: BorderRadius.circular(4),
                              onTap: () {
                                Clipboard.setData(const ClipboardData(text: dpmCommand));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: AppColors.surfaceGlass,
                                    content: Text('Command copied to clipboard'),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.accentTeal.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'COPY',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                    color: AppColors.accentTeal,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                _buildSectionLabel('INTRODUCTION & GUIDE'),
                const SizedBox(height: 8),

                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // App Identity Header
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.accentTeal,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.folder_rounded,
                              color: AppColors.background,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Xplorer',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.accentTeal.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: AppColors.accentTeal.withValues(alpha: 0.3)),
                                      ),
                                      child: const Text(
                                        'v1.2.1',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.accentTeal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  'Clean, Solid & Elevated Utility File Manager',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: AppColors.divider),
                      const SizedBox(height: 10),

                      // Welcome and Overview
                      const Text(
                        'Welcome to Xplorer',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Xplorer provides fast, dependable, and unrestricted control over your Android device storage without requiring root privileges.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Feature Guide Highlights
                      _buildGuideTile(
                        icon: Icons.shield_rounded,
                        color: AppColors.accentTeal,
                        title: 'Storage & Protected Directories',
                        description: 'Browse internal memory and SD cards. When Developer Options is active, the Wireless ADB Bridge automatically unlocks /Android/data and /Android/obb game and app packages.',
                      ),
                      const SizedBox(height: 10),
                      _buildGuideTile(
                        icon: Icons.folder_zip_rounded,
                        color: AppColors.archivePurple,
                        title: 'Multi-Format Archive Tools',
                        description: 'Compress and extract .zip, .7z, .tar, and .tar.gz archives. Password-protected archives are supported with AES-256 decryption and creation.',
                      ),
                      const SizedBox(height: 10),
                      _buildGuideTile(
                        icon: Icons.perm_media_rounded,
                        color: AppColors.imageBlue,
                        title: 'Integrated Viewers & Editors',
                        description: 'Continuous photo swiping gallery, line-numbered text editor, native PDF page renderer, and background audio/video media players.',
                      ),
                      const SizedBox(height: 10),
                      _buildGuideTile(
                        icon: Icons.content_paste_rounded,
                        color: AppColors.folderGold,
                        title: 'Batch Cut, Copy & Paste',
                        description: 'Select one or more items to copy or move across directories with a persistent, floating paste action bar.',
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: AppColors.divider),
                      const SizedBox(height: 8),

                      // Technical Specifications
                      _buildInfoRow('Engine Architecture', 'Elevated Wireless ADB Bridge'),
                      const Divider(color: AppColors.divider),
                      _buildInfoRow('Platform Compliance', 'Android 11 - 15 (API 30 - 35) Scoped Storage'),
                      const Divider(color: AppColors.divider),
                      _buildInfoRow('Archive Engines', 'Zip4j (AES-256) & Commons-Compress (7z/Tar)'),
                      const Divider(color: AppColors.divider),
                      _buildInfoRow('Privacy Guarantee', '100% On-Device Processing • Zero Telemetry'),
                      const SizedBox(height: 16),

                      // Interactive Actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppColors.accentTeal.withValues(alpha: 0.3)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _showChangelogModal(context),
                              child: const Text(
                                'Release Notes & Changelog',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accentTeal,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildGuideTile({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showChangelogModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Release Notes',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildChangelogEntry(
                version: 'v1.2.1 (Phase 7)',
                date: 'September 2026',
                points: [
                  'Multi-format archive compression & extraction: .zip, .7z, .tar, .tar.gz.',
                  'AES-256 and standard password-protected archive decryption & creation.',
                  'Continuous multi-image horizontal swipe gallery with index counter.',
                  'Batch Cut, Copy, and Paste clipboard system with persistent action bar.',
                  'Traditional solid clean utility dark aesthetic with crisp dedicated file icons.',
                  'Comprehensive Introduction & Guide console.',
                ],
              ),
              const SizedBox(height: 12),
              _buildChangelogEntry(
                version: 'v1.2.0 (Phase 6)',
                date: 'September 2026',
                points: [
                  'Full Package Visibility via QUERY_ALL_PACKAGES permission.',
                  'Direct Android/data game resolution for com.garena.game.codm, Minecraft, etc.',
                  'Recursive subfolder navigation inside protected game asset directories.',
                  'Smooth non-sticky header layout: ADB banner, storage card, and APK buttons scroll with content.',
                  'Executive About dashboard redesigned by senior developer.',
                ],
              ),
              const SizedBox(height: 12),
              _buildChangelogEntry(
                version: 'v1.1.0 (Phase 5)',
                date: 'August 2026',
                points: [
                  'Integrated zero-dependency native PDF viewer with page navigation & annotations.',
                  'In-app Text Viewer & Editor with line numbers, find in file, and safe write-back.',
                  'Fullscreen pinch-to-zoom Image Viewer with rotation and EXIF metadata.',
                  'Integrated Audio & Video media players with background controls.',
                  'Always-visible interactive scrollbar indicator.',
                ],
              ),
              const SizedBox(height: 12),
              _buildChangelogEntry(
                version: 'v1.0.0 (Phases 1-4)',
                date: 'August 2026',
                points: [
                  'Wireless ADB Auto-Bridge with automatic Developer Options detection.',
                  'Device Owner enterprise administration integration.',
                  'ZArchiver-inspired obsidian glassmorphism UI.',
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChangelogEntry({
    required String version,
    required String date,
    required List<String> points,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                version,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentTeal,
                ),
              ),
              Text(
                date,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...points.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: AppColors.accentTeal, fontSize: 12)),
                  Expanded(
                    child: Text(
                      p,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
          letterSpacing: 0.9,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool active, {String activeText = 'ACTIVE', String inactiveText = 'INACTIVE'}) {
    final color = active ? AppColors.success : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        active ? activeText : inactiveText,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              title,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
