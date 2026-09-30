import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Paints [painter] once into an image at the screen's resolution, then
/// shows that image until the painter needs repainting.
///
/// For detailed, mostly static paintings (the sand, the board's lines, the
/// pieces at rest): without a raster cache, as with Impeller, they would
/// otherwise be rendered again on every frame of any animation above them.
class RasterizedPaint extends StatefulWidget {
  const RasterizedPaint({super.key, required this.painter, required this.size});

  final CustomPainter painter;
  final Size size;

  @override
  State<RasterizedPaint> createState() => _RasterizedPaintState();
}

class _RasterizedPaintState extends State<RasterizedPaint> {
  ui.Image? _image;
  CustomPainter? _painted;
  Size? _paintedSize;
  double? _paintedRatio;

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final painted = _painted;
    if (_image == null ||
        painted == null ||
        _paintedSize != widget.size ||
        _paintedRatio != ratio ||
        widget.painter.shouldRepaint(painted)) {
      _render(ratio);
    }
    return RawImage(
      image: _image,
      width: widget.size.width,
      height: widget.size.height,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.medium,
    );
  }

  void _render(double ratio) {
    final size = widget.size;
    if (!size.isFinite) return;
    final width = (size.width * ratio).ceil();
    final height = (size.height * ratio).ceil();
    if (width <= 0 || height <= 0) return;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(ratio);
    widget.painter.paint(canvas, size);
    final picture = recorder.endRecording();
    final image = picture.toImageSync(width, height);
    picture.dispose();
    _image?.dispose();
    _image = image;
    _painted = widget.painter;
    _paintedSize = size;
    _paintedRatio = ratio;
  }
}
