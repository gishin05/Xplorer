import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../theme/colors.dart';
import '../widgets/cracked_x_logo.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  void _showChangelogModal(BuildContext context, AppThemeColor theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceGlass,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Release Notes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildChangelogEntry(
                version: 'v1.4.0',
                date: 'September 2026',
                themeColor: theme.primary,
                changes: [
                  'Official name updated to Xplorer Manager.',
                  'Redesigned logo: Cracked X on Folder Cover.',
                  'In-Zip file inspection: tap to preview images, text, and files directly from archives.',
                  'Device back button navigation with Double-Back to exit.',
                  'Compact dropdown theme selector in Settings to save vertical space.',
                  'Clean Home screen with removed Wireless ADB banner.',
                  'Unified dynamic color theming across all buttons, bars, and indicators.',
                  'Extended support for WebP, SVG, TIFF, and multimedia formats.',
                ],
              ),
              const SizedBox(height: 12),
              _buildChangelogEntry(
                version: 'v1.3.0',
                date: 'September 2026',
                themeColor: theme.primary,
                changes: [
                  'Direct unextracted ZIP and archive browsing via "Open" action.',
                  'Android system "Open In" intent launcher integration.',
                  'Traditional high-density flat file list layout (removed card borders/margins).',
                  'Native APK application icon extraction and caching.',
                  'Dynamic color themes (Teal, Blue, Green, Amber, Red, Purple, Slate).',
                  'General Settings (Home folder, Overwrite confirmation, Back button action).',
                  'Stylized Cracked X logo design on app icon and startup splash.',
                  'Circular loading indicators across directory panels.',
                ],
              ),
              const SizedBox(height: 12),
              _buildChangelogEntry(
                version: 'v1.2.1',
                date: 'September 2026',
                themeColor: theme.primary,
                changes: [
                  'Multi-format archive compression & extraction: .zip, .7z, .tar, .tar.gz.',
                  'AES-256 and standard password-protected archive decryption & creation.',
                  'Continuous multi-image horizontal swipe gallery with index counter.',
                  'Batch Cut, Copy, and Paste clipboard system with persistent action bar.',
                  'Traditional clean solid dark utility theme without heavy blur overhead.',
                  'Dedicated solid file-type icons for PDF, code, binaries, scripts, and archives.',
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildChangelogEntry({
    required String version,
    required String date,
    required Color themeColor,
    required List<String> changes,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                version,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: themeColor,
                ),
              ),
              Text(
                date,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...changes.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: themeColor, fontSize: 13)),
                  Expanded(
                    child: Text(
                      c,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'About',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // Branding Block
          Center(
            child: Column(
              children: [
                CrackedXLogo(
                  size: 80,
                  accentColor: theme.primary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Xplorer Manager',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'v1.4.0 (Build 2026.09)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.light,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Introduction Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: theme.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Introduction',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Xplorer Manager is a high-performance, unrestricted native Android file manager designed for complete control over your storage. Built with elevated scoped access to inspect deep game and app directories, direct multi-format archive tools (.zip, .7z, .tar) with in-archive file viewing, continuous swipe image gallery, and in-app code and text editing.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Technical Architecture
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.memory_rounded, size: 18, color: theme.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Technical Architecture',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTechRow('Engine Framework', 'Flutter 3.47 (AOT Optimized)'),
                _buildTechRow('Native Bridge', 'Kotlin 2.1 Coroutine Channel'),
                _buildTechRow('Archive Backend', 'Zip4j + Apache Commons Compress'),
                _buildTechRow('Binary Package', '18.5 MB Split-ABI Release'),
                _buildTechRow('Privacy Guarantee', '100% On-Device, Zero Telemetry'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Release Notes Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: theme.primary.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: Icon(Icons.history_rounded, color: theme.primary),
            label: Text(
              'Release Notes & Changelog',
              style: TextStyle(color: theme.primary, fontWeight: FontWeight.w600),
            ),
            onPressed: () => _showChangelogModal(context, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildTechRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
