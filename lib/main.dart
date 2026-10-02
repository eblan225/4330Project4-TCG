import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'audio/music_settings_scope.dart';
import 'screens/main_menu_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const AnimalTcgApp());
}

class AnimalTcgApp extends StatefulWidget {
  const AnimalTcgApp({super.key, this.musicPlayer});

  /// The app owns and disposes this player, including an injected player.
  final AudioPlayer? musicPlayer;

  @override
  State<AnimalTcgApp> createState() => _AnimalTcgAppState();
}

class _AnimalTcgAppState extends State<AnimalTcgApp> {
  late final AudioPlayer _musicPlayer;
  bool _musicEnabled = true;

  @override
  void initState() {
    super.initState();
    _musicPlayer = widget.musicPlayer ?? AudioPlayer();
    // Music belongs to the app, so navigation never restarts the track.
    unawaited(_startMusic());
  }

  Future<void> _startMusic() async {
    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      if (!mounted) return;
      // AssetSource adds the assets/ prefix automatically.
      await _musicPlayer.play(
        AssetSource('audio/Sunny Day and Yarn Ball.f251.mp3'),
      );
    } catch (error) {
      // An audio device or asset failure should not prevent playing the game.
      debugPrint('Unable to start background music: $error');
    }
  }

  Future<void> _disposeMusic() async {
    try {
      // dispose also stops playback and releases the native audio resources.
      await _musicPlayer.dispose();
    } catch (error) {
      debugPrint('Unable to dispose background music: $error');
    }
  }

  void _setMusicEnabled(bool enabled) {
    if (_musicEnabled == enabled) return;
    setState(() => _musicEnabled = enabled);
    unawaited(_updateMusicVolume(enabled));
  }

  Future<void> _updateMusicVolume(bool enabled) async {
    try {
      // Change only volume: the looping track keeps advancing while muted.
      await _musicPlayer.setVolume(enabled ? 1.0 : 0.0);
    } catch (error) {
      debugPrint('Unable to change background music volume: $error');
    }
  }

  @override
  void dispose() {
    unawaited(_disposeMusic());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MusicSettingsScope(
      musicEnabled: _musicEnabled,
      onMusicEnabledChanged: _setMusicEnabled,
      child: MaterialApp(
        title: 'Animal TCG',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const MainMenuScreen(),
      ),
    );
  }
}
