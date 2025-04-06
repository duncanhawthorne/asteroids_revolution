import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/geometry.dart';

import 'bullet.dart';
import 'space_body.dart';

mixin Gun on SpaceBody {
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    world.space.bullets.add(gun);
  }

  @override
  Future<void> onRemove() async {
    await super.onRemove();
    gun.removeFromParent();
  }

  @override
  void update(double dt) {
    _multiGunTimer.update(dt);
    if (_multiGunTimer.finished) {
      _removeMultiGun();
    }
    super.update(dt);
  }

  @override
  void reset() {
    _removeMultiGun();
    super.reset();
  }

  final Timer _multiGunTimer = Timer(15);

  final Vector2 _oneTimeVelocity = Vector2(0, 0);
  Vector2 _fBulletVelocity() {
    if (!isMounted) {
      return _oneTimeVelocity;
    }
    _oneTimeVelocity
      ..x = sin(-angle)
      ..y = cos(-angle)
      ..scale(world.downDirection.length)
      ..scale(-2 * radius)
      ..add(velocity);
    return _oneTimeVelocity;
  }

  final Vector2 _oneTimePosition = Vector2(0, 0);
  Vector2 _fBulletPosition(double offset) {
    _oneTimePosition
      ..x = radius * 2 * cos(angle - tau / 4 + offset * 1.2 / 4)
      ..y = radius * 2 * sin(angle - tau / 4 + offset * 1.2 / 4)
      ..add(position);
    return _oneTimePosition;
  }

  late final SpawnComponent gun = SpawnComponent(
    multiFactory: (int i) => _bullets(),
    selfPositioning: true,
    period: 0.15,
  );

  List<PositionComponent> _bullets() {
    final Paint bulletPaint = paint;
    final double bulletRadius = radius * 0.25;
    final List<PositionComponent> out = <PositionComponent>[
      Bullet(
        position: _fBulletPosition(0),
        velocity: _fBulletVelocity(),
        radius: bulletRadius,
        paint: bulletPaint,
      ),
    ];
    if (_withMultiGun) {
      out
        ..add(
          Bullet(
            position: _fBulletPosition(0.5),
            velocity: _fBulletVelocity(),
            radius: bulletRadius,
            paint: bulletPaint,
          ),
        )
        ..add(
          Bullet(
            position: _fBulletPosition(-0.5),
            velocity: _fBulletVelocity(),
            radius: bulletRadius,
            paint: bulletPaint,
          ),
        );
    }
    return out;
  }

  bool _withMultiGun = false;
  void addMultiGun() {
    _withMultiGun = true;
    _multiGunTimer
      ..reset()
      ..start();
  }

  void _removeMultiGun() {
    _withMultiGun = false;
    _multiGunTimer.pause();
  }
}
