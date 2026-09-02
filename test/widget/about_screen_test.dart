import 'package:file_manager/screens/about_screen.dart';
import 'package:file_manager/widgets/cracked_x_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AboutScreen renders Cracked X branding, version v1.3.0, and introduction summary', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AboutScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('About'), findsOneWidget);
    expect(find.byType(CrackedXLogo), findsOneWidget);
    expect(find.text('Xplorer Manager'), findsOneWidget);
    expect(find.text('v1.4.0 (Build 2026.09)'), findsOneWidget);
    expect(find.text('Introduction'), findsOneWidget);
    expect(find.text('Technical Architecture'), findsOneWidget);

    // Scroll down to view the Release Notes button
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.text('Release Notes & Changelog'), findsOneWidget);
  });
}
