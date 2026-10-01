import '../models/card.dart';

/// A card that's currently on a player's battlefield during a match.
/// Wraps the catalog [GameCard] (name/stats/etc., which never change)
/// with the extra state that only matters mid-game: how much HP it
/// has left, and whether it's already attacked this turn.
class BattlefieldCard {
  BattlefieldCard(this.card) : currentHp = card.hp;

  final GameCard card;
  int currentHp;
  bool hasAttackedThisTurn = false;

  bool get isDefeated => currentHp <= 0;
}
