import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final MobileScannerController _ctrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _carregando = false;
  Map<String, dynamic>? _info;
  String? _token;
  bool _registrando = false;
  bool? _sucesso;
  String? _mensagemFinal;

  Future<void> _processar(String token) async {
    if (_carregando) return;
    setState(() { _carregando = true; _info = null; _token = null; });
    await _ctrl.stop();

    try {
      final res = await dio.get('/api/presencas/qr-info', queryParameters: {'token': token});
      final dados = res.data['dados'] as Map<String, dynamic>?;
      if (dados == null) throw Exception('sem dados');
      setState(() { _info = dados; _token = token; _carregando = false; });
    } on DioException catch (e) {
      final msg = e.response?.data?['mensagem'] ?? 'Token inválido ou expirado.';
      setState(() { _carregando = false; });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
      );
      await _ctrl.start();
    }
  }

  Future<void> _registrar() async {
    if (_token == null || _registrando) return;
    setState(() { _registrando = true; });
    try {
      final res = await dio.post('/api/presencas/qrcode', data: {'token': _token});
      final body = res.data as Map<String, dynamic>;
      setState(() {
        _sucesso = body['sucesso'] == true;
        _mensagemFinal = body['mensagem'] ?? 'Presença registrada!';
        _registrando = false;
      });
    } on DioException catch (e) {
      setState(() {
        _sucesso = false;
        _mensagemFinal = e.response?.data?['mensagem'] ?? 'Erro ao registrar.';
        _registrando = false;
      });
    }
  }

  Future<void> _reiniciar() async {
    setState(() { _carregando = false; _info = null; _token = null; _sucesso = null; _mensagemFinal = null; _registrando = false; });
    await _ctrl.start();
  }

  Color _parseCor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF888888);
    final clean = hex.replaceAll('#', '');
    return Color(int.tryParse('FF$clean', radix: 16) ?? 0xFF888888);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Registrar presença', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded),
            onPressed: () => _ctrl.toggleTorch(),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Resultado final (após registrar)
    if (_mensagemFinal != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (_sucesso! ? kSuccess : kDanger).withOpacity(0.15),
                ),
                child: Icon(
                  _sucesso! ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: _sucesso! ? kSuccess : kDanger,
                  size: 44,
                ),
              ),
              const SizedBox(height: 20),
              Text(_mensagemFinal!, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _reiniciar,
                  style: FilledButton.styleFrom(backgroundColor: kPrimary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Escanear outro', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Card do aluno (após escanear, antes de registrar)
    if (_info != null) {
      final nome = _info!['nome'] as String? ?? '';
      final faixaNome = _info!['faixaNome'] as String? ?? 'Sem faixa';
      final faixaCor = _parseCor(_info!['faixaCor'] as String?);
      final turmas = (_info!['turmas'] as List? ?? []).cast<String>();
      final totalMes = (_info!['totalPresencasMes'] as num?)?.toInt() ?? 0;
      final temAula = _info!['temAulaAgora'] as bool? ?? false;
      final initials = nome.trim().split(RegExp(r'\s+')).take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: faixaCor.withOpacity(0.4), width: 1.5),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Avatar + faixa
                    Row(
                      children: [
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: faixaCor, width: 2.5),
                            color: kBg,
                          ),
                          child: Center(child: Text(initials, style: TextStyle(color: faixaCor, fontWeight: FontWeight.w800, fontSize: 20))),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(nome, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: faixaCor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                                child: Text(faixaNome, style: TextStyle(color: faixaCor, fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: kBorder, height: 1),
                    const SizedBox(height: 14),
                    // Turmas
                    if (turmas.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.class_rounded, color: kText2, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(turmas.join(', '), style: TextStyle(color: kText1, fontSize: 13))),
                        ],
                      ),
                    const SizedBox(height: 10),
                    // Presenças do mês
                    Row(
                      children: [
                        Icon(Icons.check_circle_outline_rounded, color: kText2, size: 16),
                        const SizedBox(width: 8),
                        Text('$totalMes presenças este mês', style: TextStyle(color: kText1, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: temAula && !_registrando ? _registrar : null,
                  icon: _registrando
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_rounded),
                  label: Text(
                    temAula ? 'Registrar presença' : 'Sem aulas para realizar presenças hoje',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: temAula ? kPrimary : kBorder,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _reiniciar,
                child: Text('Escanear outro', style: TextStyle(color: kText2)),
              ),
            ],
          ),
        ),
      );
    }

    // Scanner (estado inicial)
    return Stack(
      children: [
        if (!_carregando)
          MobileScanner(
            controller: _ctrl,
            onDetect: (capture) {
              final code = capture.barcodes.firstOrNull?.rawValue;
              if (code != null && code.isNotEmpty) _processar(code);
            },
          ),
        if (!_carregando)
          Center(
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: kPrimary, width: 2.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(8)),
                    child: Text('Aponte para o QR Code do aluno', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12), textAlign: TextAlign.center),
                  ),
                ],
              ),
            ),
          ),
        if (_carregando)
          Container(
            color: Colors.black,
            child: Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: kPrimary),
                const SizedBox(height: 16),
                Text('Buscando informações...', style: TextStyle(color: kText2)),
              ],
            )),
          ),
      ],
    );
  }
}
