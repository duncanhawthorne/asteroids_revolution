import 'dart:async' as async;
import 'dart:core';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/geometry.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../audio/audio_controller.dart';

/// This file has utilities used by other bits of code

final Logger _globalLog = Logger('GL');

void logGlobal(dynamic x) {
  _globalLog.info(x);
}

final List<String> debugLogList = <String>[""];
const int debugLogListMaxLength = 30;
final ValueNotifier<int> debugLogListNotifier = ValueNotifier<int>(0);

void setupGlobalLogger() {
  Logger.root.level = (kDebugMode || detailedAudioLog)
      ? Level.FINE
      : Level.INFO;
  //logging.hierarchicalLoggingEnabled = true;
  Logger.root.onRecord.listen((LogRecord record) {
    final String time =
        "${DateTime.now().minute}:${DateTime.now().second}.${DateTime.now().millisecond}";
    final String message = '$time ${record.loggerName} ${record.message}';
    debugPrint(message);
    debugLogList.add(message);
    if (debugLogList.length > debugLogListMaxLength) {
      debugLogList.removeAt(0);
    }
    debugLogListNotifier.value += 1;
  });
}

async.Timer makePeriodicTimer(
  Duration duration,
  void Function(async.Timer timer) callback, {
  bool fireNow = false,
}) {
  final async.Timer timer = async.Timer.periodic(duration, callback);
  if (fireNow) {
    callback(timer);
  }
  return timer;
}

final Random random = Random();

double centeredRandom() {
  return random.nextDouble() - 0.5;
}

// ignore: unused_element
double _centeredRandomNoMiddle() {
  double a = 0;
  a = centeredRandom() * 0.25;
  a = a < 0 ? a - (1 - 0.25 / 2) : a + (1 - 0.25 / 2);
  return a;
}

Vector2 noiseVector(double scale) {
  final double ringRadius = (0.5 + random.nextDouble() * 0.5) * scale;
  final double ringAngle = tau * random.nextDouble();
  return Vector2(ringRadius * cos(ringAngle), ringRadius * sin(ringAngle));
}

final Vector2 _oneTimeVelocity = Vector2(0, 0);
Vector2 randomVelocityOffset({double scale = 1}) {
  _oneTimeVelocity.x = centeredRandom() * scale;
  _oneTimeVelocity.y = centeredRandom() * scale;
  return _oneTimeVelocity;
}

final Vector2 _oneTimePosition = Vector2(0, 0);
Vector2 randomRThetaRing({
  required Vector2 center,
  required double ringWidth,
  double ignoredRing = 0,
  double overallScale = 1,
}) {
  final double ringRadius =
      (ignoredRing + random.nextDouble() * ringWidth) * overallScale;
  final double ringAngle = tau * random.nextDouble();
  _oneTimePosition
    ..setFrom(center)
    ..x += ringRadius * cos(ringAngle)
    ..y += ringRadius * sin(ringAngle);
  return _oneTimePosition;
}
