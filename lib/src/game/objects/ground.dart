import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class Ground extends PositionComponent {
  Ground() : super();

  @override
  FutureOr<void> onLoad() {
    add(RectangleHitbox(collisionType: CollisionType.passive));
    return super.onLoad();
  }
}
