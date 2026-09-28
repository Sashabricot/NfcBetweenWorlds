import 'dart:convert';
import 'dart:typed_data';

import 'package:nfc_manager/ndef_record.dart';

class NfcData {
  NfcData({
    required this.ndefMessage,
    required this.uid,
    this.characterPosition,
    this.characterItems,
    this.slimeType,
  }) {
    characterPosition = '';
    characterItems = [];

    if (ndefMessage != null) {
      if (ndefMessage!.records.isNotEmpty) {
        for (NdefRecord record in ndefMessage!.records) {
          String typeNameFormatString;
          typeNameFormatString = _getType(record);

          switch (typeNameFormatString) {
            case 'U':
              characterPosition = utf8.decode(record.payload);
            case 'g:i':
              characterItems!.add(record);
            case 's:t':
              slimeType = record.payload;
          }
        }
      }
    }
  }

  Uint8List? slimeType;
  final NdefMessage? ndefMessage;
  final String uid;
  String? characterPosition;
  List<NdefRecord>? characterItems;

  String _getType(NdefRecord record) {
    switch (record.typeNameFormat) {
      case TypeNameFormat.wellKnown:
        return utf8.decode(record.type);
      case TypeNameFormat.external:
        return utf8.decode(record.type);
      default:
        return '';
    }
  }
}
