import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:testgame/src/test_game.dart';

class Wall extends PositionComponent with HasGameReference<TestGame> {
  Wall() : super();

  @override
  FutureOr<void> onLoad() {
    add(RectangleHitbox(collisionType: CollisionType.passive));
    return super.onLoad();
  }
}
