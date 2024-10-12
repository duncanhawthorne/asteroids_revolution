import 'dart:async' as async;
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../utils/helper.dart';
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

  int get _zoomOrderOfMagnitude => logMaze(world.everythingScale * 2).floor();

  get overZoomError =>
      !_kZoomTrackingCamera ? 1 : game.camera.viewfinder.zoom / _optimalZoom;

  Ship get ship => world.asteroidsWrapper.ship;

  int _zoomOrderOfMagnitudeLast = -100;

  get tooZoomedOut => overZoomError < 0.75;

  async.Timer? _zoomTimer;
  void startZoomTimer() {
    _zoomTimer =
        async.Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (!kDebugMode || _kZoomTrackingCamera) {
        if (game.camera.viewfinder.zoom < _optimalZoom * 0.95) {
          //debug("zoom in");
          game.camera.viewfinder.zoom *= pow(1 / overZoomError, 1 / 300);
          //game.camera.viewfinder.zoom *= (1 + zoomAdjustmentSpeed / 300);
        }
        if (game.camera.viewfinder.zoom > _optimalZoom * 1.05) {
          //debug("zoom out");
          game.camera.viewfinder.zoom *= pow(1 / overZoomError, 1 / 300);
          //game.camera.viewfinder.zoom /= (1 + zoomAdjustmentSpeed / 300);
        }
      }
    });
  }

  final Vector2 _shipPositionLast = Vector2(0, 0);
  void fixSpaceDots() {
    // ignore: dead_code
    if (false &&
        (_zoomOrderOfMagnitude != _zoomOrderOfMagnitudeLast ||
            // ignore: dead_code
            ship.position.distanceTo(_shipPositionLast) > maze.mazeWidth / 3)) {
      _shipPositionLast.setFrom(ship.position);
      _zoomOrderOfMagnitudeLast = _zoomOrderOfMagnitude;

      debug("Start");

      for (SpaceDot dot in spaceDots) {
        if (true || world.asteroidsWrapper.isOutsideUniverse(dot.position)) {
          //debug("kill dot");
          dot.removeFromParent();
        }
      }

      for (int magicNum = 1; magicNum <= 2; magicNum++) {
        debug("for start");

        double x1a = ship.position.x /
            2 /
            pow(maze.mazeAcross, _zoomOrderOfMagnitude + magicNum);
        double y1a = ship.position.y /
            2 /
            pow(maze.mazeAcross, _zoomOrderOfMagnitude + magicNum);

        int x11 = x1a.round();
        int y11 = y1a.round();
        int x1 = x11;
        int y1 = y11;
        // for (int x1 = x11 - 1; x1 <= x11 + 1; x1++) {
        // for (int y1 = y11 - 1; y1 <= y11 + 1; y1++) {

        double xr =
            (x1 * 2 * pow(maze.mazeAcross, _zoomOrderOfMagnitude + magicNum))
                .toDouble(); //FIXME doesn't work
        double yr =
            (y1 * 2 * pow(maze.mazeAcross, _zoomOrderOfMagnitude + magicNum))
                .toDouble();

        List<SpaceDot> spaceDotsToAdd = maze.spaceDots(
            scaleFactor: _zoomOrderOfMagnitude + magicNum - 1,
            positionOffset: Vector2(xr, yr),
            game: game);

        debug("Mid");
        debug(spaceDotsToAdd.length);

        for (SpaceDot dot in spaceDotsToAdd) {
          world.walls.add(dot);
        }

        debug("end");
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
