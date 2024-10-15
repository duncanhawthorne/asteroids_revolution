import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../pacman_game.dart';
import '../pacman_world.dart';
import 'wrapper_no_events.dart';

/// Use wrappers to minimise number of components directly in main world
/// Helps due to loops running through all child components
/// Especially on drag events deliverAtPoint
/// Also set IgnoreEvents to speed up deliverAtPoint for all components queried

class PelletWrapper extends WrapperNoEvents
    with HasWorldReference<PacmanWorld>, HasGameReference<PacmanGame> {
  @override
  final int priority = -2;

  final ValueNotifier<int> pelletsRemainingNotifier = ValueNotifier<int>(1);

  @override
  void reset() {}

  @override
  Future<void> onLoad() async {
    super.onLoad();
    reset();
  }
}
