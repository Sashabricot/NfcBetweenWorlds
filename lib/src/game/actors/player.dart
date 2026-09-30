import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:gamepads/gamepads.dart';
import 'package:nfc_between_worlds/src/game/actors/player_state.dart';
import 'package:nfc_between_worlds/src/game/objects/box.dart';
import 'package:nfc_between_worlds/src/game/objects/door.dart';
import 'package:nfc_between_worlds/src/game/objects/ground.dart';
import 'package:nfc_between_worlds/src/game/objects/key.dart';
import 'package:nfc_between_worlds/src/game/objects/wall.dart';
import 'package:nfc_between_worlds/src/test_game.dart';

class Player extends SpriteAnimationGroupComponent<PlayerState>
    with CollisionCallbacks, HasGameReference<TestGame> {
  Player({
    required this.playerState,
    required this.isBlocked,
    required this.slimeImage,
    this.joystick,
    required super.position,
  }) : super(size: Vector2.all(64), anchor: Anchor.center);

  PlayerState playerState;

  SpriteAnimation? topIdle;
  SpriteAnimation? bottomIdle;
  SpriteAnimation? leftIdle;
  SpriteAnimation? rightIdle;

  final JoystickComponent? joystick;
  final String slimeImage;
  final bool isBlocked;
  final double hitBoxSize = 10;
  final double moveSpeed = 100;
  final Vector2 velocity = Vector2.zero();

  Vector2 leftStickDirection = Vector2.zero();

  @override
  FutureOr<void> onLoad() {
    Gamepads.normalizedEvents.listen((event) {
      if (event.axis == GamepadAxis.leftStickX) {
        leftStickDirection = Vector2(event.value, leftStickDirection.y);
      }
      if (event.axis == GamepadAxis.leftStickY) {
        leftStickDirection = Vector2(leftStickDirection.x, -event.value);
      }
    });

    Gamepads.onDisconnected.listen((event) {
      leftStickDirection = Vector2.zero();
    });
    loadAnimations();
    animations = {
      PlayerState.topIdle: topIdle!,
      PlayerState.bottomIdle: bottomIdle!,
      PlayerState.leftIdle: leftIdle!,
      PlayerState.rightIdle: rightIdle!,
    };
    current = playerState;
    add(
      CircleHitbox(
        radius: hitBoxSize,
        anchor: Anchor.center,
        position: Vector2.all(32),
      ),
    );
  }

  void updatePlayerDirection(Vector2 direction) {
    if (direction.x > 0) {
      if (direction.y > 0.4) {
        playerState = PlayerState.bottomIdle;
      } else if (direction.y < -0.4) {
        playerState = PlayerState.topIdle;
      } else {
        playerState = PlayerState.rightIdle;
      }
    } else if (direction.x < 0) {
      if (direction.y > 0.4) {
        playerState = PlayerState.bottomIdle;
      } else if (direction.y < -0.4) {
        playerState = PlayerState.topIdle;
      } else {
        playerState = PlayerState.leftIdle;
      }
    }
    current = playerState;
  }

  bool checkLeftStickDirection(Vector2 direction) {
    if (direction.x > 0.1 || direction.x < -0.1) {
      return true;
    } else if (direction.y > 0.1 || direction.y < -0.1) {
      return true;
    }
    return false;
  }

  @override
  void update(double dt) {
    Vector2 nextPosition = position;

    if (joystick != null) {
      if (joystick!.direction != JoystickDirection.idle) {
        updatePlayerDirection(joystick!.relativeDelta);
        nextPosition += (joystick!.relativeDelta * moveSpeed * dt);
      }
    }
    if (checkLeftStickDirection(leftStickDirection)) {
      updatePlayerDirection(leftStickDirection);
      nextPosition += leftStickDirection * moveSpeed * dt;
    }

    if (!isBlocked) {
      position = nextPosition;
    }

    super.update(dt);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Wall || other is Ground || other is BoxItem || other is Door) {
      if (intersectionPoints.length == 2) {
        final mid =
            (intersectionPoints.elementAt(0) +
                intersectionPoints.elementAt(1)) /
            2;
        final collisionNormal = absoluteCenter - mid;

        final separationDistance = hitBoxSize - collisionNormal.length;
        collisionNormal.normalize();

        position += collisionNormal.scaled(separationDistance);
      }
    }
    super.onCollision(intersectionPoints, other);
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    if (other is KeyItem) {
      collectKey(other);
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  void collectKey(KeyItem key) {
    key.collect();
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
        textureSize: Vector2.all(64),
      ),
    );
    topIdle = SpriteAnimation.fromFrameData(
      game.images.fromCache(slimeImage),
      SpriteAnimationData.sequenced(
        loop: true,
        amount: 6,
        stepTime: 0.1,
        texturePosition: Vector2(0, 1 * frameSize),
        textureSize: Vector2.all(64),
      ),
    );
    leftIdle = SpriteAnimation.fromFrameData(
      game.images.fromCache(slimeImage),
      SpriteAnimationData.sequenced(
        loop: true,
        amount: 6,
        stepTime: 0.1,
        texturePosition: Vector2(0, 2 * frameSize),
        textureSize: Vector2.all(64),
      ),
    );
    rightIdle = SpriteAnimation.fromFrameData(
      game.images.fromCache(slimeImage),
      SpriteAnimationData.sequenced(
        loop: true,
        amount: 6,
        stepTime: 0.1,
        texturePosition: Vector2(0, 3 * frameSize),
        textureSize: Vector2.all(64),
      ),
    );
  }
}
