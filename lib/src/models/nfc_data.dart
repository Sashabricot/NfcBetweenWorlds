import 'dart:convert';
import 'dart:typed_data';

import 'package:nfc_manager/ndef_record.dart';

class NfcData {
  NfcData({
    required this.ndefMessage,
    required this.uid,
    this.characterPosition,
    this.slimeType,
    this.characterLevel,
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
              switch (utf8.decode(record.payload)) {
                case '0':
                  characterItems.add('BeginnerKey');
              }

            case 'g:l':
              characterLevel = utf8.decode(record.payload);
            case 's:t':
              slimeType = record.payload;
            case 's:h':
              shouldTeleportToSlimeHub = true;
          }
        }
      }
    }
  }
  bool? shouldTeleportToSlimeHub;
  Uint8List? slimeType;
  final NdefMessage? ndefMessage;
  final String uid;
  String? characterPosition;
  List<String> characterItems = [];
  String? characterLevel;

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
