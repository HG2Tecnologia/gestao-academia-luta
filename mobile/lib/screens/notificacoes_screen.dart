import 'package:flutter/material.dart';
import '../core/auth_storage.dart';
import '../core/constants.dart';
import '../core/firestore_service.dart';
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
    setState(() { _loading = true; _erro = false; });
    try {
      final user = await AuthStorage.getUser();
      _academiaId = user?.academiaId ?? '';
      _usuarioId = user?.id ?? '';
      if (_academiaId!.isEmpty) {
        setState(() { _loading = false; });
        return;
      }
      final list = await firestoreService.getNotificacoes(_academiaId!);
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
      if (mounted) setState(() {
        final idx = _notifs.indexWhere((n) => n['id'].toString() == id);
        if (idx >= 0) _notifs[idx] = {..._notifs[idx], 'lida': true};
      });
    } catch (_) {}
  }

  Future<void> _marcarTodasLidas() async {
    if (_academiaId == null || _usuarioId == null) return;
    try {
      await firestoreService.marcarTodasNotificacoesLidas(_academiaId!);
      if (mounted) setState(() {
        _notifs = _notifs.map((n) => {...n, 'lida': true}).toList();
      });
    } catch (_) {}
  }

  // Note: single notification delete not available in firestoreService; remove locally only
  void _excluirLocal(String id) {
    if (mounted) setState(() => _notifs.removeWhere((n) => n['id'].toString() == id));
  }

  Color _tipoCor(String? tipo) {
    if (tipo == 'alerta') return kWarning;
    if (tipo == 'aniversario') return const Color(0xFFEC4899);
    return kPrimary;
  }

  IconData _tipoIcon(String? tipo) {
    if (tipo == 'alerta') return Icons.warning_amber_rounded;
    if (tipo == 'aniversario') return Icons.cake_rounded;
    return Icons.notifications_rounded;
  }

  int get _naolidas => _notifs.where((n) => n['lida'] != true).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
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
                    icon: Icon(Icons.arrow_back, color: kText1),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Notificações', style: TextStyle(color: kText1, fontSize: 22, fontWeight: FontWeight.w800)),
                        if (_naolidas > 0)
                          Text('$_naolidas não lida${_naolidas > 1 ? 's' : ''}', style: TextStyle(color: kPrimary, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (_naolidas > 0)
                    TextButton(
                      onPressed: _marcarTodasLidas,
                      style: TextButton.styleFrom(
                        foregroundColor: kPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Marcar todas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: kPrimary))
                  : _erro
                      ? ErroConexao(onRetry: _load)
                      : _notifs.isEmpty
                          ? ListaVazia(
                              icon: Icons.notifications_none_rounded,
                              titulo: 'Nenhuma notificação',
                              subtitulo: 'Você está em dia com tudo!',
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              color: kPrimary,
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _notifs.length,
                                itemBuilder: (_, i) {
                                  final n = _notifs[i];
                                  final lida = n['lida'] == true;
                                  final tipo = n['tipoLabel']?.toString() ?? n['tipo']?.toString();
                                  final cor = _tipoCor(tipo);
                                  final id = n['id'].toString();

                                  return Dismissible(
                                    key: Key(id),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      decoration: BoxDecoration(
                                        color: kDanger.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.delete_rounded, color: kDanger),
                                    ),
                                    onDismissed: (_) => _excluirLocal(id),
                                    child: GestureDetector(
                                      onTap: () { if (!lida) _marcarLida(id); },
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: lida ? kSurface : kSurface.withBlue(50),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: lida ? kBorder : cor.withOpacity(0.3)),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 38,
                                              height: 38,
                                              decoration: BoxDecoration(
                                                color: cor.withOpacity(0.12),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(_tipoIcon(tipo), color: cor, size: 18),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          n['titulo'] ?? '',
                                                          style: TextStyle(
                                                            color: kText1,
                                                            fontSize: 13,
                                                            fontWeight: lida ? FontWeight.w600 : FontWeight.w800,
                                                          ),
                                                        ),
                                                      ),
                                                      if (!lida)
                                                        Container(
                                                          width: 8,
                                                          height: 8,
                                                          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(n['mensagem'] ?? '', style: TextStyle(color: kText2, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    n['tempoRelativo']?.toString() ?? '',
                                                    style: TextStyle(color: kText2.withOpacity(0.6), fontSize: 11),
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

/// Widget do sino de notificações para usar no header
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
      final list = await firestoreService.getNotificacoes(academiaId);
      final unread = list.where((n) => n['lida'] != true).length;
      if (mounted) setState(() => _count = unread);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NotificacoesScreen()),
        );
        _fetchCount();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kBorder),
            ),
            child: Icon(Icons.notifications_outlined, color: kText2, size: 20),
          ),
          if (_count > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: kDanger, shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  _count > 9 ? '9+' : '$_count',
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
