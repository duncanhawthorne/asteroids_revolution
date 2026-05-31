import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

/// An effect that does nothing for a specified duration, useful for timing sequences.
class NullEffect extends RotateEffect {
  NullEffect(int durationMillis, {Function()? super.onComplete})
    : super.by(
        0,
        EffectController(
          duration: durationMillis / 1000,
          curve: Curves.easeOut,
        ),
      );
}
