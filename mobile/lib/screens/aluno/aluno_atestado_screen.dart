import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/api_client.dart' show dio;
import '../../core/constants.dart';

class AlunoAtestadoScreen extends StatefulWidget {
  const AlunoAtestadoScreen({super.key});

  @override
  State<AlunoAtestadoScreen> createState() => _AlunoAtestadoScreenState();
}

class _AlunoAtestadoScreenState extends State<AlunoAtestadoScreen> {
  Map<String, dynamic>? _atestado;
  bool _loading = true;
  bool _uploading = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    try {
      final res = await dio.get('/api/atestados/meu');
      setState(() {
        _atestado = res.data['dados'];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _selecionar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    if (file.size > 5 * 1024 * 1024) {
      _mostrarErro('Arquivo muito grande. Máximo 5 MB.');
      return;
    }

    final mime = _mimeType(file.extension ?? 'pdf');
    await _enviar(file.bytes!, mime, file.name);
  }

  String _mimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/pdf';
    }
  }

  Future<void> _enviar(Uint8List bytes, String mime, String nome) async {
    setState(() { _uploading = true; _erro = null; });
    try {
      final base64 = base64Encode(bytes);
      await dio.post('/api/atestados/meu', data: {
        'arquivoBase64': base64,
        'arquivoMimeType': mime,
        'arquivoNome': nome,
      });
      await _carregar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Atestado enviado! Aguarde a aprovação da academia.'),
            backgroundColor: kSuccess,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _mostrarErro('Erro ao enviar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _mostrarErro(String msg) {
    setState(() => _erro = msg);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kSurface,
        foregroundColor: kText1,
        title: const Text('Atestado Médico', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregar,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _InfoCard(),
                  const SizedBox(height: 20),
                  if (_atestado != null) _StatusCard(atestado: _atestado!) else _SemAtestadoCard(),
                  const SizedBox(height: 24),
                  _BotaoEnvio(uploading: _uploading, onTap: _selecionar, temAtestado: _atestado != null),
                  if (_erro != null) ...[
                    const SizedBox(height: 12),
                    Text(_erro!, style: TextStyle(color: kDanger, fontSize: 13), textAlign: TextAlign.center),
                  ],
                ],
              ),
            ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E40AF).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF60A5FA), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'O atestado médico é válido por 1 ano após o envio. Formatos aceitos: PDF, JPG, PNG (máx. 5 MB).',
              style: TextStyle(color: kText2, fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _SemAtestadoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFC9A020).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC9A020).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.upload_file_rounded, color: kText2, size: 40),
          const SizedBox(height: 12),
          Text('Nenhum atestado enviado', style: TextStyle(color: kText1, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            'Envie seu atestado médico para que a academia possa verificar.',
            style: TextStyle(color: kText2, fontSize: 13, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final Map<String, dynamic> atestado;
  const _StatusCard({required this.atestado});

  @override
  Widget build(BuildContext context) {
    final status = atestado['status'] as int? ?? 0;
    final dataValidade = atestado['dataValidade'] != null
        ? DateTime.tryParse(atestado['dataValidade'])
        : null;
    final motivo = atestado['motivoRejeicao'] as String?;

    final (color, bg, icon, label) = switch (status) {
      0 => (kWarning, kWarning.withValues(alpha: 0.12), Icons.hourglass_empty_rounded, 'Aguardando aprovação'),
      1 => (kSuccess, kSuccess.withValues(alpha: 0.12), Icons.check_circle_rounded, 'Aprovado'),
      2 => (kDanger, kDanger.withValues(alpha: 0.12), Icons.cancel_rounded, 'Rejeitado'),
      3 => (kDanger, kDanger.withValues(alpha: 0.12), Icons.timer_off_rounded, 'Expirado'),
      _ => (kText2, kSurface, Icons.help_outline_rounded, 'Desconhecido'),
    };

    final vencendoEmBreve = status == 1 &&
        dataValidade != null &&
        dataValidade.isBefore(DateTime.now().add(const Duration(days: 7)));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Text(label, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          if (dataValidade != null) ...[
            const SizedBox(height: 10),
            Text(
              'Válido até: ${_fmt(dataValidade)}',
              style: TextStyle(color: kText2, fontSize: 13),
            ),
          ],
          if (motivo != null) ...[
            const SizedBox(height: 10),
            Text('Motivo: $motivo', style: TextStyle(color: kDanger, fontSize: 13)),
          ],
          if (vencendoEmBreve) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: kWarning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kWarning.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: kWarning, size: 16),
                  const SizedBox(width: 6),
                  Text('Vencendo em breve! Envie um novo.', style: TextStyle(color: kWarning, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _BotaoEnvio extends StatelessWidget {
  final bool uploading;
  final VoidCallback onTap;
  final bool temAtestado;

  const _BotaoEnvio({required this.uploading, required this.onTap, required this.temAtestado});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: uploading ? null : onTap,
      icon: uploading
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.upload_file_rounded),
      label: Text(
        temAtestado ? 'Enviar novo atestado' : 'Enviar atestado',
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: kPrimary,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
