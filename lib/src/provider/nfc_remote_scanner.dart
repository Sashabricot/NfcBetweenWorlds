import 'dart:async';

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flame/game.dart';

import 'package:nfc_between_worlds/src/models/nfc_data.dart';
import 'package:nfc_between_worlds/src/provider/nfc_save.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';

class NfcRemoteScanner {
  NfcRemoteScanner() {
    if (_user != null) {
      FirebaseFirestore.instance
          .collection('nfc/${_user.uid}/update')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((saveSnapshot) {
            _processSaveSnapshot(saveSnapshot);
          });
    }
  }

  NfcSave nfcSave = NfcSave();
  final instance = FirebaseFirestore.instance;
  final _user = FirebaseAuth.instance.currentUser;
  NfcData nfcSaveData = NfcData(
    ndefMessage: NdefMessage(records: []),
    uid: '',
  );
  final stopwatch = Stopwatch();
  bool isSaving = false;
  bool loaded = false;

  Map<String, dynamic> characterSaveData = {};

  void _processSaveSnapshot(
    QuerySnapshot<Map<String, dynamic>> commandSnapshot,
  ) async {
    if (loaded) {
      isSaving = true;
      if (commandSnapshot.docs.isNotEmpty) {
        final save = commandSnapshot.docs.first.data() as Map<String, dynamic>?;
        if (save != null) {
          Vector2? characterPosition = parseVector2Position(
            save['characterPosition'],
          );
          String? level = save['level'];
          String? characterName = save['characterName'];
          List<String> characterItems = [...save['characterItems']];

          List<Vector2> boxesPosition = [];
          for (String? position in save['boxesPosition']) {
            if (position != null) {
              Vector2? boxPosition = parseVector2Position(position);
              if (boxPosition != null) boxesPosition.add(boxPosition);
            }
          }
          int? playerTimer = save['playerTimer'];

          characterSaveData = {
            'characterPosition':
                characterPosition ?? characterSaveData['characterPosition'],
            'level': level ?? characterSaveData['level'],
            'items': characterItems,
            'characterName':
                characterName ?? characterSaveData['characterName'],
          };

          await nfcSave.savePlayerDataOnNfc(
            position: characterSaveData['characterPosition'],
            stopNfcWriting: Completer(),
            level: characterSaveData['level'],
            collectedItems: characterSaveData['items'],
            boxesPosition: boxesPosition,
            playerTimer: playerTimer,
            characterName: characterSaveData['characterName'],
            nfcUtf8Type: Uint8List.fromList([save['utf8Type'].first]),
            noPlatformSoundsAndroid: true,
          );
        }
      }
      FirebaseFirestore.instance
          .collection('nfc/${_user!.uid}/update')
          .get()
          .then((snapshot) {
            for (DocumentSnapshot ds in snapshot.docs) {
              ds.reference.delete();
            }
          });
      isSaving = false;
      stopwatch.reset();
      stopwatch.stop();
      _checkSavePresence();
    }
  }

  Future<void> loadNfcSave() async {
    NfcManager.instance.stopSession();
    NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443},
      onDiscovered: (NfcTag nfc) async => {_loadNfcSaveData(nfc: nfc)},
    );
  }

  Future<void> _loadNfcSaveData({required NfcTag nfc}) async {
    try {
      final Ndef? ndef = Ndef.from(nfc);
      final NfcTagAndroid? nfcTag = NfcTagAndroid.from(nfc);
      NfcData newNfc;
      String nfcUid;

      if (ndef == null) throw Exception('Tag is not ndef');
      if (nfcTag != null) {
        nfcUid = _parseNfcUid(nfcTag.id);
      } else {
        throw Exception('Cannot parse TagId');
      }

      newNfc = NfcData(ndefMessage: ndef.cachedMessage, uid: nfcUid);
      nfcSaveData = newNfc;
      String? nfcSavedType;
      String? utf8Type;

      if (newNfc.slimeType != null) {
        switch (newNfc.slimeType) {
          case [50]:
            nfcSavedType = 'Land';
            utf8Type = '2';
          case [49]:
            nfcSavedType = 'Water';
            utf8Type = '1';
          case [48]:
            nfcSavedType = 'Lava';
            utf8Type = '0';
          case [51]:
            nfcSavedType = 'Air';
            utf8Type = '3';
          default:
        }

        if (newNfc.characterPosition == null && newNfc.slimeType != null) {
          throw Exception('Please use a new NFC card');
        }
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
      if (_user != null) {
        await FirebaseFirestore.instance
            .collection('nfc/${_user.uid}/save')
            .get()
            .then((snapshot) {
              for (DocumentSnapshot ds in snapshot.docs) {
                ds.reference.delete();
              }
            });
       
        instance.collection('nfc/${_user.uid}/save').add({
          'createdAt': DateTime.now(),
          'characterPosition': newNfc.characterPosition ?? '',
          'nfcType': nfcSavedType ?? '',
          'level': newNfc.characterLevel ?? '',
          'items': newNfc.characterItems,
          'boxesPosition': newNfc.boxesPosition,
          'playerTimer': newNfc.playerTimer ?? 0,
          'characterName': newNfc.characterName ?? '',
          'utf8Type': utf8Type ?? '',
        });

        characterSaveData = {
          'level': newNfc.characterLevel ,
          'items': newNfc.characterItems,
          'characterName': newNfc.characterName,
        };

        stopwatch.reset();
        stopwatch.start();
        loaded = true;
        _checkSavePresence();
      }
    } on Exception {
      loadNfcSave();
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

  Future<void> _checkSavePresence() async {
    if (!isSaving) {
      NfcManager.instance.stopSession();
      NfcManager.instance.startSession(
        noPlatformSoundsAndroid: true,
        pollingOptions: {NfcPollingOption.iso14443},
        onDiscovered: (NfcTag nfc) async => {_processSaveCheck(nfc: nfc)},
      );
      await Future.delayed(const Duration(milliseconds: 300));
      if (!isSaving) {
        stopwatch.start();
        if (stopwatch.elapsed < const Duration(seconds: 2)) {
          _checkSavePresence();
        } else {
          FirebaseFirestore.instance
              .collection('nfc/${_user!.uid}/commands')
              .add({'createdAt': DateTime.now(), 'menu': true});
          loaded = false;
          loadNfcSave();
        }
      }
    }
  }

  Future<void> _processSaveCheck({required NfcTag nfc}) async {
    try {
      final Ndef? ndef = Ndef.from(nfc);
      final NfcTagAndroid? nfcTag = NfcTagAndroid.from(nfc);
      NfcData newNfc;
      String nfcUid;

      if (ndef == null) throw Exception('Tag is not ndef');
      if (nfcTag != null) {
        nfcUid = _parseNfcUid(nfcTag.id);
      } else {
        throw Exception('Cannot parse TagId');
      }
      newNfc = NfcData(ndefMessage: ndef.cachedMessage, uid: nfcUid);

      if (newNfc.uid != nfcSaveData.uid) {
        throw Exception('Swapped saves');
      } else {
        stopwatch.reset();
      }
    } on Exception {
      //
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
