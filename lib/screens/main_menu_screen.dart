import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'collection_screen.dart';
import 'deck_builder_screen.dart';
import 'game_lobby_screen.dart';
import 'settings_screen.dart';

/// The first screen the player sees. Gives access to every other
/// part of the app through simple navigation buttons.
class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.darkForestGreen, AppColors.forestGreen],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pets, size: 96, color: AppColors.goldAccent),
                  const SizedBox(height: 16),
                  Text(
                    'ANIMAL TCG',
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge
                        ?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'A wild trading card game',
                    style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 48),
                  _MenuButton(
                    label: 'Play',
                    icon: Icons.play_arrow,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GameLobbyScreen()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _MenuButton(
                    label: 'Collection',
                    icon: Icons.collections_bookmark,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CollectionScreen()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _MenuButton(
                    label: 'Deck Builder',
                    icon: Icons.style,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DeckBuilderScreen()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _MenuButton(
                    label: 'Settings',
                    icon: Icons.settings,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
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

/// A fixed-width button so every menu entry lines up the same way.
class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
