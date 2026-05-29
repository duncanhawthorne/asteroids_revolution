import 'dart:async';

import 'package:flame/components.dart';

import '../components/base_component.dart';
import '../game_screen.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';

/// Manages the display and cleaning of game dialog overlays.
///
/// This includes start, lose, won, tutorial, reset, and debug dialogs.
class DialogManager extends BaseComponent with HasWorldReference<PacmanWorld> {
  late final PacmanGame game;

  /// Removes all active game dialog overlays.
  void clean() {
    game.overlays
      ..remove(GameScreen.startDialogKey)
      ..remove(GameScreen.loseDialogKey)
      ..remove(GameScreen.wonDialogKey)
      ..remove(GameScreen.tutorialDialogKey)
      ..remove(GameScreen.resetDialogKey)
      ..remove(GameScreen.debugDialogKey);
  }

  /// Toggles the visibility of a specific dialog overlay.
  ///
  /// If the dialog is currently visible, it will be removed. Otherwise,
  /// all other dialogs will be cleaned, and the specified dialog will be added.
  void toggle(String overlayKey) {
    if (game.overlays.activeOverlays.contains(overlayKey)) {
      game.overlays.remove(overlayKey);
    } else {
      clean();
      game.overlays.add(overlayKey);
    }
  }

  @override
  Future<void> onRemove() async {
    clean();
  }
}
