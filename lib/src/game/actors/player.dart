import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/src/services/hardware_keyboard.dart';
import 'package:klondike/src/game/objects/land.dart';
import 'package:klondike/src/game/objects/wall.dart';
import 'package:klondike/src/test_game.dart';

class Player extends SpriteAnimationComponent
    with KeyboardHandler, CollisionCallbacks, HasGameReference<TestGame> {
  Player({
    this.joystick,
    required super.position,
  }) : super(size: Vector2.all(20), anchor: Anchor.center);

  final JoystickComponent? joystick;
  final double moveSpeed = 100;
  final Vector2 velocity = Vector2.zero();
  int horizontalDirection = 0;
  int verticalDirection = 0;

  @override
  FutureOr<void> onLoad() {
    animation = SpriteAnimation.fromFrameData(
        game.images.fromCache('ember.png'),
        SpriteAnimationData.sequenced(
            amount: 4, stepTime: 0.12, textureSize: Vector2.all(16)));

    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    if (joystick != null) {
      if (joystick!.direction != JoystickDirection.idle) {
        position.add(joystick!.relativeDelta * moveSpeed * dt);
      }
    }

    velocity.x = horizontalDirection * moveSpeed;

    velocity.y = verticalDirection * moveSpeed;
    position += velocity * dt;

    super.update(dt);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Wall || other is Ground) {
      if (intersectionPoints.length == 2) {
        final mid = (intersectionPoints.elementAt(0) +
                intersectionPoints.elementAt(1)) /
            2;
        final collisionNormal = absoluteCenter - mid;
        final sepratationDistance = (size.x / 2) - collisionNormal.length;
        collisionNormal.normalize();

        position += collisionNormal.scaled(sepratationDistance);
      }
    }
    super.onCollision(intersectionPoints, other);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    horizontalDirection = 0;
    verticalDirection = 0;
    horizontalDirection +=
        (keysPressed.contains(LogicalKeyboardKey.keyA)) ? -1 : 0;
    horizontalDirection +=
        (keysPressed.contains(LogicalKeyboardKey.keyD)) ? 1 : 0;
    verticalDirection +=
        (keysPressed.contains(LogicalKeyboardKey.keyW)) ? -1 : 0;
    verticalDirection +=
        (keysPressed.contains(LogicalKeyboardKey.keyS)) ? 1 : 0;
    return true;
  }
}
