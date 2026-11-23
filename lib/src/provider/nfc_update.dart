import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nfc_between_worlds/src/models/nfc_data.dart';
import 'package:nfc_between_worlds/src/provider/nfc_data_state.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';

class NfcUpdate {
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

  final StreamController<NfcDataState> _nfcDataStateController =
      StreamController<NfcDataState>();

  Stream<NfcDataState> get nfcDataStateStream => _nfcDataStateController.stream;

  Future<void> startNfcCardTypeScan({required bool updateDatabase}) async {
    NfcAvailability availability = await NfcManager.instance
        .checkAvailability();
    if (availability == NfcAvailability.disabled ||
        availability == NfcAvailability.unsupported) {
      throw Exception('NFC not available');
    } else {
      NfcManager.instance.stopSession();
      NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443},
        onDiscovered: (NfcTag nfc) async =>
            _processNfcData(nfc: nfc, updateDatabase: updateDatabase),
      );
    }
  }

  Future<void> _processNfcData({
    required NfcTag nfc,
    required bool updateDatabase,
  }) async {
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

      newNfc = NfcData(ndefMessage: ndef.cachedMessage, uid: nfcUid);

      if (newNfc.shouldTeleportToSlimeHub != null &&
          newNfc.shouldTeleportToSlimeHub!) {
        _state = _state.copyWith(
          shouldTeleportToSlimeHub: true,
          latestNfcData: newNfc,
        );
        if (updateDatabase) {
          FirebaseFirestore.instance
              .collection('nfc/953WxSNs91xEMWe6u9US/commands')
              .add({'createdAt': DateTime.now(), 'teleport': true});
        }
      } else if (newNfc.shouldResetWorldValues != null &&
          newNfc.shouldResetWorldValues!) {
        _state = _state.copyWith(
          shouldResetWorldValues: true,
          latestNfcData: newNfc,
        );
        if (updateDatabase) {
          FirebaseFirestore.instance
              .collection('nfc/953WxSNs91xEMWe6u9US/commands')
              .add({'createdAt': DateTime.now(), 'reset': true});
        }
      } else if (newNfc.shouldReturnToMenu != null &&
          newNfc.shouldReturnToMenu!) {
        _state = _state.copyWith(
          shouldReturnToMenu: true,
          latestNfcData: newNfc,
        );
        if (updateDatabase) {
          FirebaseFirestore.instance
              .collection('nfc/953WxSNs91xEMWe6u9US/commands')
              .add({'createdAt': DateTime.now(), 'menu': true});
        }
      } else if (newNfc.characterItems.isNotEmpty &&
          newNfc.characterPosition == null) {
        _state = _state.copyWith(
          items: [...newNfc.characterItems],
          latestNfcData: newNfc,
        );
        if (updateDatabase) {
          FirebaseFirestore.instance
              .collection('nfc/953WxSNs91xEMWe6u9US/commands')
              .add({
                'createdAt': DateTime.now(),
                'updateItems': true,
                'items': [...newNfc.characterItems],
              });
        }
      } else if (newNfc.gameCheat != null) {
        _state = _state.copyWith(
          gameCheat: newNfc.gameCheat,
          latestNfcData: newNfc,
        );
        if (updateDatabase) {
          FirebaseFirestore.instance
              .collection('nfc/953WxSNs91xEMWe6u9US/commands')
              .add({
                'createdAt': DateTime.now(),
                'cheat': true,
                'gameCheat': newNfc.gameCheat,
              });
        }
      } else if (_state.latestNfcData.uid != newNfc.uid) {
        if (newNfc.slimeType != null && newNfc.characterPosition == null) {
          switch (newNfc.slimeType) {
            case [50]:
              _state = _state.copyWith(
                nfcType: 'Land',
                nfcUtf8Type: newNfc.slimeType,
                shouldUpdate: true,
                latestNfcData: newNfc,
              );

            case [49]:
              _state = _state.copyWith(
                nfcType: 'Water',
                nfcUtf8Type: newNfc.slimeType,
                shouldUpdate: true,
                latestNfcData: newNfc,
              );

            case [48]:
              _state = _state.copyWith(
                nfcType: 'Lava',
                nfcUtf8Type: newNfc.slimeType,
                shouldUpdate: true,
                latestNfcData: newNfc,
              );

            case [51]:
              _state = _state.copyWith(
                nfcType: 'Air',
                nfcUtf8Type: newNfc.slimeType,
                shouldUpdate: true,
                latestNfcData: newNfc,
              );

            default:
          }

          if (updateDatabase) {
            FirebaseFirestore.instance
                .collection('nfc/953WxSNs91xEMWe6u9US/commands')
                .add({
                  'createdAt': DateTime.now(),
                  'update': true,
                  'type': _state.nfcType,
                });
          }
        } else if (newNfc.characterItems.contains('EasterEgg')) {
          _state = _state.copyWith(
            nfcType: 'Air',
            nfcUtf8Type: utf8.encode('3'),
            shouldUpdate: true,
            latestNfcData: newNfc,
          );
          if (updateDatabase) {
            FirebaseFirestore.instance
                .collection('nfc/953WxSNs91xEMWe6u9US/commands')
                .add({
                  'createdAt': DateTime.now(),
                  'update': true,
                  'type': _state.nfcType,
                });
          }
        }
      }

      _nfcDataStateController.add(_state);
    } catch (e) {
      throw Exception(e);
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
      nfcUtf8Type: utf8.encode('3'),
    );
  }

  void updateState(NfcDataState state) {
    _state = state;
  }
}
