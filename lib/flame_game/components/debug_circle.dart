import 'dart:ui';

import 'package:flame/components.dart';

import '../../style/palette.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';

class DebugCircle extends CircleComponent
    with
        HasWorldReference<PacmanWorld>,
        HasGameReference<PacmanGame>,
        IgnoreEvents {
  DebugCircle({required this.type})
    : super(
        paint: Paint()..color = Palette.warning.color,
        radius: 1,
        position: Vector2(0, 0),
        anchor: Anchor.center,
      );

  @override
  int priority = -10000;

  String type;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (type == "mapped") {
      paint = Paint()..color = Palette.warning.color;
    } else if (type == "full") {
      paint = Paint()..color = Palette.dull.color;
    } else if (type == "visiblePlus") {
      paint = Paint()..color = Palette.background.color;
    } else {
      paint = Paint()..color = Palette.pacman.color;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (type == "mapped") {
      scale.setAll(world.space.mappedUniverseRadius);
    } else if (type == "full") {
      scale.setAll(world.space.fullUniverseRadius);
    } else if (type == "visiblePlus") {
      scale.setAll(world.space.visiblePlusUniverseRadius);
    } else {
      scale.setAll(world.space.visibleUniverseRadius);
    }
    position = world.space.ship.position;
  }
}
