import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../settings/settings_cubit.dart';

/// Three intro slides shown once, after the language picker and before login.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _i = 0;
  static const _slides = [
    (Icons.photo_camera_outlined, 'onb1'), (Icons.people_outline, 'onb2'), (Icons.explore_outlined, 'onb3'),
  ];

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  void _finish() => context.read<SettingsCubit>().finishOnboarding();

  @override
  Widget build(BuildContext context) {
    final c = VxColors.of(context);
    final last = _i == _slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          SizedBox(
            height: 48,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: last ? null : TextButton(onPressed: _finish, child: Text(context.t('skip'))),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _controller, itemCount: _slides.length, onPageChanged: (i) => setState(() => _i = i),
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(gradient: c.brand, borderRadius: BorderRadius.circular(56)),
                    child: Icon(_slides[i].$1, size: 88, color: Colors.white),
                  ),
                  const SizedBox(height: 40),
                  Text(context.t('${_slides[i].$2}_title'), textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Text(context.t('${_slides[i].$2}_body'), textAlign: TextAlign.center, style: TextStyle(color: c.muted, height: 1.5)),
                ]),
              ),
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var k = 0; k < _slides.length; k++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200), margin: const EdgeInsets.symmetric(horizontal: 3),
                width: k == _i ? 22 : 8, height: 8,
                decoration: BoxDecoration(color: k == _i ? c.primary : c.border, borderRadius: BorderRadius.circular(4)),
              ),
          ]),
          Padding(
            padding: const EdgeInsets.all(24),
            child: FilledButton(
              onPressed: last ? _finish : () => _controller.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
              child: Text(context.t(last ? 'get_started' : 'next')),
            ),
          ),
        ]),
      ),
    );
  }
}
