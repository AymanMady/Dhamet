import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The images cut out of the reference art by tool/cut_design_assets.py:
/// the game scene used as background, the stick and the pebble used as
/// pieces, the sand of the board and the plank of the buttons.
class GameArt {
  const GameArt({
    required this.scene,
    required this.stick,
    required this.pebble,
    required this.sand,
    required this.plank,
  });

  final ui.Image scene;

  /// The top of a stick, as it shows above the sand, its foot at the
  /// bottom of the image.
  final ui.Image stick;
  final ui.Image pebble;

  /// A seamless sand texture.
  final ui.Image sand;

  /// A plank without text, stretched behind the buttons' labels.
  final ui.Image plank;

  static const directory = 'assets/images';

  static Future<GameArt> load(AssetBundle bundle) async {
    Future<ui.Image> image(String name) async {
      final data = await bundle.load('$directory/$name');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      codec.dispose();
      return frame.image;
    }

    final images = await Future.wait([
      image('scene.jpg'),
      image('stick.png'),
      image('pebble.png'),
      image('sand.jpg'),
      image('plank.png'),
    ]);
    return GameArt(
      scene: images[0],
      stick: images[1],
      pebble: images[2],
      sand: images[3],
      plank: images[4],
    );
  }
}

/// The art loaded at start-up. `null` until then, and in tests: the scene,
/// the pieces and the planks are then drawn by the code instead.
final gameArtProvider = Provider<GameArt?>((ref) => null);

/// Makes the [GameArt] available to the widgets and painters below it.
class GameArtScope extends InheritedWidget {
  const GameArtScope({super.key, required this.art, required super.child});

  final GameArt? art;

  static GameArt? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GameArtScope>()?.art;

  @override
  bool updateShouldNotify(GameArtScope oldWidget) => oldWidget.art != art;
}
