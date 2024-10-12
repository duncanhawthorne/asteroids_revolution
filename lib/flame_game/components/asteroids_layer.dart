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
import 'camera_layer.dart';
import 'cherry.dart';
import 'heart.dart';
import 'rock.dart';
import 'ship.dart';
import 'space_body.dart';
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

const _kHubbleLimitMult = 1.6;

class AsteroidsWrapper extends WrapperNoEvents
    with HasWorldReference<PacmanWorld>, HasGameReference<PacmanGame> {
  @override
  final priority = 1;

  final ValueNotifier<int> numberOfDeathsNotifier = ValueNotifier(0);

  final Ship ship = Ship(position: Vector2(-1, -1), velocity: Vector2(0, 0));
  final CameraWrapper cameraManager = CameraWrapper();

  async.Timer? _timerTopUpSpaceBodies;
  void _startTimerTopUpSpaceBodies() {
    _timerTopUpSpaceBodies =
        async.Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      _topUpSpaceBodies();
    });
  }

  async.Timer? _timerTidySpaceBodies;
  void _startTimerTidySpaceBodies() {
    _timerTidySpaceBodies =
        async.Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      _tidySpaceBodies();
    });
  }

  get _visibleRockLimit => 30 * pow(_kHubbleLimitMult, 2);
  get _transparentrockLimit => _visibleRockLimit;
  get heartLimit => _visibleRockLimit / 4 / 6 / 2;
  static const _alienLimit = kDebugMode ? 0 : 1; //1;
  static const _cherryLimit = 4;

  get _allRocks => children.whereType<Rock>();
  get _visibleRocks =>
      children.whereType<Rock>().where((item) => item.opacity == 1);
  get _transparentRocks =>
      children.whereType<Rock>().where((item) => item.opacity != 1);
  get hearts => children.whereType<Heart>();
  get _aliens => children.whereType<Alien>();
  get _cherries => children.whereType<Cherry>();
  get _spaceBodies => children.whereType<SpaceBody>();

  get _mappedUniverseLimit =>
      maze.mazeWidth * flameGameZoom / 30 * _kHubbleLimitMult * ship.radius;

  double get _universeRadius =>
      _mappedUniverseLimit *
      (1 + _twilightZoneWidth) /
      cameraManager.overZoomError;

  bool isOutsideUniverse(Vector2 target) {
    return target.distanceTo(ship.position) > _universeRadius;
  }

  static const double _twilightZoneWidth = 0.3;
  final Vector2 _oneTimePosition = Vector2(0, 0);
  Vector2 _randomPositionInTwilightZone() {
    double ringRadius =
        (1 + random.nextDouble() * _twilightZoneWidth) * _mappedUniverseLimit;
    double ringAngle = tau * random.nextDouble();
    _oneTimePosition.setFrom(ship.position);
    _oneTimePosition
      ..x += ringRadius * cos(ringAngle)
      ..y += ringRadius * sin(ringAngle);
    return _oneTimePosition;
  }

  Vector2 _randomPositionInMappedUniverse() {
    double ringRadius =
        (0.1 + random.nextDouble() * 0.9) * _mappedUniverseLimit;
    double ringAngle = tau * random.nextDouble();
    _oneTimePosition.setFrom(ship.position);
    _oneTimePosition
      ..x += ringRadius * cos(ringAngle)
      ..y += ringRadius * sin(ringAngle);
    return _oneTimePosition;
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
    _addStarterSpaceBodyField();

    _timerTopUpSpaceBodies?.cancel();
    _timerTidySpaceBodies?.cancel();

    _startTimerTopUpSpaceBodies();
    _startTimerTidySpaceBodies();
    debug("reset end");
  }

  void _addStarterSpaceBodyField() {
    for (int i = 0; i < _visibleRockLimit - _visibleRocks.length; i++) {
      add(RecycledRock(
          position: _randomPositionInMappedUniverse(),
          velocity: randomVelocityOffset(scale: 5 * world.everythingScale),
          numberExplosionsLeft: randomStartingHits(),
          radius: ship.radius * 0.8 * randomRadiusFactor()));
    }
    for (int i = 0; i < heartLimit - hearts.length; i++) {
      add(Heart(
        position: _randomPositionInMappedUniverse(),
        velocity: randomVelocityOffset(scale: 5 * world.everythingScale),
        radius: ship.radius,
      ));
    }
    for (int i = 0; i < _cherryLimit - _cherries.length; i++) {
      add(Cherry(
        position: _randomPositionInMappedUniverse(),
        velocity: randomVelocityOffset(scale: 5 * world.everythingScale),
        radius: ship.radius,
      ));
    }
    for (int i = 0; i < _alienLimit - _aliens.length; i++) {
      add(Alien(
        position: _randomPositionInMappedUniverse(),
        velocity: randomVelocityOffset(scale: 5 * world.everythingScale),
        radius: ship.radius,
      ));
    }
  }

  void addSmallRocksOnDamage() {
    for (int i = 0; i < _transparentrockLimit - _transparentRocks.length; i++) {
      add(RecycledRock(
          position: _randomPositionInMappedUniverse(),
          velocity: randomVelocityOffset(scale: 5 * world.everythingScale),
          numberExplosionsLeft: randomStartingHits(),
          radius: ship.radius * transpThreshold * 1.15));
    }
  }

  void _topUpSpaceBodies() {
    if (game.paused) {
      return;
    }
    if (cameraManager.tooZoomedOut) {
      return; //risk adding spaceBodies that you can see being added
    }
    for (int i = 0; i < _visibleRockLimit - _visibleRocks.length; i++) {
      add(RecycledRock(
          position: _randomPositionInTwilightZone(),
          velocity: randomVelocityOffset(scale: 10 * world.everythingScale),
          ensureVelocityTowardsCenter: true,
          radius: ship.radius * randomRadiusFactor(),
          numberExplosionsLeft: randomStartingHits()));
    }
    for (int i = 0; i < heartLimit - hearts.length; i++) {
      add(Heart(
          position: _randomPositionInTwilightZone(),
          velocity: randomVelocityOffset(scale: 5 * world.everythingScale),
          radius: ship.radius,
          ensureVelocityTowardsCenter: true));
    }
    for (int i = 0; i < _cherryLimit - _cherries.length; i++) {
      add(Cherry(
        position: _randomPositionInTwilightZone(),
        velocity: randomVelocityOffset(scale: 5 * world.everythingScale),
        ensureVelocityTowardsCenter: true,
        radius: ship.radius,
      ));
    }
    for (int i = 0; i < _alienLimit - _aliens.length; i++) {
      add(Alien(
        position: _randomPositionInTwilightZone(),
        velocity: randomVelocityOffset(scale: 5 * world.everythingScale),
        radius: ship.radius,
      ));
    }
  }

  void updateAllRockOpacities() {
    for (Rock rock in _allRocks) {
      rock.updateOpacity();
    }
  }

  void _tidySpaceBodies() {
    for (SpaceBody item in _spaceBodies) {
      item.tidy();
    }
    cameraManager.fixSpaceDots();
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(ship);
    add(cameraManager);
    if (!kDebugMode || kPanTrackingCamera) {
      game.camera.follow(ship);
    }
    reset();
  }
}
