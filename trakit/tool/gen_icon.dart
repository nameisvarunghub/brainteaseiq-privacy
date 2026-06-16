// Generates the TrakIt launcher icon and adaptive-icon foreground.
//
// Usage:
//   dart run tool/gen_icon.dart
//
// Writes:
//   assets/icons/app_icon.png            (1024x1024, fully opaque)
//   assets/icons/app_icon_foreground.png (1024x1024, transparent bg)
//
// Then run flutter_launcher_icons to fan out into platform assets:
//   dart run flutter_launcher_icons

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const _size = 1024;
const _bgTop = (0x7C, 0x5C, 0xFF); // brand deep
const _bgBottom = (0xFF, 0x7A, 0x59); // accent deep
const _glyph = (0xFF, 0xFF, 0xFF);

void main() async {
  final assets = Directory('assets/icons');
  if (!assets.existsSync()) assets.createSync(recursive: true);

  final opaque = _drawIcon(opaqueBackground: true);
  final foreground = _drawIcon(opaqueBackground: false);

  await File('${assets.path}/app_icon.png')
      .writeAsBytes(img.encodePng(opaque));
  await File('${assets.path}/app_icon_foreground.png')
      .writeAsBytes(img.encodePng(foreground));

  stdout.writeln('Wrote app_icon.png and app_icon_foreground.png to ${assets.path}/');
}

img.Image _drawIcon({required bool opaqueBackground}) {
  final image = img.Image(width: _size, height: _size, numChannels: 4);
  if (opaqueBackground) {
    _fillRadialGradient(image);
    _drawBlobs(image);
  } else {
    // Transparent for the adaptive foreground — Android composes it over
    // the configured background color.
    img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));
  }
  _drawRupeeGlyph(image);
  return image;
}

void _fillRadialGradient(img.Image image) {
  final cx = _size / 2;
  final cy = _size / 2;
  final maxR = math.sqrt(cx * cx + cy * cy);
  for (int y = 0; y < _size; y++) {
    for (int x = 0; x < _size; x++) {
      final dx = x - cx;
      final dy = y - cy;
      final t = (math.sqrt(dx * dx + dy * dy) / maxR).clamp(0.0, 1.0);
      // Top-left is brand deep, bottom-right is accent — bias by t for radial.
      final r = (_bgTop.$1 * (1 - t) + _bgBottom.$1 * t).round();
      final g = (_bgTop.$2 * (1 - t) + _bgBottom.$2 * t).round();
      final b = (_bgTop.$3 * (1 - t) + _bgBottom.$3 * t).round();
      image.setPixel(x, y, img.ColorRgba8(r, g, b, 255));
    }
  }
}

void _drawBlobs(img.Image image) {
  // Two soft highlight blobs for depth.
  _softCircle(image, _size * 0.32, _size * 0.28, _size * 0.30,
      const (255, 255, 255), 0.18);
  _softCircle(image, _size * 0.75, _size * 0.78, _size * 0.34,
      const (255, 255, 255), 0.10);
}

void _softCircle(img.Image image, double cx, double cy, double r,
    (int, int, int) color, double maxAlpha) {
  final r2 = r * r;
  for (int y = (cy - r).floor(); y < (cy + r).ceil(); y++) {
    if (y < 0 || y >= _size) continue;
    for (int x = (cx - r).floor(); x < (cx + r).ceil(); x++) {
      if (x < 0 || x >= _size) continue;
      final dx = x - cx;
      final dy = y - cy;
      final d2 = dx * dx + dy * dy;
      if (d2 > r2) continue;
      final t = 1 - math.sqrt(d2) / r;
      final a = (t * t * maxAlpha * 255).round();
      _blendPixel(image, x, y, color.$1, color.$2, color.$3, a);
    }
  }
}

void _drawRupeeGlyph(img.Image image) {
  // Render a stylised ₹ by stroking three primitives:
  //  1. top horizontal bar
  //  2. middle horizontal bar
  //  3. spine with a diagonal leg
  //
  // We draw in white onto a working buffer with anti-aliased rounded
  // rectangles via supersampling.
  final cx = _size / 2;
  const padding = 0.18; // proportion of the canvas inset
  final left = _size * padding + _size * 0.04;
  final right = _size * (1 - padding) - _size * 0.04;
  final top = _size * padding;
  final bottom = _size * (1 - padding);

  final stroke = _size * 0.075;
  final radius = stroke * 0.5;

  // top bar
  _roundedRect(image, left, top, right, top + stroke, radius);
  // middle bar
  final midY = top + stroke * 2.2;
  _roundedRect(image, left, midY, right, midY + stroke, radius);

  // spine - vertical line slightly left of center, with a small belly curve
  final spineX = left + (right - left) * 0.18;
  _roundedRect(image, spineX, top, spineX + stroke, bottom, radius);

  // semicircle attaching the spine to the right side (the ₹ loop)
  final loopRadius = (right - spineX) * 0.55;
  _strokeArc(image, spineX + loopRadius * 0.6, top + stroke * 3.5, loopRadius,
      math.pi * 1.55, math.pi * 0.65, stroke);

  // diagonal leg from spine to bottom-right
  _strokeLine(image, spineX + stroke / 2, top + stroke * 3.5, right - stroke * 0.6,
      bottom, stroke);

  // tiny center tag to hint at a coin
  final r = _size * 0.04;
  _circle(image, cx, bottom - stroke * 2, r);
}

void _roundedRect(img.Image image, double x0, double y0, double x1, double y1,
    double radius) {
  final r2 = radius * radius;
  final ix0 = x0.floor();
  final iy0 = y0.floor();
  final ix1 = x1.ceil();
  final iy1 = y1.ceil();
  for (int y = iy0; y < iy1; y++) {
    if (y < 0 || y >= _size) continue;
    for (int x = ix0; x < ix1; x++) {
      if (x < 0 || x >= _size) continue;
      // distance from inner rect
      double cdx = 0;
      double cdy = 0;
      if (x < x0 + radius) {
        cdx = x - (x0 + radius);
      } else if (x > x1 - radius) {
        cdx = x - (x1 - radius);
      }
      if (y < y0 + radius) {
        cdy = y - (y0 + radius);
      } else if (y > y1 - radius) {
        cdy = y - (y1 - radius);
      }
      final d2 = cdx * cdx + cdy * cdy;
      if (d2 <= r2) {
        // soft edge
        final d = math.sqrt(d2);
        final t = (1 - (d / radius)).clamp(0.0, 1.0);
        final a = (255 * (0.7 + 0.3 * t)).round();
        _blendPixel(image, x, y, _glyph.$1, _glyph.$2, _glyph.$3, a);
      }
    }
  }
}

void _circle(img.Image image, double cx, double cy, double r) {
  final r2 = r * r;
  for (int y = (cy - r).floor(); y < (cy + r).ceil(); y++) {
    if (y < 0 || y >= _size) continue;
    for (int x = (cx - r).floor(); x < (cx + r).ceil(); x++) {
      if (x < 0 || x >= _size) continue;
      final dx = x - cx;
      final dy = y - cy;
      final d2 = dx * dx + dy * dy;
      if (d2 <= r2) {
        _blendPixel(image, x, y, _glyph.$1, _glyph.$2, _glyph.$3, 255);
      }
    }
  }
}

void _strokeLine(
    img.Image image, double x0, double y0, double x1, double y1, double width) {
  // anti-aliased thick line using distance-to-segment
  final w2 = (width / 2) * (width / 2);
  final minX = (math.min(x0, x1) - width).floor();
  final maxX = (math.max(x0, x1) + width).ceil();
  final minY = (math.min(y0, y1) - width).floor();
  final maxY = (math.max(y0, y1) + width).ceil();
  final lenSq = (x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0);
  for (int y = minY; y < maxY; y++) {
    if (y < 0 || y >= _size) continue;
    for (int x = minX; x < maxX; x++) {
      if (x < 0 || x >= _size) continue;
      final t = ((x - x0) * (x1 - x0) + (y - y0) * (y1 - y0)) / lenSq;
      final tc = t.clamp(0.0, 1.0);
      final px = x0 + (x1 - x0) * tc;
      final py = y0 + (y1 - y0) * tc;
      final dx = x - px;
      final dy = y - py;
      final d2 = dx * dx + dy * dy;
      if (d2 <= w2) {
        _blendPixel(image, x, y, _glyph.$1, _glyph.$2, _glyph.$3, 255);
      }
    }
  }
}

void _strokeArc(img.Image image, double cx, double cy, double r,
    double startAngle, double endAngle, double width) {
  final innerR = r - width / 2;
  final outerR = r + width / 2;
  final innerR2 = innerR * innerR;
  final outerR2 = outerR * outerR;
  for (int y = (cy - outerR).floor(); y < (cy + outerR).ceil(); y++) {
    if (y < 0 || y >= _size) continue;
    for (int x = (cx - outerR).floor(); x < (cx + outerR).ceil(); x++) {
      if (x < 0 || x >= _size) continue;
      final dx = x - cx;
      final dy = y - cy;
      final d2 = dx * dx + dy * dy;
      if (d2 < innerR2 || d2 > outerR2) continue;
      var angle = math.atan2(dy, dx);
      if (angle < 0) angle += math.pi * 2;
      var s = startAngle % (math.pi * 2);
      var e = endAngle % (math.pi * 2);
      bool inArc;
      if (s <= e) {
        inArc = angle >= s && angle <= e;
      } else {
        inArc = angle >= s || angle <= e;
      }
      if (inArc) {
        _blendPixel(image, x, y, _glyph.$1, _glyph.$2, _glyph.$3, 255);
      }
    }
  }
}

void _blendPixel(img.Image image, int x, int y, int r, int g, int b, int a) {
  final existing = image.getPixel(x, y);
  final er = existing.r.toInt();
  final eg = existing.g.toInt();
  final eb = existing.b.toInt();
  final ea = existing.a.toInt();
  final af = a / 255;
  final outA = (a + ea * (1 - af)).clamp(0, 255).toInt();
  final outR = (r * af + er * (1 - af)).round().clamp(0, 255);
  final outG = (g * af + eg * (1 - af)).round().clamp(0, 255);
  final outB = (b * af + eb * (1 - af)).round().clamp(0, 255);
  image.setPixel(x, y, img.ColorRgba8(outR, outG, outB, outA));
}
