import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants.dart';

/// Formata como telefone brasileiro `(XX) XXXXX-XXXX` enquanto o texto for só
/// dígitos; some da frente quando detecta letra/@ (usuário digitando e-mail).
/// Usado em campos que aceitam telefone OU e-mail no mesmo input.
class SmartPhoneOrEmailInputFormatter extends TextInputFormatter {
  static final _onlyDigits = RegExp(r'\D');
  static final _hasLetter = RegExp(r'[a-zA-Z@]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue old,
    TextEditingValue next,
  ) {
    final text = next.text;
    if (text.isEmpty) return next;
    if (_hasLetter.hasMatch(text)) return next;

    final raw = text.replaceAll(_onlyDigits, '');
    final digits = raw.length > 11 ? raw.substring(0, 11) : raw;

    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 0) buf.write('(');
      if (i == 2) buf.write(') ');
      if (digits.length == 11 && i == 7) buf.write('-');
      if (digits.length <= 10 && i == 6) buf.write('-');
      buf.write(digits[i]);
    }

    final formatted = buf.toString();
    return next.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 11 ? digits.substring(0, 11) : digits;
    final buf = StringBuffer();
    for (int i = 0; i < limited.length; i++) {
      if (i == 3 || i == 6) buf.write('.');
      if (i == 9) buf.write('-');
      buf.write(limited[i]);
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Visual representation of a martial arts belt with optional degree stripes.
/// Displays a colored bar (belt color) + optional dark tip with white stripes (degrees).
class BeltBadge extends StatelessWidget {
  final Color cor;
  final Color corBarra;
  final bool temGraus;
  final int grau;
  final int maxGraus;
  final double height;
  final double minWidth;

  const BeltBadge({
    super.key,
    required this.cor,
    this.corBarra = const Color(0xFF000000),
    this.temGraus = false,
    this.grau = 0,
    this.maxGraus = 4,
    this.height = 16,
    this.minWidth = 48,
  });

  static Color fromHex(String hex) {
    final h = hex.replaceFirst('#', '').padLeft(6, '0');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
          borderRadius: BorderRadius.circular(3),
        ),
        child: SizedBox(
          height: height,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            // Ambas as seções (cor lisa + tarja de graus) ocupam a altura
            // total: sem isto a tarja encolhe para a altura dos risquinhos
            // e o lado direito fica mais fino que o esquerdo.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main belt color
              Container(width: minWidth, color: cor),
              // Tip with stripes (only if temGraus)
              if (temGraus)
                Container(
                  color: corBarra,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(maxGraus, (i) {
                      final earned = i < grau;
                      return Container(
                        width: 3,
                        height: height * 0.65,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          color: earned
                              ? Colors.white.withOpacity(0.9)
                              : Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ErroConexao extends StatelessWidget {
  final VoidCallback onRetry;
  final String? mensagem;

  const ErroConexao({super.key, required this.onRetry, this.mensagem});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: kDanger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded, color: kDanger, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              mensagem ?? 'Sem conexão',
              style: TextStyle(
                color: kText1,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Verifique sua conexão e tente novamente.',
              style: TextStyle(color: kText2, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
              style: OutlinedButton.styleFrom(
                foregroundColor: kPrimary,
                side: BorderSide(color: kPrimary.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ListaVazia extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String? subtitulo;

  const ListaVazia({
    super.key,
    required this.icon,
    required this.titulo,
    this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: kBorder, size: 64),
            const SizedBox(height: 16),
            Text(
              titulo,
              style: TextStyle(
                color: kText2,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitulo != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitulo!,
                style: TextStyle(color: kText2.withOpacity(0.6), fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
