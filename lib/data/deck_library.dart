import '../models/deck.dart';

/// Stores every deck the player has saved, keyed by name. In-memory
/// only for now, like [PlayerCollection] — once local saving is
/// built, this is what should load from and save to disk.
class DeckLibrary {
  final List<Deck> _decks = [];

  List<Deck> get decks => List.unmodifiable(_decks);

  /// Whether the player has at least one deck that's legal to play
  /// with. Other screens (e.g. the game lobby) should check this
  /// before letting a match start.
  bool get hasValidDeck => _decks.any((deck) => deck.isValid);

  /// Saves [deck] under its name, replacing any existing deck with
  /// the same name.
  void saveDeck(Deck deck) {
    final index = _decks.indexWhere((d) => d.name == deck.name);
    if (index >= 0) {
      _decks[index] = deck;
    } else {
      _decks.add(deck);
    }
  }

  /// Removes every saved deck. Mainly useful for resetting state
  /// between tests.
  void clear() => _decks.clear();
}

/// The player's saved decks for this session.
final DeckLibrary deckLibrary = DeckLibrary();
