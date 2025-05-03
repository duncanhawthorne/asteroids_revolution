import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../style/palette.dart';
import 'alien.dart';
import 'gun.dart';

final Paint _alienGunOverridePaint =
    Paint()
      ..colorFilter = ColorFilter.mode(
        Palette.alienGun.color,
        BlendMode.modulate,
      );

class AlienGun extends Alien with Gun {
  AlienGun({
    required super.position,
    required super.velocity,
    required super.radius,
  }) : super(paint: _alienGunOverridePaint);

  static const int limit = kDebugMode ? 2 : 2;
}
