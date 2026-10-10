import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_theme.dart';

class Logo extends StatelessWidget {
  const Logo({super.key, this.size = 26});
  final double size;
  @override
  Widget build(BuildContext context) {
    final c = VxColors.of(context);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text.rich(TextSpan(children: [
        TextSpan(text: 'VXGram', style: TextStyle(fontWeight: FontWeight.w800, fontSize: size, color: c.text, letterSpacing: -0.5)),
        TextSpan(text: '.', style: TextStyle(fontWeight: FontWeight.w800, fontSize: size, color: c.pink)),
      ])),
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar({super.key, this.url, this.size = 40, this.ring = false});
  final String? url; final double size; final bool ring;
  @override
  Widget build(BuildContext context) {
    final c = VxColors.of(context);
    final img = CircleAvatar(
      radius: size / 2, backgroundColor: c.surface,
      backgroundImage: url != null ? CachedNetworkImageProvider(url!) : null,
      child: url == null ? Icon(Icons.person, size: size * .55, color: c.muted) : null,
    );
    if (!ring) return img;
    return Container(
      padding: const EdgeInsets.all(2.5), decoration: BoxDecoration(shape: BoxShape.circle, gradient: c.brand),
      child: Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(shape: BoxShape.circle, color: c.bg), child: img),
    );
  }
}

/// Image or video for a post. Video: tap to play/pause. [play]=false shows a placeholder (grids).
class MediaTile extends StatefulWidget {
  const MediaTile({super.key, required this.url, required this.isVideo, this.play = true, this.thumbUrl});
  final String url; final bool isVideo, play;
  final String? thumbUrl; // small preview; grids (play: false) show it instead of the full file
  @override
  State<MediaTile> createState() => _MediaTileState();
}

class _MediaTileState extends State<MediaTile> {
  VideoPlayerController? _v;
  @override
  void initState() {
    super.initState();
    if (widget.isVideo && widget.play) {
      _v = VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..setLooping(true)
        ..initialize().then((_) { if (mounted) setState(() {}); });
    }
  }
  @override
  void dispose() { _v?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = VxColors.of(context);
    if (!widget.play) {
      // grid / list preview: tiny decoded image. Videos without a thumbnail get a placeholder.
      final src = widget.thumbUrl ?? (widget.isVideo ? null : widget.url);
      if (src == null) return Container(color: c.surface, child: Icon(Icons.play_circle_outline, color: c.muted, size: 32));
      return CachedNetworkImage(imageUrl: src, fit: BoxFit.cover, width: double.infinity, height: double.infinity, memCacheWidth: 400,
          placeholder: (_, __) => Container(color: c.surface),
          errorWidget: (_, __, ___) => Container(color: c.surface, child: Icon(Icons.broken_image_outlined, color: c.muted)));
    }
    if (widget.isVideo) {
      final v = _v;
      if (v == null || !v.value.isInitialized) {
        return Stack(fit: StackFit.expand, children: [
          if (widget.thumbUrl != null) CachedNetworkImage(imageUrl: widget.thumbUrl!, fit: BoxFit.cover) else Container(color: c.surface),
          const Center(child: CircularProgressIndicator()),
        ]);
      }
      return GestureDetector(
        onTap: () => setState(() => v.value.isPlaying ? v.pause() : v.play()),
        child: Stack(alignment: Alignment.center, fit: StackFit.expand, children: [
          FittedBox(fit: BoxFit.cover, clipBehavior: Clip.hardEdge, child: SizedBox(width: v.value.size.width, height: v.value.size.height, child: VideoPlayer(v))),
          if (!v.value.isPlaying) const Icon(Icons.play_arrow_rounded, size: 72, color: Colors.white70),
        ]),
      );
    }
    return CachedNetworkImage(imageUrl: widget.url, fit: BoxFit.cover, width: double.infinity, height: double.infinity,
        placeholder: (_, __) => Container(color: c.surface),
        errorWidget: (_, __, ___) => Container(color: c.surface, child: Icon(Icons.broken_image_outlined, color: c.muted)));
  }
}

class AppTextField extends StatefulWidget {
  const AppTextField({super.key, required this.controller, required this.label, this.obscure = false, this.ltr = false,
      this.keyboard, this.validator, this.onChanged, this.helper, this.helperColor, this.maxLength, this.maxLines = 1});
  final TextEditingController controller; final String label; final bool obscure, ltr;
  final TextInputType? keyboard; final String? Function(String?)? validator; final ValueChanged<String>? onChanged;
  final String? helper; final Color? helperColor; final int? maxLength, maxLines;
  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _hide = true;
  @override
  Widget build(BuildContext context) {
    final c = VxColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: widget.controller, obscureText: widget.obscure && _hide, keyboardType: widget.keyboard,
        validator: widget.validator, onChanged: widget.onChanged,
        textDirection: widget.ltr || widget.obscure ? TextDirection.ltr : null, textAlign: TextAlign.start,
        autocorrect: false, maxLength: widget.maxLength, maxLines: widget.obscure ? 1 : widget.maxLines,
        decoration: InputDecoration(
          labelText: widget.label, helperText: widget.helper, helperStyle: TextStyle(color: widget.helperColor ?? c.muted),
          suffixIcon: widget.obscure
              ? IconButton(icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: c.muted), onPressed: () => setState(() => _hide = !_hide))
              : null,
        ),
      ),
    );
  }
}

/// Scrollable page body: centers content when there is room, scrolls when the keyboard
/// or a small screen leaves less space, and dismisses the keyboard on tap / drag.
class KeyboardSafeBody extends StatelessWidget {
  const KeyboardSafeBody({super.key, required this.child, this.center = true});
  final Widget child; final bool center;
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: math.max(0, box.maxHeight - 48)),
              child: center ? Center(child: child) : child,
            ),
          ),
        ),
      );
}
