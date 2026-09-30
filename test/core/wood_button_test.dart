import 'package:dhamet/core/widgets/wood_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: Center(child: child));

  testWidgets('a plank calls back when tapped', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        WoodButton(label: 'Undo', icon: Icons.undo, onPressed: () => taps++),
      ),
    );
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(
      tester.getSize(find.byType(WoodButton)).height,
      greaterThanOrEqualTo(56),
    );
  });

  testWidgets('a disabled plank does nothing', (tester) async {
    await tester.pumpWidget(
      host(const WoodButton(label: 'Redo', onPressed: null)),
    );
    await tester.tap(find.text('Redo'), warnIfMissed: false);
    await tester.pumpAndSettle();
    final handle = tester.ensureSemantics();
    expect(
      tester.getSemantics(find.text('Redo')),
      matchesSemantics(
        label: 'Redo',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
        isFocusable: false,
      ),
    );
    handle.dispose();
  });

  testWidgets('an icon plank is named by its tooltip', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        WoodButton.icon(
          icon: Icons.pause,
          tooltip: 'Pause',
          onPressed: () => taps++,
        ),
      ),
    );
    await tester.tap(find.byTooltip('Pause'));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });
}
