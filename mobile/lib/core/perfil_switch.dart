import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'auth_storage.dart';
import 'constants.dart';
import 'firestore_service.dart';
import 'profile_session_service.dart';
import 'push_service.dart';
import 'tab_refresh.dart';

/// Mostra o seletor de perfil (mesma pessoa com mais de um vínculo — ex:
/// irmãos com o mesmo contato, ou Professor que também é Aluno em outra
/// modalidade) e troca a sessão ativa sem precisar deslogar.
Future<void> mostrarTrocarPerfil(BuildContext context) async {
  var user = await AuthStorage.getUser();
  try {
    user = await ProfileSessionService.refresh() ?? user;
  } catch (_) {}
  if (user == null || user.perfis.length < 2) return;
  final sessionUser = user;
  if (!context.mounted) return;

  final selecionado = await showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    backgroundColor: kSurface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(ctx).height * 0.72,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: kPrimary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.switch_account_rounded,
                      color: kPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trocar perfil',
                          style: TextStyle(
                            color: kText1,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Escolha quem está usando o app agora',
                          style: TextStyle(color: kText2, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: kBorder),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                itemCount: sessionUser.perfis.length,
                itemBuilder: (_, index) {
                  final p = sessionUser.perfis[index];
                  final atual =
                      p['usuarioId'] == sessionUser.id &&
                      p['academiaId'] == sessionUser.academiaId;
                  final nome = p['nome'] as String? ?? '';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: atual ? kPrimary.withValues(alpha: 0.10) : kBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: atual
                            ? kPrimary.withValues(alpha: 0.45)
                            : kBorder,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: atual ? kPrimary : kBorder,
                        child: Text(
                          nome
                              .split(' ')
                              .take(2)
                              .map((w) => w.isNotEmpty ? w[0] : '')
                              .join()
                              .toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      title: Text(
                        nome,
                        style: TextStyle(
                          color: kText1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        p['perfil_nome'] as String? ?? 'Aluno',
                        style: TextStyle(color: kText2, fontSize: 12),
                      ),
                      trailing: atual
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: kSuccess.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Em uso',
                                style: TextStyle(
                                  color: kSuccess,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Acessar',
                                  style: TextStyle(
                                    color: kPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: kPrimary,
                                  size: 18,
                                ),
                              ],
                            ),
                      onTap: atual ? null : () => Navigator.of(ctx).pop(p),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );

  if (selecionado == null ||
      (selecionado['usuarioId'] == sessionUser.id &&
          selecionado['academiaId'] == sessionUser.academiaId) ||
      !context.mounted) {
    return;
  }

  final novoUsuarioId = selecionado['usuarioId'] as String? ?? sessionUser.id;
  final novoNome = selecionado['nome'] as String? ?? sessionUser.nome;
  final novaAcademiaId =
      selecionado['academiaId'] as String? ?? sessionUser.academiaId;
  final novaColecao = selecionado['colecao'] as String? ?? 'usuarios';
  final novoPerfilNome = selecionado['perfil_nome'] as String? ?? 'Aluno';

  var novasPermissoes = <String, bool>{};
  if (novaColecao == 'funcionarios' && novaAcademiaId != null) {
    final func = await firestoreService.getFuncionario(
      novaAcademiaId,
      novoUsuarioId,
    );
    final rawPerm = func?['permissoes'];
    if (rawPerm is Map) {
      novasPermissoes = rawPerm.map(
        (k, v) => MapEntry(k.toString(), v == true),
      );
    }
  }

  await AuthStorage.saveUser(
    StoredUser(
      id: novoUsuarioId,
      nome: novoNome,
      email: sessionUser.email,
      perfil: novoPerfilNome,
      academiaId: novaAcademiaId,
      permissoes: novasPermissoes,
      perfis: sessionUser.perfis,
    ),
  );

  if (novoPerfilNome == 'Admin' || novoPerfilNome == 'Secretaria') {
    PushService.init();
  }

  // Força as telas "raiz" a recarregar mesmo quando a rota de destino é a
  // mesma em que já estavam (ex: trocar entre dois perfis de Aluno mantém
  // a rota '/aluno/perfil' — sem isso a tela ficava com os dados antigos
  // até um pull-to-refresh manual).
  perfilTrocadoNotifier.value++;

  if (!context.mounted) return;
  switch (novoPerfilNome) {
    case 'Admin':
    case 'Secretaria':
      context.go('/admin/dashboard');
    case 'Professor':
      context.go('/professor/dashboard');
    case 'Aluno':
      context.go('/aluno/perfil');
    default:
      context.go('/boas-vindas');
  }
}

class PerfilSwitchButton extends StatelessWidget {
  const PerfilSwitchButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.switch_account_rounded, color: Colors.white, size: 19),
              SizedBox(width: 7),
              Text(
                'Trocar perfil',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
