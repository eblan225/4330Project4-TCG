import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:_4330project4_tcg/data/card_catalog.dart';
import 'package:_4330project4_tcg/data/deck_library.dart';
import 'package:_4330project4_tcg/game/battlefield_card.dart';
import 'package:_4330project4_tcg/game/game_engine.dart';
import 'package:_4330project4_tcg/models/deck.dart';
import 'package:_4330project4_tcg/screens/game_board_screen.dart';
import 'package:_4330project4_tcg/screens/game_results_screen.dart';

Deck deck(String name) => GameEngine.randomDeck(Random(7), name: name);
GameEngine engine({bool first = true}) => GameEngine(
  playerDeck: deck('First'),
  opponentDeck: deck('Opponent'),
  forcePlayerFirst: first,
  autoRunOpponent: false,
);

void main() {
  setUp(deckLibrary.clear);
  test('typed opponent steps and stats count actual damage', () {
    final game = engine();
    final card = cardCatalog.first;
    game.player.hand.add(card);
    game.player.resource = 99;
    game.playCard(game.player, card);
    expect(game.cardsPlayed, 1);
    game.opponent.hp = 1;
    game.attackPlayer(game.player, game.player.battlefield.single);
    expect(game.damageDealt, 1);
    expect(game.playerTurns, 1);
    expect(
      game.performNextOpponentAction().type,
      OpponentActionType.finishedTurn,
    );

    final opponentFirst = engine(first: false);
    opponentFirst.opponent.resource = 99;
    final action = opponentFirst.performNextOpponentAction();
    expect(action.type, OpponentActionType.playedCard);
    expect(action.card, isNotNull);
  });

  testWidgets('opponent attack is presented and blocks input', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final game = engine();
    game.opponent.hand.clear();
    game.opponent.deck.clear();
    final attacker = BattlefieldCard(cardCatalog.first);
    game.opponent.battlefield.add(attacker);
    game.player.hp = 1000;
    await tester.pumpWidget(
      MaterialApp(home: GameBoardScreen(gameEngine: game)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('End Turn'));
    await tester.pump();
    expect(game.player.hp, 1000);
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'End Turn'),
          )
          .onPressed,
      isNull,
    );
    await tester.pump(const Duration(milliseconds: 1600));
    expect(find.byKey(const ValueKey('damage-indicator')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 800));
    expect(game.player.hp, 1000 - attacker.card.attack);
    // Disposing during presentation cancels the remaining timer.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  for (final win in [true, false]) {
    testWidgets('results show stats and replay a fresh match ($win)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: GameResultsScreen(
            didWin: win,
            turnsPlayed: 4,
            cardsPlayed: 7,
            damageDealt: 29,
            deck: deck('Original'),
          ),
        ),
      );
      expect(find.text(win ? 'Victory!' : 'Defeat'), findsOneWidget);
      expect(find.text('--'), findsNothing);
      expect(find.text('Back to Board'), findsNothing);
      expect(find.text('29'), findsOneWidget);
      await tester.tap(find.text('Play again'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<GameBoardScreen>(find.byType(GameBoardScreen)).deck!.name,
        'Original',
      );
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('Change deck starts with the selected saved deck', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    deckLibrary.saveDeck(deck('Different deck'));
    await tester.pumpWidget(
      MaterialApp(
        home: GameResultsScreen(
          didWin: true,
          turnsPlayed: 1,
          cardsPlayed: 1,
          damageDealt: 1,
          deck: deck('Original'),
        ),
      ),
    );
    await tester.tap(find.text('Change deck'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Different deck'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<GameBoardScreen>(find.byType(GameBoardScreen)).deck!.name,
      'Different deck',
    );
    await tester.pumpWidget(const SizedBox());
  });
}
