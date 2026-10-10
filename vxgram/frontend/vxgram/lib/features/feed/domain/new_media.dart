import 'dart:typed_data';

/// A picked file waiting to be uploaded (kept as bytes so it works on every platform).
class NewMedia {
  const NewMedia({required this.bytes, required this.ext, this.thumbBytes});
  final Uint8List bytes; final String ext;
  final Uint8List? thumbBytes; // small JPEG made at pick time (optional)

  static const imageExts = {'jpg', 'jpeg', 'png', 'webp'};
  static const videoExts = {'mp4', 'mov', 'webm'};
  static const maxBytes = 100 * 1024 * 1024; // bucket limit
  static const maxItems = 10;               // trigger limit

  String get _e => ext.toLowerCase();
  bool get isVideo => videoExts.contains(_e);
  bool get isSupported => imageExts.contains(_e) || videoExts.contains(_e);
}
