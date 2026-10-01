/// How rare a card is. Only used to pick a display color/label for
/// now — rarity doesn't affect anything else yet.
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

/// Temporary stand-in for the real Card model. This only exists so
/// the UI has something to display — it will be replaced once the
/// actual card data (name, animal, HP, attack, etc.) is built as its
/// own feature.
class PlaceholderCardData {
  const PlaceholderCardData({
    required this.name,
    required this.animal,
    required this.cardType,
    required this.description,
    required this.hp,
    required this.attack,
    required this.cost,
    required this.rarity,
  });

  final String name;
  final String animal;
  final String cardType;
  final String description;
  final int hp;
  final int attack;
  final int cost;
  final CardRarity rarity;
}

/// Sample cards just for laying out grids, hands, and fields.
const List<PlaceholderCardData> placeholderCards = [
  PlaceholderCardData(
    name: 'Timber Wolf',
    animal: 'Wolf',
    cardType: 'Creature',
    description: 'Hunts in packs under the moonlight.',
    hp: 40,
    attack: 25,
    cost: 3,
    rarity: CardRarity.common,
  ),
  PlaceholderCardData(
    name: 'Desert Fox',
    animal: 'Fox',
    cardType: 'Creature',
    description: 'Quick and clever, hard to pin down.',
    hp: 25,
    attack: 20,
    cost: 2,
    rarity: CardRarity.common,
  ),
  PlaceholderCardData(
    name: 'Stone Tortoise',
    animal: 'Tortoise',
    cardType: 'Creature',
    description: 'A shell as hard as bedrock.',
    hp: 70,
    attack: 10,
    cost: 3,
    rarity: CardRarity.uncommon,
  ),
  PlaceholderCardData(
    name: 'Night Owl',
    animal: 'Owl',
    cardType: 'Creature',
    description: 'Sees everything, even in the dark.',
    hp: 30,
    attack: 30,
    cost: 4,
    rarity: CardRarity.uncommon,
  ),
  PlaceholderCardData(
    name: 'Savanna Lion',
    animal: 'Lion',
    cardType: 'Creature',
    description: 'King of the grasslands.',
    hp: 60,
    attack: 45,
    cost: 5,
    rarity: CardRarity.rare,
  ),
  PlaceholderCardData(
    name: 'Reef Shark',
    animal: 'Shark',
    cardType: 'Creature',
    description: 'Never stops circling its prey.',
    hp: 50,
    attack: 40,
    cost: 4,
    rarity: CardRarity.rare,
  ),
  PlaceholderCardData(
    name: 'Skyfire Falcon',
    animal: 'Falcon',
    cardType: 'Creature',
    description: 'Dives faster than any other bird.',
    hp: 35,
    attack: 50,
    cost: 5,
    rarity: CardRarity.rare,
  ),
  PlaceholderCardData(
    name: 'Ancient Elephant',
    animal: 'Elephant',
    cardType: 'Creature',
    description: 'Remembers every battle it has fought.',
    hp: 100,
    attack: 35,
    cost: 6,
    rarity: CardRarity.legendary,
  ),
  PlaceholderCardData(
    name: 'Shadow Tiger',
    animal: 'Tiger',
    cardType: 'Creature',
    description: 'Strikes once, and only once, perfectly.',
    hp: 55,
    attack: 60,
    cost: 6,
    rarity: CardRarity.legendary,
  ),
  PlaceholderCardData(
    name: 'Burrow Rabbit',
    animal: 'Rabbit',
    cardType: 'Creature',
    description: 'Always has an escape route ready.',
    hp: 15,
    attack: 10,
    cost: 1,
    rarity: CardRarity.common,
  ),
  PlaceholderCardData(
    name: 'Pack Tactics',
    animal: 'Wolf',
    cardType: 'Action',
    description: 'Boost an ally\'s attack for the turn.',
    hp: 0,
    attack: 15,
    cost: 2,
    rarity: CardRarity.uncommon,
  ),
  PlaceholderCardData(
    name: 'Emergency Burrow',
    animal: 'Rabbit',
    cardType: 'Action',
    description: 'Retreat a creature before it takes damage.',
    hp: 0,
    attack: 0,
    cost: 1,
    rarity: CardRarity.common,
  ),
];
