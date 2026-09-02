import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_manager/models/file_item.dart';
import 'package:file_manager/widgets/file_tile.dart';

void main() {
  testWidgets('FileTile renders directory item with folder icon and child count', (WidgetTester tester) async {
    final folderItem = FileItem(
      path: '/storage/emulated/0/Download',
      name: 'Download',
      size: 0,
      isDirectory: true,
      lastModified: DateTime(2026, 1, 1),
      childCount: 15,
    );

    var tapped = false;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: FileTile(
              item: folderItem,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('Download'), findsOneWidget);
    expect(find.text('15 items'), findsOneWidget);

    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });

  testWidgets('FileTile renders file item with formatted size and responds to tap', (WidgetTester tester) async {
    final fileItem = FileItem(
      path: '/storage/emulated/0/Download/archive.zip',
      name: 'archive.zip',
      size: 1024 * 1024 * 12, // 12 MB
      isDirectory: false,
      lastModified: DateTime(2026, 1, 1),
      extension: 'zip',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: FileTile(
              item: fileItem,
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('archive.zip'), findsOneWidget);
    expect(find.text('12.0 MB'), findsOneWidget);
  });
}
