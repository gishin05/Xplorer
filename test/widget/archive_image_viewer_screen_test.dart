import 'package:file_manager/models/archive_entry_item.dart';
import 'package:file_manager/providers/file_explorer_provider.dart';
import 'package:file_manager/screens/viewers/archive_image_viewer_screen.dart';
import 'package:file_manager/services/platform_channel_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockExtractPlatformService extends PlatformChannelService {
  @override
  Future<String?> extractArchiveEntry({
    required String archivePath,
    required String entryName,
    required String destinationPath,
    String? password,
  }) async {
    return destinationPath;
  }
}

void main() {
  testWidgets('ArchiveImageViewerScreen allows swiping between archive images', (tester) async {
    final mockService = MockExtractPlatformService();

    final images = [
      const ArchiveEntryItem(
        name: 'photos/photo1.webp',
        uncompressedSize: 50000,
        compressedSize: 25000,
        isDirectory: false,
        lastModified: 1700000000000,
        isEncrypted: false,
      ),
      const ArchiveEntryItem(
        name: 'photos/photo2.png',
        uncompressedSize: 60000,
        compressedSize: 30000,
        isDirectory: false,
        lastModified: 1700000000000,
        isEncrypted: false,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          platformServiceProvider.overrideWithValue(mockService),
        ],
        child: MaterialApp(
          home: ArchiveImageViewerScreen(
            archivePath: '/storage/emulated/0/Download/test.zip',
            archiveName: 'test.zip',
            imageEntries: images,
            initialIndex: 0,
          ),
        ),
      ),
    );

    // Initial frame renders page 1
    await tester.pump();
    expect(find.text('photo1.webp'), findsOneWidget);
    expect(find.text('1 / 2  •  test.zip'), findsOneWidget);

    // Swipe left to go to next image
    await tester.fling(find.byType(PageView), const Offset(-500, 0), 1000);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    // Now page 2 is shown
    expect(find.text('photo2.png'), findsOneWidget);
    expect(find.text('2 / 2  •  test.zip'), findsOneWidget);
  });
}
