import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/geometry.dart';
import 'package:flutter/foundation.dart';

import '../icons/stub_sprites.dart';
import '../maze.dart';
import '../pacman_game.dart';
import 'alien.dart';
import 'bullet.dart';
import 'cherry.dart';
import 'heart.dart';
import 'rock.dart';
import 'space_body.dart';
import 'wall.dart';

final double neutralShipRadius =
    maze.spriteWidth / 2 * Maze.pelletScaleFactor * 2;

double defaultShipRadius = neutralShipRadius / 18;

class Ship extends SpaceBody with CollisionCallbacks {
  Ship({required super.position, required super.velocity})
      : super(radius: defaultShipRadius);

  @override
  // ignore: overridden_fields
  bool renderShape = false;

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

  bool lastAccelerating = false;
  void accel(bool on) {
    if (on) {
      accelerating = true;
      shipSprite.current = CharacterState.accelerating;
    } else {
      accelerating = false;
      shipSprite.current = CharacterState.normal;
    }
    lastAccelerating = accelerating;
  }

  @override
  void setSize(double h) {
    if (radius != h) {
      world.space.updateAllRockOpacities();
    }
    super.setSize(h);
    shipSprite.position.setAll(radius);
    shipSprite.size.setAll(radius * 2);
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

  ShipSpriteComponent shipSprite = ShipSpriteComponent();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    hitbox.collisionType = CollisionType.active;
    world.space.bullets.add(gun);
    add(shipSprite);
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
      acceleration
        ..setFrom(world.direction)
        ..scale(-radius); //* 1.4
    } else {
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

class ShipSpriteComponent extends SpriteAnimationGroupComponent<CharacterState>
    with HasGameReference<PacmanGame>, IgnoreEvents {
  ShipSpriteComponent({super.position, super.priority = 1})
      : super(anchor: Anchor.center);

  void loadStubAnimationsOnDebugMode() {
    // works around changes made in flame 1.19
    // where animations have to be loaded before can set current
    // only fails due to assert, which is only tested in debug mode
    // so if in debug mode, quickly load up stub animations first
    // https://github.com/flame-engine/flame/pull/3258
    if (kDebugMode) {
      animations = stubSprites.stubAnimation;
    }
  }

  Future<Map<CharacterState, SpriteAnimation>?> getAnimations() async {
    return <CharacterState, SpriteAnimation>{
      CharacterState.normal: SpriteAnimation.spriteList(
        <Sprite>[await game.loadSprite("ship.png")],
        stepTime: double.infinity,
      ),
      CharacterState.accelerating: SpriteAnimation.spriteList(
        <Sprite>[await game.loadSprite('ship_flame.png')],
        stepTime: double.infinity,
      ),
    };
  }

  @override
  Future<void> onLoad() async {
    loadStubAnimationsOnDebugMode();
    animations = await getAnimations();
    angle = -tau / 4;
  }
}
