import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/geometry.dart';

import '../../style/palette.dart';
import '../../utils/helper.dart';
import 'heart.dart';
import 'space_body.dart';

final Paint _rockPaint = Paint()..color = Palette.transp.color;

double _breakupSizeFactor() {
  const List<double> breakupSizes = <double>[0.2, 0.4, 0.5, 0.6, 0.7, 0.75];
  return breakupSizes[random.nextInt(breakupSizes.length)];
}

double randomRadiusFactor() {
  const List<double> rockRadii = <double>[0.6, 0.8, 1.1, 1.3, 1.5, 2, 4, 7];
  return rockRadii[random.nextInt(rockRadii.length)];
}

int randomStartingHits() {
  const List<int> startingHits = <int>[1, 2, 3, 4];
  return startingHits[random.nextInt(startingHits.length)];
}

class Rock extends SpaceBody {
  Rock({
    required super.position,
    required super.velocity,
    this.ensureVelocityTowardsCenter = false,
    required super.radius,
    required this.numberExplosionsLeft,
  }) : super(paint: _rockPaint);

  @override
  // ignore: overridden_fields
  bool ensureVelocityTowardsCenter;

  int numberExplosionsLeft;

  late final CircleComponent hole = CircleComponent(
    radius: 0,
    anchor: Anchor.center,
    paint: Paint()..color = Palette.dull.color,
    position: Vector2.all(radius),
  );

  @override
  void setHealth(double h) {
    super.setHealth(h);
    if (h == 1) {
      removeRockHole();
    } else {
      addRockHole();
    }
    hole.radius = radius * (1 - health).clamp(0, 0.95);
    spriteHole?.size.setAll(hole.radius * 2);
    if (health < 0) {
      explode();
    }
  }

  @override
  void damage(double d) {
    super.damage(d);
    setHealth(health - d / 3 * 2);
  }

  void _addSubRock() {
    world.space.rocks.add(
      Rock(
        position: position + Vector2.random() * radius / 2,
        velocity: velocity + velocityNoise(2 * radius),
        radius: radius * _breakupSizeFactor(),
        numberExplosionsLeft: numberExplosionsLeft - 1,
      ),
    );
  }

  void _addSubHeart() {
    world.space.add(
      Heart(
        position: position + Vector2.random() * radius / 2,
        velocity: velocity + velocityNoise(2 * radius),
        radius: ship.radius,
      ),
    );
  }

  bool _isLuckyHeart() {
    return random.nextDouble() < 0.05 &&
        world.space.hearts.length < world.space.heartLimit * 1.5;
  }

  void explode() {
    final bool shouldSplit = !isSmall && numberExplosionsLeft >= 1;
    if (shouldSplit) {
      for (int i = 0; i < 2; i++) {
        if (_isLuckyHeart()) {
          _addSubHeart();
        } else {
          _addSubRock();
        }
      }
    } else {
      if (_isLuckyHeart()) {
        _addSubHeart();
      }
    }
    removalActions();
    removeFromParent();
  }

  void updateOpacity() {
    if (!isSmall) {
      opacity = 1;
    } else if (isTiny) {
      removeFromParent();
    } else {
      //update paint so can have separate transparency to other rocks
      paint = Paint()..color = Palette.transp.color;
      final double rFactor = radius / ship.radius;
      opacity = ((rFactor - transpThreshold) /
              (greyThreshold - transpThreshold))
          .clamp(0, 1);
    }
  }

  @override
  // ignore: overridden_fields
  String defaultSpritePath = "asteroid1.png";

  @override
  Future<void> onMount() async {
    await super.onMount();
    updateOpacity();
    spriteHole?.position.setAll(radius);
  }

  Sprite? rockHoleSprite;
  SpriteComponent? spriteHole;

  Future<void> addRockHole() async {
    rockHoleSprite = await Sprite.load("asteroid2.png");

    spriteHole = SpriteComponent(
      sprite: rockHoleSprite,
      angle: -tau / 4,
      anchor: Anchor.center,
      position: Vector2.all(radius),
      size: Vector2.all(0),
    );
    add(spriteHole!);
  }

  Future<void> removeRockHole() async {
    spriteHole?.removeFromParent();
  }
}
