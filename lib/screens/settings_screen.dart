import 'package:flutter/material.dart';

/// Placeholder settings screen. The switches toggle their own
/// on-screen state but don't persist or affect anything yet.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _musicEnabled = true;
  bool _soundEnabled = true;
  bool _animationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Music'),
            value: _musicEnabled,
            onChanged: (value) => setState(() => _musicEnabled = value),
          ),
          SwitchListTile(
            title: const Text('Sound Effects'),
            value: _soundEnabled,
            onChanged: (value) => setState(() => _soundEnabled = value),
          ),
          SwitchListTile(
            title: const Text('Animations'),
            value: _animationsEnabled,
            onChanged: (value) => setState(() => _animationsEnabled = value),
          ),
          const SizedBox(height: 24),
          const Text(
            'More settings will be added later.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
