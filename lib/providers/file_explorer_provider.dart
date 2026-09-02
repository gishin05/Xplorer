import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/file_item.dart';
import '../models/storage_volume.dart';
import '../services/platform_channel_service.dart';
import '../widgets/sort_filter_sheet.dart';

enum FileClipboardOp { copy, cut }

class FileClipboardData {
  final List<String> paths;
  final FileClipboardOp op;

  const FileClipboardData({required this.paths, required this.op});
}

class FileExplorerState {
  final String currentPath;
  final List<FileItem> items;
  final StorageVolume? volume;
  final Set<String> selectedPaths;
  final bool isSelectionMode;
  final String searchQuery;
  final SortBy sortBy;
  final bool sortAscending;
  final bool showHidden;
  final bool isLoading;
  final String? errorMessage;
  final FileClipboardData? clipboard;

  const FileExplorerState({
    required this.currentPath,
    this.items = const [],
    this.volume,
    this.selectedPaths = const {},
    this.isSelectionMode = false,
    this.searchQuery = '',
    this.sortBy = SortBy.name,
    this.sortAscending = true,
    this.showHidden = false,
    this.isLoading = false,
    this.errorMessage,
    this.clipboard,
  });

  FileExplorerState copyWith({
    String? currentPath,
    List<FileItem>? items,
    StorageVolume? volume,
    Set<String>? selectedPaths,
    bool? isSelectionMode,
    String? searchQuery,
    SortBy? sortBy,
    bool? sortAscending,
    bool? showHidden,
    bool? isLoading,
    String? errorMessage,
    FileClipboardData? clipboard,
    bool clearClipboard = false,
  }) {
    return FileExplorerState(
      currentPath: currentPath ?? this.currentPath,
      items: items ?? this.items,
      volume: volume ?? this.volume,
      selectedPaths: selectedPaths ?? this.selectedPaths,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
      showHidden: showHidden ?? this.showHidden,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      clipboard: clearClipboard ? null : (clipboard ?? this.clipboard),
    );
  }

  List<FileItem> get filteredItems {
    var result = items;

    // Search query filtering
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((e) => e.name.toLowerCase().contains(q)).toList();
    }

    // Sort: Always group folders first, then sort by selected criteria
    result = List<FileItem>.from(result)..sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;

      int comp;
      switch (sortBy) {
        case SortBy.name:
          comp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case SortBy.date:
          comp = a.lastModified.compareTo(b.lastModified);
          break;
        case SortBy.size:
          comp = a.size.compareTo(b.size);
          break;
        case SortBy.type:
          comp = a.extension.compareTo(b.extension);
          if (comp == 0) {
            comp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          }
          break;
      }
      return sortAscending ? comp : -comp;
    });

    return result;
  }
}

class FileExplorerNotifier extends StateNotifier<FileExplorerState> {
  final PlatformChannelService _platformService;

  FileExplorerNotifier(this._platformService)
      : super(const FileExplorerState(currentPath: '/storage/emulated/0')) {
    initialize();
  }

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final volumes = await _platformService.getStorageVolumes();
      final primary = volumes.isNotEmpty ? volumes.first : null;
      final startPath = primary?.path ?? '/storage/emulated/0';

      state = state.copyWith(
        currentPath: startPath,
        volume: primary,
      );

      await loadDirectory(startPath);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> loadDirectory(String path) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      List<FileItem> items;
      if (path == '/Installed Apps (APKs)' || path == '/virtual/installed_apks') {
        items = await _platformService.getInstalledApplications();
      } else {
        items = await _platformService.listDirectory(
          path,
          showHidden: state.showHidden,
        );
      }

      state = state.copyWith(
        currentPath: path,
        items: items,
        isLoading: false,
        selectedPaths: {},
        isSelectionMode: false,
        searchQuery: '',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to open directory: $e',
      );
    }
  }

  void navigateTo(String path) {
    loadDirectory(path);
  }

  void navigateUp() {
    final current = state.currentPath;
    if (current == '/' || current == '/storage/emulated/0') return;
    if (current == '/Installed Apps (APKs)' || current == '/virtual/installed_apks') {
      final startPath = state.volume?.path ?? '/storage/emulated/0';
      loadDirectory(startPath);
      return;
    }

    final lastSlash = current.lastIndexOf('/');
    if (lastSlash > 0) {
      final parent = current.substring(0, lastSlash);
      loadDirectory(parent);
    } else {
      loadDirectory('/');
    }
  }

  void toggleSelection(String path) {
    final updated = Set<String>.from(state.selectedPaths);
    if (updated.contains(path)) {
      updated.remove(path);
    } else {
      updated.add(path);
    }

    state = state.copyWith(
      selectedPaths: updated,
      isSelectionMode: updated.isNotEmpty,
    );
  }

  void selectAll() {
    final allPaths = state.filteredItems.map((e) => e.path).toSet();
    state = state.copyWith(
      selectedPaths: allPaths,
      isSelectionMode: true,
    );
  }

  void clearSelection() {
    state = state.copyWith(
      selectedPaths: {},
      isSelectionMode: false,
    );
  }

  void setSort(SortBy sort, bool ascending, bool showHidden) {
    final hiddenChanged = state.showHidden != showHidden;
    state = state.copyWith(
      sortBy: sort,
      sortAscending: ascending,
      showHidden: showHidden,
    );

    if (hiddenChanged) {
      loadDirectory(state.currentPath);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<bool> createFolder(String name) async {
    try {
      final ok = await _platformService.createDirectory(state.currentPath, name);
      if (ok) {
        await loadDirectory(state.currentPath);
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteSelected() async {
    try {
      for (final p in state.selectedPaths) {
        await _platformService.deleteFile(p);
      }
      await loadDirectory(state.currentPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteSingle(String path) async {
    try {
      final ok = await _platformService.deleteFile(path);
      if (ok) {
        await loadDirectory(state.currentPath);
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<bool> renameItem(String path, String newName) async {
    try {
      final ok = await _platformService.renameFile(path, newName);
      if (ok) {
        await loadDirectory(state.currentPath);
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  void copySelection(List<String> paths) {
    state = state.copyWith(
      clipboard: FileClipboardData(paths: paths, op: FileClipboardOp.copy),
      selectedPaths: {},
      isSelectionMode: false,
    );
  }

  void cutSelection(List<String> paths) {
    state = state.copyWith(
      clipboard: FileClipboardData(paths: paths, op: FileClipboardOp.cut),
      selectedPaths: {},
      isSelectionMode: false,
    );
  }

  void clearClipboard() {
    state = state.copyWith(clearClipboard: true);
  }

  Future<bool> pasteClipboard(String destinationDirPath) async {
    final clip = state.clipboard;
    if (clip == null || clip.paths.isEmpty) return false;

    state = state.copyWith(isLoading: true);
    try {
      for (final src in clip.paths) {
        final filename = src.split('/').last;
        final dest = '$destinationDirPath/$filename';
        if (src == dest) continue;

        if (clip.op == FileClipboardOp.copy) {
          await _platformService.copyFile(src, dest);
        } else {
          final ok = await _platformService.renameFile(src, dest);
          if (!ok) {
            await _platformService.copyFile(src, dest);
            await _platformService.deleteFile(src);
          }
        }
      }
      if (clip.op == FileClipboardOp.cut) {
        state = state.copyWith(clearClipboard: true);
      }
      await loadDirectory(destinationDirPath);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Paste failed: $e');
      return false;
    }
  }

  Future<bool> compressArchive({
    required List<String> paths,
    required String destinationPath,
    String format = 'zip',
    String? password,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final ok = await _platformService.compressArchive(
        sourcePaths: paths,
        destinationPath: destinationPath,
        format: format,
        password: password,
      );
      await loadDirectory(state.currentPath);
      return ok;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Compress failed: $e');
      return false;
    }
  }

  Future<bool> extractArchive({
    required String archivePath,
    required String destinationPath,
    String? password,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final ok = await _platformService.extractArchive(
        archivePath: archivePath,
        destinationPath: destinationPath,
        password: password,
      );
      await loadDirectory(state.currentPath);
      return ok;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Extract failed: $e');
      rethrow;
    }
  }
}

final platformServiceProvider = Provider<PlatformChannelService>((ref) {
  return PlatformChannelService();
});

final fileExplorerProvider =
    StateNotifierProvider<FileExplorerNotifier, FileExplorerState>((ref) {
  final service = ref.watch(platformServiceProvider);
  return FileExplorerNotifier(service);
});
