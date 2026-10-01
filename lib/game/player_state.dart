import 'dart:math';

import '../models/card.dart';
import 'battlefield_card.dart';

/// One player's live state during a match: HP, resources, hand, draw
/// pile, and battlefield. This is created fresh for each match by
/// [GameEngine] — it's runtime state, not saved data like a [Deck].
class PlayerState {
  PlayerState({required this.name, required List<GameCard> deckCards})
      : deck = List<GameCard>.from(deckCards);

  final String name;

  int hp = 0;
  int resource = 0;
  int resourceCap = 0;

  final List<GameCard> hand = [];
  final List<GameCard> deck;
  final List<BattlefieldCard> battlefield = [];

  bool get isDefeated => hp <= 0;

  void shuffleDeck(Random random) => deck.shuffle(random);

  /// Draws the top card of the deck into hand, and returns it. Does
  /// nothing (returns null) if the deck is empty — no fatigue damage,
  /// kept simple.
  GameCard? drawCard() {
    if (deck.isEmpty) return null;
    final card = deck.removeLast();
    hand.add(card);
    return card;
  }
}
