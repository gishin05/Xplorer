class StorageVolume {
  final String path;
  final String description;
  final bool isPrimary;
  final bool isRemovable;
  final int totalBytes;
  final int freeBytes;
  final int usedBytes;

  const StorageVolume({
    required this.path,
    required this.description,
    required this.isPrimary,
    required this.isRemovable,
    required this.totalBytes,
    required this.freeBytes,
    required this.usedBytes,
  });

  double get usagePercent {
    if (totalBytes <= 0) return 0.0;
    return (usedBytes / totalBytes).clamp(0.0, 1.0);
  }

  factory StorageVolume.fromMap(Map<dynamic, dynamic> map) {
    final total = (map['totalBytes'] as num?)?.toInt() ?? 0;
    final free = (map['freeBytes'] as num?)?.toInt() ?? 0;
    final used = (map['usedBytes'] as num?)?.toInt() ?? (total > free ? total - free : 0);

    return StorageVolume(
      path: map['path'] as String? ?? '/storage/emulated/0',
      description: map['description'] as String? ?? 'Internal Storage',
      isPrimary: map['isPrimary'] as bool? ?? true,
      isRemovable: map['isRemovable'] as bool? ?? false,
      totalBytes: total,
      freeBytes: free,
      usedBytes: used,
    );
  }
}
