import 'package:flame/components.dart';

import '../pacman_game.dart';
import '../pacman_world.dart';
import 'bullet.dart';
import 'wrapper_no_events.dart';

class BulletWrapper extends WrapperNoEvents
    with HasWorldReference<PacmanWorld>, HasGameReference<PacmanGame> {
  @override
  void reset() {
    removeWhere((Component item) => item is Bullet);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    reset();
  }
}
