import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:nfc_between_worlds/src/game/actors/player.dart';
import 'package:nfc_between_worlds/src/game/objects/ground.dart';
import 'package:nfc_between_worlds/src/game/objects/wall.dart';
import 'package:nfc_between_worlds/src/test_game.dart';

class BoxItem extends SpriteComponent
    with CollisionCallbacks, HasGameReference<TestGame> {
  BoxItem({required super.position})
      : super(anchor: Anchor.center, size: Vector2.all(32));
  final Vector2 hitBoxSize = Vector2.all(32);
  @override
  FutureOr<void> onLoad() async {
    sprite = Sprite(game.images.fromCache('box.png'));

    add(RectangleHitbox(
        size: hitBoxSize, anchor: Anchor.center, position: Vector2.all(16)));
    return super.onLoad();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player) {
      if (intersectionPoints.length == 2) {
        final mid =
            (intersectionPoints.elementAt(0) - intersectionPoints.elementAt(1));
        if (mid.x == 0 && mid.y < 0) position.x += 1;
        if (mid.x == 0 && mid.y > 0) position.x -= 1;
        if (mid.y == 0 && mid.x > 0) position.y += 1;
        if (mid.y == 0 && mid.x < 0) position.y -= 1;
      }
    }
    if (other is Wall || other is Ground) {
      if (intersectionPoints.length == 2) {
        final mid = (intersectionPoints.elementAt(0) +
                intersectionPoints.elementAt(1)) /
            2;
        final collisionNormal = absoluteCenter - mid;

        final separationDistance = (hitBoxSize.x / 2) - collisionNormal.length;
        collisionNormal.normalize();

        position += collisionNormal.scaled(separationDistance);
      }
    }
    super.onCollision(intersectionPoints, other);
  }
}
