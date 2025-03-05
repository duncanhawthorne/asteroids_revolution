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
import 'bullet.dart';
import 'physics_ball.dart';
import 'ship.dart';

final Vector2 _kVector2Zero = Vector2.zero();

/// The [GameCharacter] is the generic object that is linked to a [PhysicsBall]
class GameCharacter extends SpriteAnimationGroupComponent<CharacterState>
    with
        IgnoreEvents,
        HasWorldReference<PacmanWorld>,
        HasGameReference<PacmanGame> {
  GameCharacter({
    super.position,
    this.original,
    super.paint,
    required double radius,
    required Vector2 nonForgeVelocity,
  }) : super(size: Vector2.all(radius * 2), anchor: Anchor.center) {
    this._nonForgeVelocity = Vector2.zero()..setFrom(nonForgeVelocity);
  }

  bool possiblePhysicsConnection = true;

  set radius(x) => _setRadius(x);

  void _setRadius(double x) {
    size = Vector2.all(x * 2);
    if (isMounted) {
      ball.body.fixtures.first.shape.radius = x;
    }
  }

  double get radius => size.x.toDouble() / 2;

  double friction = 1;

  late final PhysicsBall ball = PhysicsBall(
    position: position,
    radius: radius,
    velocity: _nonForgeVelocity,
    damping: 1 - friction,
  ); //never created for clone
  late final Vector2 _ballPos = ball.position;
  late final Vector2 _ballVel = ball.body.linearVelocity;
  late final Vector2 _gravitySign = world.gravitySign;

  late Vector2 _nonForgeVelocity;

  Vector2 get velocity => _getVelocity();

  Vector2 _getVelocity() {
    if (connectedToBall) {
      return _ballVel;
    } else {
      return _nonForgeVelocity;
    }
  }

  bool connectedToBall =
      true; //can't rename to be private variable as overridden in clone

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
      this is Bullet || this is Ship
          ? CollisionType.active
          : CollisionType.passive;

  bool _cloneEverMade = false; //could just test clone is null
  GameCharacter? _clone;
  late final GameCharacter? original;

  bool isClone = false;

  late final CircleHitbox hitBox = CircleHitbox(
    isSolid: true,
    collisionType: CollisionType.passive,
    anchor: Anchor.center,
  );

  late final double _radius = size.x / 2;

  String defaultSpritePath = "";

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
    ball.position = position;
    ball.velocity = _nonForgeVelocity;

    if (isMounted && !isRemoving) {
      // must test isMounted as bringBallToSprite typically runs after a delay
      // and could have reset to remove the ball in the meantime
      connectToBall();
    }
  }

  void setPositionStill(Vector2 targetLoc) {
    ball
      ..position = targetLoc
      ..velocity = _kVector2Zero;
    position.setFrom(targetLoc);
    connectToBall();
  }

  void disconnectFromBall({bool spawning = false}) {
    assert(!isClone); //as for clone have no way to turn collisionType back on
    _nonForgeVelocity.setFrom(velocity);
    if (!spawning) {
      /// if body not yet initialised, this will crash
      ball.setStatic();
    }
    connectedToBall = false;
    hitBox.collisionType = CollisionType.inactive;
  }

  void connectToBall() {
    connectedToBall = true;
    ball.setDynamic();
    ball.body.angularVelocity = (random.nextDouble() - 0.5) * tau / 2;
    hitBox.collisionType = defaultCollisionType;
    assert(!isClone); //not called on clones
  }

  void oneFrameOfPhysics(double dt) {
    if (connectedToBall) {
      assert(!isClone);
      position.setFrom(_ballPos);
      if (openSpaceMovement) {
        if (this is! Ship) {
          angle = ball.angle;
        }
      } else {
        angle += speed * dt / _radius * _spinParity;
      }
    }
  }

  @override
  Future<void> onLoad() async {
    _loadStubAnimationsOnDebugMode();
    if (this is! Ship) {
      animations = await getAnimations(100);
      current = CharacterState.normal;
    }
    if (connectedToBall && !isClone) {
      parent!.add(
        ball,
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
        ball.removeFromParent();
        world.destroyBody(ball.body);
      } catch (e) {
        //FIXME
      }
      disconnectFromBall(); //sync but within async function
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
    super.onRemove();
  }
}
