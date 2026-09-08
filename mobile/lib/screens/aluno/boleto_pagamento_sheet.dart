import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/payment_request_service.dart';
import '../../core/constants.dart';
import '../../core/firestore_service.dart';

class BoletoPagamentoSheet extends StatefulWidget {
  final String academiaId;
  final String pagamentoId;
  final double valor;
  final String descricao;
  final String alunoNome;
  final String? alunoCpf;
  final String? alunoEmail;

  const BoletoPagamentoSheet({
    super.key,
    required this.academiaId,
    required this.pagamentoId,
    required this.valor,
    required this.descricao,
    required this.alunoNome,
    this.alunoCpf,
    this.alunoEmail,
  });

  static Future<bool> show(
    BuildContext context, {
    required String academiaId,
    required String pagamentoId,
    required double valor,
    required String descricao,
    required String alunoNome,
    String? alunoCpf,
    String? alunoEmail,
  }) async {
    final pago = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BoletoPagamentoSheet(
        academiaId: academiaId,
        pagamentoId: pagamentoId,
        valor: valor,
        descricao: descricao,
        alunoNome: alunoNome,
        alunoCpf: alunoCpf,
        alunoEmail: alunoEmail,
      ),
    );
    return pago == true;
  }

  @override
  State<BoletoPagamentoSheet> createState() => _BoletoPagamentoSheetState();
}

class _BoletoPagamentoSheetState extends State<BoletoPagamentoSheet> {
  String _estado = 'loading';
  String? _erroMsg;
  String? _bankSlipUrl;
  String? _identificationField;
  String? _dueDate;
  StreamSubscription? _statusSub;

  @override
  void initState() {
    super.initState();
    _criarCobranca();
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    super.dispose();
  }

  Future<void> _criarCobranca() async {
    setState(() { _estado = 'loading'; _erroMsg = null; });
    try {
      final data = await PaymentRequestService.criarCobranca(
        academiaId: widget.academiaId,
        pagamentoId: widget.pagamentoId,
        valor: widget.valor,
        descricao: widget.descricao,
        alunoNome: widget.alunoNome,
        alunoCpf: widget.alunoCpf,
        alunoEmail: widget.alunoEmail,
        billingType: 'BOLETO',
      );

      _bankSlipUrl = data['bankSlipUrl'] as String?;
      _identificationField = data['identificationField'] as String?;
      _dueDate = data['dueDate'] as String?;

      if (mounted) setState(() => _estado = 'boleto');
      _ouvirStatus();
    } on PaymentRequestError catch (e) {
      if (mounted) setState(() { _estado = 'erro'; _erroMsg = e.message; });
    } catch (_) {
      if (mounted) setState(() { _estado = 'erro'; _erroMsg = 'Erro de conexão. Verifique sua internet.'; });
    }
  }

  void _ouvirStatus() {
    _statusSub?.cancel();
    _statusSub = firestoreService
        .streamPagamento(widget.academiaId, widget.pagamentoId)
        .listen((data) {
      if (!mounted) return;
      final status = data?['status'];
      final statusInt = status is int ? status : int.tryParse(status?.toString() ?? '') ?? 0;
      if (statusInt == 1) {
        setState(() => _estado = 'pago');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop(true);
        });
      }
    });
  }

  String get _valorFormatado =>
      'R\$ ${widget.valor.toStringAsFixed(2).replaceAll('.', ',')}';

  String _fmtDueDate(String? d) {
    if (d == null) return '';
    try {
      final parts = d.split('-');
      if (parts.length == 3) return '${parts[2]}/${parts[1]}/${parts[0]}';
    } catch (_) {}
    return d;
  }

  Future<void> _copiarCodigo() async {
    if (_identificationField == null) return;
    await Clipboard.setData(ClipboardData(text: _identificationField!));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Linha digitável copiada!'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _abrirBoleto() async {
    if (_bankSlipUrl == null) return;
    final uri = Uri.parse(_bankSlipUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              if (_estado == 'loading') _buildLoading(),
              if (_estado == 'boleto') _buildBoleto(),
              if (_estado == 'pago') _buildPago(),
              if (_estado == 'erro') _buildErro(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(children: [
          CircularProgressIndicator(color: kPrimary),
          const SizedBox(height: 16),
          Text('Gerando boleto...', style: TextStyle(color: kText2, fontSize: 14)),
        ]),
      );

  Widget _buildBoleto() {
    const boletoColor = Color(0xFF1976D2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: boletoColor.withOpacity(0.12), shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long_rounded, color: boletoColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Pagar via Boleto', style: TextStyle(color: kText1, fontSize: 17, fontWeight: FontWeight.w800)),
              if (_dueDate != null)
                Text('Vencimento: ${_fmtDueDate(_dueDate)}', style: TextStyle(color: kText2, fontSize: 12)),
            ]),
          ),
        ]),
        const SizedBox(height: 20),
        Text(_valorFormatado, style: TextStyle(color: kText1, fontSize: 32, fontWeight: FontWeight.w900)),
        const SizedBox(height: 20),

        if (_identificationField != null) ...[
          Text('LINHA DIGITÁVEL', style: TextStyle(color: kText2, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder),
            ),
            child: Text(
              _identificationField!,
              style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.3),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _copiarCodigo,
              icon: const Icon(Icons.copy_rounded, size: 16, color: boletoColor),
              label: const Text('Copiar Linha Digitável', style: TextStyle(color: boletoColor, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: boletoColor),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],

        if (_bankSlipUrl != null) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _abrirBoleto,
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Visualizar / Imprimir Boleto', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: boletoColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kWarning.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kWarning.withOpacity(0.3)),
          ),
          child: Row(children: [
            Icon(Icons.info_outline_rounded, size: 16, color: kWarning),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'O boleto pode levar até 3 dias úteis para compensar. Você será notificado quando o pagamento for confirmado.',
              style: TextStyle(color: kText2, fontSize: 12, height: 1.4),
            )),
          ]),
        ),
      ],
    );
  }

  Widget _buildPago() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: kSuccess.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(Icons.check_circle_rounded, color: kSuccess, size: 40),
          ),
          const SizedBox(height: 16),
          Text('Pagamento Confirmado!', style: TextStyle(color: kText1, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(_valorFormatado, style: TextStyle(color: kSuccess, fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('Seu boleto foi compensado com sucesso.', style: TextStyle(color: kText2, fontSize: 13)),
        ]),
      );

  Widget _buildErro() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: kDanger.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(Icons.error_outline_rounded, color: kDanger, size: 32),
          ),
          const SizedBox(height: 16),
          Text('Não foi possível gerar o boleto', style: TextStyle(color: kText1, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(_erroMsg ?? 'Erro desconhecido.', textAlign: TextAlign.center, style: TextStyle(color: kText2, fontSize: 13)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _criarCobranca,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tentar Novamente', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ]),
      );
}
