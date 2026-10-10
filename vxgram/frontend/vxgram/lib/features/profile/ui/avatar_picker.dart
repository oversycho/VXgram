import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../bloc/profile_bloc.dart';

/// Opens the gallery and sends the chosen image to the ProfileBloc (upload happens there).
Future<void> pickAvatar(BuildContext context) async {
  final bloc = context.read<ProfileBloc>();
  final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
  if (x == null) return;
  final bytes = await x.readAsBytes();
  final ext = x.name.contains('.') ? x.name.split('.').last : 'jpg';
  bloc.add(AvatarPicked(bytes, ext));
}

class EditableAvatar extends StatelessWidget {
  const EditableAvatar({super.key, required this.url, required this.onTap, this.size = 88});
  final String? url; final VoidCallback? onTap; final double size;
  @override
  Widget build(BuildContext context) {
    final c = VxColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Stack(children: [
        Avatar(url: url, size: size),
        if (onTap != null)
          PositionedDirectional(bottom: 0, end: 0, child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle, border: Border.all(color: c.bg, width: 2)),
            child: Icon(Icons.camera_alt, size: 14, color: c.onPrimary),
          )),
      ]),
    );
  }
}
