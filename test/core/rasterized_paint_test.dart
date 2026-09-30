import 'package:dhamet/core/widgets/rasterized_paint.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _CountingPainter extends CustomPainter {
  _CountingPainter(this.version, this.log);

  final int version;
  final List<int> log;

  @override
  void paint(Canvas canvas, Size size) {
    log.add(version);
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.orange);
  }

  @override
  bool shouldRepaint(_CountingPainter oldDelegate) =>
      oldDelegate.version != version;
}

void main() {
  testWidgets('paints once, and again only when the painter changes', (
    tester,
  ) async {
    final log = <int>[];
    Future<void> show(int version, {double side = 100}) => tester.pumpWidget(
      Center(
        child: RasterizedPaint(
          painter: _CountingPainter(version, log),
          size: Size.square(side),
        ),
      ),
    );

    await show(1);
    expect(find.byType(RawImage), findsOneWidget);
    expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
    await show(1);
    expect(log, [1]);
    await show(2);
    expect(log, [1, 2]);
    await show(2, side: 120);
    expect(log, [1, 2, 2]);
    expect(tester.getSize(find.byType(RawImage)), const Size.square(120));
  });
}
