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
    super.original,
    super.paint,
  }) {
    this.velocity = velocity; //uses setter
    size = Vector2.all(radius * 2);
  }

  final double density;

  bool possiblePhysicsConnection = true;

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

  bool get typical => state == PhysicsState.full && stateTypical;

  final bool _cloneEverMade = false; //could just test clone is null
  GameCharacter? _clone;

  double get radius => size.x.toDouble() / 2;

  set radius(double x) => _setRadius(x);

  double get speed => _physics.speed;

  void _setRadius(double x) {
    size = Vector2.all(x * 2);
    _physics.setBallRadius(x);
  }

  late final Physics _physics = Physics(owner: this);
  late final SimplePhysics _simplePhysics = SimplePhysics(owner: this);

  bool _isFullyMounted(Component x) {
    return x.isMounted && !x.isRemoving;
  }

  PhysicsState state = PhysicsState.full;
  @override
  void setPhysicsState(PhysicsState state) {
    super.setPhysicsState(state);
    if (state == PhysicsState.full) {
      state = PhysicsState.full;
      _physics.initaliseFromOwnerAndSetDynamic();
      if (!_isFullyMounted(_physics)) {
        add(_physics);
      }
      if (_isFullyMounted(_simplePhysics)) {
        _simplePhysics.removeFromParent();
      }
    } else if (state == PhysicsState.partial) {
      state = PhysicsState.partial;
      if (!_isFullyMounted(_simplePhysics)) {
        add(_simplePhysics);
      }
      if (_isFullyMounted(_physics)) {
        _physics.removeFromParent();
      }
    } else {
      state = PhysicsState.none;
      assert(!isClone); //as for clone have no way to turn collisionType back on
      if (_isFullyMounted(_physics)) {
        _physics.removeFromParent();
      }
      if (_isFullyMounted(_simplePhysics)) {
        _simplePhysics.removeFromParent();
      }
    }
  }

  void setPositionStillActiveCurrentPosition() {
    //separate function so can be called from effects
    setPositionStillActive(position);
  }

  void setPositionStillActive(Vector2 targetLoc) {
    position.setFrom(targetLoc);
    velocity.setAll(0);
    acceleration.setAll(0);
    angularVelocity = 0;
    _physics.initaliseFromOwnerAndSetDynamic();
    setPhysicsState(PhysicsState.full);
  }

  void setPositionStillStatic(Vector2 targetLoc) {
    setPhysicsState(PhysicsState.none);
    position.setFrom(targetLoc);
    velocity.setAll(0);
    acceleration.setAll(0);
    angularVelocity = 0;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (!isClone) {
      setPhysicsState(PhysicsState.full);
    }
  }

  @override
  void removalActions() {
    super.removalActions();
    if (!isClone) {
      setPhysicsState(PhysicsState.none);
      _physics.ownerRemovedActions();
      _cloneEverMade ? _clone?.removeFromParent() : null;
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

enum PhysicsState { full, partial, none, unset }
