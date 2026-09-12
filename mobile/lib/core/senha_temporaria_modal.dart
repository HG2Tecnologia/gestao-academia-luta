import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'firebase_identity_service.dart';
import 'theme/context_ext.dart';

/// Confirma, chama o servidor e exibe a senha temporária — fluxo completo de
/// ponta a ponta usado tanto na tela de Equipe quanto na de Aluno.
Future<void> confirmarRedefinicaoSenha(
  BuildContext context, {
  required String academiaId,
  required String colecao,
  required String usuarioId,
  required String nome,
}) async {
  final l = context.l10n;
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: ctx.c.surfaceContainer,
      title: Text(
        l.resetPwDialogTitle(nome),
        style: TextStyle(color: ctx.c.onSurface),
      ),
      content: Text(
        l.resetPwDialogBody,
        style: TextStyle(color: ctx.c.onSurfaceVariant, fontSize: 13.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(
            l.commonCancel,
            style: TextStyle(color: ctx.c.onSurfaceVariant),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(backgroundColor: ctx.c.primary),
          child: Text(l.resetPwDialogConfirm),
        ),
      ],
    ),
  );
  if (confirmar != true || !context.mounted) return;
  await _executarSenhaTemporaria(
    context,
    academiaId: academiaId,
    colecao: colecao,
    usuarioId: usuarioId,
    nome: nome,
    motivo: 'redefinicao',
    erroPrefixo: (erro) => l.resetPwErrReset(erro),
  );
}

/// Gera a senha temporária de acesso ao app de um aluno recém-criado ou que
/// acabou de ganhar telefone/e-mail — sem diálogo de confirmação (não há
/// sessão a encerrar). Mostra o mesmo modal com a senha e as instruções.
/// Retorna `true` se a senha foi gerada e exibida.
Future<bool> provisionarAcessoApp(
  BuildContext context, {
  required String academiaId,
  required String colecao,
  required String usuarioId,
  required String nome,
  String motivo = 'provisao_criacao',
  bool confirmarSobrescrita = false,
  bool apenasVincular = false,
}) {
  final l = context.l10n;
  return _executarSenhaTemporaria(
    context,
    academiaId: academiaId,
    colecao: colecao,
    usuarioId: usuarioId,
    nome: nome,
    motivo: motivo,
    erroPrefixo: (erro) => l.resetPwErrProvision(erro),
    confirmarSobrescrita: confirmarSobrescrita,
    apenasVincular: apenasVincular,
  );
}

enum ResolucaoConflitoSenha { manterAtual, gerarNova }

Future<bool> _executarSenhaTemporaria(
  BuildContext context, {
  required String academiaId,
  required String colecao,
  required String usuarioId,
  required String nome,
  required String motivo,
  required String Function(String erro) erroPrefixo,
  bool confirmarSobrescrita = false,
  bool apenasVincular = false,
}) async {
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
      motivo: motivo,
      confirmarSobrescrita: confirmarSobrescrita,
      apenasVincular: apenasVincular,
    );
    navigator.pop(); // fecha o loading
    if (!context.mounted) return false;
    if (resultado.vinculadoSemSenha) {
      await mostrarVinculadoSemSenha(
        context,
        nome: resultado.nome.isNotEmpty ? resultado.nome : nome,
        loginHint: resultado.loginHint,
      );
      return true;
    }
    await mostrarSenhaTemporaria(
      context,
      nome: resultado.nome.isNotEmpty ? resultado.nome : nome,
      senha: resultado.senha,
      loginHint: resultado.loginHint,
    );
    return true;
  } on SenhaJaDefinidaException {
    navigator.pop(); // fecha o loading
    if (!context.mounted) return false;
    final escolha = await perguntarComoResolverConflitoSenha(
      context,
      nome: nome,
    );
    if (escolha == null || !context.mounted) return false;
    return _executarSenhaTemporaria(
      context,
      academiaId: academiaId,
      colecao: colecao,
      usuarioId: usuarioId,
      nome: nome,
      motivo: motivo,
      erroPrefixo: erroPrefixo,
      confirmarSobrescrita: escolha == ResolucaoConflitoSenha.gerarNova,
      apenasVincular: escolha == ResolucaoConflitoSenha.manterAtual,
    );
  } catch (e) {
    navigator.pop(); // fecha o loading
    messenger.showSnackBar(
      SnackBar(
        content: Text(erroPrefixo('$e')),
        backgroundColor: context.sem.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
    return false;
  }
}

/// Pergunta para a academia como resolver quando o telefone/e-mail cadastrado
/// já pertence a outra pessoa que já definiu a própria senha de acesso.
/// Usado tanto ANTES de criar um aluno (cancelar não deixa rastro nenhum)
/// quanto no provisionamento pós-cadastro/edição.
Future<ResolucaoConflitoSenha?> perguntarComoResolverConflitoSenha(
  BuildContext context, {
  required String nome,
}) {
  final l = context.l10n;
  return showDialog<ResolucaoConflitoSenha>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: ctx.c.surfaceContainer,
      title: Text(
        l.conflictDialogTitle,
        style: TextStyle(color: ctx.c.onSurface),
      ),
      content: Text(
        l.conflictDialogBody(nome),
        style: TextStyle(
          color: ctx.c.onSurfaceVariant,
          fontSize: 13.5,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(
            l.commonCancel,
            style: TextStyle(color: ctx.c.onSurfaceVariant),
          ),
        ),
        OutlinedButton(
          onPressed: () =>
              Navigator.of(ctx).pop(ResolucaoConflitoSenha.manterAtual),
          style: OutlinedButton.styleFrom(foregroundColor: ctx.c.onSurface),
          child: Text(l.conflictDialogKeepCurrent),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(ctx).pop(ResolucaoConflitoSenha.gerarNova),
          style: FilledButton.styleFrom(
            backgroundColor: ctx.c.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(l.conflictDialogGenerateNew),
        ),
      ],
    ),
  );
}

/// Mostra que o perfil passou a compartilhar a conta/senha já existente —
/// nenhuma senha nova foi gerada.
Future<void> mostrarVinculadoSemSenha(
  BuildContext context, {
  required String nome,
  String? loginHint,
}) {
  final l = context.l10n;
  final comoEntrar = (loginHint == null || loginHint.trim().isEmpty)
      ? l.tempPwLoginHintFallback
      : l.tempPwLoginHintWith(loginHint);
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: ctx.c.surfaceContainer,
      title: Text(
        l.linkedDialogTitle,
        style: TextStyle(color: ctx.c.onSurface),
      ),
      content: Text(
        l.linkedDialogBody(nome, comoEntrar),
        style: TextStyle(
          color: ctx.c.onSurfaceVariant,
          fontSize: 13.5,
          height: 1.4,
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(),
          style: FilledButton.styleFrom(backgroundColor: ctx.c.primary),
          child: Text(l.commonUnderstood),
        ),
      ],
    ),
  );
}

/// Mostra a senha temporária gerada pelo servidor. Ela também fica visível na
/// ficha do aluno (card "Acesso ao App") até ele entrar pela primeira vez e
/// definir a própria senha — depois disso some e resta só o botão de
/// "Redefinir senha".
Future<void> mostrarSenhaTemporaria(
  BuildContext context, {
  required String nome,
  required String senha,
  String? loginHint,
}) {
  final l = context.l10n;
  final comoEntrar = (loginHint == null || loginHint.trim().isEmpty)
      ? l.tempPwLoginHintFallback
      : l.tempPwLoginHintWith(loginHint);
  // Capturado ANTES de abrir o modal: depois que ele fecha, o contexto do
  // próprio bottom sheet deixa de existir, então o toast de "copiado" tem
  // que sair pelo Messenger da tela que chamou, não pelo `ctx` do modal.
  final messenger = ScaffoldMessenger.of(context);

  return showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    backgroundColor: context.c.surfaceContainer,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ctx.sem.warning.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.vpn_key_rounded,
                  color: ctx.sem.warning,
                  size: 22,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l.tempPwTitle(nome),
                style: TextStyle(
                  color: ctx.c.onSurface,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l.tempPwHint,
                style: TextStyle(
                  color: ctx.c.onSurfaceVariant,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 18,
                ),
                decoration: BoxDecoration(
                  color: ctx.c.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ctx.c.outline),
                ),
                child: Center(
                  child: SelectableText(
                    senha,
                    style: TextStyle(
                      color: ctx.c.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ctx.c.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ctx.c.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.tempPwExplainTitle(nome),
                      style: TextStyle(
                        color: ctx.c.onSurface,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _passo(ctx, '1', l.tempPwStep1),
                    _passo(ctx, '2', l.tempPwStep2(comoEntrar)),
                    _passo(ctx, '3', l.tempPwStep3),
                  ],
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
                            content: Text(l.tempPwCopied),
                            backgroundColor: ctx.sem.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ctx.c.onSurface,
                        side: BorderSide(color: ctx.c.outline),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: Text(l.tempPwCopy),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Share.share(
                        l.tempPwShareText(nome, comoEntrar, senha),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: ctx.c.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.ios_share_rounded, size: 18),
                      label: Text(l.tempPwShare),
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

/// Caixa que mostra a senha temporária ainda pendente na ficha de um aluno /
/// funcionário (o acesso foi provisionado mas a pessoa ainda não entrou pela
/// 1ª vez). Some do servidor quando ela define a própria senha.
class SenhaTemporariaBox extends StatelessWidget {
  final String senha;
  final String nome;
  const SenhaTemporariaBox({
    super.key,
    required this.senha,
    required this.nome,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.sem.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.sem.warning.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.vpn_key_rounded, color: context.sem.warning, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.tempPwBoxTitle,
                  style: TextStyle(
                    color: context.sem.warning,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: context.c.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.c.outline),
            ),
            child: Center(
              child: SelectableText(
                senha,
                style: TextStyle(
                  color: context.c.primary,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: senha));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l.tempPwCopied),
                        backgroundColor: context.sem.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.c.onSurface,
                    side: BorderSide(color: context.c.outline),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: Text(l.tempPwCopy),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      mostrarSenhaTemporaria(context, nome: nome, senha: senha),
                  style: FilledButton.styleFrom(
                    backgroundColor: context.c.primary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.ios_share_rounded, size: 16),
                  label: Text(l.tempPwBoxViewSend),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _passo(BuildContext context, String n, String texto) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 18,
        height: 18,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.c.primary.withValues(alpha: 0.16),
          shape: BoxShape.circle,
        ),
        child: Text(
          n,
          style: TextStyle(
            color: context.c.primary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          texto,
          style: TextStyle(
            color: context.c.onSurfaceVariant,
            fontSize: 12,
            height: 1.35,
          ),
        ),
      ),
    ],
  ),
);
