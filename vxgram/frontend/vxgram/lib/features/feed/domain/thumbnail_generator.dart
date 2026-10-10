import 'dart:typed_data';

/// Makes a small JPEG preview for a picked image or video. Returns null when it can't
/// (a missing thumbnail is not an error: grids fall back to the file itself / a placeholder).
abstract class ThumbnailGenerator {
  Future<Uint8List?> create({required String path, required Uint8List bytes, required String ext});
}
