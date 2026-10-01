import '../models/card.dart';
import 'card_catalog.dart';

/// Tracks which cards the player currently owns, by card id. This is
/// the single place "ownership" lives — the collection screen reads
/// from it, and later features (pack opening, multiplayer match
/// rewards) should add cards through it rather than tracking
/// ownership themselves.
///
/// This only lives in memory for now, so it resets on every app
/// restart. Once local saving is built, this is the class that
/// should load from and save to disk — nothing else should need to
/// change.
class PlayerCollection {
  PlayerCollection({Set<String>? startingCardIds})
      : _ownedCardIds = startingCardIds ?? _defaultStarterCardIds();

  final Set<String> _ownedCardIds;

  /// Every card id the player currently owns.
  Set<String> get ownedCardIds => Set.unmodifiable(_ownedCardIds);

  bool owns(String cardId) => _ownedCardIds.contains(cardId);

  /// Grants the player a card. Safe to call for a card they already
  /// own. Future features that give the player cards (pack opening,
  /// multiplayer rewards) should call this instead of touching
  /// ownership state directly.
  void addCard(String cardId) => _ownedCardIds.add(cardId);

  void addCards(Iterable<String> cardIds) => _ownedCardIds.addAll(cardIds);

  /// New players start owning every common and uncommon card. Rarer
  /// cards are meant to be earned later through packs or matches, so
  /// they start unowned — that's what gives the collection screen
  /// something to show as "not owned" before pack opening exists.
  static Set<String> _defaultStarterCardIds() {
    return cardCatalog
        .where(
          (card) =>
              card.rarity == CardRarity.common || card.rarity == CardRarity.uncommon,
        )
        .map((card) => card.id)
        .toSet();
  }
}

/// The player's collection for this session. A real account system
/// would load one of these per player; for this project a single
/// shared instance is enough.
final PlayerCollection playerCollection = PlayerCollection();
