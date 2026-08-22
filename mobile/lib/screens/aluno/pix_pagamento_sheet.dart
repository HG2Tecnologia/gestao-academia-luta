import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants.dart';
import '../../core/firestore_service.dart';

class PixPagamentoSheet extends StatefulWidget {
  final String academiaId;
  final String pagamentoId;
  final double valor;
  final String descricao;
  final String alunoNome;
  final String? alunoCpf;
  final String? alunoEmail;

  const PixPagamentoSheet({
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
      builder: (_) => PixPagamentoSheet(
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
  State<PixPagamentoSheet> createState() => _PixPagamentoSheetState();
}

class _PixPagamentoSheetState extends State<PixPagamentoSheet> {
  // Estados: loading, qrcode, pago, erro
  String _estado = 'loading';
  String? _erroMsg;
  String? _pixPayload;
  DateTime? _expiracao;
  int _segundosRestantes = 1800; // 30 min

  Timer? _timer;
  StreamSubscription? _statusSub;

  @override
  void initState() {
    super.initState();
    _criarCobranca();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }

  Future<void> _criarCobranca() async {
    setState(() { _estado = 'loading'; _erroMsg = null; });
    try {
      final fn = FirebaseFunctions.instanceFor(region: 'us-central1');
      final result = await fn.httpsCallable('criarCobrancaPix').call({
        'academiaId': widget.academiaId,
        'pagamentoId': widget.pagamentoId,
        'valor': widget.valor,
        'descricao': widget.descricao,
        'alunoNome': widget.alunoNome,
        'alunoCpf': widget.alunoCpf ?? '',
        'alunoEmail': widget.alunoEmail ?? '',
      });

      final data = result.data as Map;
      final payload = data['payload'] as String?;
      if (payload == null || payload.isEmpty) {
        setState(() { _estado = 'erro'; _erroMsg = 'QR Code não gerado. Tente novamente.'; });
        return;
      }

      _pixPayload = payload;

      // Calcula tempo restante até expiração (30 min por padrão)
      final expStr = data['expirationDate'] as String?;
      if (expStr != null) {
        try {
          _expiracao = DateTime.parse(expStr);
          _segundosRestantes = _expiracao!.difference(DateTime.now()).inSeconds;
          if (_segundosRestantes < 0) _segundosRestantes = 0;
        } catch (_) {
          _segundosRestantes = 1800;
        }
      }

      if (mounted) setState(() => _estado = 'qrcode');

      _iniciarTimer();
      _ouvirStatus();
    } on FirebaseFunctionsException catch (e) {
      if (mounted) setState(() { _estado = 'erro'; _erroMsg = e.message ?? 'Erro ao gerar PIX.'; });
    } catch (_) {
      if (mounted) setState(() { _estado = 'erro'; _erroMsg = 'Erro de conexão. Verifique sua internet.'; });
    }
  }

  void _iniciarTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_segundosRestantes > 0) {
          _segundosRestantes--;
        } else {
          _timer?.cancel();
          _estado = 'erro';
          _erroMsg = 'QR Code expirado. Gere um novo.';
        }
      });
    });
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
        _timer?.cancel();
        setState(() => _estado = 'pago');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop(true);
        });
      }
    });
  }

  String get _timerFormatado {
    final min = (_segundosRestantes ~/ 60).toString().padLeft(2, '0');
    final sec = (_segundosRestantes % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  String get _valorFormatado =>
      'R\$ ${widget.valor.toStringAsFixed(2).replaceAll('.', ',')}';

  Future<void> _copiarPix() async {
    if (_pixPayload == null) return;
    await Clipboard.setData(ClipboardData(text: _pixPayload!));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Chave PIX copiada!'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
              if (_estado == 'qrcode') _buildQrCode(),
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
          Text('Gerando QR Code PIX...', style: TextStyle(color: kText2, fontSize: 14)),
        ]),
      );

  Widget _buildQrCode() {
    final expirando = _segundosRestantes < 120;
    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Pagar via PIX', style: TextStyle(color: kText1, fontSize: 17, fontWeight: FontWeight.w800)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: expirando ? kDanger.withOpacity(0.12) : kPrimary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.timer_rounded, size: 14, color: expirando ? kDanger : kPrimary),
              const SizedBox(width: 4),
              Text(
                _timerFormatado,
                style: TextStyle(
                  color: expirando ? kDanger : kPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 4),
        Text(widget.descricao, style: TextStyle(color: kText2, fontSize: 13)),
        const SizedBox(height: 20),

        // Valor
        Text(_valorFormatado, style: TextStyle(color: kText1, fontSize: 32, fontWeight: FontWeight.w900)),
        const SizedBox(height: 20),

        // QR Code
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorder),
          ),
          child: QrImageView(
            data: _pixPayload!,
            version: QrVersions.auto,
            size: 200,
            backgroundColor: Colors.white,
            eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
            dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'Abra o app do seu banco, escolha Pagar com PIX\ne escaneie o QR Code acima.',
          textAlign: TextAlign.center,
          style: TextStyle(color: kText2, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 16),

        // Copiar chave
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _copiarPix,
            icon: Icon(Icons.copy_rounded, size: 16, color: kPrimary),
            label: Text('Copiar Chave PIX', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: kPrimary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'O pagamento é confirmado automaticamente assim que realizado.',
          textAlign: TextAlign.center,
          style: TextStyle(color: kText2, fontSize: 11),
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
          Text('Seu pagamento foi recebido com sucesso.', style: TextStyle(color: kText2, fontSize: 13)),
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
          Text('Não foi possível gerar o PIX', style: TextStyle(color: kText1, fontSize: 16, fontWeight: FontWeight.w700)),
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
