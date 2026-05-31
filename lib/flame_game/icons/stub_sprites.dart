import 'dart:ui';

import 'package:flame/components.dart';

import '../components/sprite_character.dart';

/// Provides empty "stub" sprites used as placeholders during initialization.
class StubSprites {
  Picture _stubRecorder() {
    final PictureRecorder recorder = PictureRecorder();
    // need to use recorder else throws error
    // ignore: unused_local_variable
    final Canvas canvas = Canvas(recorder);
    return recorder.endRecording();
  }

  /// The shared stub sprite image.
  late final Sprite _stubSprite = Sprite(_stubRecorder().toImageSync(1, 1));

  /// Generates a map of stub animations for all character states.
  Map<CharacterState, SpriteAnimation> _stubAnimations() {
    final Map<CharacterState, SpriteAnimation> result =
        <CharacterState, SpriteAnimation>{};
    for (final CharacterState state in CharacterState.values) {
      result[state] = SpriteAnimation.spriteList(<Sprite>[
        _stubSprite,
      ], stepTime: double.infinity);
    }
    return result;
  }

  late final Map<CharacterState, SpriteAnimation> stubAnimation =
      _stubAnimations();
}

StubSprites stubSprites = StubSprites();
