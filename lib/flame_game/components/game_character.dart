import 'dart:core';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/geometry.dart';
import 'package:flutter/foundation.dart';

import '../../utils/helper.dart';
import '../effects/remove_effects.dart';
import '../icons/stub_sprites.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'alien.dart';
import 'bullet.dart';
import 'physics_ball.dart';
import 'ship.dart';
import 'space_body.dart';

final Vector2 _kVector2Zero = Vector2.zero();
final Vector2 north = Vector2(0, 1);

/// The [GameCharacter] is the generic object that is linked to a [PhysicsBall]
class GameCharacter extends SpriteAnimationGroupComponent<CharacterState>
    with
        IgnoreEvents,
        HasWorldReference<PacmanWorld>,
        HasGameReference<PacmanGame> {
  GameCharacter({
    super.position,
    super.paint,
    double density = 1,
    required double radius,
    required Vector2 velocity,
  }) : super(size: Vector2.all(radius * 2), anchor: Anchor.center) {
    _simpleVelocity = Vector2.zero()..setFrom(velocity);
    _ball = PhysicsBall(
      position: position,
      radius: radius,
      velocity: _simpleVelocity,
      angularVelocity: _simpleAngularVelocity,
      damping: 1 - friction,
      density: density,
      owner: this as SpaceBody,
    );
  }

  static Vector2 reusableVector = Vector2.zero();

  bool possiblePhysicsConnection = true;
  final bool canAccelerate = false;
  double friction = 1;
  String defaultSpritePath = "";

  late final double _radius = size.x / 2;
  double get radius => size.x.toDouble() / 2;
  set radius(double x) => _setRadius(x);
  void _setRadius(double x) {
    size = Vector2.all(x * 2);
    if (isMounted && possiblePhysicsConnection) {
      _ball.radius = x;
    }
  }

  late final PhysicsBall _ball;

  Vector2 get _ballPos =>
      reusableVector
        ..setFrom(_ballPosUnscaled)
        ..scale(spriteVsPhysicsScale);
  late final Vector2 _ballPosUnscaled = _ball.position;
  Vector2 get _ballVel =>
      reusableVector
        ..setFrom(_ballVelUnscaled)
        ..scale(spriteVsPhysicsScale);
  late final Vector2 _ballVelUnscaled = _ball.body.linearVelocity;
  late final Vector2 _gravitySign = world.gravitySign;

  final Vector2 acceleration = Vector2(0, 0);
  late Vector2 _simpleVelocity;
  double _simpleAngularVelocity = (random.nextDouble() - 0.5) * tau / 2;

  Vector2 get velocity => connectedToBall ? _ballVel : _simpleVelocity;

  set velocity(Vector2 target) => _setVel(target);

  void _setVel(Vector2 target) {
    if (connectedToBall) {
      _ball.velocity = target;
    } else {
      _simpleVelocity.setFrom(target);
    }
  }

  late final bool _freeRotation = this is! Ship && this is! Alien;

  bool connectedToBall = true;

  double get speed => _ballVel.length;

  double get _spinParity =>
      _ballVel.x.abs() > _ballVel.y.abs()
          ? _gravitySign.y * _ballVel.x.sign
          : -_gravitySign.x * _ballVel.y.sign;

  bool get typical =>
      connectedToBall &&
      current != CharacterState.dead &&
      current != CharacterState.spawning;

  late final CollisionType defaultCollisionType =
      this is Ship || this is Bullet
          ? CollisionType.active
          : CollisionType.passive;

  static const bool isClone = false;

  late final CircleHitbox hitBox = CircleHitbox(
    isSolid: true,
    collisionType: defaultCollisionType,
    anchor: Anchor.center,
  );

  Future<Map<CharacterState, SpriteAnimation>> getSingleSprite([
    int size = 1,
  ]) async {
    return <CharacterState, SpriteAnimation>{
      CharacterState.normal: SpriteAnimation.spriteList(<Sprite>[
        await game.loadSprite(defaultSpritePath),
      ], stepTime: double.infinity),
    };
  }

  Future<Map<CharacterState, SpriteAnimation>> getAnimations([
    int size = 1,
  ]) async {
    if (defaultSpritePath != "") {
      return getSingleSprite(size);
    }
    if (animations == null) {
      animations = stubSprites.stubAnimation;
    }
    return animations!;
  }

  void _loadStubAnimationsOnDebugMode() {
    // works around changes made in flame 1.19
    // where animations have to be loaded before can set current
    // only fails due to assert, which is only tested in debug mode
    // so if in debug mode, quickly load up stub animations first
    // https://github.com/flame-engine/flame/pull/3258
    if (kDebugMode) {
      animations = stubSprites.stubAnimation;
    }
  }

  void bringBallToSprite() {
    assert(possiblePhysicsConnection, this);
    if (!possiblePhysicsConnection) {
      return;
    }
    if (isMounted && !isRemoving) {
      _ball.position = position;
      _ball.velocity = _simpleVelocity;
      _ball.radius = radius;
    }

    if (isMounted && !isRemoving) {
      // must test isMounted as bringBallToSprite typically runs after a delay
      // and could have reset to remove the ball in the meantime
      connectToBall();
    }
  }

  void setPositionStill(Vector2 targetLoc) {
    _ball
      ..position = targetLoc
      ..velocity = _kVector2Zero;
    position.setFrom(targetLoc);
    connectToBall();
  }

  void disconnectFromBall({bool spawning = false}) {
    assert(!isClone); //as for clone have no way to turn collisionType back on
    _simpleVelocity.setFrom(velocity);
    _simpleAngularVelocity = _ball.body.angularVelocity;
    if (!spawning) {
      /// if body not yet initialised, this will crash
      _ball.setStatic();
    }
    connectedToBall = false;
    hitBox.collisionType = CollisionType.inactive;
  }

  void connectToBall() {
    assert(possiblePhysicsConnection, this);
    if (!possiblePhysicsConnection) {
      return;
    }
    connectedToBall = true;
    _ball.setDynamic();
    _ball.body.angularVelocity = _simpleAngularVelocity;
    hitBox.collisionType = defaultCollisionType;
    assert(!isClone); //not called on clones
  }

  void oneFrameOfPhysics(double dt) {
    if (connectedToBall) {
      assert(!isClone);
      if (canAccelerate) {
        _ball.acceleration = acceleration;
      }
      position.setFrom(_ballPos);
      _simpleVelocity.setFrom(velocity);
      if (openSpaceMovement) {
        if (_freeRotation) {
          angle = _ball.angle;
        }
      } else {
        angle += speed * dt / _radius * _spinParity;
      }
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _loadStubAnimationsOnDebugMode();
    if (this is! Ship) {
      animations = await getAnimations(100);
      current = CharacterState.normal;
    }
    if (connectedToBall && !isClone) {
      parent!.add(
        _ball,
      ); //should be added to static parent but risks going stray
    }
    add(hitBox);
  }

  @mustCallSuper
  void removalActions() {
    hitBox.collisionType = CollisionType.inactive;
    if (!isClone) {
      //removeEffects(this); //dont run this, runs async code which will execute after the item has already been removed and cause a crash
      try {
        _ball.removeFromParent();
        world.destroyBody(_ball.body);
      } catch (e) {
        //FIXME
      }
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
    super.onRemove();
  }
}
