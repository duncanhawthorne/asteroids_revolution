import 'dart:async';
import 'dart:core';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../utils/constants.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'base_component.dart';
import 'physics_ball.dart';
import 'ship.dart';
import 'space_dot_block.dart';

const bool _kPanTrackingCamera = true;
const bool _kAutoZoomingCameraOnDebug = !drawDebugBoxes;
const bool _kAutoZoomingCamera = _kAutoZoomingCameraOnDebug || !kDebugMode;

class CameraWrapper extends BaseComponent
    with HasWorldReference<PacmanWorld>, HasGameReference<PacmanGame> {
  @override
  final int priority = -100;

  double _debugFakeZoom = 1;

  double get zoom =>
      _kAutoZoomingCamera ? game.camera.viewfinder.zoom : _debugFakeZoom;
  set zoom(double z) => _kAutoZoomingCamera
      ? game.camera.viewfinder.zoom = z
      : _debugFakeZoom = z;

  @override
  Future<void> reset() async {
    zoom = _optimalZoom;
    fixSpaceDots();
  }

  double get _optimalZoom => 1 / world.everythingScale;

  double get overZoomError => zoom / _optimalZoom;

  Ship get ship => world.space.ship;

  bool get tooZoomedOut => overZoomError < 0.75;

  final SpaceDotWrapper _smallDots = SpaceDotWrapper(
    position: Vector2(0, 0),
    orderMagnitude: 0,
    fullGrid: true,
  );
  final SpaceDotWrapper _bigDot = SpaceDotWrapper(
    position: Vector2(0, 0),
    orderMagnitude: 1,
    fullGrid: false,
  );

  int get _zoomOrderOfMagnitude =>
      logOrder(1 / zoom * (1 / mapSizeScale) * 75).floor();

  int _zoomOrderOfMagnitudeLast = -1;
  void fixSpaceDots() {
    if (_zoomOrderOfMagnitude != _zoomOrderOfMagnitudeLast) {
      _zoomOrderOfMagnitudeLast = _zoomOrderOfMagnitude;
      physicsScale = 1 / (ship.radius / defaultShipRadius * 1.5);
      world.space.resetSpriteVsPhysicsScale();
    }
    _smallDots.tidyUpdate(
      newOrderMagnitude: _zoomOrderOfMagnitude + 0,
      shipPosition: ship.position,
    );
    _bigDot.tidyUpdate(
      newOrderMagnitude: _zoomOrderOfMagnitude + 1,
      shipPosition: ship.position,
    );
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    if (!kDebugMode || _kPanTrackingCamera) {
      game.camera.follow(ship);
    }
    add(_smallDots);
    add(_bigDot);
    unawaited(reset());
  }

  @override
  void update(double dt) {
    if (zoom < _optimalZoom * 0.95 || zoom > _optimalZoom * 1.05) {
      zoom *= pow(1 / overZoomError, dt / 30);
    }
  }
}
