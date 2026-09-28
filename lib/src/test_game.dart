import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/widgets.dart';
import 'package:nfc_between_worlds/src/game/actors/player.dart';
import 'package:nfc_between_worlds/src/game/actors/player_state.dart';
import 'package:nfc_between_worlds/src/game/objects/ground.dart';
import 'package:nfc_between_worlds/src/game/objects/key.dart';
import 'package:nfc_between_worlds/src/game/objects/wall.dart';
import 'package:nfc_between_worlds/src/provider/nfc_data_notifier.dart';

class TestGame extends FlameGame
    with HasCollisionDetection, WidgetsBindingObserver {
  TestGame({
    required this.nfcDataNotifier,
    this.characterPosition,
    this.slimeType,
  });
  String? slimeType;
  Vector2? characterPosition;
  final NfcDataNotifier nfcDataNotifier;
  String walkingType = '';
  String slimeImage = '';

  late Player _player;
  late JoystickComponent _joystick;
  late KeyItem _key;

  List<PositionComponent> wallsList = [];
  List<PositionComponent> blockedZone = [];
  late PositionComponent door;

  ObjectGroup? waterObjects;
  ObjectGroup? landObjects;
  ObjectGroup? lavaObjects;
  ObjectGroup? doorObjects;

  @override
  Color backgroundColor() {
    return const Color.fromARGB(255, 173, 223, 247);
  }

  @override
  FutureOr<void> onLoad() async {
    WidgetsBinding.instance.addObserver(this);
    nfcDataNotifier.addListener(_updateWorldType);
    await images.loadAll([
      'Slime1_Idle_body.png',
      'Slime2_Idle_body.png',
      'Slime3_Idle_body.png',
      'joystick.png',
      'key.png',
      'box.png',
    ]);

    final sheet = SpriteSheet.fromColumnsAndRows(
      image: images.fromCache('joystick.png'),
      columns: 6,
      rows: 1,
    );

    _joystick = JoystickComponent(
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

    final firstMap = await TiledComponent.load(
      'first_map.tmx',
      Vector2.all(32),
    );

    final spawnPoint = firstMap.tileMap
        .getLayer<ObjectGroup>('SpawnPoint')!
        .objects
        .first;
    final wallObjects = firstMap.tileMap.getLayer<ObjectGroup>('Wall');
    bool isBlocked = false;
    waterObjects = firstMap.tileMap.getLayer<ObjectGroup>('WaterZone');
    landObjects = firstMap.tileMap.getLayer<ObjectGroup>('LandZone');
    lavaObjects = firstMap.tileMap.getLayer<ObjectGroup>('LavaZone');
    doorObjects = firstMap.tileMap.getLayer<ObjectGroup>('Door');
    slimeType ??= 'Land';
    loadWalkingType();
    if (characterPosition != null) {
      isBlocked = isPlayerInBlockedZone(characterPosition!);
    } else {
      characterPosition = Vector2(spawnPoint.x, spawnPoint.y);
    }

    _player = Player(
      playerState: PlayerState.bottomIdle,
      isBlocked: isBlocked,
      position: characterPosition,
      joystick: _joystick,
      slimeImage: slimeImage,
    );

    world.add(firstMap);

    for (var wall in wallObjects!.objects) {
      wallsList.add(
        Wall()
          ..position = Vector2(wall.x, wall.y)
          ..width = wall.width
          ..height = wall.height
          ..debugColor = Color.fromARGB(1, 231, 2, 193),
      );
      world.add(wallsList.last);
    }

    door = Wall()
      ..position = Vector2(
        doorObjects!.objects.first.x,
        doorObjects!.objects.first.y,
      )
      ..width = doorObjects!.objects.first.width
      ..height = doorObjects!.objects.first.height
      ..debugMode = true;

    _key = KeyItem(position: Vector2(spawnPoint.x + 64, spawnPoint.y))
      ..debugMode = true;

    world.add(_key);
    world.add(_player);
    world.add(door);
    camera.follow(_player, snap: true);
    camera.viewport.add(_joystick);

    nfcDataNotifier.startNfcCardTypeScan();

    return super.onLoad();
  }

  void _updateWorldType() {
    if (nfcDataNotifier.shouldUpdate) {
      for (PositionComponent zone in blockedZone) {
        world.remove(zone);
      }

      final playerState = _player.playerState;
      final position = _player.position;

      blockedZone = [];
      slimeType = nfcDataNotifier.nfcType;

      world.remove(_player);
      loadWalkingType();

      bool isBlocked = isPlayerInBlockedZone(position);
      _player = Player(
        playerState: playerState,
        position: position,
        joystick: _joystick,
        slimeImage: slimeImage,
        isBlocked: isBlocked,
      );

      world.add(_player);
      camera.follow(_player, snap: true);
    }
  }

  void loadWalkingType() {
    switch (slimeType) {
      case 'Land':
        addBlockedZone(waterObjects);
        addBlockedZone(lavaObjects);
        slimeImage = 'Slime1_Idle_body.png';
      case 'Water':
        addBlockedZone(landObjects);
        addBlockedZone(lavaObjects);
        slimeImage = 'Slime2_Idle_body.png';
      case 'Lava':
        addBlockedZone(waterObjects);
        addBlockedZone(landObjects);
        slimeImage = 'Slime3_Idle_body.png';
    }
  }

  void addBlockedZone(ObjectGroup? zoneObjects) {
    if (zoneObjects != null) {
      for (var zone in zoneObjects.objects) {
        blockedZone.add(
          Ground()
            ..position = Vector2(zone.x, zone.y)
            ..width = zone.width
            ..height = zone.height
            ..debugColor = Color.fromARGB(1, 88, 148, 9),
        );
        world.add(blockedZone.last);
      }
    }
  }

  bool isPlayerInBlockedZone(Vector2 position) {
    return blockedZone.any((zone) => zone.containsPoint(position));
  }

  @override
  void onRemove() {
    nfcDataNotifier.removeListener(_updateWorldType);
    super.onRemove();
  }

  void collectKey() {
    world.remove(door);
  }

  Future<void> savePlayerDataOnNfc({required Completer stopNfcWriting}) async {
    await nfcDataNotifier.savePlayerDataOnNfc(
      position: _player.position,
      stopNfcWriting: stopNfcWriting,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      pauseEngine();
    } else if (state == AppLifecycleState.resumed) {
      resumeEngine();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
