import 'package:file_manager/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SettingsScreen renders minimalist cards without unnecessary decorative icons', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    // Initial loading or loaded state
    await tester.pumpAndSettle();

    // Verify key sections are present
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('STORAGE & ELEVATED ACCESS'), findsOneWidget);
    expect(find.text('All Files Access'), findsOneWidget);
    expect(find.text('Wireless ADB Helper Bridge'), findsOneWidget);
    expect(find.text('Auto-Bridge on Developer Options'), findsOneWidget);
    expect(find.text('Enterprise Device Owner Mode'), findsOneWidget);

    // Scroll down to reveal system information section
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(find.text('INTRODUCTION & GUIDE'), findsOneWidget);
    expect(find.text('Xplorer'), findsOneWidget);
    expect(find.text('v1.2.1'), findsOneWidget);
    expect(find.text('Welcome to Xplorer'), findsOneWidget);

    // Confirm that old unnecessary icons are NOT present
    expect(find.byIcon(Icons.security_rounded), findsNothing);
    expect(find.byIcon(Icons.admin_panel_settings_rounded), findsNothing);
    expect(find.byIcon(Icons.wifi_tethering_rounded), findsNothing);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
  });
}
