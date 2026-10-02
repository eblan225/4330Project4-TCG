import 'dart:math';

import 'package:flutter/material.dart';

import '../data/deck_library.dart';
import '../game/battlefield_card.dart';
import '../game/game_engine.dart';
import '../models/card.dart';
import '../models/deck.dart';
import '../theme/app_theme.dart';
import '../widgets/section_panel.dart';
import '../widgets/trading_card.dart';
import 'game_outcome_screen.dart';

enum _OpeningPhase { hidden, gameStart, coinFlip, result }

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
  const GameBoardScreen({super.key, this.gameEngine, this.deck});

  /// Lets tests inject a pre-built engine (e.g. with a fixed seed or
  /// adjusted HP) instead of a fresh random one. Production code
  /// always leaves this null.
  final GameEngine? gameEngine;
  final Deck? deck;

  @override
  State<GameBoardScreen> createState() => _GameBoardScreenState();
}

class _GameBoardScreenState extends State<GameBoardScreen>
    with TickerProviderStateMixin {
  late final GameEngine _engine = widget.gameEngine ?? _buildEngine();
  late final AnimationController _turnController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  late final AnimationController _attackController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1152),
  );
  late final AnimationController _summonController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 672),
  );
  late final AnimationController _openingController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5300),
  );

  BattlefieldCard? _attackingCard;
  BattlefieldCard? _damagedCard;
  int? _floatingDamage;
  bool _opponentTakingDamage = false;
  bool _playerTakingDamage = false;
  bool _isBusy = false;
  BattlefieldCard? _enteringCard;
  bool _navigatingToOutcome = false;
  bool _showOpening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startBoard());
  }

  @override
  void dispose() {
    _turnController.dispose();
    _attackController.dispose();
    _summonController.dispose();
    _openingController.dispose();
    super.dispose();
  }

  GameEngine _buildEngine() {
    final random = Random();
    final playerDeck =
        widget.deck?.copy() ??
        deckLibrary.decks.firstWhere((deck) => deck.isValid);
    final opponentDeck = GameEngine.randomDeck(random);
    return GameEngine(
      playerDeck: playerDeck,
      opponentDeck: opponentDeck,
      random: random,
      autoRunOpponent: false,
    );
  }

  Future<void> _startBoard() async {
    _isBusy = true;
    await _showOpeningSequence();
    if (!mounted) return;
    await _showTurnAnnouncement();
    if (!_engine.isPlayerTurn && !_engine.isGameOver) {
      await _resolveOpponentTurn();
    } else {
      _isBusy = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _showOpeningSequence() async {
    setState(() => _showOpening = true);
    await _openingController.forward(from: 0);
    if (!mounted) return;
    setState(() => _showOpening = false);
  }

  void _afterAction() {
    setState(() {});
    if (_engine.isGameOver && !_navigatingToOutcome) {
      _navigatingToOutcome = true;
      final didWin = _engine.winner == _engine.player;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GameOutcomeScreen(
            didWin: didWin,
            turnsPlayed: _engine.playerTurns,
            cardsPlayed: _engine.cardsPlayed,
            damageDealt: _engine.damageDealt,
            deck: _engine.startingDeck,
          ),
        ),
      );
    }
  }

  Future<void> _showTurnAnnouncement() async {
    if (!mounted) return;
    await _turnController.forward(from: 0);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _playFromHand(GameCard card) async {
    if (_isBusy) return;
    try {
      _isBusy = true;
      _engine.playCard(_engine.player, card);
      setState(() => _enteringCard = _engine.player.battlefield.last);
      await _summonController.forward(from: 0);
      if (mounted) setState(() => _enteringCard = null);
    } on GameRuleViolation catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      } else {
        _isBusy = false;
      }
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

  Future<void> _attackPlayer(BattlefieldCard attacker) async {
    if (_isBusy) return;
    try {
      _isBusy = true;
      setState(() {
        _attackingCard = attacker;
        _opponentTakingDamage = true;
        _floatingDamage = attacker.card.attack;
      });
      await _attackController.forward(from: 0);
      _engine.attackPlayer(_engine.player, attacker);
      if (!mounted) return;
      setState(() {
        _attackingCard = null;
        _opponentTakingDamage = false;
        _floatingDamage = null;
      });
      _afterAction();
    } on GameRuleViolation catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      } else {
        _isBusy = false;
      }
    }
  }

  Future<void> _attackCard(
    BattlefieldCard attacker,
    BattlefieldCard defender,
  ) async {
    if (_isBusy) return;
    try {
      _isBusy = true;
      setState(() {
        _attackingCard = attacker;
        _damagedCard = defender;
        _floatingDamage = attacker.card.attack;
      });
      await _attackController.forward(from: 0);
      _engine.attackCard(_engine.player, attacker, defender);
      if (!mounted) return;
      setState(() {
        _attackingCard = null;
        _damagedCard = null;
        _floatingDamage = null;
      });
      _afterAction();
    } on GameRuleViolation catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      } else {
        _isBusy = false;
      }
    }
  }

  Future<void> _endTurn() async {
    if (_isBusy || _engine.isGameOver) return;
    _isBusy = true;
    _engine.beginOpponentTurn();
    setState(() {});
    await _showTurnAnnouncement();

    await _resolveOpponentTurn();
  }

  Future<void> _resolveOpponentTurn() async {
    while (mounted && !_engine.isPlayerTurn && !_engine.isGameOver) {
      final action = _engine.performNextOpponentAction();
      await _presentOpponentAction(action);
    }

    if (!mounted) return;
    if (_engine.isGameOver) {
      _afterAction();
      return;
    }
    setState(() {});
    await _showTurnAnnouncement();
    _isBusy = false;
    if (mounted) setState(() {});
  }

  /// Presents an action performed by the player across the table. The source
  /// can be the local AI today or a network message from a person later.
  Future<void> _presentOpponentAction(OpponentAction action) async {
    switch (action.type) {
      case OpponentActionType.playedCard:
        setState(() => _enteringCard = _engine.opponent.battlefield.last);
        await _summonController.forward(from: 0);
        if (mounted) setState(() => _enteringCard = null);
      case OpponentActionType.attackedPlayer:
        setState(() {
          _attackingCard = action.attacker;
          _playerTakingDamage = true;
          _floatingDamage = action.damage;
        });
        await _attackController.forward(from: 0);
        if (mounted) {
          setState(() {
            _attackingCard = null;
            _playerTakingDamage = false;
            _floatingDamage = null;
          });
        }
      case OpponentActionType.finishedTurn:
        if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Board')),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: SizedBox(
              width: max(920, constraints.maxWidth),
              height: max(720, constraints.maxHeight),
              child: Stack(
                children: [
                  Padding(
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
                                damageAnimation: _opponentTakingDamage
                                    ? _attackController
                                    : null,
                                damage: _opponentTakingDamage
                                    ? _floatingDamage
                                    : null,
                              ),
                              const SizedBox(height: 8),
                              _HandRow(
                                label: 'Opponent Hand',
                                count: _engine.opponent.hand.length,
                              ),
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
                                  attackAnimation: _attackController,
                                  attackingCard: _attackingCard,
                                  damagedCard: _damagedCard,
                                  damage: _damagedCard == null
                                      ? null
                                      : _floatingDamage,
                                  summonAnimation: _summonController,
                                  enteringCard: _enteringCard,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // --- Player area ---
                              _HandRow(
                                label: 'Player Hand',
                                cards: _engine.player.hand,
                                canPlay:
                                    _engine.isPlayerTurn &&
                                    !_engine.isGameOver &&
                                    !_isBusy,
                                resource: _engine.player.resource,
                                battlefieldFull:
                                    _engine.player.battlefield.length >=
                                    GameEngine.maxBattlefieldSize,
                                onTapCard: _playFromHand,
                              ),
                              const SizedBox(height: 8),
                              _PlayerStatusBar(
                                label: 'Player',
                                hp: _engine.player.hp,
                                resource: _engine.player.resource,
                                resourceCap: _engine.player.resourceCap,
                                damageAnimation: _playerTakingDamage
                                    ? _attackController
                                    : null,
                                damage: _playerTakingDamage
                                    ? _floatingDamage
                                    : null,
                                trailing: ElevatedButton.icon(
                                  onPressed:
                                      _engine.isPlayerTurn &&
                                          !_engine.isGameOver &&
                                          !_isBusy
                                      ? _endTurn
                                      : null,
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
                                final entry =
                                    _engine.log[_engine.log.length - 1 - index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    entry,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IgnorePointer(
                    child: _TurnAnnouncement(
                      animation: _turnController,
                      turnNumber: _engine.turnNumber,
                      isPlayerTurn: _engine.isPlayerTurn,
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: _OpeningAnnouncement(
                        visible: _showOpening,
                        animation: _openingController,
                        playerGoesFirst: _engine.isPlayerTurn,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
    this.damageAnimation,
    this.damage,
  });

  final String label;
  final int hp;
  final int resource;
  final int resourceCap;
  final Widget? trailing;
  final Animation<double>? damageAnimation;
  final int? damage;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.earthBrown.withValues(alpha: 0.3)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
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
          if (damageAnimation != null && damage != null)
            Positioned(
              right: 24,
              top: -40,
              child: AnimatedBuilder(
                animation: damageAnimation!,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, -28 * damageAnimation!.value),
                  child: Opacity(
                    opacity: 1 - damageAnimation!.value,
                    child: child,
                  ),
                ),
                child: _DamageNumber(damage: damage!),
              ),
            ),
        ],
      ),
    );
    if (damageAnimation == null) return content;
    return AnimatedBuilder(
      animation: damageAnimation!,
      child: content,
      builder: (context, child) {
        final shake =
            sin(damageAnimation!.value * pi * 8) *
            (1 - damageAnimation!.value) *
            7;
        return Transform.translate(offset: Offset(shake, 0), child: child);
      },
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
  });

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
          Text(
            text,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
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
                final affordable =
                    canPlay && resource >= card.attackCost && !battlefieldFull;
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
    required this.attackAnimation,
    required this.summonAnimation,
    this.attackingCard,
    this.damagedCard,
    this.damage,
    this.enteringCard,
  });

  final List<BattlefieldCard> opponentField;
  final List<BattlefieldCard> playerField;
  final int turnNumber;
  final bool isPlayerTurn;
  final ValueChanged<BattlefieldCard> onTapPlayerCard;
  final Animation<double> attackAnimation;
  final Animation<double> summonAnimation;
  final BattlefieldCard? attackingCard;
  final BattlefieldCard? damagedCard;
  final int? damage;
  final BattlefieldCard? enteringCard;

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
              attackAnimation: attackAnimation,
              summonAnimation: summonAnimation,
              enteringCard: enteringCard,
              damagedCard: damagedCard,
              damage: damage,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.center,
            child: _TurnBanner(
              turnNumber: turnNumber,
              isPlayerTurn: isPlayerTurn,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: _FieldRow(
              label: 'Player Field',
              keyPrefix: 'player-field',
              cards: playerField,
              isOpponent: false,
              onTapCard: isPlayerTurn ? onTapPlayerCard : null,
              attackAnimation: attackAnimation,
              summonAnimation: summonAnimation,
              enteringCard: enteringCard,
              attackingCard: attackingCard,
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
    required this.attackAnimation,
    required this.summonAnimation,
    this.attackingCard,
    this.damagedCard,
    this.damage,
    this.enteringCard,
  });

  final String label;
  final String keyPrefix;
  final List<BattlefieldCard> cards;
  final bool isOpponent;
  final ValueChanged<BattlefieldCard>? onTapCard;
  final Animation<double> attackAnimation;
  final Animation<double> summonAnimation;
  final BattlefieldCard? attackingCard;
  final BattlefieldCard? damagedCard;
  final int? damage;
  final BattlefieldCard? enteringCard;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Size cards from both available width and height. A fixed
              // 88px card could briefly overflow both battlefield rows on
              // shorter phones, especially while an attack was animating.
              final widthLimit =
                  (constraints.maxWidth / GameEngine.maxBattlefieldSize) - 10;
              final heightLimit = (constraints.maxHeight - 8) / 1.4;
              final cardWidth = min(
                88.0,
                min(widthLimit, heightLimit),
              ).clamp(54.0, 88.0);

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var i = 0; i < GameEngine.maxBattlefieldSize; i++)
                    _BattlefieldCardSlot(
                      key: ValueKey('$keyPrefix-$i'),
                      index: i + 1,
                      width: cardWidth,
                      battlefieldCard: i < cards.length ? cards[i] : null,
                      isOpponent: isOpponent,
                      onTap: i < cards.length ? onTapCard : null,
                      attackAnimation: attackAnimation,
                      summonAnimation: summonAnimation,
                      isAttacking:
                          i < cards.length &&
                          identical(cards[i], attackingCard),
                      isEntering:
                          i < cards.length && identical(cards[i], enteringCard),
                      isTakingDamage:
                          i < cards.length && identical(cards[i], damagedCard),
                      damage:
                          i < cards.length && identical(cards[i], damagedCard)
                          ? damage
                          : null,
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// One space on the battlefield: either an empty numbered slot, or a
/// card framed to show who controls it. Opponent cards stay neutral and
/// only flash red while taking damage. A card that's already attacked
/// is dimmed; tapping an attackable one triggers [onTap].
class _BattlefieldCardSlot extends StatelessWidget {
  const _BattlefieldCardSlot({
    super.key,
    required this.index,
    required this.width,
    required this.battlefieldCard,
    required this.isOpponent,
    this.onTap,
    required this.attackAnimation,
    required this.summonAnimation,
    this.isAttacking = false,
    this.isTakingDamage = false,
    this.isEntering = false,
    this.damage,
  });

  final int index;
  final double width;
  final BattlefieldCard? battlefieldCard;
  final bool isOpponent;
  final ValueChanged<BattlefieldCard>? onTap;
  final Animation<double> attackAnimation;
  final Animation<double> summonAnimation;
  final bool isAttacking;
  final bool isTakingDamage;
  final bool isEntering;
  final int? damage;

  @override
  Widget build(BuildContext context) {
    final card = battlefieldCard;
    if (card == null) {
      return _EmptySlot(index: index, width: width);
    }

    final haloColor = isTakingDamage
        ? Colors.redAccent
        : isOpponent
        ? AppColors.earthBrown
        : AppColors.forestGreen;
    final canTap = onTap != null && !card.hasAttackedThisTurn;

    final cardWidget = GestureDetector(
      onTap: canTap ? () => onTap!(card) : null,
      child: Opacity(
        opacity: card.hasAttackedThisTurn ? 0.5 : 1,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: haloColor.withValues(alpha: isTakingDamage ? 0.16 : 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: haloColor.withValues(alpha: isTakingDamage ? 0.85 : 0.35),
              width: 1.5,
            ),
          ),
          child: TradingCardView(
            data: card.card,
            width: width,
            hpOverride: card.currentHp,
          ),
        ),
      ),
    );
    final presentedCard = isEntering
        ? AnimatedBuilder(
            animation: summonAnimation,
            child: cardWidget,
            builder: (context, child) {
              final t = Curves.easeOutBack.transform(summonAnimation.value);
              return Opacity(
                opacity: summonAnimation.value.clamp(0, 1),
                child: Transform.translate(
                  offset: Offset(0, (isOpponent ? -34 : 34) * (1 - t)),
                  child: Transform.scale(
                    scale: 0.72 + (0.28 * t),
                    child: child,
                  ),
                ),
              );
            },
          )
        : cardWidget;
    if (!isAttacking && !isTakingDamage) return presentedCard;
    return AnimatedBuilder(
      animation: attackAnimation,
      child: presentedCard,
      builder: (context, child) {
        final t = attackAnimation.value.clamp(0.0, 1.0);
        final forward = isOpponent ? 1.0 : -1.0;
        // Decimal phase boundaries can produce values such as
        // 1.0000000000000002 on the last frame. Flutter curves assert that
        // their input is strictly within 0-1, so clamp each normalized phase.
        final windupProgress = (t / 0.24).clamp(0.0, 1.0);
        final strikeProgress = ((t - 0.43) / 0.16).clamp(0.0, 1.0);
        final returnProgress = ((t - 0.59) / 0.41).clamp(0.0, 1.0);
        final jab = switch (t) {
          < 0.24 => -8 * Curves.easeOut.transform(windupProgress),
          < 0.43 => -8,
          < 0.59 => -8 + (52 * Curves.easeIn.transform(strikeProgress)),
          _ => 44 * (1 - Curves.easeOut.transform(returnProgress)),
        };
        final turn = switch (t) {
          < 0.43 => -0.035,
          < 0.59 => -0.035 + (0.13 * strikeProgress),
          _ => 0.095 * (1 - returnProgress),
        };
        final attackLift = isAttacking ? forward * jab : 0.0;
        final shake = isTakingDamage ? sin(t * pi * 10) * (1 - t) * 8 : 0.0;
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Transform.translate(
              offset: Offset(shake, attackLift),
              child: Transform.rotate(
                angle: isAttacking ? turn : 0,
                child: Transform.scale(
                  scale: isAttacking ? 1 + (0.07 * (jab.abs() / 44)) : 1,
                  child: child,
                ),
              ),
            ),
            if (isTakingDamage && damage != null)
              Positioned(
                top: -18 - (26 * attackAnimation.value),
                child: Opacity(
                  opacity: (1 - t).clamp(0.0, 1.0),
                  child: _DamageNumber(damage: damage!),
                ),
              ),
          ],
        );
      },
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
        border: Border.all(
          color: AppColors.earthBrown.withValues(alpha: 0.3),
          width: 1.5,
        ),
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
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _DamageNumber extends StatelessWidget {
  const _DamageNumber({required this.damage});

  final int damage;

  @override
  Widget build(BuildContext context) {
    return Text(
      '-$damage',
      key: const ValueKey('damage-indicator'),
      style: const TextStyle(
        color: Colors.redAccent,
        fontSize: 24,
        fontWeight: FontWeight.w900,
        shadows: [
          Shadow(color: Colors.white, blurRadius: 5),
          Shadow(color: Colors.black54, blurRadius: 8),
        ],
      ),
    );
  }
}

/// Introduces the match before normal turn banners begin. The engine has
/// already chosen the first player randomly; this overlay makes that choice
/// visible instead of dropping the player directly into a turn.
class _OpeningAnnouncement extends StatelessWidget {
  const _OpeningAnnouncement({
    required this.visible,
    required this.animation,
    required this.playerGoesFirst,
  });

  final bool visible;
  final Animation<double> animation;
  final bool playerGoesFirst;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        const gameStartEnd = 1400 / 5300;
        const coinFlipEnd = 3200 / 5300;
        const coinHoldEnd = 3900 / 5300;
        final value = animation.value.clamp(0.0, 1.0);
        final phase = value < gameStartEnd
            ? _OpeningPhase.gameStart
            : value < coinHoldEnd
            ? _OpeningPhase.coinFlip
            : _OpeningPhase.result;
        final coinProgress =
            ((value - gameStartEnd) / (coinFlipEnd - gameStartEnd)).clamp(
              0.0,
              1.0,
            );

        return ColoredBox(
          color: Colors.black.withValues(alpha: 0.68),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: switch (phase) {
                _OpeningPhase.gameStart => _OpeningCard(
                  key: const ValueKey('opening-game-start'),
                  icon: Icons.sports_esports,
                  title: 'GAME START',
                  subtitle: 'Preparing the battlefield…',
                ),
                _OpeningPhase.coinFlip => _FlippingCoin(
                  key: const ValueKey('opening-coin-flip'),
                  progress: coinProgress,
                  landed: value >= coinFlipEnd,
                  playerWon: playerGoesFirst,
                ),
                _OpeningPhase.result => _OpeningCard(
                  key: const ValueKey('opening-result'),
                  icon: playerGoesFirst ? Icons.person : Icons.smart_toy,
                  title: playerGoesFirst
                      ? 'YOU GO FIRST!'
                      : 'OPPONENT GOES FIRST!',
                  subtitle: 'The coin has decided',
                ),
                _OpeningPhase.hidden => const SizedBox.shrink(),
              },
            ),
          ),
        );
      },
    );
  }
}

class _FlippingCoin extends StatelessWidget {
  const _FlippingCoin({
    super.key,
    required this.progress,
    required this.landed,
    required this.playerWon,
  });

  final double progress;
  final bool landed;
  final bool playerWon;

  @override
  Widget build(BuildContext context) {
    final lift = sin(progress * pi) * 70;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.translate(
          key: const ValueKey('rotating-coin'),
          offset: Offset(0, -lift),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(progress * pi * 10),
            child: _CoinFace(
              icon: landed
                  ? playerWon
                        ? Icons.person
                        : Icons.smart_toy
                  : Icons.pets,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          landed
              ? playerWon
                    ? 'YOU WON THE FLIP!'
                    : 'OPPONENT WON THE FLIP!'
              : 'FLIPPING FOR FIRST TURN…',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _CoinFace extends StatelessWidget {
  const _CoinFace({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 118,
      height: 118,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFFFFF3A6), AppColors.goldAccent],
        ),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 22, spreadRadius: 3),
        ],
      ),
      child: Icon(icon, size: 58, color: AppColors.darkForestGreen),
    );
  }
}

class _OpeningCard extends StatelessWidget {
  const _OpeningCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 430),
      padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkForestGreen, AppColors.forestGreen],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.goldAccent, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 28)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.goldAccent, size: 54),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

/// Slides across the whole board, pauses in the center, then clears the view.
class _TurnAnnouncement extends StatelessWidget {
  const _TurnAnnouncement({
    required this.animation,
    required this.turnNumber,
    required this.isPlayerTurn,
  });

  final Animation<double> animation;
  final int turnNumber;
  final bool isPlayerTurn;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final value = animation.value;
        final x = switch (value) {
          < 0.32 => -1.35 + (value / 0.32) * 1.35,
          < 0.68 => 0.0,
          _ => ((value - 0.68) / 0.32) * 1.35,
        };
        final opacity = value < 0.12
            ? value / 0.12
            : value > 0.88
            ? (1 - value) / 0.12
            : 1.0;
        return FractionalTranslation(
          translation: Offset(x, 0),
          child: Opacity(opacity: opacity.clamp(0, 1), child: child),
        );
      },
      child: Center(
        child: Container(
          key: const ValueKey('turn-announcement'),
          padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.darkForestGreen, AppColors.forestGreen],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.goldAccent, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isPlayerTurn ? 'YOUR TURN' : "OPPONENT'S TURN",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              Text(
                'Turn $turnNumber',
                style: const TextStyle(
                  color: AppColors.goldAccent,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
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
