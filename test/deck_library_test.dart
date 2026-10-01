import 'package:flutter_test/flutter_test.dart';

import 'package:_4330project4_tcg/data/deck_library.dart';
import 'package:_4330project4_tcg/models/deck.dart';

void main() {
  setUp(() {
    deckLibrary.clear();
  });

  test('a new library has no valid deck', () {
    expect(deckLibrary.hasValidDeck, isFalse);
  });

  test('saveDeck with an invalid deck does not count as a valid deck', () {
    deckLibrary.saveDeck(Deck(name: 'Incomplete', cardCounts: {'lion': 1}));

    expect(deckLibrary.hasValidDeck, isFalse);
  });

  test('saveDeck with a valid (30-card) deck is reflected in hasValidDeck', () {
    final deck = Deck(name: 'Ready');
    for (var i = 0; i < 10; i++) {
      deck.cardCounts['card$i'] = 3;
    }

    deckLibrary.saveDeck(deck);

    expect(deckLibrary.hasValidDeck, isTrue);
    expect(deckLibrary.decks, hasLength(1));
  });

  test('saving a deck with an existing name replaces it instead of duplicating', () {
    deckLibrary.saveDeck(Deck(name: 'My Deck', cardCounts: {'lion': 1}));
    deckLibrary.saveDeck(Deck(name: 'My Deck', cardCounts: {'tiger': 2}));

    expect(deckLibrary.decks, hasLength(1));
    expect(deckLibrary.decks.first.cardCounts, {'tiger': 2});
  });
}
