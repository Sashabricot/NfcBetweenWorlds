import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class Wall extends PositionComponent {
  Wall() : super();

  @override
  FutureOr<void> onLoad() {
    add(RectangleHitbox(collisionType: CollisionType.passive));
    return super.onLoad();
  }
}
