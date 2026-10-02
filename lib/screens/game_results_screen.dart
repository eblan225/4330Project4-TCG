import 'package:flutter/material.dart';

import '../data/deck_library.dart';
import '../models/deck.dart';
import '../theme/app_theme.dart';
import 'game_board_screen.dart';

/// A snapshot of the completed match; the finished board is replaced by this route.
class GameResultsScreen extends StatelessWidget {
  const GameResultsScreen({
    super.key,
    required this.didWin,
    required this.turnsPlayed,
    required this.cardsPlayed,
    required this.damageDealt,
    required this.deck,
  });
  final bool didWin;
  final int turnsPlayed;
  final int cardsPlayed;
  final int damageDealt;
  final Deck deck;

  void _play(BuildContext context, Deck selected) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => GameBoardScreen(deck: selected.copy()),
      ),
    );
  }

  Future<void> _changeDeck(BuildContext context) async {
    final decks = deckLibrary.decks.where((deck) => deck.isValid).toList();
    final selected = await showDialog<Deck>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose a deck'),
        content: SizedBox(
          width: 360,
          child: decks.isEmpty
              ? const Text(
                  'No saved decks are available. Return to the main menu to build a deck.',
                )
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final candidate in decks)
                      ListTile(
                        title: Text(candidate.name),
                        subtitle: Text('${candidate.totalCards} cards'),
                        trailing: const Icon(Icons.play_arrow),
                        onTap: () => Navigator.pop(context, candidate),
                      ),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (context.mounted && selected != null) _play(context, selected);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Game Results')),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                didWin ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                size: 96,
                color: didWin ? AppColors.goldAccent : Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                didWin ? 'Victory!' : 'Defeat',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text('Your match with ${deck.name}'),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _ResultStatRow(
                        label: 'Turns Played',
                        value: '$turnsPlayed',
                      ),
                      _ResultStatRow(
                        label: 'Cards Played',
                        value: '$cardsPlayed',
                      ),
                      _ResultStatRow(
                        label: 'Damage Dealt',
                        value: '$damageDealt',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your turns started, cards played, and actual damage to enemy cards and the opponent (including retaliation).',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _play(context, deck),
                    icon: const Icon(Icons.replay),
                    label: const Text('Play again'),
                  ),
                  OutlinedButton(
                    onPressed: () => _changeDeck(context),
                    child: const Text('Change deck'),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst),
                    child: const Text('Main Menu'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ResultStatRow extends StatelessWidget {
  const _ResultStatRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          key: ValueKey('result-$label'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}
