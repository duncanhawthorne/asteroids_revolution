import 'package:flame/components.dart';

/// A foundational base component for game objects.
///
/// Mixes in [IgnoreEvents] to optimize Flame's internal event-dispatching (`deliverAtPoint`),
/// and establishes a uniform lifecycle for manual execution via [start] and [reset].
class BaseComponent extends PositionComponent with IgnoreEvents {
  /// Resets the component to its initial state.
  ///
  /// Subclasses should override this to clear states, animations, or positions.
  Future<void> reset() async {}

  /// Starts or activates the component's internal logic.
  void start() {}
}
