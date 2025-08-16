import 'package:flutter/material.dart';

import '../../style/palette.dart';
import 'space_body.dart';

final Paint _tripleOverridePaint = Paint()
  //.color = Palette.seed.color
  ..colorFilter = ColorFilter.mode(Palette.seed.color, BlendMode.modulate);

class Triple extends SpaceBody {
  Triple({
    required super.position,
    required super.velocity,
    this.ensureVelocityTowardsCenter = true,
    required super.radius,
  }) : super(paint: _tripleOverridePaint);

  static const int limit = 4;

  @override
  // ignore: overridden_fields
  String defaultSpritePath = "triple.png";

  @override
  // ignore: overridden_fields
  bool ensureVelocityTowardsCenter;
}
