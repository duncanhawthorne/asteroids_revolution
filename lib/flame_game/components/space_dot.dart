import 'dart:ui';

import 'package:flame/components.dart';

import '../../style/palette.dart';

final Paint _spaceDotPaint = Paint()..color = Palette.dull.color;

class SpaceDot extends RectangleComponent with IgnoreEvents {
  SpaceDot({required super.position, required width, required height})
      : super(
            size: Vector2(width, height),
            anchor: Anchor.center,
            paint: _spaceDotPaint);

  bool isActive = true; //so not in sparebits

  @override
  Future<void> onMount() async {
    isActive = true; //already set sync but set here anyway
    super.onMount();
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    //spaceDotsCoords[position] = this;
  }

  @override
  Future<void> onRemove() async {
    isActive = false;
    super.onRemove();
    //spaceDotsCoords.remove(position);
  }
}

/*
bool existingSpaceDot(Vector2 position, Ship ship) {
  for (Vector2 item in spaceDotsCoords.keys) {
    if ((item.x - position.x).abs() < ship.radius &&
        (item.y - position.y).abs() < ship.radius) {
      return true;
    }
  }
  return false;
}


 */
final List<SpaceDot> _allBits = [];
Iterable<SpaceDot> get _spareBits => _allBits.where((item) => !item.isActive);
//Map<Vector2, SpaceDot> spaceDotsCoords = {};

// ignore: non_constant_identifier_names
SpaceDot RecycledSpaceDot(
    {required Vector2 position,
    required double width,
    required double height}) {
  if (_spareBits.isEmpty) {
    SpaceDot newBit =
        SpaceDot(position: position, width: width, height: height);
    _allBits.add(newBit);
    return newBit;
  } else {
    SpaceDot recycledBit = _spareBits.first;
    recycledBit.isActive = true;
    assert(_spareBits.isEmpty || _spareBits.first != recycledBit);
    recycledBit.position.setFrom(position);
    recycledBit.width = width;
    recycledBit.height = height;
    return recycledBit;
  }
}
