// Smoke tests covering navigation between all six screens and a
// few of the key placeholder elements on each one.

import 'package:flutter_test/flutter_test.dart';

import 'package:_4330project4_tcg/data/card_catalog.dart';
import 'package:_4330project4_tcg/data/deck_library.dart';
import 'package:_4330project4_tcg/main.dart';
import 'package:_4330project4_tcg/models/deck.dart';

/// A deck that satisfies the 30-card / max-3-copies rules, for tests
/// that need game start to be allowed.
Deck _validTestDeck() {
  final deck = Deck(name: 'Test Deck');
  for (final card in cardCatalog.take(10)) {
    deck.cardCounts[card.id] = 3;
  }
  return deck;
}

void main() {
  setUp(() {
    deckLibrary.clear();
  });

  testWidgets('Main menu shows title and all navigation buttons', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AnimalTcgApp());

    expect(find.text('ANIMAL TCG'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Collection'), findsOneWidget);
    expect(find.text('Deck Builder'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('Collection screen shows the card grid and filter chips', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AnimalTcgApp());

    await tester.tap(find.text('Collection'));
    await tester.pumpAndSettle();

    expect(find.text('Card Collection'), findsOneWidget);
    expect(find.text('Legendary'), findsOneWidget);
  });

  testWidgets('Deck Builder screen shows both panels, empty by default', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AnimalTcgApp());

    await tester.tap(find.text('Deck Builder'));
    await tester.pumpAndSettle();

    expect(find.text('Available Cards'), findsOneWidget);
    expect(find.text('Current Deck'), findsOneWidget);
    expect(find.text('0/30'), findsOneWidget);
  });

  testWidgets('Settings screen shows the toggle switches', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AnimalTcgApp());

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Music'), findsOneWidget);
    expect(find.text('Sound Effects'), findsOneWidget);
  });

  testWidgets('Game Lobby blocks starting a game without a valid deck', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AnimalTcgApp());

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('No Valid Deck'), findsOneWidget);
    expect(find.text('Game Board'), findsNothing);

    await tester.tap(find.text('Go to Deck Builder'));
    await tester.pumpAndSettle();

    expect(find.text('Deck Builder'), findsOneWidget);
  });

  testWidgets('Play leads to the lobby, then to a real game board', (
    WidgetTester tester,
  ) async {
    deckLibrary.saveDeck(_validTestDeck());

    await tester.pumpWidget(const AnimalTcgApp());

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    expect(find.text('Game Lobby'), findsOneWidget);
    expect(find.text('Create Game'), findsOneWidget);
    expect(find.text('Join Game'), findsOneWidget);

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(find.text('Game Board'), findsOneWidget);
    expect(find.text('Game Log'), findsOneWidget);
    expect(find.text('End Turn'), findsOneWidget);
  });
}
