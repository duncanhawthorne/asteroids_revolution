import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/geometry.dart';

import '../../style/palette.dart';
import '../../utils/helper.dart';
import 'asteroids_layer.dart';
import 'heart.dart';
import 'space_body.dart';

bool _useSprite = false;

double _breakupSizeFactor() {
  const List<double> breakupSizes = [0.2, 0.4, 0.5, 0.6, 0.7, 0.75];
  return breakupSizes[random.nextInt(breakupSizes.length)];
}

double randomRadiusFactor() {
  const List<double> rockRadii = [0.6, 0.8, 1.1, 1.3, 1.5, 2, 4, 7];
  return rockRadii[random.nextInt(rockRadii.length)];
}

int randomStartingHits() {
  const List<int> startingHits = [1, 2, 3, 4];
  return startingHits[random.nextInt(startingHits.length)];
}

class Rock extends SpaceBody {
  Rock({
    required super.position,
    required super.velocity,
    this.ensureVelocityTowardsCenter = false,
    required super.radius,
    required this.numberExplosionsLeft,
  }) : super(
            paint: _useSprite
                ? (Paint()..color = Palette.transp.color)
                : (Paint()..color = Palette.text.color),
            priority: 100);

  @override
  // ignore: overridden_fields
  bool ensureVelocityTowardsCenter;

  int numberExplosionsLeft;

  late final CircleComponent hole = CircleComponent(
      radius: 0,
      anchor: Anchor.center,
      paint: Paint()..color = Palette.dull.color,
      position: Vector2.all(radius));

  @override
  void setHealth(double h) {
    super.setHealth(h);
    hole.radius = radius * (1 - health).clamp(0, 0.95);
    if (_useSprite) {
      spriteHole?.size.setAll(hole.radius * 2);
    }
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
    world.asteroidsWrapper.add(RecycledRock(
        position: position,
        velocity: velocity + velocityNoise(2 * radius),
        radius: radius * _breakupSizeFactor(),
        numberExplosionsLeft: numberExplosionsLeft - 1));
  }

  void _addSubHeart() {
    world.asteroidsWrapper.add(Heart(
      position: position,
      velocity: velocity + velocityNoise(2 * radius),
      radius: ship.radius,
    ));
  }

  bool _isLuckyHeart() {
    return random.nextDouble() < 0.05 &&
        world.asteroidsWrapper.hearts.length <
            world.asteroidsWrapper.heartLimit * 1.5;
  }

  void explode() {
    bool shouldSplit = !isSmall && numberExplosionsLeft >= 1;
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
    removeFromParent();
  }

  void updateOpacity() {
    if (!isSmall) {
      opacity = 1;
    } else if (isTiny) {
      removeFromParent();
    } else {
      double rFactor = radius / ship.radius;
      double n25 = transpThreshold;
      opacity = ((rFactor - n25) / (1 - n25)).clamp(0, 1);
    }
    if (_useSprite) {
      //sprite!.opacity = opacity;
      //spriteHole?.opacity = opacity;
    } else {
      hole.opacity = opacity;
    }
  }

  @override
  Future<void> onMount() async {
    super.onMount();
    updateOpacity();
    if (_useSprite) {
      spriteHole?.position.setAll(radius);
    } else {
      hole.position.setAll(radius);
    }
  }

  Sprite? rock1Sprite;
  Sprite? rock2Sprite;
  SpriteComponent? spriteHole;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    if (_useSprite) {
      rock1Sprite = await Sprite.load("asteroid1.png");
      rock2Sprite = await Sprite.load("asteroid2.png");
      /*
      sprite = SpriteComponent(
          sprite: rock1Sprite,
          angle: -tau / 4,
          anchor: Anchor.center,
          position: Vector2.all(radius),
          size: Vector2.all(radius * 2));
      add(sprite!);
       */

      spriteHole = SpriteComponent(
          sprite: rock2Sprite,
          angle: -tau / 4,
          anchor: Anchor.center,
          position: Vector2.all(radius),
          size: Vector2.all(0));
      add(spriteHole!);
    } else {
      add(hole);
    }
  }
}

final List<Rock> _allBits = [];
Iterable<Rock> get _spareBits => _allBits.where((item) => !item.isActive);

// ignore: non_constant_identifier_names
Rock RecycledRock(
    {required position,
    required velocity,
    required numberExplosionsLeft,
    required radius,
    ensureVelocityTowardsCenter = false}) {
  if (_spareBits.isEmpty) {
    Rock newBit = Rock(
        position: position,
        velocity: velocity,
        numberExplosionsLeft: numberExplosionsLeft,
        ensureVelocityTowardsCenter: ensureVelocityTowardsCenter,
        radius: radius);
    _allBits.add(newBit);
    return newBit;
  } else {
    Rock recycledBit = _spareBits.first;
    recycledBit.isActive = true;
    assert(_spareBits.isEmpty || _spareBits.first != recycledBit);
    recycledBit.position.setFrom(position);
    recycledBit.velocity.setFrom(velocity);
    recycledBit.numberExplosionsLeft = numberExplosionsLeft;
    recycledBit.ensureVelocityTowardsCenter = ensureVelocityTowardsCenter;
    recycledBit.radius = radius;
    return recycledBit;
  }
}
