import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants.dart';
import 'theme/context_ext.dart';

/// Explica o recurso de "graus coloridos" em 3 passos curtos — chamado
/// automaticamente ao ligar o switch em Configurações, e reaberto a
/// qualquer momento pelo "?" em Configurações e na tela de Faixas.
Future<void> mostrarAjudaGrausColoridos(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => const _AjudaGrausColoridosDialog(),
  );
}

class _AjudaGrausColoridosDialog extends StatefulWidget {
  const _AjudaGrausColoridosDialog();

  @override
  State<_AjudaGrausColoridosDialog> createState() =>
      _AjudaGrausColoridosDialogState();
}

class _AjudaGrausColoridosDialogState
    extends State<_AjudaGrausColoridosDialog> {
  final _controller = PageController();
  int _pagina = 0;

  static const _totalPaginas = 3;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _avancar() {
    if (_pagina == _totalPaginas - 1) {
      Navigator.pop(context);
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _voltar() {
    _controller.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      backgroundColor: context.c.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      content: SizedBox(
        width: 340,
        height: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _pagina = i),
                children: [
                  _PassoAjuda(
                    icon: Icons.palette_rounded,
                    titulo: l.grauColoridoStep1Title,
                    corpo: l.grauColoridoStep1Body,
                  ),
                  _PassoAjuda(
                    icon: Icons.stairs_rounded,
                    titulo: l.grauColoridoStep2Title,
                    corpo: l.grauColoridoStep2Body,
                    exemplo: _ExemploSequencia(),
                  ),
                  _PassoAjuda(
                    icon: Icons.settings_rounded,
                    titulo: l.grauColoridoStep3Title,
                    corpo: l.grauColoridoStep3Body,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_totalPaginas, (i) {
                final ativo = i == _pagina;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: ativo ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: ativo ? context.c.primary : context.c.outline,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actions: [
        if (_pagina > 0)
          TextButton(onPressed: _voltar, child: Text(l.commonBack)),
        Expanded(
          child: ElevatedButton(
            onPressed: _avancar,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.c.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _pagina == _totalPaginas - 1 ? l.commonUnderstood : l.commonNext,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

class _PassoAjuda extends StatelessWidget {
  const _PassoAjuda({
    required this.icon,
    required this.titulo,
    required this.corpo,
    this.exemplo,
  });

  final IconData icon;
  final String titulo;
  final String corpo;
  final Widget? exemplo;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: context.c.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: context.c.primary, size: 26),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.c.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            corpo,
            style: TextStyle(
              color: context.c.onSurfaceVariant,
              height: 1.5,
              fontSize: 13.5,
            ),
          ),
          if (exemplo != null) ...[
            const SizedBox(height: 14),
            exemplo!,
          ],
        ],
      ),
    );
  }
}

/// Mini-exemplo visual fixo: 12 graus em 3 blocos de 4 (branco/vermelho/
/// amarelo), com os rótulos "1º-4º", "5º-8º", "9º-12º" embaixo de cada
/// bloco — deixa a ideia de "sequência, nunca sobreposição" visível sem
/// depender de texto.
class _ExemploSequencia extends StatelessWidget {
  const _ExemploSequencia();

  @override
  Widget build(BuildContext context) {
    Widget bloco(Color cor, String rotulo) {
      return Expanded(
        child: Column(
          children: [
            Container(
              height: 18,
              decoration: BoxDecoration(
                color: cor,
                border: Border.all(color: Colors.black26),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              rotulo,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: context.c.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        bloco(const Color(0xFFFFFFFF), '1º-4º'),
        const SizedBox(width: 2),
        bloco(const Color(0xFFFF0000), '5º-8º'),
        const SizedBox(width: 2),
        bloco(const Color(0xFFFFD500), '9º-12º'),
      ],
    );
  }
}

/// Botão "?" pequeno, pra reabrir a ajuda de graus coloridos a qualquer
/// momento (Configurações e Faixas).
class AjudaGrausColoridosButton extends StatelessWidget {
  const AjudaGrausColoridosButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => mostrarAjudaGrausColoridos(context),
      icon: Icon(
        Icons.help_outline_rounded,
        size: 20,
        color: context.c.onSurfaceVariant,
      ),
      tooltip: context.l10n.grauColoridoHelpTitle,
      visualDensity: VisualDensity.compact,
    );
  }
}

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

  /// Cor individual de cada marcador de grau (índice 0 = 1º grau), pro
  /// recurso opcional de "graus coloridos". `null` ou lista vazia mantém o
  /// visual de sempre (marcador branco/apagado, cor única da ponteira).
  final List<Color>? grauCores;

  const BeltBadge({
    super.key,
    required this.cor,
    this.corBarra = const Color(0xFF000000),
    this.temGraus = false,
    this.grau = 0,
    this.maxGraus = 4,
    this.height = 16,
    this.minWidth = 48,
    this.grauCores,
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
                      final corDoGrau = (grauCores != null && i < grauCores!.length)
                          ? grauCores![i]
                          : null;
                      return Container(
                        width: 3,
                        height: height * 0.65,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          color: earned
                              ? (corDoGrau ?? Colors.white).withOpacity(
                                  corDoGrau != null ? 1.0 : 0.9,
                                )
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
