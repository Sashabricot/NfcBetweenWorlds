import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:nfc_between_worlds/src/test_game.dart';

class TimerPositionComponent extends PositionComponent
    with HasGameReference<TestGame> {
  TimerPositionComponent() : super(anchor: .center, size: Vector2(64, 64));

  TextComponent textComponent = TextComponent(
    text: '0',
    position: Vector2(32, 32),
    priority: 5,
    anchor: .center,
    textRenderer: TextPaint(
      style: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontFamily: 'Pixel',
        shadows: <Shadow>[
          Shadow(
            offset: Offset(3.0, 3.0),
            blurRadius: 3.0,
            color: Color.fromARGB(255, 0, 0, 0),
          ),
        ],
      ),
    ),
  );

  SpriteComponent spriteComponent = SpriteComponent(
    position: Vector2(0, 32 - 12),
    size: Vector2(24, 24),
  );
  int componentTimer = 0;
  @override
  FutureOr<void> onLoad() {
    spriteComponent = SpriteComponent(
      position: Vector2(32 + (textComponent.width / 2), 32),
      sprite: Sprite(game.images.fromCache('timer.png')),
      size: Vector2(24, 24),
      anchor: .centerLeft,
    );
    add(spriteComponent);
    add(textComponent);
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (componentTimer != game.gameTimer) {
      componentTimer = game.gameTimer;
      textComponent.text = '$componentTimer';
      spriteComponent.position = Vector2(32 + (textComponent.width / 2), 32);
    }

    super.update(dt);
  }
}
