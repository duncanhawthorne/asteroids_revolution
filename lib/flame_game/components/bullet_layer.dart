import 'dart:async';

import 'package:flame/components.dart';

import '../pacman_game.dart';
import '../pacman_world.dart';
import 'bullet.dart';
import 'wrapper_no_events.dart';

class BulletWrapper extends WrapperNoEvents
    with HasWorldReference<PacmanWorld>, HasGameReference<PacmanGame> {
  @override
  final int priority = -1;

  @override
  Future<void> reset() async {
    removeWhere((Component item) => item is Bullet);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    unawaited(reset());
  }
}
