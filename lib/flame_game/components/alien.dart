import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../style/palette.dart';
import 'asteroids_layer.dart';
import 'space_body.dart';

class Alien extends SpaceBody {
  Alien({
    required super.position,
    required super.velocity,
    required super.radius,
  }) : super(paint: Paint()..color = Palette.warning.color, priority: 100);

  late final CircleComponent hole = CircleComponent(
      radius: 0,
      anchor: Anchor.center,
      paint: Paint()..color = Palette.dull.color,
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

  void updateOpacity() {
    if (isTiny) {
      removeFromParent();
      return;
    }
    if (radius > ship.radius * greyThreshold) {
      opacity = 1;
    } else {
      double rFactor = radius / ship.radius;
      double n25 = transpThreshold / greyThreshold;
      opacity = ((rFactor - n25) / (1 - n25)).clamp(0, 1);
    }
    hole.opacity = opacity;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(hole);
    updateOpacity();
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
