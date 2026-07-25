import 'dart:async';

import 'package:flame/components.dart';

import '../custom_game.dart';
import '../custom_world.dart';
import 'base_component.dart';
import 'rock.dart';

class RockWrapper extends BaseComponent
    with HasWorldReference<CustomWorld>, HasGameReference<CustomGame> {
  @override
  final int priority = -1;

  @override
  Future<void> reset() async {
    removeWhere((Component item) => item is Rock);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    unawaited(reset());
  }
}
