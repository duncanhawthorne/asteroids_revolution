import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'alien.dart';
import 'rock.dart';
import 'space_body.dart';
import 'space_layer.dart';

class Bullet extends SpaceBody with CollisionCallbacks {
  Bullet(
      {required super.position, required super.velocity, required super.radius})
      : super(paint: seedPaint);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    hitbox.collisionType = CollisionType.active;
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

final List<Bullet> _allBits = [];
Iterable<Bullet> get _spareBits => _allBits.where((item) => !item.isActive);

// ignore: non_constant_identifier_names
Bullet RecycledBullet({required position, required velocity, required radius}) {
  if (_spareBits.isEmpty) {
    Bullet newBit =
        Bullet(position: position, velocity: velocity, radius: radius);
    _allBits.add(newBit);
    return newBit;
  } else {
    Bullet recycledBit = _spareBits.first;
    recycledBit.isActive = true;
    assert(_spareBits.isEmpty || _spareBits.first != recycledBit);
    recycledBit.position.setFrom(position);
    recycledBit.velocity.setFrom(velocity);
    recycledBit.radius = radius;
    return recycledBit;
  }
}
