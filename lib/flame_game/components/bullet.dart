import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'alien.dart';
import 'rock.dart';
import 'space_body.dart';
import 'space_layer.dart';

class Bullet extends SpaceBody with CollisionCallbacks {
  Bullet({
    required super.position,
    required super.velocity,
    required super.radius,
  }) : super(paint: seedPaint);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    hitBox.collisionType = CollisionType.active;
  }

  @override
  Future<void> update(double dt) async {
    if (position.distanceTo(ship.position) > world.space.mappedUniverseRadius) {
      //as doing collision detection on bullets
      //more efficient to test this each frame to remove asap
      removeFromParent();
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
      other.damage(4 * radius / other.radius);
      removeFromParent();
    } else if (other is Alien) {
      other.damage(0.05 * radius / other.radius);
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
}) {
  if (_spareBits.isEmpty) {
    final Bullet newBit = Bullet(
      position: position,
      velocity: velocity,
      radius: radius,
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
    recycledBit.radius = radius;
    return recycledBit;
  }
}
