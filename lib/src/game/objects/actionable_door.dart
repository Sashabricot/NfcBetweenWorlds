import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:nfc_between_worlds/src/test_game.dart';

class ActionableDoor extends SpriteAnimationGroupComponent
    with HasGameReference<TestGame> {
  ActionableDoor() : super(anchor: .bottomCenter);
  final Vector2 doorSpriteSize = Vector2.all(64);
  final Vector2 doorSize = Vector2(64, 64);
  final Vector2 doorHitboxSize = Vector2(64, 8);
  bool canToggle = false;
  SpriteAnimation? idle;
  SpriteAnimation? open;
  SpriteAnimation? close;

  bool isOpened = false;

  final String doorSprite = 'DoubleDoor1.png';
  RectangleHitbox? hitBox;
  @override
  FutureOr<void> onLoad() {
    hitBox = RectangleHitbox(
      collisionType: CollisionType.passive,
      size: doorHitboxSize,
      position: Vector2(0, doorSize.y - doorHitboxSize.y),
    );
    loadAnimations();
    animations = {'idle': idle!, 'open': open!, 'close': close!};
    current = 'idle';
    size = doorSize;
    add(hitBox!);
    return super.onLoad();
  }

  void toggleDoor() {
    if (!isOpened) {
      remove(hitBox!);

      isOpened = true;
      current = 'open';
    } else {
      add(hitBox!);

      isOpened = false;
      current = 'close';
    }
  }

  void loadAnimations() {
    idle = SpriteAnimation.fromFrameData(
      game.images.fromCache(doorSprite),
      SpriteAnimationData.sequenced(
        amount: 1,
        stepTime: 0.1,
        textureSize: doorSpriteSize,
        loop: false,
      ),
    );
    open = SpriteAnimation.fromFrameData(
      game.images.fromCache(doorSprite),
      SpriteAnimationData.sequenced(
        amount: 6,
        stepTime: 0.1,
        textureSize: doorSpriteSize,
        loop: false,
      ),
    );
    close = SpriteAnimation.fromFrameData(
      game.images.fromCache(doorSprite),
      SpriteAnimationData.sequenced(
        amount: 6,
        stepTime: 0.1,
        textureSize: doorSpriteSize,
        loop: false,
      ),
    ).reversed();
  }
}
