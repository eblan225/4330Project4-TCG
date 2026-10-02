import 'package:flutter/material.dart';

import '../data/deck_library.dart';
import '../models/deck.dart';
import '../widgets/section_panel.dart';
import 'deck_builder_screen.dart';

/// The waiting room shown only after a room has been created or found.
class GameLobbyScreen extends StatefulWidget {
  const GameLobbyScreen({
    super.key,
    required this.deck,
    required this.roomCode,
    required this.isHost,
  });

  final Deck deck;
  final String roomCode;
  final bool isHost;

  @override
  State<GameLobbyScreen> createState() => _GameLobbyScreenState();
}

class _GameLobbyScreenState extends State<GameLobbyScreen> {
  late Deck _selectedDeck = widget.deck.copy();

  Future<void> _changeDeck() async {
    final decks = deckLibrary.decks.where((deck) => deck.isValid).toList();
    final selected = await showDialog<Deck>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change deck'),
        content: SizedBox(
          width: 380,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final deck in decks)
                ListTile(
                  leading: Icon(
                    deck.name == _selectedDeck.name
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                  ),
                  title: Text(deck.name),
                  subtitle: Text('${deck.totalCards} cards'),
                  onTap: () => Navigator.pop(dialogContext, deck),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (selected != null && mounted) {
      setState(() => _selectedDeck = selected.copy());
    }
  }

  Future<void> _editDeck() async {
    final savedDeck = await Navigator.push<Deck>(
      context,
      MaterialPageRoute(
        builder: (_) => DeckBuilderScreen(initialDeck: _selectedDeck),
      ),
    );
    if (mounted && savedDeck != null) {
      setState(() => _selectedDeck = savedDeck.copy());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Lobby')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 300,
                  child: SectionPanel(
                    title: 'Room ${widget.roomCode}',
                    icon: Icons.meeting_room_outlined,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(widget.isHost ? 'You (Host)' : 'You'),
                          subtitle: Text('Using ${_selectedDeck.name}'),
                        ),
                        const ListTile(
                          leading: CircleAvatar(
                            child: Icon(Icons.hourglass_empty),
                          ),
                          title: Text('Waiting for another player...'),
                          subtitle: Text(
                            'Share the room code with your opponent.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final details = Row(
                          children: [
                            const Icon(Icons.style, size: 36),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Selected deck',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    _selectedDeck.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge,
                                  ),
                                  Text(
                                    '${_selectedDeck.totalCards} cards • Ready to play',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                        final actions = Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              key: const ValueKey('lobby-edit-deck'),
                              onPressed: _editDeck,
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Edit deck'),
                            ),
                            OutlinedButton.icon(
                              key: const ValueKey('lobby-change-deck'),
                              onPressed: _changeDeck,
                              icon: const Icon(Icons.swap_horiz),
                              label: const Text('Change deck'),
                            ),
                          ],
                        );
                        if (constraints.maxWidth < 560) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              details,
                              const SizedBox(height: 12),
                              actions,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: details),
                            const SizedBox(width: 12),
                            actions,
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: null,
                  icon: Icon(Icons.hourglass_top),
                  label: Text('Waiting for opponent'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
