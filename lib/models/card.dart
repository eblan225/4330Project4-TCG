/// How rare a card is. Only affects its display color/label for now;
/// pack odds and collection rules can use this later.
enum CardRarity { common, uncommon, rare, legendary }

extension CardRarityLabel on CardRarity {
  String get label {
    switch (this) {
      case CardRarity.common:
        return 'Common';
      case CardRarity.uncommon:
        return 'Uncommon';
      case CardRarity.rare:
        return 'Rare';
      case CardRarity.legendary:
        return 'Legendary';
    }
  }
}

/// The kind of card. Only creature cards exist right now; action
/// cards (buffs, tricks, etc.) are left in the enum for later so the
/// model doesn't need to change again when those are added.
enum CardType { creature, action }

extension CardTypeLabel on CardType {
  String get label {
    switch (this) {
      case CardType.creature:
        return 'Creature';
      case CardType.action:
        return 'Action';
    }
  }
}

/// The core data for a single trading card. This is the one source
/// of truth for card stats — the UI only ever reads from a
/// [GameCard], it never hardcodes stats of its own.
///
/// Named `GameCard` (not `Card`) because Flutter's Material library
/// already has a widget called `Card`, and this file gets imported
/// alongside it everywhere.
class GameCard {
  const GameCard({
    required this.id,
    required this.name,
    required this.animal,
    required this.description,
    required this.artwork,
    required this.hp,
    required this.attack,
    required this.attackCost,
    required this.cardType,
    required this.rarity,
  });

  /// Unique, stable identifier (e.g. for referencing this card from a
  /// deck or collection later). Not shown in the UI.
  final String id;

  final String name;
  final String animal;
  final String description;

  /// Path to the card's artwork asset, e.g. 'assets/cards/lion.png'.
  /// No art files exist yet, so this is usually an empty string and
  /// the UI falls back to a placeholder icon until real art is added.
  final String artwork;

  final int hp;
  final int attack;
  final int attackCost;
  final CardType cardType;
  final CardRarity rarity;
}
