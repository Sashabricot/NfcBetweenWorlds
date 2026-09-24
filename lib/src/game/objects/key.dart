import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:nfc_between_worlds/src/test_game.dart';

class KeyItem extends SpriteComponent with HasGameReference<TestGame> {
  KeyItem({required super.position}) : super(size: Vector2.all(16));
  final Vector2 hitBoxSize = Vector2.all(16);
  bool _isCollected = false;
  @override
  FutureOr<void> onLoad() {
    sprite = Sprite(game.images.fromCache('key.png'));
    add(RectangleHitbox(
        size: hitBoxSize, anchor: Anchor.center, position: Vector2.all(8)));
    return super.onLoad();
  }

  void collect() {
    if (_isCollected) return;
    _isCollected = true;
    game.collectKey();
    removeFromParent();
  }
}
