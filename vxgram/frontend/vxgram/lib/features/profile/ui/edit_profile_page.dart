import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/widgets/common.dart';
import '../bloc/profile_bloc.dart';
import 'avatar_picker.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _user, _bio;
  static final _rx = RegExp(r'^[a-zA-Z0-9._]{3,30}$');

  @override
  void initState() {
    super.initState();
    final p = context.read<ProfileBloc>().state.profile!;
    _name = TextEditingController(text: p.fullName ?? '');
    _user = TextEditingController(text: p.username);
    _bio = TextEditingController(text: p.bio);
  }
  @override
  void dispose() { _name.dispose(); _user.dispose(); _bio.dispose(); super.dispose(); }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final p = context.read<ProfileBloc>().state.profile!;
    final newUser = _user.text.trim().toLowerCase();
    context.read<ProfileBloc>().add(ProfileEdited(
      fullName: _name.text.trim(), bio: _bio.text.trim(), username: newUser == p.username.toLowerCase() ? null : newUser));
  }

  @override
  Widget build(BuildContext context) => BlocListener<ProfileBloc, ProfileState>(
        listenWhen: (p, s) => s.notice == 'profile_updated' && p.notice != s.notice,
        listener: (context, st) => Navigator.pop(context),
        child: Scaffold(
          appBar: AppBar(title: Text(context.t('edit_profile')), actions: [
            BlocBuilder<ProfileBloc, ProfileState>(
              buildWhen: (p, s) => p.busy != s.busy,
              builder: (context, st) => TextButton(onPressed: st.busy ? null : _save, child: Text(context.t('save'))),
            ),
          ]),
          body: KeyboardSafeBody(
            center: false,
            child: Form(
              key: _form,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                BlocBuilder<ProfileBloc, ProfileState>(
                  builder: (context, st) => Column(children: [
                    EditableAvatar(url: st.profile?.avatarUrl, size: 96, onTap: st.busy ? null : () => pickAvatar(context)),
                    TextButton(onPressed: st.busy ? null : () => pickAvatar(context), child: Text(context.t('change_photo'))),
                    if (st.busy) const Padding(padding: EdgeInsets.only(bottom: 8), child: LinearProgressIndicator()),
                  ]),
                ),
                const SizedBox(height: 8),
                AppTextField(controller: _name, label: context.t('name')),
                AppTextField(controller: _user, label: context.t('username'), ltr: true,
                    validator: (v) => _rx.hasMatch((v ?? '').trim()) ? null : context.t('username_rules')),
                AppTextField(controller: _bio, label: context.t('bio'), maxLength: 150, maxLines: 3),
              ]),
            ),
          ),
        ),
      );
}
