import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/foundation.dart';

import '../../utils/constants.dart';
import '../components/physics_ball.dart';
import '../effects/remove_effects.dart';
import '../effects/rotate_effect.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';

class WorldDragRotationManager {
  WorldDragRotationManager({required this.game, required this.world});

  PacmanGame game;
  PacmanWorld world;

  final Vector2 _eventOffset = Vector2.zero();
  double canvasRadius = 1.0;
  final Map<int, double?> _fingersLastDragAngle = <int, double?>{};
  bool _cameraRotatableOnPacmanDeathFlourish = true;
  final Map<int, bool> _boostFingers = <int, bool>{};

  void clear() {
    _fingersLastDragAngle.clear();
    _boostFingers.clear();
  }

  void flourishReset(Function() callback) {
    _cameraRotatableOnPacmanDeathFlourish = false;
    resetSlideAngle(game.camera.viewfinder, onComplete: callback);
  }

  void reset() {
    //stop any rotation effect added to camera
    //note, still leaves flourish variable hot, so fix below
    removeEffects(game.camera.viewfinder);
    setMazeAngle(0);
    _cameraRotatableOnPacmanDeathFlourish = true;
  }

  void onDragStart(DragStartEvent event) {
    if (event.canvasPosition.y > game.canvasSize.y * 3 / 4 &&
        event.canvasPosition.x < game.canvasSize.x * 1 / 2) {
      world.space.ship.accel(true);
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

  void onDragUpdate(DragUpdateEvent event) {
    if (_boostFingers.containsKey(event.pointerId)) {
      return;
    }

    game.resumeGame();
    _eventOffset.setValues(
      event.canvasStartPosition.x - game.canvasSize.x / 2,
      event.canvasStartPosition.y - game.canvasSize.y / 2,
    );
    final double eventVectorLengthProportion =
        _eventOffset.length / canvasRadius;
    final double fingerCurrentDragAngle = atan2(_eventOffset.x, _eventOffset.y);
    // Need separate contains and null check due to isiOSWeb approach in onDragStart
    if (_fingersLastDragAngle.containsKey(event.pointerId)) {
      final double? lastAngle = _fingersLastDragAngle[event.pointerId];
      if (lastAngle != null) {
        final double angleDelta = smallAngle(
          fingerCurrentDragAngle - lastAngle,
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

  void onDragEnd(DragEndEvent event) {
    if (_boostFingers.containsKey(event.pointerId)) {
      world.space.ship.accel(false);
      return;
    }

    _fingersLastDragAngle.remove(event.pointerId);
  }

  void _moveMazeAngleByDelta(double angleDelta) {
    if (_cameraRotatableOnPacmanDeathFlourish &&
        game.isLive &&
        game.openingScreenCleared &&
        !game.playbackMode) {
      setMazeAngle(cameraAngle - angleDelta);
      if (!game.isWonOrLost) {
        game.startRegularItems();
      }
    }
  }

  final Vector2 downDirection = Vector2.zero();

  static const bool _updateGravityOnRotation = false;

  static const bool _kRotatingCamera = !kDebugMode || true;

  double get cameraAngle =>
      _kRotatingCamera ? game.camera.viewfinder.angle : _debugFakeAngle;

  set cameraAngle(double z) =>
      _kRotatingCamera ? game.camera.viewfinder.angle = z : _debugFakeAngle = z;

  double _debugFakeAngle = 0;

  void setMazeAngle(double angle) {
    cameraAngle = angle;
    downDirection
      ..setValues(-sin(angle), cos(angle))
      ..scale(game.level.levelSpeed / spriteVsPhysicsScale);

    if (_updateGravityOnRotation) {
      /// The gravity is defined in virtual pixels per second squared.
      /// These pixels are in relation to how big the [FixedResolutionViewport] is.

      world.gravity = downDirection;
      world.gravitySign.setValues(
        world.gravity.x.sign,
        world.gravity.y.sign,
      ); //used every frame
    }
  }
}
