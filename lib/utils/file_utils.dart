import 'dart:math';
import 'package:intl/intl.dart';

class FileUtils {
  static final DateFormat _dateFormat = DateFormat('MMM dd, yyyy  HH:mm');

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (log(bytes) / log(1024)).floor();
    final clampedIndex = i.clamp(0, suffixes.length - 1);
    final value = bytes / pow(1024, clampedIndex);
    return '${value.toStringAsFixed(clampedIndex == 0 ? 0 : 1)} ${suffixes[clampedIndex]}';
  }

  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  static String getCategory(String extension, bool isDirectory) {
    if (isDirectory) return 'Folder';
    final ext = extension.toLowerCase();

    if (const {'zip', 'rar', '7z', 'tar', 'gz', 'bz2', 'xz', 'jar', 'iso', 'tgz', 'zst'}.contains(ext)) {
      return 'Archive';
    }
    if (const {'apk', 'xapk', 'apks', 'apkm'}.contains(ext)) {
      return 'Package';
    }
    if (const {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg', 'heic', 'avif', 'ico'}.contains(ext)) {
      return 'Image';
    }
    if (const {'mp4', 'mkv', 'avi', 'mov', 'wmv', 'flv', 'webm', '3gp', 'm4v', 'ts'}.contains(ext)) {
      return 'Video';
    }
    if (const {'mp3', 'wav', 'ogg', 'flac', 'm4a', 'aac', 'opus', 'mid', 'amr'}.contains(ext)) {
      return 'Audio';
    }
    if (const {'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'csv', 'rtf', 'odt', 'epub'}.contains(ext)) {
      return 'Document';
    }
    if (const {'dart', 'kt', 'java', 'py', 'js', 'ts', 'html', 'css', 'json', 'xml', 'yaml', 'yml', 'c', 'cpp', 'h', 'hpp', 'cs', 'go', 'rs', 'php', 'sh', 'sql', 'md'}.contains(ext)) {
      return 'Code';
    }
    if (const {'ttf', 'otf', 'woff', 'woff2', 'eot'}.contains(ext)) {
      return 'Font';
    }
    if (const {'bin', 'so', 'dex', 'dat', 'dll', 'exe', 'o'}.contains(ext)) {
      return 'Binary';
    }
    return 'File';
  }

  static List<BreadcrumbSegment> buildBreadcrumbs(String currentPath) {
    final clean = currentPath.replaceAll('\\', '/');
    if (clean.isEmpty || clean == '/') {
      return [const BreadcrumbSegment(name: 'Root', path: '/')];
    }

    final segments = clean.split('/').where((s) => s.isNotEmpty).toList();
    final result = <BreadcrumbSegment>[];

    // Check if emulated storage
    if (clean.startsWith('/storage/emulated/0')) {
      result.add(const BreadcrumbSegment(name: 'Internal Storage', path: '/storage/emulated/0'));
      var accumulated = '/storage/emulated/0';
      // skip storage, emulated, 0
      final subSegments = segments.skip(3);
      for (final s in subSegments) {
        accumulated += '/$s';
        result.add(BreadcrumbSegment(name: s, path: accumulated));
      }
      return result;
    }

    var accumulated = '';
    for (final s in segments) {
      accumulated += '/$s';
      result.add(BreadcrumbSegment(name: s, path: accumulated));
    }

    return result;
  }
}

class BreadcrumbSegment {
  final String name;
  final String path;

  const BreadcrumbSegment({required this.name, required this.path});
}
