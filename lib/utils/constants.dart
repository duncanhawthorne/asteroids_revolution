import 'package:flutter/foundation.dart';

/// The display title of the application.
const String appTitle = "Asteroids Revolution";

/// Whether the app is running on iOS Safari (web).
final bool isiOSWeb = defaultTargetPlatform == TargetPlatform.iOS && kIsWeb;

const bool enableRotationRaceMode = kDebugMode && false;
const bool enableMovingWalls = kDebugMode && false;

const bool drawDebugBoxes = kDebugMode && false;
