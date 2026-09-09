import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;

import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/firestore_service.dart';
import '../../core/modalidade_icones.dart';
import 'widgets/modalidade_avatar.dart';

/// Recorta 1:1 (central) e reduz para 256px. Roda em isolate via [compute].
Uint8List? _processarImagemModalidade(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  final lado = decoded.width < decoded.height ? decoded.width : decoded.height;
  final cortada = img.copyCrop(
    decoded,
    x: (decoded.width - lado) ~/ 2,
    y: (decoded.height - lado) ~/ 2,
    width: lado,
    height: lado,
  );
  final redim = img.copyResize(cortada, width: 256, height: 256);
  return img.encodePng(redim);
}

enum _Filtro { todas, ativas, inativas }

class AdminModalidadesScreen extends StatefulWidget {
  const AdminModalidadesScreen({super.key});

  @override
  State<AdminModalidadesScreen> createState() => _AdminModalidadesScreenState();
}

class _AdminModalidadesScreenState extends State<AdminModalidadesScreen> {
  List<Map<String, dynamic>> _modalidades = [];
  bool _loading = true;
  bool _erro = false;
  String? _academiaId;

  final _buscaCtrl = TextEditingController();
  String _busca = '';
  _Filtro _filtro = _Filtro.todas;
  bool _ordAsc = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = false;
    });
    try {
      final user = await AuthStorage.getUser();
      _academiaId = user?.academiaId;
      if (_academiaId == null || _academiaId!.isEmpty) {
        setState(() {
          _loading = false;
          _erro = true;
        });
        return;
      }
      final list = await firestoreService.getModalidades(_academiaId!);
      if (mounted) {
        setState(() {
          _modalidades = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _erro = true;
        });
      }
    }
  }

  int get _totalAtivas => _modalidades.where((m) => m['ativo'] == true).length;
  int get _totalInativas => _modalidades.length - _totalAtivas;

  List<Map<String, dynamic>> get _visiveis {
    Iterable<Map<String, dynamic>> r = _modalidades;
    switch (_filtro) {
      case _Filtro.ativas:
        r = r.where((m) => m['ativo'] == true);
      case _Filtro.inativas:
        r = r.where((m) => m['ativo'] != true);
      case _Filtro.todas:
        break;
    }
    final q = _busca.trim().toLowerCase();
    if (q.isNotEmpty) {
      r = r.where(
        (m) => (m['nome'] ?? '').toString().toLowerCase().contains(q),
      );
    }
    final list = r.toList()
      ..sort((a, b) {
        final cmp = (a['nome'] ?? '').toString().toLowerCase().compareTo(
          (b['nome'] ?? '').toString().toLowerCase(),
        );
        return _ordAsc ? cmp : -cmp;
      });
    return list;
  }

  Future<void> _toggle(Map<String, dynamic> m) async {
    final ativo = m['ativo'] == true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text(
          '${ativo ? 'Desativar' : 'Ativar'} "${m['nome']}"?',
          style: TextStyle(color: kText1, fontWeight: FontWeight.w800),
        ),
        content: Text(
          ativo
              ? 'Ela deixará de aparecer nas telas de turmas, faixas e cadastro de alunos, mas não será excluída.'
              : 'Esta modalidade voltará a aparecer em todas as telas operacionais.',
          style: TextStyle(color: kText2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: TextStyle(color: kText2)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              ativo ? 'Desativar' : 'Ativar',
              style: TextStyle(
                color: ativo ? kWarning : kSuccess,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true || _academiaId == null) return;
    try {
      await firestoreService.toggleModalidadeAtivo(
        _academiaId!,
        m['id'] as String,
      );
      await _carregar();
    } catch (_) {
      _snack('Não foi possível alterar a modalidade.', erro: true);
    }
  }

  Future<void> _excluir(Map<String, dynamic> m) async {
    if (_academiaId == null) return;
    final id = (m['id'] ?? '').toString();
    final nome = (m['nome'] ?? '').toString();

    // Guarda: não exclui modalidade com turmas ou faixas vinculadas.
    int vinculos = 0;
    try {
      final res = await Future.wait([
        firestoreService.getTurmas(_academiaId!),
        firestoreService.getFaixas(_academiaId!),
      ]);
      final turmas = res[0];
      final faixas = res[1];
      vinculos =
          turmas.where((t) {
            final tid = (t['modalidadeId'] ?? '').toString();
            final tnome = (t['modalidadeNome'] ?? t['nome_modalidade'] ?? '')
                .toString();
            return tid == id || (tnome.isNotEmpty && tnome == nome);
          }).length +
          faixas
              .where((f) => (f['modalidadeId'] ?? '').toString() == id)
              .length;
    } catch (_) {
      _snack(
        'Não foi possível verificar os vínculos da modalidade.',
        erro: true,
      );
      return;
    }
    if (!mounted) return;

    if (vinculos > 0) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: kSurface,
          title: Text(
            'Não é possível excluir',
            style: TextStyle(color: kText1, fontWeight: FontWeight.w800),
          ),
          content: Text(
            'A modalidade "$nome" possui turmas ou faixas vinculadas. '
            'Você pode desativá-la — assim ela some das telas operacionais '
            'sem perder os dados.',
            style: TextStyle(color: kText2),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Entendi', style: TextStyle(color: kPrimary)),
            ),
          ],
        ),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text(
          'Excluir "$nome"?',
          style: TextStyle(color: kText1, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Essa ação não poderá ser desfeita.',
          style: TextStyle(color: kText2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: TextStyle(color: kText2)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Excluir',
              style: TextStyle(color: kDanger, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await firestoreService.deleteModalidade(_academiaId!, id);
      await _carregar();
      _snack('Modalidade excluída.');
    } catch (_) {
      _snack('Não foi possível excluir a modalidade.', erro: true);
    }
  }

  Future<void> _abrirForm({Map<String, dynamic>? modalidade}) async {
    if (_academiaId == null) return;
    final salvou = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      builder: (_) => _ModalidadeFormSheet(
        academiaId: _academiaId!,
        modalidade: modalidade,
      ),
    );
    if (salvou == true) await _carregar();
  }

  void _snack(String msg, {bool erro = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: erro ? kDanger : kSuccess,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: kText1, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const _SkeletonLista()
            : _erro
            ? _EstadoErro(onRetry: _carregar)
            : RefreshIndicator(
                onRefresh: _carregar,
                color: kPrimary,
                child: _conteudo(),
              ),
      ),
    );
  }

  Widget _conteudo() {
    final visiveis = _visiveis;
    final semNada = _modalidades.isEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      children: [
        _Cabecalho(onNova: () => _abrirForm()),
        const SizedBox(height: 8),
        const _CardInfo(),
        const SizedBox(height: 14),
        _Resumo(
          total: _modalidades.length,
          ativas: _totalAtivas,
          inativas: _totalInativas,
        ),
        const SizedBox(height: 14),
        if (!semNada) ...[
          _BuscaField(
            controller: _buscaCtrl,
            onChanged: (v) => setState(() => _busca = v),
          ),
          const SizedBox(height: 12),
          _BarraFiltros(
            filtro: _filtro,
            total: _modalidades.length,
            ativas: _totalAtivas,
            inativas: _totalInativas,
            ordAsc: _ordAsc,
            onFiltro: (f) => setState(() => _filtro = f),
            onOrdenar: () => setState(() => _ordAsc = !_ordAsc),
          ),
          const SizedBox(height: 12),
        ],
        if (semNada)
          _EstadoVazio(onNova: () => _abrirForm())
        else if (visiveis.isEmpty)
          const _SemResultados()
        else
          ...visiveis.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ModalidadeCard(
                m: m,
                onToggle: () => _toggle(m),
                onEditar: () => _abrirForm(modalidade: m),
                onExcluir: () => _excluir(m),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.onNova});
  final VoidCallback onNova;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Modalidades',
                style: TextStyle(
                  color: kText1,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Gerencie as modalidades da sua academia.',
                style: TextStyle(color: kText2, fontSize: 12.5, height: 1.3),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Semantics(
          button: true,
          label: 'Nova modalidade',
          child: Material(
            color: kPrimary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onNova,
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.add_rounded, color: Colors.black, size: 22),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CardInfo extends StatelessWidget {
  const _CardInfo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E40AF).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: const Color(0xFF60A5FA),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Modalidades ativas aparecem na gestão de faixas, turmas e demais '
              'telas. Inativas ficam ocultas, mas não são excluídas.',
              style: TextStyle(color: kText2, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _Resumo extends StatelessWidget {
  const _Resumo({
    required this.total,
    required this.ativas,
    required this.inativas,
  });
  final int total;
  final int ativas;
  final int inativas;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _MiniStat(valor: total, label: 'Modalidades', cor: kText1),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MiniStat(valor: ativas, label: 'Ativas', cor: kSuccess),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MiniStat(
              valor: inativas,
              label: 'Inativas',
              cor: inativas > 0 ? kWarning : kText2,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.valor,
    required this.label,
    required this.cor,
  });
  final int valor;
  final String label;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$valor',
            style: TextStyle(
              color: cor,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: kText2, fontSize: 11, height: 1.2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _BuscaField extends StatelessWidget {
  const _BuscaField({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(color: kText1, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Buscar modalidade...',
        hintStyle: TextStyle(color: kText2, fontSize: 14),
        prefixIcon: Icon(Icons.search_rounded, color: kText2, size: 20),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(Icons.close_rounded, color: kText2, size: 18),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
        filled: true,
        fillColor: kSurface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kPrimary, width: 1.5),
        ),
      ),
    );
  }
}

class _BarraFiltros extends StatelessWidget {
  const _BarraFiltros({
    required this.filtro,
    required this.total,
    required this.ativas,
    required this.inativas,
    required this.ordAsc,
    required this.onFiltro,
    required this.onOrdenar,
  });
  final _Filtro filtro;
  final int total;
  final int ativas;
  final int inativas;
  final bool ordAsc;
  final ValueChanged<_Filtro> onFiltro;
  final VoidCallback onOrdenar;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('Todas ($total)', _Filtro.todas),
                const SizedBox(width: 8),
                _chip('Ativas ($ativas)', _Filtro.ativas),
                const SizedBox(width: 8),
                _chip('Inativas ($inativas)', _Filtro.inativas),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: kSurface,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onOrdenar,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_vert_rounded, color: kText2, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    ordAsc ? 'A–Z' : 'Z–A',
                    style: TextStyle(
                      color: kText2,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, _Filtro f) {
    final sel = f == filtro;
    return Semantics(
      button: true,
      selected: sel,
      child: Material(
        color: sel ? kPrimary : kSurface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => onFiltro(f),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: sel ? kPrimary : kBorder),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: sel ? Colors.black : kText2,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModalidadeCard extends StatelessWidget {
  const _ModalidadeCard({
    required this.m,
    required this.onToggle,
    required this.onEditar,
    required this.onExcluir,
  });
  final Map<String, dynamic> m;
  final VoidCallback onToggle;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  @override
  Widget build(BuildContext context) {
    final ativo = m['ativo'] == true;
    final nome = (m['nome'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          Opacity(
            opacity: ativo ? 1 : 0.5,
            child: ModalidadeAvatar(modalidade: m, size: 44),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: TextStyle(
                    color: ativo ? kText1 : kText2,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  ativo ? 'Ativa' : 'Inativa',
                  style: TextStyle(
                    color: ativo ? kSuccess : kText2,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            label: ativo
                ? 'Desativar modalidade $nome'
                : 'Ativar modalidade $nome',
            child: Transform.scale(
              scale: 0.85,
              child: Switch(
                value: ativo,
                onChanged: (_) => onToggle(),
                activeThumbColor: Colors.white,
                activeTrackColor: kSuccess,
                inactiveThumbColor: kText2,
                inactiveTrackColor: kBorder,
              ),
            ),
          ),
          PopupMenuButton<String>(
            color: kSurface,
            icon: Icon(Icons.more_vert_rounded, color: kText2, size: 20),
            onSelected: (v) {
              if (v == 'editar') onEditar();
              if (v == 'excluir') onExcluir();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'editar',
                child: Text('Editar', style: TextStyle(color: kText1)),
              ),
              PopupMenuItem(
                value: 'excluir',
                child: Text('Excluir', style: TextStyle(color: kDanger)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Estados ─────────────────────────────────────────────────────────────────

class _SkeletonLista extends StatelessWidget {
  const _SkeletonLista();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      children: List.generate(
        6,
        (_) => Container(
          height: 70,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBorder),
          ),
        ),
      ),
    );
  }
}

class _EstadoVazio extends StatelessWidget {
  const _EstadoVazio({required this.onNova});
  final VoidCallback onNova;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Icon(Icons.sports_martial_arts_rounded, color: kText2, size: 50),
          const SizedBox(height: 14),
          Text(
            'Nenhuma modalidade cadastrada.',
            style: TextStyle(
              color: kText1,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Adicione a primeira modalidade da sua academia.',
            style: TextStyle(color: kText2, fontSize: 12.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onNova,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Nova modalidade'),
            style: OutlinedButton.styleFrom(
              foregroundColor: kPrimary,
              side: BorderSide(color: kPrimary.withValues(alpha: 0.6)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SemResultados extends StatelessWidget {
  const _SemResultados();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, color: kText2, size: 46),
          const SizedBox(height: 12),
          Text(
            'Nenhuma modalidade encontrada.',
            style: TextStyle(color: kText2, fontSize: 13.5),
          ),
        ],
      ),
    );
  }
}

class _EstadoErro extends StatelessWidget {
  const _EstadoErro({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: kDanger, size: 48),
            const SizedBox(height: 14),
            Text(
              'Não foi possível carregar as modalidades.',
              style: TextStyle(color: kText2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
              style: OutlinedButton.styleFrom(foregroundColor: kPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Formulário (criar / editar) ─────────────────────────────────────────────

class _ModalidadeFormSheet extends StatefulWidget {
  const _ModalidadeFormSheet({required this.academiaId, this.modalidade});
  final String academiaId;
  final Map<String, dynamic>? modalidade;

  @override
  State<_ModalidadeFormSheet> createState() => _ModalidadeFormSheetState();
}

class _ModalidadeFormSheetState extends State<_ModalidadeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  bool _ativa = true;
  ModalidadeVisualTipo _tipo = ModalidadeVisualTipo.icone;
  String _iconeKey = kModalidadeIconeGenerico;
  String? _imagemB64;
  bool _processando = false;
  bool _salvando = false;

  bool get _isEdit => widget.modalidade != null;

  @override
  void initState() {
    super.initState();
    final m = widget.modalidade;
    if (m != null) {
      _nomeCtrl.text = (m['nome'] ?? '').toString();
      _ativa = m['ativo'] == true;
      final visual = resolverVisualModalidade(m);
      _tipo = visual.tipo;
      _iconeKey = visual.icone.key;
      _imagemB64 = visual.imagemBase64;
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    super.dispose();
  }

  Future<void> _escolherImagem() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      final bytes = res?.files.single.bytes;
      if (bytes == null) return;
      if (bytes.lengthInBytes > 8 * 1024 * 1024) {
        _snack('Imagem muito grande (máximo 8 MB).');
        return;
      }
      setState(() => _processando = true);
      final out = await compute(_processarImagemModalidade, bytes);
      if (!mounted) return;
      setState(() => _processando = false);
      if (out == null) {
        _snack('Não foi possível processar a imagem.');
        return;
      }
      setState(() {
        _imagemB64 = 'data:image/png;base64,${base64Encode(out)}';
        _tipo = ModalidadeVisualTipo.imagem;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _processando = false);
        _snack('Não foi possível selecionar a imagem.');
      }
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: kDanger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final usaImagem =
        _tipo == ModalidadeVisualTipo.imagem &&
        _imagemB64 != null &&
        _imagemB64!.contains(',');
    setState(() => _salvando = true);
    try {
      final data = <String, dynamic>{
        'nome': _nomeCtrl.text.trim(),
        'ativo': _ativa,
        'iconeTipo': usaImagem ? 'imagem' : 'icone',
        'iconeKey': _iconeKey,
        'iconeCor': modalidadeIconePorKey(_iconeKey).corSugerida,
        'iconeImagem': usaImagem ? _imagemB64 : null,
      };
      if (_isEdit) {
        await firestoreService.updateModalidade(
          widget.academiaId,
          widget.modalidade!['id'].toString(),
          data,
        );
      } else {
        await firestoreService.addModalidade(widget.academiaId, data);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _salvando = false);
      _snack('Não foi possível salvar a modalidade.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kSurface,
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
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: kBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEdit ? 'Editar Modalidade' : 'Nova Modalidade',
                      style: TextStyle(
                        color: kText1,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: kText2, size: 22),
                    tooltip: 'Fechar',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text(
                'Nome da modalidade',
                style: TextStyle(
                  color: kText1,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nomeCtrl,
                autofocus: !_isEdit,
                style: TextStyle(color: kText1),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                decoration: _deco('Ex.: Jiu-Jitsu Adulto'),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
                decoration: BoxDecoration(
                  color: kBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Modalidade ativa',
                            style: TextStyle(
                              color: kText1,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Modalidades inativas não aparecem nas telas '
                            'operacionais, mas continuam cadastradas.',
                            style: TextStyle(
                              color: kText2,
                              fontSize: 11,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _ativa,
                      onChanged: (v) => setState(() => _ativa = v),
                      activeThumbColor: Colors.white,
                      activeTrackColor: kSuccess,
                      inactiveThumbColor: kText2,
                      inactiveTrackColor: kBorder,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Identificação visual',
                style: TextStyle(
                  color: kText1,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<ModalidadeVisualTipo>(
                segments: const [
                  ButtonSegment(
                    value: ModalidadeVisualTipo.icone,
                    label: Text('Ícone padrão'),
                    icon: Icon(Icons.grid_view_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: ModalidadeVisualTipo.imagem,
                    label: Text('Enviar imagem'),
                    icon: Icon(Icons.image_rounded, size: 16),
                  ),
                ],
                selected: {_tipo},
                onSelectionChanged: (s) => setState(() => _tipo = s.first),
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  textStyle: WidgetStatePropertyAll(
                    const TextStyle(fontSize: 12.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              if (_tipo == ModalidadeVisualTipo.icone)
                _gridIcones()
              else
                _blocoImagem(),

              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _salvando ? null : _salvar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: kPrimary.withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 15),
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
                          _isEdit ? 'Salvar alterações' : 'Criar Modalidade',
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

  Widget _gridIcones() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: kModalidadeIcones.map((ic) {
        final sel = ic.key == _iconeKey && _tipo == ModalidadeVisualTipo.icone;
        final cor = parseHexCor(ic.corSugerida);
        return GestureDetector(
          onTap: () => setState(() {
            _iconeKey = ic.key;
            _tipo = ModalidadeVisualTipo.icone;
          }),
          child: Semantics(
            button: true,
            selected: sel,
            label: ic.label,
            child: SizedBox(
              width: 66,
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: cor.withValues(alpha: sel ? 0.22 : 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: sel ? kPrimary : kBorder,
                        width: sel ? 2 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(ic.icon, color: cor, size: 24),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ic.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: sel ? kPrimary : kText2,
                      fontSize: 10,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _blocoImagem() {
    final temImg = _imagemB64 != null && _imagemB64!.contains(',');
    return Row(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: kBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: _processando
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : temImg
              ? Image.memory(
                  base64Decode(_imagemB64!.split(',').last),
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) =>
                      Icon(Icons.broken_image_rounded, color: kText2),
                )
              : Icon(
                  Icons.add_photo_alternate_rounded,
                  color: kText2,
                  size: 28,
                ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton.icon(
                onPressed: _processando ? null : _escolherImagem,
                icon: const Icon(Icons.upload_rounded, size: 16),
                label: Text(temImg ? 'Trocar imagem' : 'Escolher da galeria'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kPrimary,
                  side: BorderSide(color: kPrimary.withValues(alpha: 0.6)),
                ),
              ),
              if (temImg)
                TextButton.icon(
                  onPressed: () => setState(() {
                    _imagemB64 = null;
                    _tipo = ModalidadeVisualTipo.icone;
                  }),
                  icon: Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Remover'),
                  style: TextButton.styleFrom(foregroundColor: kDanger),
                ),
              Text(
                'JPG ou PNG. A imagem é recortada em quadrado.',
                style: TextStyle(color: kText2, fontSize: 10.5, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _deco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: kText2.withValues(alpha: 0.6), fontSize: 13),
    filled: true,
    fillColor: kBg,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: kBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: kBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: kPrimary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: kDanger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: kDanger, width: 1.5),
    ),
  );
}
