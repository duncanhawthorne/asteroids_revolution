import 'package:flutter/material.dart';

import '../../player_progress/player_progress.dart';
import '../../style/dialog.dart';
import '../../style/palette.dart';
import '../../utils/constants.dart';
import '../game_screen.dart';
import '../pacman_game.dart';

/// This dialog is shown when a level is won.
///
/// It shows what time the level was completed
/// and a comparison vs the leaderboard

class ResetDialog extends StatelessWidget {
  const ResetDialog({
    super.key,
    required this.game,
  });

  final PacmanGame game;

  @override
  Widget build(BuildContext context) {
    return popupDialog(
      children: [
        titleText(text: appTitle),
        bottomRowWidget(children: [
          TextButton(
              style: buttonStyle(),
              onPressed: () {
                game.overlays.remove(GameScreen.resetDialogKey);
              },
              child: Text("Cancel", style: textStyleBody)),
          TextButton(
              style: buttonStyle(borderColor: Palette.warning.color),
              onPressed: () {
                playerProgress.reset();
                game.overlays.remove(GameScreen.resetDialogKey);
              },
              child: Text("Delete all progress across levels",
                  style: textStyleBody))
        ]),
      ],
    );
  }
}
