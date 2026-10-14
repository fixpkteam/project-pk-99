import 'package:flutter/material.dart';
import '../../../core/widgets/brand.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/components.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pages = PageController();
  int _index = 0;
  bool _saving = false;
  String? _saveError;

  static const _slides = [
    (
      image: 'assets/images/home-hero.jpg',
      imageLabel: 'A modern home with rooftop solar panels',
      eyebrow: 'WELCOME HOME',
      title: 'Welcome to FixPK',
      description:
          'Expert care for your home, business and everything you’re building.',
      icon: Icons.home_work_outlined,
      caption: 'Engineering. Maintenance. Solutions.',
    ),
    (
      image: 'assets/images/solar-panels.jpg',
      imageLabel: 'Solar panels installed on a residential rooftop',
      eyebrow: 'SOLUTIONS FOR YOUR SPACE',
      title: 'One app. Every solution.',
      description:
          'Explore electrical, solar, AC, security and property services in one place.',
      icon: Icons.grid_view_rounded,
      caption: 'Find the service that fits your needs.',
    ),
    (
      image: 'assets/images/commercial-project.jpg',
      imageLabel: 'A modern commercial building',
      eyebrow: 'FROM IDEA TO DONE',
      title: 'Let’s get your project started.',
      description:
          'Tell us what you need, request a quote and follow the progress with FixPK.',
      icon: Icons.assignment_turned_in_outlined,
      caption: 'Your requests, quotes and updates. Together.',
    ),
  ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _moveTo(int page) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(page);
    } else {
      _pages.animateToPage(
        page,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _finish(String destination) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await ref
          .read(preferencesProvider)
          .setOnboardingCompleted(completed: true);
      if (mounted) context.go(destination);
    } on Object {
      if (!mounted) return;
      setState(
        () => _saveError = 'We couldn’t save your progress. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _index == 0 && !_saving,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && _index > 0 && !_saving) _moveTo(_index - 1);
    },
    child: Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 16, 4),
                  child: Row(
                    children: [
                      const FixPkLogo(width: 104),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (_index > 0)
                              IconButton(
                                tooltip: 'Previous introduction',
                                onPressed: _saving
                                    ? null
                                    : () => _moveTo(_index - 1),
                                icon: const Icon(Icons.arrow_back),
                              ),
                            Flexible(
                              child: TextButton(
                                onPressed: _saving
                                    ? null
                                    : () => _finish('/sign-in'),
                                child: const Text(
                                  'Sign in',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: _slides.length,
                    onPageChanged: (page) => setState(() => _index = page),
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return ListView(
                        key: ValueKey('onboarding-slide-$index'),
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(
                              slide.image,
                              height: (MediaQuery.sizeOf(context).height * .34)
                                  .clamp(180.0, 320.0),
                              width: double.infinity,
                              fit: BoxFit.cover,
                              cacheWidth: 1000,
                              semanticLabel: slide.imageLabel,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            slide.eyebrow,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: FixPkColors.action,
                                  letterSpacing: 1.2,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            slide.title,
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(color: FixPkColors.navy),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            slide.description,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: FixPkColors.body),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: FixPkColors.informationSurface,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                ExcludeSemantics(
                                  child: Icon(
                                    slide.icon,
                                    color: FixPkColors.action,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(slide.caption)),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        label:
                            'Introduction ${_index + 1} of ${_slides.length}',
                        liveRegion: true,
                        child: ExcludeSemantics(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _slides.length,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                height: 8,
                                width: index == _index ? 24 : 8,
                                decoration: BoxDecoration(
                                  color: index == _index
                                      ? FixPkColors.action
                                      : FixPkColors.border,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_saveError != null) ...[
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _saveError!,
                            style: const TextStyle(color: FixPkColors.error),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      AppButton(
                        key: const ValueKey('onboarding-next'),
                        label: _index == _slides.length - 1
                            ? 'Get started'
                            : _index == 0
                            ? 'Continue'
                            : 'Next',
                        icon: Icons.arrow_forward,
                        busy: _saving,
                        onPressed: _saving
                            ? null
                            : () => _index == _slides.length - 1
                                  ? _finish('/sign-up')
                                  : _moveTo(_index + 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
