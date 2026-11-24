import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:nfc_between_worlds/src/models/nfc_data.dart';
import 'package:nfc_between_worlds/src/provider/nfc_data_state.dart';
import 'package:nfc_between_worlds/src/provider/nfc_load_save.dart';
import 'package:nfc_between_worlds/src/provider/nfc_save.dart';
import 'package:nfc_between_worlds/src/provider/nfc_update.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';

class NfcDataNotifier extends ChangeNotifier {
  final NfcUpdate _nfcUpdate = NfcUpdate();
  final NfcSave _nfcSave = NfcSave();
  final NfcLoadSave nfcLoadSave = NfcLoadSave();
  final _user = FirebaseAuth.instance.currentUser;
  NfcDataNotifier() {
    _nfcUpdate.nfcDataStateStream.listen((state) {
      _state = state;
      notifyListeners();
    });
    nfcLoadSave.nfcDataStateStream.listen((state) {
      _state = state;
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

      FirebaseFirestore.instance
          .collection('nfc/${_user.uid}/save')
          .snapshots()
          .listen((saveSnapshot) {
            _processSaveSnapshot(saveSnapshot);
          });
    }
  }
  Map<String, dynamic>? characterSaveData;
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

  String nfcSaveMessage = '';

  void _processSaveSnapshot(
    QuerySnapshot<Map<String, dynamic>> commandSnapshot,
  ) {
    if (commandSnapshot.docs.isNotEmpty) {
      final command =
          commandSnapshot.docs.first.data() as Map<String, dynamic>?;
      if (command != null) {
        Vector2? characterPosition = parseVector2Position(
          command['characterPosition'],
        );
        String? nfcType = command['nfcType'];
        String? level = command['level'];
        String? characterName = command['characterName'];
        List<String>? characterItems = command['characterItems'];

        List<Vector2> boxesPosition = [];
        for (String position in command['boxesPosition']) {
          Vector2? boxPosition = parseVector2Position(position);
          if (boxPosition != null) boxesPosition.add(boxPosition);
        }
        int? playerTimer = command['playerTimer'];
        _state.copyWith(
          nfcType: nfcType,
          nfcUtf8Type: utf8.encode(command['utf8Type']),
        );

        characterSaveData = {
          'characterPosition': characterPosition,
          'nfcType': nfcType,
          'level': level,
          'items': characterItems,
          'boxesPosition': boxesPosition,
          'playerTimer': playerTimer,
          'characterName': characterName,
        };
        notifyListeners();
      }
    }
  }

  void _processCommandSnapshot(
    QuerySnapshot<Map<String, dynamic>> commandSnapshot,
  ) {
    characterSaveData = null;
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

    nfcSaveMessage = await _nfcSave.savePlayerDataOnNfc(
      position: position,
      stopNfcWriting: stopNfcWriting,
      level: level,
      collectedItems: collectedItems,
      boxesPosition: boxesPosition,
      playerTimer: playerTimer,
      characterName: characterName,
      nfcUtf8Type: _state.nfcUtf8Type,
    );

    _state = _state.copyWith(isProcessing: false);
    notifyListeners();
    startNfcCardTypeScan(updateDatabase: false);
  }

  Future<void> startNfcCardTypeScan({required bool updateDatabase}) async {
    _nfcUpdate.startNfcCardTypeScan(updateDatabase: updateDatabase);
  }

  Future<void> loadNfcSave({
    required bool startNewGame,
    required Completer stopNfcSaveReading,
    required NfcDataNotifier nfcDataNotifier,
  }) async {
    characterSaveData = await nfcLoadSave.loadNfcSave(
      startNewGame: startNewGame,
      stopNfcSaveReading: stopNfcSaveReading,
      nfcDataNotifier: nfcDataNotifier,
    );
    _nfcUpdate.updateState(_state);

    notifyListeners();
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
}
