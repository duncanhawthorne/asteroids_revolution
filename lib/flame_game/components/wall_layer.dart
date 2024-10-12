import 'package:flame/components.dart';

import '../maze.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'wrapper_no_events.dart';

class WallWrapper extends WrapperNoEvents
    with HasWorldReference<PacmanWorld>, HasGameReference<PacmanGame> {
  @override
  void reset() {
    if (children.isNotEmpty) {
      removeAll(children);
    }
    addAll(maze.mazeWalls());
    addAll(maze.spaceDots(
        scaleFactor: 0,
        positionOffset: Vector2(0, 0),
        game: game)); //FIXME scaleFactor is fudge
    addAll(maze.spaceDots(
        scaleFactor: 1, positionOffset: Vector2(0, 0), game: game));
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    reset();
  }
}
