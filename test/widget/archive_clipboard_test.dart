import 'package:file_manager/providers/file_explorer_provider.dart';
import 'package:file_manager/theme/app_theme.dart';
import 'package:file_manager/widgets/archive_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ArchivePasswordDialog renders password field with toggle and action buttons', (tester) async {
    String? enteredPassword;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              enteredPassword = await showDialog<String>(
                context: context,
                builder: (_) => const ArchivePasswordDialog(archiveName: 'secret.zip'),
              );
            },
            child: const Text('Open Dialog'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Password Required'), findsOneWidget);
    expect(find.text('Archive Password'), findsOneWidget);
    expect(find.text('Extract'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Enter password
    await tester.enterText(find.byType(TextField), 'pass1234');
    await tester.tap(find.text('Extract'));
    await tester.pumpAndSettle();

    expect(enteredPassword, 'pass1234');
  });

  testWidgets('CompressDialog supports selecting format (.zip, .7z, .tar, .tar.gz) and entering password', (tester) async {
    CompressDialogResult? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showDialog<CompressDialogResult>(
                context: context,
                builder: (_) => const CompressDialog(
                  defaultName: 'backup',
                  itemCount: 3,
                ),
              );
            },
            child: const Text('Open Compress'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Compress'));
    await tester.pumpAndSettle();

    expect(find.text('Compress (3 items)'), findsOneWidget);
    expect(find.text('.zip'), findsOneWidget);
    expect(find.text('.7z'), findsOneWidget);
    expect(find.text('.tar'), findsOneWidget);
    expect(find.text('.tar.gz'), findsOneWidget);

    // Tap .7z
    await tester.tap(find.text('.7z'));
    await tester.pumpAndSettle();

    // Enter password
    await tester.enterText(find.widgetWithText(TextField, 'Leave empty for no password'), '7zSecret');
    await tester.tap(find.text('Compress'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.filename, 'backup');
    expect(result!.format, '7z');
    expect(result!.password, '7zSecret');
  });

  test('FileExplorerState handles clipboard copy and cut operations', () {
    var state = const FileExplorerState(currentPath: '/sdcard');
    expect(state.clipboard, isNull);

    // Stage copy
    state = state.copyWith(
      clipboard: const FileClipboardData(paths: ['/sdcard/file1.txt'], op: FileClipboardOp.copy),
    );
    expect(state.clipboard, isNotNull);
    expect(state.clipboard!.op, FileClipboardOp.copy);
    expect(state.clipboard!.paths, ['/sdcard/file1.txt']);

    // Clear clipboard
    state = state.copyWith(clearClipboard: true);
    expect(state.clipboard, isNull);

    // Stage cut
    state = state.copyWith(
      clipboard: const FileClipboardData(paths: ['/sdcard/file2.txt'], op: FileClipboardOp.cut),
    );
    expect(state.clipboard, isNotNull);
    expect(state.clipboard!.op, FileClipboardOp.cut);
  });
}
