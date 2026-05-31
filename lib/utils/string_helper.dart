import 'dart:math';

const String _chars =
    'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';

/// Generates a random alphanumeric string of a given length.
String getRandomString(Random random, int length) {
  final List<int> charCodes = List<int>.generate(
    length,
    (_) => _chars.codeUnitAt(random.nextInt(_chars.length)),
    growable: false,
  );
  return String.fromCharCodes(charCodes);
}
