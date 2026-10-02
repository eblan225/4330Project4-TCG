/// A named collection of cards the player has built for play.
///
/// A [Deck] only ever stores card ids and how many copies of each are
/// included — never [GameCard] data itself — so deck data and card
/// data stay separate. Anything that needs full card details (name,
/// stats, artwork, ...) looks them up from `cardCatalog` by id.
class Deck {
  Deck({required this.name, Map<String, int>? cardCounts})
    : cardCounts = cardCounts ?? <String, int>{};

  /// How many cards a deck needs to be playable.
  static const int deckSize = 30;

  /// The most copies of a single card allowed in one deck.
  static const int maxCopiesPerCard = 3;

  String name;

  /// Card id -> number of copies in this deck.
  final Map<String, int> cardCounts;

  int get totalCards => cardCounts.values.fold(0, (sum, count) => sum + count);

  int get uniqueCardCount => cardCounts.length;

  /// How many cards are "extra" copies beyond the first of their kind,
  /// e.g. 3 copies of one card counts as 2 duplicates.
  int get duplicateCardCount => totalCards - uniqueCardCount;

  int copiesOf(String cardId) => cardCounts[cardId] ?? 0;

  bool get isCorrectSize => totalCards == deckSize;

  bool get respectsCopyLimit =>
      cardCounts.values.every((count) => count <= maxCopiesPerCard);

  /// Whether this deck is legal to take into a match.
  bool get isValid => isCorrectSize && respectsCopyLimit;

  /// Whether one more copy of [cardId] could be added without
  /// breaking the deck size or copy-limit rules.
  bool canAdd(String cardId) {
    return totalCards < deckSize && copiesOf(cardId) < maxCopiesPerCard;
  }

  void addCopy(String cardId) {
    if (!canAdd(cardId)) return;
    cardCounts[cardId] = copiesOf(cardId) + 1;
  }

  void removeCopy(String cardId) {
    final current = copiesOf(cardId);
    if (current <= 1) {
      cardCounts.remove(cardId);
    } else {
      cardCounts[cardId] = current - 1;
    }
  }

  void clear() => cardCounts.clear();

  Deck copy() =>
      Deck(name: name, cardCounts: Map<String, int>.from(cardCounts));
}
