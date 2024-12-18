import 'dart:async';

import 'package:flame/components.dart';

import '../maze.dart';
import 'wrapper_no_events.dart';

class WallWrapper extends WrapperNoEvents with Snapshot {

  @override
  int priority = -99;

  @override
  Future<void> reset() async {
    if (children.isNotEmpty) {
      removeAll(children);
    }
    await addAll(maze.mazeWalls(includeGround: false));
    clearSnapshot();
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    unawaited(reset());
  }
}
