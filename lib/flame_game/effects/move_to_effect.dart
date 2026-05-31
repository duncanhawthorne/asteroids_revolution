import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

const int kResetPositionTimeMillis = 1000;

/// An effect that moves a component to a target position over a set duration.
class MoveToPositionEffect extends MoveToEffect {
  MoveToPositionEffect(
    Vector2 destination, {
    Function()? super.onComplete,
    double duration = kResetPositionTimeMillis / 1000,
  }) : super(
         destination,
         EffectController(duration: duration, curve: Curves.easeOut),
       );
}
