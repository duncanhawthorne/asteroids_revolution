import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../style/palette.dart';
import '../icons/stub_sprites.dart';
import '../maze.dart';
import 'alien_bomb.dart';
import 'gun.dart';
import 'heart.dart';
import 'rock.dart';
import 'space_body.dart';
import 'space_layer.dart';
import 'triple.dart';

final double neutralShipRadius = maze.spriteWidth / 2 * 0.4 * 2;

double defaultShipRadius = neutralShipRadius / 18 * (kDebugMode ? 6 : 1);

final Paint _shipOverridePaint =
    Paint()
      ..colorFilter = ColorFilter.mode(Palette.seed.color, BlendMode.modulate);

class Ship extends SpaceBody with CollisionCallbacks, Gun {
  Ship({required super.position, required super.velocity})
    : super(radius: defaultShipRadius, paint: _shipOverridePaint);

  bool accelerating = false;
  @override
  // ignore: overridden_fields
  double friction = 0.98;

  @override
  // ignore: overridden_fields
  final bool canAccelerate = true;

  bool _invincibleFrames = false;

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
    d = d.clamp(-100, 0.8);
    setHealth(health * (1 - d));
    if (d > 0) {
      world.space.addSmallRocksOnDamage();
    }

    if (d > 0) {
      _invincibleFrames = true;
      Future<void>.delayed(const Duration(milliseconds: 250), () {
        _invincibleFrames = false;
      });
    }
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
    reset();
  }

  @override
  void reset() {
    super.reset();
    connectedToBall = false; //as on first run, ball not yet created
    velocity = Vector2(0, 0);
    connectedToBall = true; //as on first run, ball not yet created
    position = Vector2(0, 0);
    bringBallToSprite();
    setHealth(1);
  }

  @override
  void update(double dt) {
    angle = -atan2(world.downDirection.x, world.downDirection.y);
    if (accelerating) {
      acceleration
        ..setFrom(world.downDirection)
        ..scale(-radius); //* 1.4
    } else {
      acceleration.setAll(0);
    }
    super.update(dt);
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    onCollideWith(other as SpaceBody);
  }

  @override
  void onCollideWith(SpaceBody other) {
    if (!contactActionsEnabled) {
      return;
    }
    if (other is Rock) {
      if (!other.isSmall) {
        if (!_invincibleFrames) {
          damage(0.05 * other.radius / radius);
        }
        other.damage(4 * radius / other.radius);
      }
    } else if (other is AlienBomb) {
      damage(0.75 * other.radius / radius); //huge
      other.damage(1); //destroy
    } else if (other is Heart) {
      other.removeFromParent();
      damage(-0.2 * other.radius / radius);
    } else if (other is Triple) {
      addMultiGun();
      other.removeFromParent();
    }
  }
}
