import 'dart:ui';

import '../../style/palette.dart';
import '../../utils/helper.dart';
import 'heart.dart';
import 'overlay_sprite.dart';
import 'ship.dart';
import 'space_body.dart';
import 'space_layer.dart';

final Paint _rockPaint = Paint()..color = Palette.transp.color;

double _breakupSizeFactor() {
  const List<double> breakupSizes = <double>[0.2, 0.4, 0.5, 0.45, 0.3, 0.25];
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

class Rock extends SpaceBody with OverlaySprite {
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

  @override
  // ignore: overridden_fields
  late final String defaultSpritePath = random.nextDouble() < 1 / 3
      ? "asteroid1.png"
      : (random.nextDouble() < 0.5 ? "asteroid0.png" : "asteroid2.png");

  @override
  // ignore: overridden_fields
  late final String? overlaySpritePath = defaultSpritePath;

  @override
  void setHealth(double h, {bool dontExplode = false}) {
    super.setHealth(h);
    if (health < 0 && !dontExplode) {
      //if dontExplode, can't do this synchronously, so fix this later
      _explode();
    }
  }

  @override
  void damage(double d, {bool dontExplode = false}) {
    super.damage(d);
    setHealth(health - d / 3 * 2, dontExplode: dontExplode);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (health < 0) {
      //fix explosions where were not able to do this synchronously
      _explode();
    }
  }

  void _addSubRock() {
    world.space.rocks.add(
      Rock(
        position: position + noiseVector(radius / 2),
        velocity: velocity + noiseVector(2 * radius),
        radius: radius * _breakupSizeFactor(),
        numberExplosionsLeft: numberExplosionsLeft - 1,
      ),
    );
  }

  void _addSubHeart() {
    world.space.add(
      Heart(
        position: position + noiseVector(radius / 2),
        velocity: velocity + noiseVector(2 * radius),
        radius: ship.radius,
      ),
    );
  }

  bool _isLuckyHeart() {
    return random.nextDouble() < 0.05 &&
        world.space.hearts.length < world.space.heartLimit * 1.5;
  }

  void _explode() {
    if (isRemoving) {
      return;
    }
    final bool shouldSplit = !isSmall; // && numberExplosionsLeft >= 1;
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
    if (!isMounted) {
      return;
    }
    if (!isSmall) {
      opacity = 1;
    } else if (isTiny) {
      removeFromParent();
    } else {
      //update paint so can have separate transparency to other rocks
      paint = Paint()..color = Palette.transp.color;
      final double rFactor = radius / ship.radius;
      opacity =
          ((rFactor - transpThreshold) / (greyThreshold - transpThreshold))
              .clamp(0, 1);
    }
  }

  @override
  Future<void> onMount() async {
    await super.onMount();
    updateOpacity();
  }

  @override
  void onContactWith(SpaceBody other) {
    if (!contactActionsEnabled) {
      return;
    }
    if (other is Rock || other is Ship) {
      damage(0.2 * other.radius / radius, dontExplode: true);
    }
  }
}
