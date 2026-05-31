import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/foundation.dart';

import '../../utils/constants.dart';
import '../components/base_component.dart';
import '../components/physics_ball.dart';
import '../effects/remove_effects.dart';
import '../effects/rotate_effect.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'playback.dart';

/// Manages the rotation of the maze based on user drag input.
///
/// This class handles the conversion of drag events into maze rotation,
/// which in turn affects the gravity in the game world.
class DragRotation extends BaseComponent with HasGameReference<PacmanGame> {
  late final PacmanWorld world;

  final Vector2 _eventOffset = Vector2.zero();
  double _canvasRadius = 1.0;
  final Map<int, double?> _fingersLastDragAngle = <int, double?>{};
  bool _cameraRotatable = true;

  final Map<int, bool> _boostFingers = <int, bool>{};

  /// Initiates a sliding reset of the maze angle to its default.
  void resetSlide(VoidCallback callback) {
    assert(game.playState == PlayState.flourish);
    _cameraRotatable = false;
    resetSlideAngle(game.camera.viewfinder, onComplete: callback);
  }

  /// Resets the maze angle to zero instantly and stops any ongoing rotation effects.
  @override
  Future<void> reset() async {
    //stop any rotation effect added to camera
    //note, still leaves flourish variable hot, so fix below
    removeEffects(game.camera.viewfinder);
    setMazeAngle(0, noStartRegularItems: true);
    _cameraRotatable = true;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _canvasRadius = min(game.canvasSize.x, game.canvasSize.y) / 2;
  }

  /// Handles the start of a drag event to begin rotating the maze.
  void onDragStart(DragStartEvent event) {
    if (event.canvasPosition.y > game.canvasSize.y * 3 / 4 &&
        event.canvasPosition.x < game.canvasSize.x * 1 / 2) {
      world.space.ship.accel(true);
      _boostFingers[event.pointerId] = true;
      game.lifecycle.resumeGame();
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

  /// Handles the update of a drag event, calculating the rotation delta and applying it.
  void onDragUpdate(DragUpdateEvent event) {
    if (_boostFingers.containsKey(event.pointerId)) {
      return;
    }
    game.lifecycle.resumeGame();
    _eventOffset.setValues(
      event.canvasStartPosition.x - game.canvasSize.x / 2,
      event.canvasStartPosition.y - game.canvasSize.y / 2,
    );
    final double eventVectorLengthProportion =
        _eventOffset.length / _canvasRadius;
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

  /// Handles the end of a drag event.
  void onDragEnd(DragEndEvent event) {
    if (_boostFingers.containsKey(event.pointerId)) {
      world.space.ship.accel(false);
      return;
    }

    _fingersLastDragAngle.remove(event.pointerId);
  }

  /// Moves the maze angle by the specified delta if rotation is allowed.
  void _moveMazeAngleByDelta(double angleDelta) {
    if (_cameraRotatable &&
        game.isLive &&
        (game.playState == PlayState.gaming ||
            game.playState == PlayState.flourish)) {
      setMazeAngle(
        cameraAngle + (_reversedRotation ? -angleDelta : angleDelta),
      );
    }
  }

  /// The current direction of gravity based on the maze rotation.
  final Vector2 downDirection = Vector2.zero();

  static final Vector2 _reusableVector = Vector2.zero();

  /// Direction of gravity in physics units.
  Vector2 get _downDirectionPhysics => _reusableVector
    ..setFrom(downDirection)
    ..scale(1 / spriteVsPhysicsScale);

  /// Current angle pointing towards "down" in the maze.
  double get downAngle => -atan2(downDirection.x, downDirection.y);

  static const bool _updateGravityOnRotation = false;

  static const bool _reversedRotation = true;

  static const bool _kRotatingCamera = !kDebugMode || true;

  /// Gets the current camera (maze) angle.
  double get cameraAngle =>
      _kRotatingCamera ? game.camera.viewfinder.angle : _debugFakeAngle;

  /// Sets the current camera (maze) angle.
  set cameraAngle(double z) =>
      _kRotatingCamera ? game.camera.viewfinder.angle = z : _debugFakeAngle = z;

  double _debugFakeAngle = 0;

  /// Sets the maze angle and updates gravity and related game state.
  void setMazeAngle(double angle, {bool noStartRegularItems = false}) {
    if (!noStartRegularItems &&
        game.playState != PlayState.flourish &&
        !game.session.isWonOrLost) {
      game.lifecycle.startRegularItems();
    }
    Playback.recordMode ? game.playback.recordAngle(angle) : null; //disabled
    cameraAngle = angle;
    downDirection
      ..setValues(-sin(angle), cos(angle))
      ..scale(game.level.levelSpeed);

    if (_updateGravityOnRotation) {
      /// The gravity is defined in virtual pixels per second squared.
      /// These pixels are in relation to how big the [FixedResolutionViewport] is.

      world.gravity = _downDirectionPhysics;
      world.gravitySign.setValues(
        world.gravity.x.sign,
        world.gravity.y.sign,
      ); //used every frame
    }
  }
}
