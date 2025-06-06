import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';

import '../../style/palette.dart';
import '../../utils/helper.dart';
import '../maze.dart';
import '../pacman_game.dart';
import 'removal_actions.dart';
import 'space_body.dart';

const bool openSpaceMovement = true;

double spriteVsPhysicsScale = 2;
const bool spriteVsPhysicsScaleConstant = false;

final Paint _activePaint = Paint()..color = Palette.pacman.color;
final Paint _inactivePaint = Paint()..color = Palette.warning.color;

const double _lubricationScaleFactor = 1;
const bool _kVerticalPortalsEnabled = false;

class PhysicsBall extends BodyComponent<PacmanGame>
    with RemovalActions, ContactCallbacks, IgnoreEvents {
  PhysicsBall({
    required Vector2 position,
    required double radius,
    required Vector2 velocity,
    required double angularVelocity,
    required double damping,
    required double density,
    bool active = true,
    required this.owner,
  }) : super(
         fixtureDefs: <FixtureDef>[
           FixtureDef(
             restitution: openSpaceMovement ? 1 : 0,
             friction: damping != 0 ? 1 : 0,
             density: density,
             CircleShape(
               radius: radius * _lubricationScaleFactor / spriteVsPhysicsScale,
             ),
           ),
         ],
         bodyDef: BodyDef(
           angularDamping: openSpaceMovement ? 0 : 0,
           position: position / spriteVsPhysicsScale,
           linearVelocity: velocity / spriteVsPhysicsScale,
           linearDamping: damping * 20,
           angularVelocity: angularVelocity,
           type: BodyType.dynamic,
           active: active,
           fixedRotation: !openSpaceMovement,
         ),
       ) {
    _bodyIsActive = active;
  }

  final SpaceBody owner;

  @override
  // ignore: overridden_fields
  final bool renderBody = kDebugMode && true;

  @override
  // ignore: overridden_fields
  Paint paint = _activePaint;

  @override
  int priority = -100;

  ///[_bodyIsActive] is a mirror variable to [body.isActive]
  ///for use when body not yet initialised
  late bool _bodyIsActive;

  static final Vector2 _reusableVector = Vector2.zero();

  set position(Vector2 pos) => body.setTransform(
    spriteVsPhysicsScaleConstant ? pos : pos / spriteVsPhysicsScale,
    owner.angle,
  );

  bool get _outsideMazeBounds =>
      position.x.abs() > maze.mazeHalfWidth ||
      (_kVerticalPortalsEnabled && position.y.abs() > maze.mazeHalfHeight);

  set velocity(Vector2 vel) => body.linearVelocity.setFrom(
    spriteVsPhysicsScaleConstant ? vel : vel / spriteVsPhysicsScale,
  );

  set acceleration(Vector2 acceleration) => body.applyForce(
    _reusableVector
      ..setFrom(acceleration)
      ..scale(body.mass / spriteVsPhysicsScale),
  );

  set radius(double rad) =>
      body.fixtures.first.shape.radius = rad / spriteVsPhysicsScale;

  void setActive() {
    paint = _activePaint;
    if (isRemoving) {
      return;
    }
    if (body.isActive == true && _bodyIsActive == true) {
      //no action required
      return;
    }
    assert(isMounted);
    assert(isLoaded);
    body.setActive(true);
    _bodyIsActive = true;
  }

  void setInactive() {
    paint = _inactivePaint;
    if (isRemoving) {
      return;
    }
    if (_bodyIsActive == false && !isMounted) {
      //just test subConnectedBall as body not yet initialised
      return;
    }
    if (body.isActive == false && _bodyIsActive == false) {
      //no action required
      return;
    }
    assert(isMounted);
    assert(isLoaded);
    body.setActive(false);
    _bodyIsActive = false;
  }

  Vector2 _teleportedPosition() {
    _reusableVector.setValues(
      _smallMod(position.x, maze.mazeWidth),
      !_kVerticalPortalsEnabled
          ? position.y
          : _smallMod(position.y, maze.mazeHeight),
    );
    return _reusableVector;
  }

  // ignore: unused_element
  void _moveThroughPipePortal() {
    if (_bodyIsActive && _outsideMazeBounds) {
      position = _teleportedPosition();
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    //must set userData for contactCallbacks to work
    body.userData = this;
  }

  @override
  void beginContact(Object other, Contact contact) {
    super.beginContact(other, contact);
    if (other is PhysicsBall) {
      owner.onContactWith(other.owner);
    }
  }

  @override
  void removalActions() {
    try {
      setInactive();
    } catch (e) {
      logGlobal("catch ball removalactions set static");
    }
    super.removalActions();
  }
}

double _smallMod(double value, double mod) {
  //produces number between -mod / 2 and +mod / 2
  value = value % mod;
  return value > mod / 2 ? value - mod : value;
}
