import 'package:flutter/material.dart';

import '../data/card_catalog.dart';
import '../data/player_collection.dart';
import '../models/card.dart';
import '../theme/app_theme.dart';
import '../widgets/trading_card.dart';

/// Shows every card in the game — the ones the player owns, and the
/// ones they don't yet (shown dimmed and locked). Reads entirely from
/// `cardCatalog` (the card data) and `playerCollection` (which cards
/// are owned); it never stores its own copy of card data.
class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

enum _SortOption { nameAsc, rarity, costAsc, hpDesc, attackDesc }

extension on _SortOption {
  String get label {
    switch (this) {
      case _SortOption.nameAsc:
        return 'Name (A–Z)';
      case _SortOption.rarity:
        return 'Rarity';
      case _SortOption.costAsc:
        return 'Attack Cost (Low–High)';
      case _SortOption.hpDesc:
        return 'HP (High–Low)';
      case _SortOption.attackDesc:
        return 'Attack (High–Low)';
    }
  }
}

class _CollectionScreenState extends State<CollectionScreen> {
  final _searchController = TextEditingController();

  CardRarity? _rarityFilter;
  _SortOption _sortOption = _SortOption.rarity;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cards = _visibleCards();
    final ownedCount = cardCatalog.where((c) => playerCollection.owns(c.id)).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Card Collection')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by name or animal...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _RarityChip(
                  label: 'All',
                  selected: _rarityFilter == null,
                  onTap: () => setState(() => _rarityFilter = null),
                ),
                for (final rarity in CardRarity.values)
                  _RarityChip(
                    label: rarity.label,
                    selected: _rarityFilter == rarity,
                    onTap: () => setState(() => _rarityFilter = rarity),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$ownedCount of ${cardCatalog.length} cards collected '
                    '(${cards.length} shown)',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
                const Text('Sort: ', style: TextStyle(color: Colors.black54)),
                DropdownButton<_SortOption>(
                  value: _sortOption,
                  underline: const SizedBox.shrink(),
                  items: [
                    for (final option in _SortOption.values)
                      DropdownMenuItem(value: option, child: Text(option.label)),
                  ],
                  onChanged: (option) {
                    if (option != null) setState(() => _sortOption = option);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: cards.isEmpty
                  ? const Center(child: Text('No cards match your search/filter.'))
                  : GridView.builder(
                      itemCount: cards.length,
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 150,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1 / 1.4,
                      ),
                      itemBuilder: (context, index) => Center(
                        child: TradingCardView(
                          data: cards[index],
                          width: 140,
                          owned: playerCollection.owns(cards[index].id),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<GameCard> _visibleCards() {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = cardCatalog.where((card) {
      final matchesRarity = _rarityFilter == null || card.rarity == _rarityFilter;
      final matchesSearch = query.isEmpty ||
          card.name.toLowerCase().contains(query) ||
          card.animal.toLowerCase().contains(query);
      return matchesRarity && matchesSearch;
    }).toList();

    switch (_sortOption) {
      case _SortOption.nameAsc:
        filtered.sort((a, b) => a.name.compareTo(b.name));
      case _SortOption.rarity:
        filtered.sort((a, b) => a.rarity.index.compareTo(b.rarity.index));
      case _SortOption.costAsc:
        filtered.sort((a, b) => a.attackCost.compareTo(b.attackCost));
      case _SortOption.hpDesc:
        filtered.sort((a, b) => b.hp.compareTo(a.hp));
      case _SortOption.attackDesc:
        filtered.sort((a, b) => b.attack.compareTo(a.attack));
    }

    return filtered;
  }
}

class _RarityChip extends StatelessWidget {
  const _RarityChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
