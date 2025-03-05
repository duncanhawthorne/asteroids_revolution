import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../icons/stub_sprites.dart';
import '../maze.dart';
import 'alien.dart';
import 'bullet.dart';
import 'cherry.dart';
import 'heart.dart';
import 'rock.dart';
import 'space_body.dart';
import 'wall.dart';

final double neutralShipRadius = maze.spriteWidth / 2 * 0.4 * 2;

double defaultShipRadius = neutralShipRadius / 18 * (kDebugMode ? 6 : 1);

class Ship extends SpaceBody with CollisionCallbacks {
  Ship({required super.position, required super.velocity})
    : super(radius: defaultShipRadius);

  @override
  // ignore: overridden_fields
  bool neverRender = true;

  bool accelerating = false;
  @override
  // ignore: overridden_fields
  double friction = 0.98;

  @override
  // ignore: overridden_fields
  final bool canAccelerate = true;

  final Timer _multiGunTimer = Timer(15);

  final Vector2 _oneTimeVelocity = Vector2(0, 0);
  Vector2 _fBulletVelocity() {
    _oneTimeVelocity
      ..setFrom(world.downDirection)
      ..scale(-2 * radius)
      ..add(velocity);
    return _oneTimeVelocity;
  }

  final Vector2 _oneTimePosition = Vector2(0, 0);
  Vector2 _fBulletPosition(double offset) {
    _oneTimePosition
      ..setFrom(position)
      ..x += radius * cos(angle) * offset
      ..y += radius * sin(angle) * offset;
    return _oneTimePosition;
  }

  late final SpawnComponent gun = SpawnComponent(
    multiFactory: (int i) => _bullets(),
    selfPositioning: true,
    period: 0.15,
  );

  List<PositionComponent> _bullets() {
    final List<PositionComponent> out = <PositionComponent>[
      RecycledBullet(
        position: position,
        velocity: _fBulletVelocity(),
        radius: radius * 0.25,
      ),
    ];
    if (_withMultiGun) {
      out
        ..add(
          RecycledBullet(
            position: _fBulletPosition(0.5),
            velocity: _fBulletVelocity(),
            radius: radius * 0.25,
          ),
        )
        ..add(
          RecycledBullet(
            position: _fBulletPosition(-0.5),
            velocity: _fBulletVelocity(),
            radius: radius * 0.25,
          ),
        );
    }
    return out;
  }

  void accel(bool on) {
    if (on) {
      accelerating = true;
      current = CharacterState.accelerating;
    } else {
      accelerating = false;
      current = CharacterState.normal;
    }
  }

  @override
  void setSize(double h) {
    if (radius != h) {
      world.space.updateAllRockOpacities();
    }
    super.setSize(h);
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
    hitBox.collisionType = CollisionType.inactive;
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      hitBox.collisionType = CollisionType.active;
    });
  }

  bool _withMultiGun = false;
  void _addMultiGun() {
    _withMultiGun = true;
    _multiGunTimer
      ..reset()
      ..start();
  }

  void _removeMultiGun() {
    _withMultiGun = false;
    _multiGunTimer.pause();
  }

  @override
  Future<Map<CharacterState, SpriteAnimation>> getAnimations([
    int size = 1,
  ]) async {
    return <CharacterState, SpriteAnimation>{
      CharacterState.normal: SpriteAnimation.spriteList(<Sprite>[
        await game.loadSprite("ship.png"),
      ], stepTime: double.infinity),
      CharacterState.accelerating: SpriteAnimation.spriteList(<Sprite>[
        await game.loadSprite('ship_flame.png'),
      ], stepTime: double.infinity),
    };
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    animations = await getAnimations(100); //FIXME
    current = CharacterState.normal;
    hitBox.collisionType = CollisionType.active;
    world.space.bullets.add(gun);
    reset();
  }

  @override
  void reset() {
    super.reset();
    position = Vector2(0, 0);
    bringBallToSprite();
    //velocity.setAll(0); //FIXME
    setHealth(1);
  }

  @override
  Future<void> update(double dt) async {
    angle = -atan2(world.downDirection.x, world.downDirection.y);
    if (accelerating) {
      acceleration
        ..setFrom(world.downDirection)
        ..scale(-radius); //* 1.4
    } else {
      acceleration.setAll(0);
    }
    _multiGunTimer.update(dt);
    if (_multiGunTimer.finished) {
      _removeMultiGun();
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
    } else if (other is WallRectangleVisual) {
      velocity.scale(-1);
    } else if (other is Cherry) {
      _addMultiGun();
      other.removeFromParent();
    }
  }
}
