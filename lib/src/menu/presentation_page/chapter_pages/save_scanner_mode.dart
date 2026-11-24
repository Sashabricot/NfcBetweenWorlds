import 'package:flutter/material.dart';
import 'package:nfc_between_worlds/src/provider/nfc_remote_scanner.dart';

class SaveScannerMode extends StatelessWidget {
  const SaveScannerMode({super.key});
  @override
  Widget build(BuildContext context) {
    NfcRemoteScanner nfcRemoteScanner = NfcRemoteScanner();
    nfcRemoteScanner.loadNfcSave();
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: .expand,
        children: [
          Image(
            image: AssetImage(
              'assets/images/presentation/teleporter_map_tiles.png',
            ),
            filterQuality: .none,
            fit: .cover,
          ),
          Center(
            child: Text(
              'Save Scanner mode active',
              style: TextStyle(color: Colors.white, fontFamily: 'Pixel'),
            ),
          ),
        ],
      ),
    );
  }
}
