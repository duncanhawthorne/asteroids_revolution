import 'dart:ui';

import 'package:flame_forge2d/body_component.dart';

import '../../utils/constants.dart';
import '../pacman_game.dart';
import 'physics_ball.dart';

/// Mixin to handle coordinate scaling when rendering physics bodies.
mixin ScaledBodyRender on BodyComponent<PacmanGame> {
  @override
  void render(Canvas canvas) {
    if (kPhysicsScaleLockedAtOne) {
      super.render(canvas);
      return;
    }

    canvas
      ..save()
      ..rotate(-body.angle)
      ..translate(-position.x, -position.y)
      ..scale(invPhysicsScale)
      ..translate(position.x, position.y)
      ..rotate(body.angle);
    super.render(canvas);
    canvas.restore();

    // ignore: dead_code
    if (drawDebugBoxes && false) {
      super.render(canvas);
    }
  }
}
