import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:klondike/src/test_game.dart';

class Land extends PositionComponent
    with CollisionCallbacks, HasGameReference<TestGame> {
  Land() : super();

  @override
  FutureOr<void> onLoad() {
    add(RectangleHitbox(collisionType: CollisionType.passive));
    return super.onLoad();
  }
}
