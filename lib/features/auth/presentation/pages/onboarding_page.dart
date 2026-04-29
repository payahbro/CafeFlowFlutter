import 'dart:async';

import 'package:cafe/features/auth/presentation/pages/login_page.dart';
import 'package:cafe/features/auth/presentation/pages/register_page.dart';
import 'package:cafe/shared/services/session_controller.dart';
import 'package:flutter/material.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.sessionController});

  final SessionController sessionController;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const Duration _autoSlideDuration = Duration(seconds: 4);
  static const int _virtualInitialPage = 1000;

  late final PageController _pageController;
  Timer? _timer;
  int _virtualPage = _virtualInitialPage;
  int _activeIndex = 0;
  bool _isUserDragging = false;

  final List<_OnboardingSlide> _slides = const [
    _OnboardingSlide(
      title: 'Kopi Terbaik, Hanya Untukmu',
      subtitle:
          'Temukan minuman favoritmu dari ratusan pilihan menu autentik dari KafeKu.',
    ),
    _OnboardingSlide(
      title: 'Pesan Tanpa Antri',
      subtitle:
          'Pilih menu, bayar, dan tinggal ambil. Semudah itu tanpa drama, tanpa antre panjang bersama KafeKu.',
    ),
    _OnboardingSlide(
      title: 'Semua Ada di Genggamanmu',
      subtitle:
          'Dari espresso hingga snack favorit, semuanya bisa kamu order kapan saja lewat KafeKu.',
    ),
    _OnboardingSlide(
      title: 'Bayar Sesukamu',
      subtitle:
          'Cash, kartu, GoPay, OVO, DANA, ShopeePay. Pilih cara bayar yang paling nyaman buatmu di KafeKu.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _virtualInitialPage);
    _activeIndex = _virtualInitialPage % _slides.length;
    _startAutoSlide();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final c = _clamp;

            final cardRadius = c(w * 0.08, 24, 36);
            final horizontalPadding = c(w * 0.07, 20, 32);
            final verticalPadding = c(h * 0.032, 18, 28);
            final bottomPadding = c(h * 0.04, 20, 32);
            final titleSize = c(w * 0.058, 20, 28);
            final subtitleSize = c(w * 0.035, 12, 16);
            final textGap = c(h * 0.01, 8, 12);
            final afterTextGap = c(h * 0.02, 14, 20);
            final buttonHeight = c(h * 0.065, 44, 56);
            final buttonRadius = c(w * 0.08, 20, 28);
            final buttonTextSize = c(w * 0.045, 14, 16);
            final buttonGap = c(h * 0.012, 8, 12);
            final dotsGap = c(h * 0.02, 12, 18);
            final dotHeight = c(w * 0.018, 6, 8);
            final dotActiveWidth = dotHeight * 2.2;
            final dotSpacing = dotHeight * 1.2;
            final dotBorderWidth = c(w * 0.003, 1, 1.4);
            final textAreaHeight = c(h * 0.18, 110, 170);

            return Stack(
              children: [
                const Positioned.fill(
                  child: Image(
                    image: NetworkImage(
                      'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=1400&q=80',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                const Positioned.fill(child: _VignetteOverlay()),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: _UiTokens.cardGradient,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(cardRadius),
                        topRight: Radius.circular(cardRadius),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      left: false,
                      right: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          verticalPadding,
                          horizontalPadding,
                          bottomPadding,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: textAreaHeight,
                              child: NotificationListener<ScrollNotification>(
                                onNotification: _handleScrollNotification,
                                child: PageView.builder(
                                  controller: _pageController,
                                  onPageChanged: (value) {
                                    setState(() {
                                      _virtualPage = value;
                                      _activeIndex = value % _slides.length;
                                    });
                                  },
                                  itemBuilder: (context, index) {
                                    final slide =
                                        _slides[index % _slides.length];
                                    return Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          slide.title,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: _UiTokens.titleColor,
                                            fontWeight: FontWeight.w800,
                                            fontSize: titleSize,
                                          ),
                                        ),
                                        SizedBox(height: textGap),
                                        Text(
                                          slide.subtitle,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: _UiTokens.subtitleColor,
                                            fontWeight: FontWeight.w500,
                                            height: 1.45,
                                            fontSize: subtitleSize,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: afterTextGap),
                            SizedBox(
                              height: buttonHeight,
                              width: double.infinity,
                              child: _GradientButton(
                                label: 'Login',
                                radius: buttonRadius,
                                textStyle: TextStyle(
                                  color: Colors.white,
                                  fontSize: buttonTextSize,
                                  fontWeight: FontWeight.w700,
                                ),
                                onTap: _openLogin,
                              ),
                            ),
                            SizedBox(height: buttonGap),
                            SizedBox(
                              height: buttonHeight,
                              width: double.infinity,
                              child: _OutlineButton(
                                label: 'Register',
                                radius: buttonRadius,
                                textStyle: TextStyle(
                                  color: _UiTokens.buttonOrange,
                                  fontSize: buttonTextSize,
                                  fontWeight: FontWeight.w700,
                                ),
                                onTap: _openRegister,
                              ),
                            ),
                            SizedBox(height: dotsGap),
                            _DotsIndicator(
                              count: _slides.length,
                              activeIndex: _activeIndex,
                              activeColor: _UiTokens.dotActive,
                              inactiveBorderColor: _UiTokens.dotInactiveBorder,
                              height: dotHeight,
                              activeWidth: dotActiveWidth,
                              spacing: dotSpacing,
                              borderWidth: dotBorderWidth,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _isUserDragging = true;
    } else if (notification is ScrollEndNotification) {
      _isUserDragging = false;
    }

    return false;
  }

  void _startAutoSlide() {
    _timer?.cancel();
    _timer = Timer.periodic(_autoSlideDuration, (_) {
      if (!mounted) return;
      if (!_pageController.hasClients) return;
      if (_isUserDragging) return;

      final nextPage = _virtualPage + 1;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _openLogin() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LoginPage(sessionController: widget.sessionController),
      ),
    );
  }

  void _openRegister() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            RegisterPage(sessionController: widget.sessionController),
      ),
    );
  }

  double _clamp(double value, double min, double max) {
    return value.clamp(min, max).toDouble();
  }
}

class _VignetteOverlay extends StatelessWidget {
  const _VignetteOverlay();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.35)],
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.onTap,
    required this.radius,
    required this.textStyle,
  });

  final String label;
  final VoidCallback onTap;
  final double radius;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          decoration: BoxDecoration(
            gradient: _UiTokens.buttonGradient,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Center(child: Text(label, style: textStyle)),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.label,
    required this.onTap,
    required this.radius,
    required this.textStyle,
  });

  final String label;
  final VoidCallback onTap;
  final double radius;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: _UiTokens.buttonOrange, width: 1.2),
          ),
          child: Center(child: Text(label, style: textStyle)),
        ),
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({
    required this.count,
    required this.activeIndex,
    required this.activeColor,
    required this.inactiveBorderColor,
    required this.height,
    required this.activeWidth,
    required this.spacing,
    required this.borderWidth,
  });

  final int count;
  final int activeIndex;
  final Color activeColor;
  final Color inactiveBorderColor;
  final double height;
  final double activeWidth;
  final double spacing;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return Padding(
          padding: EdgeInsets.only(right: index == count - 1 ? 0 : spacing),
          child: Container(
            width: isActive ? activeWidth : height,
            height: height,
            decoration: BoxDecoration(
              color: isActive ? activeColor : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              border: isActive
                  ? null
                  : Border.all(color: inactiveBorderColor, width: borderWidth),
            ),
          ),
        );
      }),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}

class _UiTokens {
  const _UiTokens._();

  static const Color titleColor = Color(0xFF1F1A14);
  static const Color subtitleColor = Color(0xFF3B342D);

  static const Color dotActive = Color(0xFFE87B35);
  static const Color dotInactiveBorder = Color(0xFFB8B0A8);

  static const Color buttonOrange = Color(0xFFE87B35);

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE87B35), Color(0xFFFDF3E7)],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFE87B35), Color(0xFFF2A351)],
  );
}
