// Checks on the card data itself, separate from the UI tests in
// widget_test.dart.

import 'package:flutter_test/flutter_test.dart';

import 'package:_4330project4_tcg/data/card_catalog.dart';

void main() {
  test('catalog has around 20 cards', () {
    expect(cardCatalog.length, 20);
  });

  test('every card has a unique id', () {
    final ids = cardCatalog.map((card) => card.id).toSet();
    expect(ids.length, cardCatalog.length);
  });

  test('every card has positive stats and a valid attack cost', () {
    for (final card in cardCatalog) {
      expect(card.hp, greaterThan(0), reason: '${card.name} should have positive HP');
      expect(card.attack, greaterThan(0), reason: '${card.name} should have positive attack');
      expect(
        card.attackCost,
        inInclusiveRange(1, 6),
        reason: '${card.name} should have a 1-6 attack cost',
      );
    }
  });

  test('higher attack cost cards are generally stronger', () {
    final byCost = <int, List<int>>{};
    for (final card in cardCatalog) {
      byCost.putIfAbsent(card.attackCost, () => []).add(card.hp + card.attack);
    }

    double averageAt(int cost) {
      final totals = byCost[cost]!;
      return totals.reduce((a, b) => a + b) / totals.length;
    }

    final costs = byCost.keys.toList()..sort();
    for (var i = 1; i < costs.length; i++) {
      expect(
        averageAt(costs[i]),
        greaterThan(averageAt(costs[i - 1])),
        reason: 'cost ${costs[i]} cards should average stronger than cost ${costs[i - 1]} cards',
      );
    }
  });
}
