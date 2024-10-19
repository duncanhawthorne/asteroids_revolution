import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../pacman_game.dart';
import '../pacman_world.dart';
import 'ship.dart';
import 'space_dot_block.dart';
import 'wrapper_no_events.dart';

bool _kPanTrackingCamera = true;
bool _kAutoZoomingCamera = true;

class CameraWrapper extends WrapperNoEvents
    with HasWorldReference<PacmanWorld>, HasGameReference<PacmanGame> {
  @override
  final int priority = -100;

  double get zoom => game.camera.viewfinder.zoom;
  set zoom(double z) => game.camera.viewfinder.zoom = z;

  @override
  void reset() {
    fixSpaceDots();

    if (!kDebugMode || _kAutoZoomingCamera) {
      zoom = _optimalZoom;
    }
  }

  double get _optimalZoom => 30 / world.everythingScale;

  double get overZoomError => !_kAutoZoomingCamera ? 1 : zoom / _optimalZoom;

  Ship get ship => world.space.ship;

  bool get tooZoomedOut => overZoomError < 0.75;

  SpaceDotWrapper smallDots = SpaceDotWrapper(
      position: Vector2(0, 0), orderMagnitude: 0, fullGrid: true);
  SpaceDotWrapper bigDot = SpaceDotWrapper(
      position: Vector2(0, 0), orderMagnitude: 1, fullGrid: false);

  int get _zoomOrderOfMagnitude => logOrder(1 / zoom * 75).floor();

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

  @override
  Future<void> update(double dt) async {
    if (!kDebugMode || _kAutoZoomingCamera) {
      if (zoom < _optimalZoom * 0.95 || zoom > _optimalZoom * 1.05) {
        zoom *= pow(1 / overZoomError, dt / 30);
      }
    }
  }
}
