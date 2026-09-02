import '../utils/file_utils.dart';

class FileItem {
  final String path;
  final String name;
  final int size;
  final bool isDirectory;
  final DateTime lastModified;
  final bool canRead;
  final bool canWrite;
  final bool isHidden;
  final String extension;
  final String mimeType;
  final int childCount;
  final String? md5;
  final String? sha256;

  const FileItem({
    required this.path,
    required this.name,
    required this.size,
    required this.isDirectory,
    required this.lastModified,
    this.canRead = true,
    this.canWrite = true,
    this.isHidden = false,
    this.extension = '',
    this.mimeType = '*/*',
    this.childCount = 0,
    this.md5,
    this.sha256,
  });

  factory FileItem.fromMap(Map<dynamic, dynamic> map) {
    final rawLastModified = map['lastModified'];
    final DateTime modified = rawLastModified is int
        ? DateTime.fromMillisecondsSinceEpoch(rawLastModified)
        : (rawLastModified is DateTime ? rawLastModified : DateTime.now());

    return FileItem(
      path: map['path'] as String? ?? '',
      name: map['name'] as String? ?? '',
      size: (map['size'] as num?)?.toInt() ?? 0,
      isDirectory: map['isDirectory'] as bool? ?? false,
      lastModified: modified,
      canRead: map['canRead'] as bool? ?? true,
      canWrite: map['canWrite'] as bool? ?? true,
      isHidden: map['isHidden'] as bool? ?? false,
      extension: (map['extension'] as String? ?? '').toLowerCase(),
      mimeType: map['mimeType'] as String? ?? '*/*',
      childCount: (map['childCount'] as num?)?.toInt() ?? 0,
      md5: map['md5'] as String?,
      sha256: map['sha256'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'name': name,
      'size': size,
      'isDirectory': isDirectory,
      'lastModified': lastModified.millisecondsSinceEpoch,
      'canRead': canRead,
      'canWrite': canWrite,
      'isHidden': isHidden,
      'extension': extension,
      'mimeType': mimeType,
      'childCount': childCount,
      'md5': md5,
      'sha256': sha256,
    };
  }

  bool get isArchive => const {
        'zip',
        'rar',
        '7z',
        'tar',
        'gz',
        'bz2',
        'xz',
        'jar',
        'iso',
        'tgz',
        'zst'
      }.contains(extension.toLowerCase());

  bool get isImage => const {
        'jpg',
        'jpeg',
        'png',
        'gif',
        'webp',
        'bmp',
        'svg',
        'heic',
        'avif',
        'ico'
      }.contains(extension.toLowerCase());

  bool get isVideo => const {
        'mp4',
        'mkv',
        'avi',
        'mov',
        'wmv',
        'flv',
        'webm',
        '3gp',
        'm4v',
        'ts'
      }.contains(extension.toLowerCase());

  bool get isAudio => const {
        'mp3',
        'wav',
        'ogg',
        'flac',
        'm4a',
        'aac',
        'wma',
        'opus',
        'mid',
        'amr'
      }.contains(extension.toLowerCase());

  bool get isPdf => extension.toLowerCase() == 'pdf';

  bool get isText => const {
        'txt',
        'log',
        'ini',
        'conf',
        'cfg',
        'properties',
        'env',
        'gradle',
        'bat',
        'sh'
      }.contains(extension.toLowerCase());

  bool get isDocument => const {
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'ppt',
        'pptx',
        'txt',
        'rtf',
        'csv',
        'odt',
        'epub'
      }.contains(extension.toLowerCase());

  bool get isCode => const {
        'dart',
        'kt',
        'java',
        'py',
        'js',
        'ts',
        'html',
        'css',
        'json',
        'xml',
        'yaml',
        'yml',
        'c',
        'cpp',
        'h',
        'hpp',
        'cs',
        'go',
        'rs',
        'php',
        'sh',
        'sql',
        'md'
      }.contains(extension.toLowerCase());

  bool get isFont => const {
        'ttf',
        'otf',
        'woff',
        'woff2',
        'eot'
      }.contains(extension.toLowerCase());

  bool get isBinary => const {
        'bin',
        'so',
        'dex',
        'dat',
        'dll',
        'exe',
        'o'
      }.contains(extension.toLowerCase());

  bool get isApk => const {'apk', 'xapk', 'apks', 'apkm'}.contains(extension.toLowerCase());

  String get formattedSize => FileUtils.formatBytes(size);

  FileItem copyWith({
    String? path,
    String? name,
    int? size,
    bool? isDirectory,
    DateTime? lastModified,
    bool? canRead,
    bool? canWrite,
    bool? isHidden,
    String? extension,
    String? mimeType,
    int? childCount,
    String? md5,
    String? sha256,
  }) {
    return FileItem(
      path: path ?? this.path,
      name: name ?? this.name,
      size: size ?? this.size,
      isDirectory: isDirectory ?? this.isDirectory,
      lastModified: lastModified ?? this.lastModified,
      canRead: canRead ?? this.canRead,
      canWrite: canWrite ?? this.canWrite,
      isHidden: isHidden ?? this.isHidden,
      extension: extension ?? this.extension,
      mimeType: mimeType ?? this.mimeType,
      childCount: childCount ?? this.childCount,
      md5: md5 ?? this.md5,
      sha256: sha256 ?? this.sha256,
    );
  }
}
