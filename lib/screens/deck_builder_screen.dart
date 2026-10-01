import 'package:flutter/material.dart';

import '../data/placeholder_cards.dart';
import '../widgets/section_panel.dart';
import '../widgets/trading_card.dart';

/// Lets the player look at their available cards next to their
/// current deck. Both panels show placeholder data for now — actual
/// deck building (adding/removing cards, saving decks) is a later
/// feature, so the buttons here just explain that it's not ready.
class DeckBuilderScreen extends StatelessWidget {
  const DeckBuilderScreen({super.key});

  static const _deckSizeLimit = 30;

  @override
  Widget build(BuildContext context) {
    final deckCards = placeholderCards.take(5).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Deck Builder')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: SectionPanel(
                      title: 'Available Cards',
                      icon: Icons.collections_bookmark,
                      child: GridView.builder(
                        itemCount: placeholderCards.length,
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 120,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1 / 1.4,
                        ),
                        itemBuilder: (context, index) => Center(
                          child: TradingCardView(
                            data: placeholderCards[index],
                            width: 110,
                          ),
                        ),
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
                        '${deckCards.length}/$_deckSizeLimit',
                        style: const TextStyle(color: Colors.white),
                      ),
                      child: deckCards.isEmpty
                          ? const Center(child: Text('No cards in your deck yet.'))
                          : GridView.builder(
                              itemCount: deckCards.length,
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 110,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 1 / 1.4,
                              ),
                              itemBuilder: (context, index) => Center(
                                child: TradingCardView(
                                  data: deckCards[index],
                                  width: 100,
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showComingSoon(context),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear Deck'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showComingSoon(context),
                  icon: const Icon(Icons.save),
                  label: const Text('Save Deck'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Deck building isn't implemented yet.")),
    );
  }
}
