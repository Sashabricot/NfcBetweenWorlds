import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:klondike/src/test_game.dart';

class Ground extends PositionComponent
    with CollisionCallbacks, HasGameReference<TestGame> {
  Ground() : super();

  @override
  FutureOr<void> onLoad() {
    add(RectangleHitbox(collisionType: CollisionType.passive));
    return super.onLoad();
  }
}
