import 'dart:async';
import 'dart:math';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';

import '../../audio/sounds.dart';
import '../utils/constants.dart';
import 'components/pellet_layer.dart';
import 'components/ship.dart';
import 'components/space_layer.dart';
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

class PacmanWorld extends Forge2DWorld
    with HasGameReference<PacmanGame>, DragCallbacks {
  PacmanWorld._();

  factory PacmanWorld() {
    assert(_instance == null);
    _instance ??= PacmanWorld._();
    return _instance!;
  }

  ///ensures singleton [PacmanWorld]
  static PacmanWorld? _instance;

  final WrapperNoEvents noEventsWrapper = WrapperNoEvents();
  final PelletWrapper pellets = PelletWrapper();
  final WallWrapper _walls = WallWrapper();
  final List<WrapperNoEvents> wrappers = <WrapperNoEvents>[];

  double get everythingScale =>
      space.ship.radius / neutralShipRadius * 30 / flameGameZoom;

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
    game.audioController.stopSound(SfxType.ghostsScared);
    play(SfxType.endMusic);
  }

  void _cameraAndTimersReset() {
    //stop any rotation effect added to camera
    //note, still leaves flourish variable hot, so fix below
    removeEffects(game.camera.viewfinder);
    setMazeAngle(0);
    _cameraRotatableOnPacmanDeathFlourish = true;
    doingLevelResetFlourish = false;
  }

  void reset({bool firstRun = false}) {
    _cameraAndTimersReset();
    game.audioController.stopSound(SfxType.ghostsScared);

    if (!firstRun) {
      for (final WrapperNoEvents wrapper in wrappers) {
        assert(wrapper.isLoaded, wrapper);
        if (wrapper == _walls) {
          continue; //no need to reset, stops a flash on screen
        }
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

  static const bool enableMovingWalls = kDebugMode && false;
  @override
  Future<void> onLoad() async {
    super.onLoad();
    gravity = gravZero;
    add(noEventsWrapper);
    wrappers.addAll(<WrapperNoEvents>[space]);
    for (final WrapperNoEvents wrapper in wrappers) {
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
      space.ship.accel(true);
      _boostFingers[event.pointerId] = true;
      game.resumeGame();
      _moveMazeAngleByDelta(0); //to start timer
      return;
    }
    if (isiOSWeb) {
      _fingersLastDragAngle[event.pointerId] = null;
    } else {
      _fingersLastDragAngle[event.pointerId] = atan2(
        event.canvasPosition.x - game.canvasSize.x / 2,
        event.canvasPosition.y - game.canvasSize.y / 2,
      );
    }
  }

  final Vector2 _eventOffset = Vector2.zero();
  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);

    if (_boostFingers.containsKey(event.pointerId)) {
      return;
    }

    game.resumeGame();
    _eventOffset.setValues(
      event.canvasStartPosition.x - game.canvasSize.x / 2,
      event.canvasStartPosition.y - game.canvasSize.y / 2,
    );
    final double eventVectorLengthProportion =
        _eventOffset.length / (min(game.canvasSize.x, game.canvasSize.y) / 2);
    final double fingerCurrentDragAngle = atan2(_eventOffset.x, _eventOffset.y);
    if (_fingersLastDragAngle.containsKey(event.pointerId)) {
      if (_fingersLastDragAngle[event.pointerId] != null) {
        final double angleDelta = smallAngle(
          fingerCurrentDragAngle - _fingersLastDragAngle[event.pointerId]!,
        );
        const double maxSpinMultiplierRadius = 0.75;
        final double spinMultiplier =
            4 *
            game.level.spinSpeedFactor *
            min(1, eventVectorLengthProportion / maxSpinMultiplierRadius);

        _moveMazeAngleByDelta(angleDelta * spinMultiplier);
      }
      _fingersLastDragAngle[event.pointerId] = fingerCurrentDragAngle;
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);

    if (_boostFingers.containsKey(event.pointerId)) {
      space.ship.accel(false);
      return;
    }

    if (_fingersLastDragAngle.containsKey(event.pointerId)) {
      _fingersLastDragAngle.remove(event.pointerId);
    }
  }

  void _moveMazeAngleByDelta(double angleDelta) {
    if (_cameraRotatableOnPacmanDeathFlourish &&
        game.isLive &&
        game.openingScreenCleared &&
        !game.playbackMode) {
      setMazeAngle(cameraAngle - angleDelta);
      if (!doingLevelResetFlourish && !game.isWonOrLost) {
        game.startRegularItems();
      }
    }
  }

  final Vector2 downDirection = Vector2.zero();
  final Vector2 gravZero = Vector2.zero();

  static const bool _updateGravityOnRotation = false;
  final Vector2 gravitySign = Vector2(0, 0);

  static bool _kRotatingCamera = true;
  double get cameraAngle =>
      _kRotatingCamera ? game.camera.viewfinder.angle : _debugFakeAngle;
  set cameraAngle(double z) =>
      _kRotatingCamera ? game.camera.viewfinder.angle = z : _debugFakeAngle = z;

  double _debugFakeAngle = 0;

  void setMazeAngle(double angle) {
    game.recordAngle(angle);
    cameraAngle = angle;
    downDirection
      ..setValues(-sin(angle), cos(angle))
      ..scale(game.level.levelSpeed);

    if (_updateGravityOnRotation) {
      gravity = downDirection;
      gravitySign.setValues(gravity.x.sign, gravity.y.sign); //used every frame
    }
  }
}
