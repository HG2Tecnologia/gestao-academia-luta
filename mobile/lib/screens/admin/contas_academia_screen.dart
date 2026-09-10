import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/auth_storage.dart';
import '../../core/theme/context_ext.dart';
import '../../l10n/app_localizations.dart';
import '../../core/firestore_service.dart';

const _kCategorias = ['Água', 'Luz', 'Aluguel', 'Internet', 'Outros'];

String _catLabel(String c, AppLocalizations l) {
  switch (c) {
    case 'Água':
      return l.caCatWater;
    case 'Luz':
      return l.caCatPower;
    case 'Aluguel':
      return l.caCatRent;
    case 'Internet':
      return l.caCatInternet;
    default:
      return l.caCatOther;
  }
}

class AdminContasAcademiaScreen extends StatefulWidget {
  const AdminContasAcademiaScreen({super.key});

  @override
  State<AdminContasAcademiaScreen> createState() =>
      _AdminContasAcademiaScreenState();
}

class _AdminContasAcademiaScreenState extends State<AdminContasAcademiaScreen> {
  AppLocalizations get _l => context.l10n;
  List<Map<String, dynamic>> _contas = [];
  bool _loading = true;
  String? _erro;
  String? _academiaId;
  String _filtro = 'todas'; // todas | pendente | atrasada | paga

  final _fmtMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _fmtData = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final user = await AuthStorage.getUser();
      _academiaId = user?.academiaId;
      if (_academiaId == null) return;
      final list = await firestoreService.getContasAcademia(_academiaId!);

      final hoje = DateTime.now();
      final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
      for (final c in list) {
        if (c['status'] == 'pendente') {
          final venc = _parseData(c['data_vencimento'] as String?);
          if (venc != null && venc.isBefore(hojeSemHora))
            c['_status_efetivo'] = 'atrasada';
        }
      }

      if (mounted) setState(() => _contas = list);
    } catch (e) {
      if (mounted) setState(() => _erro = _l.caLoadError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  DateTime? _parseData(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    try {
      return DateTime.parse(iso);
    } catch (_) {
      return null;
    }
  }

  String _statusEfetivo(Map<String, dynamic> c) =>
      (c['_status_efetivo'] as String?) ??
      (c['status'] as String? ?? 'pendente');

  List<Map<String, dynamic>> get _contasFiltradas {
    if (_filtro == 'todas') return _contas;
    return _contas.where((c) => _statusEfetivo(c) == _filtro).toList();
  }

  double _somaPendentes() => _contas
      .where(
        (c) => _statusEfetivo(c) != 'paga' && _statusEfetivo(c) != 'cancelada',
      )
      .fold(0.0, (s, c) => s + ((c['valor'] as num?)?.toDouble() ?? 0));

  double _somaAtrasadas() => _contas
      .where((c) => _statusEfetivo(c) == 'atrasada')
      .fold(0.0, (s, c) => s + ((c['valor'] as num?)?.toDouble() ?? 0));

  Future<void> _marcarPaga(Map<String, dynamic> c) async {
    try {
      await firestoreService
          .updateContaAcademia(_academiaId!, c['id'] as String, {
            'status': 'paga',
            'data_pagamento': DateTime.now().toIso8601String().split('T').first,
          });
      _load();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_l.caMarkPaidError)));
    }
  }

  Future<void> _excluir(Map<String, dynamic> c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.c.surfaceContainer,
        title: Text(
          _l.caDeleteTitle,
          style: TextStyle(
            color: context.c.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          _l.caDeleteBody(c['descricao']?.toString() ?? ''),
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
      await firestoreService.deleteContaAcademia(
        _academiaId!,
        c['id'] as String,
      );
      _load();
    } catch (_) {}
  }

  Future<void> _abrirForm({Map<String, dynamic>? conta}) async {
    final descCtrl = TextEditingController(
      text: conta?['descricao'] as String? ?? '',
    );
    final valorCtrl = TextEditingController(
      text: conta != null
          ? ((conta['valor'] as num?)?.toStringAsFixed(2) ?? '')
          : '',
    );
    final obsCtrl = TextEditingController(
      text: conta?['observacoes'] as String? ?? '',
    );
    String categoria = conta?['categoria'] as String? ?? _kCategorias.first;
    DateTime vencimento =
        _parseData(conta?['data_vencimento'] as String?) ?? DateTime.now();
    bool recorrente = conta?['recorrente'] as bool? ?? false;
    bool salvando = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.c.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conta == null ? _l.caNewBill : _l.caEditBill,
                  style: TextStyle(
                    color: context.c.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                _campoTexto(descCtrl, _l.caDescHint),
                const SizedBox(height: 10),
                _campoDropdown(categoria, (v) => setSt(() => categoria = v!)),
                const SizedBox(height: 10),
                _campoTexto(
                  valorCtrl,
                  _l.caAmountHint,
                  keyboard: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: vencimento,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      locale: const Locale('pt', 'BR'),
                    );
                    if (picked != null) setSt(() => vencimento = picked);
                  },
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: context.c.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.c.outline),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          color: context.c.onSurfaceVariant,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _l.caDueOn(_fmtData.format(vencimento)),
                          style: TextStyle(
                            color: context.c.onSurface,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _campoTexto(obsCtrl, _l.sdNotesOptional),
                const SizedBox(height: 6),
                SwitchListTile(
                  value: recorrente,
                  onChanged: (v) => setSt(() => recorrente = v),
                  activeColor: context.c.primary,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _l.caRecurring,
                    style: TextStyle(
                      color: context.c.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: salvando
                        ? null
                        : () async {
                            if (descCtrl.text.trim().isEmpty ||
                                valorCtrl.text.trim().isEmpty)
                              return;
                            setSt(() => salvando = true);
                            final valor =
                                double.tryParse(
                                  valorCtrl.text.trim().replaceAll(',', '.'),
                                ) ??
                                0;
                            final data = {
                              'descricao': descCtrl.text.trim(),
                              'categoria': categoria,
                              'valor': valor,
                              'data_vencimento': vencimento
                                  .toIso8601String()
                                  .split('T')
                                  .first,
                              'observacoes': obsCtrl.text.trim().isEmpty
                                  ? null
                                  : obsCtrl.text.trim(),
                              'recorrente': recorrente,
                            };
                            try {
                              if (conta == null) {
                                await firestoreService.addContaAcademia(
                                  _academiaId!,
                                  data,
                                );
                              } else {
                                await firestoreService.updateContaAcademia(
                                  _academiaId!,
                                  conta['id'] as String,
                                  data,
                                );
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                              _load();
                            } catch (_) {
                              setSt(() => salvando = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.c.primary,
                      foregroundColor: context.c.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: salvando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            conta == null ? _l.caSaveBill : _l.sdSaveChanges,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _campoTexto(
    TextEditingController ctrl,
    String hint, {
    TextInputType? keyboard,
  }) => TextField(
    controller: ctrl,
    keyboardType: keyboard,
    style: TextStyle(color: context.c.onSurface),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: context.c.onSurfaceVariant, fontSize: 14),
      filled: true,
      fillColor: context.c.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        borderSide: BorderSide(color: context.c.primary),
      ),
    ),
  );

  Widget _campoDropdown(String valor, ValueChanged<String?> onChanged) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: context.c.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.c.outline),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: valor,
            dropdownColor: context.c.surfaceContainer,
            isExpanded: true,
            items: _kCategorias
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(
                      _catLabel(c, _l),
                      style: TextStyle(color: context.c.onSurface),
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      );

  Color _corStatus(String status) {
    switch (status) {
      case 'paga':
        return context.sem.success;
      case 'atrasada':
        return context.sem.danger;
      case 'cancelada':
        return context.c.onSurfaceVariant;
      default:
        return context.sem.warning;
    }
  }

  String _labelStatus(String status) {
    switch (status) {
      case 'paga':
        return _l.caStPaid;
      case 'atrasada':
        return _l.caStOverdue;
      case 'cancelada':
        return _l.caStCancelled;
      default:
        return _l.caStPending;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.surface,
      appBar: AppBar(
        backgroundColor: context.c.surfaceContainer,
        foregroundColor: context.c.onSurface,
        elevation: 0,
        title: Text(
          _l.caTitle,
          style: TextStyle(
            color: context.c.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirForm(),
        backgroundColor: context.c.primary,
        child: Icon(Icons.add, color: context.c.onPrimary),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: context.c.primary))
          : _erro != null
          ? Center(
              child: Text(_erro!, style: TextStyle(color: context.sem.danger)),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: context.c.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _resumoCard(
                          _l.caToPay,
                          _somaPendentes(),
                          context.sem.warning,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _resumoCard(
                          _l.caOverdue,
                          _somaAtrasadas(),
                          context.sem.danger,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _chipFiltro('todas', _l.caFilterAll),
                        _chipFiltro('pendente', _l.caFilterPending),
                        _chipFiltro('atrasada', _l.caFilterOverdue),
                        _chipFiltro('paga', _l.caFilterPaid),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_contasFiltradas.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              color: context.c.onSurfaceVariant,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _l.caEmpty,
                              style: TextStyle(
                                color: context.c.onSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._contasFiltradas.map(_contaCard),
                ],
              ),
            ),
    );
  }

  Widget _resumoCard(String label, double valor, Color cor) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: context.c.surfaceContainer,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: context.c.outline),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.c.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _fmtMoeda.format(valor),
          style: TextStyle(
            color: cor,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );

  Widget _chipFiltro(String valor, String label) {
    final selecionado = _filtro == valor;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _filtro = valor),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selecionado ? context.c.primary : context.c.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selecionado ? context.c.primary : context.c.outline,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selecionado
                  ? context.c.onPrimary
                  : context.c.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _contaCard(Map<String, dynamic> c) {
    final status = _statusEfetivo(c);
    final venc = _parseData(c['data_vencimento'] as String?);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.c.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.c.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        c['descricao'] as String? ?? '',
                        style: TextStyle(
                          color: context.c.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _corStatus(status).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _labelStatus(status),
                        style: TextStyle(
                          color: _corStatus(status),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _l.caCategoryDueOn(
                    _catLabel((c['categoria'] ?? '').toString(), _l),
                    venc != null ? _fmtData.format(venc) : '-',
                  ),
                  style: TextStyle(
                    color: context.c.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _fmtMoeda.format((c['valor'] as num?)?.toDouble() ?? 0),
                  style: TextStyle(
                    color: context.c.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            color: context.c.surfaceContainer,
            icon: Icon(
              Icons.more_vert_rounded,
              color: context.c.onSurfaceVariant,
            ),
            onSelected: (v) {
              if (v == 'pagar') _marcarPaga(c);
              if (v == 'editar') _abrirForm(conta: c);
              if (v == 'excluir') _excluir(c);
            },
            itemBuilder: (_) => [
              if (status != 'paga')
                PopupMenuItem(
                  value: 'pagar',
                  child: Text(
                    _l.caMarkAsPaid,
                    style: TextStyle(color: context.sem.success),
                  ),
                ),
              PopupMenuItem(
                value: 'editar',
                child: Text(
                  _l.commonEdit,
                  style: TextStyle(color: context.c.onSurface),
                ),
              ),
              PopupMenuItem(
                value: 'excluir',
                child: Text(
                  _l.commonDelete,
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
