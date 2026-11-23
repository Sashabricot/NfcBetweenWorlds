import 'package:flutter/material.dart';
import 'package:nfc_between_worlds/src/provider/nfc_data_notifier.dart';

class ReaderModePage extends StatelessWidget {
  const ReaderModePage({super.key, required this.nfcDataNotifier});
  final NfcDataNotifier nfcDataNotifier;
  @override
  Widget build(BuildContext context) {
    nfcDataNotifier.startNfcCardTypeScan(updateDatabase: true);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Chapitre 1 - NFC', style: TextStyle(fontWeight: .bold)),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: Center(child: Text('Reader mode active')),
    );
  }
}
