import 'package:flutter_test/flutter_test.dart';
import 'package:file_manager/utils/file_utils.dart';

void main() {
  group('FileUtils Tests', () {
    test('formatBytes formats binary magnitudes accurately', () {
      expect(FileUtils.formatBytes(0), '0 B');
      expect(FileUtils.formatBytes(512), '512 B');
      expect(FileUtils.formatBytes(1024), '1.0 KB');
      expect(FileUtils.formatBytes(1024 * 1024 * 5), '5.0 MB');
      expect(FileUtils.formatBytes(1024 * 1024 * 1024 * 2), '2.0 GB');
    });

    test('getCategory categorizes file extensions correctly', () {
      expect(FileUtils.getCategory('zip', false), 'Archive');
      expect(FileUtils.getCategory('7z', false), 'Archive');
      expect(FileUtils.getCategory('tar', false), 'Archive');
      expect(FileUtils.getCategory('apk', false), 'Package');
      expect(FileUtils.getCategory('png', false), 'Image');
      expect(FileUtils.getCategory('webp', false), 'Image');
      expect(FileUtils.getCategory('svg', false), 'Image');
      expect(FileUtils.getCategory('heic', false), 'Image');
      expect(FileUtils.getCategory('mp4', false), 'Video');
      expect(FileUtils.getCategory('mp3', false), 'Audio');
      expect(FileUtils.getCategory('pdf', false), 'Document');
      expect(FileUtils.getCategory('dart', false), 'Code');
      expect(FileUtils.getCategory('', true), 'Folder');
      expect(FileUtils.getCategory('xyz', false), 'File');
    });

    test('buildBreadcrumbs breaks path into hierarchy segments', () {
      final crumbs = FileUtils.buildBreadcrumbs('/storage/emulated/0/Download/Archives');
      expect(crumbs.length, 3);
      expect(crumbs[0].name, 'Internal Storage');
      expect(crumbs[0].path, '/storage/emulated/0');
      expect(crumbs[1].name, 'Download');
      expect(crumbs[1].path, '/storage/emulated/0/Download');
      expect(crumbs[2].name, 'Archives');
      expect(crumbs[2].path, '/storage/emulated/0/Download/Archives');
    });
  });
}
