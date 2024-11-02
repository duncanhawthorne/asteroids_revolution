import 'dart:async' as async;
import 'dart:core';
import 'dart:math';
import 'dart:ui';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../app_lifecycle/app_lifecycle.dart';
import '../audio/audio_controller.dart';
import '../firebase/firebase_saves.dart';
import '../level_selection/levels.dart';
import '../player_progress/player_progress.dart';
import '../style/palette.dart';
import '../utils/src/workarounds.dart';
import 'game_screen.dart';
import 'maze.dart';
import 'pacman_world.dart';

/// This is the base of the game which is added to the [GameWidget].
///
/// This class defines a few different properties for the game:
///  - That it should have a [FixedResolutionViewport] containing
///  a square of size [kVirtualGameSize]
///  this means that even if you resize the window, the square itself will keep
///  the defined virtual resolution.
///  - That the default world that the camera is looking at should be the
///  [PacmanWorld].
///
/// Note that both of the last are passed in to the super constructor, they
/// could also be set inside of `onLoad` for example.

// flame_forge2d has a maximum allowed speed for physical objects.
// Reducing map size 30x, scaling up gravity 30x, & zooming 30x changes nothing,
// but reduces chance of hitting maximum allowed speed
const double flameGameZoom = 30.0;
const double _visualZoomMultiplier = 1;
const double kVirtualGameSize = 1700; //determines speed of game

class PacmanGame extends Forge2DGame<PacmanWorld>
    with
        // ignore: always_specify_types
        HasCollisionDetection,
        SingleGameInstance,
        HasTimeScale {
  PacmanGame({
    required this.level,
    required int mazeId,
    required this.playerProgress,
    required this.audioController,
    required this.appLifecycleStateNotifier,
  }) : super(
          world: PacmanWorld(),
          camera: CameraComponent.withFixedResolution(
              width: kVirtualGameSize, height: kVirtualGameSize),
          zoom: flameGameZoom * _visualZoomMultiplier,
        ) {
    this.mazeId = mazeId;
  }

  /// What the properties of the level that is played has.
  GameLevel level;

  set mazeId(int id) => <void>{maze.mazeId = id};

  int get mazeId => maze.mazeId;

  final AudioController audioController;
  final AppLifecycleStateNotifier appLifecycleStateNotifier;
  final PlayerProgress playerProgress;

  String _userString = "";

  static const int _deathPenaltyMillis = 5000;
  final Timer stopwatch = Timer(double.infinity);
  int get stopwatchMilliSeconds =>
      (stopwatch.current * 1000).toInt() +
      min(level.maxAllowedDeaths - 1,
              world.pacmans.numberOfDeathsNotifier.value) *
          _deathPenaltyMillis *
          (level.isTutorial ? 0 : 1);
  bool get levelStarted => stopwatchMilliSeconds > 0;

  bool get isGameLive =>
      !paused &&
      isLoaded &&
      isMounted &&
      !(overlays.isActive(GameScreen.startDialogKey) && !levelStarted);

  final Random random = Random();

  @override
  Color backgroundColor() => Palette.background.color;

  Map<String, dynamic> _getCurrentGameState() {
    final Map<String, dynamic> gameStateTmp = <String, dynamic>{};
    gameStateTmp["userString"] = _userString;
    gameStateTmp["levelNum"] = level.number;
    gameStateTmp["levelCompleteTime"] = stopwatchMilliSeconds;
    gameStateTmp["dateTime"] = DateTime.now().millisecondsSinceEpoch;
    gameStateTmp["mazeId"] = maze.mazeId;
    return gameStateTmp;
  }

  void pauseGame() {
    pause(); //timeScale = 0;
    pauseEngine();
    //stopwatch.pause(); //shouldn't be necessary given timeScale = 0
  }

  void resumeGame() {
    resume(); //timeScale = 1.0;
    resumeEngine();
  }

  void _lifecycleChangeListener() {
    appLifecycleStateNotifier.addListener(() {
      if (appLifecycleStateNotifier.value == AppLifecycleState.hidden) {
        pauseGame();
      }
    });
  }

  void _winOrLoseGameListener() {
    assert(world.pellets.pelletsRemainingNotifier.value > 0 || !levelStarted);
    world.snakeWrapper.numberOfDeathsNotifier.addListener(() {
      if (world.snakeWrapper.numberOfDeathsNotifier.value >=
              level.maxAllowedDeaths &&
          levelStarted) {
        _handleLoseGame();
      }
    });
    world.pellets.pelletsRemainingNotifier.addListener(() {
      if (world.pellets.pelletsRemainingNotifier.value == 0 && levelStarted) {
        _handleWinGame();
      }
    });
  }

  void _handleWinGame() {
    if (isGameLive) {
      if (world.pellets.pelletsRemainingNotifier.value == 0) {
        world.resetAfterGameWin();
        stopwatch.pause();
        if (stopwatchMilliSeconds > 0 * 1000 && !level.isTutorial) {
          fBase.firebasePushSingleScore(_userString, _getCurrentGameState());
        }
        playerProgress.saveLevelComplete(_getCurrentGameState());
        cleanDialogs();
        overlays.add(GameScreen.wonDialogKey);
      }
    }
  }

  void _handleLoseGame() {
    audioController.stopAllSfx();
    cleanDialogs();
    overlays.add(GameScreen.loseDialogKey);
  }

  void cleanDialogs() {
    overlays
      ..remove(GameScreen.startDialogKey)
      ..remove(GameScreen.loseDialogKey)
      ..remove(GameScreen.wonDialogKey)
      ..remove(GameScreen.tutorialDialogKey)
      ..remove(GameScreen.resetDialogKey);
  }

  void toggleOverlay(String overlayKey) {
    if (overlays.activeOverlays.contains(overlayKey)) {
      overlays.remove(overlayKey);
    } else {
      cleanDialogs();
      overlays.add(overlayKey);
    }
  }

  @override
  Future<void> onGameResize(Vector2 size) async {
    camera.viewport =
        FixedResolutionViewport(resolution: _sanitizeScreenSize(size));
    super.onGameResize(size);
  }

  void reset({bool firstRun = false, bool showStartDialog = false}) {
    pauseEngineIfNoActivity();
    _userString = _getRandomString(random, 15);
    cleanDialogs();
    if (showStartDialog) {
      overlays.add(GameScreen.startDialogKey);
    }
    stopwatch
      ..pause()
      ..reset();
    if (!firstRun) {
      assert(world.isLoaded);
      world.reset();
    }
  }

  void resetAndStart() {
    reset();
    start();
  }

  void start() {
    //resumeEngine();
    pauseEngineIfNoActivity();
    world.start();
  }

  int _framesRendered = 0;

  void pauseEngineIfNoActivity() {
    resumeEngine(); //for any catch up animation, if not already resumed
    _framesRendered = 0;
    async.Timer.periodic(const Duration(milliseconds: 10), (async.Timer timer) {
      if (paused) {
        //already paused, no further action required, just cancel timer
        timer.cancel();
      } else if (stopwatch.isRunning()) {
        //some game activity has happened, no need to pause, just cancel timer
        timer.cancel();
      } else if (!(world.isMounted &&
          world.ghosts.ghostList.isNotEmpty &&
          world.ghosts.ghostList[0].isLoaded)) {
        //core components haven't loaded yet, so wait before start frame count
        _framesRendered = 0;
      } else if (_framesRendered <= 5) {
        //core components loaded, but not yet had 5 good safety frame
      } else {
        //everything loaded and rendered, and still no game activity
        pauseEngine();
        timer.cancel();
      }
    });
  }

  void _bugFixes() {
    setStatusBarColor(Palette.background.color);
  }

  /// In the [onLoad] method you load different type of assets and set things
  /// that only needs to be set once when the level starts up.
  @override
  Future<void> onLoad() async {
    super.onLoad();
    _bugFixes();
    reset(firstRun: true);
    overlays.add(GameScreen.startDialogKey);
    _winOrLoseGameListener(); //isn't disposed so run once, not on start()
    _lifecycleChangeListener(); //isn't disposed so run once, not on start()
  }

  @override
  void update(double dt) {
    stopwatch.update(dt * timeScale); //stops stopwatch when timeScale = 0
    _framesRendered++;
    super.update(dt);
  }

  @override
  Future<void> onRemove() async {
    cleanDialogs();
    audioController.stopAllSfx();
    super.onRemove();
  }
}

Vector2 _sanitizeScreenSize(Vector2 size) {
  if (size.x > size.y) {
    return Vector2(kVirtualGameSize * size.x / size.y, kVirtualGameSize);
  } else {
    return Vector2(kVirtualGameSize, kVirtualGameSize * size.y / size.x);
  }
}

const String _chars =
    'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';

String _getRandomString(Random random, int length) =>
    String.fromCharCodes(Iterable<int>.generate(
        length, (_) => _chars.codeUnitAt(random.nextInt(_chars.length))));
