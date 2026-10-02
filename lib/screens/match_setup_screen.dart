import 'package:flutter/material.dart';

import '../data/deck_library.dart';
import '../models/deck.dart';
import 'deck_builder_screen.dart';
import 'game_board_screen.dart';
import 'game_lobby_screen.dart';

/// Selects a deck and match type before entering a room or game.
class MatchSetupScreen extends StatefulWidget {
  const MatchSetupScreen({super.key});

  @override
  State<MatchSetupScreen> createState() => _MatchSetupScreenState();
}

class _MatchSetupScreenState extends State<MatchSetupScreen> {
  final _roomCodeController = TextEditingController();
  Deck? _selectedDeck;

  List<Deck> get _validDecks =>
      deckLibrary.decks.where((deck) => deck.isValid).toList();

  @override
  void initState() {
    super.initState();
    final decks = _validDecks;
    if (decks.isNotEmpty) _selectedDeck = decks.first;
  }

  @override
  void dispose() {
    _roomCodeController.dispose();
    super.dispose();
  }

  Deck? _requireDeck() {
    if (_selectedDeck case final deck? when deck.isValid) return deck;
    _showNoValidDeckDialog();
    return null;
  }

  Future<void> _openDeckBuilder({Deck? deck}) async {
    final savedDeck = await Navigator.push<Deck>(
      context,
      MaterialPageRoute(
        builder: (_) => DeckBuilderScreen(initialDeck: deck?.copy()),
      ),
    );
    if (!mounted) return;
    final validDecks = _validDecks;
    setState(() {
      if (savedDeck?.isValid ?? false) {
        _selectedDeck = savedDeck;
      } else if (_selectedDeck == null && validDecks.isNotEmpty) {
        _selectedDeck = validDecks.first;
      }
    });
  }

  void _playBot() {
    final deck = _requireDeck();
    if (deck == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GameBoardScreen(deck: deck.copy())),
    );
  }

  void _createRoom() {
    final deck = _requireDeck();
    if (deck == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameLobbyScreen(
          deck: deck.copy(),
          roomCode: 'WILD-482',
          isHost: true,
        ),
      ),
    );
  }

  void _findRoom() {
    final deck = _requireDeck();
    if (deck == null) return;
    final code = _roomCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter the room code your friend shared.'),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            GameLobbyScreen(deck: deck.copy(), roomCode: code, isHost: false),
      ),
    );
  }

  void _showNoValidDeckDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('No Valid Deck'),
        content: Text(
          'You need a saved deck with exactly ${Deck.deckSize} cards before starting.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _openDeckBuilder();
            },
            child: const Text('Go to Deck Builder'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final decks = _validDecks;
    return Scaffold(
      appBar: AppBar(title: const Text('Play')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Choose your deck',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                if (decks.isEmpty)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.warning_amber),
                      title: const Text('No playable decks yet'),
                      subtitle: const Text(
                        'Build and save a valid 30-card deck first.',
                      ),
                      trailing: FilledButton(
                        onPressed: _openDeckBuilder,
                        child: const Text('Build deck'),
                      ),
                    ),
                  )
                else
                  DropdownButtonFormField<Deck>(
                    key: const ValueKey('deck-chooser'),
                    isExpanded: true,
                    initialValue: _selectedDeck,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.style),
                      labelText: 'Battle deck',
                    ),
                    items: [
                      for (final deck in decks)
                        DropdownMenuItem(
                          value: deck,
                          child: Text(
                            '${deck.name} • ${deck.totalCards} cards',
                          ),
                        ),
                    ],
                    onChanged: (deck) => setState(() => _selectedDeck = deck),
                  ),
                if (_selectedDeck != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      key: const ValueKey('setup-edit-deck'),
                      onPressed: () => _openDeckBuilder(deck: _selectedDeck),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit deck'),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Choose a match',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    _SetupAction(
                      icon: Icons.smart_toy_outlined,
                      title: 'Practice with bot',
                      subtitle: 'Start immediately.',
                      onTap: _playBot,
                    ),
                    _SetupAction(
                      icon: Icons.add_circle_outline,
                      title: 'Create room',
                      subtitle: 'Open a room for a friend.',
                      onTap: _createRoom,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final field = TextField(
                          controller: _roomCodeController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Room code',
                            hintText: 'WILD-482',
                            border: OutlineInputBorder(),
                          ),
                        );
                        final button = FilledButton.icon(
                          onPressed: _findRoom,
                          icon: const Icon(Icons.search),
                          label: const Text('Find room'),
                        );
                        if (constraints.maxWidth < 480) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              field,
                              const SizedBox(height: 12),
                              button,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: field),
                            const SizedBox(width: 12),
                            button,
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupAction extends StatelessWidget {
  const _SetupAction({
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
    return SizedBox(
      width: 280,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(child: Icon(icon)),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }
}
