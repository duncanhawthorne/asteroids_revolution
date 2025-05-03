import 'dart:math';

import 'package:flame/geometry.dart';
import 'package:vector_math/vector_math.dart';

import '../../utils/helper.dart';
import '../effects/rotate_effect.dart';
import 'game_character.dart';
import 'overlay_sprite.dart';
import 'space_body.dart';

class Alien extends SpaceBody with OverlaySprite {
  Alien({
    required super.position,
    required super.velocity,
    required super.radius,
    required super.paint,
  }) : super(density: 0.001);

  @override
  // ignore: overridden_fields
  String defaultSpritePath = "ship.png";

  @override
  // ignore: overridden_fields
  String? overlaySpritePath = "ship.png";

  @override
  // ignore: overridden_fields
  final double friction = 0.98;

  @override
  // ignore: overridden_fields
  final bool canAccelerate = true;

  @override
  void setHealth(double h) {
    super.setHealth(h);
    if (health <= 0) {
      removeFromParent();
    }
  }

  @override
  void damage(double d) {
    super.damage(d);
    setHealth(health - d);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }

  static final Vector2 _pd = Vector2.zero();
  static final Vector2 _vd = Vector2.zero();
  static final Vector2 _target = Vector2.zero();

  double? bullseye() {
    if (!ship.isMounted && !isMounted) {
      logGlobal("not mounted");
      return 0;
    }
    final double bulletSpeed = world.downDirection.length * radius * 2;
    _pd
      ..setFrom(ship.position)
      ..sub(position); //position delta
    _vd
      ..setFrom(ship.velocity)
      ..sub(velocity); //velocity delta
    final double w = bulletSpeed;
    final double k1 = _pd.y * _vd.x - _vd.y * _pd.x;
    final double k2 = _pd.x * w;
    final double k3 = _pd.y * w;

    final num a = pow(k3, 2) + pow(k2, 2);
    final double b = 2 * k1 * k3;
    final num c = pow(k1, 2) - pow(k2, 2);
    final num discriminant = pow(b, 2) - 4 * a * c;

    if (discriminant < 0 || a == 0) {
      //logGlobal(<Object>["no solution", discriminant, a, b, c]);
      return null;
    }

    //determine which root of quadratic for cosTheta

    final double cosThetaRoot1 = (-b + sqrt(discriminant)) / (2 * a);
    final double cosThetaRoot2 = (-b - sqrt(discriminant)) / (2 * a);

    double cosThetaRoot = 0;

    //assess if intercept time is negative for degenerate solutions

    final double interceptTime1 = _pd.x / (-cosThetaRoot1 * w - _vd.x);

    if (interceptTime1 < 0) {
      cosThetaRoot = cosThetaRoot2;
    } else {
      cosThetaRoot = cosThetaRoot1;
    }

    //determine which theta is behind cosTheta

    double theta = 0;

    final double interceptTime = _pd.x / (-cosThetaRoot * w - _vd.x);

    _target
      ..setFrom(_pd)
      ..scale(1 / interceptTime)
      ..add(_vd)
      ..scale(1 / w);

    if ((_target.x - (-cos(acos(cosThetaRoot)))).abs() < 0.01 * radius &&
        (_target.y - sin(acos(cosThetaRoot))).abs() < 0.01 * radius) {
      theta = acos(cosThetaRoot);
    } else {
      theta = tau - acos(cosThetaRoot);
    }

    if (theta.isNaN) {
      logGlobal("nan");
      return null;
    }
    return smallAngle(-tau / 4 - theta);
  }

  @override
  void update(double dt) {
    super.update(dt);
    GameCharacter.reusableVector
      ..setFrom(ship.position)
      ..sub(position);
    final double distanceToShip = GameCharacter.reusableVector.length;
    acceleration
      ..setFrom(GameCharacter.reusableVector)
      ..scale(1 / distanceToShip * 5 * radius);
    final double? bullseyeAngle = bullseye();
    angle =
        bullseyeAngle ??
        north.angleToSigned(
          GameCharacter.reusableVector
            ..setFrom(position)
            ..sub(world.space.ship.position),
        ); //move to alien gun
  }
}
