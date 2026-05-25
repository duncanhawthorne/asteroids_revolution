import 'dart:ui';

import 'package:flame_forge2d/body_component.dart';

import '../../utils/constants.dart';
import '../pacman_game.dart';
import 'physics_ball.dart';

mixin ScaledBodyRender on BodyComponent<PacmanGame> {
  @override
  void render(Canvas canvas) {
    if (spriteVsPhysicsScaleConstant) {
      super.render(canvas);
      return;
    }

    final double s = spriteVsPhysicsScale;
    canvas
      ..save()
      ..rotate(-body.angle)
      ..translate(-position.x, -position.y)
      ..scale(s)
      ..translate(position.x, position.y)
      ..rotate(body.angle);
    super.render(canvas);
    canvas.restore();

    if (drawDebugBoxes) {
      super.render(canvas);
    }
  }
}
