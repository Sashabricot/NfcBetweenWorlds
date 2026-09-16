import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:klondike/src/models/nfc_data.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';

class NfcDataNotifier extends ChangeNotifier {
  final Map<String, NfcData> _nfcTags = {};
  bool _found = false;
  String _nfcType = '';

  NfcData _latestNfcData = NfcData(
    ndefMessage: NdefMessage(records: []),
    uid: '',
  );
  Map<String, NfcData> get nfcTags => _nfcTags;
  NfcData get latestNfcData => _latestNfcData;
  bool get found => _found;
  String get nfcType => _nfcType;

  Future<void> startNfcRead() async {
    NfcAvailability availability =
        await NfcManager.instance.checkAvailability();
    if (availability == NfcAvailability.disabled ||
        availability == NfcAvailability.unsupported) {
      print('unavailable or unsupported');
      throw Exception('NFC not available');
    } else {
      do {
        print('starting session');
        Completer nfcDataProcessing = Completer();
        await NfcManager.instance.startSession(
          pollingOptions: {NfcPollingOption.iso14443},
          onDiscovered: (NfcTag nfc) async =>
              _processNfcData(nfcDataProcessing: nfcDataProcessing, nfc: nfc),
        );
        await nfcDataProcessing.future;
      } while (true);
    }
  }

  Future<void> _processNfcData({
    required Completer nfcDataProcessing,
    required NfcTag nfc,
  }) async {
    try {
      NfcData newNfc;
      final Ndef? ndef = await Ndef.from(nfc);
      final NfcTagAndroid? nfcTag = await NfcTagAndroid.from(nfc);

      final String nfcUid;

      if (ndef == null) throw ('Tag is not ndef');
      if (nfcTag != null) {
        nfcUid = _parseNfcUid(nfcTag.id);
      } else {
        nfcUid = '';
      }

      if (_nfcTags[nfcUid] == null) {
        NfcData newNfc = NfcData(ndefMessage: ndef.cachedMessage, uid: nfcUid);
        print('${newNfc.characterName}');
        print('${newNfc.uid}');
        _nfcTags[nfcUid] = newNfc;
      } else {
        print('not new');
        newNfc = _nfcTags[nfcUid]!;
        if (_latestNfcData.uid != newNfc.uid) {
          print('not latest update');
          if (newNfc.slimeType != null) {
            print('checking slimeType ${newNfc.slimeType}');
            switch (newNfc.slimeType) {
              case [50]:
                print('Land');
                _nfcType = 'Land';
                notifyListeners();
              case [49]:
                print('Water');
                _nfcType = 'Water';
                notifyListeners();
              case [48]:
                print('Lava');
                _nfcType = 'Lava';
                notifyListeners();
              default:
            }
          }
        }
        _latestNfcData = newNfc;
      }
    } catch (e) {
      print('$e');
    }
    print('scan completed');

    print('stopping session');
    await NfcManager.instance.stopSession();
    nfcDataProcessing.complete();
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

  //  final ndefMessage = NdefMessage(          <-- à utiliser en cas de tests
  //       records: [
  //         NdefRecord(
  //           typeNameFormat: .wellKnown,
  //           type: utf8.encode('U'),
  //           identifier: Uint8List.fromList([]),
  //           payload: utf8.encode('Link'),
  //         ),
  //         NdefRecord(
  //           typeNameFormat: .external,
  //           type: utf8.encode('g:i'),
  //           identifier: Uint8List.fromList([]),
  //           payload: utf8.encode('1'),
  //         ),
  //         NdefRecord(
  //           typeNameFormat: .external,
  //           type: utf8.encode('g:i'),
  //           identifier: Uint8List.fromList([]),
  //           payload: utf8.encode('2'),
  //         ),
  //         NdefRecord(
  //           typeNameFormat: .external,
  //           type: utf8.encode('g:i'),
  //           identifier: Uint8List.fromList([]),
  //           payload: utf8.encode('3'),
  //         ),
  //       ],
  //     );

  //     await ndef.write(message: ndefMessage);
}
