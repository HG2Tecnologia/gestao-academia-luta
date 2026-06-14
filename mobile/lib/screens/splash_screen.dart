import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/auth_storage.dart';
import '../core/constants.dart';
import '../core/paywall_modal.dart';
import '../core/plan_service.dart';
import '../core/version_check_service.dart';

const _letters = ['S', 'E', 'N', 'S', 'E', 'I'];

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final AnimationController _beltCtrl;
  late final AnimationController _textCtrl;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _beltWidth;
  late final Animation<double> _subtitleOpacity;

  // Uma animação de escala + opacidade por letra
  late final List<Animation<double>> _letterOpacity;
  late final List<Animation<double>> _letterScale;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _beltCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _logoScale = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _beltWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _beltCtrl, curve: Curves.easeInOut),
    );
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _beltCtrl,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    // Cada letra: stagger de 0.11, duração 0.30 cada
    // Letra i: [i*0.11, i*0.11 + 0.30] — última letra: [0.66, 0.96]
    _letterOpacity = List.generate(_letters.length, (i) {
      final start = i * 0.11;
      final end = (start + 0.30).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _textCtrl,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    // Efeito de golpe: escala de 1.45 → 1.0 (punch-in)
    _letterScale = List.generate(_letters.length, (i) {
      final start = i * 0.11;
      final end = (start + 0.25).clamp(0.0, 1.0);
      return Tween<double>(begin: 1.45, end: 1.0).animate(
        CurvedAnimation(
          parent: _textCtrl,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 150));
    await _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 80));
    // Belt e letras iniciam juntos
    _beltCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 120));
    await _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 900));
    await _redirect();
  }

  Future<void> _redirect() async {
    if (!mounted) return;
    await VersionCheckService.check(context);
    if (!mounted) return;
    final user = await AuthStorage.getUser();
    if (!mounted) return;
    if (user != null && (user.perfil == 'Admin' || user.perfil == 'Secretaria')) {
      await PlanService.instance.load();
      if (mounted && PlanService.instance.showAds) {
        await mostrarPaywall(context);
      }
    }
    if (!mounted) return;
    switch (user?.perfil) {
      case 'Admin':
      case 'Secretaria':
        context.go('/admin/dashboard');
      case 'Professor':
        context.go('/professor/turmas');
      case 'Aluno':
        context.go('/aluno/perfil');
      default:
        context.go('/login');
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _beltCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo animado
            ScaleTransition(
              scale: _logoScale,
              child: FadeTransition(
                opacity: _logoOpacity,
                child: Image.asset(
                  'assets/logo_app.png',
                  width: 88,
                  height: 88,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Faixa preta com tarja vermelha
            AnimatedBuilder(
              animation: _beltWidth,
              builder: (context, child) {
                return ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: _beltWidth.value,
                    child: child,
                  ),
                );
              },
              child: _BeltDivider(),
            ),

            const SizedBox(height: 22),

            // TATAKAI — letra por letra com efeito de golpe
            AnimatedBuilder(
              animation: _textCtrl,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_letters.length, (i) {
                    return Transform.scale(
                      scale: _letterScale[i].value,
                      child: Opacity(
                        opacity: _letterOpacity[i].value,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.5),
                          child: Text(
                            _letters[i],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),

            const SizedBox(height: 8),

            FadeTransition(
              opacity: _subtitleOpacity,
              child: Text(
                'Gestão inteligente para academia de lutas',
                style: TextStyle(
                  color: kText2,
                  fontSize: 12,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Belt divider ─────────────────────────────────────────────────────────────

class _BeltDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 10,
      child: CustomPaint(painter: _BeltPainter()),
    );
  }
}

class _BeltPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Faixa preta (referência BJJ faixa preta)
    final beltPaint = Paint()..color = const Color(0xFF111111);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(4),
      ),
      beltPaint,
    );

    // Borda sutil para profundidade
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(4),
      ),
      borderPaint,
    );

    // Tarja dourada na ponta
    final tipPaint = Paint()..color = const Color(0xFFC9A020);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - 38, 0, 38, size.height),
        const Radius.circular(4),
      ),
      tipPaint,
    );

    // Costura central
    final seamPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width - 38, size.height / 2),
      seamPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
