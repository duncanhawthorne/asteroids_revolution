import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';

import '../../style/palette.dart';
import '../maze.dart';
import 'space_body.dart';

const bool openSpaceMovement = true;

double spriteVsPhysicsScale = 2;
const bool spriteVsPhysicsScaleConstant = false;

final Paint _activePaint = Paint()..color = Palette.pacman.color;
final Paint _inactivePaint = Paint()..color = Palette.warning.color;

double get playerSize => maze.spriteWidth / 2 * _lubricationScaleFactor;
const double _lubricationScaleFactor = 0.99;
const bool _kVerticalPortalsEnabled = false;

// ignore: always_specify_types
class PhysicsBall extends BodyComponent with IgnoreEvents, ContactCallbacks {
  PhysicsBall({
    required Vector2 position,
    required double radius,
    required Vector2 velocity,
    required double angularVelocity,
    required double damping,
    required double density,
    required this.owner,
  }) : super(
         fixtureDefs: <FixtureDef>[
           FixtureDef(
             restitution: openSpaceMovement ? 1 : 0,
             friction: damping != 0 ? 1 : 0,
             density: density,
             CircleShape(radius: radius / spriteVsPhysicsScale),
           ),
         ],
         bodyDef: BodyDef(
           angularDamping: openSpaceMovement ? 0 : 0,
           position: position / spriteVsPhysicsScale,
           linearVelocity: velocity / spriteVsPhysicsScale,
           linearDamping: damping * 20,
           angularVelocity: angularVelocity,
           type: BodyType.dynamic,
           fixedRotation: !openSpaceMovement,
         ),
       );

  final SpaceBody owner;

  @override
  // ignore: overridden_fields
  final bool renderBody = kDebugMode && true;

  @override
  // ignore: overridden_fields
  Paint paint = _activePaint;

  @override
  int priority = -100;

  // ignore: unused_field
  bool _subConnectedBall = true;

  static Vector2 reusableVector = Vector2.zero();

  set position(Vector2 pos) => _setPositionNow(pos / spriteVsPhysicsScale);

  bool get _outsideMazeBounds =>
      position.x.abs() > maze.mazeHalfWidth ||
      (_kVerticalPortalsEnabled && position.y.abs() > maze.mazeHalfHeight);

  set velocity(Vector2 vel) =>
      body.linearVelocity.setFrom(vel / spriteVsPhysicsScale);

  set acceleration(Vector2 acceleration) => body.applyForce(
    reusableVector
      ..setFrom(acceleration)
      ..scale(body.mass / spriteVsPhysicsScale),
  );

  set radius(double rad) =>
      body.fixtures.first.shape.radius = rad / spriteVsPhysicsScale;

  void _setPositionNow(Vector2 pos) {
    body.setTransform(pos, owner.angle);
  }

  Future<void> setDynamic() async {
    if (!isMounted) {
      await loaded;
      await mounted;
    }
    assert(isMounted);
    assert(isLoaded);
    body
      ..setType(BodyType.dynamic)
      ..setActive(true);
    _subConnectedBall = true;
    paint = _activePaint;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    //must set userData for contactCallbacks to work
    body.userData = this;
  }

  Future<void> setStatic() async {
    if (!isMounted) {
      await loaded;
      await mounted;
    }
    assert(isMounted);
    assert(isLoaded);
    body
      ..setType(BodyType.static)
      ..setActive(false);
    _subConnectedBall = false;
    paint = _inactivePaint;
  }

  Vector2 _teleportedPosition() {
    reusableVector.setValues(
      _smallMod(position.x, maze.mazeWidth),
      !_kVerticalPortalsEnabled
          ? position.y
          : _smallMod(position.y, maze.mazeHeight),
    );
    return reusableVector;
  }

  // ignore: unused_element
  void _moveThroughPipePortal() {
    if (_subConnectedBall && _outsideMazeBounds) {
      position = _teleportedPosition();
    }
  }

  @override
  void beginContact(Object other, Contact contact) {
    super.beginContact(other, contact);
    if (other is PhysicsBall) {
      owner.onContactWith(other.owner);
    }
  }
}

double _smallMod(double value, double mod) {
  //produces number between -mod / 2 and +mod / 2
  value = value % mod;
  return value > mod / 2 ? value - mod : value;
}
