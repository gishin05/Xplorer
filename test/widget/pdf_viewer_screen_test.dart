import 'package:file_manager/models/file_item.dart';
import 'package:file_manager/screens/viewers/pdf_viewer_screen.dart';
import 'package:file_manager/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PdfViewerScreen renders document title and jump actions', (tester) async {
    final item = FileItem(
      path: '/sdcard/manual.pdf',
      name: 'manual.pdf',
      size: 5 * 1024 * 1024,
      isDirectory: false,
      lastModified: DateTime.now(),
      extension: 'pdf',
      mimeType: 'application/pdf',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: PdfViewerScreen(item: item),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('manual.pdf'), findsOneWidget);
    expect(find.byIcon(Icons.pin_invoke_rounded), findsOneWidget);
  });
}
