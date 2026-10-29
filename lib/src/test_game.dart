import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flame_tiled_utils/flame_tiled_utils.dart';
import 'package:flutter/material.dart';
import 'package:gamepads/gamepads.dart';
import 'package:nfc_between_worlds/src/game/actors/player.dart';
import 'package:nfc_between_worlds/src/game/actors/player_state.dart';
import 'package:nfc_between_worlds/src/game/objects/actionable_door.dart';
import 'package:nfc_between_worlds/src/game/objects/box.dart';
import 'package:nfc_between_worlds/src/game/objects/button.dart';
import 'package:nfc_between_worlds/src/game/objects/door.dart';
import 'package:nfc_between_worlds/src/game/objects/ground.dart';
import 'package:nfc_between_worlds/src/game/objects/key.dart';
import 'package:nfc_between_worlds/src/game/objects/teleporter.dart';
import 'package:nfc_between_worlds/src/game/objects/timer_position_component.dart';
import 'package:nfc_between_worlds/src/game/objects/wall.dart';
import 'package:nfc_between_worlds/src/leaderboard/hive_service.dart';
import 'package:nfc_between_worlds/src/menu/congratulations_menu.dart';
import 'package:nfc_between_worlds/src/menu/main_menu.dart';
import 'package:nfc_between_worlds/src/models/leaderboard_record.dart';
import 'package:nfc_between_worlds/src/provider/nfc_data_notifier.dart';

class TestGame extends FlameGame
    with HasCollisionDetection, WidgetsBindingObserver {
  TestGame({
    required this.nfcDataNotifier,
    this.characterPosition,
    this.slimeType,
    this.level,
    this.characterItems,
    this.playerTimer,
    required this.savedBoxesPosition,
    required this.characterName,
  });

  String characterName;
  String? slimeType;
  Vector2? characterPosition;
  List<Vector2> savedBoxesPosition;
  String? level;
  final NfcDataNotifier nfcDataNotifier;
  String walkingType = '';
  String slimeImage = '';
  List<String> collectedItems = [];
  String worldKey = '';
  List<String>? characterItems;
  bool removeLavaWalls = false;
  int actionedButtonsNumber = 0;
  int? playerTimer;
  int gameTimer = 0;
  TimerComponent interval = TimerComponent(period: 1);
  Vector2 timerPosition = Vector2.all(0);
  EdgeInsets joystickPosition = EdgeInsets.all(0);

  late Player player;
  JoystickComponent? _joystick;
  late KeyItem _key;
  List<BoxItem> _boxes = [];
  List<Button> _buttons = [];

  List<PositionComponent> wallsList = [];
  List<PositionComponent> blockedZone = [];
  List<PositionComponent> teleporterZone = [];
  List<Door> doors = [];

  ObjectGroup? waterObjects;
  ObjectGroup? landObjects;
  ObjectGroup? lavaObjects;
  ObjectGroup? groundObjects;
  ObjectGroup? beginnerDoorObjects;
  ObjectGroup? intermediateDoorObjects;
  ObjectGroup? advancedDoorObjects;
  ObjectGroup? teleportationObjects;

  ObjectGroup? firstMapTeleporter;
  ObjectGroup? beginnerMapTeleporter;
  ObjectGroup? intermediateMapTeleporter;
  ObjectGroup? advancedMapTeleporter;
  ObjectGroup? keyItem;
  ObjectGroup? boxItems;
  ObjectGroup? lavaButtonObjects;
  ObjectGroup? buttonDoorObjects;
  ObjectGroup? finalDoorObjects;
  ObjectGroup? doorButtonObjects;
  ObjectGroup? finalButtonObjects;
  ObjectGroup? decorationsObjects;
  ObjectGroup? congratulationsTeleporter;

  PositionComponent? timer;
  PositionComponent? landLayer;
  PositionComponent? lavaLayer;
  PositionComponent? waterLayer;
  PositionComponent? bordersLayer;
  PositionComponent? bridgesLayer;
  PositionComponent? decorationLayer;
  PositionComponent? groundDecorationsLayer;
  PositionComponent? waterBridgesLayer;
  ActionableDoor? buttonDoor;
  ActionableDoor? finalDoor;

  late TiledComponent levelMap;

  @override
  Color backgroundColor() {
    return const Color.fromARGB(255, 173, 223, 247);
  }

  @override
  FutureOr<void> onLoad() async {
    await images.loadAll([
      'timer.png',
      'Slime1_Idle_body.png',
      'Slime2_Idle_body.png',
      'Slime3_Idle_body.png',
      'joystick.png',
      'key.png',
      'box.png',
      'DoubleDoor1.png',
      'button.png',
    ]);
    timerPosition = Vector2(
      (camera.viewport.virtualSize.x / 2),
      camera.viewport.virtualSize.y * 0.1,
    );
    joystickPosition = .only(
      left: (MediaQuery.of(buildContext!).size.width / 2) - 75,
      bottom: MediaQuery.of(buildContext!).size.height * 0.15,
    );
    interval = TimerComponent(
      period: 1,
      onTick: () {
        gameTimer += 1;
      },
      repeat: true,
    );
    interval.timer.pause();

    world.add(interval);
    if (playerTimer != null) {
      gameTimer = playerTimer!;
    }

    timer = TimerPositionComponent();
    camera.viewport.add(timer!);
    if (characterItems != null && characterItems!.isNotEmpty) {
      collectedItems.addAll(characterItems!);
    }
    WidgetsBinding.instance.addObserver(this);
    nfcDataNotifier.addListener(_updateWorldFromNFC);

    _loadJoystick();
    final gamepads = await Gamepads.list();
    if (gamepads.isEmpty) {
      camera.viewport.add(_joystick!);
    }

    Gamepads.onConnected.listen((event) {
      camera.viewport.remove(_joystick!);
    });

    Gamepads.onDisconnected.listen((event) {
      camera.viewport.add(_joystick!);
    });

    level ??= 'teleportation_map.tmx';
    await _loadLevel(level!);

    nfcDataNotifier.startNfcCardTypeScan();

    return super.onLoad();
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
      margin: joystickPosition,
    );
  }

  Future<void> _loadLevel(String level) async {
    switch (level) {
      case 'first_map.tmx':
        worldKey = 'BeginnerKey';
      case 'beginner_map.tmx':
        worldKey = 'IntermediateKey';
      case 'intermediate_map.tmx':
        worldKey = 'AdvancedKey';
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
    intermediateDoorObjects = levelMap.tileMap.getLayer<ObjectGroup>(
      'IntermediateDoor',
    );
    advancedDoorObjects = levelMap.tileMap.getLayer<ObjectGroup>(
      'AdvancedDoor',
    );
    buttonDoorObjects = levelMap.tileMap.getLayer<ObjectGroup>('ButtonDoor');
    finalDoorObjects = levelMap.tileMap.getLayer<ObjectGroup>('FinalDoor');

    groundObjects = levelMap.tileMap.getLayer<ObjectGroup>('GroundZone');

    firstMapTeleporter = levelMap.tileMap.getLayer<ObjectGroup>(
      'FirstMapTeleporter',
    );

    beginnerMapTeleporter = levelMap.tileMap.getLayer<ObjectGroup>(
      'BeginnerMapTeleporter',
    );
    intermediateMapTeleporter = levelMap.tileMap.getLayer<ObjectGroup>(
      'IntermediateMapTeleporter',
    );
    advancedMapTeleporter = levelMap.tileMap.getLayer<ObjectGroup>(
      'AdvancedMapTeleporter',
    );
    congratulationsTeleporter = levelMap.tileMap.getLayer<ObjectGroup>(
      'CongratulationsTeleporter',
    );

    teleportationObjects = levelMap.tileMap.getLayer<ObjectGroup>('Teleporter');

    lavaButtonObjects = levelMap.tileMap.getLayer<ObjectGroup>('LavaButton');
    doorButtonObjects = levelMap.tileMap.getLayer<ObjectGroup>('DoorButton');
    finalButtonObjects = levelMap.tileMap.getLayer<ObjectGroup>('FinalButton');
    decorationsObjects = levelMap.tileMap.getLayer<ObjectGroup>('Decorations');

    boxItems = levelMap.tileMap.getLayer<ObjectGroup>('Box');
    keyItem = levelMap.tileMap.getLayer<ObjectGroup>(worldKey);

    slimeType ??= 'Land';

    _loadWalkingType();

    if (characterPosition != null) {
      isBlocked = isPlayerInBlockedZone(characterPosition!);
    } else {
      characterPosition = Vector2(spawnPoint.x, spawnPoint.y);
      isBlocked = isPlayerInBlockedZone(characterPosition!);
    }

    player = Player(
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

    if (!collectedItems.contains(worldKey) && keyItem != null) {
      _key = KeyItem(
        position: Vector2(keyItem!.objects.first.x, keyItem!.objects.first.y),
      );
      _key.priority = 2;
      world.add(_key);
    }
    if (boxItems != null) {
      if (savedBoxesPosition.isEmpty) {
        for (var element in boxItems!.objects) {
          _boxes.add(
            BoxItem(position: Vector2(element.x, element.y))..priority = 3,
          );
        }
      } else {
        for (var element in savedBoxesPosition) {
          _boxes.add(
            BoxItem(position: Vector2(element.x, element.y))..priority = 3,
          );
          savedBoxesPosition = [];
        }
      }

      world.addAll(_boxes);
    }

    _loadDecorations();

    _loadDoors();

    _loadButtons();

    _loadTeleporter();

    _loadLayers(levelMap);
  }

  void _loadDecorations() {
    if (decorationsObjects != null) {
      for (var tiledObject in decorationsObjects!.objects) {
        if (tiledObject.gid != null) {
          final decorationSprite = levelMap.tileMap.map.tileByGid(
            tiledObject.gid!,
          );
          final correctedPosition = Vector2(tiledObject.x, tiledObject.y);
          final image = images.fromCache(decorationSprite!.image!.source!);
          final sprite = Sprite(
            image,
            srcSize: Vector2(
              image.width.toDouble(),
              tiledObject.height.toDouble(),
            ),
            srcPosition: Vector2(0, 0),
          );

          final decorationComponent = SpriteComponent(
            sprite: sprite,
            position: correctedPosition,
            size: Vector2(sprite.srcSize.x * 1.5, sprite.srcSize.y * 1.5),
            priority: 2,
            anchor: .center,
          );
          world.add(decorationComponent);
        }
      }
    }
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
    groundDecorationsLayer = imageCompiler.compileMapLayer(
      tileMap: levelMap.tileMap,
      layerNames: ['ground_decorations'],
    );

    if (waterLayer != null) {
      waterLayer!.priority = 1;
      world.add(waterLayer!);
    }
    if (lavaLayer != null) {
      if (removeLavaWalls == false) {
        lavaLayer!.priority = 2;
      }

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
    if (groundDecorationsLayer != null) {
      groundDecorationsLayer!.priority = 2;
      world.add(groundDecorationsLayer!);
    }

    if (bridgesLayer != null) {
      if (slimeType == 'Water') {
        bridgesLayer!.priority = 4;
        world.add(bridgesLayer!);
      } else {
        bridgesLayer!.priority = 2;
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

    player.priority = 3;

    world.add(player);
    camera.follow(player, snap: true);
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

  void _loadButtons() {
    if (lavaButtonObjects != null) {
      _buttons.add(
        Button(
          buttonPressedAction: () {
            lavaLayer!.priority = 0;
            world.removeAll(blockedZone);
            blockedZone = [];
            removeLavaWalls = true;
            _loadWalkingType();
          },
          buttonNotPressedAction: () {
            lavaLayer!.priority = 2;
            world.removeAll(blockedZone);
            blockedZone = [];
            removeLavaWalls = false;
            _loadWalkingType();
          },
          position: Vector2(
            lavaButtonObjects!.objects.first.x,
            lavaButtonObjects!.objects.first.y,
          ),
        )..priority = 2,
      );

      world.add(_buttons.last);
    }
    if (doorButtonObjects != null) {
      _buttons.add(
        Button(
          position: Vector2(
            doorButtonObjects!.objects.first.x,
            doorButtonObjects!.objects.first.y,
          ),
          buttonPressedAction: buttonDoor!.toggleDoor,
          buttonNotPressedAction: buttonDoor!.toggleDoor,
        )..priority = 2,
      );
      world.add(_buttons.last);
    }
    if (finalButtonObjects != null) {
      for (var element in finalButtonObjects!.objects) {
        _buttons.add(
          Button(
            position: Vector2(element.x, element.y),
            buttonPressedAction: _incrementActionedButton,
            buttonNotPressedAction: _decrementActionedButton,
          )..priority = 2,
        );
        world.add(_buttons.last);
      }
    }
  }

  void _incrementActionedButton() {
    actionedButtonsNumber += 1;
    if (actionedButtonsNumber == 2) {
      finalDoor!.toggleDoor();
    }
  }

  void _decrementActionedButton() {
    if (actionedButtonsNumber == 2) {
      finalDoor!.toggleDoor();
    }
    if (actionedButtonsNumber > 0) {
      actionedButtonsNumber -= 1;
    }
  }

  void _loadDoors() {
    if (beginnerDoorObjects != null) {
      doors.add(
        Door(keyItemString: 'BeginnerKey')
          ..position = Vector2(
            beginnerDoorObjects!.objects.first.x,
            beginnerDoorObjects!.objects.first.y,
          ),
      );

      doors.last.priority = 3;
      world.add(doors.last);
    }
    if (intermediateDoorObjects != null) {
      doors.add(
        Door(keyItemString: 'IntermediateKey')
          ..position = Vector2(
            intermediateDoorObjects!.objects.first.x,
            intermediateDoorObjects!.objects.first.y,
          ),
      );

      doors.last.priority = 3;
      world.add(doors.last);
    }
    if (advancedDoorObjects != null) {
      doors.add(
        Door(keyItemString: 'AdvancedKey')
          ..position = Vector2(
            advancedDoorObjects!.objects.first.x,
            advancedDoorObjects!.objects.first.y,
          ),
      );

      doors.last.priority = 3;
      world.add(doors.last);
    }
    if (buttonDoorObjects != null) {
      buttonDoor = ActionableDoor()
        ..position = Vector2(
          buttonDoorObjects!.objects.first.x,
          buttonDoorObjects!.objects.first.y,
        )
        ..priority = 4;

      world.add(buttonDoor!);
    }
    if (finalDoorObjects != null) {
      finalDoor = ActionableDoor()
        ..position = Vector2(
          finalDoorObjects!.objects.first.x,
          finalDoorObjects!.objects.first.y,
        )
        ..priority = 4;

      world.add(finalDoor!);
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
    if (intermediateMapTeleporter != null) {
      level = 'intermediate_map.tmx';
      _addTeleporterObjects(
        level: level,
        teleportationObjectGroup: intermediateMapTeleporter,
      );
    }
    if (advancedMapTeleporter != null) {
      level = 'advanced_map.tmx';
      _addTeleporterObjects(
        level: level,
        teleportationObjectGroup: advancedMapTeleporter,
      );
    }
    if (congratulationsTeleporter != null) {
      level = 'congratulations';
      _addTeleporterObjects(
        level: level,
        teleportationObjectGroup: congratulationsTeleporter,
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
    if (newLevel == 'congratulations') {
      _showCongratulations();
    } else {
      _resetWorldValues();
      level = newLevel;
      _loadLevel(newLevel);
    }
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
    doors = [];
    _buttons = [];
    _boxes = [];
    world.remove(player);
    characterPosition = null;
    actionedButtonsNumber = 0;
  }

  void _loadWalkingType() {
    switch (slimeType) {
      case 'Land':
        addBlockedZone(waterObjects);
        if (removeLavaWalls == false) {
          addBlockedZone(lavaObjects);
        }
        slimeImage = 'Slime1_Idle_body.png';
      case 'Water':
        addBlockedZone(landObjects);
        if (removeLavaWalls == false) {
          addBlockedZone(lavaObjects);
        }
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

  void _updateWorldFromNFC() {
    if (nfcDataNotifier.shouldUpdate) {
      for (PositionComponent zone in blockedZone) {
        world.remove(zone);
      }

      final playerState = player.playerState;
      final position = player.position;

      blockedZone = [];
      slimeType = nfcDataNotifier.nfcType;
      world.remove(player);
      _loadWalkingType();

      bool isBlocked = isPlayerInBlockedZone(position);
      player = Player(
        playerState: playerState,
        position: position,
        joystick: _joystick,
        slimeImage: slimeImage,
        isBlocked: isBlocked,
      );

      _removeLayers();
      _loadLayers(levelMap);

      camera.follow(player, snap: true);
    } else if (nfcDataNotifier.shouldTeleportToSlimeHub) {
      changeLevel('teleportation_map.tmx');
    } else if (nfcDataNotifier.shouldResetWorldValues) {
      changeLevel(level!);
    } else if (nfcDataNotifier.shouldReturnToMenu) {
      Navigator.pushReplacement(
        buildContext!,
        MaterialPageRoute(
          builder: (context) => PopScope(
            canPop: false,
            child: MainMenu(nfcDataNotifier: nfcDataNotifier),
          ),
        ),
      );
    }
  }

  void _showCongratulations() {
    LeaderboardRecord record = HiveService()
        .getLeaderboardRecordBox()
        .values
        .firstWhere(
          (record) => record.name == characterName,
          orElse: () => LeaderboardRecord(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: characterName,
            time: 1234567890,
          ),
        );
    if (record.time > gameTimer) record.time = gameTimer;
    HiveService().getLeaderboardRecordBox().put(record.id, record);
    Navigator.pushReplacement(
      buildContext!,
      MaterialPageRoute(
        builder: (context) => PopScope(
          canPop: false,
          child: CongratulationsMenu(
            nfcDataNotifier: nfcDataNotifier,
            playerName: record.name,
            time: gameTimer,
          ),
        ),
      ),
    );
  }

  Future<void> savePlayerDataOnNfc({required Completer stopNfcWriting}) async {
    List<Vector2> boxesPosition = [];
    for (BoxItem box in _boxes) {
      boxesPosition.add(box.position);
    }
    await nfcDataNotifier.savePlayerDataOnNfc(
      characterName: characterName,
      position: player.position,
      level: level!,
      stopNfcWriting: stopNfcWriting,
      collectedItems: collectedItems,
      boxesPosition: boxesPosition,
      playerTimer: gameTimer,
    );
  }

  void collectKey() {
    for (Door door in doors) {
      world.remove(door);

      door = Door(keyItemString: door.keyItemString)
        ..position = Vector2(
          beginnerDoorObjects!.objects.first.x,
          beginnerDoorObjects!.objects.first.y,
        );

      door.priority = 3;
      world.add(door);
    }
    collectedItems.add(worldKey);
  }

  @override
  void onGameResize(Vector2 size) {
    nfcDataNotifier.startNfcCardTypeScan();

    if (_joystick != null && _joystick!.isLoaded) {
      joystickPosition = .only(
        left: (MediaQuery.of(buildContext!).size.width / 2) - 75,
        bottom: MediaQuery.of(buildContext!).size.height * 0.15,
      );
      camera.viewport.remove(_joystick!);
      _joystick!.margin = joystickPosition;

      camera.viewport.add(_joystick!);
    }
    if (timer != null && timer!.isLoaded) {
      timerPosition = Vector2(
        (MediaQuery.of(buildContext!).size.width / 2),
        MediaQuery.of(buildContext!).size.height * 0.1,
      );
      // camera.viewport.remove(timerText!);
      timer!.position = timerPosition;
      camera.viewport.add(timer!);
    }
    super.onGameResize(size);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      pauseEngine();
    } else if (state == AppLifecycleState.resumed) {
      nfcDataNotifier.startNfcCardTypeScan();
      resumeEngine();
    }

    super.didChangeAppLifecycleState(state);
  }

  @override
  void onRemove() {
    nfcDataNotifier.removeListener(_updateWorldFromNFC);
    super.onRemove();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
