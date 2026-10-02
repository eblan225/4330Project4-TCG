import 'dart:math';

import '../data/card_catalog.dart';
import '../models/card.dart';
import '../models/deck.dart';
import 'battlefield_card.dart';
import 'player_state.dart';

/// Thrown when an action would break the game's rules — not enough
/// resources, out of turn, a card that isn't in hand, an attacker
/// that's already attacked, etc. The UI catches this and shows the
/// message instead of the action happening.
class GameRuleViolation implements Exception {
  GameRuleViolation(this.message);
  final String message;

  @override
  String toString() => message;
}

enum OpponentActionType { playedCard, attackedPlayer, finishedTurn }

/// One visible step of the automatic opponent's turn. The UI can request
/// these one at a time so each play and attack has time to animate.
class OpponentAction {
  const OpponentAction._({
    required this.type,
    this.card,
    this.attacker,
    this.damage = 0,
  });

  const OpponentAction.played(GameCard card)
    : this._(type: OpponentActionType.playedCard, card: card);

  const OpponentAction.attacked(BattlefieldCard attacker, int damage)
    : this._(
        type: OpponentActionType.attackedPlayer,
        attacker: attacker,
        damage: damage,
      );

  const OpponentAction.finished()
    : this._(type: OpponentActionType.finishedTurn);

  final OpponentActionType type;
  final GameCard? card;
  final BattlefieldCard? attacker;
  final int damage;
}

/// Runs one full two-player match: setup, turns, playing cards, and
/// attacking. This class has no Flutter dependency — it's plain game
/// logic that a screen reads from and calls into.
///
/// The rules are kept deliberately simple:
/// - Both players start at [startingHp] HP and 0 resource, shuffle
///   their deck, and draw a [startingHandSize]-card opening hand.
/// - One player is chosen at random to go first.
/// - At the start of every turn (including the very first), the
///   active player's resource cap goes up by 1 (max
///   [maxResourceCap]), their resource refills to that cap, their
///   battlefield cards become able to attack again, and they draw 1
///   card.
/// - Playing a card costs its `attackCost` in resources and moves it
///   from hand onto the player's battlefield (max
///   [maxBattlefieldSize] cards).
/// - A battlefield card that hasn't attacked yet this turn can attack
///   either an enemy battlefield card or the enemy player directly —
///   the attacking player's choice; there's no "must attack creatures
///   first" rule. Attacking a card deals damage to both cards (a
///   trade); attacking a player only damages the player.
/// - A battlefield card at 0 HP is defeated and removed. A player at
///   0 HP loses.
///
/// There's no multiplayer or networked opponent yet, so once the
/// player ends their turn, the opponent's turn plays out
/// automatically with simple logic (play what it can afford, then
/// attack with everything) before control returns to the player.
class GameEngine {
  GameEngine({
    required Deck playerDeck,
    required Deck opponentDeck,
    Random? random,
    bool? forcePlayerFirst,
    this.autoRunOpponent = true,
  }) : startingDeck = playerDeck.copy(),
       _random = random ?? Random(),
       player = PlayerState(name: 'Player', deckCards: _expand(playerDeck)),
       opponent = PlayerState(
         name: 'Opponent',
         deckCards: _expand(opponentDeck),
       ) {
    _setUpGame(forcePlayerFirst);
  }

  static const int startingHp = 30;
  static const int startingHandSize = 5;
  static const int maxResourceCap = 10;
  static const int maxBattlefieldSize = 5;

  final Deck startingDeck;
  bool autoRunOpponent;
  int playerTurns = 0;
  int cardsPlayed = 0;
  int damageDealt = 0;
  final Random _random;
  final PlayerState player;
  final PlayerState opponent;

  bool isPlayerTurn = true;
  int turnNumber = 1;
  final List<String> log = [];

  bool get isGameOver => player.isDefeated || opponent.isDefeated;

  /// The player who won, or null if the game isn't over yet.
  PlayerState? get winner {
    if (!isGameOver) return null;
    return player.isDefeated ? opponent : player;
  }

  PlayerState get currentPlayer => isPlayerTurn ? player : opponent;

  PlayerState _otherPlayerOf(PlayerState actor) =>
      actor == player ? opponent : player;

  /// Builds a random, rule-valid 30-card deck from the full card
  /// catalog. Used to give the automatic opponent a deck, since it
  /// doesn't have a collection of owned cards like the player does.
  static Deck randomDeck(Random random, {String name = 'Opponent Deck'}) {
    final shuffled = List<GameCard>.from(cardCatalog)..shuffle(random);
    final deck = Deck(name: name);
    for (final card in shuffled.take(10)) {
      deck.cardCounts[card.id] = Deck.maxCopiesPerCard;
    }
    return deck;
  }

  static List<GameCard> _expand(Deck deck) {
    final cards = <GameCard>[];
    deck.cardCounts.forEach((id, count) {
      final card = cardCatalogById[id];
      if (card == null) return;
      for (var i = 0; i < count; i++) {
        cards.add(card);
      }
    });
    return cards;
  }

  void _setUpGame(bool? forcePlayerFirst) {
    player.hp = startingHp;
    opponent.hp = startingHp;

    player.shuffleDeck(_random);
    opponent.shuffleDeck(_random);

    for (var i = 0; i < startingHandSize; i++) {
      player.drawCard();
      opponent.drawCard();
    }

    isPlayerTurn = forcePlayerFirst ?? _random.nextBool();
    _log('${currentPlayer.name} goes first.');
    _beginTurn();

    if (!isPlayerTurn && autoRunOpponent) {
      _runOpponentTurn();
    }
  }

  void _beginTurn() {
    final actor = currentPlayer;
    if (actor == player) playerTurns++;
    for (final battlefieldCard in actor.battlefield) {
      battlefieldCard.hasAttackedThisTurn = false;
    }
    actor.resourceCap = min(actor.resourceCap + 1, maxResourceCap);
    actor.resource = actor.resourceCap;

    _log("${actor.name}'s turn begins (Turn $turnNumber).");
    final drawn = actor.drawCard();
    if (drawn == null) {
      _log("${actor.name}'s deck is empty — no card drawn.");
    } else {
      _log('${actor.name} draws a card.');
    }
  }

  void _assertActorTurn(PlayerState actor) {
    if (isGameOver) {
      throw GameRuleViolation('The game is already over.');
    }
    if (actor != currentPlayer) {
      throw GameRuleViolation("It isn't ${actor.name}'s turn.");
    }
  }

  /// Plays [card] from [actor]'s hand onto their battlefield.
  void playCard(PlayerState actor, GameCard card) {
    _assertActorTurn(actor);
    if (!actor.hand.contains(card)) {
      throw GameRuleViolation('${card.name} is not in ${actor.name}\'s hand.');
    }
    if (actor.resource < card.attackCost) {
      throw GameRuleViolation('Not enough resources to play ${card.name}.');
    }
    if (actor.battlefield.length >= maxBattlefieldSize) {
      throw GameRuleViolation("${actor.name}'s battlefield is full.");
    }

    if (actor == player) cardsPlayed++;
    actor.hand.remove(card);
    actor.resource -= card.attackCost;
    actor.battlefield.add(BattlefieldCard(card));
    _log('${actor.name} plays ${card.name}.');
  }

  /// [attacker] (belonging to [actor]) attacks [defender], an enemy
  /// battlefield card. Both deal their attack as damage to each
  /// other; defeated cards are removed afterward.
  void attackCard(
    PlayerState actor,
    BattlefieldCard attacker,
    BattlefieldCard defender,
  ) {
    _assertActorTurn(actor);
    _assertCanAttack(actor, attacker);
    final defendingPlayer = _otherPlayerOf(actor);
    if (!defendingPlayer.battlefield.contains(defender)) {
      throw GameRuleViolation('That card is not a valid target.');
    }

    if (actor == player) {
      damageDealt += min(defender.currentHp, attacker.card.attack);
    }
    defender.currentHp = max(0, defender.currentHp - attacker.card.attack);
    attacker.currentHp = max(0, attacker.currentHp - defender.card.attack);
    attacker.hasAttackedThisTurn = true;
    _log(
      '${attacker.card.name} attacks ${defender.card.name} '
      '(${attacker.card.attack} dmg); ${defender.card.name} strikes back '
      '(${defender.card.attack} dmg).',
    );

    _removeDefeated(actor);
    _removeDefeated(defendingPlayer);
  }

  /// [attacker] (belonging to [actor]) attacks the opposing player
  /// directly.
  void attackPlayer(PlayerState actor, BattlefieldCard attacker) {
    _assertActorTurn(actor);
    _assertCanAttack(actor, attacker);

    final defendingPlayer = _otherPlayerOf(actor);
    if (actor == player) {
      damageDealt += min(defendingPlayer.hp, attacker.card.attack);
    }
    defendingPlayer.hp = max(0, defendingPlayer.hp - attacker.card.attack);
    attacker.hasAttackedThisTurn = true;
    _log(
      '${attacker.card.name} attacks ${defendingPlayer.name} directly for '
      '${attacker.card.attack} damage.',
    );

    if (defendingPlayer.isDefeated) {
      _log('${defendingPlayer.name} has been defeated!');
    }
  }

  void _assertCanAttack(PlayerState actor, BattlefieldCard attacker) {
    if (!actor.battlefield.contains(attacker)) {
      throw GameRuleViolation(
        'That card is not on ${actor.name}\'s battlefield.',
      );
    }
    if (attacker.hasAttackedThisTurn) {
      throw GameRuleViolation(
        '${attacker.card.name} has already attacked this turn.',
      );
    }
  }

  void _removeDefeated(PlayerState owner) {
    owner.battlefield.removeWhere((battlefieldCard) {
      if (battlefieldCard.isDefeated) {
        _log('${battlefieldCard.card.name} is defeated.');
        return true;
      }
      return false;
    });
  }

  /// Ends the current player's turn. When it was the player's turn,
  /// this also automatically plays out the opponent's turn (there's
  /// no multiplayer or AI-controlled screen yet) before handing
  /// control back.
  void endTurn() {
    if (isGameOver) return;

    beginOpponentTurn();
    if (autoRunOpponent) {
      while (!isPlayerTurn && !isGameOver) {
        performNextOpponentAction();
      }
    }
  }

  /// Hands control to the opponent without immediately resolving its whole
  /// turn. This is used by the animated board; [endTurn] remains the
  /// convenient synchronous version for rules tests and non-visual callers.
  void beginOpponentTurn() {
    if (isGameOver || !isPlayerTurn) return;

    _log('${currentPlayer.name} ends their turn.');
    isPlayerTurn = false;
    _beginTurn();
  }

  /// Resolves exactly one bot play, attack, or end-of-turn transition.
  OpponentAction performNextOpponentAction() {
    if (isGameOver || isPlayerTurn) return const OpponentAction.finished();

    for (final card in List<GameCard>.from(opponent.hand)) {
      if (opponent.resource >= card.attackCost &&
          opponent.battlefield.length < maxBattlefieldSize) {
        playCard(opponent, card);
        return OpponentAction.played(card);
      }
    }

    for (final attacker in List<BattlefieldCard>.from(opponent.battlefield)) {
      if (!attacker.hasAttackedThisTurn) {
        final damage = attacker.card.attack;
        attackPlayer(opponent, attacker);
        return OpponentAction.attacked(attacker, damage);
      }
    }

    _log('${currentPlayer.name} ends their turn.');
    isPlayerTurn = true;
    turnNumber++;
    _beginTurn();
    return const OpponentAction.finished();
  }

  /// A very simple automatic opponent: play whatever it can afford,
  /// then attack the player's face with everything able to. This is
  /// enough to demonstrate a full two-player match without building
  /// real multiplayer or AI.
  void _runOpponentTurn() {
    while (!isPlayerTurn && !isGameOver) {
      performNextOpponentAction();
    }
  }

  void _log(String message) => log.add(message);
}
