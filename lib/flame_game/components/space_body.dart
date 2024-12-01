import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../pacman_game.dart';
import '../pacman_world.dart';
import 'ship.dart';

const double greyThreshold = 0.5;
const double transpThreshold = 0.5 * 0.2;

class SpaceBody extends CircleComponent
    with
        HasWorldReference<PacmanWorld>,
        HasGameReference<PacmanGame>,
        IgnoreEvents {
  SpaceBody({
    required super.position,
    required Vector2 velocity,
    required super.radius,
    super.paint,
  }) : super(anchor: Anchor.center) {
    this.velocity.setFrom(velocity);
  }

  late final CircleHitbox hitBox = CircleHitbox(
    isSolid: true,
    collisionType: CollisionType.passive,
    anchor: Anchor.center,
  );

  final Vector2 velocity = Vector2(0, 0);
  final Vector2 acceleration = Vector2(0, 0);
  double friction = 1;
  double health = 1;
  final bool cleanIfTiny = true;
  bool ensureVelocityTowardsCenter = false;
  final bool canAccelerate = false;
  bool isActive = true; //do not in spareBits

  Ship get ship => world.space.ship;

  bool get isSmall => radius < ship.radius * greyThreshold;

  bool get isTiny => radius < ship.radius * transpThreshold;

  void fixVelocityTowardsCenter() {
    if (velocity.x.sign == (position.x - ship.position.x).sign) {
      velocity.x = -velocity.x;
    }
    if (velocity.y.sign == (position.y - ship.position.y).sign) {
      velocity.y = -velocity.y;
    }
  }

  bool get isOutsideFullUniverse => world.space.isOutsideFullUniverse(position);
  bool get isOutsideMappedUniverse =>
      world.space.isOutsideMappedUniverse(position);

  @mustCallSuper
  void setSize(double h) {
    radius = h;
    hitBox.position.setAll(radius);
    hitBox.radius = radius;
  }

  @mustCallSuper
  void setHealth(double h) {
    health = h;
  }

  @mustCallSuper
  void damage(double d) {}

  @mustCallSuper
  void reset() {}

  @override
  Future<void> onMount() async {
    isActive = true; //already set sync but set here anyway
    super.onMount();
    if (ensureVelocityTowardsCenter) {
      fixVelocityTowardsCenter();
    }
    setHealth(1);
    add(hitBox);
    setSize(radius); //FIXME fixes hitboxes
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    reset();
  }

  void tidy() {
    if (cleanIfTiny) {
      if (isTiny) {
        removeFromParent();
      }
    }
    if (isOutsideFullUniverse) {
      removeFromParent();
    }
  }

  @override
  Future<void> update(double dt) async {
    super.update(dt);
    if (canAccelerate) {
      velocity.addScaled(acceleration, dt);
    }
    if (friction != 1) {
      velocity.scale(friction);
    }
    position.addScaled(velocity, dt);
  }

  @override
  Future<void> onRemove() async {
    isActive = false;
    super.onRemove();
  }
}
