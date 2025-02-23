import 'dart:ui';

import 'package:flame/components.dart';

import '../../style/palette.dart';

final Paint _spaceDotPaint = Paint()..color = Palette.dotsColor;

class SpaceDot extends CircleComponent with IgnoreEvents {
  SpaceDot({
    required super.position,
    required double width,
    required double height,
  }) : super(radius: width / 2, anchor: Anchor.center, paint: _spaceDotPaint);
}
