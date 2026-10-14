import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _logoScaleAnimation;
  late final Animation<double> _logoFadeAnimation;
  late final Animation<double> _textFadeAnimation;
  late final Animation<double> _roadAnimation;

  Timer? _safetyTimeout;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoFadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _roadAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeInOut),
    );

    _textFadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );

    _animController.forward();
    _startBootstrapSequence();
  }

  Future<void> _startBootstrapSequence() async {
    // Part 8: Minimum display duration (1200ms) + real bootstrap readiness
    final minDisplayFuture = Future.delayed(const Duration(milliseconds: 1200));

    // Watch auth state readiness
    await minDisplayFuture;

    // Safety timeout in case auth stream takes long
    _safetyTimeout = Timer(const Duration(milliseconds: 800), () {
      _checkAndNavigate();
    });

    _checkAndNavigate();
  }

  void _checkAndNavigate() {
    if (!mounted || _hasNavigated) return;

    final authState = ref.read(authProvider);

    // If still initial/loading and we haven't hit timeout, wait for listener
    if (authState is AuthInitial || authState is AuthLoading) {
      return;
    }

    _hasNavigated = true;
    _safetyTimeout?.cancel();

    if (authState is Authenticated) {
      final user = authState.user;
      if (user.role == 'passenger') {
        context.go('/dashboard');
      } else if (user.role == 'driver') {
        if (user.status == 'approved') {
          context.go('/driver-dashboard');
        } else if (user.status == 'pending_review') {
          context.go('/pending-approval');
        } else if (user.status == 'need_modification') {
          context.go('/need-modification');
        } else {
          context.go('/driver-dashboard');
        }
      } else if (user.role == 'company') {
        context.go('/company-dashboard');
      } else if (user.role == 'admin') {
        context.go('/admin/dashboard');
      } else {
        context.go('/dashboard');
      }
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _safetyTimeout?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth state changes if auth resolved after min duration
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (!_hasNavigated && (next is! AuthInitial && next is! AuthLoading)) {
        _checkAndNavigate();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0B1F3A),
      body: Center(
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Scaled & Faded Logo Container
                FadeTransition(
                  opacity: _logoFadeAnimation,
                  child: ScaleTransition(
                    scale: _logoScaleAnimation,
                    child: Container(
                      width: 108,
                      height: 108,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFF5A623).withValues(alpha: 0.6),
                          width: 2.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF5A623).withValues(alpha: 0.25),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.directions_car_filled_rounded,
                          size: 58,
                          color: Color(0xFFF5A623),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Animated Road Line
                FadeTransition(
                  opacity: _roadAnimation,
                  child: SizedBox(
                    width: 140,
                    height: 4,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: _roadAnimation.value,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFF5A623),
                                  Color(0xFFFFD54F),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF5A623).withValues(alpha: 0.5),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // Wordmark Reveal & Tagline
                FadeTransition(
                  opacity: _textFadeAnimation,
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'رحّال',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF5A623),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'رحلتك تبدأ من هنا',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
