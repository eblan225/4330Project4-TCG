// Behavior tests for the Game Board screen: playing cards, attacking,
// turn switching, and reaching the results screen on a real win —
// all driven through the UI with an injected, deterministic engine.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:_4330project4_tcg/data/card_catalog.dart';
import 'package:_4330project4_tcg/game/battlefield_card.dart';
import 'package:_4330project4_tcg/game/game_engine.dart';
import 'package:_4330project4_tcg/models/deck.dart';
import 'package:_4330project4_tcg/screens/game_board_screen.dart';

Deck _deckFrom(int offset) {
  final deck = Deck(name: 'Test');
  for (final card in cardCatalog.skip(offset).take(10)) {
    deck.cardCounts[card.id] = 3;
  }
  return deck;
}

/// A deterministic engine (fixed seed, forced first player) with
/// opponent HP high enough by default that an attack can never
/// accidentally end the game early — tests that want a win override
/// [opponentHp] explicitly.
GameEngine _engine({int opponentHp = 10000}) {
  final engine = GameEngine(
    playerDeck: _deckFrom(0),
    opponentDeck: _deckFrom(10),
    random: Random(7),
    forcePlayerFirst: true,
  );
  engine.player.resource = 99; // every hand card is affordable in tests
  engine.opponent.hp = opponentHp;
  return engine;
}

Future<void> _pumpBoard(WidgetTester tester, GameEngine engine) async {
  await tester.pumpWidget(
    MaterialApp(home: GameBoardScreen(gameEngine: engine)),
  );
  await _finishActions(tester);
}

Future<void> _finishActions(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows real HP and resource from the engine', (
    WidgetTester tester,
  ) async {
    final engine = _engine();
    await _pumpBoard(tester, engine);

    expect(find.byKey(const ValueKey('player-hp')), findsOneWidget);
    expect(find.byKey(const ValueKey('opponent-hp')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('player-resource')),
        matching: find.text(
          '${engine.player.resource}/${engine.player.resourceCap}',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping an affordable hand card plays it to the battlefield', (
    WidgetTester tester,
  ) async {
    final engine = _engine();
    await _pumpBoard(tester, engine);

    expect(engine.player.battlefield, isEmpty);

    await tester.tap(find.byKey(const ValueKey('hand-0')));
    await _finishActions(tester);

    expect(engine.player.battlefield, hasLength(1));
    expect(find.byKey(const ValueKey('player-field-0')), findsOneWidget);
  });

  testWidgets(
    'attacking with no enemy creatures on the field hits the opponent directly',
    (WidgetTester tester) async {
      final engine = _engine();
      // Put a known card directly on the battlefield so the attack's
      // damage is predictable, instead of depending on which card a
      // shuffled hand happened to draw.
      final attacker = BattlefieldCard(
        cardCatalog.firstWhere((c) => c.id == 'lion'),
      );
      engine.player.battlefield.add(attacker);
      await _pumpBoard(tester, engine);

      final startingOpponentHp = engine.opponent.hp;

      // The opponent has no battlefield cards, so tapping the attacker
      // skips the target dialog and attacks the opponent's face.
      await tester.tap(find.byKey(const ValueKey('player-field-0')));
      await _finishActions(tester);

      expect(find.text('Attack with Savanna Lion'), findsNothing);
      expect(engine.opponent.hp, startingOpponentHp - attacker.card.attack);
    },
  );

  testWidgets(
    'attacking offers a choice when the opponent has a battlefield card',
    (WidgetTester tester) async {
      final engine = _engine();
      final attacker = BattlefieldCard(
        cardCatalog.firstWhere((c) => c.id == 'lion'),
      );
      engine.player.battlefield.add(attacker);
      final enemyCreature = BattlefieldCard(
        cardCatalog.firstWhere((c) => c.id == 'fox'),
      );
      engine.opponent.battlefield.add(enemyCreature);
      await _pumpBoard(tester, engine);

      await tester.tap(find.byKey(const ValueKey('player-field-0')));
      await _finishActions(tester);

      expect(find.text('Attack Opponent Directly'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(enemyCreature.card.name),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('attack-enemy-0')));
      await _finishActions(tester);

      // Lion (55 attack) easily defeats Fox (20 HP).
      expect(engine.opponent.battlefield, isEmpty);
    },
  );

  testWidgets('a card that already attacked cannot be tapped again this turn', (
    WidgetTester tester,
  ) async {
    final engine = _engine();
    final attacker = BattlefieldCard(
      cardCatalog.firstWhere((c) => c.id == 'fox'),
    );
    engine.player.battlefield.add(attacker);
    await _pumpBoard(tester, engine);

    await tester.tap(find.byKey(const ValueKey('player-field-0')));
    await _finishActions(tester);

    final hpAfterFirstAttack = engine.opponent.hp;
    expect(attacker.hasAttackedThisTurn, isTrue);

    // The slot is now disabled (dimmed, no onTap), so this tap should
    // do nothing rather than attack a second time.
    await tester.tap(
      find.byKey(const ValueKey('player-field-0')),
      warnIfMissed: false,
    );
    await _finishActions(tester);

    expect(engine.opponent.hp, hpAfterFirstAttack);
  });

  testWidgets('End Turn passes control through the opponent and back', (
    WidgetTester tester,
  ) async {
    final engine = _engine();
    await _pumpBoard(tester, engine);

    expect(find.text('Turn 1 • Your Turn'), findsOneWidget);

    await tester.tap(find.text('End Turn'));
    await _finishActions(tester);

    expect(engine.isPlayerTurn, isTrue);
    expect(find.text('Turn 2 • Your Turn'), findsOneWidget);
  });

  testWidgets('defeating the opponent navigates to the results screen', (
    WidgetTester tester,
  ) async {
    final engine = _engine(opponentHp: 1);
    final attacker = BattlefieldCard(
      cardCatalog.firstWhere((c) => c.id == 'fox'),
    );
    engine.player.battlefield.add(attacker);
    await _pumpBoard(tester, engine);

    await tester.tap(find.byKey(const ValueKey('player-field-0')));
    await _finishActions(tester);

    expect(engine.isGameOver, isTrue);
    expect(find.text('Game Results'), findsOneWidget);
    expect(find.text('Victory!'), findsOneWidget);
  });
}
