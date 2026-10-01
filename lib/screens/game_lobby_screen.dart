import 'package:flutter/material.dart';

import '../data/deck_library.dart';
import '../models/deck.dart';
import '../widgets/section_panel.dart';
import 'deck_builder_screen.dart';
import 'game_board_screen.dart';

/// Lets a player create or join a match before heading to the game
/// board. Matchmaking isn't implemented yet — both buttons just open
/// the board so the rest of the navigation flow can be seen end-to-end.
class GameLobbyScreen extends StatefulWidget {
  const GameLobbyScreen({super.key});

  @override
  State<GameLobbyScreen> createState() => _GameLobbyScreenState();
}

class _GameLobbyScreenState extends State<GameLobbyScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Lobby')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 2,
              child: SectionPanel(
                title: 'Players in Lobby',
                icon: Icons.groups,
                child: ListView(
                  children: const [
                    ListTile(
                      leading: Icon(Icons.person),
                      title: Text('You (Host)'),
                    ),
                    ListTile(
                      leading: Icon(Icons.hourglass_empty),
                      title: Text('Waiting for an opponent...'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              flex: 3,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _LobbyActionCard(
                      icon: Icons.add_circle_outline,
                      title: 'Create Game',
                      description: 'Start a new match and wait for an opponent to join.',
                      buttonLabel: 'Create',
                      onPressed: () => _enterGame(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _LobbyActionCard(
                      icon: Icons.login,
                      title: 'Join Game',
                      description: "Enter a game code to join a friend's match.",
                      buttonLabel: 'Join',
                      onPressed: () => _enterGame(context),
                      field: TextField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          hintText: 'Game code',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _enterGame(BuildContext context) {
    if (!deckLibrary.hasValidDeck) {
      _showNoValidDeckDialog(context);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GameBoardScreen()),
    );
  }

  void _showNoValidDeckDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('No Valid Deck'),
        content: Text(
          'You need a saved deck with exactly ${Deck.deckSize} cards (no more than '
          '${Deck.maxCopiesPerCard} copies of any one card) before starting a game. '
          'Go build one in Deck Builder.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DeckBuilderScreen()),
              );
            },
            child: const Text('Go to Deck Builder'),
          ),
        ],
      ),
    );
  }
}

class _LobbyActionCard extends StatelessWidget {
  const _LobbyActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
    this.field,
  });

  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onPressed;
  final Widget? field;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            if (field != null) ...[
              const SizedBox(height: 12),
              field!,
            ],
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onPressed, child: Text(buttonLabel)),
          ],
        ),
      ),
    );
  }
}
