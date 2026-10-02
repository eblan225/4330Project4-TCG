import 'dart:async';

import 'package:_4330project4_tcg/main.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_music_player.dart';

void main() {
  testWidgets(
    'Music switch mutes without interrupting or restarting playback',
    (tester) async {
      final player = FakeMusicPlayer();
      await tester.pumpWidget(AnimalTcgApp(musicPlayer: player));
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      final musicSwitch = find.widgetWithText(SwitchListTile, 'Music');
      expect(tester.widget<SwitchListTile>(musicSwitch).value, isTrue);
      await tester.tap(musicSwitch);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(musicSwitch).value, isFalse);
      expect(player.calls, ['mode:ReleaseMode.loop', 'play', 'volume:0.0']);

      // Reopening Settings reflects the app's current mute state.
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(musicSwitch).value, isFalse);

      await tester.tap(musicSwitch);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(musicSwitch).value, isTrue);
      expect(player.calls, [
        'mode:ReleaseMode.loop',
        'play',
        'volume:0.0',
        'volume:1.0',
      ]);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(player.calls.last, 'dispose');
    },
  );

  testWidgets(
    'music loops once across navigation and is disposed with the app',
    (tester) async {
      final player = FakeMusicPlayer();
      await tester.pumpWidget(AnimalTcgApp(musicPlayer: player));

      expect(player.calls, ['mode:ReleaseMode.loop', 'play']);
      expect(
        (player.playedSource as AssetSource).path,
        'audio/Sunny Day and Yarn Ball.f251.mp3',
      );

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pumpWidget(AnimalTcgApp(musicPlayer: player));
      expect(player.calls, ['mode:ReleaseMode.loop', 'play']);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(player.calls, ['mode:ReleaseMode.loop', 'play', 'dispose']);
    },
  );

  testWidgets('closing during initialization does not start music afterward', (
    tester,
  ) async {
    final ready = Completer<void>();
    final player = FakeMusicPlayer()..configuration = ready.future;
    await tester.pumpWidget(AnimalTcgApp(musicPlayer: player));
    await tester.pumpWidget(const SizedBox.shrink());

    ready.complete();
    await tester.pump();
    expect(player.calls, ['mode:ReleaseMode.loop', 'dispose']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('audio startup failure leaves the game usable', (tester) async {
    final ready = Completer<void>();
    final player = FakeMusicPlayer()..configuration = ready.future;
    await tester.pumpWidget(AnimalTcgApp(musicPlayer: player));
    ready.completeError(StateError('No audio device'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Sound Effects'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(player.calls.last, 'dispose');
  });

  testWidgets('blocked browser autoplay retries on the first tap', (
    tester,
  ) async {
    final player = FakeMusicPlayer()..failNextPlay = true;
    await tester.pumpWidget(AnimalTcgApp(musicPlayer: player));
    await tester.pump();

    expect(player.calls, ['mode:ReleaseMode.loop', 'play']);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(player.calls, ['mode:ReleaseMode.loop', 'play', 'play']);
    expect(player.playedSource, isA<AssetSource>());
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
