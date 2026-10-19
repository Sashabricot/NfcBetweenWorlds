import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';
import 'package:nfc_between_worlds/src/game/actors/player.dart';
import 'package:nfc_between_worlds/src/game/objects/box.dart';

import 'package:nfc_between_worlds/src/test_game.dart';

class Button extends SpriteGroupComponent
    with CollisionCallbacks, HasGameReference<TestGame> {
  Button({
    required super.position,
    required this.buttonPressedAction,
    required this.buttonNotPressedAction,
  }) : super(anchor: Anchor.center, size: Vector2.all(32));
  final Vector2 hitBoxSize = Vector2.all(16);
  VoidCallback buttonPressedAction;
  VoidCallback buttonNotPressedAction;
  bool isPressed = false;
  @override
  FutureOr<void> onLoad() async {
    sprites = {
      'notPressed': Sprite(
        game.images.fromCache('button.png'),
        srcPosition: Vector2.all(0),
        srcSize: Vector2.all(32),
      ),
      'pressed': Sprite(
        game.images.fromCache('button.png'),
        srcPosition: Vector2(32, 0),
        srcSize: Vector2.all(32),
      ),
    };
    current = 'notPressed';

    add(
      RectangleHitbox(
        size: hitBoxSize,
        anchor: Anchor.center,
        position: Vector2.all(16),
      ),
    );
    return super.onLoad();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player || other is BoxItem) {
      if (isPressed == false) {
        isPressed = true;
        buttonPressedAction();
      }
      current = 'pressed';
      print('pressing');
    }
    super.onCollision(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if (other is Player || other is BoxItem) {
      current = 'notPressed';
      isPressed = false;
      buttonNotPressedAction();
    }
    print('stopped');
    super.onCollisionEnd(other);
  }
}
