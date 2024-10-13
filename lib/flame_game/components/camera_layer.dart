import 'dart:async' as async;
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../maze.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'ship.dart';
import 'space_dot.dart';
import 'wrapper_no_events.dart';

bool _kPanTrackingCamera = true;
bool _kZoomTrackingCamera = true;

class CameraWrapper extends WrapperNoEvents
    with HasWorldReference<PacmanWorld>, HasGameReference<PacmanGame> {
  Iterable<SpaceDot> get spaceDots =>
      world.walls.children.whereType<SpaceDot>();

  @override
  void reset() {
    _zoomTimer?.cancel();
    startZoomTimer();

    if (!kDebugMode || _kZoomTrackingCamera) {
      game.camera.viewfinder.zoom = _optimalZoom;
    }
  }

  double get _optimalZoom => 30 / world.everythingScale;

  get overZoomError =>
      !_kZoomTrackingCamera ? 1 : game.camera.viewfinder.zoom / _optimalZoom;

  Ship get ship => world.asteroidsWrapper.ship;

  get tooZoomedOut => overZoomError < 0.75;

  async.Timer? _zoomTimer;
  void startZoomTimer() {
    _zoomTimer =
        async.Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (!kDebugMode || _kZoomTrackingCamera) {
        if (game.camera.viewfinder.zoom < _optimalZoom * 0.95) {
          //zoom in
          game.camera.viewfinder.zoom *= pow(1 / overZoomError, 1 / 300);
        }
        if (game.camera.viewfinder.zoom > _optimalZoom * 1.05) {
          //zoom out
          game.camera.viewfinder.zoom *= pow(1 / overZoomError, 1 / 300);
        }
      }
    });
  }

  int kOrderOfMagnitudeOrder = 5;
  List<SpaceDot> dots = [];
  double logOrder(num x) => log(x) / log(kOrderOfMagnitudeOrder);
  int get _zoomOrderOfMagnitude =>
      logOrder(world.everythingScale * 2).floor(); //FIXME should be off zoom
  void fixSpaceDots() {
    double scale =
        maze.blockWidth * pow(5, _zoomOrderOfMagnitude); //maze.mazeAcross
    double rounding = scale; //maze.blockWidth
    int howFarAway = 3;
    assert(howFarAway < kOrderOfMagnitudeOrder);

    for (int i = -howFarAway; i <= howFarAway; i++) {
      for (int j = -howFarAway; j <= howFarAway; j++) {
        Vector2 basePos = Vector2(
            ((ship.position.x / rounding).round() + i) * rounding,
            ((ship.position.y / rounding).round() + j) * rounding);

        bool found = false;
        for (SpaceDot testDot in dots) {
          if (testDot.position.x == basePos.x &&
              testDot.position.y == basePos.y) {
            found = true;
          }
        }

        if (!found) {
          SpaceDot newDot = RecycledSpaceDot(
              position: basePos, width: scale * 0.05, height: scale * 0.05);
          if (!dots.contains(newDot)) {
            dots.add(newDot);
          }
          if (!newDot.isMounted && !newDot.isMounting) {
            add(newDot);
          }
        }
      }
    }

    for (var item in children) {
      if (item is SpaceDot) {
        if (item.position.distanceTo(ship.position) >
                item.width / 0.05 * (howFarAway + 1) ||
            item.width != scale * 0.05 ||
            world.asteroidsWrapper.isOutsideUniverse(item.position)) {
          item.removeFromParent();
        }
      }
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    if (!kDebugMode || _kPanTrackingCamera) {
      game.camera.follow(ship);
    }
    reset();
  }
}
