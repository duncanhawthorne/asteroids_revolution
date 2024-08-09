import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../audio/audio_controller.dart';
import '../level_selection/levels.dart';
import '../player_progress/player_progress.dart';
import 'dialogs/game_lose_dialog.dart';
import 'dialogs/game_overlays.dart';
import 'dialogs/game_start_dialog.dart';
import 'dialogs/game_won_dialog.dart';
import 'pacman_game.dart';

/// This widget defines the properties of the game screen.
///
/// It mostly sets up the overlays (widgets shown on top of the Flame game) and
/// the gets the [AudioController] from the context and passes it in to the
/// [PacmanGame] class so that it can play audio.

const double statusWidgetHeightFactor = 0.75;
const statusWidgetHeight = 30;

class GameScreen extends StatelessWidget {
  const GameScreen({required this.level, required this.mazeId, super.key});

  final GameLevel level;
  final int mazeId;

  static const String loseDialogKey = 'lose_dialog';
  static const String wonDialogKey = 'won_dialog';
  static const String startDialogKey = 'start_dialog';
  static const String topLeftOverlayKey = 'top_left_overlay';
  static const String topRightOverlayKey = 'top_right_overlay';

  @override
  Widget build(BuildContext context) {
    final audioController = context.read<AudioController>();
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: GameWidget<PacmanGame>(
            key: const Key('play session'),
            game: PacmanGame(
              level: level,
              mazeId: mazeId,
              playerProgress: context.read<PlayerProgress>(),
              audioController: audioController,
              //palette: palette,
            ),
            overlayBuilderMap: {
              topLeftOverlayKey: (BuildContext context, PacmanGame game) {
                return topLeftOverlayWidget(context, game);
              },
              topRightOverlayKey: (BuildContext context, PacmanGame game) {
                return topRightOverlayWidget(context, game);
              },
              loseDialogKey: (BuildContext context, PacmanGame game) {
                return GameLoseDialog(
                  level: level,
                  game: game,
                );
              },
              wonDialogKey: (BuildContext context, PacmanGame game) {
                return GameWonDialog(
                    level: level,
                    levelCompletedInMillis: game.stopwatchMilliSeconds,
                    game: game);
              },
              startDialogKey: (BuildContext context, PacmanGame game) {
                return StartDialog(level: level, game: game);
              }
            },
          ),
        ),
      ),
    );
  }
}
