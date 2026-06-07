import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../components/physics_ball.dart';
import '../components/wall_visual.dart';
import 'maze_dimensions.dart';
import 'maze_layout.dart';

/// Factory for creating physical bodies and fixtures for the maze walls.
class MazePhysicsFactory {
  MazePhysicsFactory({
    required MazeLayout layout,
    required MazeDimensions dimensions,
  }) : _layout = layout,
       _dimensions = dimensions;

  final MazeLayout _layout;
  final MazeDimensions _dimensions;

  static const double _mazeInnerWallWidthFactor = 0.7;
  static const double _pixelationBuffer = 0.03;

  static final Vector2 _reusableVector = Vector2.zero();

  FixtureDef _fixtureDefBlock({
    required Vector2 position,
    required double width,
    required double height,
    double density = 1,
  }) {
    /// [_reusableVector] safely instantly consumed inside FixtureDef
    return FixtureDef(
      friction: openSpaceMovement ? 1 : 0,
      restitution: openSpaceMovement ? 0.4 : 0,
      PolygonShape()..setAsBox(
        width / 2 / spriteVsPhysicsScale,
        height / 2 / spriteVsPhysicsScale,
        _reusableVector
          ..setFrom(position)
          ..scale(1 / spriteVsPhysicsScale),
        0,
      ),
      density: density,
    );
  }

  bool _topLeftOfBigBlock(int i, int j, {bool moving = false}) {
    final bool Function(int i, int j) localWallAt = moving
        ? _layout.movingWallAt
        : _layout.wallAt;
    assert(localWallAt(i, j));
    return (!localWallAt(i - 1, j) || !localWallAt(i - 1, j + 1)) &&
        (!localWallAt(i, j - 1) || !localWallAt(i + 1, j - 1)) &&
        !localWallAt(i - 1, j - 1) &&
        localWallAt(i + 1, j) &&
        localWallAt(i, j + 1) &&
        localWallAt(i + 1, j + 1);
  }

  int _bigBlockWidth(
    int i,
    int j, {
    bool singleHeight = true,
    bool moving = false,
  }) {
    final bool Function(int i, int j) localWallAt = moving
        ? _layout.movingWallAt
        : _layout.wallAt;
    assert(localWallAt(i, j));
    int k = 0;
    while (j + k < _layout.lengthH &&
        (singleHeight || localWallAt(i + 1, j + k + 1)) &&
        localWallAt(i, j + k + 1)) {
      k++;
    }
    return k;
  }

  int _bigBlockHeight(
    int i,
    int j, {
    bool singleWidth = true,
    bool moving = false,
  }) {
    final bool Function(int i, int j) localWallAt = moving
        ? _layout.movingWallAt
        : _layout.wallAt;
    assert(localWallAt(i, j));
    int l = 0;
    while (i + l < _layout.length &&
        (singleWidth || localWallAt(i + l + 1, j + 1)) &&
        localWallAt(i + l + 1, j)) {
      l++;
    }
    return l;
  }

  FixtureDef _fixtureCircle({
    required Vector2 position,
    required double radius,
  }) {
    /// [_reusableVector] safely instantly consumed inside FixtureDef
    return FixtureDef(
      CircleShape(
        radius: radius / spriteVsPhysicsScale,
        position: _reusableVector
          ..setFrom(position)
          ..scale(1 / spriteVsPhysicsScale),
      ),
    );
  }

  /// Generates the static walls of the maze, both their physical bodies and visuals.
  List<Component> walls({
    bool includeGround = true,
    bool includeVisualWalls = true,
  }) {
    final List<FixtureDef> fixtureDefs = <FixtureDef>[];
    final List<Component> result = <Component>[];
    final double scale = _dimensions.blockWidth;
    final Vector2 center = Vector2.zero();
    final Vector2 bigBlockCenter = Vector2.zero();
    final Vector2 bigBlockSize = Vector2.zero();
    for (int i = 0; i < _layout.length; i++) {
      for (int j = 0; j < _layout.lengthH; j++) {
        _dimensions.locationOfIJ(i, j, output: center);
        if (_layout.wallAt(i, j)) {
          if (_layout.circleAt(i, j)) {
            fixtureDefs.add(
              _fixtureCircle(position: center, radius: scale / 2),
            );
            result.add(
              WallCircleVisual(
                position: center,
                radius: scale / 2 * _mazeInnerWallWidthFactor,
              ),
            );
          }
          if (!_layout.wallAt(i, j - 1)) {
            final int width = _bigBlockWidth(i, j);
            if (width > 0) {
              bigBlockCenter
                ..setFrom(center)
                ..x += scale * width / 2;
              bigBlockSize.setValues(
                scale * (width + _pixelationBuffer),
                scale * _mazeInnerWallWidthFactor,
              );
              fixtureDefs.add(
                _fixtureDefBlock(
                  position: bigBlockCenter,
                  width: scale * (width + _pixelationBuffer),
                  height: scale,
                ),
              );
              result.add(
                WallRectangleVisual(
                  position: bigBlockCenter,
                  size: bigBlockSize,
                ),
              );
            }
          }
          if (!_layout.wallAt(i - 1, j)) {
            final int height = _bigBlockHeight(i, j);
            if (height > 0) {
              bigBlockCenter
                ..setFrom(center)
                ..y += scale * height / 2;
              bigBlockSize.setValues(
                scale * _mazeInnerWallWidthFactor,
                scale * (height + _pixelationBuffer),
              );
              fixtureDefs.add(
                _fixtureDefBlock(
                  position: bigBlockCenter,
                  width: scale,
                  height: scale * (height + _pixelationBuffer),
                ),
              );
              result.add(
                WallRectangleVisual(
                  position: bigBlockCenter,
                  size: bigBlockSize,
                ),
              );
            }
          }
          if (_topLeftOfBigBlock(i, j)) {
            final int width = _bigBlockWidth(i, j, singleHeight: false);
            final int height = _bigBlockHeight(i, j, singleWidth: false);
            if (width > 0 && height > 0) {
              bigBlockCenter
                ..setFrom(center)
                ..x += scale * width / 2
                ..y += scale * height / 2;
              bigBlockSize.setValues(scale * width, scale * height);
              result.add(
                WallRectangleVisual(
                  position: bigBlockCenter,
                  size: bigBlockSize,
                ),
              );
            }
          }
        }
      }
    }
    if (!includeVisualWalls) {
      result.clear();
    }
    return result;
  }
}
