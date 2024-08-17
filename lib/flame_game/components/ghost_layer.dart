import 'dart:async' as async;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/foundation.dart';

import '../../audio/sounds.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'game_character.dart';
import 'ghost.dart';
import 'wrapper_no_events.dart';

final bool _iOSWeb = defaultTargetPlatform == TargetPlatform.iOS && kIsWeb;
final bool _sirenEnabled = !_iOSWeb;
const int _kGhostChaseTimeMillis = 6000;

class Ghosts extends WrapperNoEvents
    with HasWorldReference<PacmanWorld>, HasGameReference<PacmanGame> {
  @override
  final priority = 1;

  final List<Ghost> ghostList = [];

  CharacterState current = CharacterState.normal;
  Timer ghostsScaredTimer = Timer(_kGhostChaseTimeMillis / 1000);
  SpawnComponent? ghostSpawner;
  async.Timer? _sirenTimer;

  double _averageGhostSpeed() {
    if (!game.isGameLive ||
        world.pacmans.numberAlivePacman() == 0 ||
        world.gameWonOrLost ||
        ghostList.isEmpty) {
      return 0;
    } else {
      return ghostList
              .map((Ghost ghost) =>
                  ghost.current == CharacterState.normal ? ghost.speed : 0.0)
              .reduce((value, element) => value + element) /
          ghostList.length;
    }
  }

  void sirenVolumeUpdatedTimer() async {
    // ignore: prefer_conditional_assignment
    if (_sirenEnabled) {
      if (_sirenTimer == null &&
          isMounted &&
          game.isGameLive &&
          !world.gameWonOrLost) {
        _sirenTimer =
            async.Timer.periodic(const Duration(milliseconds: 250), (timer) {
          if (game.isGameLive &&
              !world.gameWonOrLost &&
              !world.doingLevelResetFlourish) {
            game.audioController.setSirenVolume(
                _averageGhostSpeed() * flameGameZoom / 30,
                gradual: true);
          } else {
            _cancelSirenVolumeUpdatedTimer();
          }
        });
      }
    }
  }

  void _cancelSirenVolumeUpdatedTimer() {
    if (_sirenTimer != null) {
      game.audioController.setSirenVolume(0);
      _sirenTimer!.cancel();
      _sirenTimer = null;
    }
  }

  void _addThreeGhosts() {
    for (int i = 0; i < 3; i++) {
      add(Ghost(idNum: i));
    }
  }

  void scareGhosts() {
    if (!isMounted) {
      return;
    }
    current = CharacterState.scared;
    if (world.pellets.pelletsRemainingNotifier.value != 0) {
      world.play(SfxType.ghostsScared);
      for (Ghost ghost in ghostList) {
        ghost.setScared();
      }
      ghostsScaredTimer.start();
    }
  }

  void addSpawner() {
    if (!isMounted) {
      return; //else cant use game references
    }
    ghostSpawner ??= SpawnComponent(
      factory: (i) => Ghost(idNum: [3, 4, 5][game.random.nextInt(3)]),
      selfPositioning: true,
      period: world.level.ghostSpwanTimerLength.toDouble(),
    );
    if (game.level.multipleSpawningGhosts &&
        !ghostSpawner!.isMounted &&
        !world.gameWonOrLost) {
      add(ghostSpawner!);
    }
  }

  void removeSpawner() {
    if (world.level.multipleSpawningGhosts && ghostSpawner != null) {
      ghostSpawner!.removeFromParent();
    }
  }

  void _trimAllGhosts() {
    for (Ghost ghost in ghostList) {
      ghost.removeWhere((item) => item is Effect); //sync
      ghost.disconnectFromBall(); //sync
      ghost.removeFromParent(); //async
    }
    removeSpawner();
  }

  void disconnectGhostsFromBalls() {
    for (Ghost ghost in ghostList) {
      ghost.removeWhere((item) => item is Effect);
      ghost.disconnectFromBall(); //sync
    }
  }

  void resetAfterGameWin() {
    current = CharacterState.normal;
    ghostsScaredTimer.pause(); //makes update function for timer free
    _trimAllGhosts();
  }

  void resetSlideAfterPacmanDeath() {
    current = CharacterState.normal;
    ghostsScaredTimer.pause(); //makes update function for timer free
    for (Ghost ghost in ghostList) {
      ghost.resetSlideAfterPacmanDeath();
    }
  }

  void resetInstantAfterPacmanDeath() {
    current = CharacterState.normal;
    ghostsScaredTimer.pause(); //makes update function for timer free
    if (game.level.multipleSpawningGhosts) {
      _trimAllGhosts();
      _addThreeGhosts();
    } else {
      for (Ghost ghost in ghostList) {
        ghost.resetInstantAfterPacmanDeath();
      }
      //no spawner to remove
    }
  }

  void _stateSequence(double dt) {
    ghostsScaredTimer.update(dt);
    if (current == CharacterState.scared) {
      if (ghostsScaredTimer.current > 2 / 3 * ghostsScaredTimer.limit) {
        current = CharacterState.scaredIsh;
        for (Ghost ghost in ghostList) {
          ghost.setScaredToScaredIsh();
        }
      }
    }
    if (current == CharacterState.scaredIsh) {
      if (ghostsScaredTimer.finished) {
        current = CharacterState.normal;
        for (Ghost ghost in ghostList) {
          ghost.setScaredIshToNormal();
          ghostsScaredTimer.pause(); //makes update function for timer free
        }
        game.audioController.stopSfx(SfxType.ghostsScared);
      }
    }
  }

  @override
  void reset({bool mazeResize = false}) {
    _cancelSirenVolumeUpdatedTimer;
    current = CharacterState.normal;
    ghostsScaredTimer.pause(); //makes update function for timer free
    _trimAllGhosts();
    _addThreeGhosts();
  }

  @override
  void update(double dt) {
    _stateSequence(dt);
    super.update(dt);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    reset();
  }
}
