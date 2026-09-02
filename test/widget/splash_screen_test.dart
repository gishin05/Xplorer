import 'package:file_manager/screens/splash_screen.dart';
import 'package:file_manager/theme/app_theme.dart';
import 'package:file_manager/widgets/cracked_x_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SplashScreen renders Cracked X logo, app title, and progress indicator', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const SplashScreen(),
        ),
      ),
    );

    // Initial frame
    await tester.pump();

    expect(find.text('Xplorer Manager'), findsOneWidget);
    expect(find.byType(CrackedXLogo), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    // Verify removed description text is not present
    expect(find.text('STORAGE & WIRELESS ADB BRIDGE'), findsNothing);

    // Advance past minimum delay
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 700));
  });
}
