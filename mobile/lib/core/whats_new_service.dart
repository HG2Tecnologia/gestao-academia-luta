import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

/// Novidades da versão atual do app. Atualize esta lista a cada release que
/// tenha mudanças relevantes para o usuário — o modal só aparece uma vez por
/// versão (controlado por `_prefKey`, comparando com a versão já vista).
const List<String> kNovidadesVersaoAtual = [
  'Nova tela de entrada: escolha se você é aluno/responsável ou uma academia antes de fazer login, com atalhos mais claros para primeiro acesso e recuperação de senha.',
  'Gestores e secretaria agora podem redefinir a senha de qualquer aluno ou funcionário direto pelo app, gerando uma senha temporária seguida de troca obrigatória.',
  'Edição de graduações com histórico completo: corrija uma graduação lançada errada sem perder o registro anterior, com aviso automático se a correção gerar conflito com uma graduação posterior.',
  'Exclusão de turma agora é segura: a turma some das listas ativas e as matrículas são encerradas, mas alunos, presenças e o histórico continuam intactos.',
  'Financeiro: as mensalidades do mês são geradas automaticamente ao abrir a tela, sem precisar clicar em "Gerar cobranças", e já dá para navegar e receber pagamentos antecipados do próximo mês.',
];

abstract class WhatsNewService {
  static const _prefKey = 'whats_new_last_seen_version';

  static Future<void> checkAndShow(BuildContext context) async {
    if (kNovidadesVersaoAtual.isEmpty) return;
    try {
      final info = await PackageInfo.fromPlatform();
      final versaoAtual = info.version;
      final prefs = await SharedPreferences.getInstance();
      final ultimaVista = prefs.getString(_prefKey);
      if (ultimaVista == versaoAtual) return;

      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: kSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: kPrimary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Novidades da versão $versaoAtual',
                  style: TextStyle(
                    color: kText1,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in kNovidadesVersaoAtual)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: kSuccess,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              style: TextStyle(
                                color: kText2,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Entendi',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      );
      await prefs.setString(_prefKey, versaoAtual);
    } catch (_) {
      // Se falhar (ex: PackageInfo indisponível), não bloqueia o uso do app.
    }
  }
}
