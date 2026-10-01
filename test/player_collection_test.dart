import 'package:flutter_test/flutter_test.dart';

import 'package:_4330project4_tcg/data/card_catalog.dart';
import 'package:_4330project4_tcg/data/player_collection.dart';
import 'package:_4330project4_tcg/models/card.dart';

void main() {
  test('new players start owning every common and uncommon card only', () {
    final collection = PlayerCollection();

    for (final card in cardCatalog) {
      final shouldOwn =
          card.rarity == CardRarity.common || card.rarity == CardRarity.uncommon;
      expect(
        collection.owns(card.id),
        shouldOwn,
        reason: '${card.name} (${card.rarity.label}) ownership should be $shouldOwn',
      );
    }
  });

  test('addCard grants a single card', () {
    final collection = PlayerCollection(startingCardIds: {});
    expect(collection.owns('lion'), isFalse);

    collection.addCard('lion');

    expect(collection.owns('lion'), isTrue);
  });

  test('addCard is safe to call for an already-owned card', () {
    final collection = PlayerCollection(startingCardIds: {'lion'});

    collection.addCard('lion');

    expect(collection.ownedCardIds, {'lion'});
  });

  test('addCards grants several cards at once', () {
    final collection = PlayerCollection(startingCardIds: {});

    collection.addCards(['lion', 'tiger', 'shark']);

    expect(collection.owns('lion'), isTrue);
    expect(collection.owns('tiger'), isTrue);
    expect(collection.owns('shark'), isTrue);
    expect(collection.owns('elephant'), isFalse);
  });

  test('ownedCardIds cannot be mutated from outside', () {
    final collection = PlayerCollection(startingCardIds: {'lion'});

    expect(() => collection.ownedCardIds.add('tiger'), throwsUnsupportedError);
  });
}
