import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/auth_storage.dart';
import '../core/firestore_service.dart';
import '../core/theme/context_ext.dart';
import '../core/widgets.dart';

class NotificacoesScreen extends StatefulWidget {
  const NotificacoesScreen({super.key});

  @override
  State<NotificacoesScreen> createState() => _NotificacoesScreenState();
}

class _NotificacoesScreenState extends State<NotificacoesScreen> {
  List<Map<String, dynamic>> _notifs = [];
  bool _loading = true;
  bool _erro = false;
  String? _academiaId;
  String? _usuarioId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = false;
    });
    try {
      final user = await AuthStorage.getUser();
      _academiaId = user?.academiaId ?? '';
      _usuarioId = user?.id ?? '';
      if (_academiaId!.isEmpty) {
        setState(() => _loading = false);
        return;
      }
      // Aluno vê só os eventos PESSOAIS dele (cobrança, graduação); qualquer
      // outro perfil vê o feed da academia (conta vencida etc.), como hoje.
      final list = user?.perfil == 'Aluno'
          ? await firestoreService.getNotificacoesAluno(
              _academiaId!,
              _usuarioId!,
            )
          : await firestoreService.getNotificacoes(_academiaId!);
      if (mounted) setState(() => _notifs = list.cast<Map<String, dynamic>>());
    } catch (_) {
      if (mounted) setState(() => _erro = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _marcarLida(String id) async {
    if (_academiaId == null) return;
    try {
      await firestoreService.marcarNotificacaoLida(_academiaId!, id);
      if (mounted) {
        setState(() {
          final idx = _notifs.indexWhere((n) => n['id'].toString() == id);
          if (idx >= 0) _notifs[idx] = {..._notifs[idx], 'lida': true};
        });
      }
    } catch (_) {}
  }

  Future<void> _marcarTodasLidas() async {
    if (_academiaId == null || _usuarioId == null) return;
    try {
      await firestoreService.marcarTodasNotificacoesLidas(_academiaId!);
      if (mounted) {
        setState(() {
          _notifs = _notifs.map((n) => {...n, 'lida': true}).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _excluir(String id) async {
    if (_academiaId == null) return;
    final idx = _notifs.indexWhere((n) => n['id'].toString() == id);
    final removida = idx >= 0 ? _notifs[idx] : null;
    if (mounted) setState(() => _notifs.removeWhere((n) => n['id'].toString() == id));
    try {
      await firestoreService.deleteNotificacao(_academiaId!, id);
    } catch (_) {
      // Falhou no servidor: devolve pra lista pra não perder a notificação.
      if (mounted && removida != null) {
        setState(() => _notifs.insert(idx.clamp(0, _notifs.length), removida));
      }
    }
  }

  /// Ao tocar numa notificação já lida (ou depois de marcar como lida): abre
  /// o destino relevante pro tipo. Tipos antigos (`alerta`/`info`/
  /// `aniversario`) não têm destino — só marcam como lida, igual sempre foi.
  void _abrirDestino(Map<String, dynamic> n) {
    final tipo = n['tipo']?.toString();
    switch (tipo) {
      case 'solicitacao_senha':
        // Quando mais de um aluno compartilha o telefone/e-mail, o backend
        // não grava `usuario_id` (só `usuario_ids`) — ambíguo pra abrir uma
        // ficha só, então aqui só marca como lida e a academia decide.
        final usuarioId = n['usuario_id']?.toString();
        if (usuarioId != null && usuarioId.isNotEmpty) {
          context.push('/admin/alunos/$usuarioId');
        }
      case 'cobranca_gerada':
        context.push('/aluno/financeiro');
      case 'graduacao':
        context.push('/aluno/graduacoes');
    }
  }

  Color _tipoCor(BuildContext context, String? tipo) {
    if (tipo == 'alerta') return context.sem.warning;
    if (tipo == 'aniversario') return const Color(0xFFEC4899);
    return context.c.primary;
  }

  IconData _tipoIcon(String? tipo) {
    if (tipo == 'alerta') return Icons.warning_amber_rounded;
    if (tipo == 'aniversario') return Icons.cake_rounded;
    if (tipo == 'solicitacao_senha') return Icons.vpn_key_rounded;
    if (tipo == 'cobranca_gerada') return Icons.receipt_long_rounded;
    if (tipo == 'graduacao') return Icons.workspace_premium_rounded;
    return Icons.notifications_rounded;
  }

  int get _naolidas => _notifs.where((n) => n['lida'] != true).length;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: context.c.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.arrow_back, color: context.c.onSurface),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.notifTitle,
                          style: TextStyle(
                            color: context.c.onSurface,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (_naolidas > 0)
                          Text(
                            l.notifUnreadCount(_naolidas),
                            style: TextStyle(
                              color: context.c.primary,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_naolidas > 0)
                    TextButton(
                      onPressed: _marcarTodasLidas,
                      style: TextButton.styleFrom(
                        foregroundColor: context.c.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        l.notifMarkAllRead,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: context.c.primary,
                      ),
                    )
                  : _erro
                  ? ErroConexao(onRetry: _load)
                  : _notifs.isEmpty
                  ? ListaVazia(
                      icon: Icons.notifications_none_rounded,
                      titulo: l.notifEmptyTitle,
                      subtitulo: l.notifEmptySubtitle,
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: context.c.primary,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _notifs.length,
                        itemBuilder: (_, i) {
                          final n = _notifs[i];
                          final lida = n['lida'] == true;
                          final tipo = n['tipo']?.toString();
                          final cor = _tipoCor(context, tipo);
                          final id = n['id'].toString();

                          return Dismissible(
                            key: Key(id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: context.sem.danger.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.delete_rounded,
                                color: context.sem.danger,
                              ),
                            ),
                            onDismissed: (_) => _excluir(id),
                            child: GestureDetector(
                              onTap: () async {
                                if (!lida) await _marcarLida(id);
                                if (!mounted) return;
                                _abrirDestino(n);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: lida
                                      ? context.c.surfaceContainer
                                      : context.c.primary.withValues(
                                          alpha: 0.06,
                                        ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: lida
                                        ? context.c.outline
                                        : cor.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: cor.withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _tipoIcon(tipo),
                                        color: cor,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  n['titulo'] ?? '',
                                                  style: TextStyle(
                                                    color: context.c.onSurface,
                                                    fontSize: 13,
                                                    fontWeight: lida
                                                        ? FontWeight.w600
                                                        : FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                              if (!lida)
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: cor,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            n['mensagem'] ?? '',
                                            style: TextStyle(
                                              color: context.c.onSurfaceVariant,
                                              fontSize: 12,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget do sino de notificações para usar no header — auto-detecta se o
/// usuário logado é aluno (conta eventos pessoais) ou staff (conta o feed da
/// academia), sem precisar de nenhum parâmetro.
class SinoNotificacoes extends StatefulWidget {
  const SinoNotificacoes({super.key});

  @override
  State<SinoNotificacoes> createState() => _SinoNotificacoesState();
}

class _SinoNotificacoesState extends State<SinoNotificacoes> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _fetchCount();
  }

  Future<void> _fetchCount() async {
    try {
      final user = await AuthStorage.getUser();
      final academiaId = user?.academiaId ?? '';
      final usuarioId = user?.id ?? '';
      if (academiaId.isEmpty) return;
      final list = user?.perfil == 'Aluno'
          ? await firestoreService.getNotificacoesAluno(academiaId, usuarioId)
          : await firestoreService.getNotificacoes(academiaId);
      final unread = list.where((n) => n['lida'] != true).length;
      if (mounted) setState(() => _count = unread);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const NotificacoesScreen()));
        _fetchCount();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.c.surfaceContainer,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.c.outline),
            ),
            child: Icon(
              Icons.notifications_outlined,
              color: context.c.onSurfaceVariant,
              size: 20,
            ),
          ),
          if (_count > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: context.sem.danger,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  _count > 9 ? '9+' : '$_count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
