import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/firestore_service.dart';

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
  String? _alunoId;
  String? _horarioId;
  bool _registrando = false;
  bool? _sucesso;
  String? _mensagemFinal;

  Future<void> _processar(String qrData) async {
    if (_carregando) return;
    setState(() { _carregando = true; _info = null; _alunoId = null; });
    await _ctrl.stop();

    try {
      // QR data format: "{academiaId}:{userId}"
      final parts = qrData.split(':');
      if (parts.length < 2) throw Exception('QR inválido');

      final academiaId = parts[0];
      final userId = parts[1];

      // Busca dados do aluno no Firestore
      final aluno = await firestoreService.getAluno(academiaId, userId);
      if (aluno == null) throw Exception('Aluno não encontrado');

      // Verifica se tem aula agora
      final now = DateTime.now();
      final weekDay = now.weekday % 7; // 0=Dom, 1=Seg, ..., 6=Sab
      final horaAtual = now.hour * 60 + now.minute;

      // Busca matrículas ativas
      final matriculas = await firestoreService.getMatriculas(
        academiaId,
        alunoId: userId,
        ativasOnly: true,
      );

      final turmaIds = matriculas
          .map((m) => m['turma_id'] as String?)
          .whereType<String>()
          .toList();

      // Busca horários das turmas do aluno para hoje
      String? horarioIdAgora;
      for (final turmaId in turmaIds) {
        final horarios = await firestoreService.getHorarios(academiaId, turmaId: turmaId);
        for (final h in horarios) {
          if ((h['dia_semana'] as int?) != weekDay) continue;
          // Verifica se a aula está em andamento (±30 min de tolerância)
          try {
            final inicio = _parseTime(h['hora_inicio']?.toString() ?? '');
            final fim = _parseTime(h['hora_fim']?.toString() ?? '');
            if (horaAtual >= inicio - 30 && horaAtual <= fim + 30) {
              horarioIdAgora = h['id'] as String?;
              break;
            }
          } catch (_) {}
        }
        if (horarioIdAgora != null) break;
      }

      // Busca turmas para exibição
      final turmasSnap = await Future.wait(
        turmaIds.map((id) => firestoreService.getTurma(academiaId, id)),
      );
      final turmasNomes = turmasSnap
          .whereType<Map<String, dynamic>>()
          .map((t) => t['nome'] as String? ?? '')
          .where((n) => n.isNotEmpty)
          .toList();

      // Conta presenças do mês
      final mes = now.month;
      final ano = now.year;
      final mesStr = '$ano-${mes.toString().padLeft(2, '0')}';
      final presencasSnap = await FirebaseFirestore.instance
          .collection('academias')
          .doc(academiaId)
          .collection('presencas')
          .where('aluno_id', isEqualTo: userId)
          .where('data', isGreaterThanOrEqualTo: '$mesStr-01')
          .get();

      setState(() {
        _info = {
          'nome': aluno['nome'] ?? '',
          'faixaNome': aluno['faixa_nome'] ?? 'Sem faixa',
          'faixaCor': '#888888',
          'turmas': turmasNomes,
          'totalPresencasMes': presencasSnap.docs.length,
          'temAulaAgora': horarioIdAgora != null,
          'academiaId': academiaId,
        };
        _alunoId = userId;
        _horarioId = horarioIdAgora;
        _carregando = false;
      });
    } catch (e) {
      setState(() { _carregando = false; });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('QR inválido ou aluno não encontrado.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
      );
      await _ctrl.start();
    }
  }

  int _parseTime(String t) {
    // Format: "HH:MM:SS" or "HH:MM"
    final parts = t.split(':');
    if (parts.length < 2) return 0;
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  Future<void> _registrar() async {
    if (_alunoId == null || _registrando || _info == null) return;
    setState(() { _registrando = true; });
    try {
      final user = await AuthStorage.getUser();
      final academiaId = _info!['academiaId'] as String;
      final now = DateTime.now();
      final dataStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      await firestoreService.addPresenca(academiaId, {
        'aluno_id': _alunoId,
        'horario_id': _horarioId ?? '',
        'academia_id': academiaId,
        'data': dataStr,
        'hora_checkin': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00',
        'metodo_checkin': 3, // QR Code
        'confirmado': true,
        'registrado_por': user?.id ?? '',
      });

      setState(() {
        _sucesso = true;
        _mensagemFinal = 'Presença registrada com sucesso!';
        _registrando = false;
      });
    } catch (e) {
      setState(() {
        _sucesso = false;
        _mensagemFinal = e is CheckinBloqueadoException ? e.mensagem : 'Erro ao registrar presença.';
        _registrando = false;
      });
    }
  }

  Future<void> _reiniciar() async {
    setState(() { _carregando = false; _info = null; _alunoId = null; _horarioId = null; _sucesso = null; _mensagemFinal = null; _registrando = false; });
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
                  color: (_sucesso! ? kSuccess : kDanger).withValues(alpha: 0.15),
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
                  border: Border.all(color: faixaCor.withValues(alpha: 0.4), width: 1.5),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
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
                                decoration: BoxDecoration(color: faixaCor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
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
                    if (turmas.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.class_rounded, color: kText2, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(turmas.join(', '), style: TextStyle(color: kText1, fontSize: 13))),
                        ],
                      ),
                    const SizedBox(height: 10),
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
                    temAula ? 'Registrar presença' : 'Sem aulas para realizar presenças agora',
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
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(8)),
                    child: Text('Aponte para o QR Code do aluno', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12), textAlign: TextAlign.center),
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
