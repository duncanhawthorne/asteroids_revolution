import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../level_selection/levels.dart';
import '../../router.dart';
import '../../style/dialog.dart';
import '../../style/palette.dart';
import '../../utils/constants.dart';
import '../game_screen.dart';
import '../maze.dart';
import '../pacman_game.dart';

/// This dialog is shown before starting the game.

class StartDialog extends StatelessWidget {
  const StartDialog({
    super.key,
    required this.level,
    required this.game,
  });

  /// The properties of the level that was just finished.
  final GameLevel level;

  final PacmanGame game;

  @override
  Widget build(BuildContext context) {
    return popupDialog(
      children: [
        titleWidget(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
            child: Transform.rotate(
              angle: -0.1,
              child: Text(appTitle,
                  style: textStyleHeading, textAlign: TextAlign.center),
            ),
          ),
        ),
        levelSelector(context, game),
        mazeSelector(context, game),
        bottomRowWidget(
          children: game.levelStarted
              ? [
                  TextButton(
                      style: buttonStyle(borderColor: Palette.redWarning),
                      onPressed: () {
                        game.overlays.remove(GameScreen.startDialogKey);
                        game.resetAndStart();
                      },
                      child: Text('Reset', style: textStyleBody)),
                  TextButton(
                      style: buttonStyle(),
                      onPressed: () {
                        game.overlays.remove(GameScreen.startDialogKey);
                      },
                      child: Text('Resume', style: textStyleBody))
                ]
              : [
                  TextButton(
                      style: buttonStyle(),
                      onPressed: () {
                        game.overlays.remove(GameScreen.startDialogKey);
                        game.start();
                      },
                      child: Text('Play', style: textStyleBody)),
                ],
        )
      ],
    );
  }
}

const double width = 40; //70;
const bool hideGrid = true;
Widget levelSelector(BuildContext context, PacmanGame game) {
  int maxLevelToShowCache = maxLevelToShow(game);
  bool showText = maxLevelToShowCache <= 2;
  return maxLevelToShowCache == 1
      ? const SizedBox.shrink()
      : bodyWidget(
          child: Column(
            children: [
              hideGrid
                  ? const SizedBox.shrink()
                  : SizedBox(
                      //alternative implementation
                      width: width * 5,
                      height: width * 2,
                      child: GridView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          cacheExtent: 10000,
                          reverse: false,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 2 * 5,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                          ),
                          itemBuilder: (BuildContext context, int index) {
                            return levelButtonSingle(context, game, index);
                          }),
                    ),
              Row(
                children: [
                  !showText
                      ? const SizedBox.shrink()
                      : Text('Level:', style: textStyleBody),
                  !showText
                      ? const SizedBox.shrink()
                      : const SizedBox(width: 10),
                  ...List.generate(min(5, maxLevelToShowCache),
                      (index) => levelButtonSingle(context, game, index)),
                ],
              ),
              maxLevelToShowCache <= 5
                  ? const SizedBox.shrink()
                  : Row(
                      children: [
                        ...List.generate(
                            maxLevelToShowCache - 5,
                            (index) =>
                                levelButtonSingle(context, game, 5 + index)),
                      ],
                    )
            ],
          ),
        );
}

Widget levelButtonSingle(BuildContext context, PacmanGame game, int index) {
  return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
      child: TextButton(
          style: game.level.number == index + 1
              ? buttonStyle(small: true)
              : buttonStyle(small: true, borderColor: Palette.transp),
          onPressed: () {
            context.go(
                '/?$levelUrlKey=${index + 1}&$mazeUrlKey=${mazeNames[maze.mazeId]}');
          },
          child: Text('${index + 1}',
              style: game.world.playerProgress.levels.containsKey(index + 1)
                  ? textStyleBody
                  : textStyleBodyDull)));
}

Widget mazeSelector(BuildContext context, PacmanGame game) {
  int maxLevelToShowCache = maxLevelToShow(game);
  bool showText = maxLevelToShowCache <= 2;
  return maxLevelToShowCache == 1
      ? const SizedBox.shrink()
      : bodyWidget(
          child: Column(
            children: [
              Row(
                children: [
                  !showText
                      ? const SizedBox.shrink()
                      : Text('Maze:', style: textStyleBody),
                  !showText
                      ? const SizedBox.shrink()
                      : const SizedBox(width: 10),
                  ...List.generate(
                      3, (index) => mazeButtonSingle(context, game, index)),
                ],
              ),
            ],
          ),
        );
}

Widget mazeButtonSingle(BuildContext context, PacmanGame game, int index) {
  return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
      child: TextButton(
          style: maze.mazeId == index
              ? buttonStyle(small: true)
              : buttonStyle(small: true, borderColor: Palette.transp),
          onPressed: () {
            if (index != maze.mazeId) {
              context.go(
                  '/?$levelUrlKey=${game.level.number}&$mazeUrlKey=${mazeNames[index]}');
            }
          },
          child: Text(mazeNames[index] ?? "X", style: textStyleBody)));
}

int maxLevelToShow(PacmanGame game) {
  return [
    game.level.number,
    isTutorialMaze(maze.mazeId) || maze.mazeId == tutorialMazeId + 1
        ? tutorialLevelNum - 1
        : defaultLevelNum + 1,
    game.world.playerProgress.maxLevelCompleted + 1
  ].reduce(max).clamp(0, maxLevel());
}
