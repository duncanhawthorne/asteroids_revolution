import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import 'bullet.dart';
import 'game_character.dart';
import 'ship.dart';

const double greyThreshold = 0.5;
const double transpThreshold = 0.5 * 0.2;

class SpaceBody extends GameCharacter with IgnoreEvents {
  SpaceBody({
    required super.position,
    required super.velocity,
    required super.radius,
    super.paint,
  });

  double health = 1;
  final bool cleanIfTiny = true;
  bool ensureVelocityTowardsCenter = false;

  Ship get ship => world.space.ship;

  bool get isSmall => radius < ship.radius * greyThreshold;

  bool get isTiny => radius < ship.radius * transpThreshold;

  void fixVelocityTowardsCenter() {
    GameCharacter.reusableVector.setFrom(velocity);
    if (GameCharacter.reusableVector.x.sign ==
        (position.x - ship.position.x).sign) {
      GameCharacter.reusableVector.x *= -1;
    }
    if (velocity.y.sign == (position.y - ship.position.y).sign) {
      GameCharacter.reusableVector.y *= -1;
    }
    velocity = GameCharacter.reusableVector;
  }

  bool isOutsideVisiblePlusUniverseCache = false;

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
    super.onMount();
    if (ensureVelocityTowardsCenter) {
      fixVelocityTowardsCenter();
    }
    setHealth(1);
    add(hitBox);
    setSize(radius); //FIXME fixes hitboxes
    distanceFromShipCache = 0;
    isOutsideVisiblePlusUniverseCache = false;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    reset();
  }

  double distanceFromShipCache = 0;

  void tidy() {
    distanceFromShipCache = position.distanceTo(ship.position);
    isOutsideVisiblePlusUniverseCache =
        distanceFromShipCache > world.space.visiblePlusUniverseRadius + radius;

    if (cleanIfTiny) {
      if (isTiny) {
        removeFromParent();
      }
    }
    if (distanceFromShipCache > world.space.fullUniverseRadius) {
      removeFromParent();
    }
  }

  void resetSpriteVsPhysicsScale() {
    bringBallToSprite();
  }

  void setUpdateMode() {
    if (isOutsideVisiblePlusUniverseCache) {
      if (connectedToBall && this is! Bullet) {
        disconnectFromBall();
      }
    } else {
      if (possiblePhysicsConnection && !connectedToBall) {
        bringBallToSprite();
      }
    }
  }

  double _dtCache = 0;
  @override
  void updateTree(double dt) {
    if (isOutsideVisiblePlusUniverseCache && !connectedToBall) {
      bool oneFrameDue = true;
      if (_dtCache < 1) {
        _dtCache += dt;
        oneFrameDue = false;
      } else {
        dt = _dtCache;
        _dtCache = 0;
      }
      if (oneFrameDue) {
        super.updateTree(dt);
      }
    } else {
      _dtCache = 0;
      super.updateTree(dt);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (health <= -1 && !isRemoving) {
      removeFromParent();
    }
    setUpdateMode();

    if (!connectedToBall) {
      if (canAccelerate) {
        velocity.addScaled(acceleration, dt);
      }
      if (friction != 1) {
        velocity.scale(friction);
      }
      position.addScaled(velocity, dt);
    } else {
      oneFrameOfPhysics(dt);
    }
    distanceFromShipCache = position.distanceTo(ship.position);
  }

  void onCollideWith(SpaceBody other) {}

  void onContactWith(SpaceBody other) {}
}
