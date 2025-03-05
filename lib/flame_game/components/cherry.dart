import 'package:flutter/material.dart';

import 'space_body.dart';

final Paint _cherryPaint = Paint()..color = Colors.purple[300]!;

class Cherry extends SpaceBody {
  Cherry({
    required super.position,
    required super.velocity,
    this.ensureVelocityTowardsCenter = true,
    required super.radius,
  }) : super(paint: _cherryPaint);

  @override
  // ignore: overridden_fields
  String defaultSpritePath = "triple.png";

  @override
  // ignore: overridden_fields
  bool ensureVelocityTowardsCenter;
}
