import 'dart:ui';

import '../../style/palette.dart';
import 'game_character.dart';
import 'overlay_sprite.dart';
import 'space_body.dart';

final Paint _alienOverridePaint =
    Paint()
      //.color = Palette.seed.color
      ..colorFilter = ColorFilter.mode(
        Palette.warning.color,
        BlendMode.modulate,
      );

class Alien extends SpaceBody with OverlaySprite {
  Alien({
    required super.position,
    required super.velocity,
    required super.radius,
  }) : super(paint: _alienOverridePaint);

  @override
  // ignore: overridden_fields
  String defaultSpritePath = "ship.png";

  @override
  // ignore: overridden_fields
  String? overlaySpritePath = "ship.png";

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
  Future<void> onLoad() async {
    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    GameCharacter.reusableVector
      ..setFrom(ship.position)
      ..sub(position);
    final double distanceToShip = GameCharacter.reusableVector.length;
    acceleration
      ..setFrom(GameCharacter.reusableVector)
      ..scale(1 / distanceToShip * 5 * radius);
    angle = north.angleToSigned(
      GameCharacter.reusableVector
        ..setFrom(position)
        ..sub(world.space.ship.position),
    );
  }
}
