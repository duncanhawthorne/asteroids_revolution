import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'alien_bomb.dart';
import 'alien_gun.dart';
import 'rock.dart';
import 'ship.dart';
import 'space_body.dart';

final Vector2 _offscreen = Vector2(1000, 1000);

class Bullet extends SpaceBody with CollisionCallbacks {
  Bullet({
    required super.position,
    required super.velocity,
    required super.radius,
    required super.paint,
    super.density = 0.001,
  });

  @override
  // ignore: overridden_fields
  final bool connectedToBall = true;

  @override
  // ignore: overridden_fields
  final bool possiblePhysicsConnection = true;

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
    onCollideWith(other as SpaceBody);
  }

  @override
  void onCollideWith(SpaceBody other) {
    if (other is Rock) {
      other.damage(4 * radius / other.radius);
      position = _offscreen; //stop repeat hits
      removeFromParent();
    } else if (other is AlienBomb) {
      other.damage(0.05 * radius / other.radius);
      position = _offscreen; //stop repeat hits
      removeFromParent();
    } else if (other is AlienGun) {
      other.damage(1);
      position = _offscreen; //stop repeat hits
      removeFromParent();
    } else if (other is Ship) {
      other.damage(0.01 * radius / other.radius);
      position = _offscreen; //stop repeat hits
      removeFromParent();
    }
  }
}
