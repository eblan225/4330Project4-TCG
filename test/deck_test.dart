import 'package:flutter_test/flutter_test.dart';

import 'package:_4330project4_tcg/models/deck.dart';

void main() {
  test('a fresh deck is empty and invalid', () {
    final deck = Deck(name: 'Empty');

    expect(deck.totalCards, 0);
    expect(deck.uniqueCardCount, 0);
    expect(deck.duplicateCardCount, 0);
    expect(deck.isValid, isFalse);
  });

  test('addCopy increases the count for that card', () {
    final deck = Deck(name: 'Test');

    deck.addCopy('lion');
    deck.addCopy('lion');

    expect(deck.copiesOf('lion'), 2);
    expect(deck.totalCards, 2);
    expect(deck.uniqueCardCount, 1);
    expect(deck.duplicateCardCount, 1);
  });

  test('addCopy refuses a 4th copy of the same card', () {
    final deck = Deck(name: 'Test');

    for (var i = 0; i < 5; i++) {
      deck.addCopy('lion');
    }

    expect(deck.copiesOf('lion'), Deck.maxCopiesPerCard);
  });

  test('addCopy refuses to exceed the deck size', () {
    final deck = Deck(name: 'Test');
    final ids = List.generate(11, (i) => 'card$i');

    for (final id in ids) {
      deck.addCopy(id);
      deck.addCopy(id);
      deck.addCopy(id);
    }

    expect(deck.totalCards, Deck.deckSize);
  });

  test('removeCopy decreases the count and removes the entry at zero', () {
    final deck = Deck(name: 'Test', cardCounts: {'lion': 2});

    deck.removeCopy('lion');
    expect(deck.copiesOf('lion'), 1);
    expect(deck.cardCounts.containsKey('lion'), isTrue);

    deck.removeCopy('lion');
    expect(deck.copiesOf('lion'), 0);
    expect(deck.cardCounts.containsKey('lion'), isFalse);
  });

  test('removeCopy on a card not in the deck does nothing', () {
    final deck = Deck(name: 'Test');

    deck.removeCopy('lion');

    expect(deck.totalCards, 0);
  });

  test('a deck with exactly 30 cards and no card over the copy limit is valid', () {
    final deck = Deck(name: 'Valid');
    for (var i = 0; i < 10; i++) {
      deck.cardCounts['card$i'] = 3;
    }

    expect(deck.totalCards, 30);
    expect(deck.isValid, isTrue);
  });

  test('clear empties the deck', () {
    final deck = Deck(name: 'Test', cardCounts: {'lion': 3, 'tiger': 2});

    deck.clear();

    expect(deck.totalCards, 0);
    expect(deck.cardCounts, isEmpty);
  });

  test('copy produces an independent deck', () {
    final original = Deck(name: 'Original', cardCounts: {'lion': 1});
    final copy = original.copy();

    copy.addCopy('lion');

    expect(original.copiesOf('lion'), 1);
    expect(copy.copiesOf('lion'), 2);
  });
}
