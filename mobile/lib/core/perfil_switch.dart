import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'auth_storage.dart';
import 'theme/context_ext.dart';
import 'firestore_service.dart';
import 'profile_session_service.dart';
import 'push_service.dart';
import 'tab_refresh.dart';
import '../l10n/app_localizations.dart';

/// Rótulo localizado para o nome de perfil armazenado ('Aluno', 'Professor',
/// 'Secretaria', 'Admin'). O valor cru continua sendo o dado de negócio — só a
/// exibição é traduzida.
String _perfilLabel(String? raw, AppLocalizations l) {
  switch (raw) {
    case 'Admin':
      return l.roleAdmin;
    case 'Professor':
      return l.roleTeacher;
    case 'Secretaria':
      return l.roleSecretary;
    case 'Aluno':
      return l.roleStudent;
    default:
      return raw == null || raw.isEmpty ? l.roleStudent : raw;
  }
}

/// Mostra o seletor de perfil (mesma pessoa com mais de um vínculo — ex:
/// irmãos com o mesmo contato, ou Professor que também é Aluno em outra
/// modalidade) e troca a sessão ativa sem precisar deslogar.
Future<void> mostrarTrocarPerfil(BuildContext context) async {
  // Abre imediatamente com os perfis já em cache (SharedPreferences). O
  // `refresh()` remoto (Firebase + Firestore) roda em segundo plano só para
  // deixar a lista atualizada na próxima abertura — não bloqueia o modal.
  var user = await AuthStorage.getUser();
  if (user == null || user.perfis.length < 2) {
    // Cache diz que não há o que trocar: confirma no servidor antes de desistir.
    try {
      user = await ProfileSessionService.refresh() ?? user;
    } catch (_) {}
    if (user == null || user.perfis.length < 2) return;
  } else {
    ProfileSessionService.refresh().ignore();
  }
  final sessionUser = user;
  if (!context.mounted) return;

  final selecionado = await showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    backgroundColor: context.c.surfaceContainer,
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
                color: ctx.c.outline,
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
                      color: ctx.c.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.switch_account_rounded,
                      color: ctx.c.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ctx.l10n.psTitle,
                          style: TextStyle(
                            color: ctx.c.onSurface,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          ctx.l10n.psSubtitle,
                          style: TextStyle(
                            color: ctx.c.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: ctx.c.outline),
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
                      color: atual
                          ? ctx.c.primary.withValues(alpha: 0.10)
                          : ctx.c.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: atual
                            ? ctx.c.primary.withValues(alpha: 0.45)
                            : ctx.c.outline,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: atual ? ctx.c.primary : ctx.c.outline,
                        child: Text(
                          nome
                              .split(' ')
                              .take(2)
                              .map((w) => w.isNotEmpty ? w[0] : '')
                              .join()
                              .toUpperCase(),
                          style: TextStyle(
                            color: atual
                                ? ctx.c.onPrimary
                                : ctx.c.onSurfaceVariant,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      title: Text(
                        nome,
                        style: TextStyle(
                          color: ctx.c.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        _perfilLabel(p['perfil_nome'] as String?, ctx.l10n),
                        style: TextStyle(
                          color: ctx.c.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      trailing: atual
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: ctx.sem.success.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                ctx.l10n.psInUse,
                                style: TextStyle(
                                  color: ctx.sem.success,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  ctx.l10n.psAccess,
                                  style: TextStyle(
                                    color: ctx.c.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: ctx.c.primary,
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
      context.go('/aluno/inicio');
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
            color: context.c.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.c.primary.withValues(alpha: 0.30),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.switch_account_rounded,
                color: context.c.primary,
                size: 19,
              ),
              const SizedBox(width: 7),
              Text(
                context.l10n.psTitle,
                style: TextStyle(
                  color: context.c.primary,
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
