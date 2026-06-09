import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/tab_refresh.dart';
import '../../core/widgets.dart';
import 'aluno_qrcode_sheet.dart';

class AlunoPerfilScreen extends StatefulWidget {
  const AlunoPerfilScreen({super.key});

  @override
  State<AlunoPerfilScreen> createState() => _AlunoPerfilScreenState();
}

class _AlunoPerfilScreenState extends State<AlunoPerfilScreen> {
  Map<String, dynamic>? _aluno;
  List<Map<String, dynamic>> _contratos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    alunoTabNotifier.addListener(_onTabChanged);
    _load();
  }

  @override
  void dispose() {
    alunoTabNotifier.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (alunoTabNotifier.value == 0) _load();
  }

  Future<void> _load() async {
    try {
      final res = await dio.get('/api/alunos/me');
      final dados = res.data['dados'] as Map<String, dynamic>?;
      if (mounted) setState(() => _aluno = dados);
      if (dados != null) {
        final alunoId = dados['id']?.toString() ?? '';
        try {
          final cr = await dio.get('/api/contratos', queryParameters: {'alunoId': alunoId});
          final lista = (cr.data['dados'] as List? ?? []).cast<Map<String, dynamic>>();
          if (mounted) setState(() => _contratos = lista);
        } catch (_) {}
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _stripHtml(String html) {
    var text = html
        .replaceAll(RegExp(r'<br\s*/?>',  caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>',        caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'</h[1-6]>',  caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'</li>',       caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'&amp;'),  '&')
        .replaceAll(RegExp(r'&lt;'),   '<')
        .replaceAll(RegExp(r'&gt;'),   '>')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    return text;
  }

  Future<void> _assinarContrato(Map<String, dynamic> contrato) async {
    final nome = _aluno?['nome'] as String? ?? '';
    final contratoId = contrato['id']?.toString() ?? '';

    // 1. Busca o conteúdo do contrato
    String conteudo = '';
    try {
      final res = await dio.get('/api/contratos/$contratoId');
      final html = (res.data['dados'] as Map<String, dynamic>?)?['conteudoHtml'] as String? ?? '';
      conteudo = _stripHtml(html);
    } catch (_) {
      conteudo = 'Não foi possível carregar o conteúdo do contrato.';
    }
    if (!mounted) return;

    // 2. Mostra o contrato para leitura + botão assinar
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (ctx2, scrollCtrl) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(child: Text('Contrato para assinatura', style: TextStyle(color: kText1, fontSize: 17, fontWeight: FontWeight.w800))),
                  IconButton(onPressed: () => Navigator.of(ctx).pop(false), icon: Icon(Icons.close, color: kText2)),
                ],
              ),
            ),
            Divider(color: kBorder, height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Text(
                  conteudo.isEmpty ? 'Conteúdo não disponível.' : conteudo,
                  style: TextStyle(color: kText1, fontSize: 13, height: 1.6),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              decoration: BoxDecoration(
                color: kSurface,
                border: Border(top: BorderSide(color: kBorder)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Ao assinar, você confirma ter lido e concordado com os termos acima como "$nome".',
                    style: TextStyle(color: kText2, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Assinar digitalmente', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (ok != true || !mounted) return;
    try {
      await dio.post('/api/contratos/$contratoId/assinar', data: {'nomeCompleto': nome});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Contrato assinado com sucesso!'), backgroundColor: kSuccess, behavior: SnackBarBehavior.floating),
        );
        _load();
      }
    } catch (e) {
      String msg = 'Erro ao assinar contrato.';
      try { msg = ((e as dynamic).response?.data as Map?)?['mensagem'] ?? msg; } catch (_) {}
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
      );
    }
  }

  Color _faixaCor() {
    final hex = _aluno?['faixaAtualCor'] as String? ?? '';
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return kPrimary;
    }
  }

  Color _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.black;
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return Colors.black;
    }
  }

  void _mostrarQrCode() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const AlunoQrCodeSheet(),
    );
  }

  void _editarPerfil() {
    final nomeCtrl = TextEditingController(text: _aluno?['nome'] as String? ?? '');
    final telCtrl = TextEditingController(text: _aluno?['telefone'] as String? ?? '');
    bool salvando = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: BoxDecoration(color: kSurface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2)))),
              Row(children: [
                Container(width: 38, height: 38,
                  decoration: BoxDecoration(color: kPrimary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.person_rounded, color: kPrimary, size: 20)),
                const SizedBox(width: 12),
                Text('Editar Perfil', style: TextStyle(color: kText1, fontSize: 17, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 20),
              TextField(
                controller: nomeCtrl,
                style: TextStyle(color: kText1),
                decoration: InputDecoration(
                  labelText: 'Nome completo',
                  labelStyle: TextStyle(color: kText2, fontSize: 13),
                  prefixIcon: Icon(Icons.badge_rounded, color: kText2, size: 18),
                  filled: true, fillColor: kBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPrimary, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: telCtrl,
                style: TextStyle(color: kText1),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Telefone',
                  labelStyle: TextStyle(color: kText2, fontSize: 13),
                  prefixIcon: Icon(Icons.phone_rounded, color: kText2, size: 18),
                  filled: true, fillColor: kBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPrimary, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: salvando ? null : () async {
                    setModal(() => salvando = true);
                    try {
                      await dio.put('/api/usuarios/me', data: {
                        'nome': nomeCtrl.text.trim(),
                        'telefone': telCtrl.text.trim().isEmpty ? null : telCtrl.text.trim(),
                      });
                      if (!mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('Perfil atualizado!'), backgroundColor: kSuccess, behavior: SnackBarBehavior.floating),
                      );
                      _load();
                    } catch (_) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('Erro ao salvar.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
                      );
                    } finally {
                      setModal(() => salvando = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: salvando
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Salvar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sair() async {
    try { await dio.post('/api/auth/logout'); } catch (_) {}
    await AuthStorage.clear();
    if (mounted) context.go('/login');
  }

  Future<void> _excluirConta() async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Excluir conta?', style: TextStyle(color: kText1, fontWeight: FontWeight.w800)),
        content: Text('Seus dados pessoais serão removidos permanentemente. Esta ação não pode ser desfeita.', style: TextStyle(color: kText2)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar', style: TextStyle(color: kText2))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Excluir', style: TextStyle(color: kDanger, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirma != true || !mounted) return;
    try {
      await dio.delete('/api/usuarios/me');
      await AuthStorage.clear();
      if (mounted) context.go('/login');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Erro ao excluir conta.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(backgroundColor: kBg, body: Center(child: CircularProgressIndicator(color: kPrimary)));
    }

    final a = _aluno ?? {};
    final nome = a['nome'] as String? ?? '';
    final initials = nome.trim().split(RegExp(r'\s+')).take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();
    final faixaCor = _faixaCor();
    final faixaNome = a['faixaAtualNome'] as String? ?? 'Sem faixa';
    final grauAtual = (a['grauAtual'] as num?)?.toInt() ?? 0;
    final faixaCorBarra = _parseHex(a['faixaAtualCorBarra'] as String?);
    final faixaTemGraus = a['faixaAtualTemGraus'] as bool? ?? false;
    final faixaMaxGraus = (a['faixaAtualMaxGraus'] as num?)?.toInt() ?? 4;
    final turmasDetalhes = (a['turmasDetalhes'] as List? ?? []).cast<Map<String, dynamic>>();
    final finRaw = a['situacaoFinanceira'] as String?;
    final fin = finRaw == 'EmDia' ? 'Em Dia' : finRaw;

    Color finCor() {
      if (fin == 'Inadimplente') return kDanger;
      if (fin == 'Pendente') return kWarning;
      if (fin == 'Em Dia') return kSuccess;
      return kText2;
    }

    // Use kPrimary for very light belts (white, cinza) to keep the dark theme readable
    final beltColor = faixaCor.computeLuminance() > 0.5 ? kPrimary : faixaCor;
    final accentLight = Color.lerp(beltColor, Colors.white, 0.25)!;

    return Scaffold(
      backgroundColor: kBg,
      body: RefreshIndicator(
        onRefresh: _load,
        color: kPrimary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
          // ── Hero header ──────────────────────────────────
          SliverToBoxAdapter(
            child: Stack(
              children: [
                // Belt-colored gradient header
                Container(
                  height: 230,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [beltColor.withOpacity(0.30), kBg],
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: () => context.push('/alterar-senha'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(children: [
                                  Icon(Icons.lock_reset_rounded, size: 14, color: kText2),
                                  const SizedBox(width: 4),
                                  Text('Senha', style: TextStyle(color: kText2, fontSize: 12)),
                                ]),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _sair,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(children: [
                                  Icon(Icons.logout_rounded, size: 14, color: kText2),
                                  const SizedBox(width: 4),
                                  Text('Sair', style: TextStyle(color: kText2, fontSize: 12)),
                                ]),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Avatar with belt-color ring
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [accentLight, beltColor.withOpacity(0.5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 46,
                          backgroundColor: kSurface,
                          child: Text(
                            initials.isEmpty ? '?' : initials,
                            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        nome.isEmpty ? 'Aluno' : nome,
                        style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      // Belt badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: beltColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: beltColor.withOpacity(0.5)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              grauAtual > 0 ? '$faixaNome · ${grauAtual}° Grau' : faixaNome,
                              style: TextStyle(color: accentLight, fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            BeltBadge(
                              cor: faixaCor,
                              corBarra: faixaCorBarra,
                              temGraus: faixaTemGraus,
                              grau: grauAtual,
                              maxGraus: faixaMaxGraus,
                              height: 14,
                              minWidth: 52,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: _mostrarQrCode,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.18)),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.qr_code_rounded, size: 14, color: Colors.white70),
                                const SizedBox(width: 6),
                                Text('QR Presença', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                              ]),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _editarPerfil,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.18)),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.edit_rounded, size: 14, color: Colors.white70),
                                const SizedBox(width: 6),
                                Text('Editar Perfil', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                              ]),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Situação financeira — só mostra se houver pendência ──
          if (fin == 'Inadimplente' || fin == 'Pendente')
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: finCor().withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: finCor().withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: finCor(), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Situação: $fin',
                                style: TextStyle(color: finCor(), fontSize: 13, fontWeight: FontWeight.w700)),
                            Text('Entre em contato com a secretaria.',
                                style: TextStyle(color: kText2, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Graduações ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: GestureDetector(
                onTap: () => context.push('/aluno/perfil/graduacoes'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: kSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: beltColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.military_tech_rounded, color: beltColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Histórico de Graduações', style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w700)),
                            Text('Ver todas as faixas e exames', style: TextStyle(color: kText2, fontSize: 11)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: kText2, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Turmas ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
              child: Text('MINHAS TURMAS',
                  style: TextStyle(color: kText2, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            ),
          ),

          if (turmasDetalhes.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kBorder),
                  ),
                  child: Text('Nenhuma turma matriculada.',
                      style: TextStyle(color: kText2, fontSize: 13)),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final t = turmasDetalhes[i];
                  final nome = t['nome'] as String? ?? '';
                  final presencas = (t['totalPresencas'] as num?)?.toInt() ?? 0;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: kBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: beltColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.groups_rounded, color: beltColor, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              nome,
                              style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: beltColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '$presencas',
                                  style: TextStyle(color: beltColor, fontSize: 15, fontWeight: FontWeight.w800),
                                ),
                                Text('presenças', style: TextStyle(color: kText2, fontSize: 9)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: turmasDetalhes.length,
              ),
            ),

          // ── Contratos ────────────────────────────────────
          if (_contratos.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
                child: Text('CONTRATOS',
                    style: TextStyle(color: kText2, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final c = _contratos[i];
                  final status = c['statusLabel'] as String? ?? c['status']?.toString() ?? '';
                  final isPendente = status == 'Pendente';
                  final statusCor = isPendente ? kWarning : (status == 'Assinado' ? kSuccess : kText2);
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: kSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isPendente ? kWarning.withOpacity(0.4) : kBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: statusCor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isPendente ? Icons.edit_document : Icons.check_circle_rounded,
                              color: statusCor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c['nomeModalidade'] as String? ?? 'Contrato',
                                  style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                Text(status, style: TextStyle(color: statusCor, fontSize: 11, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          if (isPendente)
                            SizedBox(
                              height: 34,
                              child: ElevatedButton(
                                onPressed: () => _assinarContrato(c),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Assinar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: _contratos.length,
              ),
            ),
          ],

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: TextButton.icon(
                onPressed: _excluirConta,
                icon: Icon(Icons.delete_forever_rounded, size: 16, color: kDanger.withOpacity(0.6)),
                label: Text('Excluir minha conta', style: TextStyle(color: kDanger.withOpacity(0.6), fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
