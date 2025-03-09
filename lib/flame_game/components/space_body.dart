import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

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
  bool isActive = true; //do not in spareBits

  bool neverRender = false;

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
    if (overlaySpritePath != null) {
      if (h == 1) {
        removeOverlaySprite();
      } else {
        addOverlaySprite();
      }
      final double holeRadius = radius * (1 - health).clamp(0, 0.9);
      overlaySprite?.size.setAll(holeRadius * 2);
    }
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

  void setUpdateMode() {
    if (isOutsideVisiblePlusUniverseCache) {
      if (connectedToBall) {
        disconnectFromBall();
      }
    } else {
      if (possiblePhysicsConnection && !connectedToBall) {
        bringBallToSprite();
      }
    }
  }

  double dtCache = 0;
  @override
  Future<void> update(double dt) async {
    super.update(dt);
    setUpdateMode();

    bool oneFrameDue = true;
    if (!connectedToBall) {
      if (isOutsideVisiblePlusUniverseCache) {
        if (dtCache < 1) {
          dtCache += dt;
          oneFrameDue = false;
        } else {
          dt = dtCache;
          dtCache = 0;
        }
      }
      if (oneFrameDue) {
        if (canAccelerate) {
          velocity.addScaled(acceleration, dt);
        }
        if (friction != 1) {
          velocity.scale(friction);
        }
        position.addScaled(velocity, dt);
      }
    } else {
      oneFrameOfPhysics(dt);
    }
    if (oneFrameDue) {
      distanceFromShipCache = position.distanceTo(ship.position);
    }
  }

  @override
  Future<void> onRemove() async {
    isActive = false;
    await super.onRemove();
  }
}
