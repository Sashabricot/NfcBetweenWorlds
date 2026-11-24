import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:nfc_between_worlds/src/models/nfc_data.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';

class NfcRemoteScanner {
  final instance = FirebaseFirestore.instance;
  final _user = FirebaseAuth.instance.currentUser;

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
      final String nfcUid;

      if (ndef == null) throw Exception('Tag is not ndef');
      if (nfcTag != null) {
        nfcUid = _parseNfcUid(nfcTag.id);
      } else {
        throw Exception('Cannot parse TagId');
      }

      newNfc = NfcData(ndefMessage: ndef.cachedMessage, uid: nfcUid);

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
        instance.collection('nfc/${_user.uid}/save').add({
          'characterPosition': newNfc.characterPosition,
          'nfcType': nfcSavedType,
          'level': newNfc.characterLevel,
          'items': newNfc.characterItems,
          'boxesPosition': newNfc.boxesPosition,
          'playerTimer': newNfc.playerTimer,
          'characterName': newNfc.characterName,
          'utf8Type': utf8Type,
        });
      }
    } on Exception {
      loadNfcSave();
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
