import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';

import '../../style/palette.dart';
import 'space_body.dart';

const bool openSpaceMovement = true;

double spriteVsPhysicsScale = 2;

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
  final bool renderBody = kDebugMode && false;

  @override
  // ignore: overridden_fields
  final Paint paint = Paint()..color = Palette.warning.color;

  @override
  int priority = -100;

  // ignore: unused_field
  bool _subConnectedBall = true;

  static Vector2 reusableVector = Vector2.zero();

  set position(Vector2 pos) => _setPositionNow(pos / spriteVsPhysicsScale);

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

  void setDynamic() {
    body
      ..setType(BodyType.dynamic)
      ..setActive(true);
    _subConnectedBall = true;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    //must set userData for contactCallbacks to work
    body.userData = this;
  }

  void setStatic() {
    if (isMounted && body.isActive) {
      // avoid crashes if body not yet initialised
      // Probably about to remove ball anyway
      body
        ..setType(BodyType.static)
        ..setActive(false);
    }
    _subConnectedBall = false;
  }

  @override
  void beginContact(Object other, Contact contact) {
    super.beginContact(other, contact);
    if (other is PhysicsBall) {
      owner.onContactWith(other.owner);
    }
  }
}
