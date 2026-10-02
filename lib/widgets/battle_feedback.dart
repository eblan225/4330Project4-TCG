import 'package:flutter/material.dart';

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
