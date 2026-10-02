import 'package:flutter/widgets.dart';

/// Shares the app's music preference with every route for this session.
class MusicSettingsScope extends InheritedWidget {
  const MusicSettingsScope({
    super.key,
    required this.musicEnabled,
    required this.onMusicEnabledChanged,
    required super.child,
  });

  final bool musicEnabled;
  final ValueChanged<bool> onMusicEnabledChanged;

  static MusicSettingsScope of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<MusicSettingsScope>();
    assert(scope != null, 'MusicSettingsScope must be above the app routes.');
    return scope!;
  }

  @override
  bool updateShouldNotify(MusicSettingsScope oldWidget) =>
      musicEnabled != oldWidget.musicEnabled;
}
