import 'dart:math';

import 'package:flame/components.dart';

import '../maze.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'space_dot.dart';

int kOrderOfMagnitudeOrder = maze.mazeAcross;

class SpaceDotWrapper extends PositionComponent
    with
        IgnoreEvents,
        HasWorldReference<PacmanWorld>,
        HasGameReference<PacmanGame> {
  SpaceDotWrapper({
    required super.position,
    required this.orderMagnitude,
    required this.fullGrid,
  });

  bool fullGrid;
  int orderMagnitude;
  double roundingUnscaled = -1; //maze.mazeAcross

  void setScale() {
    scale = Vector2.all(pow(kOrderOfMagnitudeOrder, orderMagnitude).toDouble());
  }

  void tidyUpdate(
      {required int newOrderMagnitude, required Vector2 shipPosition}) {
    if (newOrderMagnitude != orderMagnitude) {
      orderMagnitude = newOrderMagnitude;
      setScale();
    }

    double roundingScaled =
        maze.blockWidth * pow(kOrderOfMagnitudeOrder, orderMagnitude);
    Vector2 centerPos = Vector2(
        ((shipPosition.x / roundingScaled).round()) * roundingScaled,
        ((shipPosition.y / roundingScaled).round()) * roundingScaled);
    position.setFrom(centerPos);
  }

  void reset() {
    removeAll(children);
    roundingUnscaled =
        maze.blockWidth * pow(kOrderOfMagnitudeOrder, 0); //orderMag
    int howFarAway = fullGrid ? (kOrderOfMagnitudeOrder / 2).ceil() : 0;
    assert(howFarAway <= kOrderOfMagnitudeOrder);
    for (int i = -howFarAway; i <= howFarAway; i++) {
      for (int j = -howFarAway; j <= howFarAway; j++) {
        Vector2 dotPos = Vector2(
            ((0 / roundingUnscaled).round() + i) * roundingUnscaled,
            ((0 / roundingUnscaled).round() + j) * roundingUnscaled);
        SpaceDot newDot = RecycledSpaceDot(
            position: dotPos,
            width: roundingUnscaled * 0.05,
            height: roundingUnscaled * 0.05);
        add(newDot);
      }
    }
    setScale();
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    reset();
  }
}
