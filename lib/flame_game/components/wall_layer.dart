import 'dart:async';

import 'package:flame/components.dart';

import '../maze/maze.dart';
import '../pacman_game.dart';
import 'base_component.dart';

/// A container component that manages and renders all static walls in the maze.
class WallWrapper extends BaseComponent
    with HasGameReference<PacmanGame>, Snapshot {
  int _mazeIdLast = -100;

  @override
  int priority = -99;

  @override
  Future<void> reset() async {
    if (maze.mazeId == _mazeIdLast) {
      return;
    }
    _mazeIdLast = maze.mazeId;
    if (children.isNotEmpty) {
      removeAll(children);
    }
    await addAll(maze.physicsFactory.walls(includeGround: false));
    clearSnapshot();
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    await reset();
  }

  @override
  void updateTree(double dt) {
    // no point traversing large list of children as nothing to update
    // so cut short the updateTree here
    //super.updateTree(dt);
  }
}
