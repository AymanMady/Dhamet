import 'dart:ui';

/// A smooth closed curve through the midpoints of [points], each point
/// acting as a control point: irregular, hand-made outlines (a pebble, a
/// patch of smoothed sand) without corners.
Path smoothClosedPath(List<Offset> points) {
  final path = Path();
  final count = points.length;
  if (count < 3) return path;
  Offset midpoint(int i) => (points[i % count] + points[(i + 1) % count]) / 2;
  final start = midpoint(0);
  path.moveTo(start.dx, start.dy);
  for (var i = 1; i <= count; i++) {
    final control = points[i % count];
    final end = midpoint(i);
    path.quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
  }
  return path..close();
}
