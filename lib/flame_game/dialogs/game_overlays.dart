import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../google_logic.dart';
import '../../settings/settings.dart';
import '../../style/dialog.dart';
import '../../style/palette.dart';
import '../game_screen.dart';
import '../icons/circle_icon.dart';
import '../icons/pacman_icons.dart';
import '../pacman_game.dart';

const double _statusWidgetHeightFactor = 1.0;
const _clockSpacing = 10 * _statusWidgetHeightFactor;
const _widgetSpacing = 15 * _statusWidgetHeightFactor;
const _pacmanSpacing = 2 * _statusWidgetHeightFactor;
const pacmanIconSize = 21 * _statusWidgetHeightFactor;
const gIconSize = pacmanIconSize * 4 / 3;
const circleIconSize = 10 * _statusWidgetHeightFactor;

Widget topOverlayWidget(BuildContext context, PacmanGame game) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: _widgetSpacing,
            children: [
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
    children: [
      _mainMenuButtonWidget(context, game),
      _audioOnOffButtonWidget(context, game),
      game.level.isTutorial
          ? SizedBox.shrink()
          : loginLogoutWidget(context, game),
    ],
  );
}

Widget _topRightWidget(BuildContext context, PacmanGame game) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.end,
    mainAxisSize: MainAxisSize.min,
    spacing: _widgetSpacing,
    children: [
      _pelletsWidget(context, game),
      _pelletsCounterWidget(game),
    ],
  );
}

Widget _mainMenuButtonWidget(BuildContext context, PacmanGame game) {
  return IconButton(
    onPressed: () {
      game.toggleOverlay(GameScreen.startDialogKey);
    },
    icon: const Icon(Icons.menu, color: Palette.textColor),
  );
}

// ignore: unused_element
Widget _livesWidget(BuildContext context, PacmanGame game) {
  return ValueListenableBuilder<int>(
    valueListenable: game.world.pacmans.numberOfDeathsNotifier,
    builder: (BuildContext context, int value, Widget? child) {
      return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: _pacmanSpacing,
          children: List.generate(game.level.maxAllowedDeaths,
              (index) => animatedPacmanIcon(game, index)));
    },
  );
}

Widget _pelletsWidget(BuildContext context, PacmanGame game) {
  return ValueListenableBuilder<int>(
    valueListenable: game.world.pellets.pelletsRemainingNotifier,
    builder: (BuildContext context, int value, Widget? child) {
      return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: _pacmanSpacing,
          children: List.generate(
              min(20, game.world.pellets.pelletsRemainingNotifier.value),
              (index) => circleIcon()));
    },
  );
}

// ignore: unused_element
Widget _clockWidget(PacmanGame game) {
  return Padding(
    padding: const EdgeInsets.only(left: _clockSpacing),
    child: StreamBuilder(
      stream: Stream.periodic(const Duration(milliseconds: 100)),
      builder: (context, snapshot) {
        return Text(
            (game.stopwatchMilliSeconds / 1000)
                .toStringAsFixed(1)
                .padLeft(4, " "),
            style: textStyleBody);
      },
    ),
  );
}

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
  const color = Palette.textColor;
  final settingsController = context.watch<SettingsController>();
  return ValueListenableBuilder<bool>(
    valueListenable: settingsController.audioOn,
    builder: (context, audioOn, child) {
      return IconButton(
        onPressed: () => settingsController.toggleAudioOn(),
        icon: Icon(audioOn ? Icons.volume_up : Icons.volume_off, color: color),
      );
    },
  );
}

Widget loginLogoutWidget(BuildContext context, PacmanGame game) {
  return !gOn
      ? SizedBox.shrink()
      : ValueListenableBuilder<String>(
          valueListenable: g.gUserNotifier,
          builder: (context, audioOn, child) {
            return !g.signedIn
                ? loginButton(context, game)
                : logoutButton(context, game);
          });
}

Widget loginButton(BuildContext context, PacmanGame game) {
  const bool newLoginButtons = false;
  return newLoginButtons
      // ignore: dead_code
      ? g.platformAdaptiveSignInButton(context, game)
      : lockStyleSignInButton(context, game);
}

Widget lockStyleSignInButton(BuildContext context, PacmanGame game) {
  return IconButton(
    icon: const Icon(Icons.lock, color: Palette.textColor),
    onPressed: () {
      g.signInSilentlyThenDirectly();
    },
  );
}

Widget logoutButton(BuildContext context, PacmanGame game) {
  return IconButton(
    icon: g.gUserIcon == G.gUserIconDefault
        ? const Icon(Icons.face_outlined, color: Palette.textColor)
        : CircleAvatar(
            radius: gIconSize / 2, backgroundImage: NetworkImage(g.gUserIcon)),
    onPressed: () {
      g.signOutAndExtractDetails();
    },
  );
}
