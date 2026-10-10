import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:video_thumbnail_gen/video_thumbnail_gen.dart';
import '../../feed/domain/new_media.dart';
import '../../feed/domain/thumbnail_generator.dart';

/// Images: resized to 480 px wide JPEG in a background isolate. Videos: first frame via the native plugin.
/// To disable video thumbnails (e.g. if the plugin does not build on your setup), return null in the video branch.
class ThumbnailGeneratorImpl implements ThumbnailGenerator {
  @override
  Future<Uint8List?> create(
      {required String path,
      required Uint8List bytes,
      required String ext}) async {
    try {
      if (NewMedia.videoExts.contains(ext.toLowerCase())) {
        return await VideoThumbnail.thumbnailData(
            video: path,
            imageFormat: ImageFormat.JPEG,
            maxWidth: 480,
            quality: 75);
      }
      return await compute(_resize, bytes);
    } catch (_) {
      return null;
    }
  }
}

Uint8List? _resize(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  final upright = img.bakeOrientation(decoded);
  final small =
      upright.width > 480 ? img.copyResize(upright, width: 480) : upright;
  return Uint8List.fromList(img.encodeJpg(small, quality: 78));
}
