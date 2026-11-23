import 'package:flutter/material.dart';
import 'package:nfc_between_worlds/src/menu/presentation_page%20copy/constant_widgets/styled_text.dart';
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
        children: [
          Image(
            image: AssetImage(
              'assets/images/presentation/teleporter_map_tiles.png',
            ),
            filterQuality: .none,
            fit: .cover,
          ),
          Center(child: StyledText('Reader mode active')),
        ],
      ),
    );
  }
}
