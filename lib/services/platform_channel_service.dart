import 'dart:io';
import 'package:flutter/services.dart';
import '../models/file_item.dart';
import '../models/permission_status.dart';
import '../models/storage_volume.dart';

class PlatformChannelService {
  static const MethodChannel _channel = MethodChannel('com.antigravity.filemanager/bridge');

  Future<StoragePermissionStatus> checkPermissions() async {
    if (!Platform.isAndroid) {
      return const StoragePermissionStatus(
        hasAllFilesAccess: true,
        isDeviceOwner: false,
        androidVersion: 34,
        primaryStoragePath: '/storage/emulated/0',
      );
    }

    try {
      final Map<dynamic, dynamic>? result = await _channel.invokeMethod('checkPermissions');
      if (result != null) {
        return StoragePermissionStatus.fromMap(result);
      }
    } catch (_) {}

    return const StoragePermissionStatus(
      hasAllFilesAccess: false,
      isDeviceOwner: false,
      androidVersion: 30,
      primaryStoragePath: '/storage/emulated/0',
    );
  }

  Future<bool> requestAllFilesAccess() async {
    if (!Platform.isAndroid) return true;
    try {
      final bool? success = await _channel.invokeMethod('requestAllFilesAccess');
      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, bool>> checkDeveloperOptions() async {
    if (!Platform.isAndroid) {
      return {
        'isDevOptionsEnabled': true,
        'isAdbEnabled': true,
        'isAutoBridgeActive': true,
      };
    }

    try {
      final Map<dynamic, dynamic>? res = await _channel.invokeMethod('isDeveloperOptionsEnabled');
      if (res != null) {
        return {
          'isDevOptionsEnabled': res['isDevOptionsEnabled'] as bool? ?? false,
          'isAdbEnabled': res['isAdbEnabled'] as bool? ?? false,
          'isAutoBridgeActive': res['isAutoBridgeActive'] as bool? ?? false,
        };
      }
    } catch (_) {}

    return {
      'isDevOptionsEnabled': false,
      'isAdbEnabled': false,
      'isAutoBridgeActive': false,
    };
  }

  Future<bool> openDeveloperSettings() async {
    if (!Platform.isAndroid) return true;
    try {
      final bool? res = await _channel.invokeMethod('openDeveloperSettings');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<List<FileItem>> getInstalledApplications() async {
    if (!Platform.isAndroid) {
      return [
        FileItem(
          path: '/data/app/com.android.chrome/base.apk',
          name: 'Chrome',
          size: 110 * 1024 * 1024,
          isDirectory: false,
          lastModified: DateTime.now().subtract(const Duration(days: 3)),
          extension: 'apk',
          mimeType: 'application/vnd.android.package-archive',
        ),
        FileItem(
          path: '/data/app/com.google.android.youtube/base.apk',
          name: 'YouTube',
          size: 95 * 1024 * 1024,
          isDirectory: false,
          lastModified: DateTime.now().subtract(const Duration(days: 1)),
          extension: 'apk',
          mimeType: 'application/vnd.android.package-archive',
        ),
      ];
    }

    try {
      final List<dynamic>? list = await _channel.invokeMethod('getInstalledApplications');
      if (list != null) {
        return list.map((e) => FileItem.fromMap(e as Map<dynamic, dynamic>)).toList();
      }
    } catch (_) {}

    return [];
  }

  Future<List<StorageVolume>> getStorageVolumes() async {
    if (!Platform.isAndroid) {
      return [
        const StorageVolume(
          path: '/storage/emulated/0',
          description: 'Internal Storage',
          isPrimary: true,
          isRemovable: false,
          totalBytes: 128 * 1024 * 1024 * 1024,
          freeBytes: 64 * 1024 * 1024 * 1024,
          usedBytes: 64 * 1024 * 1024 * 1024,
        ),
      ];
    }

    try {
      final List<dynamic>? rawList = await _channel.invokeMethod('getStorageVolumes');
      if (rawList != null) {
        return rawList.map((e) => StorageVolume.fromMap(e as Map<dynamic, dynamic>)).toList();
      }
    } catch (_) {}

    return [
      const StorageVolume(
        path: '/storage/emulated/0',
        description: 'Internal Storage',
        isPrimary: true,
        isRemovable: false,
        totalBytes: 100 * 1024 * 1024 * 1024,
        freeBytes: 50 * 1024 * 1024 * 1024,
        usedBytes: 50 * 1024 * 1024 * 1024,
      ),
    ];
  }

  Future<List<FileItem>> listDirectory(String path, {bool showHidden = false}) async {
    if (!Platform.isAndroid) {
      // In non-Android or tests, return mock demonstration structure if real path does not exist
      final dir = Directory(path);
      if (await dir.exists()) {
        final List<FileSystemEntity> entities = await dir.list().toList();
        final List<FileItem> items = [];
        for (final e in entities) {
          final stat = await e.stat();
          final isDir = stat.type == FileSystemEntityType.directory;
          final name = e.path.split(Platform.pathSeparator).last;
          final isHidden = name.startsWith('.');
          if (!showHidden && isHidden) continue;
          items.add(FileItem(
            path: e.path,
            name: name,
            size: stat.size,
            isDirectory: isDir,
            lastModified: stat.modified,
            isHidden: isHidden,
            extension: isDir ? '' : (name.contains('.') ? name.split('.').last : ''),
            childCount: isDir ? 0 : 0,
          ));
        }
        return items;
      }

      // Mock sample files for tests/desktop
      return [
        FileItem(
          path: '$path/Android',
          name: 'Android',
          size: 0,
          isDirectory: true,
          lastModified: DateTime.now().subtract(const Duration(days: 2)),
          childCount: 4,
        ),
        FileItem(
          path: '$path/Download',
          name: 'Download',
          size: 0,
          isDirectory: true,
          lastModified: DateTime.now().subtract(const Duration(hours: 3)),
          childCount: 12,
        ),
        FileItem(
          path: '$path/DCIM',
          name: 'DCIM',
          size: 0,
          isDirectory: true,
          lastModified: DateTime.now().subtract(const Duration(days: 5)),
          childCount: 48,
        ),
        FileItem(
          path: '$path/Documents',
          name: 'Documents',
          size: 0,
          isDirectory: true,
          lastModified: DateTime.now().subtract(const Duration(days: 1)),
          childCount: 6,
        ),
        FileItem(
          path: '$path/backup_data.zip',
          name: 'backup_data.zip',
          size: 45 * 1024 * 1024,
          isDirectory: false,
          lastModified: DateTime.now().subtract(const Duration(days: 1)),
          extension: 'zip',
        ),
        FileItem(
          path: '$path/application_v2.apk',
          name: 'application_v2.apk',
          size: 28 * 1024 * 1024,
          isDirectory: false,
          lastModified: DateTime.now().subtract(const Duration(hours: 1)),
          extension: 'apk',
        ),
        FileItem(
          path: '$path/system_log.txt',
          name: 'system_log.txt',
          size: 14 * 1024,
          isDirectory: false,
          lastModified: DateTime.now(),
          extension: 'txt',
        ),
      ];
    }

    try {
      final List<dynamic>? rawList = await _channel.invokeMethod('listDirectory', {
        'path': path,
        'showHidden': showHidden,
      });

      if (rawList != null) {
        return rawList.map((e) => FileItem.fromMap(e as Map<dynamic, dynamic>)).toList();
      }
    } catch (e) {
      throw Exception('Failed to read directory: $e');
    }

    return [];
  }

  Future<FileItem?> getFileInfo(String path) async {
    if (!Platform.isAndroid) {
      return FileItem(
        path: path,
        name: path.split('/').last,
        size: 1024 * 50,
        isDirectory: false,
        lastModified: DateTime.now(),
      );
    }

    try {
      final Map<dynamic, dynamic>? result = await _channel.invokeMethod('getFileInfo', {'path': path});
      if (result != null) {
        return FileItem.fromMap(result);
      }
    } catch (_) {}
    return null;
  }

  Future<bool> createDirectory(String parentPath, String name) async {
    if (!Platform.isAndroid) {
      final dir = Directory('$parentPath/$name');
      await dir.create(recursive: true);
      return true;
    }
    final bool? res = await _channel.invokeMethod('createDirectory', {
      'parentPath': parentPath,
      'name': name,
    });
    return res ?? false;
  }

  Future<bool> deleteFile(String path) async {
    if (!Platform.isAndroid) {
      final f = File(path);
      if (await f.exists()) {
        await f.delete();
        return true;
      }
      final d = Directory(path);
      if (await d.exists()) {
        await d.delete(recursive: true);
        return true;
      }
      return true;
    }
    final bool? res = await _channel.invokeMethod('deleteFile', {'path': path});
    return res ?? false;
  }

  Future<bool> renameFile(String path, String newName) async {
    if (!Platform.isAndroid) return true;
    final bool? res = await _channel.invokeMethod('renameFile', {
      'path': path,
      'newName': newName,
    });
    return res ?? false;
  }

  Future<bool> copyFile(String sourcePath, String destinationPath) async {
    if (!Platform.isAndroid) return true;
    final bool? res = await _channel.invokeMethod('copyFile', {
      'sourcePath': sourcePath,
      'destinationPath': destinationPath,
    });
    return res ?? false;
  }

  Future<String> readFile(String path) async {
    if (!Platform.isAndroid) {
      final f = File(path);
      if (await f.exists()) {
        return await f.readAsString();
      }
      return 'Sample content for $path';
    }
    try {
      final String? content = await _channel.invokeMethod('readFile', {'path': path});
      return content ?? '';
    } catch (e) {
      throw Exception('Failed to read file: $e');
    }
  }

  Future<bool> writeFile(String path, String content) async {
    if (!Platform.isAndroid) {
      final f = File(path);
      await f.parent.create(recursive: true);
      await f.writeAsString(content);
      return true;
    }
    try {
      final bool? res = await _channel.invokeMethod('writeFile', {
        'path': path,
        'content': content,
      });
      return res ?? false;
    } catch (e) {
      throw Exception('Failed to write file: $e');
    }
  }

  Future<int> getPdfPageCount(String path) async {
    if (!Platform.isAndroid) return 1;
    try {
      final int? count = await _channel.invokeMethod('getPdfPageCount', {'path': path});
      return count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<Uint8List?> renderPdfPage(
    String path,
    int pageIndex, {
    int width = 0,
    int height = 0,
  }) async {
    if (!Platform.isAndroid) return null;
    try {
      final dynamic raw = await _channel.invokeMethod('renderPdfPage', {
        'path': path,
        'pageIndex': pageIndex,
        'width': width,
        'height': height,
      });
      if (raw is Uint8List) return raw;
      if (raw is List<dynamic>) return Uint8List.fromList(raw.cast<int>());
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> playAudio(String path) async {
    if (!Platform.isAndroid) {
      return {'duration': 180000, 'position': 0, 'isPlaying': true};
    }
    try {
      final Map<dynamic, dynamic>? res = await _channel.invokeMethod('playAudio', {'path': path});
      return res != null ? Map<String, dynamic>.from(res) : {'duration': 0, 'position': 0, 'isPlaying': false};
    } catch (_) {
      return {'duration': 0, 'position': 0, 'isPlaying': false};
    }
  }

  Future<bool> pauseAudio() async {
    if (!Platform.isAndroid) return true;
    final bool? res = await _channel.invokeMethod('pauseAudio');
    return res ?? false;
  }

  Future<bool> resumeAudio() async {
    if (!Platform.isAndroid) return true;
    final bool? res = await _channel.invokeMethod('resumeAudio');
    return res ?? false;
  }

  Future<bool> seekAudio(int positionMs) async {
    if (!Platform.isAndroid) return true;
    final bool? res = await _channel.invokeMethod('seekAudio', {'positionMs': positionMs});
    return res ?? false;
  }

  Future<Map<String, dynamic>> getAudioPosition() async {
    if (!Platform.isAndroid) {
      return {'duration': 180000, 'position': 0, 'isPlaying': false};
    }
    try {
      final Map<dynamic, dynamic>? res = await _channel.invokeMethod('getAudioPosition');
      return res != null ? Map<String, dynamic>.from(res) : {'duration': 0, 'position': 0, 'isPlaying': false};
    } catch (_) {
      return {'duration': 0, 'position': 0, 'isPlaying': false};
    }
  }

  Future<bool> stopAudio() async {
    if (!Platform.isAndroid) return true;
    final bool? res = await _channel.invokeMethod('stopAudio');
    return res ?? false;
  }

  Future<bool> openFileWithSystemApp(String path, {String? mimeType}) async {
    if (!Platform.isAndroid) return true;
    try {
      final bool? res = await _channel.invokeMethod('openFileWithSystemApp', {
        'path': path,
        'mimeType': mimeType,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isArchiveEncrypted(String path) async {
    if (!Platform.isAndroid) return false;
    try {
      final bool? res = await _channel.invokeMethod('isArchiveEncrypted', {'path': path});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> compressArchive({
    required List<String> sourcePaths,
    required String destinationPath,
    String format = 'zip',
    String? password,
  }) async {
    if (!Platform.isAndroid) return true;
    try {
      final bool? res = await _channel.invokeMethod('compressArchive', {
        'sourcePaths': sourcePaths,
        'destinationPath': destinationPath,
        'format': format,
        'password': password,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> extractArchive({
    required String archivePath,
    required String destinationPath,
    String? password,
  }) async {
    if (!Platform.isAndroid) return true;
    final bool? res = await _channel.invokeMethod('extractArchive', {
      'archivePath': archivePath,
      'destinationPath': destinationPath,
      'password': password,
    });
    return res ?? false;
  }
}
