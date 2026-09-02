import 'package:flutter_test/flutter_test.dart';
import 'package:file_manager/models/permission_status.dart';
import 'package:file_manager/models/storage_volume.dart';

void main() {
  group('Permission & Storage Models Tests', () {
    test('StoragePermissionStatus parses maps and detects elevation', () {
      final status1 = StoragePermissionStatus.fromMap({
        'hasAllFilesAccess': true,
        'isDeviceOwner': false,
        'androidVersion': 34,
        'primaryStoragePath': '/storage/emulated/0',
      });
      expect(status1.hasAllFilesAccess, isTrue);
      expect(status1.isElevated, isTrue);

      final status2 = StoragePermissionStatus.fromMap({
        'hasAllFilesAccess': false,
        'isDeviceOwner': true,
        'androidVersion': 33,
        'primaryStoragePath': '/storage/emulated/0',
      });
      expect(status2.isDeviceOwner, isTrue);
      expect(status2.isElevated, isTrue);

      final status3 = StoragePermissionStatus.fromMap({
        'hasAllFilesAccess': false,
        'isDeviceOwner': false,
        'androidVersion': 30,
        'primaryStoragePath': '/storage/emulated/0',
      });
      expect(status3.isElevated, isFalse);
    });

    test('StorageVolume calculates usage percentage correctly', () {
      const vol = StorageVolume(
        path: '/storage/emulated/0',
        description: 'Internal Storage',
        isPrimary: true,
        isRemovable: false,
        totalBytes: 1000,
        freeBytes: 250,
        usedBytes: 750,
      );
      expect(vol.usagePercent, 0.75);
    });
  });
}
