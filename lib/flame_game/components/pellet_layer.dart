import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../pacman_game.dart';
import 'base_component.dart';

/// A container component that manages and renders all pellets in the maze.
class PelletWrapper extends BaseComponent
    with HasGameReference<PacmanGame>, Snapshot {
  @override
  final int priority = -2;

  /// Indicates if the player has collected all pellets (win condition).
  bool get winState =>
      ((!kDebugMode || isMounted) && pelletsRemainingNotifier.value <= 0);

  /// Tracks the total number of pellets remaining in the maze.
  final ValueNotifier<int> pelletsRemainingNotifier = ValueNotifier<int>(0);

  @override
  Future<void> reset() async {}

  @override
  Future<void> onLoad() async {
    super.onLoad();
    pelletsRemainingNotifier.addListener(() {
      assert(!isRemoving);
      clearSnapshot();
    });
    await reset();
    renderSnapshot = true;
  }

  @override
  void updateTree(double dt) {
    // no point traversing large list of children as nothing to update
    // so cut short the updateTree here
    //super.updateTree(dt);
  }
}
