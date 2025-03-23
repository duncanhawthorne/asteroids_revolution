import 'package:flame/components.dart';
import 'package:flame/geometry.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../../utils/helper.dart';
import 'rock.dart';
import 'space_body.dart';

const bool openSpaceMovement = true;

// ignore: always_specify_types
class PhysicsBall extends BodyComponent with IgnoreEvents, ContactCallbacks {
  PhysicsBall({
    required Vector2 position,
    required double radius,
    required Vector2 velocity,
    required double damping,
    required double density,
    required this.owner,
  }) : super(
         fixtureDefs: <FixtureDef>[
           FixtureDef(
             restitution: openSpaceMovement ? 1 : 0,
             friction: damping != 0 ? 1 : 0,
             density: density,
             CircleShape(radius: radius),
           ),
         ],
         bodyDef: BodyDef(
           angularDamping: openSpaceMovement ? 0 : 0,
           position: position,
           linearVelocity: velocity,
           linearDamping: damping * 20,
           angularVelocity: (random.nextDouble() - 0.5) * tau / 2,
           type: BodyType.dynamic,
           fixedRotation: !openSpaceMovement,
         ),
       );

  final SpaceBody owner;

  @override
  // ignore: overridden_fields
  final bool renderBody = false;

  @override
  int priority = -100;

  // ignore: unused_field
  bool _subConnectedBall = true;

  set velocity(Vector2 vel) => body.linearVelocity.setFrom(vel);

  set position(Vector2 pos) => _setPositionNow(pos);

  void _setPositionNow(Vector2 pos) {
    body.setTransform(pos, 0);
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
      if (owner is Rock && other.owner is Rock) {
        //damage but dont explode as can't modidy bodies during a contact
        (owner as Rock).damage(
          0.05 * other.owner.radius / owner.radius,
          dontExplode: true,
        );
        (other.owner as Rock).damage(
          0.05 * owner.radius / other.owner.radius,
          dontExplode: true,
        );
      }
    }
  }
}
