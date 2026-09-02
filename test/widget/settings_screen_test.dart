import 'package:file_manager/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SettingsScreen renders File Access, General Settings, and Interface Themes', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify top sections
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('PERMISSIONS & ACCESS'), findsOneWidget);
    expect(find.text('File Access'), findsOneWidget);
    expect(find.text('GENERAL SETTINGS'), findsOneWidget);
    expect(find.text('Home Folder'), findsOneWidget);
    expect(find.text('Overwrite Confirmation'), findsOneWidget);
    expect(find.text('Back Button Action'), findsOneWidget);

    // Scroll down to see Interface Settings and Application section
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(find.text('INTERFACE SETTINGS'), findsOneWidget);
    expect(find.text('Color Theme'), findsOneWidget);
    expect(find.text('About Xplorer Manager'), findsOneWidget);

    // Confirm that removed sections are NOT present
    expect(find.text('Wireless ADB Helper Bridge'), findsNothing);
    expect(find.text('Enterprise Device Owner Mode'), findsNothing);
    expect(find.text('Next-Gen Elevated Android File Manager'), findsNothing);
  });
}
