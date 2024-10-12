import 'dart:async' as async;
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/geometry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../style/palette.dart';
import '../../utils/helper.dart';
import '../maze.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'alien.dart';
import 'bullet.dart';
import 'cherry.dart';
import 'heart.dart';
import 'rock.dart';
import 'ship.dart';
import 'space_body.dart';
import 'space_dot.dart';
import 'wrapper_no_events.dart';

final Paint snakePaint = Paint()..color = Palette.seed.color;
final Paint rockPaint = Paint()..color = Palette.text.color;
final Paint pebblePaint = Paint()..color = Palette.dull.color;
final Paint heartPaint = Paint()..color = Palette.warning.color;
final Paint wallBackgroundPaint = Paint()..color = Palette.background.color;
final double neutralShipRadius =
    maze.spriteWidth / 2 * Maze.pelletScaleFactor * 2;

const double greyThreshold = 0.5;
const double transpThreshold = 0.5 * 0.2;
bool kPanTrackingCamera = true;
bool kZoomTrackingCamera = true;
const _kHubbleLimitMult = 1.6;

class AsteroidsWrapper extends WrapperNoEvents
    with HasWorldReference<PacmanWorld>, HasGameReference<PacmanGame> {
  @override
  final priority = 1;

  final ValueNotifier<int> numberOfDeathsNotifier = ValueNotifier(0);

  Ship ship = Ship(position: Vector2(-1, -1), velocity: Vector2(0, 0));

  get _hubbleLimit =>
      maze.mazeWidth *
      flameGameZoom /
      30 *
      _kHubbleLimitMult *
      ship.radius; // / zoomError;

  get overZoomError =>
      !kZoomTrackingCamera ? 1 : game.camera.viewfinder.zoom / optimalZoom();

  get _visibleRockLimit => 30 * pow(_kHubbleLimitMult, 2);
  get heartLimit => _visibleRockLimit / 4 / 6 / 2;
  get _alienLimit => kDebugMode ? 0 : 1; //1;
  get _cherryLimit => 4;
  get _transparentrockLimit => _visibleRockLimit;

  get _allRocks => children.whereType<Rock>();
  get _visibleRocks =>
      children.whereType<Rock>().where((item) => item.opacity == 1);
  get _transparentRocks =>
      children.whereType<Rock>().where((item) => item.opacity != 1);
  get hearts => children.whereType<Heart>();
  get _aliens => children.whereType<Alien>();
  get _cherries => children.whereType<Cherry>();
  // ignore: unused_element
  get _bullets => children.whereType<Bullet>();
  get _spaceBodies => children.whereType<SpaceBody>();
  Iterable<SpaceDot> get spaceDots =>
      world.walls.children.whereType<SpaceDot>();

  bool isOutsideKnownWorld(Vector2 target) {
    return target.distanceTo(ship.position) > _hubbleLimit;
  }

  bool isVeryOutsideKnownWorld(Vector2 target) {
    return target.distanceTo(ship.position) >
        _hubbleLimit * (1 + _ringJustOutsideKnownWorld) / overZoomError;
  }

  final Vector2 _oneTimeVelocity = Vector2(0, 0);
  Vector2 randomVelocityOffset({double scale = 1}) {
    //_oneTimeVelocity.setAll(0);
    _oneTimeVelocity.x = centeredRandom() * scale;
    _oneTimeVelocity.y = centeredRandom() * scale;
    return _oneTimeVelocity;
  }

  static const double _ringJustOutsideKnownWorld = 0.3;
  final Vector2 _oneTimePosition = Vector2(0, 0);
  Vector2 positionJustOutsideKnownWorld() {
    double ringRadius =
        (1 + random.nextDouble() * _ringJustOutsideKnownWorld) * _hubbleLimit;
    double ringAngle = tau * random.nextDouble();
    _oneTimePosition.setFrom(ship.position);
    _oneTimePosition
      ..x += ringRadius * cos(ringAngle)
      ..y += ringRadius * sin(ringAngle);
    return _oneTimePosition;
  }

  Vector2 positionInsideKnownWorld() {
    double ringRadius = (0.1 + random.nextDouble() * 0.9) * _hubbleLimit;
    double ringAngle = tau * random.nextDouble();
    _oneTimePosition.setFrom(ship.position);
    _oneTimePosition
      ..x += ringRadius * cos(ringAngle)
      ..y += ringRadius * sin(ringAngle);
    return _oneTimePosition;
  }

  void addStarterSpaceBodyField() {
    debug("starter field start");
    for (int i = 0; i < _visibleRockLimit - _visibleRocks.length; i++) {
      add(RecycledRock(
          position: positionInsideKnownWorld(),
          velocity: randomVelocityOffset(scale: 5 * world.everythingScale),
          numberExplosionsLeft: randomStartingHits(),
          radius: ship.radius * 0.8 * randomRadiusFactor()));
    }
    for (int i = 0; i < heartLimit - hearts.length; i++) {
      add(Heart(
        position: positionInsideKnownWorld(),
        velocity: randomVelocityOffset(scale: 5 * world.everythingScale),
        radius: ship.radius,
      ));
    }
    for (int i = 0; i < _cherryLimit - _cherries.length; i++) {
      add(Cherry(
        position: positionInsideKnownWorld(),
        velocity: randomVelocityOffset(scale: 5 * world.everythingScale),
        radius: ship.radius,
      ));
    }
    for (int i = 0; i < _alienLimit - _aliens.length; i++) {
      add(Alien(
        position: positionInsideKnownWorld(),
        velocity: randomVelocityOffset(scale: 5 * world.everythingScale),
        radius: ship.radius,
      ));
    }
    debug("starter field end");
  }

  void addSmallRocksOnDamage() {
    for (int i = 0; i < _transparentrockLimit - _transparentRocks.length; i++) {
      add(RecycledRock(
          position: positionInsideKnownWorld(),
          velocity: randomVelocityOffset(scale: 5 * world.everythingScale),
          numberExplosionsLeft: randomStartingHits(),
          radius: ship.radius * transpThreshold * 1.15));
    }
  }

  double optimalZoom() {
    return 30 / world.everythingScale;
  }

  @override
  void reset() {
    debug("reset start");
    removeWhere((item) => item is Rock);
    removeWhere((item) => item is Bullet);
    removeWhere((item) => item is Heart);
    removeWhere((item) => item is Cherry);
    removeWhere((item) => item is Alien);

    ship.reset();
    addStarterSpaceBodyField();

    if (!kDebugMode || kZoomTrackingCamera) {
      game.camera.viewfinder.zoom = optimalZoom();
    }

    _zoomTimer?.cancel();
    _topUpSpaceBodies?.cancel();
    _tidySpaceBodies?.cancel();

    startZoomTimer();
    _startTopUpSpaceBodies();
    _startTidySpaceBodies();
    debug("reset end");
  }

  void updateAllRockOpacities() {
    for (Rock rock in _allRocks) {
      rock.updateOpacity();
    }
  }

  double logMaze(num x) => log(x) / log(maze.mazeAcross);
  int get zoomOrderOfMagnitude => logMaze(world.everythingScale * 2).floor();

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

  get tooZoomedOut => overZoomError < 0.75;

  async.Timer? _topUpSpaceBodies;
  void _startTopUpSpaceBodies() {
    _topUpSpaceBodies =
        async.Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (game.paused) {
        return;
      }
      if (tooZoomedOut) {
        return; //risk adding spaceBodies that you can see being added
      }
      for (int i = 0; i < _visibleRockLimit - _visibleRocks.length; i++) {
        //debug(["asteroidTimer add", visibleRocks.length, rockLimit]);
        add(RecycledRock(
            position: positionJustOutsideKnownWorld(),
            velocity: randomVelocityOffset(scale: 10 * world.everythingScale),
            ensureVelocityTowardsCenter: true,
            radius: ship.radius * randomRadiusFactor(),
            numberExplosionsLeft: randomStartingHits()));
      }
      for (int i = 0; i < heartLimit - hearts.length; i++) {
        add(Heart(
            position: positionJustOutsideKnownWorld(),
            velocity: randomVelocityOffset(scale: 5 * world.everythingScale),
            radius: ship.radius,
            ensureVelocityTowardsCenter: true));
      }
      for (int i = 0; i < _cherryLimit - _cherries.length; i++) {
        add(Cherry(
          position: positionJustOutsideKnownWorld(),
          velocity: randomVelocityOffset(scale: 5 * world.everythingScale),
          ensureVelocityTowardsCenter: true,
          radius: ship.radius,
        ));
      }
      for (int i = 0; i < _alienLimit - _aliens.length; i++) {
        add(Alien(
          position: positionJustOutsideKnownWorld(),
          velocity: randomVelocityOffset(scale: 5 * world.everythingScale),
          radius: ship.radius,
        ));
      }
    });
  }

  int _zoomOrderOfMagnitudeLast = -100;
  async.Timer? _tidySpaceBodies;
  void _startTidySpaceBodies() {
    _tidySpaceBodies =
        async.Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      singleTidy();
    });
  }

  Vector2 shipPositionLast = Vector2(0, 0);
  void fixSpaceDot() {
    if (false &&
        (zoomOrderOfMagnitude != _zoomOrderOfMagnitudeLast ||
            ship.position.distanceTo(shipPositionLast) > maze.mazeWidth / 3)) {
      shipPositionLast.setFrom(ship.position);
      _zoomOrderOfMagnitudeLast = zoomOrderOfMagnitude;

      debug("Start");

      for (SpaceDot dot in spaceDots) {
        if (true || isOutsideKnownWorld(dot.position)) {
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

  void singleTidy() {
    /*
    if (tooZoomedOut) {
      return; //risk adding spaceBodies that you can see being added
    }

     */
    for (SpaceBody item in _spaceBodies) {
      item.tidy();
    }
    fixSpaceDot();
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(ship);
    if (!kDebugMode || kPanTrackingCamera) {
      game.camera.follow(ship);
    }
    reset();
  }
}
