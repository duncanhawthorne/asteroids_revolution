import 'package:flame/components.dart';

import '../pacman_game.dart';
import '../pacman_world.dart';
import 'rock.dart';
import 'wrapper_no_events.dart';

class RockWrapper extends WrapperNoEvents
    with HasWorldReference<PacmanWorld>, HasGameReference<PacmanGame> {
  @override
  final int priority = -1;

  @override
  void reset() {
    removeWhere((Component item) => item is Rock);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    reset();
  }
}
