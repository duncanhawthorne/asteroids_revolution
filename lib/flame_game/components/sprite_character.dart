import 'dart:core';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../style/palette.dart';
import '../effects/remove_effects.dart';
import '../icons/stub_sprites.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'bullet.dart';
import 'game_character.dart';
import 'ship.dart';

// ignore: unused_element
final Paint _highQualityPaint =
    Paint()
      ..filterQuality = FilterQuality.high
      //..color = const Color.fromARGB(255, 255, 255, 255)
      ..isAntiAlias = true;

class SpriteCharacter extends SpriteAnimationGroupComponent<CharacterState>
    with
        HasWorldReference<PacmanWorld>,
        HasGameReference<PacmanGame>,
        IgnoreEvents {
  SpriteCharacter({super.position, super.paint, this.original})
    : super(anchor: Anchor.center);

  late final GameCharacter? original;

  String defaultSpritePath = "";

  bool get stateTypical =>
      current != CharacterState.dead && current != CharacterState.spawning;

  late final CollisionType defaultCollisionType =
      this is Ship || this is Bullet
          ? CollisionType.active
          : CollisionType.passive;

  final bool isClone = false;

  late final CircleHitbox hitBox = CircleHitbox(
    isSolid: true,
    collisionType: defaultCollisionType,
  )..debugMode = kDebugMode && false;

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

  @mustCallSuper
  void setPhysicsState(PhysicsState state) {
    assert(!isClone); //not called on clones
    if (state == PhysicsState.full) {
      hitBox.collisionType = defaultCollisionType;
      hitBox.debugColor = Palette.pacman.color;
    } else if (state == PhysicsState.partial) {
      hitBox.collisionType = CollisionType.inactive;
      hitBox.debugColor = Palette.warning.color;
    } else {
      hitBox.collisionType = CollisionType.inactive;
      hitBox.debugColor = Palette.seed.color;
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
    add(hitBox);
  }

  @mustCallSuper
  void removalActions() {
    hitBox.collisionType = CollisionType.inactive;
    if (!isClone) {
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
