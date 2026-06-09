import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/api_client.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';

class AlunoQrCodeSheet extends StatefulWidget {
  const AlunoQrCodeSheet({super.key});

  @override
  State<AlunoQrCodeSheet> createState() => _AlunoQrCodeSheetState();
}

class _AlunoQrCodeSheetState extends State<AlunoQrCodeSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: kText2,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Meu QR Code'),
                  Tab(text: 'Escanear Academia'),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tab,
              children: const [
                _MeuQrTab(),
                _EscanearTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MeuQrTab extends StatefulWidget {
  const _MeuQrTab();

  @override
  State<_MeuQrTab> createState() => _MeuQrTabState();
}

class _MeuQrTabState extends State<_MeuQrTab> {
  String? _token;
  bool _loading = true;
  bool _erro = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _erro = false; });
    try {
      final user = await AuthStorage.getUser();
      if (user == null) throw Exception('sem usuario');
      final res = await dio.get('/api/presencas/qr/${user.id}');
      final dados = res.data['dados'];
      final token = dados is String ? dados : dados?['token']?.toString();
      if (token == null || token.isEmpty) throw Exception('token vazio');
      if (mounted) setState(() { _token = token; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _erro = true; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: kPrimary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.qr_code_2_rounded, color: kPrimary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Apresente ao professor na entrada',
                    style: TextStyle(color: kText2, fontSize: 12)),
              ),
              IconButton(
                onPressed: _loading ? null : _load,
                icon: Icon(Icons.refresh_rounded, color: kText2, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_erro)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded, color: kDanger, size: 48),
                  const SizedBox(height: 12),
                  Text('Não foi possível gerar o QR Code',
                      style: TextStyle(color: kText2, fontSize: 13), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Tentar novamente'),
                    style: OutlinedButton.styleFrom(foregroundColor: kPrimary),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.18), blurRadius: 28, spreadRadius: 2)],
              ),
              child: QrImageView(
                data: _token!,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'O código expira automaticamente. Toque em ↺ para renovar.',
            style: TextStyle(color: kText2.withOpacity(0.6), fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EscanearTab extends StatefulWidget {
  const _EscanearTab();

  @override
  State<_EscanearTab> createState() => _EscanearTabState();
}

class _EscanearTabState extends State<_EscanearTab> {
  final MobileScannerController _ctrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _processando = false;
  bool? _sucesso;
  String? _mensagem;

  Future<void> _processar(String codigo) async {
    if (_processando) return;
    setState(() { _processando = true; _sucesso = null; _mensagem = null; });
    await _ctrl.stop();

    try {
      final res = await dio.post('/api/presencas/checkin-self');
      final body = res.data as Map<String, dynamic>;
      setState(() {
        _sucesso = body['sucesso'] == true;
        _mensagem = body['mensagem'] ?? 'Presença registrada!';
      });
    } on DioException catch (e) {
      setState(() {
        _sucesso = false;
        _mensagem = e.response?.data?['mensagem'] ?? 'Erro ao registrar presença.';
      });
    }
  }

  Future<void> _reiniciar() async {
    setState(() { _processando = false; _sucesso = null; _mensagem = null; });
    await _ctrl.start();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_processando) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_mensagem == null) ...[
              CircularProgressIndicator(color: kPrimary),
              const SizedBox(height: 16),
              Text('Registrando presença...', style: TextStyle(color: kText2)),
            ] else ...[
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (_sucesso! ? kSuccess : kDanger).withOpacity(0.15),
                ),
                child: Icon(
                  _sucesso! ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: _sucesso! ? kSuccess : kDanger,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(_mensagem!, style: TextStyle(color: kText1, fontSize: 16, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _reiniciar,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Escanear novamente'),
                style: FilledButton.styleFrom(backgroundColor: kPrimary),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                MobileScanner(
                  controller: _ctrl,
                  onDetect: (capture) {
                    final code = capture.barcodes.firstOrNull?.rawValue;
                    if (code != null && code.isNotEmpty) _processar(code);
                  },
                ),
                Center(
                  child: Container(
                    width: 220, height: 220,
                    decoration: BoxDecoration(
                      border: Border.all(color: kPrimary, width: 2.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Aponte para o QR Code da academia na entrada',
            style: TextStyle(color: kText2, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
