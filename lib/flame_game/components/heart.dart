import 'dart:ui';

import '../../style/palette.dart';
import 'space_body.dart';

final Paint _heartOverridePaint =
    Paint()
      //.color = Palette.seed.color
      ..colorFilter = ColorFilter.mode(Palette.seed.color, BlendMode.modulate);

class Heart extends SpaceBody {
  Heart({
    required super.position,
    required super.velocity,
    this.ensureVelocityTowardsCenter = false,
    required super.radius,
  }) : super(paint: _heartOverridePaint);

  @override
  // ignore: overridden_fields
  String defaultSpritePath = "heart.png";

  @override
  // ignore: overridden_fields
  bool ensureVelocityTowardsCenter;
}
