import 'dart:core';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

/// Mixin that ensures specific cleanup actions are performed when a component is removed.
mixin RemovalActions on Component {
  /// Custom cleanup logic to be executed upon removal.
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
