import 'dart:core';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

mixin RemovalActions on Component {
  @mustCallSuper
  void removalActions() {}

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
