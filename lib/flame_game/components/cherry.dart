import 'package:flutter/material.dart';

import '../../style/palette.dart';
import 'space_body.dart';

final Paint _cherryOverridePaint =
    Paint()
      //.color = Palette.seed.color
      ..colorFilter = ColorFilter.mode(Palette.seed.color, BlendMode.modulate);

class Cherry extends SpaceBody {
  Cherry({
    required super.position,
    required super.velocity,
    this.ensureVelocityTowardsCenter = true,
    required super.radius,
  }) : super(paint: _cherryOverridePaint);

  @override
  // ignore: overridden_fields
  String defaultSpritePath = "triple.png";

  @override
  // ignore: overridden_fields
  bool ensureVelocityTowardsCenter;
}
