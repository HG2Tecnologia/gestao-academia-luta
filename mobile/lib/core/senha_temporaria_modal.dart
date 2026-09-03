import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'constants.dart';
import 'firebase_identity_service.dart';

/// Confirma, chama o servidor e exibe a senha temporária — fluxo completo de
/// ponta a ponta usado tanto na tela de Equipe quanto na de Aluno.
Future<void> confirmarRedefinicaoSenha(
  BuildContext context, {
  required String academiaId,
  required String colecao,
  required String usuarioId,
  required String nome,
}) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: kSurface,
      title: Text('Redefinir senha de $nome?', style: TextStyle(color: kText1)),
      content: Text(
        'Uma nova senha temporária será gerada e a sessão atual dessa pessoa '
        'será encerrada. Ela precisará usar a senha temporária para entrar e '
        'trocar por uma senha definitiva.',
        style: TextStyle(color: kText2, fontSize: 13.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('Cancelar', style: TextStyle(color: kText2)),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(backgroundColor: kPrimary),
          child: const Text('Redefinir'),
        ),
      ],
    ),
  );
  if (confirmar != true || !context.mounted) return;

  // Usa sempre o Navigator raiz — showDialog também abre no raiz por padrão
  // (`useRootNavigator: true`). Se `Navigator.of(context)` (sem isso)
  // resolvesse um Navigator aninhado diferente, o pop() abaixo fecharia a
  // rota errada e o diálogo de loading ficava preso na tela pra sempre,
  // bloqueando toda interação por trás do próximo modal.
  final navigator = Navigator.of(context, rootNavigator: true);
  final messenger = ScaffoldMessenger.of(context);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final resultado = await firebaseIdentityService.adminResetPassword(
      academiaId: academiaId,
      colecao: colecao,
      usuarioId: usuarioId,
    );
    navigator.pop(); // fecha o loading
    if (!context.mounted) return;
    await mostrarSenhaTemporaria(
      context,
      nome: resultado.nome.isNotEmpty ? resultado.nome : nome,
      senha: resultado.senha,
    );
  } catch (e) {
    navigator.pop(); // fecha o loading
    messenger.showSnackBar(
      SnackBar(
        content: Text('Não foi possível redefinir a senha: $e'),
        backgroundColor: kDanger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Mostra a senha temporária gerada pelo servidor UMA ÚNICA VEZ — ela nunca
/// é persistida em texto claro (nem no Firestore, nem no app) e some da
/// memória assim que este modal é fechado. Copiar já encerra o modal e
/// confirma com um toast — não precisa de um botão "fechar" separado.
Future<void> mostrarSenhaTemporaria(
  BuildContext context, {
  required String nome,
  required String senha,
}) {
  // Capturado ANTES de abrir o modal: depois que ele fecha, o contexto do
  // próprio bottom sheet deixa de existir, então o toast de "copiado" tem
  // que sair pelo Messenger da tela que chamou, não pelo `ctx` do modal.
  final messenger = ScaffoldMessenger.of(context);

  return showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: kSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: kWarning.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.vpn_key_rounded, color: kWarning, size: 22),
            ),
            const SizedBox(height: 14),
            Text(
              'Senha temporária de $nome',
              style: TextStyle(
                color: kText1,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Esta senha só aparece agora. Copie ou compartilhe antes de fechar — '
              'depois disso não é possível vê-la de novo. Ela é obrigada a trocar '
              'por uma senha definitiva no próximo acesso.',
              style: TextStyle(color: kText2, fontSize: 12.5, height: 1.4),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorder),
              ),
              child: Center(
                child: SelectableText(
                  senha,
                  style: TextStyle(
                    color: kPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: senha));
                      // showModalBottomSheet abre no Navigator LOCAL por
                      // padrão (`useRootNavigator: false`) — diferente do
                      // showDialog do loading, que abre no raiz. Usar
                      // `rootNavigator: true` aqui fecharia a tela de trás
                      // em vez do próprio modal (mesma classe de bug do
                      // loading travado, só que invertida).
                      Navigator.of(ctx).pop();
                      messenger.showSnackBar(
                        SnackBar(
                          content: const Text('Senha copiada.'),
                          backgroundColor: kSuccess,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kText1,
                      side: BorderSide(color: kBorder),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copiar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Share.share(
                      'Sensei Manager — senha temporária de $nome: $senha\n'
                      'Troque por uma senha definitiva no primeiro acesso.',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: kPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.ios_share_rounded, size: 18),
                    label: const Text('Compartilhar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
