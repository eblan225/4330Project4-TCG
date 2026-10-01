import 'dart:math';

import 'package:flutter/material.dart';

import '../data/deck_library.dart';
import '../game/battlefield_card.dart';
import '../game/game_engine.dart';
import '../models/card.dart';
import '../theme/app_theme.dart';
import '../widgets/section_panel.dart';
import '../widgets/trading_card.dart';
import 'game_results_screen.dart';

/// Plays a full two-player match using [GameEngine]. There's no
/// multiplayer yet, so the opponent is driven by the engine's simple
/// built-in automatic logic — the player only ever controls their
/// own side.
///
/// Reaching this screen requires a valid saved deck (the game lobby
/// checks that), which is used to build the player's side; the
/// opponent gets a random valid deck since it doesn't have a
/// collection of owned cards.
class GameBoardScreen extends StatefulWidget {
  const GameBoardScreen({super.key, this.gameEngine});

  /// Lets tests inject a pre-built engine (e.g. with a fixed seed or
  /// adjusted HP) instead of a fresh random one. Production code
  /// always leaves this null.
  final GameEngine? gameEngine;

  @override
  State<GameBoardScreen> createState() => _GameBoardScreenState();
}

class _GameBoardScreenState extends State<GameBoardScreen> {
  late final GameEngine _engine = widget.gameEngine ?? _buildEngine();

  GameEngine _buildEngine() {
    final random = Random();
    final playerDeck = deckLibrary.decks.firstWhere((deck) => deck.isValid);
    final opponentDeck = GameEngine.randomDeck(random);
    return GameEngine(playerDeck: playerDeck, opponentDeck: opponentDeck, random: random);
  }

  void _afterAction() {
    setState(() {});
    if (_engine.isGameOver) {
      final didWin = _engine.winner == _engine.player;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GameResultsScreen(didWin: didWin)),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _playFromHand(GameCard card) {
    try {
      _engine.playCard(_engine.player, card);
      _afterAction();
    } on GameRuleViolation catch (e) {
      _showError(e.message);
    }
  }

  void _attackWithCard(BattlefieldCard attacker) {
    if (attacker.hasAttackedThisTurn) {
      _showError('${attacker.card.name} has already attacked this turn.');
      return;
    }
    if (_engine.opponent.battlefield.isEmpty) {
      _attackPlayer(attacker);
      return;
    }
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _AttackTargetDialog(
        attacker: attacker,
        opponentBattlefield: _engine.opponent.battlefield,
        onAttackPlayer: () {
          Navigator.of(dialogContext).pop();
          _attackPlayer(attacker);
        },
        onAttackCard: (defender) {
          Navigator.of(dialogContext).pop();
          _attackCard(attacker, defender);
        },
      ),
    );
  }

  void _attackPlayer(BattlefieldCard attacker) {
    try {
      _engine.attackPlayer(_engine.player, attacker);
      _afterAction();
    } on GameRuleViolation catch (e) {
      _showError(e.message);
    }
  }

  void _attackCard(BattlefieldCard attacker, BattlefieldCard defender) {
    try {
      _engine.attackCard(_engine.player, attacker, defender);
      _afterAction();
    } on GameRuleViolation catch (e) {
      _showError(e.message);
    }
  }

  void _endTurn() {
    _engine.endTurn();
    _afterAction();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Board')),
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
                  // --- Opponent area ---
                  _PlayerStatusBar(
                    label: 'Opponent',
                    hp: _engine.opponent.hp,
                    resource: _engine.opponent.resource,
                    resourceCap: _engine.opponent.resourceCap,
                  ),
                  const SizedBox(height: 8),
                  _HandRow(label: 'Opponent Hand', count: _engine.opponent.hand.length),
                  const SizedBox(height: 8),
                  // --- Center battlefield ---
                  Expanded(
                    flex: 3,
                    child: _BattlefieldPanel(
                      opponentField: _engine.opponent.battlefield,
                      playerField: _engine.player.battlefield,
                      turnNumber: _engine.turnNumber,
                      isPlayerTurn: _engine.isPlayerTurn,
                      onTapPlayerCard: _attackWithCard,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // --- Player area ---
                  _HandRow(
                    label: 'Player Hand',
                    cards: _engine.player.hand,
                    canPlay: _engine.isPlayerTurn && !_engine.isGameOver,
                    resource: _engine.player.resource,
                    battlefieldFull:
                        _engine.player.battlefield.length >= GameEngine.maxBattlefieldSize,
                    onTapCard: _playFromHand,
                  ),
                  const SizedBox(height: 8),
                  _PlayerStatusBar(
                    label: 'Player',
                    hp: _engine.player.hp,
                    resource: _engine.player.resource,
                    resourceCap: _engine.player.resourceCap,
                    trailing: ElevatedButton.icon(
                      onPressed:
                          _engine.isPlayerTurn && !_engine.isGameOver ? _endTurn : null,
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
                  itemCount: _engine.log.length,
                  itemBuilder: (context, index) {
                    final entry = _engine.log[_engine.log.length - 1 - index];
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
    required this.resourceCap,
    this.trailing,
  });

  final String label;
  final int hp;
  final int resource;
  final int resourceCap;
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
          _StatPill(
            key: ValueKey('${label.toLowerCase()}-hp'),
            icon: Icons.favorite,
            color: Colors.redAccent,
            text: '$hp',
          ),
          const SizedBox(width: 8),
          _StatPill(
            key: ValueKey('${label.toLowerCase()}-resource'),
            icon: Icons.bolt,
            color: Colors.blueAccent,
            text: '$resource/$resourceCap',
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({super.key, required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

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
          Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
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
    this.canPlay = false,
    this.resource = 0,
    this.battlefieldFull = false,
    this.onTapCard,
  });

  final String label;
  final int count;
  final List<GameCard>? cards;
  final bool canPlay;
  final int resource;
  final bool battlefieldFull;
  final ValueChanged<GameCard>? onTapCard;

  @override
  Widget build(BuildContext context) {
    final cardList = cards;
    final itemCount = cardList?.length ?? count;
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
            height: cardList == null ? 84 : 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: itemCount,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                if (cardList == null) {
                  return const TradingCardView(faceDown: true, width: 60);
                }
                final card = cardList[index];
                final affordable = canPlay && resource >= card.attackCost && !battlefieldFull;
                return GestureDetector(
                  key: ValueKey('hand-$index'),
                  onTap: affordable ? () => onTapCard?.call(card) : null,
                  child: Opacity(
                    opacity: affordable ? 1 : 0.5,
                    child: TradingCardView(data: card, width: 80),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// The shared zone between both hands: a bordered region containing
/// the opponent's field, the turn indicator, and the player's field.
class _BattlefieldPanel extends StatelessWidget {
  const _BattlefieldPanel({
    required this.opponentField,
    required this.playerField,
    required this.turnNumber,
    required this.isPlayerTurn,
    required this.onTapPlayerCard,
  });

  final List<BattlefieldCard> opponentField;
  final List<BattlefieldCard> playerField;
  final int turnNumber;
  final bool isPlayerTurn;
  final ValueChanged<BattlefieldCard> onTapPlayerCard;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.earthBrown.withValues(alpha: 0.06),
        border: Border.all(color: AppColors.earthBrown.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'BATTLEFIELD',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1.5,
              color: AppColors.earthBrown.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: _FieldRow(
              label: 'Opponent Field',
              keyPrefix: 'opponent-field',
              cards: opponentField,
              isOpponent: true,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.center,
            child: _TurnBanner(turnNumber: turnNumber, isPlayerTurn: isPlayerTurn),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: _FieldRow(
              label: 'Player Field',
              keyPrefix: 'player-field',
              cards: playerField,
              isOpponent: false,
              onTapCard: isPlayerTurn ? onTapPlayerCard : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.label,
    required this.keyPrefix,
    required this.cards,
    required this.isOpponent,
    this.onTapCard,
    this.slotCount = 5,
  });

  final String label;
  final String keyPrefix;
  final List<BattlefieldCard> cards;
  final bool isOpponent;
  final ValueChanged<BattlefieldCard>? onTapCard;
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
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < slotCount; i++)
                _BattlefieldCardSlot(
                  key: ValueKey('$keyPrefix-$i'),
                  index: i + 1,
                  battlefieldCard: i < cards.length ? cards[i] : null,
                  isOpponent: isOpponent,
                  onTap: i < cards.length ? onTapCard : null,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One space on the battlefield: either an empty numbered slot, or a
/// card tinted to show who controls it — green for the player, red
/// for the opponent. A player card that's already attacked this turn
/// is dimmed; tapping an attackable one triggers [onTap].
class _BattlefieldCardSlot extends StatelessWidget {
  const _BattlefieldCardSlot({
    super.key,
    required this.index,
    required this.battlefieldCard,
    required this.isOpponent,
    this.onTap,
  });

  final int index;
  final BattlefieldCard? battlefieldCard;
  final bool isOpponent;
  final ValueChanged<BattlefieldCard>? onTap;

  static const double _cardWidth = 88;

  @override
  Widget build(BuildContext context) {
    final card = battlefieldCard;
    if (card == null) {
      return _EmptySlot(index: index, width: _cardWidth);
    }

    final haloColor = isOpponent ? Colors.redAccent : AppColors.forestGreen;
    final canTap = onTap != null && !card.hasAttackedThisTurn;

    return GestureDetector(
      onTap: canTap ? () => onTap!(card) : null,
      child: Opacity(
        opacity: card.hasAttackedThisTurn ? 0.5 : 1,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: haloColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: haloColor.withValues(alpha: 0.6), width: 1.5),
          ),
          child: TradingCardView(
            data: card.card,
            width: _cardWidth,
            hpOverride: card.currentHp,
          ),
        ),
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.index, required this.width});

  final int index;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width * 1.4,
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

/// Lets the player choose what an attacking card targets: the enemy
/// player directly, or one of the enemy's battlefield cards.
class _AttackTargetDialog extends StatelessWidget {
  const _AttackTargetDialog({
    required this.attacker,
    required this.opponentBattlefield,
    required this.onAttackPlayer,
    required this.onAttackCard,
  });

  final BattlefieldCard attacker;
  final List<BattlefieldCard> opponentBattlefield;
  final VoidCallback onAttackPlayer;
  final ValueChanged<BattlefieldCard> onAttackCard;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Attack with ${attacker.card.name}'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const ValueKey('attack-player'),
              leading: const Icon(Icons.person),
              title: const Text('Attack Opponent Directly'),
              onTap: onAttackPlayer,
            ),
            for (var i = 0; i < opponentBattlefield.length; i++)
              ListTile(
                key: ValueKey('attack-enemy-$i'),
                leading: const Icon(Icons.pets),
                title: Text(opponentBattlefield[i].card.name),
                subtitle: Text(
                  '${opponentBattlefield[i].currentHp} HP • '
                  '${opponentBattlefield[i].card.attack} ATK',
                ),
                onTap: () => onAttackCard(opponentBattlefield[i]),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
