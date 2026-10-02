import 'package:flutter/material.dart';

import '../game/battlefield_card.dart';

class BattleFeedback extends InheritedWidget {
  const BattleFeedback({
    super.key,
    required super.child,
    this.attacker,
    this.target,
    this.targetPlayer,
  });
  final BattlefieldCard? attacker;
  final BattlefieldCard? target;
  final String? targetPlayer;
  static BattleFeedback? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BattleFeedback>();
  @override
  bool updateShouldNotify(BattleFeedback oldWidget) =>
      attacker != oldWidget.attacker ||
      target != oldWidget.target ||
      targetPlayer != oldWidget.targetPlayer;
}

/// Retains the previous HP so changes count smoothly to the new value.
class AnimatedHp extends StatelessWidget {
  const AnimatedHp({super.key, required this.hp});
  final int hp;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: hp.toDouble(), end: hp.toDouble()),
    duration: const Duration(milliseconds: 500),
    builder: (context, value, child) => Semantics(
      label: 'Health: $hp',
      child: ExcludeSemantics(
        child: Text(
          '${value.round()} HP',
          style: const TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  );
}
