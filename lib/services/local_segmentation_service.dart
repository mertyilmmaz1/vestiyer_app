import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Lightweight on-device background removal tuned for plain backgrounds.
/// Returns PNG bytes (white background, centered 1:1 canvas) or null.
class LocalSegmentationService {
  static const int _maxInputSide = 1024;
  static const int _outputSize = 512;
  static const double _innerObjectRatio = 0.85;
  static const int _bgThreshold = 42;
  static const int _minForegroundPixels = 1200;

  Future<Uint8List?> segmentFromBytes(Uint8List bytes) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    var source = decoded;
    if (math.max(source.width, source.height) > _maxInputSide) {
      source = img.copyResize(
        source,
        width: source.width >= source.height ? _maxInputSide : null,
        height: source.height > source.width ? _maxInputSide : null,
        interpolation: img.Interpolation.linear,
      );
    }

    final w = source.width;
    final h = source.height;
    if (w < 80 || h < 80) return null;

    final borderColor = _averageBorderColor(source);
    final bgMask = _buildBackgroundMask(source, borderColor);

    int minX = w;
    int minY = h;
    int maxX = -1;
    int maxY = -1;
    int foregroundCount = 0;

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final idx = y * w + x;
        if (bgMask[idx] == 1) continue;
        foregroundCount++;
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }

    if (foregroundCount < _minForegroundPixels ||
        maxX <= minX ||
        maxY <= minY) {
      return null;
    }

    final foreground = img.Image(width: w, height: h);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final idx = y * w + x;
        if (bgMask[idx] == 1) {
          foreground.setPixelRgb(x, y, 255, 255, 255);
          continue;
        }
        final p = source.getPixel(x, y);
        foreground.setPixelRgb(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt());
      }
    }

    final objW = (maxX - minX + 1);
    final objH = (maxY - minY + 1);
    final padX = (objW * 0.05).round();
    final padY = (objH * 0.05).round();
    final cropX = math.max(0, minX - padX);
    final cropY = math.max(0, minY - padY);
    final cropW = math.min(w - cropX, objW + padX * 2);
    final cropH = math.min(h - cropY, objH + padY * 2);

    final cropped = img.copyCrop(
      foreground,
      x: cropX,
      y: cropY,
      width: cropW,
      height: cropH,
    );

    final targetInner = (_outputSize * _innerObjectRatio).round();
    final scale = targetInner / math.max(cropped.width, cropped.height);
    final resized = img.copyResize(
      cropped,
      width: math.max(1, (cropped.width * scale).round()),
      height: math.max(1, (cropped.height * scale).round()),
      interpolation: img.Interpolation.linear,
    );

    final canvas = img.Image(width: _outputSize, height: _outputSize);
    img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
    final xOff = (_outputSize - resized.width) ~/ 2;
    final yOff = (_outputSize - resized.height) ~/ 2;
    img.compositeImage(canvas, resized, dstX: xOff, dstY: yOff);

    return Uint8List.fromList(img.encodePng(canvas));
  }

  List<int> _averageBorderColor(img.Image image) {
    int sumR = 0;
    int sumG = 0;
    int sumB = 0;
    int count = 0;

    for (int x = 0; x < image.width; x++) {
      final top = image.getPixel(x, 0);
      final bottom = image.getPixel(x, image.height - 1);
      sumR += top.r.toInt() + bottom.r.toInt();
      sumG += top.g.toInt() + bottom.g.toInt();
      sumB += top.b.toInt() + bottom.b.toInt();
      count += 2;
    }

    for (int y = 1; y < image.height - 1; y++) {
      final left = image.getPixel(0, y);
      final right = image.getPixel(image.width - 1, y);
      sumR += left.r.toInt() + right.r.toInt();
      sumG += left.g.toInt() + right.g.toInt();
      sumB += left.b.toInt() + right.b.toInt();
      count += 2;
    }

    return [sumR ~/ count, sumG ~/ count, sumB ~/ count];
  }

  Uint8List _buildBackgroundMask(img.Image image, List<int> bgColor) {
    final w = image.width;
    final h = image.height;
    final mask = Uint8List(w * h);
    final visited = Uint8List(w * h);
    final queue = <int>[];
    var head = 0;

    bool isCandidate(int x, int y) {
      final p = image.getPixel(x, y);
      final dr = (p.r.toInt() - bgColor[0]).abs();
      final dg = (p.g.toInt() - bgColor[1]).abs();
      final db = (p.b.toInt() - bgColor[2]).abs();
      return (dr + dg + db) <= _bgThreshold;
    }

    void trySeed(int x, int y) {
      final idx = y * w + x;
      if (visited[idx] == 1) return;
      visited[idx] = 1;
      if (!isCandidate(x, y)) return;
      mask[idx] = 1;
      queue.add(idx);
    }

    for (int x = 0; x < w; x++) {
      trySeed(x, 0);
      trySeed(x, h - 1);
    }
    for (int y = 1; y < h - 1; y++) {
      trySeed(0, y);
      trySeed(w - 1, y);
    }

    while (head < queue.length) {
      final idx = queue[head++];
      final x = idx % w;
      final y = idx ~/ w;

      void visitNeighbor(int nx, int ny) {
        if (nx < 0 || ny < 0 || nx >= w || ny >= h) return;
        final nIdx = ny * w + nx;
        if (visited[nIdx] == 1) return;
        visited[nIdx] = 1;
        if (!isCandidate(nx, ny)) return;
        mask[nIdx] = 1;
        queue.add(nIdx);
      }

      visitNeighbor(x + 1, y);
      visitNeighbor(x - 1, y);
      visitNeighbor(x, y + 1);
      visitNeighbor(x, y - 1);
    }

    return mask;
  }
}
