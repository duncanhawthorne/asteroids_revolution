import 'dart:core';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../style/palette.dart';
import 'space_body.dart';

final Paint backgroundOverridePaint =
    Paint()
      //.color = Palette.seed.color
      ..colorFilter = ColorFilter.mode(
        Palette.background.color,
        BlendMode.modulate,
      );

mixin OverlaySprite on SpaceBody {
  SpriteComponent? overlaySprite;
  String? overlaySpritePath;

  @override
  void setHealth(double h) {
    super.setHealth(h);
    _setHealth(h);
  }

  Future<void> _setHealth(double h) async {
    if (overlaySpritePath != null) {
      if (h == 1) {
        await _removeOverlaySprite();
      } else {
        await _addOverlaySprite();
      }
      final double holeRadius = radius * (1 - health).clamp(0, 0.9);
      overlaySprite?.size.setAll(holeRadius * 2);
    }
  }

  Future<void> _addOverlaySprite() async {
    if (overlaySprite == null) {
      overlaySprite = SpriteComponent(
        sprite: await Sprite.load(overlaySpritePath!),
        //angle: -tau / 4,
        anchor: Anchor.center,
        position: Vector2.all(radius),
        size: Vector2.all(0),
        paint: backgroundOverridePaint,
      );
      overlaySprite!.position.setAll(radius);
      add(overlaySprite!);
    }
  }

  Future<void> _removeOverlaySprite() async {
    overlaySprite?.removeFromParent();
  }
}
