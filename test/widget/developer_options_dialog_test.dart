import 'package:file_manager/theme/app_theme.dart';
import 'package:file_manager/widgets/developer_options_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DeveloperOptionsDialog renders title, description, and responds to actions', (tester) async {
    bool settingsOpened = false;
    bool dismissed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                DeveloperOptionsDialog.show(
                  context,
                  onOpenSettings: () {
                    settingsOpened = true;
                  },
                  onDismiss: () {
                    dismissed = true;
                  },
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ),
    );

    // Tap button to open dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Verify dialog content
    expect(find.text('WIRELESS ADB HELPER BRIDGE'), findsOneWidget);
    expect(find.text('Unlock /Android/data & APK Access'), findsOneWidget);
    expect(find.text('HOW TO ENABLE DEVELOPER OPTIONS'), findsOneWidget);
    expect(find.text('Not Now'), findsOneWidget);
    expect(find.text('Open Settings'), findsOneWidget);

    // Tap Open Settings
    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();

    expect(settingsOpened, isTrue);
    expect(dismissed, isFalse);
  });
}
