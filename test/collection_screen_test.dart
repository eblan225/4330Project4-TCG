// Behavior tests for the Collection screen: search, rarity filter,
// sort control, and the owned-vs-not-owned visual distinction.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:_4330project4_tcg/main.dart';

Future<void> _openCollection(WidgetTester tester) async {
  await tester.pumpWidget(const AnimalTcgApp());
  await tester.tap(find.text('Collection'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a not-owned card (legendary) is labeled NOT OWNED', (
    WidgetTester tester,
  ) async {
    await _openCollection(tester);

    await tester.enterText(find.byType(TextField), 'Elephant');
    await tester.pumpAndSettle();

    expect(find.text('Ancient Elephant'), findsOneWidget);
    expect(find.text('NOT OWNED'), findsOneWidget);
  });

  testWidgets('an owned card (common) is not labeled NOT OWNED', (
    WidgetTester tester,
  ) async {
    await _openCollection(tester);

    await tester.enterText(find.byType(TextField), 'fox');
    await tester.pumpAndSettle();

    expect(find.text('Desert Fox'), findsOneWidget);
    expect(find.text('NOT OWNED'), findsNothing);
  });

  testWidgets('search narrows the grid to matching cards only', (
    WidgetTester tester,
  ) async {
    await _openCollection(tester);

    await tester.enterText(find.byType(TextField), 'nonexistent animal');
    await tester.pumpAndSettle();

    expect(find.text('No cards match your search/filter.'), findsOneWidget);
  });

  testWidgets('rarity filter narrows results to that rarity', (
    WidgetTester tester,
  ) async {
    await _openCollection(tester);

    await tester.tap(find.text('Legendary'));
    await tester.pumpAndSettle();

    expect(find.text('Ancient Elephant'), findsOneWidget);
    expect(find.text('Desert Fox'), findsNothing);
  });

  testWidgets('the sort control is present', (WidgetTester tester) async {
    await _openCollection(tester);

    expect(find.text('Sort: '), findsOneWidget);
  });
}
