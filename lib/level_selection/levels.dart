import 'dart:math';

class Levels {
  static const int firstRealLevel = 1;
  static const int min = 1;
  static const int max = 15;
  static const int levelToShowInstructions = defaultLevelNum;
  static const int defaultLevelNum = min;

  static const List<int> _ghostSpawnTimerLengthPattern = <int>[5, 3, 2, 1];

  static const double _levelSpeedFactor = 50;

  GameLevel getLevel(int levelNum) {
    assert(levelNum <= max && levelNum >= min);
    final GameLevel result = (
      number: levelNum,
      maxAllowedDeaths: 1,
      superPelletsEnabled: levelNum <= 1 ? true : false,
      multipleSpawningGhosts: levelNum <= 2 ? false : true,
      ghostSpawnTimerLength: levelNum <= 2
          ? -1
          : _ghostSpawnTimerLengthPattern[
              (levelNum - 3) % _ghostSpawnTimerLengthPattern.length],
      homingGhosts:
          levelNum <= 2 + _ghostSpawnTimerLengthPattern.length ? false : true,
      isTutorial: levelNum <= 0,
      numStartingGhosts: levelNum >= 0
          ? 3
          : levelNum == min
              ? 1
              : (levelNum - 1) % 3 + 1,
      levelString:
          levelNum > 0 ? levelNum.toString() : "T${(levelNum - 1) % 4}",
      infLives: levelNum == min ? true : false,
      levelSpeed: _levelSpeedFactor * 0.25 * pow(1.1, levelNum).toDouble()
    );
    return result;
  }
}

final Levels levels = Levels();

typedef GameLevel = ({
  int number,
  int maxAllowedDeaths,
  bool superPelletsEnabled,
  bool multipleSpawningGhosts,
  int ghostSpawnTimerLength,
  bool homingGhosts,
  bool isTutorial,
  double levelSpeed,
  int numStartingGhosts,
  String levelString,
  bool infLives,
});
