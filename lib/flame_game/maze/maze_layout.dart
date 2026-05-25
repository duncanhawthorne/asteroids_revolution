import 'maze_data.dart';
import 'maze_tiles.dart';

class MazeLayout {
  MazeLayout(int mazeId, {required bool raceMode}) {
    _layout = MazeData.getLayout(mazeId, raceMode: raceMode);
  }

  late final List<List<Tile>> _layout;

  static const int _bufferColumns = 2;

  int get lengthH => _layout.isEmpty ? 0 : (_layout[0].length);

  int get lengthHBuffered =>
      _layout.isEmpty ? 0 : (_layout[0].length - _bufferColumns);

  int get length => _layout.length;

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

  bool wallAt(int i, int j) {
    return i >= 0 &&
        i < _layout.length &&
        j >= 0 &&
        j < _layout[i].length &&
        _layout[i][j] == Tile.wall;
  }

  bool circleAt(int i, int j) {
    assert(wallAt(i, j));
    return !(wallAt(i - 1, j) && wallAt(i + 1, j) ||
        wallAt(i, j - 1) && wallAt(i, j + 1));
  }

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

  bool pelletIsSuperPellet(int i, int j) {
    assert(pelletAt(i, j));
    return _layout[i][j] == Tile.superPellet;
  }
}
