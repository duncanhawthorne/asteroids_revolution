import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/geometry.dart';

import '../../style/palette.dart';
import '../maze.dart';
import 'alien.dart';
import 'asteroids_layer.dart';
import 'bullet.dart';
import 'cherry.dart';
import 'heart.dart';
import 'rock.dart';
import 'space_body.dart';
import 'wall.dart';

final Paint _wallBackgroundPaint = Paint()..color = Palette.background.color;

final double neutralShipRadius =
    maze.spriteWidth / 2 * Maze.pelletScaleFactor * 2;

double defaultShipRadius = neutralShipRadius / 18;

class Ship extends SpaceBody with CollisionCallbacks {
  Ship({required super.position, required super.velocity})
      : super(
            paint: Paint()..color = Palette.transp.color, //
            radius: defaultShipRadius,
            priority: 100);

  bool accelerating = false;
  @override
  // ignore: overridden_fields
  double friction = 0.98;

  @override
  // ignore: overridden_fields
  final canAccelerate = true;

  Timer multiGunTimer = Timer(15);

  final Vector2 _oneTimeVelocity = Vector2(0, 0);
  Vector2 fBulletVelocity() {
    _oneTimeVelocity.setFrom(world.direction);
    _oneTimeVelocity.scale(-2 * radius);
    _oneTimeVelocity.add(velocity);
    return _oneTimeVelocity;
  }

  final Vector2 _oneTimePosition = Vector2(0, 0);
  Vector2 fBulletPosition(double offset) {
    _oneTimePosition.setFrom(position);
    _oneTimePosition.x += radius * cos(angle) * offset;
    _oneTimePosition.y += radius * sin(angle) * offset;
    return _oneTimePosition;
  }

  late final gun = SpawnComponent(
    factory: (i) => RecycledBullet(
        position: position, velocity: fBulletVelocity(), radius: radius * 0.25),
    selfPositioning: true,
    period: 0.15,
  );

  late final gunR = SpawnComponent(
    factory: (i) => RecycledBullet(
        position: fBulletPosition(0.5),
        velocity: fBulletVelocity(),
        radius: radius * 0.25),
    selfPositioning: true,
    period: 0.15,
  );

  late final gunL = SpawnComponent(
    factory: (i) => RecycledBullet(
        position: fBulletPosition(-0.5),
        velocity: fBulletVelocity(),
        radius: radius * 0.25),
    selfPositioning: true,
    period: 0.15,
  );

  late final CircleComponent gunDot = CircleComponent(
      radius: 1,
      anchor: Anchor.center,
      paint: _wallBackgroundPaint,
      position: Vector2(1, 1));

  late final CircleComponent flameDot = CircleComponent(
      radius: 1,
      anchor: Anchor.center,
      paint: snakePaint,
      position: Vector2(1, 1))
    ..scale = Vector2(2, 5);

  @override
  void setSize(double h) {
    super.setSize(h);
    gunDot.radius = radius / 4;
    gunDot.position
      ..x = radius
      ..y = radius / 4;
    flameDot.radius = radius / 4;
    flameDot.position
      ..x = radius
      ..y = radius * 8 / 4;
    sprite?.position.setAll(radius);
    sprite?.size.setAll(radius * 2);
    world.asteroidsWrapper.updateAllRockOpacities();
  }

  @override
  setHealth(double h) {
    h = h.clamp(0.01, double.infinity);
    super.setHealth(h);
    setSize(defaultShipRadius * h);
  }

  @override
  void damage(double d) {
    super.damage(d);
    setHealth(health * (1 - d));
    if (d > 0) {
      world.asteroidsWrapper.addSmallRocksOnDamage();
    }

    //i-frames
    hitbox.collisionType = CollisionType.inactive;
    Future.delayed(Duration(milliseconds: 250), () {
      hitbox.collisionType = CollisionType.active;
    });
  }

  void addMultiGun() {
    world.asteroidsWrapper.add(gunR);
    world.asteroidsWrapper.add(gunL);
    multiGunTimer.reset();
    multiGunTimer.start();
  }

  SpriteComponent? sprite;
  Sprite? shipSprite;
  Sprite? shipSpriteFlame;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    hitbox.collisionType = CollisionType.active;
    add(gunDot);

    world.asteroidsWrapper.add(gun);

    shipSprite = await Sprite.load("ship.png");
    shipSpriteFlame = await Sprite.load("ship_flame.png");
    sprite = SpriteComponent(
        sprite: shipSprite,
        angle: -tau / 4,
        anchor: Anchor.center,
        position: Vector2.all(radius),
        size: Vector2.all(radius * 2));
    add(sprite!);

    reset();
  }

  @override
  void reset() {
    super.reset();
    position = Vector2(0, 0);
    velocity.setAll(0);
    setHealth(1);
  }

  @override
  Future<void> update(double dt) async {
    angle = -atan2(world.direction.x, world.direction.y);
    if (accelerating) {
      sprite?.sprite = shipSpriteFlame;
      //add(flameDot);
      acceleration.setFrom(world.direction);
      acceleration.scale(-radius); //* 1.4
    } else {
      //flameDot.removeFromParent();
      sprite?.sprite = shipSprite;
      acceleration.setAll(0);
    }
    multiGunTimer.update(dt);
    if (multiGunTimer.finished) {
      gunR.removeFromParent();
      gunL.removeFromParent();
      multiGunTimer.pause();
    }
    super.update(dt);
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    _onCollideWith(other);
  }

  void _onCollideWith(PositionComponent other) {
    if (other is Rock) {
      if (other.radius > radius * greyThreshold) {
        damage(0.2);
        other.explode();
      } else {
        other.velocity.scale(-1);
      }
    } else if (other is Alien) {
      if (other.radius > radius * greyThreshold) {
        damage(0.75); //huge
        other.damage(1);
      } else {
        other.velocity.scale(-1);
      }
    } else if (other is Heart) {
      other.removeFromParent();
      damage(-0.2);
    } else if (other is MazeWallRectangleVisual) {
      velocity.scale(-1);
    } else if (other is Cherry) {
      addMultiGun();
      other.removeFromParent();
    }
  }
}
