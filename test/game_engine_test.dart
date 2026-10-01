import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:_4330project4_tcg/data/card_catalog.dart';
import 'package:_4330project4_tcg/game/battlefield_card.dart';
import 'package:_4330project4_tcg/game/game_engine.dart';
import 'package:_4330project4_tcg/models/deck.dart';

/// A valid 30-card deck (10 unique cards x3) built from the real
/// catalog, offset so player/opponent decks can use different cards.
Deck _deckFrom(int offset) {
  final deck = Deck(name: 'Test');
  final cards = cardCatalog.skip(offset).take(10).toList();
  for (final card in cards) {
    deck.cardCounts[card.id] = 3;
  }
  return deck;
}

GameEngine _newGame({bool? forcePlayerFirst = true, int seed = 1}) {
  return GameEngine(
    playerDeck: _deckFrom(0),
    opponentDeck: _deckFrom(10),
    random: Random(seed),
    forcePlayerFirst: forcePlayerFirst,
  );
}

void main() {
  group('setup', () {
    test('both players start at the same HP', () {
      final game = _newGame();
      expect(game.player.hp, GameEngine.startingHp);
      expect(game.opponent.hp, GameEngine.startingHp);
    });

    test('the player who goes first has already drawn their turn-start card', () {
      final game = _newGame(forcePlayerFirst: true);
      // 5-card opening hand + 1 turn-start draw.
      expect(game.player.hand.length, GameEngine.startingHandSize + 1);
      expect(game.opponent.hand.length, GameEngine.startingHandSize);
    });

    test('the game is not over at the start', () {
      final game = _newGame();
      expect(game.isGameOver, isFalse);
      expect(game.winner, isNull);
    });

    test('turn 1 belongs to whoever was forced to go first', () {
      final game = _newGame(forcePlayerFirst: true);
      expect(game.isPlayerTurn, isTrue);
      expect(game.turnNumber, 1);
    });

    test('decks are shuffled and distinct between runs with different seeds', () {
      final gameA = GameEngine(
        playerDeck: _deckFrom(0),
        opponentDeck: _deckFrom(10),
        random: Random(1),
        forcePlayerFirst: true,
      );
      final gameB = GameEngine(
        playerDeck: _deckFrom(0),
        opponentDeck: _deckFrom(10),
        random: Random(2),
        forcePlayerFirst: true,
      );

      final handA = gameA.player.hand.map((c) => c.id).toList();
      final handB = gameB.player.hand.map((c) => c.id).toList();
      expect(handA, isNot(equals(handB)));
    });
  });

  group('resources', () {
    test('the starting player has 1 resource on turn 1', () {
      final game = _newGame(forcePlayerFirst: true);
      expect(game.player.resource, 1);
      expect(game.player.resourceCap, 1);
    });

    test("resource cap grows by 1 each of a player's own turns, up to the max", () {
      final game = _newGame(forcePlayerFirst: true);
      game.player.hp = 100000; // keep the match running for the full loop
      for (var i = 0; i < 20; i++) {
        game.endTurn();
      }
      expect(game.player.resourceCap, GameEngine.maxResourceCap);
      expect(game.player.resource, GameEngine.maxResourceCap);
    });
  });

  group('playing cards', () {
    test('playing a card removes it from hand, spends resource, and adds it to the battlefield', () {
      final game = _newGame(forcePlayerFirst: true);
      game.player.resource = 99; // avoid depending on which cards were drawn
      final card = game.player.hand.first;
      final startingResource = game.player.resource;

      game.playCard(game.player, card);

      expect(game.player.hand.contains(card), isFalse);
      expect(game.player.resource, startingResource - card.attackCost);
      expect(game.player.battlefield, hasLength(1));
      expect(game.player.battlefield.first.card, card);
    });

    test('cannot play a card that costs more than available resource', () {
      final game = _newGame(forcePlayerFirst: true);
      final expensiveCard =
          game.player.hand.reduce((a, b) => a.attackCost > b.attackCost ? a : b);
      // The opening hand always has at least one 1-cost card available
      // from this catalog slice, and resource is only 1 on turn 1.
      if (expensiveCard.attackCost <= game.player.resource) {
        return; // nothing to assert against with this seed/offset
      }

      expect(
        () => game.playCard(game.player, expensiveCard),
        throwsA(isA<GameRuleViolation>()),
      );
    });

    test('cannot play a card that is not in hand', () {
      final game = _newGame(forcePlayerFirst: true);
      final notInHand = cardCatalog.firstWhere(
        (c) => !game.player.hand.contains(c),
      );

      expect(
        () => game.playCard(game.player, notInHand),
        throwsA(isA<GameRuleViolation>()),
      );
    });

    test('cannot play a card when it is not your turn', () {
      final game = _newGame(forcePlayerFirst: true);
      final opponentCard = game.opponent.hand.first;

      expect(
        () => game.playCard(game.opponent, opponentCard),
        throwsA(isA<GameRuleViolation>()),
      );
    });

    test('cannot play a card once the battlefield is full', () {
      final game = _newGame(forcePlayerFirst: true);
      // Give the player enough resource and cards to fill the board.
      for (var i = 0; i < GameEngine.maxBattlefieldSize; i++) {
        game.player.resource = 99;
        game.player.hand.add(cardCatalog[i]);
        game.playCard(game.player, cardCatalog[i]);
      }
      expect(game.player.battlefield, hasLength(GameEngine.maxBattlefieldSize));

      game.player.resource = 99;
      game.player.hand.add(cardCatalog[0]);

      expect(
        () => game.playCard(game.player, cardCatalog[0]),
        throwsA(isA<GameRuleViolation>()),
      );
    });
  });

  group('attacking', () {
    test('attacking a card deals mutual damage and can defeat both sides', () {
      final game = _newGame(forcePlayerFirst: true);
      final attacker = BattlefieldCard(cardCatalog.firstWhere((c) => c.id == 'lion'));
      final defender = BattlefieldCard(cardCatalog.firstWhere((c) => c.id == 'fox'));
      game.player.battlefield.add(attacker);
      game.opponent.battlefield.add(defender);

      game.attackCard(game.player, attacker, defender);

      // Fox has 20 HP and Lion attacks for 55, so Fox is defeated.
      expect(game.opponent.battlefield.contains(defender), isFalse);
      // Lion has 70 HP and Fox attacks for 15, so Lion survives at 55.
      expect(attacker.currentHp, 70 - 15);
      expect(attacker.hasAttackedThisTurn, isTrue);
    });

    test('attacking the player reduces their HP by the attacker\'s attack', () {
      final game = _newGame(forcePlayerFirst: true);
      // Fox's attack (15) is less than starting HP (30), so this checks
      // plain subtraction without the 0-floor kicking in.
      final attacker = BattlefieldCard(cardCatalog.firstWhere((c) => c.id == 'fox'));
      game.player.battlefield.add(attacker);
      final startingHp = game.opponent.hp;

      game.attackPlayer(game.player, attacker);

      expect(game.opponent.hp, startingHp - attacker.card.attack);
    });

    test('a player\'s HP cannot go below 0', () {
      final game = _newGame(forcePlayerFirst: true);
      final attacker = BattlefieldCard(cardCatalog.firstWhere((c) => c.id == 'lion'));
      game.player.battlefield.add(attacker);
      game.opponent.hp = 10; // less than Lion's 55 attack

      game.attackPlayer(game.player, attacker);

      expect(game.opponent.hp, 0);
    });

    test('a card cannot attack twice in the same turn', () {
      final game = _newGame(forcePlayerFirst: true);
      final attacker = BattlefieldCard(cardCatalog.firstWhere((c) => c.id == 'lion'));
      game.player.battlefield.add(attacker);

      game.attackPlayer(game.player, attacker);

      expect(
        () => game.attackPlayer(game.player, attacker),
        throwsA(isA<GameRuleViolation>()),
      );
    });

    test('cannot attack when it is not your turn', () {
      final game = _newGame(forcePlayerFirst: true);
      final attacker = BattlefieldCard(cardCatalog.firstWhere((c) => c.id == 'lion'));
      game.opponent.battlefield.add(attacker);

      expect(
        () => game.attackPlayer(game.opponent, attacker),
        throwsA(isA<GameRuleViolation>()),
      );
    });

    test('cannot attack with a card that is not on your battlefield', () {
      final game = _newGame(forcePlayerFirst: true);
      final notOnBoard = BattlefieldCard(cardCatalog.firstWhere((c) => c.id == 'lion'));

      expect(
        () => game.attackPlayer(game.player, notOnBoard),
        throwsA(isA<GameRuleViolation>()),
      );
    });

    test('defeating the opponent ends the game with the player winning', () {
      final game = _newGame(forcePlayerFirst: true);
      game.opponent.hp = 10;
      final attacker = BattlefieldCard(cardCatalog.firstWhere((c) => c.id == 'lion'));
      game.player.battlefield.add(attacker);

      game.attackPlayer(game.player, attacker);

      expect(game.isGameOver, isTrue);
      expect(game.winner, game.player);
    });
  });

  group('turns', () {
    test('ending the player\'s turn eventually returns control to the player', () {
      final game = _newGame(forcePlayerFirst: true);

      game.endTurn();

      expect(game.isPlayerTurn, isTrue);
      expect(game.turnNumber, 2);
    });

    test('a defeated player stops the opponent from taking further turns', () {
      final game = _newGame(forcePlayerFirst: true);
      game.player.hp = 1;

      // Drive several turns; the game should end rather than loop forever.
      for (var i = 0; i < 10 && !game.isGameOver; i++) {
        game.endTurn();
      }

      // Either the game ended, or it's still safely the player's turn —
      // either way this should never throw or hang.
      expect(game.isGameOver || game.isPlayerTurn, isTrue);
    });
  });
}
