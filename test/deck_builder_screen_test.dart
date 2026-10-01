// Behavior tests for the Deck Builder screen: add/remove, ownership
// restriction, copy limit, search/filter, and saving.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:_4330project4_tcg/data/deck_library.dart';
import 'package:_4330project4_tcg/main.dart';

Future<void> _openDeckBuilder(WidgetTester tester) async {
  await tester.pumpWidget(const AnimalTcgApp());
  await tester.tap(find.text('Deck Builder'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    deckLibrary.clear();
  });

  testWidgets('only owned cards appear in Available Cards', (
    WidgetTester tester,
  ) async {
    await _openDeckBuilder(tester);

    // Fox is common (owned by default), Elephant is legendary (not owned).
    expect(find.byKey(const ValueKey('available-fox')), findsOneWidget);
    expect(find.byKey(const ValueKey('available-elephant')), findsNothing);
  });

  testWidgets('tapping an available card adds a copy to the deck', (
    WidgetTester tester,
  ) async {
    await _openDeckBuilder(tester);

    expect(find.text('0/30'), findsOneWidget);
    expect(find.byKey(const ValueKey('deck-fox')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('available-fox')));
    await tester.pumpAndSettle();

    expect(find.text('1/30'), findsOneWidget);
    expect(find.byKey(const ValueKey('deck-fox')), findsOneWidget);
    expect(find.text('x1'), findsNWidgets(2)); // badge on both tiles
  });

  testWidgets('tapping a card in the deck removes a copy', (
    WidgetTester tester,
  ) async {
    await _openDeckBuilder(tester);

    await tester.tap(find.byKey(const ValueKey('available-fox')));
    await tester.pumpAndSettle();
    expect(find.text('1/30'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('deck-fox')));
    await tester.pumpAndSettle();

    expect(find.text('0/30'), findsOneWidget);
    expect(find.byKey(const ValueKey('deck-fox')), findsNothing);
  });

  testWidgets('cannot add more than 3 copies of the same card', (
    WidgetTester tester,
  ) async {
    await _openDeckBuilder(tester);

    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byKey(const ValueKey('available-fox')));
      await tester.pumpAndSettle();
    }

    expect(find.text('3/30'), findsOneWidget);
  });

  testWidgets('search narrows the available card grid', (
    WidgetTester tester,
  ) async {
    await _openDeckBuilder(tester);

    await tester.enterText(find.byType(TextField).first, 'fox');
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('available-fox')), findsOneWidget);
    expect(find.byKey(const ValueKey('available-wolf')), findsNothing);
  });

  testWidgets('saving with no name shows an error and does not save', (
    WidgetTester tester,
  ) async {
    await _openDeckBuilder(tester);

    await tester.tap(find.text('Save Deck'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a deck name first.'), findsOneWidget);
    expect(deckLibrary.decks, isEmpty);
  });

  testWidgets('saving an incomplete deck shows an error and does not save', (
    WidgetTester tester,
  ) async {
    await _openDeckBuilder(tester);

    await tester.enterText(find.byType(TextField).first, 'My Deck');
    await tester.tap(find.byKey(const ValueKey('available-fox')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save Deck'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Deck needs'), findsOneWidget);
    expect(deckLibrary.decks, isEmpty);
  });

  testWidgets('Clear Deck empties the current deck', (WidgetTester tester) async {
    await _openDeckBuilder(tester);

    await tester.tap(find.byKey(const ValueKey('available-fox')));
    await tester.pumpAndSettle();
    expect(find.text('1/30'), findsOneWidget);

    await tester.tap(find.text('Clear Deck'));
    await tester.pumpAndSettle();

    expect(find.text('0/30'), findsOneWidget);
  });
}
