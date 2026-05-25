import 'dart:math';

import 'package:flame/components.dart';

import '../components/physics_ball.dart';
import '../pacman_game.dart';
import 'maze_layout.dart';
import 'maze_tiles.dart';

class MazeDimensions {
  MazeDimensions({required MazeLayout layout}) : _layout = layout;

  final MazeLayout _layout;

  late final Vector2 ghostStart = _vectorOfMazeTile(Tile.ghostStart);
  late final Vector2 pacmanStart = _vectorOfMazeTile(Tile.pacmanStart);
  late final Vector2 _cage = _vectorOfMazeTile(Tile.cage);
  late final double mazeWidth = blockWidth * _layout.lengthHBuffered;
  late final double mazeHeight = blockWidth * _layout.length;
  late final double blockWidth = _blockWidth();
  late final double spriteWidth = _spriteWidth();
  late final double cloneThreshold = mazeWidth / 2 - spriteWidth / 2;
  late final double mazeHalfWidthPhysics = mazeWidth / 2 / spriteVsPhysicsScale;
  late final double mazeHalfHeightPhysics =
      mazeHeight / 2 / spriteVsPhysicsScale;
  late final Vector2 spriteSize = Vector2.zero()..setAll(spriteWidth);
  late final Map<int, Vector2> _ghostStartForIdMap = <int, Vector2>{
    0: _ghostStartForId(0),
    1: _ghostStartForId(1),
    2: _ghostStartForId(2),
  };

  double _blockWidth() {
    return kVirtualGameSize /
        flameGameZoom /
        max(_layout.lengthHBuffered, _layout.length);
  }

  double _spriteWidth() {
    return blockWidth * 2;
  }

  Vector2 locationOfIJ(
    int icore,
    int jcore, {
    double ioffset = 0,
    double joffset = 0,
    required Vector2 output,
  }) {
    final double i = ioffset + icore;
    final double j = joffset + jcore;

    /// using _reusableVector
    /// so we don't have to make new Vector2 every time called
    /// but therefore must instantly consume the output as it may change
    assert(blockWidth != 0); //i.e. not set yet
    return output..setValues(
      (j + 1 / 2 - _layout.lengthH / 2) * blockWidth,
      (i + 1 / 2 - _layout.length / 2) * blockWidth,
    );
  }

  Vector2 _vectorOfMazeTile(Tile tile, {Vector2? output}) {
    final Vector2 out = output ?? Vector2.zero();
    final (int i, int j) = _layout.ijOfMazeTile(tile);
    return locationOfIJ(i, j, ioffset: 0.5, output: out);
  }

  Vector2 ghostStartForId(int idNum) {
    return _ghostStartForIdMap[idNum % 3]!;
  }

  Vector2 _ghostStartForId(int idNum) {
    return ghostStart.clone()..x += spriteWidth * (idNum % 3 - 1);
  }

  Vector2 ghostSpawnForId(int idNum) {
    return idNum <= 2 ? ghostStartForId(idNum) : _cage;
  }

  int spriteWidthOnScreen(Vector2 size) {
    return (spriteWidth /
            (kVirtualGameSize / flameGameZoom) *
            min(size.x, size.y))
        .toInt();
  }
}
