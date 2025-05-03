import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../style/palette.dart';
import 'alien.dart';

final Paint _alienBombOverridePaint =
    Paint()
      ..colorFilter = ColorFilter.mode(
        Palette.alienBomb.color,
        BlendMode.modulate,
      );

class AlienBomb extends Alien {
  AlienBomb({
    required super.position,
    required super.velocity,
    required super.radius,
  }) : super(paint: _alienBombOverridePaint);

  static const int limit = kDebugMode ? 0 : 1;
}
