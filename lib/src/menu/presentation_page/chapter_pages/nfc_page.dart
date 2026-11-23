import 'package:flutter/material.dart';
import 'package:nfc_between_worlds/src/menu/presentation_page/constant_widgets/image_slider.dart';
import 'package:nfc_between_worlds/src/menu/presentation_page/constant_widgets/styled_text.dart';

class NfcPage extends StatelessWidget {
  const NfcPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Chapitre 1 - NFC', style: TextStyle(fontWeight: .bold)),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: Padding(
          padding: .symmetric(vertical: 36, horizontal: 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: .max,
              crossAxisAlignment: .center,
              children: [
                StyledText(
                  'Les tags NFC sont utilisés partout, on peut donc citer les cartes bancaires, les badges mais aussi les jeux vidéos.',
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: .maxFinite,
                  child: ImageSlider(
                    images: [
                      'credit_card.jpg',
                      'nfc_badge.jpg',
                      'amiibo.jpg',
                      'skylanders.jpg',
                    ],
                  ),
                ),
                SizedBox(height: 16),
                StyledText(
                  'La compréhension de leur structure joue un rôle clé dans le développement. Les données de mes cartes sont stockées sous un format nommé NDEF',
                ),
                SizedBox(height: 16),
                Image(
                  image: AssetImage(
                    'assets/images/presentation/ndef_schema.jpg',
                  ),
                  filterQuality: .none,
                  width: .maxFinite,
                  fit: .contain,
                ),
                SizedBox(height: 16),
                StyledText(
                  'Le typage des données était donc primordial pour prendre le moins de place possible dans mes tags NFC. ',
                ),
                SizedBox(height: 16),
                Image(
                  image: AssetImage(
                    'assets/images/presentation/ndef_example.png',
                  ),
                  filterQuality: .none,
                  width: .maxFinite,
                  fit: .contain,
                ),
                SizedBox(height: 512),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
