import 'dart:convert';
import 'dart:typed_data';

import 'package:nfc_manager/ndef_record.dart';

class NfcData {
  NfcData(
      {required this.ndefMessage,
      required this.uid,
      this.characterName,
      this.characterItems,
      this.slimeType}) {
    print('calling constr');
    characterName = '';
    characterItems = [];

    if (ndefMessage != null) {
      if (ndefMessage!.records.isNotEmpty) {
        for (NdefRecord record in ndefMessage!.records) {
          String typeNameFormatString;
          typeNameFormatString = _getType(record);

          switch (typeNameFormatString) {
            case 'U':
              characterName = utf8.decode(record.payload);
              print('character name :  $characterName');
            case 'g:i':
              characterItems!.add(record);
              print('item : ${utf8.decode(record.payload)}');
            case 's:t':
              slimeType = record.payload;
          }

          print(
            '${utf8.decode(record.payload)} ${utf8.decode(record.type)} ${record.typeNameFormat}',
          );
        }
      }
    }
  }
  Uint8List? slimeType;
  final NdefMessage? ndefMessage;
  final String uid;
  String? characterName;
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
