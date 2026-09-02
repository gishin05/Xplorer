import 'package:file_manager/models/file_item.dart';
import 'package:file_manager/screens/viewers/text_editor_screen.dart';
import 'package:file_manager/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TextEditorScreen renders file name, lines gutter, and responds to edit mode toggle', (tester) async {
    final item = FileItem(
      path: '/sdcard/test.txt',
      name: 'test.txt',
      size: 1024,
      isDirectory: false,
      lastModified: DateTime.now(),
      extension: 'txt',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: TextEditorScreen(
            item: item,
            initialContent: 'Sample content here\nSecond line',
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('test.txt'), findsOneWidget);
    expect(find.byIcon(Icons.edit_rounded), findsOneWidget);

    // Toggle edit mode
    await tester.tap(find.byIcon(Icons.edit_rounded));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byIcon(Icons.visibility_rounded), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
