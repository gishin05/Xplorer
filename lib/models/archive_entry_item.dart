class ArchiveEntryItem {
  final String name;
  final int uncompressedSize;
  final int compressedSize;
  final bool isDirectory;
  final int lastModified;
  final bool isEncrypted;

  const ArchiveEntryItem({
    required this.name,
    required this.uncompressedSize,
    required this.compressedSize,
    required this.isDirectory,
    required this.lastModified,
    required this.isEncrypted,
  });

  factory ArchiveEntryItem.fromMap(Map<dynamic, dynamic> map) {
    return ArchiveEntryItem(
      name: map['name'] as String? ?? '',
      uncompressedSize: (map['uncompressedSize'] as num?)?.toInt() ?? 0,
      compressedSize: (map['compressedSize'] as num?)?.toInt() ?? 0,
      isDirectory: map['isDirectory'] as bool? ?? false,
      lastModified: (map['lastModified'] as num?)?.toInt() ?? 0,
      isEncrypted: map['isEncrypted'] as bool? ?? false,
    );
  }
}
