import 'dart:io';
import 'dart:math';
import 'package:image/image.dart';

// Generates assets/icon/app_icon.png — navy background with the
// cyan/magenta capsule robot face from the Pharma Intelligence website.
void main() {
  const s = 1024;
  final img = Image(width: s, height: s);
  fill(img, color: ColorRgb8(5, 6, 15)); // navy bg

  final cyan = ColorRgb8(34, 211, 238);
  final magenta = ColorRgb8(232, 121, 249);
  final dark = ColorRgb8(15, 23, 42);
  final sparkleHi = ColorRgb8(165, 243, 252);

  // Capsule: 760x340, centered
  const w = 760, h = 340, r = h ~/ 2;
  final x0 = (s - w) ~/ 2, y0 = (s - h) ~/ 2;

  // left half cyan, right half magenta
  fillRect(img, x1: x0, y1: y0, x2: x0 + w ~/ 2, y2: y0 + h, color: cyan);
  fillRect(img, x1: x0 + w ~/ 2, y1: y0, x2: x0 + w, y2: y0 + h, color: magenta);
  // round the two ends
  fillCircle(img, x: x0 + r, y: y0 + r, radius: r, color: cyan);
  fillCircle(img, x: x0 + w - r, y: y0 + r, radius: r, color: magenta);

  // carve corners back to navy
  void corner(int cx, int cy, int dx, int dy) {
    for (var y = 0; y < r; y++) {
      for (var x = 0; x < r; x++) {
        final ddx = x - r, ddy = y - r;
        if (ddx * ddx + ddy * ddy > r * r) {
          img.setPixelRgb(cx + dx * x, cy + dy * y, 5, 6, 15);
        }
      }
    }
  }
  corner(x0, y0, 1, 1);
  corner(x0 + w, y0, -1, 1);
  corner(x0, y0 + h, 1, -1);
  corner(x0 + w, y0 + h, -1, -1);

  // Robot face on the cyan half
  const eyeR = 26, eyeY = y0 + r - 50;
  fillCircle(img, x: x0 + 140, y: eyeY, radius: eyeR, color: dark);
  fillCircle(img, x: x0 + 300, y: eyeY, radius: eyeR, color: dark);
  fillCircle(img, x: x0 + 132, y: eyeY - 8, radius: 9, color: sparkleHi);
  fillCircle(img, x: x0 + 292, y: eyeY - 8, radius: 9, color: sparkleHi);

  // smile (arc of small circles)
  for (var a = 30; a <= 150; a += 4) {
    final rad = a * pi / 180;
    fillCircle(img,
        x: x0 + 220 + (45 * cos(rad)).round(),
        y: eyeY + 10 + (45 * sin(rad)).round(),
        radius: 6,
        color: dark);
  }

  // Sparkles
  void sparkle(int cx, int cy, int sz, ColorRgb8 c) {
    fillPolygon(img, vertices: [
      Point(cx, cy - sz), Point(cx + sz ~/ 4, cy - sz ~/ 4),
      Point(cx + sz, cy), Point(cx + sz ~/ 4, cy + sz ~/ 4),
      Point(cx, cy + sz), Point(cx - sz ~/ 4, cy + sz ~/ 4),
      Point(cx - sz, cy), Point(cx - sz ~/ 4, cy - sz ~/ 4),
    ], color: c);
  }
  sparkle(x0 - 40, y0 - 30, 34, cyan);
  sparkle(x0 + w + 50, y0 + 20, 26, magenta);
  sparkle(x0 + w + 10, y0 + h + 60, 20, cyan);
  sparkle(x0 - 70, y0 + h - 20, 22, magenta);

  File('assets/icon/app_icon.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(encodePng(img));
  print('Icon written to assets/icon/app_icon.png');
}
