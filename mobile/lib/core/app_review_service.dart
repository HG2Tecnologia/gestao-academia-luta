import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/context_ext.dart';

/// Pedido de avaliação do app, de tempos em tempos, até o usuário avaliar.
///
/// Regras (todas locais, em SharedPreferences):
/// - só depois de [_minDiasInstalado] dias e [_minAberturas] aberturas;
/// - no máximo [_maxTentativas] pedidos, com [_intervaloDias] dias entre eles;
/// - "Sim" → avaliação nativa da loja e nunca mais pergunta;
/// - "Não" → campo de feedback privado (vai para a equipe, não para a loja)
///   e nunca mais pergunta;
/// - "Agora não" → pergunta de novo depois do intervalo.
abstract final class AppReviewService {
  static const _minDiasInstalado = 14;
  static const _minAberturas = 5;
  static const _maxTentativas = 3;
  static const _intervaloDias = 30;

  /// Só para testar: `flutter build apk --dart-define=REVIEW_TEST=true` faz o
  /// pedido aparecer em toda abertura, ignorando prazos, limites e o "já
  /// avaliou". Fora disso (builds normais) fica sempre desligado.
  static const _modoTeste = bool.fromEnvironment('REVIEW_TEST');

  static const _kPrimeiraAbertura = 'review_first_seen_ms';
  static const _kAberturas = 'review_open_count';
  static const _kUltimoPedido = 'review_last_prompt_ms';
  static const _kTentativas = 'review_prompt_count';
  static const _kConcluido = 'review_done';

  /// Chamado no `initState` dos shells: conta a abertura e, se for a hora,
  /// mostra o pedido. Nunca lança nem bloqueia o uso do app.
  static Future<void> registrarAberturaEPerguntar(
    BuildContext context, {
    required String papel,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final agora = DateTime.now();
      if (!prefs.containsKey(_kPrimeiraAbertura)) {
        await prefs.setInt(_kPrimeiraAbertura, agora.millisecondsSinceEpoch);
      }
      final aberturas = (prefs.getInt(_kAberturas) ?? 0) + 1;
      await prefs.setInt(_kAberturas, aberturas);

      final ultimo = prefs.getInt(_kUltimoPedido);
      if (!_modoTeste &&
          !deveSolicitar(
        agora: agora,
        primeiraAbertura: DateTime.fromMillisecondsSinceEpoch(
          prefs.getInt(_kPrimeiraAbertura) ?? agora.millisecondsSinceEpoch,
        ),
        aberturas: aberturas,
        tentativas: prefs.getInt(_kTentativas) ?? 0,
        ultimoPedido: ultimo == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(ultimo),
        concluido: prefs.getBool(_kConcluido) ?? false,
      )) {
        return;
      }

      // Espera o app assentar (e o modal "Novidades" fechar, se houver).
      await Future<void>.delayed(Duration(seconds: _modoTeste ? 3 : 6));
      if (!context.mounted) return;
      if (ModalRoute.of(context)?.isCurrent != true) return;

      await prefs.setInt(_kUltimoPedido, DateTime.now().millisecondsSinceEpoch);
      await prefs.setInt(_kTentativas, (prefs.getInt(_kTentativas) ?? 0) + 1);
      if (!context.mounted) return;

      final resposta = await showModalBottomSheet<_Resposta>(
        context: context,
        backgroundColor: context.c.surfaceContainer,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => const _PedidoAvaliacaoSheet(),
      );

      switch (resposta) {
        case _Resposta.sim:
          await prefs.setBool(_kConcluido, true);
          await _abrirAvaliacaoDaLoja();
        case _Resposta.nao:
          await prefs.setBool(_kConcluido, true);
          if (!context.mounted) return;
          await _pedirFeedback(context, papel: papel);
        case _Resposta.agoraNao:
        case null:
          break;
      }
    } catch (_) {
      // Prefs/plugin indisponível — nunca atrapalha o uso do app.
    }
  }

  /// Regra pura (testável) de quando o pedido deve aparecer.
  static bool deveSolicitar({
    required DateTime agora,
    required DateTime primeiraAbertura,
    required int aberturas,
    required int tentativas,
    required DateTime? ultimoPedido,
    required bool concluido,
  }) {
    if (concluido) return false;
    if (tentativas >= _maxTentativas) return false;
    if (aberturas < _minAberturas) return false;
    if (agora.difference(primeiraAbertura).inDays < _minDiasInstalado) {
      return false;
    }
    if (ultimoPedido != null &&
        agora.difference(ultimoPedido).inDays < _intervaloDias) {
      return false;
    }
    return true;
  }

  static Future<void> _abrirAvaliacaoDaLoja() async {
    final review = InAppReview.instance;
    if (await review.isAvailable()) {
      await review.requestReview();
    } else {
      await review.openStoreListing();
    }
  }

  static Future<void> _pedirFeedback(
    BuildContext context, {
    required String papel,
  }) async {
    final mensagem = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.c.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _FeedbackSheet(),
    );
    if (mensagem == null || mensagem.trim().length < 3) return;
    try {
      final info = await PackageInfo.fromPlatform();
      await FirebaseFunctions.instance
          .httpsCallable('registrarFeedbackApp')
          .call({
            'mensagem': mensagem.trim(),
            'papel': papel,
            'versao': '${info.version}+${info.buildNumber}',
            'plataforma': Platform.isIOS ? 'ios' : 'android',
          });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.reviewFeedbackThanks)),
      );
    } catch (_) {
      // Feedback é "melhor esforço"; falha de rede não deve incomodar.
    }
  }
}

enum _Resposta { sim, nao, agoraNao }

class _PedidoAvaliacaoSheet extends StatelessWidget {
  const _PedidoAvaliacaoSheet();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_rounded, color: context.c.primary, size: 36),
            const SizedBox(height: 12),
            Text(
              l.reviewAskTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.c.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.reviewAskSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.c.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _Resposta.sim),
                child: Text(l.reviewAskYes),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, _Resposta.nao),
                child: Text(l.reviewAskNo),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, _Resposta.agoraNao),
              child: Text(l.reviewAskLater),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackSheet extends StatefulWidget {
  const _FeedbackSheet();

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.reviewFeedbackTitle,
                style: TextStyle(
                  color: context.c.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.reviewFeedbackSubtitle,
                style: TextStyle(
                  color: context.c.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ctrl,
                autofocus: true,
                maxLines: 4,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(hintText: l.reviewFeedbackHint),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _ctrl.text),
                  child: Text(l.reviewFeedbackSend),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
