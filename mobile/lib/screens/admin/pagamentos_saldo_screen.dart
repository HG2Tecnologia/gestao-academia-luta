import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/firestore_service.dart';
import '../../core/payment_request_service.dart';
import '../../l10n/app_localizations.dart';

class PagamentosSaldoScreen extends StatefulWidget {
  const PagamentosSaldoScreen({super.key});

  @override
  State<PagamentosSaldoScreen> createState() => _PagamentosSaldoScreenState();
}

class _PagamentosSaldoScreenState extends State<PagamentosSaldoScreen> {
  String? _academiaId;
  bool _loadingSaldo = true;
  bool _loadingExtrato = true;
  bool _processando = false;
  double? _saldo;
  List<Map<String, dynamic>> _extrato = [];
  final _valorSaqueCtrl = TextEditingController();

  AppLocalizations get _l => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _valorSaqueCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final user = await AuthStorage.getUser();
    _academiaId = user?.academiaId;
    if (_academiaId == null) return;
    await Future.wait([_carregarSaldo(), _carregarExtrato()]);
  }

  Future<void> _carregarSaldo() async {
    if (_academiaId == null) return;
    setState(() => _loadingSaldo = true);
    try {
      final data = await PaymentRequestService.adminRequest(academiaId: _academiaId!, tipo: 'consultarSaldo');
      if (mounted) setState(() => _saldo = (data['saldo'] as num?)?.toDouble() ?? 0.0);
    } catch (_) {
      // mantém o último saldo conhecido em caso de falha de rede
    } finally {
      if (mounted) setState(() => _loadingSaldo = false);
    }
  }

  Future<void> _carregarExtrato() async {
    if (_academiaId == null) return;
    setState(() => _loadingExtrato = true);
    try {
      final data = await PaymentRequestService.adminRequest(
        academiaId: _academiaId!,
        tipo: 'obterExtrato',
        extra: {'offset': 0, 'limit': 30},
      );
      if (mounted) {
        setState(() => _extrato = List<Map<String, dynamic>>.from(
          (data['itens'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? [],
        ));
      }
    } catch (_) {
      // extrato é informativo — falha não bloqueia o resto da tela
    } finally {
      if (mounted) setState(() => _loadingExtrato = false);
    }
  }

  Future<void> _solicitarSaque() async {
    final valor = double.tryParse(_valorSaqueCtrl.text.replaceAll('.', '').replaceAll(',', '.'));
    if (valor == null || valor <= 0) {
      _snack(_l.pagAppValorInvalido, erro: true);
      return;
    }
    if (_saldo != null && valor > _saldo!) {
      _snack(_l.pagAppValorMaiorQueSaldo, erro: true);
      return;
    }

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text(_l.pagAppSaqueDialogTitle, style: TextStyle(color: kText1, fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(_l.pagAppSaqueDialogContaDestino, style: TextStyle(color: kText2, fontSize: 13, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_l.commonCancel, style: TextStyle(color: kText2))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_l.pagAppSaqueDialogConfirmar, style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;

    setState(() => _processando = true);
    try {
      await PaymentRequestService.adminRequest(
        academiaId: _academiaId!,
        tipo: 'solicitarSaque',
        extra: {'valor': valor},
      );
      _valorSaqueCtrl.clear();
      if (mounted) _snack(_l.pagAppSaqueSucesso, erro: false);
      await _carregarSaldo();
    } on PaymentRequestError catch (e) {
      if (mounted) _snack(e.message, erro: true);
    } catch (_) {
      if (mounted) _snack(_l.pagAppSemContaBancaria, erro: true);
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  Future<void> _atualizarStatusSaque(String transferId) async {
    if (_academiaId == null) return;
    try {
      await PaymentRequestService.adminRequest(
        academiaId: _academiaId!,
        tipo: 'verificarStatusSaque',
        extra: {'transferId': transferId},
      );
    } catch (_) {
      // a tela já escuta o documento via stream — uma falha aqui só significa
      // que o status não avançou nesta tentativa.
    }
  }

  void _snack(String msg, {required bool erro}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: erro ? kDanger : kSuccess,
      behavior: SnackBarBehavior.floating,
    ));
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'PENDING':
        return _l.pagAppSaqueStatusPending;
      case 'BANK_PROCESSING':
        return _l.pagAppSaqueStatusBankProcessing;
      case 'DONE':
        return _l.pagAppSaqueStatusDone;
      case 'CANCELLED':
        return _l.pagAppSaqueStatusCancelled;
      case 'FAILED':
        return _l.pagAppSaqueStatusFailed;
      default:
        return status ?? '—';
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'DONE':
        return kSuccess;
      case 'FAILED':
      case 'CANCELLED':
        return kDanger;
      default:
        return kWarning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kSurface,
        foregroundColor: kText1,
        elevation: 0,
        title: Text(_l.pagAppSaldoTitle, style: TextStyle(color: kText1, fontSize: 17, fontWeight: FontWeight.w700)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: kBorder)),
      ),
      body: RefreshIndicator(
        onRefresh: () => Future.wait([_carregarSaldo(), _carregarExtrato()]),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSaldoCard(),
            const SizedBox(height: 24),
            if (_academiaId != null) _buildSaquesHistorico(),
            const SizedBox(height: 24),
            _buildExtratoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSaldoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_l.pagAppSaldoDisponivel, style: TextStyle(color: kText2, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          _loadingSaldo
              ? SizedBox(height: 28, width: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: kPrimary))
              : Text(
                  'R\$ ${(_saldo ?? 0).toStringAsFixed(2).replaceAll('.', ',')}',
                  style: TextStyle(color: kText1, fontSize: 28, fontWeight: FontWeight.w800),
                ),
          const SizedBox(height: 20),
          Container(height: 1, color: kBorder),
          const SizedBox(height: 16),
          TextField(
            controller: _valorSaqueCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [_MoneyFormatter()],
            style: TextStyle(color: kText1, fontSize: 15),
            decoration: InputDecoration(
              labelText: _l.pagAppSaqueDialogValor,
              labelStyle: TextStyle(color: kText2, fontSize: 13),
              prefixIcon: Icon(Icons.attach_money_rounded, color: kText2, size: 18),
              filled: true,
              fillColor: kBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPrimary, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _processando ? null : _solicitarSaque,
              icon: _processando
                  ? SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(Icons.account_balance_rounded, size: 18),
              label: Text(_l.pagAppSaldoSacar, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaquesHistorico() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: firestoreService.streamSaques(_academiaId!),
      builder: (context, snap) {
        final saques = snap.data ?? [];
        if (saques.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_l.pagAppSaqueHistoricoTitle, style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              for (final s in saques) _saqueRow(s),
            ],
          ),
        );
      },
    );
  }

  Widget _saqueRow(Map<String, dynamic> s) {
    final valor = (s['valor'] as num?)?.toDouble() ?? 0.0;
    final status = s['status'] as String?;
    final id = s['id'] as String? ?? s['asaasTransferId'] as String?;
    final pendente = status == 'PENDING' || status == 'BANK_PROCESSING';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}', style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w700)),
                Text(_statusLabel(status), style: TextStyle(color: _statusColor(status), fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (pendente && id != null)
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: kPrimary, size: 20),
              tooltip: _l.pagAppVerificarStatus,
              onPressed: () => _atualizarStatusSaque(id),
            ),
        ],
      ),
    );
  }

  Widget _buildExtratoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(_l.pagAppExtratoTitle, style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w700))),
            if (_loadingExtrato)
              SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary)),
          ]),
          const SizedBox(height: 12),
          if (_extrato.isEmpty && !_loadingExtrato)
            Text(_l.pagAppExtratoVazio, style: TextStyle(color: kText2, fontSize: 13))
          else
            for (final item in _extrato) _extratoRow(item),
        ],
      ),
    );
  }

  Widget _extratoRow(Map<String, dynamic> item) {
    final valor = (item['valor'] as num?)?.toDouble() ?? 0.0;
    final positivo = valor >= 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['descricao'] as String? ?? item['tipo'] as String? ?? '', style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(item['data'] as String? ?? '', style: TextStyle(color: kText2, fontSize: 11)),
              ],
            ),
          ),
          Text(
            '${positivo ? '+' : ''}R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}',
            style: TextStyle(color: positivo ? kSuccess : kDanger, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _MoneyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return next.copyWith(text: '');
    final value = int.tryParse(digits) ?? 0;
    final intPart = value ~/ 100;
    final decPart = value % 100;
    final intStr = intPart == 0
        ? '0'
        : intPart.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    final result = '$intStr,${decPart.toString().padLeft(2, '0')}';
    return TextEditingValue(text: result, selection: TextSelection.collapsed(offset: result.length));
  }
}
