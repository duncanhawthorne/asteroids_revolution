import 'dart:core';

import 'package:flame/components.dart';
import 'package:flame/geometry.dart';

import '../../utils/helper.dart';
import '../effects/remove_effects.dart';
import 'follow_physics.dart';
import 'follow_simple_physics.dart';
import 'sprite_character.dart';

final Vector2 north = Vector2(0, 1);

class GameCharacter extends SpriteCharacter {
  GameCharacter({
    super.position,
    required Vector2 velocity,
    required double radius,
    this.density = 1,
    super.paint,
  }) {
    this.velocity = Vector2.zero()..setFrom(velocity);
    size = Vector2.all(radius * 2);
  }

  final double density;

  bool possiblePhysicsConnection = true;

  bool connectedToBall = true;

  final bool canAccelerate = false;

  set velocity(Vector2 v) => _velocity.setFrom(v);
  Vector2 get velocity => _velocity;
  final Vector2 _velocity = Vector2(0, 0);

  set acceleration(Vector2 v) => _acceleration.setFrom(v);
  Vector2 get acceleration => _acceleration;
  final Vector2 _acceleration = Vector2(0, 0);

  double angularVelocity = (random.nextDouble() - 0.5) * tau / 2;

  double friction = 1;
  static Vector2 reusableVector = Vector2.zero();

  bool get typical => connectedToBall && stateTypical;

  double get radius => size.x.toDouble() / 2;
  set radius(double x) => _setRadius(x);

  void _setRadius(double x) {
    size = Vector2.all(x * 2);
    physics.setBallRadius(x);
  }

  late final Physics physics = Physics(owner: this);
  late final SimplePhysics simplePhysics = SimplePhysics(owner: this);

  void initialisePhysics() {
    physics.initaliseFromOwner();
    connectedToBall = true;
    if (children.contains(simplePhysics)) {
      simplePhysics.removeFromParent();
    }
    if (!children.contains(physics)) {
      add(physics);
    }
    hitBox.collisionType = defaultCollisionType; //FIXME move to sprite
    assert(!isClone); //not called on clones
  }

  void initialiseSimplePhysics() {
    if (children.contains(physics)) {
      physics.removeFromParent();
    }
    if (!children.contains(simplePhysics)) {
      add(simplePhysics);
    }
    connectedToBall = false;
    hitBox.collisionType =
        defaultCollisionType; //FIXME change, and move to sprite
  }

  void disconnectFromBall() {
    physics.removeFromParent();
    assert(!isClone); //as for clone have no way to turn collisionType back on
    connectedToBall = false;
  }

  // ignore: unused_element
  void _setPositionStill(Vector2 targetLoc) {
    position.setFrom(targetLoc);
    velocity.setAll(0);
    acceleration.setAll(0);
    angularVelocity = 0;
    physics.initaliseFromOwner();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    initialisePhysics();
  }

  @override
  void removalActions() {
    super.removalActions();
    if (!isClone) {
      physics.ownerRemovedActions();
      disconnectFromBall(); //sync but within async function
      removeEffects(this); //sync and async
    }
  }

  @override
  void removeFromParent() {
    removalActions();
    super.removeFromParent(); //async
  }

  @override
  Future<void> onRemove() async {
    removalActions();
    await super.onRemove();
  }
}
