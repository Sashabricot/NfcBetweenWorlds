import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/src/services/hardware_keyboard.dart';
import 'package:testgame/src/game/actors/player_state.dart';
import 'package:testgame/src/game/objects/land.dart';
import 'package:testgame/src/game/objects/wall.dart';
import 'package:testgame/src/test_game.dart';

class Player extends SpriteAnimationGroupComponent<PlayerState>
    with KeyboardHandler, CollisionCallbacks, HasGameReference<TestGame> {
  Player({
    required this.playerState,
    required this.isBlocked,
    required this.slimeImage,
    this.joystick,
    required super.position,
  }) : super(
          size: Vector2.all(64),
          anchor: Anchor.center,
        );

  SpriteAnimation? topIdle;
  SpriteAnimation? bottomIdle;
  SpriteAnimation? leftIdle;
  SpriteAnimation? rightIdle;

  PlayerState playerState;
  final String slimeImage;
  final bool isBlocked;
  final double hitBoxSize = 10;
  final JoystickComponent? joystick;
  final double moveSpeed = 100;
  final Vector2 velocity = Vector2.zero();
  int horizontalDirection = 0;
  int verticalDirection = 0;

  @override
  FutureOr<void> onLoad() {
    loadAnimations();
    animations = {
      PlayerState.topIdle: topIdle!,
      PlayerState.bottomIdle: bottomIdle!,
      PlayerState.leftIdle: leftIdle!,
      PlayerState.rightIdle: rightIdle!
    };
    current = playerState;
    add(CircleHitbox(
        radius: hitBoxSize, anchor: Anchor.center, position: Vector2.all(32)));
  }

  @override
  void update(double dt) {
    Vector2 nextPosition = position;

    if (joystick != null) {
      if (joystick!.direction != JoystickDirection.idle) {
        if (joystick!.relativeDelta.x > 0) {
          if (joystick!.relativeDelta.y > 0.4)
            playerState = PlayerState.bottomIdle;
          else if (joystick!.relativeDelta.y < -0.4)
            playerState = PlayerState.topIdle;
          else
            playerState = PlayerState.rightIdle;
        } else if (joystick!.relativeDelta.x < 0) {
          if (joystick!.relativeDelta.y > 0.4)
            playerState = PlayerState.bottomIdle;
          else if (joystick!.relativeDelta.y < -0.4)
            playerState = PlayerState.topIdle;
          else
            playerState = PlayerState.leftIdle;
        }
        current = playerState;
        nextPosition += (joystick!.relativeDelta * moveSpeed * dt);
      }
    }

    velocity.x = horizontalDirection * moveSpeed;
    velocity.y = verticalDirection * moveSpeed;
    nextPosition += velocity * dt;

    if (!isBlocked) {
      position = nextPosition;
    }

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

        final sepratationDistance = hitBoxSize - collisionNormal.length;
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

  void loadAnimations() {
    final double frameSize = 64;
    bottomIdle = SpriteAnimation.fromFrameData(
        game.images.fromCache(slimeImage),
        SpriteAnimationData.sequenced(
            loop: true,
            amount: 6,
            stepTime: 0.1,
            texturePosition: Vector2(0, 0 * frameSize),
            textureSize: Vector2.all(64)));
    topIdle = SpriteAnimation.fromFrameData(
        game.images.fromCache(slimeImage),
        SpriteAnimationData.sequenced(
            loop: true,
            amount: 6,
            stepTime: 0.1,
            texturePosition: Vector2(0, 1 * frameSize),
            textureSize: Vector2.all(64)));
    leftIdle = SpriteAnimation.fromFrameData(
        game.images.fromCache(slimeImage),
        SpriteAnimationData.sequenced(
            loop: true,
            amount: 6,
            stepTime: 0.1,
            texturePosition: Vector2(0, 2 * frameSize),
            textureSize: Vector2.all(64)));
    rightIdle = SpriteAnimation.fromFrameData(
        game.images.fromCache(slimeImage),
        SpriteAnimationData.sequenced(
            loop: true,
            amount: 6,
            stepTime: 0.1,
            texturePosition: Vector2(0, 3 * frameSize),
            textureSize: Vector2.all(64)));
  }
}
