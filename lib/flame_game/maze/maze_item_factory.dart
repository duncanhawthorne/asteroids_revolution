import 'package:flame/components.dart';

import '../components/wall_visual.dart';
import 'maze_dimensions.dart';
import 'maze_layout.dart';

/// Factory for creating visual components and positions for maze items.
class MazeItemFactory {
  MazeItemFactory({
    required MazeLayout layout,
    required MazeDimensions dimensions,
  }) : _layout = layout,
       _dimensions = dimensions;

  final MazeLayout _layout;
  final MazeDimensions _dimensions;

  /// Creates visual boundaries for the edges of the maze.
  List<Component> blockingWalls() {
    final List<Component> result = <Component>[];
    final double scale = _dimensions.blockWidth;
    const int width = 7;
    final Vector2 size = Vector2(scale * width, scale * _layout.length);
    final Vector2 position = Vector2(
      scale * (_layout.lengthHBuffered / 2 + width / 2),
      0,
    );

    /// [position] safely instantly consumed by [WallRectangleVisual]
    result
      ..add(WallRectangleVisual(position: position, size: size))
      ..add(WallRectangleVisual(position: position..x *= -1, size: size));
    return result;
  }

  /// Generates world positions for all mini pellets.
  Iterable<Vector2> miniPelletPositions(bool superPelletsEnabled) sync* {
    /// [center] safely instantly consumed by receiving function
    final Vector2 center = Vector2.zero();
    for (int i = 0; i < _layout.length; i++) {
      for (int j = 0; j < _layout.lengthH; j++) {
        if (_layout.pelletAt(i, j)) {
          final bool isSuperPellet = _layout.pelletIsSuperPellet(i, j);
          if (!isSuperPellet || !superPelletsEnabled) {
            _dimensions.locationOfIJ(
              i,
              j,
              ioffset: 0.5,
              joffset: 0.5,
              output: center,
            );
            yield center;
          }
        }
      }
    }
  }

  /// Generates world positions for all super pellets.
  Iterable<Vector2> superPelletPositions() sync* {
    /// [center] safely instantly consumed by receiving function
    final Vector2 center = Vector2.zero();
    for (int i = 0; i < _layout.length; i++) {
      for (int j = 0; j < _layout.lengthH; j++) {
        if (_layout.pelletAt(i, j) && _layout.pelletIsSuperPellet(i, j)) {
          _dimensions.locationOfIJ(
            i,
            j,
            ioffset: 0.5,
            joffset: 0.5,
            output: center,
          );
          yield center;
        }
      }
    }
  }
}
