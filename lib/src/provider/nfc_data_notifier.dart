import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:nfc_between_worlds/src/models/nfc_data.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';

class NfcDataNotifier extends ChangeNotifier {
  final Map<String, NfcData> _nfcTags = {};

  String _nfcType = '';
  Uint8List _nfcUtf8Type = utf8.encode('2');
  NfcData _latestNfcData = NfcData(
    ndefMessage: NdefMessage(records: []),
    uid: '',
  );
  bool isProcessing = false;
  bool shouldUpdate = false;
  bool shouldTeleportToSlimeHub = false;
  Exception? error;
  String nfcSaveMessage = '';

  Map<String, NfcData> get nfcTags => _nfcTags;
  NfcData get latestNfcData => _latestNfcData;

  String get nfcType => _nfcType;

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
  }) async {
    shouldUpdate = false;
    isProcessing = true;
    notifyListeners();
    NfcManager.instance.stopSession();
    NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443},
      onDiscovered: (NfcTag nfc) async => _writeNfcSaveData(
        nfc: nfc,
        position: position,
        stopNfcWriting: stopNfcWriting,
        level: level,
        collectedItems: collectedItems,
      ),
    );
    await stopNfcWriting.future;
    isProcessing = false;
    startNfcCardTypeScan();
  }

  Future<void> _writeNfcSaveData({
    required NfcTag nfc,
    required Vector2 position,
    required Completer stopNfcWriting,
    required String level,
    required List<String> collectedItems,
  }) async {
    try {
      final String positionString = '${position.x},${position.y}';

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
            payload: _nfcUtf8Type,
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

      final ndef = Ndef.from(nfc);
      if (ndef == null) throw ('Tag is not ndef');
      if (!ndef.isWritable) throw ('Tag is not writeable');
      await ndef.write(message: saveData);
      nfcSaveMessage = 'SavedData :  \nslimeType : $nfcType, \nlevel : $level';
      stopNfcWriting.complete();
    } catch (e) {
      nfcSaveMessage = e.toString();
      stopNfcWriting.complete();
    }
    isProcessing = false;
    notifyListeners();
  }

  Future<void> startNfcCardTypeScan() async {
    shouldUpdate = true;
    NfcAvailability availability = await NfcManager.instance
        .checkAvailability();
    if (availability == NfcAvailability.disabled ||
        availability == NfcAvailability.unsupported) {
      throw Exception('NFC not available');
    } else {
      NfcManager.instance.stopSession();
      NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443},
        onDiscovered: (NfcTag nfc) async => _processNfcData(nfc: nfc),
      );
    }
  }

  Future<void> _processNfcData({required NfcTag nfc}) async {
    try {
      NfcData newNfc;
      final Ndef? ndef = Ndef.from(nfc);
      final NfcTagAndroid? nfcTag = NfcTagAndroid.from(nfc);

      final String nfcUid;

      if (ndef == null) throw ('Tag is not ndef');
      if (nfcTag != null) {
        nfcUid = _parseNfcUid(nfcTag.id);
      } else {
        nfcUid = '';
      }

      if (_nfcTags[nfcUid] == null) {
        newNfc = NfcData(ndefMessage: ndef.cachedMessage, uid: nfcUid);

        _nfcTags[nfcUid] = newNfc;
      } else {
        newNfc = _nfcTags[nfcUid]!;
      }
      if (_latestNfcData.uid != newNfc.uid) {
        if (newNfc.slimeType != null) {
          switch (newNfc.slimeType) {
            case [50]:
              _nfcUtf8Type = newNfc.slimeType!;
              _nfcType = 'Land';
              notifyListeners();
            case [49]:
              _nfcUtf8Type = newNfc.slimeType!;
              _nfcType = 'Water';
              notifyListeners();
            case [48]:
              _nfcUtf8Type = newNfc.slimeType!;
              _nfcType = 'Lava';
              notifyListeners();
            default:
          }
        }
      } else if (newNfc.shouldTeleportToSlimeHub != null &&
          newNfc.shouldTeleportToSlimeHub!) {
        shouldUpdate = false;
        shouldTeleportToSlimeHub = true;
        notifyListeners();
        shouldUpdate = true;
        shouldTeleportToSlimeHub = false;
      }
      _latestNfcData = newNfc;
    } catch (e) {
      throw Exception(e);
    }
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
    blockSystemNfc();
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
    List<String>? characterItems;
    List<String>? collectedItems;
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
      _nfcTags[nfcUid] = newNfc;
      String? nfcSavedType;

      if (newNfc.slimeType != null) {
        switch (newNfc.slimeType) {
          case [50]:
            _nfcUtf8Type = newNfc.slimeType!;
            _nfcType = 'Land';

          case [49]:
            _nfcUtf8Type = newNfc.slimeType!;
            _nfcType = 'Water';
          case [48]:
            _nfcUtf8Type = newNfc.slimeType!;
            _nfcType = 'Lava';
          default:
        }
        nfcSavedType = _nfcType;
      }
      if (newNfc.characterPosition != null) {
        characterPosition = parseCharacterPosition(newNfc.characterPosition!);
        if (characterPosition == null && newNfc.slimeType != null) {
          throw Exception('Please use a new NFC card');
        }
      }
      if (newNfc.characterLevel != null) {
        level = newNfc.characterLevel;
      }
      if (newNfc.shouldTeleportToSlimeHub != null) {
        throw Exception('Please use a new NFC card');
      }
      if (newNfc.characterItems.isNotEmpty) {
        characterItems = newNfc.characterItems;
        collectedItems = [];
        for (String item in characterItems) {
          switch (item) {
            case '0':
              collectedItems.add('BeginnerKey');
          }
        }
      }
      characterSaveData.addAll({
        'characterPosition': characterPosition,
        'nfcType': nfcSavedType,
        'level': level,
        'items': characterItems,
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

  Vector2? parseCharacterPosition(String position) {
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
