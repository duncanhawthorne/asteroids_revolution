import 'dart:async' as async;
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../utils/helper.dart';
import '../maze.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'alien_bomb.dart';
import 'alien_gun.dart';
import 'bullet.dart';
import 'bullet_layer.dart';
import 'camera_layer.dart';
import 'debug_circle.dart';
import 'heart.dart';
import 'rock.dart';
import 'rock_layer.dart';
import 'ship.dart';
import 'space_body.dart';
import 'triple.dart';
import 'wrapper_no_events.dart';

const double _kHubbleLimitMult = 1.4;

class SpaceWrapper extends WrapperNoEvents
    with HasWorldReference<PacmanWorld>, HasGameReference<PacmanGame> {
  final ValueNotifier<int> numberOfDeathsNotifier = ValueNotifier<int>(0);

  final Ship ship = Ship(position: Vector2(0, 0), velocity: Vector2(0, 0));
  final CameraWrapper _cameraManager = CameraWrapper();
  final BulletWrapper bullets = BulletWrapper();
  final RockWrapper rocks = RockWrapper();

  async.Timer? _timerTopUpSpaceBodies;
  void _startTimerTopUpSpaceBodies() {
    _timerTopUpSpaceBodies = async.Timer.periodic(
      const Duration(milliseconds: 1000),
      (async.Timer timer) {
        _topUpSpaceBodies();
      },
    );
  }

  async.Timer? _timerTidySpaceBodies;
  void _startTimerTidySpaceBodies() {
    _timerTidySpaceBodies = async.Timer.periodic(
      const Duration(milliseconds: 1000),
      (async.Timer timer) {
        _tidySpaceBodies();
      },
    );
  }

  double get zoomAdjustedEverythingScale =>
      world.everythingScale / _cameraManager.overZoomError;

  final int _visibleRockLimit = (30 * pow(_kHubbleLimitMult, 2)).floor();
  late final int _transparentRockLimit = _visibleRockLimit ~/ 20;
  late final double heartLimit = _visibleRockLimit / 4 / 6;

  Iterable<Rock> get _allRocks => rocks.children.whereType<Rock>();
  Iterable<Rock> get _visibleRocks =>
      rocks.children.whereType<Rock>().where((Rock item) => item.opacity == 1);
  Iterable<Rock> get _transparentRocks =>
      rocks.children.whereType<Rock>().where((Rock item) => item.opacity != 1);
  Iterable<Bullet> get _bullets => bullets.children.whereType<Bullet>();
  Iterable<Heart> get hearts => children.whereType<Heart>();
  Iterable<SpaceBody> get _otherSpaceBodies => children.whereType<SpaceBody>();

  double get _visibleUniverseRadius =>
      max(game.size.y, game.size.x) / 2 / _cameraManager.zoom;

  double get _mappedUniverseRadius =>
      maze.mazeWidth *
      flameGameZoom /
      30 *
      ship.radius /
      _cameraManager.overZoomError *
      _kHubbleLimitMult;

  double get _fullUniverseRadius =>
      mappedUniverseRadius * (1 + _twilightZoneWidth);

  double get _visiblePlusUniverseRadius => visibleUniverseRadius * 1.7;

  double visibleUniverseRadius = 100000;
  double mappedUniverseRadius = 100000;
  double fullUniverseRadius = 100000;
  double visiblePlusUniverseRadius = 100000;

  static const double _twilightZoneWidth = 0.3;
  Vector2 _randomPositionInTwilightZone() {
    return randomRThetaRing(
      center: ship.position,
      ringWidth: _twilightZoneWidth,
      ignoredRing: 1,
      overallScale: mappedUniverseRadius,
    );
  }

  Vector2 _randomPositionInMappedUniverse() {
    return randomRThetaRing(
      center: ship.position,
      ringWidth: 0.9,
      ignoredRing: 0.1,
      overallScale: mappedUniverseRadius,
    );
  }

  @override
  Future<void> reset() async {
    removeWhere((Component item) => item is Heart);
    removeWhere((Component item) => item is Triple);
    removeWhere((Component item) => item is AlienBomb);
    removeWhere((Component item) => item is AlienGun);

    ship.reset();
    async.unawaited(_cameraManager.reset());
    async.unawaited(bullets.reset());
    async.unawaited(rocks.reset());

    _addStarterSpaceBodyField();

    _timerTopUpSpaceBodies?.cancel();
    _timerTidySpaceBodies?.cancel();

    _startTimerTopUpSpaceBodies();
    _startTimerTidySpaceBodies();
  }

  void addSmallRocksOnDamage() {
    for (int i = 0; i < _transparentRockLimit - _transparentRocks.length; i++) {
      rocks.add(
        Rock(
          position: _randomPositionInMappedUniverse(),
          velocity: randomVelocityOffset(
            scale: 5 * zoomAdjustedEverythingScale,
          ),
          numberExplosionsLeft: randomStartingHits(),
          radius: ship.radius * transpThreshold * 1.15,
        ),
      );
    }
  }

  void _addStarterSpaceBodyField() {
    _topUpSpaceBodies(initial: true);
  }

  Vector2 _newBodyPosition(bool initial) {
    return initial
        ? _randomPositionInMappedUniverse()
        : _randomPositionInTwilightZone();
  }

  void _topUpSpaceBodies({bool initial = false}) {
    if (game.paused) {
      return;
    }
    if (_cameraManager.tooZoomedOut) {
      return; //risk adding spaceBodies that you can see being added
    }
    for (int i = 0; i < _visibleRockLimit - _visibleRocks.length; i++) {
      rocks.add(
        Rock(
          position: _newBodyPosition(initial),
          velocity: randomVelocityOffset(
            scale: 10 * zoomAdjustedEverythingScale,
          ),
          ensureVelocityTowardsCenter: true,
          radius: ship.radius * randomRadiusFactor(),
          numberExplosionsLeft: randomStartingHits(),
        ),
      );
    }
    for (int i = 0; i < heartLimit - hearts.length; i++) {
      add(
        Heart(
          position: _newBodyPosition(initial),
          velocity: randomVelocityOffset(
            scale: 5 * zoomAdjustedEverythingScale,
          ),
          radius: ship.radius,
          ensureVelocityTowardsCenter: true,
        ),
      );
    }
    for (
      int i = 0;
      i < Triple.limit - children.whereType<Triple>().length;
      i++
    ) {
      add(
        Triple(
          position: _newBodyPosition(initial),
          velocity: randomVelocityOffset(
            scale: 5 * zoomAdjustedEverythingScale,
          ),
          ensureVelocityTowardsCenter: true,
          radius: ship.radius,
        ),
      );
    }
    for (
      int i = 0;
      i < AlienBomb.limit - children.whereType<AlienBomb>().length;
      i++
    ) {
      add(
        AlienBomb(
          position: _newBodyPosition(initial),
          velocity: randomVelocityOffset(
            scale: 5 * zoomAdjustedEverythingScale,
          ),
          radius: ship.radius,
        ),
      );
    }
    for (
      int i = 0;
      i < AlienGun.limit - children.whereType<AlienGun>().length;
      i++
    ) {
      add(
        AlienGun(
          position: _newBodyPosition(initial),
          velocity: randomVelocityOffset(
            scale: 5 * zoomAdjustedEverythingScale,
          ),
          radius: ship.radius,
        ),
      );
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

  void resetSpriteVsPhysicsScale() {
    for (SpaceBody item in _otherSpaceBodies) {
      item.resetSpriteVsPhysicsScale();
    }
    for (Rock rock in _allRocks) {
      rock.resetSpriteVsPhysicsScale();
    }
    for (Bullet bullet in _bullets) {
      bullet.resetSpriteVsPhysicsScale();
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(ship);
    add(_cameraManager);
    add(bullets);
    add(rocks);
    //add(world.walls);
    // ignore: dead_code
    if (false && kDebugMode) {
      add(DebugCircle(type: "full")); //full universe
      add(DebugCircle(type: "mapped")); //mapped universe
      add(DebugCircle(type: "visiblePlus")); //visible universe
      add(DebugCircle(type: "visible")); //visible universe
    }
    async.unawaited(reset());
  }

  @override
  Future<void> update(double dt) async {
    super.update(dt);

    visibleUniverseRadius = _visibleUniverseRadius;
    mappedUniverseRadius = _mappedUniverseRadius;
    fullUniverseRadius = _fullUniverseRadius;
    visiblePlusUniverseRadius = _visiblePlusUniverseRadius;
  }
}
