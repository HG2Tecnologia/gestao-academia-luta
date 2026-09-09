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
  await _executarSenhaTemporaria(
    context,
    academiaId: academiaId,
    colecao: colecao,
    usuarioId: usuarioId,
    nome: nome,
    motivo: 'redefinicao',
    erroPrefixo: 'Não foi possível redefinir a senha',
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
}) {
  return _executarSenhaTemporaria(
    context,
    academiaId: academiaId,
    colecao: colecao,
    usuarioId: usuarioId,
    nome: nome,
    motivo: motivo,
    erroPrefixo: 'Não foi possível gerar a senha de acesso',
  );
}

Future<bool> _executarSenhaTemporaria(
  BuildContext context, {
  required String academiaId,
  required String colecao,
  required String usuarioId,
  required String nome,
  required String motivo,
  required String erroPrefixo,
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
    );
    navigator.pop(); // fecha o loading
    if (!context.mounted) return false;
    await mostrarSenhaTemporaria(
      context,
      nome: resultado.nome.isNotEmpty ? resultado.nome : nome,
      senha: resultado.senha,
      loginHint: resultado.loginHint,
    );
    return true;
  } catch (e) {
    navigator.pop(); // fecha o loading
    messenger.showSnackBar(
      SnackBar(
        content: Text('$erroPrefixo: $e'),
        backgroundColor: kDanger,
        behavior: SnackBarBehavior.floating,
      ),
    );
    return false;
  }
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
  final comoEntrar = (loginHint == null || loginHint.trim().isEmpty)
      ? 'o telefone ou e-mail cadastrado'
      : 'o $loginHint';
  // Capturado ANTES de abrir o modal: depois que ele fecha, o contexto do
  // próprio bottom sheet deixa de existir, então o toast de "copiado" tem
  // que sair pelo Messenger da tela que chamou, não pelo `ctx` do modal.
  final messenger = ScaffoldMessenger.of(context);

  return showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    backgroundColor: kSurface,
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
                'Copie ou compartilhe agora. Você também vê esta senha na ficha '
                'do aluno (Acesso ao App) até ele entrar pela primeira vez.',
                style: TextStyle(color: kText2, fontSize: 12.5, height: 1.4),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 18,
                ),
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
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explique para $nome:',
                      style: TextStyle(
                        color: kText1,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _passo(
                      '1',
                      'Abrir o app e tocar em "Sou aluno ou responsável".',
                    ),
                    _passo('2', 'Digitar $comoEntrar + esta senha temporária.'),
                    _passo(
                      '3',
                      'O app pede para criar a senha definitiva — pronto, sem "primeiro acesso".',
                    ),
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
                        'Sensei Manager — acesso de $nome\n'
                        'Entre no app com $comoEntrar e a senha temporária: $senha\n'
                        'O app vai pedir para você criar a sua senha definitiva.',
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kWarning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kWarning.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.vpn_key_rounded, color: kWarning, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Senha temporária — ainda não entrou pela 1ª vez',
                  style: TextStyle(
                    color: kWarning,
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
              color: kBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kBorder),
            ),
            child: Center(
              child: SelectableText(
                senha,
                style: TextStyle(
                  color: kPrimary,
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
                        content: const Text('Senha copiada.'),
                        backgroundColor: kSuccess,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kText1,
                    side: BorderSide(color: kBorder),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copiar'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      mostrarSenhaTemporaria(context, nome: nome, senha: senha),
                  style: FilledButton.styleFrom(
                    backgroundColor: kPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.ios_share_rounded, size: 16),
                  label: const Text('Ver / enviar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _passo(String n, String texto) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 18,
        height: 18,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: kPrimary.withValues(alpha: 0.16),
          shape: BoxShape.circle,
        ),
        child: Text(
          n,
          style: TextStyle(
            color: kPrimary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          texto,
          style: TextStyle(color: kText2, fontSize: 12, height: 1.35),
        ),
      ),
    ],
  ),
);
