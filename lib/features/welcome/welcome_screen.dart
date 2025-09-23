import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_providers.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.82);
  bool _isStarting = false;
  int _currentPage = 0;
  double _pageOffset = 0;

  @override
  void initState() {
    super.initState();
    _pageOffset = _pageController.initialPage.toDouble();
    _pageController.addListener(_handlePageOffset);
  }

  void _handlePageOffset() {
    final value =
        _pageController.page ?? _pageController.initialPage.toDouble();
    if (value != _pageOffset) {
      setState(() => _pageOffset = value);
    }
  }

  static const List<_WelcomeSlideData> _slides = [
    _WelcomeSlideData(
      imageAsset: 'assets/HectorNBB.png',
      cardTitle: 'Forge Mode',
      cardSubtitle: 'Rutinas de élite, resultados reales.',
      headlinePrefix: 'Bienvenido Coloso,',
      highlight: 'Never Be Broken',
      description:
          'Forja tu cuenta, responde el cuestionario inicial y te guiaremos paso a paso.',
      highlightColor: Color(0xFFFF1744),
      backgroundGradient: [Color(0xFF1C1C1C), Color(0xFF090909)],
      cardGradient: [Color(0xFFB71C1C), Color(0xFFD32F2F)],
      strokeColor: Color(0xCCFFFFFF),
      overlayShade: Color(0x88000000),
    ),
    _WelcomeSlideData(
      imageAsset: 'assets/MonochromeOnTransparent.png',
      cardTitle: 'Momentum Mode',
      cardSubtitle: 'Analíticas para monitorear cada progreso.',
      headlinePrefix: 'Tu progreso merece',
      highlight: 'precisión total',
      description:
          'Sincroniza tus métricas, descubre patrones y mantén el enfoque con reportes claros.',
      highlightColor: Color(0xFF00E5FF),
      backgroundGradient: [Color(0xFF131313), Color(0xFF050505)],
      cardGradient: [Color(0xFF263238), Color(0xFF37474F)],
      strokeColor: Color(0xB3FFFFFF),
      overlayShade: Color(0xAA000000),
      imageTint: Color(0xFFE0F7FA),
      imageBlendMode: BlendMode.srcIn,
    ),
    _WelcomeSlideData(
      imageAsset: 'assets/WhiteOnTransparent.png',
      cardTitle: 'Legacy Mode',
      cardSubtitle: 'Inspiración constante, disciplina diaria.',
      headlinePrefix: 'El camino es duro,',
      highlight: 'pero tú más',
      description:
          'Crea hábitos irrompibles, desbloquea retos épicos y comparte tu evolución con la tribu.',
      highlightColor: Color(0xFFFF80AB),
      backgroundGradient: [Color(0xFF180B1E), Color(0xFF0B040F)],
      cardGradient: [Color(0xFF8E24AA), Color(0xFFD81B60)],
      strokeColor: Color(0xB3FFFFFF),
      overlayShade: Color(0x99000000),
      imageTint: Colors.white,
      imageBlendMode: BlendMode.srcIn,
    ),
  ];

  @override
  void dispose() {
    _pageController.removeListener(_handlePageOffset);
    _pageController.dispose();
    super.dispose();
  }

  void _openAuth() {
    context.go('/auth');
  }

  Future<void> _startOnboarding() async {
    if (_isStarting) return;
    setState(() => _isStarting = true);

    try {
      final FirebaseAuth auth = ref.read(firebaseAuthProvider);
      final current = auth.currentUser;

      if (current != null && !current.isAnonymous) {
        await current.reload();
      }

      if (!mounted) return;
      context.go('/onboarding');
    } catch (_) {
      if (!mounted) return;
      _showError('No pudimos iniciar el cuestionario. Intenta de nuevo.');
    } finally {
      if (mounted) {
        setState(() => _isStarting = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent.shade200,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slide = _slides[_currentPage];
    final accentColor = _resolveAccentColor();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _WelcomeHero(
                controller: _pageController,
                slides: _slides,
                currentPage: _currentPage,
                pageOffset: _pageOffset,
                onPageChanged: (page) => setState(() => _currentPage = page),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 12, 32, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RichText(
                    text: TextSpan(
                      text: '${slide.headlinePrefix} ',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                      children: [
                        TextSpan(
                          text: slide.highlight,
                          style: TextStyle(color: accentColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    slide.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 0; i < _slides.length; i++) ...[
                        _PageDot(
                          active: i == _currentPage,
                          activeColor: accentColor,
                        ),
                        if (i != _slides.length - 1) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                  const SizedBox(height: 28),
                  OutlinedButton.icon(
                    onPressed: _openAuth,
                    icon: const Icon(Icons.lock_open_rounded),
                    label: const Text('INICIAR SESIÓN'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.7)),
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _startOnboarding,
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _isStarting
                          ? const SizedBox(
                              key: ValueKey('loading'),
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.bolt_rounded,
                              key: ValueKey('bolt'),
                            ),
                    ),
                    label: Text(
                      _isStarting ? 'CREANDO TU ESPACIO...' : 'EMPEZAR AHORA',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF1744),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 16,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _resolveAccentColor() {
    final clamped = _pageOffset.clamp(0, _slides.length - 1).toDouble();
    final lowerIndex = clamped.floor();
    final upperIndex = clamped.ceil();

    if (lowerIndex == upperIndex) {
      return _slides[lowerIndex].highlightColor;
    }

    final t = clamped - lowerIndex;
    final lowerColor = _slides[lowerIndex].highlightColor;
    final upperColor = _slides[upperIndex].highlightColor;

    return Color.lerp(lowerColor, upperColor, t) ?? lowerColor;
  }
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero({
    required this.controller,
    required this.slides,
    required this.currentPage,
    required this.pageOffset,
    required this.onPageChanged,
  });

  final PageController controller;
  final List<_WelcomeSlideData> slides;
  final int currentPage;
  final double pageOffset;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final backgroundGradient = _resolveGradient();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: backgroundGradient,
        ),
      ),
      child: PageView.builder(
        controller: controller,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        onPageChanged: onPageChanged,
        itemCount: slides.length,
        itemBuilder: (context, index) {
          final data = slides[index];
          final isActive = index == currentPage;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: _HeroSlideCard(data: data, isActive: isActive),
          );
        },
      ),
    );
  }

  List<Color> _resolveGradient() {
    final clamped = pageOffset.clamp(0, slides.length - 1).toDouble();
    final lowerIndex = clamped.floor();
    final upperIndex = clamped.ceil();

    if (lowerIndex == upperIndex) {
      return slides[lowerIndex].backgroundGradient;
    }

    final t = clamped - lowerIndex;
    final lower = slides[lowerIndex].backgroundGradient;
    final upper = slides[upperIndex].backgroundGradient;

    final length = lower.length < upper.length ? lower.length : upper.length;

    return List<Color>.generate(
      length,
      (i) => Color.lerp(lower[i], upper[i], t) ?? lower[i],
    );
  }
}

class _HeroSlideCard extends StatelessWidget {
  const _HeroSlideCard({required this.data, required this.isActive});

  final _WelcomeSlideData data;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isActive ? 1.0 : 0.93,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 36,
                bottom: 36,
                left: -48,
                child: _SideGlow(color: data.highlightColor),
              ),
              Positioned(
                top: 36,
                bottom: 36,
                right: -48,
                child: _SideGlow(color: data.highlightColor, mirrored: true),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: data.highlightColor.withOpacity(0.25),
                        blurRadius: isActive ? 28 : 16,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: data.cardGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Image.asset(
                              data.imageAsset,
                              fit: BoxFit.contain,
                              color: data.imageTint,
                              colorBlendMode: data.imageBlendMode,
                            ),
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, data.overlayShade],
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data.cardTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  data.cardSubtitle,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 15,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: data.strokeColor.withOpacity(0.25),
                                width: 1.2,
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideGlow extends StatelessWidget {
  const _SideGlow({required this.color, this.mirrored = false});

  final Color color;
  final bool mirrored;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Transform.rotate(
        angle: mirrored ? 0.32 : -0.32,
        child: Container(
          width: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(120),
            gradient: RadialGradient(
              radius: 0.85,
              center: mirrored ? Alignment.centerLeft : Alignment.centerRight,
              colors: [
                color.withOpacity(0.38),
                color.withOpacity(0.14),
                Colors.transparent,
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.18),
                blurRadius: 56,
                spreadRadius: 6,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageDot extends StatelessWidget {
  const _PageDot({required this.active, required this.activeColor});

  final bool active;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: active ? 12 : 8,
      height: active ? 12 : 8,
      decoration: BoxDecoration(
        color: active ? activeColor : Colors.white.withOpacity(0.4),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _WelcomeSlideData {
  const _WelcomeSlideData({
    required this.imageAsset,
    required this.cardTitle,
    required this.cardSubtitle,
    required this.headlinePrefix,
    required this.highlight,
    required this.description,
    required this.highlightColor,
    required this.backgroundGradient,
    required this.cardGradient,
    required this.strokeColor,
    required this.overlayShade,
    this.imageTint,
    this.imageBlendMode,
  });

  final String imageAsset;
  final String cardTitle;
  final String cardSubtitle;
  final String headlinePrefix;
  final String highlight;
  final String description;
  final Color highlightColor;
  final List<Color> backgroundGradient;
  final List<Color> cardGradient;
  final Color strokeColor;
  final Color overlayShade;
  final Color? imageTint;
  final BlendMode? imageBlendMode;
}
