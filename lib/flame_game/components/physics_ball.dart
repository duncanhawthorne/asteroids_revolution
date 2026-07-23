import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../../style/palette.dart';
import '../../utils/constants.dart';
import '../../utils/helper.dart';
import '../maze/maze.dart';
import '../pacman_game.dart';
import 'removal_actions.dart';
import 'scaled_body_render.dart';
import 'space_body.dart';

const bool openSpaceMovement = true;

double physicsScale = 0.5;
double get invPhysicsScale =>
    1 / physicsScale; // change to get if physicsScale non-constant
const bool kPhysicsScaleLockedAtOne = false;

final Paint _activePaint = Paint()..color = Palette.pacman.color;
final Paint _inactivePaint = Paint()..color = Palette.warning.color;

const double _lubricationScaleFactor = 0.95;
const bool _kVerticalPortalsEnabled = false;

/// A physical body representing a character in the Forge2D physics world.
class PhysicsBall extends BodyComponent<PacmanGame>
    with RemovalActions, ContactCallbacks, IgnoreEvents, ScaledBodyRender {
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
         shapeSpecs: <ShapeSpec>[_buildShape(radius, density, damping)],
         bodyDef: BodyDef(
           enableSleep: false,
           angularDamping: openSpaceMovement ? 0 : 0,
           position: position * physicsScale,
           linearVelocity: velocity * physicsScale,
           linearDamping: damping * 20,
           angularVelocity: angularVelocity,
           type: BodyType.dynamic,
           isEnabled: active,
           fixedRotation: !openSpaceMovement,
         ),
       ) {
    _bodyIsActive = active;
  }

  final SpaceBody owner;

  @override
  // ignore: overridden_fields
  final bool renderBody = drawDebugBoxes;

  @override
  // ignore: overridden_fields
  Paint paint = _activePaint;

  @override
  int priority = -100;

  ///[_bodyIsActive] is a mirror variable to [body.isEnabled]
  ///for use when body not yet initialised
  late bool _bodyIsActive;

  static final Vector2 _reusableVector = Vector2.zero();

  static ShapeSpec _buildShape(double radius, double density, double damping) {
    return ShapeSpec(
      Circle(radius: radius * _lubricationScaleFactor * physicsScale),
      ShapeDef(
        material: SurfaceMaterial(
          restitution: openSpaceMovement ? 1 : 0,
          friction: damping != 0 ? 1 : 0,
        ),
        density: density,
        enableContactEvents: false, // Opt in required for contact callbacks
      ),
    );
  }

  /// Synchronizes the physical body's position with the character's visual position.
  set position(Vector2 pos) => body.setTransform(
    kPhysicsScaleLockedAtOne ? pos : _reusableVector
      ..setFrom(pos)
      ..scale(physicsScale),
    Rot.fromAngle(owner.angle),
  );

  /// Checks if the ball has moved outside the maze boundaries (e.g., into a portal).
  bool get _outsideMazeBounds =>
      position.x.abs() > maze.dimensions.mazeHalfWidthPhysics ||
      (_kVerticalPortalsEnabled &&
          position.y.abs() > maze.dimensions.mazeHalfHeightPhysics);

  /// Synchronizes the physical body's linear velocity.
  set velocity(Vector2 vel) =>
      body.linearVelocity = kPhysicsScaleLockedAtOne ? vel : vel * physicsScale;

  /// Applies a force to the physical body.
  set acceleration(Vector2 acceleration) => body.applyForce(
    _reusableVector
      ..setFrom(acceleration)
      ..scale(body.mass * physicsScale),
  );

  /// Updates the radius of the physical fixture.
  set radius(double rad) {
    // Forge2D 0.15: Shapes are value-like handles over native ids.
    // To change geometry, destroy the old shape and attach a new one.
    if (body.shapes.isEmpty) return;

    final double currentDensity = body.shapes.first.density;
    final double currentDamping = body.linearDamping / 20;
    body.shapes.first.destroy();
    final ShapeSpec shapeSpec = _buildShape(
      rad,
      currentDensity,
      currentDamping,
    );
    body.createShape(
      shapeSpec.geometry,
      shapeSpec.definition,
    ); // may need applyMassFromShapes()
  }

  /// Activates the physical body in the simulation.
  void setActive() {
    paint = _activePaint;
    if (isRemoving) {
      return;
    }
    if (body.isEnabled == true && _bodyIsActive == true) {
      //no action required
      return;
    }
    assert(isMounted);
    assert(isLoaded);
    body.isEnabled = true;
    _bodyIsActive = true;
  }

  /// Deactivates the physical body to stop it from being affected by or affecting other bodies.
  void setInactive() {
    paint = _inactivePaint;
    if (isRemoving) {
      return;
    }
    if (_bodyIsActive == false && !isMounted) {
      //just test subConnectedBall as body not yet initialised
      return;
    }
    if (body.isEnabled == false && _bodyIsActive == false) {
      //no action required
      return;
    }
    assert(isMounted);
    assert(isLoaded);
    body.isEnabled = false;
    _bodyIsActive = false;
  }

  Vector2 _teleportedPosition() {
    _reusableVector.setValues(
      _smallMod(position.x * invPhysicsScale, maze.dimensions.mazeWidth),
      !_kVerticalPortalsEnabled
          ? position.y * invPhysicsScale
          : _smallMod(position.y * invPhysicsScale, maze.dimensions.mazeHeight),
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
  final double remainder = value % mod;
  return remainder > mod / 2 ? remainder - mod : remainder;
}
