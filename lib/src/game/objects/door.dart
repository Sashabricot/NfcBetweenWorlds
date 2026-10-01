import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:nfc_between_worlds/src/test_game.dart';

class Door extends SpriteAnimationComponent with HasGameReference<TestGame> {
  Door({required this.keyItemString}) : super(anchor: .bottomCenter);
  final Vector2 doorSpriteSize = Vector2.all(64);
  final Vector2 doorSize = Vector2(64, 64);
  final Vector2 doorHitboxSize = Vector2(64, 8);
  final String keyItemString;
  RectangleHitbox? hitBox;
  @override
  FutureOr<void> onLoad() {
    hitBox = RectangleHitbox(
      collisionType: CollisionType.passive,
      size: doorHitboxSize,
      position: Vector2(0, doorSize.y - doorHitboxSize.y),
    );
    add(hitBox!);
    return super.onLoad();
  }

  @override
  void onMount() {
    remove(hitBox!);
    int amount = 1;
    if (game.collectedItems.contains(keyItemString)) {
      amount = 6;
    } else {
      add(hitBox!);
    }
    animation = SpriteAnimation.fromFrameData(
      game.images.fromCache('DoubleDoor1.png'),
      SpriteAnimationData.sequenced(
        amount: amount,
        stepTime: 0.2,
        textureSize: doorSpriteSize,
        loop: false,
      ),
    );
    size = doorSize;
    super.onMount();
  }
}
