import 'dart:async' as async;
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../style/palette.dart';
import '../../utils/helper.dart';
import '../maze.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'alien.dart';
import 'bullet.dart';
import 'bullet_layer.dart';
import 'camera_layer.dart';
import 'cherry.dart';
import 'heart.dart';
import 'rock.dart';
import 'rock_layer.dart';
import 'ship.dart';
import 'space_body.dart';
import 'wrapper_no_events.dart';

final Paint seedPaint = Paint()..color = Palette.seed.color;

const double _kHubbleLimitMult = 1.6;

class SpaceWrapper extends WrapperNoEvents
    with HasWorldReference<PacmanWorld>, HasGameReference<PacmanGame> {
  final ValueNotifier<int> numberOfDeathsNotifier = ValueNotifier<int>(0);

  final Ship ship = Ship(position: Vector2(-1, -1), velocity: Vector2(0, 0));
  final CameraWrapper _cameraManager = CameraWrapper();
  final BulletWrapper bullets = BulletWrapper();
  final RockWrapper rocks = RockWrapper();

  async.Timer? _timerTopUpSpaceBodies;
  void _startTimerTopUpSpaceBodies() {
    _timerTopUpSpaceBodies = async.Timer.periodic(
        const Duration(milliseconds: 1000), (async.Timer timer) {
      _topUpSpaceBodies();
    });
  }

  async.Timer? _timerTidySpaceBodies;
  void _startTimerTidySpaceBodies() {
    _timerTidySpaceBodies = async.Timer.periodic(
        const Duration(milliseconds: 1000), (async.Timer timer) {
      _tidySpaceBodies();
    });
  }

  double get zoomAdjustedEverythingScale =>
      world.everythingScale / _cameraManager.overZoomError;

  final int _visibleRockLimit = (30 * pow(_kHubbleLimitMult, 2)).floor();
  late final int _transparentrockLimit = _visibleRockLimit ~/ 20;
  late final double heartLimit = _visibleRockLimit / 4 / 6 / 2;
  static const int _alienLimit = kDebugMode ? 0 : 1; //1;
  static const int _cherryLimit = 4;

  Iterable<Rock> get _allRocks => rocks.children.whereType<Rock>();
  Iterable<Rock> get _visibleRocks =>
      rocks.children.whereType<Rock>().where((Rock item) => item.opacity == 1);
  Iterable<Rock> get _transparentRocks =>
      rocks.children.whereType<Rock>().where((Rock item) => item.opacity != 1);
  Iterable<Bullet> get _bullets => bullets.children.whereType<Bullet>();
  Iterable<Heart> get hearts => children.whereType<Heart>();
  Iterable<Alien> get _aliens => children.whereType<Alien>();
  Iterable<Cherry> get _cherries => children.whereType<Cherry>();
  Iterable<SpaceBody> get _otherSpaceBodies => children.whereType<SpaceBody>();

  double get mappedUniverseRadius =>
      maze.mazeWidth *
      flameGameZoom /
      30 *
      _kHubbleLimitMult *
      ship.radius /
      min(1, _cameraManager.overZoomError);

  double get _fullUniverseRadius =>
      mappedUniverseRadius * (1 + _twilightZoneWidth);

  bool isOutsideFullUniverse(Vector2 target) {
    return target.distanceTo(ship.position) > _fullUniverseRadius;
  }

  static const double _twilightZoneWidth = 0.3;
  Vector2 _randomPositionInTwilightZone() {
    return randomRThetaRing(
        center: ship.position,
        ringWidth: _twilightZoneWidth,
        ignoredRing: 1,
        overallScale: mappedUniverseRadius);
  }

  Vector2 _randomPositionInMappedUniverse() {
    return randomRThetaRing(
        center: ship.position,
        ringWidth: 0.9,
        ignoredRing: 0.1,
        overallScale: mappedUniverseRadius);
  }

  @override
  void reset() {
    removeWhere((Component item) => item is Heart);
    removeWhere((Component item) => item is Cherry);
    removeWhere((Component item) => item is Alien);

    ship.reset();
    _cameraManager.reset();
    bullets.reset();
    rocks.reset();

    _addStarterSpaceBodyField();

    _timerTopUpSpaceBodies?.cancel();
    _timerTidySpaceBodies?.cancel();

    _startTimerTopUpSpaceBodies();
    _startTimerTidySpaceBodies();
  }

  void _addStarterSpaceBodyField() {
    for (int i = 0; i < _visibleRockLimit - _visibleRocks.length; i++) {
      rocks.add(RecycledRock(
          position: _randomPositionInMappedUniverse(),
          velocity:
              randomVelocityOffset(scale: 5 * zoomAdjustedEverythingScale),
          numberExplosionsLeft: randomStartingHits(),
          radius: ship.radius * 0.8 * randomRadiusFactor()));
    }
    for (int i = 0; i < heartLimit - hearts.length; i++) {
      add(Heart(
        position: _randomPositionInMappedUniverse(),
        velocity: randomVelocityOffset(scale: 5 * zoomAdjustedEverythingScale),
        radius: ship.radius,
      ));
    }
    for (int i = 0; i < _cherryLimit - _cherries.length; i++) {
      add(Cherry(
        position: _randomPositionInMappedUniverse(),
        velocity: randomVelocityOffset(scale: 5 * zoomAdjustedEverythingScale),
        radius: ship.radius,
      ));
    }
    for (int i = 0; i < _alienLimit - _aliens.length; i++) {
      add(Alien(
        position: _randomPositionInMappedUniverse(),
        velocity: randomVelocityOffset(scale: 5 * zoomAdjustedEverythingScale),
        radius: ship.radius,
      ));
    }
  }

  void addSmallRocksOnDamage() {
    for (int i = 0; i < _transparentrockLimit - _transparentRocks.length; i++) {
      rocks.add(RecycledRock(
          position: _randomPositionInMappedUniverse(),
          velocity:
              randomVelocityOffset(scale: 5 * zoomAdjustedEverythingScale),
          numberExplosionsLeft: randomStartingHits(),
          radius: ship.radius * transpThreshold * 1.15));
    }
  }

  void _topUpSpaceBodies() {
    if (game.paused) {
      return;
    }
    if (_cameraManager.tooZoomedOut) {
      return; //risk adding spaceBodies that you can see being added
    }
    for (int i = 0; i < _visibleRockLimit - _visibleRocks.length; i++) {
      rocks.add(RecycledRock(
          position: _randomPositionInTwilightZone(),
          velocity:
              randomVelocityOffset(scale: 10 * zoomAdjustedEverythingScale),
          ensureVelocityTowardsCenter: true,
          radius: ship.radius * randomRadiusFactor(),
          numberExplosionsLeft: randomStartingHits()));
    }
    for (int i = 0; i < heartLimit - hearts.length; i++) {
      add(Heart(
          position: _randomPositionInTwilightZone(),
          velocity:
              randomVelocityOffset(scale: 5 * zoomAdjustedEverythingScale),
          radius: ship.radius,
          ensureVelocityTowardsCenter: true));
    }
    for (int i = 0; i < _cherryLimit - _cherries.length; i++) {
      add(Cherry(
        position: _randomPositionInTwilightZone(),
        velocity: randomVelocityOffset(scale: 5 * zoomAdjustedEverythingScale),
        ensureVelocityTowardsCenter: true,
        radius: ship.radius,
      ));
    }
    for (int i = 0; i < _alienLimit - _aliens.length; i++) {
      add(Alien(
        position: _randomPositionInTwilightZone(),
        velocity: randomVelocityOffset(scale: 5 * zoomAdjustedEverythingScale),
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
    for (SpaceBody item in _otherSpaceBodies) {
      item.tidy();
    }
    for (Rock rock in _allRocks) {
      rock.tidy();
    }
    for (Bullet bullet in _bullets) {
      bullet.tidy();
    }
    _cameraManager.fixSpaceDots();
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(ship);
    add(_cameraManager);
    add(bullets);
    add(rocks);
    add(world.walls);
    reset();
  }
}
