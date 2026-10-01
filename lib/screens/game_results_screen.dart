import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shown after a match ends. Takes whether the player won so the
/// banner and icon can change, but there's no real win/loss logic
/// wired up yet — this is reached from a demo button on the game
/// board for now.
class GameResultsScreen extends StatelessWidget {
  const GameResultsScreen({super.key, required this.didWin});

  final bool didWin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Results')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: const [
                      _ResultStatRow(label: 'Turns Played', value: '--'),
                      _ResultStatRow(label: 'Cards Played', value: '--'),
                      _ResultStatRow(label: 'Damage Dealt', value: '--'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () =>
                        Navigator.of(context).popUntil((route) => route.isFirst),
                    child: const Text('Main Menu'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back to Board'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultStatRow extends StatelessWidget {
  const _ResultStatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
