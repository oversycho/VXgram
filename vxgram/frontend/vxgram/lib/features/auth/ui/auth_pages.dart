import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../bloc/auth_bloc.dart';
import '../domain/auth_repository.dart';

/// Shows backend errors / notices as snackbars.
class _AuthListener extends StatelessWidget {
  const _AuthListener({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => BlocListener<AuthBloc, AuthState>(
        listenWhen: (p, c) => (c.error != null && c.error != p.error) || (c.notice != null && c.notice != p.notice),
        listener: (context, st) {
          final msg = st.error ?? context.t(st.notice!);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        },
        child: child,
      );
}

String? vReq(BuildContext c, String? v) => (v == null || v.trim().isEmpty) ? c.t('required') : null;
String? vEmail(BuildContext c, String? v) => (v == null || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) ? c.t('invalid_email') : null;
String? vPass(BuildContext c, String? v) => (v == null || v.length < 6) ? c.t('password_short') : null;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(), _pass = TextEditingController();
  @override
  void dispose() { _email.dispose(); _pass.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = VxColors.of(context);
    return _AuthListener(
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _form,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Center(child: Logo(size: 40)),
                  const SizedBox(height: 40),
                  Text(context.t('welcome'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 24),
                  AppTextField(controller: _email, label: context.t('email'), ltr: true, keyboard: TextInputType.emailAddress, validator: (v) => vEmail(context, v)),
                  AppTextField(controller: _pass, label: context.t('password'), obscure: true, validator: (v) => vReq(context, v)),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: () {
                        if (vEmail(context, _email.text) == null) context.read<AuthBloc>().add(ResetRequested(_email.text));
                        else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('invalid_email'))));
                      },
                      child: Text(context.t('forgot')),
                    ),
                  ),
                  const SizedBox(height: 8),
                  BlocBuilder<AuthBloc, AuthState>(
                    buildWhen: (p, c) => p.busy != c.busy,
                    builder: (context, st) => FilledButton(
                      onPressed: st.busy ? null : () {
                        if (_form.currentState!.validate()) context.read<AuthBloc>().add(LoginSubmitted(_email.text, _pass.text));
                      },
                      child: st.busy ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2)) : Text(context.t('login')),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpPage())),
                    child: Text(context.t('no_account'), style: TextStyle(color: c.primary, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _form = GlobalKey<FormState>();
  final _user = TextEditingController(), _name = TextEditingController(), _email = TextEditingController(), _pass = TextEditingController();
  Timer? _debounce;
  bool? _available; // null = unknown/checking
  static final _rx = RegExp(r'^[a-zA-Z0-9._]{3,30}$');

  @override
  void dispose() { _debounce?.cancel(); _user.dispose(); _name.dispose(); _email.dispose(); _pass.dispose(); super.dispose(); }

  void _check(String v) {
    _debounce?.cancel();
    setState(() => _available = null);
    if (!_rx.hasMatch(v.trim())) return;
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final ok = await context.read<AuthRepository>().usernameAvailable(v);
        if (mounted && _user.text.trim() == v.trim()) setState(() => _available = ok);
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = VxColors.of(context);
    final valid = _rx.hasMatch(_user.text.trim());
    final helper = _user.text.isEmpty || !valid ? context.t('username_rules')
        : _available == null ? '…' : (_available! ? context.t('username_available') : context.t('username_taken'));
    final helperColor = !valid || _available == null ? c.muted : (_available! ? c.success : c.error);
    return _AuthListener(
      child: Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(context.t('signup'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 24),
                AppTextField(controller: _user, label: context.t('username'), ltr: true, onChanged: _check, helper: helper, helperColor: helperColor,
                    validator: (v) => !_rx.hasMatch((v ?? '').trim()) ? context.t('username_rules') : (_available == false ? context.t('username_taken') : null)),
                AppTextField(controller: _name, label: context.t('full_name'), validator: (v) => vReq(context, v)),
                AppTextField(controller: _email, label: context.t('email'), ltr: true, keyboard: TextInputType.emailAddress, validator: (v) => vEmail(context, v)),
                AppTextField(controller: _pass, label: context.t('password'), obscure: true, validator: (v) => vPass(context, v)),
                const SizedBox(height: 8),
                BlocBuilder<AuthBloc, AuthState>(
                  buildWhen: (p, c) => p.busy != c.busy,
                  builder: (context, st) => FilledButton(
                    onPressed: st.busy ? null : () {
                      if (_form.currentState!.validate()) {
                        context.read<AuthBloc>().add(SignUpSubmitted(email: _email.text, password: _pass.text, username: _user.text, fullName: _name.text));
                      }
                    },
                    child: st.busy ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2)) : Text(context.t('create')),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(onPressed: () => Navigator.pop(context), child: Text(context.t('have_account'), style: TextStyle(color: c.primary, fontWeight: FontWeight.w600))),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
