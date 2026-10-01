import 'package:flutter/material.dart';

import '../data/placeholder_cards.dart';
import '../theme/app_theme.dart';
import '../widgets/section_panel.dart';
import '../widgets/trading_card.dart';
import 'game_results_screen.dart';

/// Lays out every area a match will need: both hands, both fields,
/// HP/resource totals, a turn indicator, the end turn button, and a
/// game log. No game rules are implemented yet — this screen is UI
/// only. "End Turn" just flips the turn indicator and adds a line to
/// the log so the layout can be seen working.
class GameBoardScreen extends StatefulWidget {
  const GameBoardScreen({super.key});

  @override
  State<GameBoardScreen> createState() => _GameBoardScreenState();
}

class _GameBoardScreenState extends State<GameBoardScreen> {
  bool _isPlayerTurn = true;
  int _turnNumber = 1;
  final List<String> _log = ['Game started.', 'Your turn begins.'];

  void _endTurn() {
    setState(() {
      _log.add(_isPlayerTurn ? 'You ended your turn.' : "Opponent ended their turn.");
      _isPlayerTurn = !_isPlayerTurn;
      if (_isPlayerTurn) _turnNumber++;
      _log.add(_isPlayerTurn ? 'Your turn begins.' : "Opponent's turn begins.");
    });
  }

  @override
  Widget build(BuildContext context) {
    final handCards = placeholderCards.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Board'),
        actions: [
          IconButton(
            tooltip: 'Preview results screen (demo)',
            icon: const Icon(Icons.flag_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GameResultsScreen(didWin: true)),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _PlayerStatusBar(label: 'Opponent', hp: 100, resource: 3),
                  const SizedBox(height: 8),
                  const _HandRow(label: 'Opponent Hand', count: 5, faceDown: true),
                  const SizedBox(height: 8),
                  const Expanded(child: _FieldRow(label: 'Opponent Field')),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.center,
                    child: _TurnBanner(
                      turnNumber: _turnNumber,
                      isPlayerTurn: _isPlayerTurn,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Expanded(child: _FieldRow(label: 'Player Field')),
                  const SizedBox(height: 8),
                  _HandRow(label: 'Player Hand', cards: handCards),
                  const SizedBox(height: 8),
                  _PlayerStatusBar(
                    label: 'Player',
                    hp: 100,
                    resource: 3,
                    trailing: ElevatedButton.icon(
                      onPressed: _endTurn,
                      icon: const Icon(Icons.skip_next),
                      label: const Text('End Turn'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 220,
              child: SectionPanel(
                title: 'Game Log',
                icon: Icons.menu_book,
                child: ListView.builder(
                  reverse: true,
                  itemCount: _log.length,
                  itemBuilder: (context, index) {
                    final entry = _log[_log.length - 1 - index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(entry, style: const TextStyle(fontSize: 13)),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerStatusBar extends StatelessWidget {
  const _PlayerStatusBar({
    required this.label,
    required this.hp,
    required this.resource,
    this.trailing,
  });

  final String label;
  final int hp;
  final int resource;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.earthBrown.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          _StatPill(icon: Icons.favorite, color: Colors.redAccent, value: hp),
          const SizedBox(width: 8),
          _StatPill(icon: Icons.bolt, color: Colors.blueAccent, value: resource),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.color,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text('$value', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _HandRow extends StatelessWidget {
  const _HandRow({
    required this.label,
    this.count = 0,
    this.cards,
    this.faceDown = false,
  });

  final String label;
  final int count;
  final List<PlaceholderCardData>? cards;
  final bool faceDown;

  @override
  Widget build(BuildContext context) {
    final itemCount = cards?.length ?? count;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            '$label ($itemCount)',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: faceDown ? 84 : 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: itemCount,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                if (faceDown || cards == null) {
                  return const TradingCardView(faceDown: true, width: 60);
                }
                return TradingCardView(data: cards![index], width: 80);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.label, this.slotCount = 5});

  final String label;
  final int slotCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        const SizedBox(height: 4),
        Expanded(
          child: Row(
            children: [
              for (var i = 0; i < slotCount; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _EmptySlot(index: i + 1)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.earthBrown.withValues(alpha: 0.3), width: 1.5),
        borderRadius: BorderRadius.circular(8),
        color: AppColors.forestGreen.withValues(alpha: 0.05),
      ),
      child: Center(
        child: Text(
          '$index',
          style: TextStyle(
            color: AppColors.earthBrown.withValues(alpha: 0.4),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _TurnBanner extends StatelessWidget {
  const _TurnBanner({required this.turnNumber, required this.isPlayerTurn});

  final int turnNumber;
  final bool isPlayerTurn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isPlayerTurn ? AppColors.forestGreen : AppColors.earthBrown,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Turn $turnNumber • ${isPlayerTurn ? "Your Turn" : "Opponent's Turn"}',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
