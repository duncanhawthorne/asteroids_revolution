import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../style/palette.dart';
import 'space_body.dart';

final Paint _alienPaint = Paint()..color = Palette.warning.color;
final Paint _alienCorePaint = Paint()..color = Palette.dull.color;

class Alien extends SpaceBody {
  Alien({
    required super.position,
    required super.velocity,
    required super.radius,
  }) : super(paint: _alienPaint, priority: 100);

  late final CircleComponent hole = CircleComponent(
      radius: 0,
      anchor: Anchor.center,
      paint: _alienCorePaint,
      position: Vector2.all(radius));

  @override
  // ignore: overridden_fields
  final friction = 0.98;

  @override
  // ignore: overridden_fields
  final canAccelerate = true;

  @override
  void damage(double d) {
    super.damage(d);
    health -= d;
    hole.radius = radius * (1 - health).clamp(0, 0.95);
    if (health <= 0) {
      removeFromParent();
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(hole);
    hitbox.collisionType = CollisionType.passive;
  }

  final Vector2 _oneTimeGoal = Vector2(0, 0);
  @override
  Future<void> update(double dt) async {
    super.update(dt);
    _oneTimeGoal
      ..x = ship.position.x - position.x
      ..y = ship.position.y - position.y;
    double oneTimeGoalLength = _oneTimeGoal.length;
    acceleration.setFrom(_oneTimeGoal);
    acceleration.scale(1 / oneTimeGoalLength * 5 * radius);
  }
}
