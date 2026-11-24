import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:nfc_between_worlds/src/models/nfc_data.dart';
import 'package:nfc_between_worlds/src/provider/nfc_data_notifier.dart';
import 'package:nfc_between_worlds/src/provider/nfc_data_state.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';

class NfcLoadSave extends ChangeNotifier {
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

  Map<String, dynamic>? characterSaveData;

  final StreamController<NfcDataState> _nfcDataStateController =
      StreamController<NfcDataState>();

  Stream<NfcDataState> get nfcDataStateStream => _nfcDataStateController.stream;

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

  Future<Map<String, dynamic>?> loadNfcSave({
    required bool startNewGame,
    required Completer stopNfcSaveReading,
    required NfcDataNotifier nfcDataNotifier,
  }) async {
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
      _state = _state.copyWith(error: null);
      _nfcDataStateController.add(_state);
      stopNfcSaveReading.complete();
      return characterSaveData;
    } on Exception catch (e) {
      characterSaveData = {};
      _state = _state.copyWith(error: e.toString());
      _nfcDataStateController.add(_state);

      stopNfcSaveReading.complete();
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
}
