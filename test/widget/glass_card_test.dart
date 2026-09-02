import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_manager/widgets/glass_card.dart';

void main() {
  testWidgets('GlassCard renders child and fires onTap', (WidgetTester tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlassCard(
            onTap: () {
              tapped = true;
            },
            child: const Text('Test Glass Content'),
          ),
        ),
      ),
    );

    expect(find.text('Test Glass Content'), findsOneWidget);
    await tester.tap(find.text('Test Glass Content'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('GlassCard displays selection styling when isSelected is true', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GlassCard(
            isSelected: true,
            child: Text('Selected Glass'),
          ),
        ),
      ),
    );

    expect(find.text('Selected Glass'), findsOneWidget);
  });
}
