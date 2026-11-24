import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flame/components.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';

class NfcSave {
  Future<String> savePlayerDataOnNfc({
    required Vector2 position,
    required Completer stopNfcWriting,
    required String level,
    required List<String> collectedItems,
    required List<Vector2> boxesPosition,
    required int? playerTimer,
    required String characterName,
    required Uint8List nfcUtf8Type,
  }) async {
    String nfcSaveMessage = '';
    NfcManager.instance.stopSession();
    NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443},
      onDiscovered: (NfcTag nfc) async => {
        nfcSaveMessage = await _writeNfcSaveData(
          characterName: characterName,
          nfc: nfc,
          position: position,
          stopNfcWriting: stopNfcWriting,
          level: level,
          collectedItems: collectedItems,
          boxesPosition: boxesPosition,
          playerTimer: playerTimer,
          nfcUtf8Type: nfcUtf8Type,
        ),
      },
    );

    await stopNfcWriting.future;
    return nfcSaveMessage;
  }

  Future<String> _writeNfcSaveData({
    required NfcTag nfc,
    required Vector2 position,
    required Completer stopNfcWriting,
    required String level,
    required List<String> collectedItems,
    required List<Vector2> boxesPosition,
    required int? playerTimer,
    required String characterName,
    required Uint8List nfcUtf8Type,
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
            payload: nfcUtf8Type,
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
      stopNfcWriting.complete();
      return 'SavedData :  \nslimeType : $nfcUtf8Type, \nlevel : $level';
    } catch (e) {
      stopNfcWriting.complete();
      return e.toString();
    }
  }
}
