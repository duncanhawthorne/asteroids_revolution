import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../utils/constants.dart';
import 'components/base_component.dart';
import 'components/pellet_layer.dart';
import 'components/ship.dart';
import 'components/space_layer.dart';
import 'managers/drag_rotation.dart';
import 'pacman_game.dart';

/// The game world responsible for managing the lifecycle, physics, and hierarchy
/// of all active gameplay elements in the Pacman game.
///
/// This includes the player, enemies, obstacles, and game state managers.
///
/// **Mixins:**
/// * [DragCallbacks]: Enables the world to intercept and respond to user touch,
///   drag, and mouse interactions.
/// * [HasGameReference]: Provides direct access to the parent [PacmanGame]
///   instance via the `game` property.
class PacmanWorld extends Forge2DWorld
    with HasGameReference<PacmanGame>, DragCallbacks {
  /// Private constructor to enforce the singleton pattern.
  PacmanWorld._();

  /// Factory constructor that returns the single initialized instance of [PacmanWorld].
  ///
  /// Throws an [AssertionError] if an attempt is made to instantiate more than once.
  factory PacmanWorld() {
    assert(
      _instance == null,
      'PacmanWorld is a singleton and can only be initialized once.',
    );
    _instance ??= PacmanWorld._();
    return _instance!;
  }

  /// The internal singleton instance of the world.
  static PacmanWorld? _instance;

  /// Vector tracking the directional sign of the world's gravity.
  final Vector2 gravitySign = Vector2.zero();
  final Vector2 gravZero = Vector2.zero();

  /// Internal tracking list containing all system managers and game wrappers.
  final List<BaseComponent> _wrappers = <BaseComponent>[];

  /// A passive visual container used to hold components that do not require
  /// gesture event dispatching.
  final BaseComponent _noEvents = BaseComponent();

  // ==========================================
  // Core Component & Manager Definitions
  // ==========================================

  /// Layer managing pellets and power-ups.
  final PelletWrapper pellets = PelletWrapper();

  /// Layer managing space.
  final SpaceWrapper space = SpaceWrapper();

  /// Handler for maze rotation gestures.
  late final DragRotation dragRotate = DragRotation()..world = this;

  double get everythingScale =>
      space.ship.radius / neutralShipRadius * mapSizeScale;

  /// Resets the game state for all managed wrappers.
  ///
  /// If [firstRun] is true, the reset cycle is skipped, as components are
  /// expected to initialize to their default states natively during [onLoad].
  void reset({bool firstRun = false}) {
    if (!firstRun) {
      for (final BaseComponent wrapper in _wrappers) {
        assert(
          wrapper.isLoaded,
          'Attempted to reset a component that has not finished loading: $wrapper',
        );
        wrapper.reset();
      }
    }
  }

  /// Signals all tracked wrappers to begin their primary game execution routines.
  void start() {
    for (final BaseComponent wrapper in _wrappers) {
      wrapper.start();
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    gravity = gravZero;

    // Mount the non-event container directly to the world.
    add(_noEvents);

    // Register all core gameplay elements, configuration layers, and systems.
    _wrappers.addAll(<BaseComponent>[
      if (!enableRotationRaceMode) pellets,
      dragRotate,
      game.session,
      game.lifecycle,
      game.playback,
      game.dialogs,
      space,
    ]);

    /// Optimization: Nesting wrappers inside [_noEvents] keeps the flat count
    /// of root-level world components minimal. This speeds up Flame's internal
    /// element tree traversals, significantly optimizing gesture hit-testing
    /// methods like `deliverAtPoint` during drag interactions.
    _wrappers.forEach(_noEvents.add);

    reset(firstRun: true);
  }

  @override
  void onRemove() {
    _wrappers.clear();
    super.onRemove();
  }

  // ==========================================
  // Drag Input Event Handlers
  // ==========================================

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    dragRotate.onDragStart(event);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    dragRotate.onDragUpdate(event);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    dragRotate.onDragEnd(event);
  }
}
