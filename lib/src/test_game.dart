import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flame_tiled_utils/flame_tiled_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:gamepads/gamepads.dart';
import 'package:nfc_between_worlds/src/game/actors/player.dart';
import 'package:nfc_between_worlds/src/game/actors/player_state.dart';
import 'package:nfc_between_worlds/src/game/objects/box.dart';
import 'package:nfc_between_worlds/src/game/objects/door.dart';
import 'package:nfc_between_worlds/src/game/objects/ground.dart';
import 'package:nfc_between_worlds/src/game/objects/key.dart';
import 'package:nfc_between_worlds/src/game/objects/teleporter.dart';
import 'package:nfc_between_worlds/src/game/objects/wall.dart';
import 'package:nfc_between_worlds/src/provider/nfc_data_notifier.dart';

class TestGame extends FlameGame
    with HasCollisionDetection, WidgetsBindingObserver {
  TestGame({
    required this.nfcDataNotifier,
    this.characterPosition,
    this.slimeType,
    this.level,
    this.characterItems,
  });
  String? slimeType;
  Vector2? characterPosition;
  String? level;
  final NfcDataNotifier nfcDataNotifier;
  String walkingType = '';
  String slimeImage = '';
  List<String> collectedItems = [];
  String worldKey = '';
  List<String>? characterItems;

  late Player _player;
  late JoystickComponent _joystick;
  late KeyItem _key;
  late BoxItem _box;

  List<PositionComponent> wallsList = [];
  List<PositionComponent> blockedZone = [];
  List<PositionComponent> teleporterZone = [];
  late PositionComponent beginnerDoor;

  ObjectGroup? waterObjects;
  ObjectGroup? landObjects;
  ObjectGroup? lavaObjects;
  ObjectGroup? groundObjects;
  ObjectGroup? beginnerDoorObjects;
  ObjectGroup? teleportationObjects;
  ObjectGroup? firstMapTeleporter;
  ObjectGroup? beginnerMapTeleporter;
  ObjectGroup? keyItems;
  ObjectGroup? boxItems;

  PositionComponent? landLayer;
  PositionComponent? lavaLayer;
  PositionComponent? waterLayer;
  PositionComponent? bordersLayer;
  PositionComponent? bridgesLayer;
  PositionComponent? decorationLayer;
  PositionComponent? waterBridgesLayer;

  late TiledComponent levelMap;

  @override
  Color backgroundColor() {
    return const Color.fromARGB(255, 173, 223, 247);
  }

  @override
  FutureOr<void> onLoad() async {
    if (characterItems != null && characterItems!.isNotEmpty) {
      collectedItems.addAll(characterItems!);
    }
    WidgetsBinding.instance.addObserver(this);
    nfcDataNotifier.addListener(_updateWorldType);
    await images.loadAll([
      'Slime1_Idle_body.png',
      'Slime2_Idle_body.png',
      'Slime3_Idle_body.png',
      'joystick.png',
      'key.png',
      'box.png',
      'DoubleDoor1.png',
    ]);
    _loadJoystick();
    final gamepads = await Gamepads.list();
    if (gamepads.isEmpty) {
      camera.viewport.add(_joystick);
    }

    Gamepads.onConnected.listen((event) {
      camera.viewport.remove(_joystick);
    });

    Gamepads.onDisconnected.listen((event) {
      camera.viewport.add(_joystick);
    });

    level ??= 'first_map.tmx';
    await _loadLevel(level!);

    nfcDataNotifier.startNfcCardTypeScan();

    return super.onLoad();
  }

  Future<void> _loadLevel(String level) async {
    switch (level) {
      case 'first_map.tmx':
        worldKey = 'BeginnerKey';
      case 'beginner_map.tmx':
        worldKey = 'IntermediateKey';
    }
    levelMap = await TiledComponent.load(level, Vector2.all(32));

    final spawnPoint = levelMap.tileMap
        .getLayer<ObjectGroup>('SpawnPoint')!
        .objects
        .first;

    final wallObjects = levelMap.tileMap.getLayer<ObjectGroup>('Wall');
    bool isBlocked = false;

    waterObjects = levelMap.tileMap.getLayer<ObjectGroup>('WaterZone');
    landObjects = levelMap.tileMap.getLayer<ObjectGroup>('LandZone');
    lavaObjects = levelMap.tileMap.getLayer<ObjectGroup>('LavaZone');
    beginnerDoorObjects = levelMap.tileMap.getLayer<ObjectGroup>(
      'BeginnerDoor',
    );
    teleportationObjects = levelMap.tileMap.getLayer<ObjectGroup>('Teleporter');
    groundObjects = levelMap.tileMap.getLayer<ObjectGroup>('GroundZone');
    firstMapTeleporter = levelMap.tileMap.getLayer<ObjectGroup>(
      'FirstMapTeleporter',
    );
    beginnerMapTeleporter = levelMap.tileMap.getLayer<ObjectGroup>(
      'BeginnerMapTeleporter',
    );
    boxItems = levelMap.tileMap.getLayer<ObjectGroup>('Box');
    keyItems = levelMap.tileMap.getLayer<ObjectGroup>(worldKey);

    slimeType ??= 'Land';

    _loadWalkingType();

    if (characterPosition != null) {
      isBlocked = isPlayerInBlockedZone(characterPosition!);
    } else {
      characterPosition = Vector2(spawnPoint.x, spawnPoint.y);
      isBlocked = isPlayerInBlockedZone(characterPosition!);
    }

    _player = Player(
      playerState: PlayerState.bottomIdle,
      isBlocked: isBlocked,
      position: characterPosition,
      joystick: _joystick,
      slimeImage: slimeImage,
    );

    if (wallObjects != null) {
      for (var wall in wallObjects.objects) {
        wallsList.add(
          Wall()
            ..position = Vector2(wall.x, wall.y)
            ..width = wall.width
            ..height = wall.height
            ..debugColor = Color.fromRGBO(231, 2, 193, 0.004),
        );
        world.add(wallsList.last);
      }
    }
    if (beginnerDoorObjects != null) {
      beginnerDoor = Door(keyItemString: worldKey)
        ..position = Vector2(
          beginnerDoorObjects!.objects.first.x,
          beginnerDoorObjects!.objects.first.y,
        );

      beginnerDoor.priority = 3;
      world.add(beginnerDoor);
    }
    if (!collectedItems.contains(worldKey) && keyItems != null) {
      _key = KeyItem(
        position: Vector2(keyItems!.objects.first.x, keyItems!.objects.first.y),
      );
      _key.priority = 2;
      world.add(_key);
    }
    if (boxItems != null) {
      _box = BoxItem(
        position: Vector2(boxItems!.objects.first.x, boxItems!.objects.first.y),
      )..debugMode = true;

      _box.priority = 3;
      world.add(_box);
    }

    _loadTeleporter();

    _loadLayers(levelMap);
  }

  void _loadLayers(TiledComponent levelMap) {
    final imageCompiler = ImageBatchCompiler();

    waterLayer = imageCompiler.compileMapLayer(
      tileMap: levelMap.tileMap,
      layerNames: ['water'],
    );
    lavaLayer = imageCompiler.compileMapLayer(
      tileMap: levelMap.tileMap,
      layerNames: ['lava'],
    );
    landLayer = imageCompiler.compileMapLayer(
      tileMap: levelMap.tileMap,
      layerNames: ['land'],
    );
    decorationLayer = imageCompiler.compileMapLayer(
      tileMap: levelMap.tileMap,
      layerNames: ['decoration'],
    );
    bridgesLayer = imageCompiler.compileMapLayer(
      tileMap: levelMap.tileMap,
      layerNames: ['bridges'],
    );
    bordersLayer = imageCompiler.compileMapLayer(
      tileMap: levelMap.tileMap,
      layerNames: ['borders'],
    );
    waterBridgesLayer = imageCompiler.compileMapLayer(
      tileMap: levelMap.tileMap,
      layerNames: ['water_bridges'],
    );

    if (waterLayer != null) {
      waterLayer!.priority = 1;
      world.add(waterLayer!);
    }
    if (lavaLayer != null) {
      lavaLayer!.priority = 2;
      world.add(lavaLayer!);
    }
    if (landLayer != null) {
      landLayer!.priority = 1;
      world.add(landLayer!);
    }
    if (decorationLayer != null) {
      decorationLayer!.priority = 4;
      world.add(decorationLayer!);
    }
    if (bridgesLayer != null) {
      if (slimeType == 'Water') {
        bridgesLayer!.priority = 4;
        world.add(bridgesLayer!);
      } else {
        bridgesLayer!.priority = 1;
        world.add(bridgesLayer!);
      }
    }
    if (bordersLayer != null) {
      bordersLayer!.priority = 1;
      world.add(bordersLayer!);
    }
    if (waterBridgesLayer != null) {
      waterBridgesLayer!.priority = 2;
      world.add(waterBridgesLayer!);
    }

    _player.priority = 3;

    world.add(_player);
    camera.follow(_player, snap: true);
  }

  void _removeLayers() {
    if (waterLayer != null) {
      world.remove(waterLayer!);
    }
    if (lavaLayer != null) {
      world.remove(lavaLayer!);
    }
    if (landLayer != null) {
      world.remove(landLayer!);
    }
    if (decorationLayer != null) {
      world.remove(decorationLayer!);
    }
    if (bridgesLayer != null) {
      world.remove(bridgesLayer!);
    }
    if (bordersLayer != null) {
      world.remove(bordersLayer!);
    }
  }

  void _loadTeleporter() {
    String level = '';
    if (teleportationObjects != null) {
      level = 'teleportation_map.tmx';
      _addTeleporterObjects(
        level: level,
        teleportationObjectGroup: teleportationObjects,
      );
    }
    if (firstMapTeleporter != null) {
      level = 'first_map.tmx';
      _addTeleporterObjects(
        level: level,
        teleportationObjectGroup: firstMapTeleporter,
      );
    }
    if (beginnerMapTeleporter != null) {
      level = 'beginner_map.tmx';
      _addTeleporterObjects(
        level: level,
        teleportationObjectGroup: beginnerMapTeleporter,
      );
    }
  }

  void _addTeleporterObjects({
    required String level,
    required ObjectGroup? teleportationObjectGroup,
  }) {
    if (teleportationObjectGroup != null) {
      for (var teleporter in teleportationObjectGroup.objects) {
        teleporterZone.add(
          Teleporter(level)
            ..position = Vector2(teleporter.x, teleporter.y)
            ..width = teleporter.width
            ..height = teleporter.height,
        );
        world.add(teleporterZone.last);
      }
    }
  }

  void changeLevel(String newLevel) {
    _resetWorldValues();
    level = newLevel;
    _loadLevel(newLevel);
  }

  void _resetWorldValues() {
    world.children.whereType<TiledComponent>().forEach(
      (element) => element.removeFromParent(),
    );
    world.children.whereType<PositionComponent>().forEach(
      (element) => element.removeFromParent(),
    );
    wallsList = [];
    blockedZone = [];
    teleporterZone = [];
    world.remove(_player);
    characterPosition = null;
  }

  void _loadJoystick() {
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
  }

  void _loadWalkingType() {
    switch (slimeType) {
      case 'Land':
        addBlockedZone(waterObjects);
        addBlockedZone(lavaObjects);
        slimeImage = 'Slime1_Idle_body.png';
      case 'Water':
        addBlockedZone(landObjects);
        addBlockedZone(lavaObjects);
        addBlockedZone(groundObjects);
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
      _loadWalkingType();

      bool isBlocked = isPlayerInBlockedZone(position);
      _player = Player(
        playerState: playerState,
        position: position,
        joystick: _joystick,
        slimeImage: slimeImage,
        isBlocked: isBlocked,
      );

      _removeLayers();
      _loadLayers(levelMap);

      camera.follow(_player, snap: true);
    } else if (nfcDataNotifier.shouldTeleportToSlimeHub) {
      if (collectedItems.contains('BeginnerKey')) {
        changeLevel('teleportation_map.tmx');
      } else {
        print('should have first key');
      }
    }
  }

  Future<void> savePlayerDataOnNfc({required Completer stopNfcWriting}) async {
    await nfcDataNotifier.savePlayerDataOnNfc(
      position: _player.position,
      level: level!,
      stopNfcWriting: stopNfcWriting,
      collectedItems: collectedItems,
    );
  }

  void collectKey() {
    world.remove(beginnerDoor);
    collectedItems.add(worldKey);

    beginnerDoor = Door(keyItemString: worldKey);
    if (beginnerDoorObjects != null) {
      beginnerDoor = Door(keyItemString: worldKey)
        ..position = Vector2(
          beginnerDoorObjects!.objects.first.x,
          beginnerDoorObjects!.objects.first.y,
        );

      beginnerDoor.priority = 3;
      world.add(beginnerDoor);
    }
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
  void onRemove() {
    nfcDataNotifier.removeListener(_updateWorldType);
    super.onRemove();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
