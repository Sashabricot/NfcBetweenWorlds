import 'package:flutter/material.dart';
import 'package:nfc_between_worlds/src/menu/presentation_page%20copy/constant_widgets/image_slider.dart';
import 'package:nfc_between_worlds/src/menu/presentation_page%20copy/constant_widgets/styled_text.dart';

class TiledPage extends StatelessWidget {
  const TiledPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Chapitre 2 - Tiled et images',
          style: TextStyle(fontWeight: .bold),
        ),
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
                  'Tiled est un outil me permettant de placer des images dans une grille et de créer plusieurs calques pour donner une illusion de 3ème dimension. Il me sert également à créer des objets pouvant contenir une position, une taille et une image.',
                ),
                SizedBox(height: 16),
                ImageSlider(images: ['tiled_example.png', 'tiled_layers.png']),
                SizedBox(height: 16),
                StyledText(
                  "La création d'un jeu requiert beaucoup d'harmonisation dans son aspect visuel pour rendre son immersion meilleure, c'est pourquoi beaucoup d'éléments ont été retravaillés.",
                ),
                SizedBox(height: 16),
                StyledText(
                  "Nous travaillons donc avec ce qu'on appelle un set de tuiles, voici donc une représentation des différences avec un avant et un après.",
                ),
                SizedBox(height: 16),
                ImageSlider(images: ['old_map_tiles.png', 'Map_tiles.png']),
                SizedBox(height: 16),
                ImageSlider(
                  images: [
                    'old_teleporter_map_tiles.png',
                    'teleporter_map_tiles.png',
                  ],
                ),
                SizedBox(height: 16),
                StyledText(
                  'Il a donc fallu également créer et ajouter des décorations.',
                ),
                SizedBox(height: 16),
                ImageSlider(
                  images: [
                    'button.png',
                    'Grass/3.png',
                    'Grass/10.png',
                    'IceDecorations/Grass/3.png',
                    'IceDecorations/Grass/10.png',
                  ],
                ),
                SizedBox(height: 16),
                StyledText(
                  "Il ne manque donc plus qu'un seul élément à notre set, l'air. J'ai donc créé des tuiles de nuage ainsi qu'un personnage caché sous forme d'Easter Egg.",
                ),
                SizedBox(height: 16),
                ImageSlider(
                  images: ['Slime4_Idle_body.png', 'cloud_map_tiles.png'],
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
