import 'package:flutter/material.dart';

import 'space_body.dart';

class Cherry extends SpaceBody {
  Cherry({
    required super.position,
    required super.velocity,
    this.ensureVelocityTowardsCenter = true,
    required super.radius,
  }) : super(paint: Paint()..color = Colors.purple[300]!);
  /*
  @override
  // ignore: overridden_fields
  final debugMode = true;
   */

  @override
  // ignore: overridden_fields
  bool ensureVelocityTowardsCenter;
}
