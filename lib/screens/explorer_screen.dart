import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/file_item.dart';
import '../providers/adb_bridge_provider.dart';
import '../providers/file_explorer_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/colors.dart';
import '../widgets/archive_dialogs.dart';
import '../widgets/breadcrumb_bar.dart';
import '../widgets/cracked_x_logo.dart';
import '../widgets/file_tile.dart';
import '../widgets/sort_filter_sheet.dart';
import '../widgets/storage_indicator.dart';
import 'file_details_screen.dart';
import 'settings_screen.dart';
import 'viewers/archive_viewer_screen.dart';
import 'viewers/image_viewer_screen.dart';
import 'viewers/media_player_modal.dart';
import 'viewers/pdf_viewer_screen.dart';
import 'viewers/text_editor_screen.dart';

class ExplorerScreen extends ConsumerStatefulWidget {
  const ExplorerScreen({super.key});

  @override
  ConsumerState<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends ConsumerState<ExplorerScreen>
    with WidgetsBindingObserver {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      ref.read(fileExplorerProvider.notifier).initialize();
      ref.read(adbBridgeProvider.notifier).checkDeveloperOptionsAndBridge();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final wasConnected = ref.read(adbBridgeProvider).isConnected;
      ref.read(adbBridgeProvider.notifier).checkDeveloperOptionsAndBridge().then((_) {
        final nowConnected = ref.read(adbBridgeProvider).isConnected;
        if (!wasConnected && nowConnected && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.surfaceGlass,
              content: Text(
                'Wireless ADB Auto-Bridge connected! Elevated access active.',
                style: TextStyle(color: AppColors.accentTeal, fontWeight: FontWeight.w600),
              ),
              duration: Duration(seconds: 3),
            ),
          );
          ref.read(fileExplorerProvider.notifier).loadDirectory(
            ref.read(fileExplorerProvider).currentPath,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final explorerState = ref.watch(fileExplorerProvider);
    final currentTheme = ref.watch(themeProvider);
    final notifier = ref.read(fileExplorerProvider.notifier);

    final isRoot = explorerState.currentPath == '/' ||
        explorerState.currentPath == '/storage/emulated/0';
    final items = explorerState.filteredItems;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.9),
        elevation: 0,
        leading: isRoot
            ? Padding(
                padding: const EdgeInsets.all(12.0),
                child: CrackedXLogo(
                  size: 24,
                  accentColor: currentTheme.primary,
                  showBackground: false,
                ),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchController.clear();
                  });
                  notifier.navigateUp();
                },
              ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                cursorColor: currentTheme.primary,
                decoration: InputDecoration(
                  hintText: 'Search files in folder...',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () {
                      setState(() {
                        _isSearching = false;
                        _searchController.clear();
                        notifier.setSearchQuery('');
                      });
                    },
                  ),
                ),
                onChanged: (val) => notifier.setSearchQuery(val),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    explorerState.currentPath.split('/').last.isEmpty
                        ? 'Root'
                        : explorerState.currentPath.split('/').last,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${items.length} items',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search_rounded, color: AppColors.textPrimary),
              onPressed: () {
                setState(() => _isSearching = true);
              },
            ),
          IconButton(
            icon: const Icon(Icons.sort_rounded, color: AppColors.textPrimary),
            onPressed: () => _openSortSheet(context, explorerState, notifier),
          ),
          if (explorerState.isSelectionMode)
            IconButton(
              icon: Icon(Icons.select_all_rounded, color: currentTheme.primary),
              onPressed: () => notifier.selectAll(),
            )
          else
            IconButton(
              icon: const Icon(Icons.checklist_rounded, color: AppColors.textPrimary),
              onPressed: () => notifier.toggleSelection(items.isNotEmpty ? items.first.path : ''),
            ),
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: AppColors.textPrimary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;

          // 1. If in selection mode, clear selection first
          if (explorerState.isSelectionMode) {
            notifier.clearSelection();
            return;
          }

          // 2. If searching, cancel search
          if (_isSearching) {
            setState(() {
              _isSearching = false;
              _searchController.clear();
              notifier.setSearchQuery('');
            });
            return;
          }

          // 3. If in a subdirectory, navigate up!
          final isAtRoot = explorerState.currentPath == '/' ||
              explorerState.currentPath == '/storage/emulated/0';

          if (!isAtRoot) {
            notifier.navigateUp();
            return;
          }

          // 4. Double back to exit at root
          final now = DateTime.now();
          if (_lastBackPressTime == null ||
              now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
            _lastBackPressTime = now;
            ScaffoldMessenger.of(context).removeCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Press back again to exit'),
                duration: const Duration(seconds: 2),
                backgroundColor: AppColors.surfaceGlass,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          } else {
            SystemNavigator.pop();
          }
        },
        child: Column(
          children: [
            BreadcrumbBar(
              currentPath: explorerState.currentPath,
              onNavigate: (path) => notifier.navigateTo(path),
            ),
            if (explorerState.clipboard != null)
              _buildClipboardPasteBar(context, explorerState, notifier),
            Expanded(
              child: RefreshIndicator(
                color: currentTheme.primary,
                backgroundColor: AppColors.surfaceDark,
                onRefresh: () => notifier.loadDirectory(explorerState.currentPath),
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  interactive: true,
                  thickness: 5,
                  radius: const Radius.circular(3),
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      // Scrollable Header: Storage Indicator & Browse Installed APKs
                      if (isRoot && explorerState.volume != null) ...[
                        SliverToBoxAdapter(
                          child: StorageIndicator(volume: explorerState.volume),
                        ),
                        SliverToBoxAdapter(
                          child: _buildQuickAccessRow(context, notifier, currentTheme),
                        ),
                      ],

                      // Scrollable Error Banner if any
                      if (explorerState.errorMessage != null)
                        SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    explorerState.errorMessage!,
                                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      if (items.isEmpty && !explorerState.isLoading)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isSearching ? Icons.search_off_rounded : Icons.folder_open_rounded,
                                  size: 64,
                                  color: AppColors.textMuted.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _isSearching ? 'No files match "${explorerState.searchQuery}"' : 'This folder is empty',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = items[index];
                              final isSelected =
                                  explorerState.selectedPaths.contains(item.path);

                              return FileTile(
                                key: ValueKey(item.path),
                                item: item,
                                isSelected: isSelected,
                                isSelectionMode: explorerState.isSelectionMode,
                                onTap: () {
                                  if (explorerState.isSelectionMode) {
                                    notifier.toggleSelection(item.path);
                                  } else if (item.isDirectory) {
                                    setState(() {
                                      _isSearching = false;
                                      _searchController.clear();
                                    });
                                    notifier.navigateTo(item.path);
                                  } else {
                                    _openFile(context, item);
                                  }
                                },
                                onLongPress: () {
                                  notifier.toggleSelection(item.path);
                                },
                                onMoreOptions: () {
                                  _showItemOptionsModal(context, item, notifier);
                                },
                              );
                            },
                            childCount: items.length,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (explorerState.isSelectionMode)
              _buildSelectionBottomBar(context, explorerState, notifier, currentTheme),
          ],
        ),
      ),
      floatingActionButton: explorerState.isSelectionMode
          ? null
          : FloatingActionButton(
              backgroundColor: currentTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onPressed: () => _showCreateFolderDialog(context, notifier),
              child: const Icon(Icons.create_new_folder_rounded, size: 24),
            ),
    );
  }

  Widget _buildSelectionBottomBar(
    BuildContext context,
    FileExplorerState state,
    FileExplorerNotifier notifier,
    AppThemeColor currentTheme,
  ) {
    final count = state.selectedPaths.length;
    final selectedList = state.selectedPaths.toList();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(
          top: BorderSide(color: AppColors.glassBorder, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Text(
              '$count selected',
              style: TextStyle(
                color: currentTheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Copy',
              icon: const Icon(Icons.copy_rounded, size: 20, color: AppColors.textPrimary),
              onPressed: () {
                notifier.copySelection(selectedList);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Copied $count item(s) to clipboard'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            IconButton(
              tooltip: 'Cut',
              icon: const Icon(Icons.content_cut_rounded, size: 20, color: AppColors.textPrimary),
              onPressed: () {
                notifier.cutSelection(selectedList);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cut $count item(s) to clipboard'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            IconButton(
              tooltip: 'Compress',
              icon: const Icon(Icons.archive_rounded, size: 20, color: AppColors.textPrimary),
              onPressed: () => _showCompressDialog(context, selectedList, notifier),
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_rounded, size: 20, color: AppColors.danger),
              onPressed: () => _confirmDeleteSelected(context, notifier, count),
            ),
            IconButton(
              tooltip: 'Cancel',
              icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
              onPressed: () => notifier.clearSelection(),
            ),
          ],
        ),
      ),
    );
  }

  void _openSortSheet(
    BuildContext context,
    FileExplorerState state,
    FileExplorerNotifier notifier,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SortFilterSheet(
        currentSort: state.sortBy,
        ascending: state.sortAscending,
        showHidden: state.showHidden,
        onApply: (sort, asc, hidden) {
          notifier.setSort(sort, asc, hidden);
        },
      ),
    );
  }

  void _openFile(BuildContext context, FileItem item) {
    final ext = item.extension.toLowerCase();
    const imageExts = {'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp', 'svg', 'heic', 'avif', 'ico'};
    const textExts = {
      'txt', 'md', 'json', 'log', 'xml', 'yaml', 'yml', 'dart', 'kt', 'java',
      'py', 'js', 'ts', 'html', 'css', 'csv', 'ini', 'conf', 'sh', 'gradle',
      'kts', 'properties', 'c', 'cpp', 'h', 'hpp', 'cs', 'go', 'rs', 'php', 'sql'
    };
    const audioExts = {'mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a', 'wma', 'opus', 'mid', 'amr'};
    const videoExts = {'mp4', 'mkv', 'webm', 'avi', 'mov', '3gp', 'flv', 'wmv', 'ts', 'm4v'};

    if (imageExts.contains(ext)) {
      final gallery = ref
          .read(fileExplorerProvider)
          .filteredItems
          .where((e) => !e.isDirectory && imageExts.contains(e.extension.toLowerCase()))
          .toList();
      final initialIdx = gallery.indexWhere((e) => e.path == item.path);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ImageViewerScreen(
            item: item,
            galleryItems: gallery,
            initialIndex: initialIdx != -1 ? initialIdx : 0,
          ),
        ),
      );
    } else if (item.isArchive) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ArchiveViewerScreen(archiveItem: item)),
      );
    } else if (textExts.contains(ext)) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TextEditorScreen(item: item)),
      );
    } else if (ext == 'pdf') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PdfViewerScreen(item: item)),
      );
    } else if (audioExts.contains(ext)) {
      AudioPlayerModal.show(context, item);
    } else if (videoExts.contains(ext)) {
      VideoViewerModal.show(context, item);
    } else {
      _openFileDetails(context, item);
    }
  }

  void _openFileDetails(BuildContext context, FileItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FileDetailsScreen(item: item),
      ),
    );
  }

  void _showItemOptionsModal(
    BuildContext context,
    FileItem item,
    FileExplorerNotifier notifier,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        decoration: const BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_browser_rounded, color: AppColors.textPrimary),
              title: const Text('Open', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                if (item.isArchive) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ArchiveViewerScreen(archiveItem: item)),
                  );
                } else {
                  _openFile(context, item);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new_rounded, color: AppColors.textPrimary),
              title: const Text('Open In', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                ref.read(platformServiceProvider).openFileWithSystemApp(item.path);
              },
            ),
            if (item.isArchive)
              ListTile(
                leading: const Icon(Icons.unarchive_rounded, color: AppColors.archivePurple),
                title: const Text('Extract Archive...', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  _showArchiveExtractModal(context, item, notifier);
                },
              ),
            ListTile(
              leading: const Icon(Icons.copy_rounded, color: AppColors.textPrimary),
              title: const Text('Copy', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                notifier.copySelection([item.path]);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Copied "${item.name}" to clipboard'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.content_cut_rounded, color: AppColors.textPrimary),
              title: const Text('Cut', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                notifier.cutSelection([item.path]);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cut "${item.name}" to clipboard'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive_rounded, color: AppColors.textPrimary),
              title: const Text('Compress', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _showCompressDialog(context, [item.path], notifier);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: AppColors.textPrimary),
              title: const Text('Rename', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context, item, notifier);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded, color: AppColors.accentTeal),
              title: const Text('View Details', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _openFileDetails(context, item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: AppColors.danger),
              title: const Text('Delete', style: TextStyle(color: AppColors.danger)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteSingle(context, item, notifier);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClipboardPasteBar(
    BuildContext context,
    FileExplorerState state,
    FileExplorerNotifier notifier,
  ) {
    final clip = state.clipboard;
    if (clip == null || clip.paths.isEmpty) return const SizedBox.shrink();

    final isCopy = clip.op == FileClipboardOp.copy;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accentTeal, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(
            isCopy ? Icons.copy_rounded : Icons.content_cut_rounded,
            color: AppColors.accentTeal,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${clip.paths.length} item${clip.paths.length > 1 ? 's' : ''} staged to ${isCopy ? 'copy' : 'move'}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentTeal,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            icon: const Icon(Icons.content_paste_rounded, size: 14),
            label: const Text('Paste Here', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            onPressed: () async {
              final ok = await notifier.pasteClipboard(state.currentPath);
              if (context.mounted && ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Pasted ${clip.paths.length} item(s) successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
            tooltip: 'Cancel',
            onPressed: () => notifier.clearClipboard(),
          ),
        ],
      ),
    );
  }

  void _showArchiveExtractModal(
    BuildContext context,
    FileItem item,
    FileExplorerNotifier notifier,
  ) {
    final parentDir = item.path.substring(0, item.path.lastIndexOf('/'));
    final folderName = item.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
    final specificDir = '$parentDir/$folderName';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        decoration: const BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.folder_zip_rounded, color: AppColors.archivePurple, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.unarchive_rounded, color: AppColors.accentTeal),
              title: const Text('Extract Here', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: Text(parentDir, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              onTap: () {
                Navigator.pop(ctx);
                _extractArchiveFlow(context, item, parentDir, notifier);
              },
            ),
            ListTile(
              leading: const Icon(Icons.create_new_folder_rounded, color: AppColors.folderGold),
              title: Text('Extract to /$folderName/', style: const TextStyle(color: AppColors.textPrimary)),
              subtitle: Text(specificDir, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              onTap: () {
                Navigator.pop(ctx);
                _extractArchiveFlow(context, item, specificDir, notifier);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary),
              title: const Text('Archive Details', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _openFileDetails(context, item);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _extractArchiveFlow(
    BuildContext context,
    FileItem item,
    String targetDir,
    FileExplorerNotifier notifier,
  ) async {
    final isEncrypted = await ref.read(platformServiceProvider).isArchiveEncrypted(item.path);
    String? password;
    if (isEncrypted) {
      if (!context.mounted) return;
      password = await showDialog<String>(
        context: context,
        builder: (_) => ArchivePasswordDialog(archiveName: item.name),
      );
      if (password == null) return;
    }

    try {
      await notifier.extractArchive(
        archivePath: item.path,
        destinationPath: targetDir,
        password: password,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Extracted "${item.name}" successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        if (e.toString().contains('INVALID_PASSWORD')) {
          final retryPassword = await showDialog<String>(
            context: context,
            builder: (_) => ArchivePasswordDialog(archiveName: item.name),
          );
          if (retryPassword != null) {
            try {
              await notifier.extractArchive(
                archivePath: item.path,
                destinationPath: targetDir,
                password: retryPassword,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Extracted "${item.name}" successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            } catch (err) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Extraction failed: $err'),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Extraction failed: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  Future<void> _showCompressDialog(
    BuildContext context,
    List<String> paths,
    FileExplorerNotifier notifier,
  ) async {
    if (paths.isEmpty) return;
    final defaultName = paths.length == 1
        ? paths.first.split('/').last.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '')
        : 'Archive';

    final result = await showDialog<CompressDialogResult>(
      context: context,
      builder: (_) => CompressDialog(
        defaultName: defaultName,
        itemCount: paths.length,
      ),
    );

    if (result == null || !context.mounted) return;

    final currentDir = ref.read(fileExplorerProvider).currentPath;
    final ext = result.format == 'tar.gz' ? 'tar.gz' : result.format;
    final destZipPath = '$currentDir/${result.filename}.$ext';

    final ok = await notifier.compressArchive(
      paths: paths,
      destinationPath: destZipPath,
      format: result.format,
      password: result.password,
    );

    if (context.mounted && ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Created ${result.filename}.$ext successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showCreateFolderDialog(BuildContext context, FileExplorerNotifier notifier) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Folder', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          cursorColor: AppColors.accentTeal,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Folder name',
            hintStyle: TextStyle(color: AppColors.textMuted),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.accentTeal),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentTeal,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                notifier.createFolder(name);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(
    BuildContext context,
    FileItem item,
    FileExplorerNotifier notifier,
  ) {
    final controller = TextEditingController(text: item.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Item', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          cursorColor: AppColors.accentTeal,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.accentTeal),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentTeal,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != item.name) {
                notifier.renameItem(item.path, newName);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSingle(
    BuildContext context,
    FileItem item,
    FileExplorerNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Are you sure you want to permanently delete "${item.name}"?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              notifier.deleteSingle(item.path);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSelected(
    BuildContext context,
    FileExplorerNotifier notifier,
    int count,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Bulk Delete', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Are you sure you want to permanently delete $count selected items?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              notifier.deleteSelected();
              Navigator.pop(ctx);
            },
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessRow(
    BuildContext context,
    FileExplorerNotifier notifier,
    AppThemeColor currentTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                notifier.navigateTo('/Installed Apps (APKs)');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceGlass,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Browse Installed APKs & Packages',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: currentTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
