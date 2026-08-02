import 'dart:async';

import '../app_lifecycle/app_lifecycle.dart';
import '../settings/settings.dart';

/// Stub implementation of [AudioController].
class AudioController {
  // Public Methods (No-Ops)

  Future<void> stopAllSounds() async {}

  void attachDependencies(
    AppLifecycleStateNotifier lifecycleNotifier,
    SettingsController settingsController,
  ) {}

  Future<void> dispose() async {}
}
