import 'dart:ui';

import 'package:flame/components.dart';

import '../../style/palette.dart';

final Paint _spaceDotPaint = Paint()..color = Palette.dull.color;

class SpaceDot extends RectangleComponent with IgnoreEvents {
  SpaceDot(
      {required super.position, required double width, required double height})
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
  }

  @override
  Future<void> onRemove() async {
    isActive = false;
    super.onRemove();
  }
}

final List<SpaceDot> _allBits = <SpaceDot>[];
Iterable<SpaceDot> get _spareBits =>
    _allBits.where((SpaceDot item) => !item.isActive);

// ignore: non_constant_identifier_names
SpaceDot RecycledSpaceDot(
    {required Vector2 position,
    required double width,
    required double height}) {
  if (_spareBits.isEmpty) {
    final SpaceDot newBit =
        SpaceDot(position: position, width: width, height: height);
    _allBits.add(newBit);
    return newBit;
  } else {
    final SpaceDot recycledBit = _spareBits.first;
    // ignore: cascade_invocations
    recycledBit.isActive = true;
    assert(_spareBits.isEmpty || _spareBits.first != recycledBit);
    recycledBit.position.setFrom(position);
    recycledBit
      ..width = width
      ..height = height;
    return recycledBit;
  }
}
