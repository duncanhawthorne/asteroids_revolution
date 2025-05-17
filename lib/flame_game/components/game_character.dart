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
    this.velocity = velocity; //uses setter
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
    _physics.setBallRadius(x);
  }

  late final Physics _physics = Physics(owner: this);
  late final SimplePhysics _simplePhysics = SimplePhysics(owner: this);

  @override
  void setPreciseMode() {
    super.setPreciseMode();
    _initialisePhysics();
  }

  @override
  void setImpreciseMode() {
    super.setImpreciseMode();
    _initialiseSimplePhysics();
  }

  void _initialisePhysics() {
    _physics.initaliseFromOwner();
    connectedToBall = true;
    if (children.contains(_simplePhysics)) {
      _simplePhysics.removeFromParent();
    }
    if (!children.contains(_physics)) {
      add(_physics);
    }
  }

  void _initialiseSimplePhysics() {
    if (children.contains(_physics)) {
      _physics.removeFromParent();
    }
    if (!children.contains(_simplePhysics)) {
      add(_simplePhysics);
    }
    connectedToBall = false;
  }

  void _disconnectFromBall() {
    _physics.removeFromParent();
    assert(!isClone); //as for clone have no way to turn collisionType back on
    connectedToBall = false;
  }

  // ignore: unused_element
  void _setPositionStill(Vector2 targetLoc) {
    position.setFrom(targetLoc);
    velocity.setAll(0);
    acceleration.setAll(0);
    angularVelocity = 0;
    _physics.initaliseFromOwner();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    setPreciseMode();
  }

  @override
  void removalActions() {
    super.removalActions();
    if (!isClone) {
      _physics.ownerRemovedActions();
      _disconnectFromBall(); //sync but within async function
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
