import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'alien.dart';
import 'rock.dart';
import 'space_body.dart';

final Vector2 _offscreen = Vector2(1000, 1000);

class Bullet extends SpaceBody with CollisionCallbacks {
  Bullet({
    required super.position,
    required super.velocity,
    required super.radius,
    required super.paint,
  });

  @override
  // ignore: overridden_fields
  final bool connectedToBall = false;

  @override
  // ignore: overridden_fields
  final bool possiblePhysicsConnection = false;

  @override
  // ignore: overridden_fields
  String defaultSpritePath = "bullet.png";

  bool isActive = true; //do not in spareBits

  @override
  Future<void> onMount() async {
    isActive = true; //already set sync but set here anyway
    await super.onMount();
  }

  @override
  void update(double dt) {
    if (position.distanceTo(ship.position) > world.space.mappedUniverseRadius) {
      //as doing collision detection on bullets
      //more efficient to test this each frame to remove asap
      removeFromParent();
    }
    super.update(dt);
  }

  @override
  Future<void> onRemove() async {
    isActive = false;
    await super.onRemove();
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
      other.damage(4 * radius / other.radius);
      position = _offscreen; //stop repeat hits
      removeFromParent();
    } else if (other is Alien) {
      other.damage(0.05 * radius / other.radius);
      position = _offscreen; //stop repeat hits
      removeFromParent();
    }
  }
}

final List<Bullet> _allBits = <Bullet>[];
Iterable<Bullet> get _spareBits =>
    _allBits.where((Bullet item) => !item.isActive);

// ignore: non_constant_identifier_names
Bullet RecycledBullet({
  required Vector2 position,
  required Vector2 velocity,
  required double radius,
  required Paint paint,
}) {
  if (_spareBits.isEmpty) {
    final Bullet newBit = Bullet(
      position: position,
      velocity: velocity,
      radius: radius,
      paint: paint,
    );
    _allBits.add(newBit);
    return newBit;
  } else {
    final Bullet recycledBit = _spareBits.first;
    // ignore: cascade_invocations
    recycledBit.isActive = true;
    assert(_spareBits.isEmpty || _spareBits.first != recycledBit);
    recycledBit.position.setFrom(position);
    recycledBit.velocity.setFrom(velocity);
    recycledBit
      ..radius = radius
      ..paint = paint;
    recycledBit.hitBox.collisionType = recycledBit.defaultCollisionType;
    return recycledBit;
  }
}
