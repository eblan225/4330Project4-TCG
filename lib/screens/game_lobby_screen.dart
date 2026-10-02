import 'package:flutter/material.dart';

import '../data/deck_library.dart';
import '../models/deck.dart';
import '../widgets/section_panel.dart';
import 'deck_builder_screen.dart';
import 'game_board_screen.dart';

/// Lets a player choose an AI practice match or prepare a private room.
/// The private-room UI is ready for a future networking service; only
/// bot matches enter the board until that service is connected.
class GameLobbyScreen extends StatefulWidget {
  const GameLobbyScreen({super.key});

  @override
  State<GameLobbyScreen> createState() => _GameLobbyScreenState();
}

class _GameLobbyScreenState extends State<GameLobbyScreen> {
  final _codeController = TextEditingController();
  bool _isHosting = false;
  static const _roomCode = 'WILD-482';

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
                  children: [
                    const ListTile(
                      leading: Icon(Icons.person),
                      title: Text('You (Host)'),
                    ),
                    ListTile(
                      leading: Icon(
                        _isHosting
                            ? Icons.wifi_tethering
                            : Icons.hourglass_empty,
                      ),
                      title: Text(
                        _isHosting
                            ? 'Private room: $_roomCode'
                            : 'Choose how you want to play below',
                      ),
                      subtitle: _isHosting
                          ? const Text('Waiting for another player to join...')
                          : null,
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
                      description:
                          'Start a new match and wait for an opponent to join.',
                      buttonLabel: 'Create',
                      onPressed: () => _showCreateGameChoices(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _LobbyActionCard(
                      icon: Icons.login,
                      title: 'Join Game',
                      description:
                          "Enter a game code to join a friend's match.",
                      buttonLabel: 'Join',
                      onPressed: () => _joinHumanGame(context),
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

  void _showCreateGameChoices(BuildContext context) {
    if (!_hasValidDeck(context)) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose an opponent',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              const Text(
                'You can practice immediately or create a room for a friend.',
              ),
              const SizedBox(height: 20),
              _OpponentChoice(
                icon: Icons.smart_toy_outlined,
                title: 'Play against a bot',
                subtitle: 'Start a match right away.',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _enterBotGame(context);
                },
              ),
              const SizedBox(height: 12),
              _OpponentChoice(
                icon: Icons.people_outline,
                title: 'Play another player',
                subtitle: 'Create a private room and share its code.',
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() => _isHosting = true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasValidDeck(BuildContext context) {
    if (!deckLibrary.hasValidDeck) {
      _showNoValidDeckDialog(context);
      return false;
    }
    return true;
  }

  void _enterBotGame(BuildContext context) {
    if (!_hasValidDeck(context)) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GameBoardScreen()),
    );
  }

  void _joinHumanGame(BuildContext context) {
    if (!_hasValidDeck(context)) return;
    if (_codeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter the room code your friend shared.'),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Online room connection is the next multiplayer step.'),
      ),
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

class _OpponentChoice extends StatelessWidget {
  const _OpponentChoice({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
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
            if (field != null) ...[const SizedBox(height: 12), field!],
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onPressed, child: Text(buttonLabel)),
          ],
        ),
      ),
    );
  }
}
