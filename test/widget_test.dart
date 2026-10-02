// Smoke tests covering navigation between all six screens and a
// few of the key placeholder elements on each one.

import 'package:flutter/material.dart';
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
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('main menu and match screens do not overflow on a phone', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    deckLibrary.saveDeck(_validTestDeck());

    await tester.pumpWidget(const AnimalTcgApp());
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Play'));
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Create room'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Profile opens account creation and sign in', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AnimalTcgApp());
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Player Account'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Create Account'), findsWidgets);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.byKey(const ValueKey('account-submit')), findsOneWidget);
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

  testWidgets('Play setup blocks creating a room without a valid deck', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AnimalTcgApp());

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();

    expect(find.text('Choose your deck'), findsOneWidget);
    await tester.tap(find.text('Create room'));
    await tester.pumpAndSettle();

    expect(find.text('No Valid Deck'), findsOneWidget);
    expect(find.text('Game Board'), findsNothing);

    await tester.tap(find.text('Go to Deck Builder'));
    await tester.pumpAndSettle();

    expect(find.text('Deck Builder'), findsOneWidget);
  });

  testWidgets('Play setup can start a bot game with the selected deck', (
    WidgetTester tester,
  ) async {
    deckLibrary.saveDeck(_validTestDeck());

    await tester.pumpWidget(const AnimalTcgApp());

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    expect(find.text('Choose your deck'), findsOneWidget);
    expect(find.byKey(const ValueKey('deck-chooser')), findsOneWidget);
    expect(find.text('Create room'), findsOneWidget);
    expect(find.text('Find room'), findsOneWidget);

    await tester.tap(find.text('Practice with bot'));
    await tester.pumpAndSettle();
    expect(find.text('Game Board'), findsOneWidget);
    expect(find.text('Game Log'), findsOneWidget);
    expect(find.text('End Turn'), findsOneWidget);
  });

  testWidgets('creating a room opens a separate lobby with deck changing', (
    WidgetTester tester,
  ) async {
    final first = _validTestDeck()..name = 'Forest Deck';
    final second = _validTestDeck()..name = 'River Deck';
    deckLibrary
      ..saveDeck(first)
      ..saveDeck(second);

    await tester.pumpWidget(const AnimalTcgApp());
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create room'));
    await tester.pumpAndSettle();

    expect(find.text('Game Lobby'), findsOneWidget);
    expect(find.text('Room WILD-482'), findsOneWidget);
    expect(find.text('Using Forest Deck'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('lobby-change-deck')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('River Deck'));
    await tester.pumpAndSettle();

    expect(find.text('Using River Deck'), findsOneWidget);
    expect(find.byKey(const ValueKey('lobby-edit-deck')), findsOneWidget);
  });

  testWidgets('saving an edited deck returns and refreshes the setup screen', (
    WidgetTester tester,
  ) async {
    final deck = _validTestDeck()..name = 'Old Name';
    deckLibrary.saveDeck(deck);

    await tester.pumpWidget(const AnimalTcgApp());
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('setup-edit-deck')));
    await tester.pumpAndSettle();

    expect(find.text('Deck Builder'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Updated Deck');
    await tester.tap(find.text('Save Deck'));
    await tester.pumpAndSettle();

    expect(find.text('Choose your deck'), findsOneWidget);
    expect(find.textContaining('Updated Deck'), findsOneWidget);
  });
}
