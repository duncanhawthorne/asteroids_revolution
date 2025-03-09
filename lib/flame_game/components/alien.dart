import 'dart:ui';

import '../../style/palette.dart';
import 'game_character.dart';
import 'space_body.dart';

final Paint _alienPaint = Paint()..color = Palette.warning.color;

class Alien extends SpaceBody {
  Alien({
    required super.position,
    required super.velocity,
    required super.radius,
  }) : super(paint: _alienPaint);

  @override
  // ignore: overridden_fields
  String defaultSpritePath = "alien.png";

  @override
  // ignore: overridden_fields
  String? overlaySpritePath = "alien_overlay.png";

  @override
  // ignore: overridden_fields
  final double friction = 0.98;

  @override
  // ignore: overridden_fields
  final bool canAccelerate = true;

  @override
  void setHealth(double h) {
    super.setHealth(h);
    if (health <= 0) {
      removeFromParent();
    }
  }

  @override
  void damage(double d) {
    super.damage(d);
    setHealth(health - d);
  }

  @override
  Future<void> update(double dt) async {
    await super.update(dt);
    GameCharacter.reusableVector
      ..setFrom(ship.position)
      ..sub(position);
    final double distanceToShip = GameCharacter.reusableVector.length;
    acceleration
      ..setFrom(GameCharacter.reusableVector)
      ..scale(1 / distanceToShip * 5 * radius);
  }
}
