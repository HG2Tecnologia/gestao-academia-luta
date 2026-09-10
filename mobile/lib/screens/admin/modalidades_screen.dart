import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;

import '../../core/auth_storage.dart';
import '../../core/theme/context_ext.dart';
import '../../l10n/app_localizations.dart';
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
  AppLocalizations get _l => context.l10n;
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
        backgroundColor: context.c.surfaceContainer,
        title: Text(
          '${ativo ? _l.mdlDeactivate : _l.mdlActivate} "${m['nome']}"?',
          style: TextStyle(
            color: context.c.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          ativo ? _l.mdlDeactivateBody : _l.mdlActivateBody,
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
              ativo ? _l.mdlDeactivate : _l.mdlActivate,
              style: TextStyle(
                color: ativo ? context.sem.warning : context.sem.success,
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
      _snack(_l.mdlToggleError, erro: true);
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
      _snack(_l.mdlLinksCheckError, erro: true);
      return;
    }
    if (!mounted) return;

    if (vinculos > 0) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: context.c.surfaceContainer,
          title: Text(
            _l.mdlCannotDeleteTitle,
            style: TextStyle(
              color: context.c.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            _l.mdlCannotDeleteBody(nome),
            style: TextStyle(color: context.c.onSurfaceVariant),
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
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.c.surfaceContainer,
        title: Text(
          _l.mdlDeleteTitle(nome),
          style: TextStyle(
            color: context.c.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          _l.mdlDeleteBody,
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
    if (ok != true) return;
    try {
      await firestoreService.deleteModalidade(_academiaId!, id);
      await _carregar();
      _snack(_l.mdlDeleted);
    } catch (_) {
      _snack(_l.mdlDeleteError, erro: true);
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
        backgroundColor: erro ? context.sem.danger : context.sem.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                color: context.c.primary,
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
                context.l10n.mdlTitle,
                style: TextStyle(
                  color: context.c.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                context.l10n.mdlSubtitle,
                style: TextStyle(
                  color: context.c.onSurfaceVariant,
                  fontSize: 12.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Semantics(
          button: true,
          label: context.l10n.mdlNew,
          child: Material(
            color: context.c.primary,
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
              context.l10n.mdlInfoBanner,
              style: TextStyle(
                color: context.c.onSurfaceVariant,
                fontSize: 12,
                height: 1.4,
              ),
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
            child: _MiniStat(
              valor: total,
              label: context.l10n.mdlTitle,
              cor: context.c.onSurface,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MiniStat(
              valor: ativas,
              label: context.l10n.mdlFilterActive,
              cor: context.sem.success,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MiniStat(
              valor: inativas,
              label: context.l10n.mdlFilterInactive,
              cor: inativas > 0
                  ? context.sem.warning
                  : context.c.onSurfaceVariant,
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
        color: context.c.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.c.outline),
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
            style: TextStyle(
              color: context.c.onSurfaceVariant,
              fontSize: 11,
              height: 1.2,
            ),
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
      style: TextStyle(color: context.c.onSurface, fontSize: 14),
      decoration: InputDecoration(
        hintText: context.l10n.mdlSearchHint,
        hintStyle: TextStyle(color: context.c.onSurfaceVariant, fontSize: 14),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: context.c.onSurfaceVariant,
          size: 20,
        ),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: context.c.onSurfaceVariant,
                  size: 18,
                ),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
        filled: true,
        fillColor: context.c.surfaceContainer,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
                _chip(
                  context,
                  context.l10n.mdlFilterAllCount(total),
                  _Filtro.todas,
                ),
                const SizedBox(width: 8),
                _chip(
                  context,
                  context.l10n.mdlFilterActiveCount(ativas),
                  _Filtro.ativas,
                ),
                const SizedBox(width: 8),
                _chip(
                  context,
                  context.l10n.mdlFilterInactiveCount(inativas),
                  _Filtro.inativas,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: context.c.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onOrdenar,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.c.outline),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.swap_vert_rounded,
                    color: context.c.onSurfaceVariant,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ordAsc ? context.l10n.mdlSortAZ : context.l10n.mdlSortZA,
                    style: TextStyle(
                      color: context.c.onSurfaceVariant,
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

  Widget _chip(BuildContext context, String label, _Filtro f) {
    final sel = f == filtro;
    return Semantics(
      button: true,
      selected: sel,
      child: Material(
        color: sel ? context.c.primary : context.c.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => onFiltro(f),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: sel ? context.c.primary : context.c.outline,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: sel ? Colors.black : context.c.onSurfaceVariant,
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
        color: context.c.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.c.outline),
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
                    color: ativo
                        ? context.c.onSurface
                        : context.c.onSurfaceVariant,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  ativo
                      ? context.l10n.mdlStatusActive
                      : context.l10n.mdlStatusInactive,
                  style: TextStyle(
                    color: ativo
                        ? context.sem.success
                        : context.c.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            label: ativo
                ? context.l10n.mdlA11yDeactivate(nome)
                : context.l10n.mdlA11yActivate(nome),
            child: Transform.scale(
              scale: 0.85,
              child: Switch(
                value: ativo,
                onChanged: (_) => onToggle(),
                activeThumbColor: Colors.white,
                activeTrackColor: context.sem.success,
                inactiveThumbColor: context.c.onSurfaceVariant,
                inactiveTrackColor: context.c.outline,
              ),
            ),
          ),
          PopupMenuButton<String>(
            color: context.c.surfaceContainer,
            icon: Icon(
              Icons.more_vert_rounded,
              color: context.c.onSurfaceVariant,
              size: 20,
            ),
            onSelected: (v) {
              if (v == 'editar') onEditar();
              if (v == 'excluir') onExcluir();
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
            color: context.c.surfaceContainer,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.c.outline),
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
          Icon(
            Icons.sports_martial_arts_rounded,
            color: context.c.onSurfaceVariant,
            size: 50,
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.mdlEmpty,
            style: TextStyle(
              color: context.c.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.mdlEmptyHint,
            style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 12.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onNova,
            icon: Icon(Icons.add_rounded),
            label: Text(context.l10n.mdlNew),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.c.primary,
              side: BorderSide(color: context.c.primary.withValues(alpha: 0.6)),
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
          Icon(
            Icons.search_off_rounded,
            color: context.c.onSurfaceVariant,
            size: 46,
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.mdlNoResults,
            style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 13.5),
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
            Icon(
              Icons.error_outline_rounded,
              color: context.sem.danger,
              size: 48,
            ),
            const SizedBox(height: 14),
            Text(
              context.l10n.mdlLoadError,
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

// ─── Formulário (criar / editar) ─────────────────────────────────────────────

class _ModalidadeFormSheet extends StatefulWidget {
  const _ModalidadeFormSheet({required this.academiaId, this.modalidade});
  final String academiaId;
  final Map<String, dynamic>? modalidade;

  @override
  State<_ModalidadeFormSheet> createState() => _ModalidadeFormSheetState();
}

class _ModalidadeFormSheetState extends State<_ModalidadeFormSheet> {
  AppLocalizations get _l => context.l10n;
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
        _snack(_l.mdlImageTooLarge);
        return;
      }
      setState(() => _processando = true);
      final out = await compute(_processarImagemModalidade, bytes);
      if (!mounted) return;
      setState(() => _processando = false);
      if (out == null) {
        _snack(_l.mdlImageProcessError);
        return;
      }
      setState(() {
        _imagemB64 = 'data:image/png;base64,${base64Encode(out)}';
        _tipo = ModalidadeVisualTipo.imagem;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _processando = false);
        _snack(_l.mdlImagePickError);
      }
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: context.sem.danger,
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
      _snack(_l.mdlSaveError);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: context.c.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEdit ? _l.mdlEditTitle : _l.mdlNewTitle,
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
              const SizedBox(height: 12),

              Text(
                _l.mdlNameField,
                style: TextStyle(
                  color: context.c.onSurface,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nomeCtrl,
                autofocus: !_isEdit,
                style: TextStyle(color: context.c.onSurface),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? _l.commonRequiredField
                    : null,
                decoration: _deco(_l.mdlNameHint),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
                decoration: BoxDecoration(
                  color: context.c.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.c.outline),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _l.mdlActiveToggle,
                            style: TextStyle(
                              color: context.c.onSurface,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _l.mdlActiveToggleSub,
                            style: TextStyle(
                              color: context.c.onSurfaceVariant,
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
                      activeTrackColor: context.sem.success,
                      inactiveThumbColor: context.c.onSurfaceVariant,
                      inactiveTrackColor: context.c.outline,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(
                _l.mdlVisualId,
                style: TextStyle(
                  color: context.c.onSurface,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<ModalidadeVisualTipo>(
                segments: [
                  ButtonSegment(
                    value: ModalidadeVisualTipo.icone,
                    label: Text(_l.mdlDefaultIcon),
                    icon: Icon(Icons.grid_view_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: ModalidadeVisualTipo.imagem,
                    label: Text(_l.mdlUploadImage),
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
                    backgroundColor: context.c.primary,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: context.c.primary.withValues(
                      alpha: 0.5,
                    ),
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
                          _isEdit ? _l.sdSaveChanges : _l.mdlCreateBtn,
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
                        color: sel ? context.c.primary : context.c.outline,
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
                      color: sel
                          ? context.c.primary
                          : context.c.onSurfaceVariant,
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
            color: context.c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.c.outline),
          ),
          clipBehavior: Clip.antiAlias,
          child: _processando
              ? Center(
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
                  errorBuilder: (_, _, _) => Icon(
                    Icons.broken_image_rounded,
                    color: context.c.onSurfaceVariant,
                  ),
                )
              : Icon(
                  Icons.add_photo_alternate_rounded,
                  color: context.c.onSurfaceVariant,
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
                icon: Icon(Icons.upload_rounded, size: 16),
                label: Text(temImg ? _l.mdlChangeImage : _l.mdlChooseGallery),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.c.primary,
                  side: BorderSide(
                    color: context.c.primary.withValues(alpha: 0.6),
                  ),
                ),
              ),
              if (temImg)
                TextButton.icon(
                  onPressed: () => setState(() {
                    _imagemB64 = null;
                    _tipo = ModalidadeVisualTipo.icone;
                  }),
                  icon: Icon(Icons.delete_outline_rounded, size: 16),
                  label: Text(_l.commonRemove),
                  style: TextButton.styleFrom(
                    foregroundColor: context.sem.danger,
                  ),
                ),
              Text(
                _l.mdlImageHint,
                style: TextStyle(
                  color: context.c.onSurfaceVariant,
                  fontSize: 10.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
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
