import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../maze.dart';
import '../pacman_world.dart';

class Pellet extends CircleComponent
    with HasWorldReference<PacmanWorld>, IgnoreEvents {
  Pellet(
      {required super.position,
      double radiusFactor = 1,
      this.hitBoxRadiusFactor = 1})
      : super(
            radius:
                maze.spriteWidth / 2 * Maze.pelletScaleFactor * radiusFactor,
            anchor: Anchor.center);

  double hitBoxRadiusFactor;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox(
      isSolid: true,
      collisionType: CollisionType.active,
      radius: radius * hitBoxRadiusFactor,
      position: Vector2.all(radius),
      anchor: Anchor.center,
    ));
    //debugMode = true;
  }
}
