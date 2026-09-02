import 'package:file_manager/models/archive_entry_item.dart';
import 'package:file_manager/models/file_item.dart';
import 'package:file_manager/providers/file_explorer_provider.dart';
import 'package:file_manager/screens/viewers/archive_viewer_screen.dart';
import 'package:file_manager/services/platform_channel_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockPlatformService extends PlatformChannelService {
  @override
  Future<List<ArchiveEntryItem>> listArchiveEntries(String path, {String? password}) async {
    return [
      const ArchiveEntryItem(
        name: 'assets/sample.webp',
        uncompressedSize: 20480,
        compressedSize: 10240,
        isDirectory: false,
        lastModified: 1700000000000,
        isEncrypted: false,
      ),
      const ArchiveEntryItem(
        name: 'docs/readme.txt',
        uncompressedSize: 512,
        compressedSize: 256,
        isDirectory: false,
        lastModified: 1700000000000,
        isEncrypted: false,
      ),
      const ArchiveEntryItem(
        name: 'docs/',
        uncompressedSize: 0,
        compressedSize: 0,
        isDirectory: true,
        lastModified: 1700000000000,
        isEncrypted: false,
      ),
    ];
  }
}

void main() {
  testWidgets('ArchiveViewerScreen renders archive entries and allows inspection', (tester) async {
    final mockService = MockPlatformService();

    final testArchive = FileItem(
      path: '/storage/emulated/0/Download/test.zip',
      name: 'test.zip',
      size: 102400,
      isDirectory: false,
      lastModified: DateTime.now(),
      extension: 'zip',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          platformServiceProvider.overrideWithValue(mockService),
        ],
        child: MaterialApp(
          home: ArchiveViewerScreen(archiveItem: testArchive),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('test.zip'), findsOneWidget);
    expect(find.text('Extract All'), findsOneWidget);
    expect(find.text('sample.webp'), findsOneWidget);
    expect(find.text('readme.txt'), findsOneWidget);
    expect(find.text('docs'), findsNWidgets(2));
    expect(find.byIcon(Icons.folder_rounded), findsOneWidget);
  });
}
