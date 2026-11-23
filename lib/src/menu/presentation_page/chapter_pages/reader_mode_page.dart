import 'package:flutter/material.dart';
import 'package:nfc_between_worlds/src/provider/nfc_data_notifier.dart';

class ReaderModePage extends StatelessWidget {
  const ReaderModePage({super.key, required this.nfcDataNotifier});
  final NfcDataNotifier nfcDataNotifier;
  @override
  Widget build(BuildContext context) {
    nfcDataNotifier.startNfcCardTypeScan(updateDatabase: true);
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
              'Reader mode active',
              style: TextStyle(color: Colors.white, fontFamily: 'Pixel'),
            ),
          ),
        ],
      ),
    );
  }
}
