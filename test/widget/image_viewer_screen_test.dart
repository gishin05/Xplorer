import 'package:file_manager/models/file_item.dart';
import 'package:file_manager/screens/viewers/image_viewer_screen.dart';
import 'package:file_manager/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ImageViewerScreen renders app bar with rotation and info actions', (tester) async {
    final item = FileItem(
      path: '/sdcard/photo.jpg',
      name: 'photo.jpg',
      size: 2 * 1024 * 1024,
      isDirectory: false,
      lastModified: DateTime.now(),
      extension: 'jpg',
      mimeType: 'image/jpeg',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: ImageViewerScreen(item: item),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('photo.jpg'), findsOneWidget);
    expect(find.byIcon(Icons.rotate_right_rounded), findsOneWidget);
    expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });

  testWidgets('ImageViewerScreen supports swiping across gallery items', (tester) async {
    final item1 = FileItem(
      path: '/sdcard/photo1.jpg',
      name: 'photo1.jpg',
      size: 1024,
      isDirectory: false,
      lastModified: DateTime.now(),
      extension: 'jpg',
      mimeType: 'image/jpeg',
    );
    final item2 = FileItem(
      path: '/sdcard/photo2.jpg',
      name: 'photo2.jpg',
      size: 2048,
      isDirectory: false,
      lastModified: DateTime.now(),
      extension: 'jpg',
      mimeType: 'image/jpeg',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: ImageViewerScreen(
            item: item1,
            galleryItems: [item1, item2],
            initialIndex: 0,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('photo1.jpg'), findsOneWidget);
    expect(find.textContaining('1 / 2'), findsOneWidget);

    // Swipe to next image
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('photo2.jpg'), findsOneWidget);
    expect(find.textContaining('2 / 2'), findsOneWidget);
  });
}
