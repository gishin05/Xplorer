import 'package:file_manager/screens/splash_screen.dart';
import 'package:file_manager/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SplashScreen renders Xplorer logo and progress indicator', (tester) async {
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

    expect(find.text('Xplorer'), findsOneWidget);
    expect(find.text('STORAGE & WIRELESS ADB BRIDGE'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.folder_rounded), findsOneWidget);

    // Advance past minimum delay
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 700));
  });
}
