import 'package:flame/components.dart';
import 'package:flame/effects.dart';

/// Utility function to remove all active [Effect]s from a component,
/// stopping them synchronously and removing them from the component tree.
void removeEffects(Component component) {
  component.children
      .whereType<Effect>()
      //create a new list toList so can iterate and remove simultaneously
      .toList(growable: false)
      .forEach((Effect item) {
        item
          ..pause() //sync
          ..removeFromParent();
      });
}
