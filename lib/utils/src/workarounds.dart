import 'package:flutter/services.dart';

import '../../style/palette.dart';
import 'workarounds_stub.dart'
    if (dart.library.js_interop) 'workarounds_web.dart';

void bugFixes() {
  setStatusBarColor(Palette.background.color);
}

/// Sets the system status and navigation bar colors.
void setStatusBarColor(Color color) {
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: color, // Status bar color
      systemNavigationBarColor: color,
    ),
  );
}

void fixTitlePerm() {
  // to workaround a bug in flutter on ios web
  titleFixPermReal();
}

double gestureInset() {
  // to workaround a bug in flutter on ios web
  return gestureInsetReal(); //either from web or stub depending on platform
}
