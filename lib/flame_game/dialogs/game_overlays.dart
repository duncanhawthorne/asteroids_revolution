import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../audio/audio_controller.dart';
import '../../google/google.dart';
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

/// Top-level status widget displayed over the game.
Widget topOverlayWidget(BuildContext context, PacmanGame game) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: ValueListenableBuilder<bool>(
        valueListenable: g.loggingInProcess,
        builder: (BuildContext context, bool value, Widget? child) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: _widgetSpacing,
                children: <Widget>[
                  _topLeftWidget(context, game),
                  _topRightWidget(context, game),
                ],
              ),
              Visibility(
                visible: g.loggingInProcess.value,
                maintainState: false,
                child: g.gWidget,
              ),
            ],
          );
        },
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
    children: <Widget>[_mainMenuButtonWidget(context, game)],
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
      game.overlays.activeOverlays.contains(GameScreen.beginDialogKey)
          ? null
          : game.dialogs.toggle(GameScreen.startDialogKey);
    },
    icon: const Icon(Icons.menu, color: Palette.textColor),
  );
}

// ignore: unused_element
Widget _clockWidget(PacmanGame game) {
  return GestureDetector(
    onLongPress: () {
      if (detailedAudioLog) {
        game.dialogs.toggle(GameScreen.debugDialogKey);
      }
    },
    child: Padding(
      padding: const EdgeInsets.only(left: _clockSpacing, right: _clockSpacing),
      child: StreamBuilder<int>(
        stream: Stream<int>.periodic(
          const Duration(milliseconds: 100),
          (int i) => i,
        ),
        builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
          return Text(
            (game.session.stopwatchMilliSeconds / 1000)
                .toStringAsFixed(1)
                .padLeft(4, " "),
            style: textStyleBody,
          );
        },
      ),
    ),
  );
}

// ignore: unused_element
Widget _audioOnOffButtonWidget(BuildContext context, PacmanGame game) {
  const Color color = Palette.textColor;
  final SettingsController settingsController = context
      .watch<SettingsController>();
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
