import 'dart:async';
import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:nfc_between_worlds/src/game/actors/player.dart';
import 'package:nfc_between_worlds/src/test_game.dart';

class Teleporter extends PositionComponent
    with CollisionCallbacks, HasGameReference<TestGame> {
  Teleporter(this.level) : super();
  final String level;
  bool hasChanged = false;
  Random rnd = Random();
  Vector2 randomVector2() => (Vector2.random(rnd) - Vector2.random(rnd)) * 200;
  @override
  FutureOr<void> onLoad() {
    add(RectangleHitbox());
    return super.onLoad();
  }

  @override
  void onCollision(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) async {
    if (other is Player) {
      if (!hasChanged) {
        game.interval.timer.pause();
        hasChanged = true;
        game.player.add(
          ParticleSystemComponent(
            particle: Particle.generate(
              count: 10,
              generator: (i) => AcceleratedParticle(
                acceleration: randomVector2(),
                child: CircleParticle(
                  paint: Paint()..color = Colors.blue,
                  radius: 2,
                ),
              ),
            ),

            anchor: .center,
            position: Vector2(super.width / 2, super.height / 2),
          ),
        );
        await Future.delayed(Duration(milliseconds: 500));
        game.changeLevel(level);
      }
    }
    super.onCollision(intersectionPoints, other);
  }
}
