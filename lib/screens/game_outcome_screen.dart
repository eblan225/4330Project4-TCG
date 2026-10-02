import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'game_results_screen.dart';

/// A short, celebratory beat between the final attack and match details.
class GameOutcomeScreen extends StatefulWidget {
  const GameOutcomeScreen({
    super.key,
    required this.didWin,
    required this.turnsPlayed,
  });

  final bool didWin;
  final int turnsPlayed;

  @override
  State<GameOutcomeScreen> createState() => _GameOutcomeScreenState();
}

class _GameOutcomeScreenState extends State<GameOutcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..forward();
  late final Animation<double> _scale = CurvedAnimation(
    parent: _controller,
    curve: Curves.elasticOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.didWin
        ? AppColors.goldAccent
        : Colors.blueGrey.shade200;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.darkForestGreen, AppColors.forestGreen],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.didWin ? Icons.emoji_events : Icons.shield_outlined,
                    size: 116,
                    color: color,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.didWin ? 'YOU WON!' : 'DEFEAT',
                    key: const ValueKey('outcome-title'),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.didWin
                        ? 'The wild is yours.'
                        : 'Your animals will fight another day.',
                    style: const TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                  const SizedBox(height: 40),
                  FilledButton.icon(
                    key: const ValueKey('view-results'),
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GameResultsScreen(
                          didWin: widget.didWin,
                          turnsPlayed: widget.turnsPlayed,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.bar_chart),
                    label: const Text('View match details'),
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
