import 'package:flutter/material.dart';

import '../data/card_catalog.dart';
import '../data/deck_library.dart';
import '../data/player_collection.dart';
import '../models/card.dart';
import '../models/deck.dart';
import '../theme/app_theme.dart';
import '../widgets/section_panel.dart';
import '../widgets/trading_card.dart';

/// Lets the player build a deck out of cards they own. Reads cards
/// from `cardCatalog`, ownership from `playerCollection`, and saves
/// finished decks into `deckLibrary` — it never keeps its own copy of
/// card or ownership data, only the deck-in-progress itself.
class DeckBuilderScreen extends StatefulWidget {
  const DeckBuilderScreen({super.key, this.initialDeck});

  final Deck? initialDeck;

  @override
  State<DeckBuilderScreen> createState() => _DeckBuilderScreenState();
}

class _DeckBuilderScreenState extends State<DeckBuilderScreen> {
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();

  CardRarity? _rarityFilter;
  late final Deck _deck;

  @override
  void initState() {
    super.initState();
    _deck = widget.initialDeck?.copy() ?? Deck(name: '');
    _nameController.text = _deck.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableCards = _visibleAvailableCards();
    final deckCards = _deckCardsInOrder();

    return Scaffold(
      appBar: AppBar(title: const Text('Deck Builder')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Deck name',
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _saveDeck,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Deck'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search your cards...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
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
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: SectionPanel(
                      title: 'Available Cards',
                      icon: Icons.collections_bookmark,
                      trailing: Text(
                        '${availableCards.length} owned',
                        style: const TextStyle(color: Colors.white),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Tap a card to add a copy to your deck.',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: availableCards.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No owned cards match your search/filter.',
                                    ),
                                  )
                                : GridView.builder(
                                    itemCount: availableCards.length,
                                    gridDelegate:
                                        const SliverGridDelegateWithMaxCrossAxisExtent(
                                          maxCrossAxisExtent: 120,
                                          mainAxisSpacing: 16,
                                          crossAxisSpacing: 12,
                                          childAspectRatio: 1 / 1.4,
                                        ),
                                    itemBuilder: (context, index) {
                                      final card = availableCards[index];
                                      return Center(
                                        child: _AvailableCardTile(
                                          key: ValueKey('available-${card.id}'),
                                          card: card,
                                          countInDeck: _deck.copiesOf(card.id),
                                          canAdd: _deck.canAdd(card.id),
                                          onTap: () => setState(
                                            () => _deck.addCopy(card.id),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: SectionPanel(
                      title: 'Current Deck',
                      icon: Icons.style,
                      trailing: Text(
                        '${_deck.totalCards}/${Deck.deckSize}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '${_deck.uniqueCardCount} unique  •  '
                            '${_deck.duplicateCardCount} duplicate',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tap a card to remove a copy.',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: deckCards.isEmpty
                                ? const Center(
                                    child: Text('No cards in your deck yet.'),
                                  )
                                : GridView.builder(
                                    itemCount: deckCards.length,
                                    gridDelegate:
                                        const SliverGridDelegateWithMaxCrossAxisExtent(
                                          maxCrossAxisExtent: 110,
                                          mainAxisSpacing: 16,
                                          crossAxisSpacing: 10,
                                          childAspectRatio: 1 / 1.4,
                                        ),
                                    itemBuilder: (context, index) {
                                      final card = deckCards[index];
                                      return Center(
                                        child: _DeckCardTile(
                                          key: ValueKey('deck-${card.id}'),
                                          card: card,
                                          count: _deck.copiesOf(card.id),
                                          onTap: () => setState(
                                            () => _deck.removeCopy(card.id),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  _deck.isValid ? Icons.check_circle : Icons.error_outline,
                  color: _deck.isValid
                      ? AppColors.forestGreen
                      : Colors.redAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _deck.isValid
                        ? 'Deck is ready to play.'
                        : 'A deck needs exactly ${Deck.deckSize} cards, with no more '
                              'than ${Deck.maxCopiesPerCard} copies of any one card.',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => setState(_deck.clear),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear Deck'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<GameCard> _visibleAvailableCards() {
    final query = _searchController.text.trim().toLowerCase();

    return cardCatalog.where((card) {
      if (!playerCollection.owns(card.id)) return false;
      final matchesRarity =
          _rarityFilter == null || card.rarity == _rarityFilter;
      final matchesSearch =
          query.isEmpty ||
          card.name.toLowerCase().contains(query) ||
          card.animal.toLowerCase().contains(query);
      return matchesRarity && matchesSearch;
    }).toList();
  }

  List<GameCard> _deckCardsInOrder() {
    return [
      for (final card in cardCatalog)
        if (_deck.cardCounts.containsKey(card.id)) card,
    ];
  }

  void _saveDeck() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage('Enter a deck name first.');
      return;
    }

    if (!_deck.isValid) {
      final remaining = Deck.deckSize - _deck.totalCards;
      final String message;
      if (remaining > 0) {
        message =
            'Deck needs $remaining more card${remaining == 1 ? '' : 's'} '
            '(${_deck.totalCards}/${Deck.deckSize}).';
      } else if (remaining < 0) {
        message =
            'Deck has too many cards (${_deck.totalCards}/${Deck.deckSize}).';
      } else {
        message = 'A card exceeds the ${Deck.maxCopiesPerCard}-copy limit.';
      }
      _showMessage(message);
      return;
    }

    _deck.name = name;
    final savedDeck = _deck.copy();
    deckLibrary.saveDeck(savedDeck);
    if (Navigator.canPop(context)) {
      Navigator.pop(context, savedDeck);
    } else {
      _showMessage("Deck '$name' saved!");
    }
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(content: Text(message)));
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

/// A card in the "Available Cards" grid. Tapping it adds a copy to
/// the deck, unless the deck is full or already has the max copies
/// of this card, in which case it's dimmed and inert.
class _AvailableCardTile extends StatelessWidget {
  const _AvailableCardTile({
    super.key,
    required this.card,
    required this.countInDeck,
    required this.canAdd,
    required this.onTap,
  });

  final GameCard card;
  final int countInDeck;
  final bool canAdd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canAdd ? onTap : null,
      child: Opacity(
        opacity: canAdd ? 1 : 0.5,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            TradingCardView(data: card, width: 100),
            if (countInDeck > 0)
              Positioned(
                top: -6,
                right: -6,
                child: _CountBadge(count: countInDeck),
              ),
          ],
        ),
      ),
    );
  }
}

/// A card in the "Current Deck" grid. Tapping it removes one copy.
class _DeckCardTile extends StatelessWidget {
  const _DeckCardTile({
    super.key,
    required this.card,
    required this.count,
    required this.onTap,
  });

  final GameCard card;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          TradingCardView(data: card, width: 95),
          Positioned(top: -6, right: -6, child: _CountBadge(count: count)),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.darkForestGreen,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Text(
        'x$count',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}
