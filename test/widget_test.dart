import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_manager/app.dart';

void main() {
  testWidgets('App root initializes and loads without crash', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FileManagerApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byType(FileManagerApp), findsOneWidget);
  });
}
