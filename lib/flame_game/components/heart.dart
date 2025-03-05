import 'space_body.dart';
import 'space_layer.dart';

class Heart extends SpaceBody {
  Heart({
    required super.position,
    required super.velocity,
    this.ensureVelocityTowardsCenter = false,
    required super.radius,
  }) : super(paint: seedPaint);

  @override
  // ignore: overridden_fields
  String defaultSpritePath = "heart.png";

  @override
  // ignore: overridden_fields
  bool ensureVelocityTowardsCenter;
}
