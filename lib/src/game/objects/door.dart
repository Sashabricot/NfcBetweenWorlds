import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:nfc_between_worlds/src/test_game.dart';

class Door extends SpriteAnimationComponent with HasGameReference<TestGame> {
  Door({required String keyItemString}) : super(anchor: .bottomCenter);
  final Vector2 doorSpriteSize = Vector2.all(64);
  final Vector2 doorSize = Vector2(64, 64);
  final Vector2 doorHitboxSize = Vector2(64, 8);
  @override
  FutureOr<void> onLoad() {
    int amount = 1;
    if (game.collectedItems.contains('key1')) {
      amount = 6;
    } else {
      add(
        RectangleHitbox(
          collisionType: CollisionType.passive,
          size: doorHitboxSize,
          position: Vector2(0, doorSize.y - doorHitboxSize.y),
        ),
      );
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

    return super.onLoad();
  }
}
