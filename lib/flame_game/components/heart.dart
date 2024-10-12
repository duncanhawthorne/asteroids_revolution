import 'asteroids_layer.dart';
import 'space_body.dart';

class Heart extends SpaceBody {
  Heart({
    required super.position,
    required super.velocity,
    this.ensureVelocityTowardsCenter = false,
    required super.radius,
  }) : super(paint: snakePaint, priority: 100);

  /*
  @override
  // ignore: overridden_fields
  final debugMode = true;
   */

  @override
  // ignore: overridden_fields
  bool ensureVelocityTowardsCenter;
}
