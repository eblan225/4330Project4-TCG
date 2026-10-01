import 'package:flutter/material.dart';

import '../data/placeholder_cards.dart';
import '../theme/app_theme.dart';
import '../widgets/trading_card.dart';

/// Shows every card the player owns. The grid is populated with
/// placeholder cards for now until the real collection data exists.
class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  CardRarity? _rarityFilter;

  @override
  Widget build(BuildContext context) {
    final cards = _rarityFilter == null
        ? placeholderCards
        : placeholderCards.where((c) => c.rarity == _rarityFilter).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Card Collection')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search cards...',
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
            Text(
              '${cards.length} card${cards.length == 1 ? '' : 's'}',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: cards.isEmpty
                  ? const Center(child: Text('No cards match this filter yet.'))
                  : GridView.builder(
                      itemCount: cards.length,
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 150,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1 / 1.4,
                      ),
                      itemBuilder: (context, index) => Center(
                        child: TradingCardView(data: cards[index], width: 140),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
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
