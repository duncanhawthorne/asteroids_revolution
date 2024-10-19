import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/geometry.dart';

import '../../style/palette.dart';
import '../maze.dart';
import 'alien.dart';
import 'bullet.dart';
import 'cherry.dart';
import 'heart.dart';
import 'rock.dart';
import 'space_body.dart';
import 'space_layer.dart';
import 'wall.dart';

final Paint _wallBackgroundPaint = Paint()..color = Palette.background.color;
final Paint _transparentPaint = Paint()..color = Palette.transp.color;

final double neutralShipRadius =
    maze.spriteWidth / 2 * Maze.pelletScaleFactor * 2;

double defaultShipRadius = neutralShipRadius / 18;

class Ship extends SpaceBody with CollisionCallbacks {
  Ship({required super.position, required super.velocity})
      : super(
            paint: _transparentPaint, //
            radius: defaultShipRadius);

  bool accelerating = false;
  @override
  // ignore: overridden_fields
  double friction = 0.98;

  @override
  // ignore: overridden_fields
  final bool canAccelerate = true;

  Timer multiGunTimer = Timer(15);

  final Vector2 _oneTimeVelocity = Vector2(0, 0);
  Vector2 fBulletVelocity() {
    _oneTimeVelocity
      ..setFrom(world.direction)
      ..scale(-2 * radius)
      ..add(velocity);
    return _oneTimeVelocity;
  }

  final Vector2 _oneTimePosition = Vector2(0, 0);
  Vector2 fBulletPosition(double offset) {
    _oneTimePosition
      ..setFrom(position)
      ..x += radius * cos(angle) * offset
      ..y += radius * sin(angle) * offset;
    return _oneTimePosition;
  }

  late final SpawnComponent gun = SpawnComponent(
    factory: (int i) => RecycledBullet(
        position: position, velocity: fBulletVelocity(), radius: radius * 0.25),
    selfPositioning: true,
    period: 0.15,
  );

  late final SpawnComponent gunR = SpawnComponent(
    factory: (int i) => RecycledBullet(
        position: fBulletPosition(0.5),
        velocity: fBulletVelocity(),
        radius: radius * 0.25),
    selfPositioning: true,
    period: 0.15,
  );

  late final SpawnComponent gunL = SpawnComponent(
    factory: (int i) => RecycledBullet(
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
      paint: seedPaint,
      position: Vector2(1, 1))
    ..scale = Vector2(2, 5);

  @override
  void setSize(double h) {
    if (radius != h) {
      world.space.updateAllRockOpacities();
    }
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
  }

  @override
  void setHealth(double h) {
    h = h.clamp(0.01, double.infinity);
    super.setHealth(h);
    setSize(defaultShipRadius * h);
  }

  @override
  void damage(double d) {
    super.damage(d);
    setHealth(health * (1 - d));
    if (d > 0) {
      world.space.addSmallRocksOnDamage();
    }

    //i-frames
    hitbox.collisionType = CollisionType.inactive;
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      hitbox.collisionType = CollisionType.active;
    });
  }

  void addMultiGun() {
    world.space.bullets.add(gunR);
    world.space.bullets.add(gunL);
    multiGunTimer
      ..reset()
      ..start();
  }

  SpriteComponent? sprite;
  Sprite? shipSprite;
  Sprite? shipSpriteFlame;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    hitbox.collisionType = CollisionType.active;
    //add(gunDot);

    world.space.bullets.add(gun);

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
      acceleration
        ..setFrom(world.direction)
        ..scale(-radius); //* 1.4
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
    await super.update(dt);
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
      if (!other.isSmall) {
        damage(0.2);
        other.explode();
      } else {
        other.velocity.scale(-1);
      }
    } else if (other is Alien) {
      damage(0.75); //huge
      other.damage(1);
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
