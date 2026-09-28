import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:nfc_between_worlds/src/game/actors/player.dart';
import 'package:nfc_between_worlds/src/test_game.dart';

class Teleporter extends PositionComponent
    with CollisionCallbacks, HasGameReference<TestGame> {
  Teleporter(this.level) : super();
  final String level;
  bool hasChanged = false;
  @override
  FutureOr<void> onLoad() {
    add(RectangleHitbox());
    return super.onLoad();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player) {
      if (!hasChanged) {
        game.changeLevel(level);
        hasChanged = true;
      }
    }
    super.onCollision(intersectionPoints, other);
  }
}
