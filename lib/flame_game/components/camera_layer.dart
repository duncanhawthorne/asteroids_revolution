import 'dart:async' as async;
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../pacman_game.dart';
import '../pacman_world.dart';
import 'ship.dart';
import 'space_dot.dart';
import 'space_dot_block.dart';
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

  SpaceDotWrapper smallDots = SpaceDotWrapper(
      position: Vector2(0, 0), orderMagnitude: 0, fullGrid: true);
  SpaceDotWrapper bigDot = SpaceDotWrapper(
      position: Vector2(0, 0), orderMagnitude: 1, fullGrid: false);

  double logOrder(num x) => log(x) / log(kOrderOfMagnitudeOrder);
  int get _zoomOrderOfMagnitude =>
      logOrder(world.everythingScale * 2).floor(); //FIXME should be off zoom

  void fixSpaceDots() {
    smallDots.tidyUpdate(
        newOrderMagnitude: _zoomOrderOfMagnitude + 0,
        shipPosition: ship.position);
    bigDot.tidyUpdate(
        newOrderMagnitude: _zoomOrderOfMagnitude + 1,
        shipPosition: ship.position);
    return;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    if (!kDebugMode || _kPanTrackingCamera) {
      game.camera.follow(ship);
    }
    add(smallDots);
    add(bigDot);
    reset();
  }
}
