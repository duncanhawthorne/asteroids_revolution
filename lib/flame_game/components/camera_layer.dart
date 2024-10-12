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

bool kPanTrackingCamera = true;
bool kZoomTrackingCamera = true;

class CameraWrapper extends WrapperNoEvents
    with HasWorldReference<PacmanWorld>, HasGameReference<PacmanGame> {
  Iterable<SpaceDot> get spaceDots =>
      world.walls.children.whereType<SpaceDot>();

  @override
  void reset() {
    _zoomTimer?.cancel();
    startZoomTimer();

    if (!kDebugMode || kZoomTrackingCamera) {
      game.camera.viewfinder.zoom = optimalZoom();
    }
  }

  double optimalZoom() {
    return 30 / world.everythingScale;
  }

  int get zoomOrderOfMagnitude => logMaze(world.everythingScale * 2).floor();

  get overZoomError =>
      !kZoomTrackingCamera ? 1 : game.camera.viewfinder.zoom / optimalZoom();

  Ship get ship => world.asteroidsWrapper.ship;

  int _zoomOrderOfMagnitudeLast = -100;

  async.Timer? _zoomTimer;
  void startZoomTimer() {
    _zoomTimer =
        async.Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (!kDebugMode || kZoomTrackingCamera) {
        if (game.camera.viewfinder.zoom < optimalZoom() * 0.95) {
          //debug("zoom in");
          game.camera.viewfinder.zoom *= pow(1 / overZoomError, 1 / 300);
          //game.camera.viewfinder.zoom *= (1 + zoomAdjustmentSpeed / 300);
        }
        if (game.camera.viewfinder.zoom > optimalZoom() * 1.05) {
          //debug("zoom out");
          game.camera.viewfinder.zoom *= pow(1 / overZoomError, 1 / 300);
          //game.camera.viewfinder.zoom /= (1 + zoomAdjustmentSpeed / 300);
        }
      }
    });
  }

  Vector2 shipPositionLast = Vector2(0, 0);
  void fixSpaceDots() {
    // ignore: dead_code
    if (false &&
        (zoomOrderOfMagnitude != _zoomOrderOfMagnitudeLast ||
            // ignore: dead_code
            ship.position.distanceTo(shipPositionLast) > maze.mazeWidth / 3)) {
      shipPositionLast.setFrom(ship.position);
      _zoomOrderOfMagnitudeLast = zoomOrderOfMagnitude;

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
            pow(maze.mazeAcross, zoomOrderOfMagnitude + magicNum);
        double y1a = ship.position.y /
            2 /
            pow(maze.mazeAcross, zoomOrderOfMagnitude + magicNum);

        int x11 = x1a.round();
        int y11 = y1a.round();
        int x1 = x11;
        int y1 = y11;
        // for (int x1 = x11 - 1; x1 <= x11 + 1; x1++) {
        // for (int y1 = y11 - 1; y1 <= y11 + 1; y1++) {

        double xr =
            (x1 * 2 * pow(maze.mazeAcross, zoomOrderOfMagnitude + magicNum))
                .toDouble(); //FIXME doesn't work
        double yr =
            (y1 * 2 * pow(maze.mazeAcross, zoomOrderOfMagnitude + magicNum))
                .toDouble();

        List<SpaceDot> spaceDotsToAdd = maze.spaceDots(
            scaleFactor: zoomOrderOfMagnitude + magicNum - 1,
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

  get tooZoomedOut => overZoomError < 0.75;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    reset();
  }
}
