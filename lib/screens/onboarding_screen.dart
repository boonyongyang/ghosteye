import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/constants.dart';
import '../providers/onboarding_provider.dart';
import '../services/app_haptics.dart';
import '../widgets/brand_mark.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _pageTurnDuration = Duration(milliseconds: 360);
  static const _pages = <_OnboardingPageData>[
    _OnboardingPageData(
      eyebrow: 'PRIVATE BY DEFAULT',
      title: 'Keep the shot on the device',
      body:
          'Ghosteye watches the live frame on-device, writes the scene locally, and keeps the camera moment in your hands.',
      details: <String>[
        'Frames stay local while the screenplay builds.',
        'No cloud cutaway between the lens and the line.',
      ],
      backgroundColors: <Color>[
        Color(0xFF030508),
        Color(0xFF0A1118),
        Color(0xFF0B1921),
      ],
      accent: Color(0xFF00C9FF),
      secondaryAccent: Color(0xFFF2B95C),
      motifLabel: 'ON-DEVICE VISION',
    ),
    _OnboardingPageData(
      eyebrow: 'FIRST-RUN SETUP',
      title: 'Let the model prep before the camera rolls',
      body:
          'The first launch may ask for camera permission and prepare a large on-device model. Wi-Fi helps, and CPU fallback can feel slower if the GPU runtime misses.',
      details: <String>[
        'Managed download and local import both stay in the setup flow.',
        'Source-specific recovery remains available if setup stalls.',
      ],
      backgroundColors: <Color>[
        Color(0xFF050608),
        Color(0xFF151018),
        Color(0xFF26171D),
      ],
      accent: Color(0xFFF2B95C),
      secondaryAccent: Color(0xFF00C9FF),
      motifLabel: 'MODEL PREP',
    ),
    _OnboardingPageData(
      eyebrow: 'FIRST TAKE',
      title: 'Direct the tone, then keep the good takes',
      body:
          'Pick a mode to steer the voice, point at the shot you want, and let Ghosteye build the first scene. Recent takes stay in History for review later.',
      details: <String>[
        'NOIR, SCI-FI, and SITCOM redirect the same moment differently.',
        'The first director tips sheet pauses the scene before capture starts.',
      ],
      backgroundColors: <Color>[
        Color(0xFF050608),
        Color(0xFF081019),
        Color(0xFF111C27),
      ],
      accent: Color(0xFF00C9FF),
      secondaryAccent: Color(0xFFF2B95C),
      motifLabel: 'LIVE SCREENPLAY',
    ),
  ];

  final PageController _pageController = PageController();
  bool _submitting = false;
  int _currentPage = 0;

  Future<void> _completeOnboarding() async {
    if (_submitting) {
      return;
    }

    AppHaptics.trigger(AppHapticPattern.action);
    setState(() {
      _submitting = true;
    });

    await ref.read(onboardingProvider.notifier).completeIntro();
    if (!mounted) {
      return;
    }
    context.go('/setup');
  }

  Future<void> _nextPage() async {
    if (_currentPage >= _pages.length - 1) {
      await _completeOnboarding();
      return;
    }

    AppHaptics.trigger(AppHapticPattern.selection);
    await _pageController.nextPage(
      duration: _pageTurnDuration,
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _previousPage() async {
    if (_currentPage == 0) {
      return;
    }

    AppHaptics.trigger(AppHapticPattern.selection);
    await _pageController.previousPage(
      duration: _pageTurnDuration,
      curve: Curves.easeOutCubic,
    );
  }

  void _handlePageChanged(int index) {
    if (_currentPage == index) {
      return;
    }

    setState(() {
      _currentPage = index;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final page = _pages[_currentPage];
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: _handlePageChanged,
            itemBuilder: (context, index) {
              return _OnboardingPosterPage(
                page: _pages[index],
                pageIndex: index,
                controller: _pageController,
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const BrandMark(size: 52, radius: 16),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              AppConstants.appTitle,
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              page.motifLabel,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: page.secondaryAccent.withOpacity(0.85),
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _GlassPillButton(
                        label: 'Skip',
                        onPressed: _submitting ? null : _completeOnboarding,
                      ),
                    ],
                  ),
                  const Spacer(),
                  _OnboardingControlBar(
                    currentPage: _currentPage,
                    pageCount: _pages.length,
                    isLastPage: isLastPage,
                    submitting: _submitting,
                    accent: page.secondaryAccent,
                    onBack: _previousPage,
                    onNext: _nextPage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPosterPage extends StatelessWidget {
  const _OnboardingPosterPage({
    required this.page,
    required this.pageIndex,
    required this.controller,
  });

  final _OnboardingPageData page;
  final int pageIndex;
  final PageController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            var rawPage = pageIndex.toDouble();
            if (controller.hasClients &&
                controller.position.hasContentDimensions) {
              rawPage = controller.page ?? pageIndex.toDouble();
            }
            final pageDelta = rawPage - pageIndex;
            final parallax = pageDelta * 48;
            final rotation = pageDelta * 0.08;

            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: page.backgroundColors,
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Positioned(
                    top: -constraints.maxWidth * 0.18,
                    right: -constraints.maxWidth * 0.2 - parallax,
                    child: Transform.rotate(
                      angle: rotation,
                      child: _LightOrb(
                        size: constraints.maxWidth * 0.72,
                        color: page.accent.withOpacity(0.24),
                      ),
                    ),
                  ),
                  Positioned(
                    top: constraints.maxHeight * 0.18,
                    left: -constraints.maxWidth * 0.28 + parallax * 0.4,
                    child: Transform.rotate(
                      angle: -0.24 - rotation * 0.6,
                      child: _LightBar(
                        width: constraints.maxWidth * 0.86,
                        color: page.secondaryAccent.withOpacity(0.12),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: constraints.maxHeight * 0.2,
                    right: -constraints.maxWidth * 0.08 - parallax * 0.6,
                    child: Transform.rotate(
                      angle: 0.18 + rotation * 0.4,
                      child: _ShutterRings(
                        size: constraints.maxWidth * 0.56,
                        color: page.secondaryAccent.withOpacity(0.24),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: constraints.maxHeight * 0.36,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[
                              Colors.black.withOpacity(0),
                              Colors.black.withOpacity(0.32),
                              Colors.black.withOpacity(0.76),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.zero,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        24,
                        constraints.maxHeight * 0.16,
                        24,
                        constraints.maxHeight * 0.28,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight * 0.56,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.26),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white12,
                                ),
                              ),
                              child: Text(
                                page.eyebrow,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: page.secondaryAccent,
                                  letterSpacing: 1.6,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 320),
                              child: Text(
                                page.title,
                                style: theme.textTheme.displaySmall?.copyWith(
                                  fontSize: 42,
                                  height: 0.92,
                                  shadows: const <Shadow>[
                                    Shadow(
                                      color: Color(0x33000000),
                                      blurRadius: 18,
                                      offset: Offset(0, 10),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 340),
                              child: Text(
                                page.body,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.white.withOpacity(0.88),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            for (final detail in page.details) ...<Widget>[
                              _OnboardingDetailRow(
                                color: page.secondaryAccent,
                                detail: detail,
                              ),
                              const SizedBox(height: 12),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _OnboardingControlBar extends StatelessWidget {
  const _OnboardingControlBar({
    required this.currentPage,
    required this.pageCount,
    required this.isLastPage,
    required this.submitting,
    required this.accent,
    required this.onBack,
    required this.onNext,
  });

  final int currentPage;
  final int pageCount;
  final bool isLastPage;
  final bool submitting;
  final Color accent;
  final Future<void> Function() onBack;
  final Future<void> Function() onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.18),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white12),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      '0${currentPage + 1}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PageIndicators(
                        currentPage: currentPage,
                        pageCount: pageCount,
                        accent: accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '0$pageCount',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    SizedBox(
                      width: 104,
                      child: currentPage == 0
                          ? const SizedBox.shrink()
                          : OutlinedButton(
                              onPressed: submitting ? null : () => onBack(),
                              child: const Text('Back'),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: submitting ? null : () => onNext(),
                        child: Text(isLastPage ? 'Start setup' : 'Next'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PageIndicators extends StatelessWidget {
  const _PageIndicators({
    required this.currentPage,
    required this.pageCount,
    required this.accent,
  });

  final int currentPage;
  final int pageCount;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List<Widget>.generate(pageCount, (index) {
        final isActive = index == currentPage;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: 4,
            margin: EdgeInsets.only(right: index == pageCount - 1 ? 0 : 6),
            decoration: BoxDecoration(
              color: isActive ? accent : Colors.white24,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}

class _OnboardingDetailRow extends StatelessWidget {
  const _OnboardingDetailRow({
    required this.color,
    required this.detail,
  });

  final Color color;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            detail,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.86),
                ),
          ),
        ),
      ],
    );
  }
}

class _GlassPillButton extends StatelessWidget {
  const _GlassPillButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.16),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white12),
          ),
          child: TextButton(
            onPressed: onPressed,
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

class _LightOrb extends StatelessWidget {
  const _LightOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[
              color,
              color.withOpacity(0),
            ],
          ),
        ),
      ),
    );
  }
}

class _LightBar extends StatelessWidget {
  const _LightBar({
    required this.width,
    required this.color,
  });

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: width,
        height: 2,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              color.withOpacity(0),
              color,
              color.withOpacity(0),
            ],
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 18,
              spreadRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShutterRings extends StatelessWidget {
  const _ShutterRings({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.2),
              ),
            ),
            Container(
              width: size * 0.7,
              height: size * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.7), width: 1),
              ),
            ),
            Container(
              width: size * 0.4,
              height: size * 0.4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.5), width: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.details,
    required this.backgroundColors,
    required this.accent,
    required this.secondaryAccent,
    required this.motifLabel,
  });

  final String eyebrow;
  final String title;
  final String body;
  final List<String> details;
  final List<Color> backgroundColors;
  final Color accent;
  final Color secondaryAccent;
  final String motifLabel;
}
