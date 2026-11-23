import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:nfc_between_worlds/src/models/nfc_data.dart';
import 'package:nfc_between_worlds/src/provider/nfc_data_state.dart';
import 'package:nfc_between_worlds/src/provider/nfc_update.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';

class NfcDataNotifier extends ChangeNotifier {
  final NfcUpdate _nfcUpdate = NfcUpdate();
  final _user = FirebaseAuth.instance.currentUser;
  NfcDataNotifier() {
    _nfcUpdate.nfcDataStateStream.listen((state) {
      _state = state;
      notifyListeners();
    });
    if (_user != null) {
      FirebaseFirestore.instance
          .collection('nfc/${_user.uid}/commands')
          .get()
          .then((snapshot) {
            for (DocumentSnapshot ds in snapshot.docs) {
              ds.reference.delete();
            }
          });
      FirebaseFirestore.instance
          .collection('nfc/${_user.uid}/commands')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((dataSnapshot) {
            _processCommandSnapshot(dataSnapshot);
          });
    }
  }

  NfcDataState _state = NfcDataState(
    shouldResetWorldValues: false,
    shouldReturnToMenu: false,
    shouldUpdate: false,
    items: [],
    shouldTeleportToSlimeHub: false,
    latestNfcData: NfcData(
      ndefMessage: NdefMessage(records: []),
      uid: '',
    ),
    nfcUtf8Type: utf8.encode('2'),
  );

  NfcDataState get state => _state;

  Exception? error;
  String nfcSaveMessage = '';
  void _processCommandSnapshot(
    QuerySnapshot<Map<String, dynamic>> commandSnapshot,
  ) {
    if (commandSnapshot.docs.isNotEmpty) {
      final command =
          commandSnapshot.docs.first.data() as Map<String, dynamic>?;
      if (command != null) {
        if (command['update'] != null) {
          Uint8List utf8type = utf8.encode('');
          switch (command['type']) {
            case 'Land':
              utf8type = utf8.encode('0');
            case 'Water':
              utf8type = utf8.encode('1');
            case 'Lava':
              utf8type = utf8.encode('2');
            case 'Air':
              utf8type = utf8.encode('3');
          }
          _state = _state.copyWith(
            nfcType: command['type'],
            shouldUpdate: true,
            nfcUtf8Type: utf8type,
          );
          _nfcUpdate.updateState(_state);
          notifyListeners();
        } else if (command['teleport'] != null) {
          _state = _state.copyWith(shouldTeleportToSlimeHub: true);
          notifyListeners();
        } else if (command['reset'] != null) {
          _state = _state.copyWith(shouldResetWorldValues: true);
          notifyListeners();
        } else if (command['menu'] != null) {
          _state = _state.copyWith(shouldReturnToMenu: true);
          notifyListeners();
        } else if (command['updateItems'] != null) {
          _state = _state.copyWith(items: [...command['items']]);
          _nfcUpdate.updateState(_state);
          notifyListeners();
        } else if (command['cheat'] != null) {
          _state = _state.copyWith(gameCheat: command['gameCheat']);
          notifyListeners();
        }
      }
    }
  }

  Future<void> blockSystemNfc() async {
    NfcAvailability availability = await NfcManager.instance
        .checkAvailability();
    if (availability == NfcAvailability.disabled) {
      return;
    } else {
      NfcManager.instance.stopSession();
      NfcManager.instance.startSession(
        noPlatformSoundsAndroid: true,
        onDiscovered: (NfcTag tag) {},
        pollingOptions: {NfcPollingOption.iso14443},
      );
    }
  }

  Future<void> savePlayerDataOnNfc({
    required Vector2 position,
    required Completer stopNfcWriting,
    required String level,
    required List<String> collectedItems,
    required List<Vector2> boxesPosition,
    required int? playerTimer,
    required String characterName,
  }) async {
    _state = _state.copyWith(isProcessing: true);
    notifyListeners();
    NfcManager.instance.stopSession();
    NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443},
      onDiscovered: (NfcTag nfc) async => _writeNfcSaveData(
        characterName: characterName,
        nfc: nfc,
        position: position,
        stopNfcWriting: stopNfcWriting,
        level: level,
        collectedItems: collectedItems,
        boxesPosition: boxesPosition,
        playerTimer: playerTimer,
      ),
    );
    await stopNfcWriting.future;
    _state = _state.copyWith(isProcessing: false);
    startNfcCardTypeScan(updateDatabase: false);
  }

  Future<void> _writeNfcSaveData({
    required NfcTag nfc,
    required Vector2 position,
    required Completer stopNfcWriting,
    required String level,
    required List<String> collectedItems,
    required List<Vector2> boxesPosition,
    required int? playerTimer,
    required String characterName,
  }) async {
    try {
      final String positionXString = '${position.x}'.length >= 7
          ? '${position.x}'.substring(0, 7)
          : '${position.x}';
      final String positionYString = '${position.y}'.length >= 7
          ? '${position.y}'.substring(0, 7)
          : '${position.y}';
      final String positionString = '$positionXString,$positionYString';

      final NdefMessage saveData = NdefMessage(
        records: [
          NdefRecord(
            typeNameFormat: TypeNameFormat.wellKnown,
            type: Uint8List.fromList([0x55]),
            identifier: Uint8List.fromList([]),
            payload: utf8.encode(positionString),
          ),
          NdefRecord(
            typeNameFormat: TypeNameFormat.external,
            type: utf8.encode('s:t'),
            identifier: Uint8List.fromList([]),
            payload: _state.nfcUtf8Type,
          ),
          NdefRecord(
            typeNameFormat: TypeNameFormat.external,
            type: utf8.encode('g:l'),
            identifier: Uint8List.fromList([]),
            payload: utf8.encode(level),
          ),
        ],
      );
      for (String item in collectedItems) {
        Uint8List? itemUtf8;
        switch (item) {
          case 'BeginnerKey':
            itemUtf8 = utf8.encode('0');
          case 'IntermediateKey':
            itemUtf8 = utf8.encode('1');
          case 'AdvancedKey':
            itemUtf8 = utf8.encode('2');
          case 'EasterEgg':
            itemUtf8 = utf8.encode('3');
        }
        if (itemUtf8 != null) {
          saveData.records.add(
            NdefRecord(
              typeNameFormat: .external,
              type: utf8.encode('g:i'),
              identifier: Uint8List.fromList([]),
              payload: itemUtf8,
            ),
          );
        }
      }

      for (Vector2 position in boxesPosition) {
        saveData.records.add(
          NdefRecord(
            typeNameFormat: .wellKnown,
            type: utf8.encode('T'),
            identifier: Uint8List.fromList([]),
            payload: utf8.encode('${position.x},${position.y}'),
          ),
        );
      }

      saveData.records.add(
        NdefRecord(
          typeNameFormat: .external,
          type: utf8.encode('p:t'),
          identifier: Uint8List.fromList([]),
          payload: utf8.encode(playerTimer.toString()),
        ),
      );

      saveData.records.add(
        NdefRecord(
          typeNameFormat: .external,
          type: utf8.encode('c:n'),
          identifier: utf8.encode(''),
          payload: utf8.encode(characterName),
        ),
      );

      final ndef = Ndef.from(nfc);
      if (ndef == null) throw ('Tag is not ndef');
      if (!ndef.isWritable) throw ('Tag is not writeable');
      await ndef.write(message: saveData);
      nfcSaveMessage =
          'SavedData :  \nslimeType : ${_state.nfcType}, \nlevel : $level';
      stopNfcWriting.complete();
    } catch (e) {
      nfcSaveMessage = e.toString();
      stopNfcWriting.complete();
    }
    _state = _state.copyWith(isProcessing: false);
    notifyListeners();
  }

  Future<void> startNfcCardTypeScan({required bool updateDatabase}) async {
    _nfcUpdate.startNfcCardTypeScan(updateDatabase: updateDatabase);
  }

  Future<Map<String, dynamic>?> loadNfcSave({
    required bool startNewGame,
    required Completer stopNfcSaveReading,
    required NfcDataNotifier nfcDataNotifier,
  }) async {
    error = null;
    Map<String, dynamic>? characterSaveData;
    NfcManager.instance.stopSession();
    NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443},
      onDiscovered: (NfcTag nfc) async => {
        characterSaveData = await _loadNfcSaveData(
          nfc: nfc,
          stopNfcSaveReading: stopNfcSaveReading,

          nfcDataNotifier: nfcDataNotifier,
        ),
      },
    );

    await stopNfcSaveReading.future;
    // blockSystemNfc();

    return characterSaveData;
  }

  Future<Map<String, dynamic>> _loadNfcSaveData({
    required NfcTag nfc,
    required Completer stopNfcSaveReading,

    required NfcDataNotifier nfcDataNotifier,
  }) async {
    await blockSystemNfc();
    Map<String, dynamic> characterSaveData = {};
    Vector2? characterPosition;
    NfcData newNfc;
    String? level;
    String? characterName;
    List<String>? characterItems;
    List<String>? collectedItems;
    List<Vector2> boxesPosition = [];
    int? playerTimer;
    try {
      final Ndef? ndef = Ndef.from(nfc);
      final NfcTagAndroid? nfcTag = NfcTagAndroid.from(nfc);

      final String nfcUid;

      if (ndef == null) throw Exception('Tag is not ndef');
      if (nfcTag != null) {
        nfcUid = _parseNfcUid(nfcTag.id);
      } else {
        throw Exception('Cannot parse TagId');
      }

      newNfc = NfcData(ndefMessage: ndef.cachedMessage, uid: nfcUid);

      String? nfcSavedType;

      if (newNfc.slimeType != null) {
        switch (newNfc.slimeType) {
          case [50]:
            _state = _state.copyWith(
              nfcType: 'Land',
              nfcUtf8Type: newNfc.slimeType,
            );
          case [49]:
            _state = _state.copyWith(
              nfcType: 'Water',
              nfcUtf8Type: newNfc.slimeType,
            );
          case [48]:
            _state = _state.copyWith(
              nfcType: 'Lava',
              nfcUtf8Type: newNfc.slimeType,
            );
          case [51]:
            _state = _state.copyWith(
              nfcType: 'Air',
              nfcUtf8Type: newNfc.slimeType,
            );
          default:
        }
        nfcSavedType = _state.nfcType;
        if (newNfc.characterPosition == null && newNfc.slimeType != null) {
          throw Exception('Please use a new NFC card');
        }
      }
      if (newNfc.characterPosition != null) {
        characterPosition = parseVector2Position(newNfc.characterPosition!);
      }

      for (String boxPosition in newNfc.boxesPosition) {
        Vector2? boxParsedPosition = parseVector2Position(boxPosition);
        if (boxParsedPosition != null) {
          boxesPosition.add(boxParsedPosition);
        }
      }
      if (newNfc.characterLevel != null) {
        level = newNfc.characterLevel;
      }
      if (newNfc.shouldTeleportToSlimeHub != null) {
        throw Exception('Please use a new NFC card');
      }
      if (newNfc.shouldResetWorldValues != null) {
        throw Exception('Please use a new NFC card');
      }
      if (newNfc.shouldReturnToMenu != null) {
        throw Exception('Please use a new NFC card');
      }
      if (newNfc.characterItems.isNotEmpty) {
        characterItems = newNfc.characterItems;
        collectedItems = [];
        for (String item in characterItems) {
          switch (item) {
            case '0':
              collectedItems.add('BeginnerKey');
            case '1':
              collectedItems.add('IntermediateKey');
            case '2':
              collectedItems.add('AdvancedKey');
          }
        }
      }
      if (newNfc.playerTimer != null) {
        playerTimer = newNfc.playerTimer;
      }
      if (newNfc.characterName != null) {
        characterName = newNfc.characterName;
      }
      characterSaveData.addAll({
        'characterPosition': characterPosition,
        'nfcType': nfcSavedType,
        'level': level,
        'items': characterItems,
        'boxesPosition': boxesPosition,
        'playerTimer': playerTimer,
        'characterName': characterName,
      });

      stopNfcSaveReading.complete();
      return characterSaveData;
    } on Exception catch (e) {
      characterSaveData = {};
      stopNfcSaveReading.complete();
      error = e;
      notifyListeners();
      return characterSaveData;
    }
  }

  Vector2? parseVector2Position(String position) {
    List<double> characterPosition = [];
    List<String> positions = position.split(',');
    for (String position in positions) {
      double? positionDouble = double.tryParse(position);
      if (positionDouble != null) {
        characterPosition.add(positionDouble);
      }
    }
    if (characterPosition.length == 2) {
      return Vector2(characterPosition.first, characterPosition.last);
    } else {
      return null;
    }
  }

  String _parseNfcUid(Uint8List? nfcId) {
    if (nfcId != null) {
      return nfcId
          .sublist(0, 5)
          .map((e) => e.toRadixString(16).padLeft(2, '0'))
          .join(':')
          .toUpperCase();
    } else {
      return '';
    }
  }

  void giveAirSlime() {
    _state = _state.copyWith(
      nfcType: 'Air',
      latestNfcData: NfcData(
        ndefMessage: NdefMessage(records: []),
        uid: '',
      ),
    );
    _nfcUpdate.giveAirSlime();
  }
}
