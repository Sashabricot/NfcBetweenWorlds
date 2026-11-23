import 'package:flutter/material.dart';
import 'package:nfc_between_worlds/src/menu/presentation_page/chapter_pages/nfc_page.dart';
import 'package:nfc_between_worlds/src/menu/presentation_page/chapter_pages/reader_mode_page.dart';
import 'package:nfc_between_worlds/src/menu/presentation_page/chapter_pages/tiled_page.dart';
import 'package:nfc_between_worlds/src/menu/presentation_page/constant_widgets/presentation_page_button.dart';
import 'package:nfc_between_worlds/src/provider/nfc_data_notifier.dart';

class PresentationPageMenu extends StatelessWidget {
  const PresentationPageMenu({super.key, required this.nfcDataNotifier});

  final NfcDataNotifier nfcDataNotifier;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'NFC BW - Dossier Visuel',
          style: TextStyle(fontWeight: .bold),
        ),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: Padding(
          padding: .symmetric(vertical: 36, horizontal: 24),
          child: Column(
            mainAxisSize: .max,
            crossAxisAlignment: .center,
            children: [
              PresentationPageButton(
                widget: NfcPage(),
                text: 'Chapitre 1 - NFC',
                replace: false,
              ),
              SizedBox(height: 8),
              PresentationPageButton(
                widget: TiledPage(),
                text: 'Chapitre 2 - Tiled et images',
                replace: false,
              ),
              Expanded(child: SizedBox()),
              PresentationPageButton(
                widget: ReaderModePage(nfcDataNotifier: nfcDataNotifier),
                text: 'Reader mode',
                replace: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
