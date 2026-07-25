import 'dart:async';

import '../app_lifecycle/app_lifecycle.dart';
import '../settings/settings.dart';
import 'sounds.dart';

/// Stubbed initialisation - no-op.
Future<void> firstInitialiseSoLoud() async {}

final bool detailedAudioLog = false;

/// Stub implementation of [AudioController].
class AudioController {
  AudioController._();

  factory AudioController() {
    _instance ??= AudioController._();
    return _instance!;
  }

  static AudioController? _instance;

  // Public Methods (No-Ops)
  Future<void> playSfx(
    SfxType type, {
    bool forceUseAudioPlayersOnce = false,
  }) async {}

  Future<void> stopAllSounds() async {}

  Future<void> workaroundiOSSafariAudioOnUserInteraction() async {}

  void attachDependencies(
    AppLifecycleStateNotifier lifecycleNotifier,
    SettingsController settingsController,
  ) {}

  Future<void> dispose() async {}
}
