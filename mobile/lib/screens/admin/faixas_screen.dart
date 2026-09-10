import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_storage.dart';
import '../../core/theme/context_ext.dart';
import '../../l10n/app_localizations.dart';
import '../../core/firestore_service.dart';
import '../../core/graduacao_order.dart';

class AdminFaixasScreen extends StatefulWidget {
  const AdminFaixasScreen({super.key});

  @override
  State<AdminFaixasScreen> createState() => _AdminFaixasScreenState();
}

class _AdminFaixasScreenState extends State<AdminFaixasScreen> {
  AppLocalizations get _l => context.l10n;
  List<Map<String, dynamic>> _modalidades = [];
  List<Map<String, dynamic>> _faixas = [];
  String? _modalidadeId;
  bool _loading = true;
  bool _loadingFaixas = false;
  bool _erro = false;
  String? _academiaId;

  // Contagem de alunos derivada das graduações aprovadas (opcional).
  Map<String, int> _alunosPorFaixa = {};
  int? _alunosNaModalidade;
  bool _contagemDisponivel = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _erro = false;
    });
    try {
      final user = await AuthStorage.getUser();
      _academiaId = user?.academiaId ?? '';
      if (_academiaId!.isEmpty) {
        setState(() => _loading = false);
        return;
      }
      final todasModalidades = await firestoreService.getModalidades(
        _academiaId!,
      );
      final modalidades = todasModalidades
          .where((m) => m['ativo'] == true)
          .toList();
      if (!mounted) return;
      setState(() {
        _modalidades = modalidades.cast<Map<String, dynamic>>();
      });
      if (modalidades.isNotEmpty) {
        _modalidadeId = modalidades.first['id']?.toString();
        await _loadFaixas();
      }
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _erro = true;
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadFaixas() async {
    if (_modalidadeId == null || _academiaId == null) return;
    setState(() {
      _loadingFaixas = true;
      _erro = false;
    });
    try {
      final faixas = await firestoreService.getFaixas(
        _academiaId!,
        modalidadeId: _modalidadeId,
      );
      final list = faixas.cast<Map<String, dynamic>>();
      list.sort(
        (a, b) => (a['ordem'] as int? ?? 0).compareTo(b['ordem'] as int? ?? 0),
      );
      if (mounted) {
        setState(() {
          _faixas = list;
          _loadingFaixas = false;
        });
      }
      await _carregarContagemAlunos();
    } catch (_) {
      if (mounted) {
        setState(() {
          _erro = true;
          _loadingFaixas = false;
        });
      }
    }
  }

  /// Deriva "N alunos por faixa" e "N alunos na modalidade" a partir do
  /// histórico de graduações aprovadas. É best-effort: qualquer falha aqui
  /// apenas esconde os contadores, sem quebrar a tela.
  Future<void> _carregarContagemAlunos() async {
    if (_academiaId == null || _modalidadeId == null) return;
    try {
      final grads = await firestoreService.getGraduacoes(_academiaId!);
      final faixasAtuais = montarFaixasAtuaisPorAluno(grads);
      final porFaixa = <String, int>{};
      var naModalidade = 0;
      faixasAtuais.forEach((_, porModalidade) {
        final atual = porModalidade[_modalidadeId];
        if (atual == null) return;
        naModalidade++;
        final fid = (atual['faixaId'] ?? '').toString();
        if (fid.isNotEmpty) porFaixa[fid] = (porFaixa[fid] ?? 0) + 1;
      });
      if (!mounted) return;
      setState(() {
        _alunosPorFaixa = porFaixa;
        _alunosNaModalidade = naModalidade;
        _contagemDisponivel = true;
      });
    } catch (_) {
      if (mounted) setState(() => _contagemDisponivel = false);
    }
  }

  void _trocarModalidade(String id) {
    if (id == _modalidadeId) return;
    setState(() {
      _modalidadeId = id;
      _alunosPorFaixa = {};
      _alunosNaModalidade = null;
      _contagemDisponivel = false;
    });
    _loadFaixas();
  }

  Future<void> _selecionarModalidade() async {
    final id = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ModalidadePickerSheet(
        modalidades: _modalidades,
        selecionadaId: _modalidadeId,
      ),
    );
    if (id != null) _trocarModalidade(id);
  }

  Future<void> _deletar(Map<String, dynamic> faixa) async {
    final nome = faixa['nome']?.toString() ?? '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.c.surfaceContainer,
        title: Text(
          _l.fxDeleteTitle,
          style: TextStyle(
            color: context.c.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          _l.fxDeleteBody(nome),
          style: TextStyle(color: context.c.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              _l.commonCancel,
              style: TextStyle(color: context.c.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              _l.commonDelete,
              style: TextStyle(
                color: context.sem.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted || _academiaId == null) return;
    try {
      await firestoreService.deleteFaixa(_academiaId!, faixa['id'].toString());
      await _loadFaixas();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_l.fxDeleteError),
          backgroundColor: context.sem.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _abrirForm({Map<String, dynamic>? faixa}) {
    if (_modalidadeId == null || _academiaId == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      builder: (_) => _FaixaFormSheet(
        academiaId: _academiaId!,
        modalidadeId: _modalidadeId!,
        faixa: faixa,
        proximaOrdem: _faixas.isEmpty
            ? 1
            : (_faixas.last['ordem'] as int? ?? 0) + 1,
        onSalvo: _loadFaixas,
      ),
    );
  }

  void _mostrarAjuda() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.c.surfaceContainer,
        title: Text(
          _l.fxAboutTitle,
          style: TextStyle(
            color: context.c.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          _l.fxAboutBody,
          style: TextStyle(color: context.c.onSurfaceVariant, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              _l.commonUnderstood,
              style: TextStyle(color: context.c.primary),
            ),
          ),
        ],
      ),
    );
  }

  String get _nomeModalidadeAtual {
    final m = _modalidades.firstWhere(
      (e) => e['id']?.toString() == _modalidadeId,
      orElse: () => const {},
    );
    return m['nome']?.toString() ?? _l.fxSelectModality;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.surface,
      appBar: AppBar(
        backgroundColor: context.c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: context.c.onSurface,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Cabecalho(onAjuda: _mostrarAjuda),
            if (_modalidades.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: _ModalidadeSelector(
                  nome: _nomeModalidadeAtual,
                  onTap: _selecionarModalidade,
                ),
              ),
            if (_modalidades.isNotEmpty && !_erro)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: _ResumoModalidade(
                  faixas: _loading || _loadingFaixas ? null : _faixas.length,
                  alunos: _contagemDisponivel ? _alunosNaModalidade : null,
                ),
              ),
            Expanded(child: _conteudo()),
            if (_modalidadeId != null && !_erro && !_loading)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _abrirForm(),
                    icon: Icon(Icons.add_rounded, color: Colors.black),
                    label: Text(
                      _l.fxNewBelt,
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.c.primary,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _conteudo() {
    if (_loading) return const _SkeletonLista();
    if (_erro) {
      return _EstadoErro(
        mensagem: _l.fxLoadError,
        onRetry: _modalidades.isEmpty ? _init : _loadFaixas,
      );
    }
    if (_modalidades.isEmpty) {
      return _EstadoVazio(
        icon: Icons.sports_martial_arts_rounded,
        titulo: _l.fxNoModalities,
        subtitulo: _l.fxNoModalitiesHint,
      );
    }
    if (_loadingFaixas) return const _SkeletonLista();
    if (_faixas.isEmpty) {
      return _EstadoVazio(
        icon: Icons.military_tech_rounded,
        titulo: _l.fxEmpty,
        subtitulo: _l.fxEmptyHint,
        acao: OutlinedButton.icon(
          onPressed: () => _abrirForm(),
          icon: Icon(Icons.add_rounded),
          label: Text(_l.fxCreateFirst),
          style: OutlinedButton.styleFrom(
            foregroundColor: context.c.primary,
            side: BorderSide(color: context.c.primary.withValues(alpha: 0.6)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: _faixas.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final f = _faixas[i];
        final id = f['id']?.toString() ?? '';
        return _FaixaCard(
          faixa: f,
          alunos: _contagemDisponivel ? (_alunosPorFaixa[id] ?? 0) : null,
          onEdit: () => _abrirForm(faixa: f),
          onDelete: () => _deletar(f),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cabeçalho
// ─────────────────────────────────────────────────────────────────────────────

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.onAjuda});
  final VoidCallback onAjuda;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.fxTitle,
                  style: TextStyle(
                    color: context.c.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.fxSubtitle,
                  style: TextStyle(
                    color: context.c.onSurfaceVariant,
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onAjuda,
            icon: Icon(
              Icons.help_outline_rounded,
              color: context.c.primary,
              size: 22,
            ),
            tooltip: context.l10n.fxHelp,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Seletor de modalidade
// ─────────────────────────────────────────────────────────────────────────────

class _ModalidadeSelector extends StatelessWidget {
  const _ModalidadeSelector({required this.nome, required this.onTap});
  final String nome;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.c.surfaceContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.c.primary.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.sports_martial_arts_rounded,
                color: context.c.primary,
                size: 19,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  nome,
                  style: TextStyle(
                    color: context.c.onSurface,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.expand_more_rounded,
                color: context.c.onSurfaceVariant,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModalidadePickerSheet extends StatelessWidget {
  const _ModalidadePickerSheet({
    required this.modalidades,
    required this.selecionadaId,
  });
  final List<Map<String, dynamic>> modalidades;
  final String? selecionadaId;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.c.surfaceContainer,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: context.c.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.l10n.fxModality,
                style: TextStyle(
                  color: context.c.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: modalidades.length,
              itemBuilder: (_, i) {
                final m = modalidades[i];
                final id = m['id']?.toString();
                final selected = id == selecionadaId;
                return ListTile(
                  onTap: () => Navigator.pop(context, id),
                  leading: Icon(
                    Icons.sports_martial_arts_rounded,
                    color: selected
                        ? context.c.primary
                        : context.c.onSurfaceVariant,
                    size: 20,
                  ),
                  title: Text(
                    m['nome']?.toString() ?? '',
                    style: TextStyle(
                      color: selected ? context.c.primary : context.c.onSurface,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  trailing: selected
                      ? Icon(
                          Icons.check_rounded,
                          color: context.c.primary,
                          size: 20,
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cards de resumo
// ─────────────────────────────────────────────────────────────────────────────

class _ResumoModalidade extends StatelessWidget {
  const _ResumoModalidade({required this.faixas, required this.alunos});
  final int? faixas;
  final int? alunos;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _ResumoCard(
              icon: Icons.layers_rounded,
              valor: faixas?.toString() ?? '—',
              label: context.l10n.fxBeltsCount(faixas ?? 0),
            ),
          ),
          if (alunos != null) ...[
            const SizedBox(width: 10),
            Expanded(
              child: _ResumoCard(
                icon: Icons.groups_rounded,
                valor: '$alunos',
                label: context.l10n.fxStudentsInModality,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResumoCard extends StatelessWidget {
  const _ResumoCard({
    required this.icon,
    required this.valor,
    required this.label,
  });
  final IconData icon;
  final String valor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.c.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.c.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: context.c.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: context.c.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  valor,
                  style: TextStyle(
                    color: context.c.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: context.c.onSurfaceVariant,
                    fontSize: 11,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card de faixa
// ─────────────────────────────────────────────────────────────────────────────

Color _parseCorFaixa(String? hex) {
  try {
    if (hex == null || hex.isEmpty) return Colors.grey;
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  } catch (_) {
    return Colors.grey;
  }
}

class _FaixaCard extends StatelessWidget {
  const _FaixaCard({
    required this.faixa,
    required this.alunos,
    required this.onEdit,
    required this.onDelete,
  });
  final Map<String, dynamic> faixa;
  final int? alunos;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cor = _parseCorFaixa(faixa['cor']?.toString());
    final lum = cor.computeLuminance();
    final ordem = faixa['ordem'] as int? ?? 0;
    final meses = faixa['requisitosMesesMinimos'] as int? ?? 0;
    final presencas = faixa['requisitosPresencasMinimas'] as int? ?? 0;
    final descricao = faixa['descricao']?.toString() ?? '';

    // Barra lateral: clareia faixas muito escuras para não sumir no fundo.
    final corBarra = lum < 0.12 ? Color.lerp(cor, Colors.white, 0.3)! : cor;
    // Badge: contorno neutro p/ preta, a própria cor p/ demais.
    final corBadgeBorda = lum < 0.12 ? context.c.onSurfaceVariant : cor;
    final corBadgeTexto = lum > 0.6 ? Colors.black : cor;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.c.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.c.outline),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: corBarra),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: cor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: corBadgeBorda,
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$ordem',
                            style: TextStyle(
                              color: corBadgeTexto,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            faixa['nome']?.toString() ?? '',
                            style: TextStyle(
                              color: context.c.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: onEdit,
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.edit_rounded,
                            color: context.c.primary,
                            size: 19,
                          ),
                          tooltip: context.l10n.commonEdit,
                        ),
                        PopupMenuButton<String>(
                          color: context.c.surfaceContainer,
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: context.c.onSurfaceVariant,
                            size: 20,
                          ),
                          onSelected: (v) {
                            if (v == 'editar') onEdit();
                            if (v == 'excluir') onDelete();
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'editar',
                              child: Text(
                                context.l10n.commonEdit,
                                style: TextStyle(color: context.c.onSurface),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'excluir',
                              child: Text(
                                context.l10n.commonDelete,
                                style: TextStyle(color: context.sem.danger),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (meses > 0)
                            _Chip(
                              Icons.calendar_month_rounded,
                              context.l10n.fxMinMonths(meses),
                              context.sem.warning,
                            ),
                          if (presencas > 0)
                            _Chip(
                              Icons.check_circle_outline_rounded,
                              context.l10n.fxMinAttendances(presencas),
                              context.sem.success,
                            ),
                          if (meses == 0 && presencas == 0)
                            _Chip(
                              Icons.remove_circle_outline_rounded,
                              context.l10n.fxNoMinReq,
                              context.c.onSurfaceVariant,
                            ),
                          if (alunos != null)
                            _Chip(
                              Icons.person_outline_rounded,
                              context.l10n.fxStudentsCount(alunos ?? 0),
                              context.c.onSurfaceVariant,
                            ),
                        ],
                      ),
                    ),
                    if (descricao.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          descricao,
                          style: TextStyle(
                            color: context.c.onSurfaceVariant,
                            fontSize: 12,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.icon, this.text, this.color);
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Estados auxiliares
// ─────────────────────────────────────────────────────────────────────────────

class _SkeletonLista extends StatelessWidget {
  const _SkeletonLista();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => Container(
        height: 78,
        decoration: BoxDecoration(
          color: context.c.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.c.outline),
        ),
      ),
    );
  }
}

class _EstadoVazio extends StatelessWidget {
  const _EstadoVazio({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    this.acao,
  });
  final IconData icon;
  final String titulo;
  final String subtitulo;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: context.c.onSurfaceVariant, size: 50),
            const SizedBox(height: 14),
            Text(
              titulo,
              style: TextStyle(
                color: context.c.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitulo,
              style: TextStyle(
                color: context.c.onSurfaceVariant,
                fontSize: 12.5,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            if (acao != null) ...[const SizedBox(height: 18), acao!],
          ],
        ),
      ),
    );
  }
}

class _EstadoErro extends StatelessWidget {
  const _EstadoErro({required this.mensagem, required this.onRetry});
  final String mensagem;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: context.sem.danger,
              size: 50,
            ),
            const SizedBox(height: 14),
            Text(
              mensagem,
              style: TextStyle(color: context.c.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh_rounded),
              label: Text(context.l10n.commonRetry),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.c.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Formulário (criar / editar)
// ─────────────────────────────────────────────────────────────────────────────

class _FaixaFormSheet extends StatefulWidget {
  const _FaixaFormSheet({
    required this.academiaId,
    required this.modalidadeId,
    required this.onSalvo,
    required this.proximaOrdem,
    this.faixa,
  });

  final String academiaId;
  final String modalidadeId;
  final Map<String, dynamic>? faixa;
  final int proximaOrdem;
  final VoidCallback onSalvo;

  @override
  State<_FaixaFormSheet> createState() => _FaixaFormSheetState();
}

class _FaixaFormSheetState extends State<_FaixaFormSheet> {
  AppLocalizations get _l => context.l10n;
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _mesesCtrl = TextEditingController();
  final _presencasCtrl = TextEditingController();
  final _ordemCtrl = TextEditingController();
  String _cor = '#FF0000';
  bool _salvando = false;

  static const _cores = [
    '#FFFFFF',
    '#F5F5DC',
    '#FFFF00',
    '#FFA500',
    '#008000',
    '#0000FF',
    '#8B00FF',
    '#8B4513',
    '#FF0000',
    '#000000',
  ];

  @override
  void initState() {
    super.initState();
    final f = widget.faixa;
    if (f != null) {
      _nomeCtrl.text = f['nome']?.toString() ?? '';
      _descCtrl.text = f['descricao']?.toString() ?? '';
      _mesesCtrl.text = (f['requisitosMesesMinimos'] as int? ?? 0).toString();
      _presencasCtrl.text = (f['requisitosPresencasMinimas'] as int? ?? 0)
          .toString();
      _ordemCtrl.text = (f['ordem'] as int? ?? 1).toString();
      _cor = f['cor']?.toString() ?? '#FF0000';
    } else {
      _mesesCtrl.text = '0';
      _presencasCtrl.text = '0';
      _ordemCtrl.text = widget.proximaOrdem.toString();
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _descCtrl.dispose();
    _mesesCtrl.dispose();
    _presencasCtrl.dispose();
    _ordemCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      final data = {
        'modalidadeId': widget.modalidadeId,
        'nome': _nomeCtrl.text.trim(),
        'cor': _cor,
        'ordem': int.tryParse(_ordemCtrl.text.trim()) ?? 1,
        'requisitosMesesMinimos': int.tryParse(_mesesCtrl.text.trim()) ?? 0,
        'requisitosPresencasMinimas':
            int.tryParse(_presencasCtrl.text.trim()) ?? 0,
        'descricao': _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
      };
      if (widget.faixa != null) {
        await firestoreService.updateFaixa(
          widget.academiaId,
          widget.faixa!['id'].toString(),
          data,
        );
      } else {
        await firestoreService.addFaixa(widget.academiaId, data);
      }
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSalvo();
    } catch (_) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_l.fxSaveError),
          backgroundColor: context.sem.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String? _validarInteiroNaoNegativo(String? v) {
    if (v == null || v.trim().isEmpty) return _l.fxEnterZeroOrMore;
    final n = int.tryParse(v.trim());
    if (n == null) return _l.fxNumbersOnly;
    if (n < 0) return _l.fxNotNegative;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.faixa != null;
    return Container(
      decoration: BoxDecoration(
        color: context.c.surfaceContainer,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: context.c.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: context.c.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.military_tech_rounded,
                      color: context.c.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEdit ? _l.fxEditTitle : _l.fxNewBelt,
                      style: TextStyle(
                        color: context.c.onSurface,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: context.c.onSurfaceVariant,
                      size: 22,
                    ),
                    tooltip: _l.commonClose,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _Label(_l.fxNameField),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nomeCtrl,
                style: TextStyle(color: context.c.onSurface),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? _l.commonRequiredField
                    : null,
                decoration: _deco(_l.fxNameHint),
              ),
              const SizedBox(height: 16),

              _Label(_l.fxOrder),
              const SizedBox(height: 6),
              SizedBox(
                width: 120,
                child: TextFormField(
                  controller: _ordemCtrl,
                  style: TextStyle(color: context.c.onSurface),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    if (n == null) return _l.fxInvalid;
                    if (n < 1) return _l.fxMin1;
                    return null;
                  },
                  decoration: _deco('1'),
                ),
              ),
              const SizedBox(height: 4),
              _Helper(_l.fxOrderHint),
              const SizedBox(height: 18),

              _Label(_l.fxGradCriteria),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, c) {
                  final campoMeses = _CampoCriterio(
                    controller: _mesesCtrl,
                    titulo: _l.fxMinTimeMonths,
                    hint: '0',
                    helper: _l.fxMinTimeMonthsHint,
                    validator: _validarInteiroNaoNegativo,
                  );
                  final campoPresencas = _CampoCriterio(
                    controller: _presencasCtrl,
                    titulo: _l.fxMinAttendancesField,
                    hint: '0',
                    helper: _l.fxMinAttendancesHint,
                    validator: _validarInteiroNaoNegativo,
                  );
                  if (c.maxWidth < 340) {
                    return Column(
                      children: [
                        campoMeses,
                        const SizedBox(height: 14),
                        campoPresencas,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: campoMeses),
                      const SizedBox(width: 12),
                      Expanded(child: campoPresencas),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              _Helper(_l.fxZeroNoMin),
              const SizedBox(height: 18),

              _Label(_l.commonDescriptionOptional),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descCtrl,
                style: TextStyle(color: context.c.onSurface),
                maxLines: 3,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: _deco(_l.fxDescHint),
              ),
              const SizedBox(height: 18),

              _Label(_l.fxBeltColor),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _cores.map((hex) {
                  final selected = hex == _cor;
                  final color = _parseCorFaixa(hex);
                  return GestureDetector(
                    onTap: () => setState(() => _cor = hex),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? context.c.primary
                              : context.c.outline,
                          width: selected ? 3 : 1.5,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: context.c.primary.withValues(
                                    alpha: 0.45,
                                  ),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: selected
                          ? Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: color.computeLuminance() > 0.5
                                  ? Colors.black
                                  : Colors.white,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _salvando ? null : _salvar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.c.primary,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: context.c.primary.withValues(
                      alpha: 0.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _salvando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : Text(
                          isEdit ? _l.sdSaveChanges : _l.fxCreateBtn,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _deco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      color: context.c.onSurfaceVariant.withValues(alpha: 0.6),
      fontSize: 13,
    ),
    filled: true,
    fillColor: context.c.surface,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: context.c.outline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: context.c.outline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: context.c.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: context.sem.danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: context.sem.danger, width: 1.5),
    ),
  );
}

class _CampoCriterio extends StatelessWidget {
  const _CampoCriterio({
    required this.controller,
    required this.titulo,
    required this.hint,
    required this.helper,
    required this.validator,
  });
  final TextEditingController controller;
  final String titulo;
  final String hint;
  final String helper;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: TextStyle(
            color: context.c.onSurface,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          style: TextStyle(color: context.c.onSurface),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: context.c.onSurfaceVariant.withValues(alpha: 0.6),
              fontSize: 13,
            ),
            filled: true,
            fillColor: context.c.surface,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.c.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.c.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.c.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.sem.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.sem.danger, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 4),
        _Helper(helper),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: context.c.onSurface,
      fontSize: 13.5,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _Helper extends StatelessWidget {
  const _Helper(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: context.c.onSurfaceVariant,
      fontSize: 11,
      height: 1.3,
    ),
  );
}
