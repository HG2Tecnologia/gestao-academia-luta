import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'auth_storage.dart';
import 'constants.dart';
import 'firestore_service.dart';
import 'push_service.dart';
import 'tab_refresh.dart';

/// Mostra o seletor de perfil (mesma pessoa com mais de um vínculo — ex:
/// irmãos com o mesmo contato, ou Professor que também é Aluno em outra
/// modalidade) e troca a sessão ativa sem precisar deslogar.
Future<void> mostrarTrocarPerfil(BuildContext context) async {
  final user = await AuthStorage.getUser();
  if (user == null || user.perfis.length < 2) return;
  if (!context.mounted) return;

  final selecionado = await showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    backgroundColor: kSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.swap_horiz_rounded, color: kPrimary, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Trocar de perfil',
                  style: TextStyle(
                    color: kText1,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (final p in user.perfis)
            ListTile(
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: kPrimary,
                child: Text(
                  (p['nome'] as String? ?? '')
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
                p['nome'] as String? ?? '',
                style: TextStyle(color: kText1, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                p['perfil_nome'] as String? ?? 'Aluno',
                style: TextStyle(color: kText2, fontSize: 12),
              ),
              trailing: (p['usuarioId'] == user.id)
                  ? Icon(Icons.check_circle_rounded, color: kSuccess, size: 20)
                  : null,
              onTap: () => Navigator.of(ctx).pop(p),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );

  if (selecionado == null ||
      selecionado['usuarioId'] == user.id ||
      !context.mounted)
    return;

  final novoUsuarioId = selecionado['usuarioId'] as String? ?? user.id;
  final novoNome = selecionado['nome'] as String? ?? user.nome;
  final novaAcademiaId =
      selecionado['academiaId'] as String? ?? user.academiaId;
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
      email: user.email,
      perfil: novoPerfilNome,
      academiaId: novaAcademiaId,
      permissoes: novasPermissoes,
      perfis: user.perfis,
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
      context.go('/login');
  }
}
