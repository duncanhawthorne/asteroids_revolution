import 'package:flame/game.dart';

import '../game_screen.dart';

mixin GameOverlayManager on Game {
  void cleanDialogs() {
    overlays
      ..remove(GameScreen.startDialogKey)
      ..remove(GameScreen.loseDialogKey)
      ..remove(GameScreen.wonDialogKey)
      ..remove(GameScreen.tutorialDialogKey)
      ..remove(GameScreen.resetDialogKey)
      ..remove(GameScreen.debugDialogKey);
  }

  void toggleOverlay(String overlayKey) {
    if (overlays.activeOverlays.contains(overlayKey)) {
      overlays.remove(overlayKey);
    } else {
      cleanDialogs();
      overlays.add(overlayKey);
    }
  }
}
