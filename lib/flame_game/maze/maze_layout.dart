import 'maze_data.dart';
import 'maze_tiles.dart';

/// Represents the logical grid-based layout of a maze.
class MazeLayout {
  MazeLayout(int mazeId, {required bool raceMode}) {
    _layout = MazeData.getLayout(mazeId, raceMode: raceMode);
  }

  late final List<List<Tile>> _layout;

  static const int _bufferColumns = 2;

  /// Horizontal length of the maze grid.
  int get lengthH => _layout.isEmpty ? 0 : (_layout[0].length);

  /// Horizontal length minus buffer columns.
  int get lengthHBuffered =>
      _layout.isEmpty ? 0 : (_layout[0].length - _bufferColumns);

  /// Vertical length of the maze grid.
  int get length => _layout.length;

  /// Finds the (row, column) coordinates of the first occurrence of a specific tile.
  (int, int) ijOfMazeTile(Tile tile) {
    for (int i = 0; i < _layout.length; i++) {
      for (int j = 0; j < _layout[i].length; j++) {
        if (_layout[i][j] == tile) {
          return (i, j);
        }
      }
    }
    throw 'Missing maze tile $tile';
  }

  /// Checks if there is a static wall at the specified grid coordinates.
  bool wallAt(int i, int j) {
    return i >= 0 &&
        i < _layout.length &&
        j >= 0 &&
        j < _layout[i].length &&
        _layout[i][j] == Tile.wall;
  }

  /// Checks if a wall at the specified coordinates should be rendered as a circle.
  bool circleAt(int i, int j) {
    assert(wallAt(i, j));
    return !(wallAt(i - 1, j) && wallAt(i + 1, j) ||
        wallAt(i, j - 1) && wallAt(i, j + 1));
  }

  /// Checks if there is a moving wall at the specified grid coordinates.
  bool movingWallAt(int i, int j) {
    return i >= 0 &&
        i < _layout.length &&
        j >= 0 &&
        j < _layout[i].length &&
        _layout[i][j] == Tile.movingWall;
  }

  bool _pelletTileAtCell(int i, int j) {
    final Tile char = _layout[i][j];
    return char == Tile.miniPellet ||
        char == Tile.superPellet ||
        char == Tile.movingWall;
  }

  /// Checks if a pellet (mini or super) exists at the specified grid coordinates.
  bool pelletAt(int i, int j) {
    return i >= 0 &&
        j >= 0 &&
        i + 1 < _layout.length &&
        j + 1 < _layout[0].length &&
        _pelletTileAtCell(i, j) &&
        _pelletTileAtCell(i, j + 1) &&
        _pelletTileAtCell(i + 1, j) &&
        _pelletTileAtCell(i + 1, j + 1);
  }

  /// Determines if the pellet at (i, j) is a super pellet.
  bool pelletIsSuperPellet(int i, int j) {
    assert(pelletAt(i, j));
    return _layout[i][j] == Tile.superPellet;
  }
}
