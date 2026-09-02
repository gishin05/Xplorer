class StoragePermissionStatus {
  final bool hasAllFilesAccess;
  final bool isDeviceOwner;
  final int androidVersion;
  final String primaryStoragePath;

  const StoragePermissionStatus({
    required this.hasAllFilesAccess,
    required this.isDeviceOwner,
    required this.androidVersion,
    required this.primaryStoragePath,
  });

  factory StoragePermissionStatus.fromMap(Map<dynamic, dynamic> map) {
    return StoragePermissionStatus(
      hasAllFilesAccess: map['hasAllFilesAccess'] as bool? ?? false,
      isDeviceOwner: map['isDeviceOwner'] as bool? ?? false,
      androidVersion: (map['androidVersion'] as num?)?.toInt() ?? 30,
      primaryStoragePath: map['primaryStoragePath'] as String? ?? '/storage/emulated/0',
    );
  }

  bool get isElevated => hasAllFilesAccess || isDeviceOwner;
}
