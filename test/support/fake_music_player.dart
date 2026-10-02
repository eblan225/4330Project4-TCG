import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';

/// Keeps widget tests independent of native audio devices and platform plugins.
class FakeMusicPlayer extends Fake implements AudioPlayer {
  final calls = <String>[];
  Source? playedSource;
  Future<void>? configuration;

  @override
  Future<void> setVolume(double volume) async {
    calls.add('volume:$volume');
  }

  @override
  Future<void> setReleaseMode(ReleaseMode mode) async {
    calls.add('mode:$mode');
    await configuration;
  }

  @override
  Future<void> play(
    Source source, {
    double? volume,
    double? balance,
    AudioContext? ctx,
    Duration? position,
    PlayerMode? mode,
  }) async {
    calls.add('play');
    playedSource = source;
  }

  @override
  Future<void> dispose() async {
    calls.add('dispose');
  }
}
