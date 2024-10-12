import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/cupertino.dart';

import '../pacman_game.dart';
import '../pacman_world.dart';
import 'asteroids_layer.dart';
import 'ship.dart';

class SpaceBody extends CircleComponent
    with
        HasWorldReference<PacmanWorld>,
        HasGameReference<PacmanGame>,
        IgnoreEvents {
  SpaceBody({
    required super.position,
    required velocity,
    required super.radius,
    super.paint,
    super.priority = 1,
  }) : super(anchor: Anchor.center) {
    this.velocity.setFrom(velocity);
  }

  late final CircleHitbox hitbox = CircleHitbox(
    isSolid: true,
    collisionType: CollisionType.passive,
    anchor: Anchor.center,
  );

  final Vector2 velocity = Vector2(0, 0);
  final Vector2 acceleration = Vector2(0, 0);
  double friction = 1;
  double health = 1;
  bool everOnScreen = false;
  final cleanBasedOnBeingEverOnScreen = true;
  final cleanIfTiny = true;
  bool ensureVelocityTowardsCenter = false;
  final bool canAccelerate = false;
  bool isActive = true; //do not in spareBits

  Ship get ship => world.asteroidsWrapper.ship;

  bool get isSmall => radius < ship.radius * greyThreshold;

  bool get isTiny => radius < ship.radius * transpThreshold;

  fixVelocityTowardsCenter() {
    if (velocity.x.sign == (position - ship.position).x.sign) {
      velocity.x = -velocity.x;
    }
    if (velocity.y.sign == (position - ship.position).y.sign) {
      velocity.y = -velocity.y;
    }
  }

  bool get isOutsideKnownWorld =>
      world.asteroidsWrapper.isOutsideKnownWorld(position);

  bool get isVeryOutsideKnownWorld =>
      world.asteroidsWrapper.isVeryOutsideKnownWorld(position);

  @mustCallSuper
  void setSize(double h) {
    radius = h;
    hitbox.position.setAll(radius);
    hitbox.radius = radius;
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
    everOnScreen = false; //reset this
    super.onMount();
    if (ensureVelocityTowardsCenter) {
      fixVelocityTowardsCenter();
    }
    setHealth(1);
    add(hitbox);
    setSize(radius); //FIXME fixes hitboxes
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    reset();
  }

  void tidy() async {
    if (cleanIfTiny) {
      if (isTiny) {
        removeFromParent();
      }
    }
    if (cleanBasedOnBeingEverOnScreen) {
      if (!everOnScreen && !isOutsideKnownWorld) {
        everOnScreen = true;
      }
      if (everOnScreen && isOutsideKnownWorld) {
        removeFromParent();
      }
    }
    if (isVeryOutsideKnownWorld) {
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
