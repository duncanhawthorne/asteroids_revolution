import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../audio/audio_controller.dart';
import '../../settings/settings.dart';
import '../../style/dialog.dart';
import '../../style/palette.dart';
import '../game_screen.dart';
import '../pacman_game.dart';

const double _statusWidgetHeightFactor = 1.0;
const double _widgetSpacing = 8 * _statusWidgetHeightFactor;
const double _clockSpacing = 8 * _statusWidgetHeightFactor;
const double pacmanIconSize = 21 * _statusWidgetHeightFactor;
const double gIconSize = pacmanIconSize * 4 / 3;
const double circleIconSize = 10 * _statusWidgetHeightFactor;

Widget topOverlayWidget(BuildContext context, PacmanGame game) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: _widgetSpacing,
            children: <Widget>[
              _topLeftWidget(context, game),
              _topRightWidget(context, game)
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _topLeftWidget(BuildContext context, PacmanGame game) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: _widgetSpacing,
    children: <Widget>[
      _mainMenuButtonWidget(context, game),
    ],
  );
}

Widget _topRightWidget(BuildContext context, PacmanGame game) {
  return const Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.end,
    mainAxisSize: MainAxisSize.min,
    spacing: _widgetSpacing,
    children: <Widget>[],
  );
}

Widget _mainMenuButtonWidget(BuildContext context, PacmanGame game) {
  return IconButton(
    onPressed: () {
      game.playbackMode ? null : game.toggleOverlay(GameScreen.startDialogKey);
    },
    icon: const Icon(Icons.menu, color: Palette.textColor),
  );
}

// ignore: unused_element
Widget _clockWidget(PacmanGame game) {
  return GestureDetector(
    onLongPress: () {
      if (detailedAudioLog) {
        game.toggleOverlay(GameScreen.debugDialogKey);
      }
    },
    child: Padding(
      padding: const EdgeInsets.only(left: _clockSpacing, right: _clockSpacing),
      child: StreamBuilder<dynamic>(
        stream: Stream<dynamic>.periodic(const Duration(milliseconds: 100)),
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          return Text(
              (game.stopwatchMilliSeconds / 1000)
                  .toStringAsFixed(1)
                  .padLeft(4, " "),
              style: textStyleBody);
        },
      ),
    ),
  );
}

// ignore: unused_element
Widget _pelletsCounterWidget(PacmanGame game) {
  return ValueListenableBuilder<int>(
    valueListenable: game.world.pellets.pelletsRemainingNotifier,
    builder: (BuildContext context, int value, Widget? child) {
      return Text(game.world.pellets.pelletsRemainingNotifier.value.toString());
    },
  );
}

// ignore: unused_element
Widget _audioOnOffButtonWidget(BuildContext context, PacmanGame game) {
  const Color color = Palette.textColor;
  final SettingsController settingsController =
      context.watch<SettingsController>();
  return ValueListenableBuilder<bool>(
    valueListenable: settingsController.audioOn,
    builder: (BuildContext context, bool audioOn, Widget? child) {
      return IconButton(
        onPressed: () {
          settingsController.toggleAudioOn();
        },
        icon: Icon(audioOn ? Icons.volume_up : Icons.volume_off, color: color),
      );
    },
  );
}
