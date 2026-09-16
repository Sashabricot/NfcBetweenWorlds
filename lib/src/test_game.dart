import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/sprite.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/widgets.dart';
import 'package:klondike/src/game/actors/player.dart';
import 'package:klondike/src/game/objects/land.dart';
import 'package:klondike/src/game/objects/wall.dart';
import 'package:klondike/src/provider/nfc_data_notifier.dart';

class TestGame extends FlameGame
    with HasCollisionDetection, HasKeyboardHandlerComponents {
  TestGame();
  String walkingType = '';
  late Player _player;
  var wallsList = [];
  var blockedZone = [];
  var waterObjects;
  var landObjects;
  var lavaObjects;
  @override
  Color backgroundColor() {
    return const Color.fromARGB(255, 173, 223, 247);
  }

  NfcDataNotifier nfcDataNotifier = NfcDataNotifier();

  @override
  FutureOr<void> onLoad() async {
    nfcDataNotifier.addListener(_removeWalls);
    nfcDataNotifier.startNfcRead();
    await images.loadAll([
      'Slime1_Walk_body.png',
      'ember.png',
      'joystick.png',
    ]);

    final sheet = SpriteSheet.fromColumnsAndRows(
      image: images.fromCache('joystick.png'),
      columns: 6,
      rows: 1,
    );

    final joystick = JoystickComponent(
      knob: SpriteComponent(
        sprite: sheet.getSpriteById(1),
        size: Vector2.all(100),
      ),
      background: SpriteComponent(
        sprite: sheet.getSpriteById(0),
        size: Vector2.all(150),
      ),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );

    final component = await TiledComponent.load(
      'first_map.tmx',
      Vector2.all(32),
    );
    final spawnPoint =
        component.tileMap.getLayer<ObjectGroup>('SpawnPoint')!.objects.first;

    final wallObjects = component.tileMap.getLayer<ObjectGroup>('Wall');
    waterObjects = component.tileMap.getLayer<ObjectGroup>('WaterZone');
    landObjects = component.tileMap.getLayer<ObjectGroup>('LandZone');
    lavaObjects = component.tileMap.getLayer<ObjectGroup>('LavaZone');

    _player = Player(
        position: Vector2(spawnPoint.x, spawnPoint.y), joystick: joystick)
      ..debugMode = true;
    world.add(component);

    for (var wall in wallObjects!.objects) {
      wallsList.add(Wall()
        ..position = Vector2(wall.x, wall.y)
        ..width = wall.width
        ..height = wall.height
        ..debugMode = true
        ..debugColor = Color.fromARGB(1, 231, 2, 193));
      world.add(wallsList.last);
    }
    addBlockedZone(waterObjects);
    world.add(_player);

    camera.follow(_player, snap: true);
    camera.viewport.add(joystick);
    return super.onLoad();
  }

  void _removeWalls() {
    for (var element in blockedZone) {
      world.remove(element);
    }
    blockedZone = [];
    walkingType = nfcDataNotifier.nfcType;

    if (walkingType == 'Land') {
      addBlockedZone(waterObjects);
      addBlockedZone(lavaObjects);
    } else if (walkingType == 'Water') {
      addBlockedZone(landObjects);
      addBlockedZone(lavaObjects);
    } else if (walkingType == 'Lava') {
      addBlockedZone(waterObjects);
      addBlockedZone(landObjects);
    }
  }

  void addBlockedZone(ObjectGroup? zoneObjects) {
    if (zoneObjects != null) {
      for (var zone in zoneObjects.objects) {
        blockedZone.add(Ground()
          ..position = Vector2(zone.x, zone.y)
          ..width = zone.width
          ..height = zone.height
          ..debugMode = true
          ..debugColor = Color.fromARGB(1, 88, 148, 9));
        world.add(blockedZone.last);
      }
    }
  }

  @override
  void onRemove() {
    nfcDataNotifier.removeListener(_removeWalls);
    super.onRemove();
  }
}
