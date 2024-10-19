import 'dart:async';
import 'dart:math';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';

import '../../audio/sounds.dart';
import 'components/pellet_layer.dart';
import 'components/ship.dart';
import 'components/space_layer.dart';
import 'components/tutorial_layer.dart';
import 'components/wall_layer.dart';
import 'components/wrapper_no_events.dart';
import 'effects/remove_effects.dart';
import 'effects/rotate_effect.dart';
import 'pacman_game.dart';

/// The world is where you place all the components that should live inside of
/// the game, like the player, enemies, obstacles and points for example.
/// The world can be much bigger than what the camera is currently looking at,
/// but in this game all components that go outside of the size of the viewport
/// are removed, since the player can't interact with those anymore.
///
/// The [PacmanWorld] has two mixins added to it:
///  - The [DragCallbacks] that makes it possible to react to taps and drags
///  (or mouse clicks) on the world.
///  - The [HasGameReference] that gives the world access to a variable called
///  `game`, which is a reference to the game class that the world is attached
///  to.

final bool _iOSWeb = defaultTargetPlatform == TargetPlatform.iOS && kIsWeb;

class PacmanWorld extends Forge2DWorld
    with HasGameReference<PacmanGame>, DragCallbacks {
  final WrapperNoEvents noEventsWrapper = WrapperNoEvents();
  final PelletWrapper pellets = PelletWrapper();
  final WallWrapper walls = WallWrapper();
  final TutorialWrapper _tutorial = TutorialWrapper();
  final List<WrapperNoEvents> wrappers = <WrapperNoEvents>[];

  bool get gameWonOrLost =>
      pellets.pelletsRemainingNotifier.value <= 0 ||
      space.numberOfDeathsNotifier.value >= game.level.maxAllowedDeaths;

  double get everythingScale =>
      space.ship.scaledRadius / neutralShipRadius * 30 / flameGameZoom;

  final Map<int, double?> _fingersLastDragAngle = <int, double?>{};

  bool doingLevelResetFlourish = false;
  bool _cameraRotatableOnPacmanDeathFlourish = true;

  /// The gravity is defined in virtual pixels per second squared.
  /// These pixels are in relation to how big the [FixedResolutionViewport] is.

  void play(SfxType type) {
    const bool soundOn = false; //!(windows && !kIsWeb);
    // ignore: dead_code
    if (soundOn) {
      game.audioController.playSfx(type);
    }
  }

  void resetAfterGameWin() {
    game.audioController.stopSfx(SfxType.ghostsScared);
    play(SfxType.endMusic);
  }

  void _cameraAndTimersReset() {
    //stop any rotation effect added to camera
    //note, still leaves flourish variable hot, so fix below
    removeEffects(game.camera.viewfinder);
    _setMazeAngle(0);
    _cameraRotatableOnPacmanDeathFlourish = true;
    doingLevelResetFlourish = false;
  }

  void reset({bool firstRun = false}) {
    _cameraAndTimersReset();
    game.audioController.stopSfx(SfxType.ghostsScared);

    if (!firstRun) {
      for (final WrapperNoEvents wrapper in wrappers) {
        assert(wrapper.isLoaded);
        wrapper.reset();
      }
    }
  }

  final SpaceWrapper space = SpaceWrapper();

  void start() {
    play(SfxType.startMusic);
    for (final WrapperNoEvents wrapper in wrappers) {
      wrapper.start();
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(noEventsWrapper);
    wrappers.addAll(<WrapperNoEvents>[space]); //_blocking, _tutorial
    for (WrapperNoEvents wrapper in wrappers) {
      noEventsWrapper.add(wrapper);
    }
    reset(firstRun: true);
  }

  final Map<int, bool> _boostFingers = <int, bool>{};

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (event.canvasPosition.y > game.canvasSize.y * 3 / 4 &&
        event.canvasPosition.x < game.canvasSize.x * 1 / 2) {
      space.ship.accelerating = true;
      _boostFingers[event.pointerId] = true;
      game.resumeGame();
      _moveMazeAngleByDelta(0); //to start timer
      return;
    }

    if (_iOSWeb) {
      _fingersLastDragAngle[event.pointerId] = null;
    } else {
      _fingersLastDragAngle[event.pointerId] = atan2(
          event.canvasPosition.x - game.canvasSize.x / 2,
          event.canvasPosition.y - game.canvasSize.y / 2);
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);

    if (_boostFingers.containsKey(event.pointerId)) {
      return;
    }

    game.resumeGame();
    final double eventVectorLengthProportion =
        (event.canvasStartPosition - game.canvasSize / 2).length /
            (min(game.canvasSize.x, game.canvasSize.y) / 2);
    final double fingerCurrentDragAngle = atan2(
        event.canvasStartPosition.x - game.canvasSize.x / 2,
        event.canvasStartPosition.y - game.canvasSize.y / 2);
    if (_fingersLastDragAngle.containsKey(event.pointerId)) {
      if (_fingersLastDragAngle[event.pointerId] != null) {
        final double angleDelta = smallAngle(
            fingerCurrentDragAngle - _fingersLastDragAngle[event.pointerId]!);
        const double maxSpinMultiplierRadius = 0.75;
        final num spinMultiplier =
            4 * min(1, eventVectorLengthProportion / maxSpinMultiplierRadius);

        _tutorial.hide();
        _moveMazeAngleByDelta(angleDelta * spinMultiplier);
      }
      _fingersLastDragAngle[event.pointerId] = fingerCurrentDragAngle;
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);

    if (_boostFingers.containsKey(event.pointerId)) {
      space.ship.accelerating = false;
      return;
    }

    if (_fingersLastDragAngle.containsKey(event.pointerId)) {
      _fingersLastDragAngle.remove(event.pointerId);
    }
  }

  void _moveMazeAngleByDelta(double angleDelta) {
    if (_cameraRotatableOnPacmanDeathFlourish && game.isGameLive) {
      _setMazeAngle(game.camera.viewfinder.angle - angleDelta);

      if (!doingLevelResetFlourish) {
        if (!gameWonOrLost) {
          game.stopwatch.resume();
        }
      }
    }
  }

  late final double _levelSpeed =
      0.5 * 0.5 * pow(1.1, game.level.number).toDouble();
  final Vector2 direction = Vector2.zero();

  final Vector2 _tmpGravity = Vector2.zero();
  late final double _gravityScale = 50 * _levelSpeed;
  void _setMazeAngle(double angle) {
    //using tmpGravity to avoid creating a new Vector2 on each update / frame
    //could instead directly do gravity = Vector2(calc, calc);
    _tmpGravity
      ..x = -sin(angle) * _gravityScale
      ..y = cos(angle) * _gravityScale;
    direction.setFrom(_tmpGravity);
    //gravity = _tmpGravity;
    game.camera.viewfinder.angle = angle;
  }
}
