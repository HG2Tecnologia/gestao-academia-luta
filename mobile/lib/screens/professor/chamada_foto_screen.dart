import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../../core/face_recognition_service.dart';
import '../../core/firestore_service.dart';
import '../../core/theme/context_ext.dart';

const int metodoCheckinReconhecimentoFacial = 5;

class _FaceCandidato {
  _FaceCandidato({required this.face, required this.thumbnail});
  final DetectedFace face;
  final Uint8List thumbnail;
  String? alunoId;
  double score = 0;
  bool confirmado = false;
}

/// Chamada por foto: o professor tira uma foto da turma, o app detecta cada
/// rosto e sugere de qual aluno matriculado é — comparando com o embedding
/// gerado da foto de perfil (e, com o tempo, com confirmações anteriores).
/// Tudo roda no aparelho, nenhuma foto sai do app. Alunos sem consentimento
/// não entram na comparação, mesmo que apareçam na foto.
class ChamadaFotoScreen extends StatefulWidget {
  const ChamadaFotoScreen({
    super.key,
    required this.academiaId,
    required this.turmaId,
    required this.turmaNome,
    required this.alunos,
  });

  final String academiaId;
  final String turmaId;
  final String turmaNome;

  /// Alunos matriculados nessa turma — só quem tiver
  /// `consentimento_reconhecimento_facial == true` entra na comparação.
  final List<Map<String, dynamic>> alunos;

  @override
  State<ChamadaFotoScreen> createState() => _ChamadaFotoScreenState();
}

class _ChamadaFotoScreenState extends State<ChamadaFotoScreen> {
  bool _carregandoModelo = true;
  bool _processandoFoto = false;
  bool _salvando = false;
  List<_FaceCandidato> _candidatos = [];
  Set<String> _jaPresentes = {};
  Map<String, Map<String, dynamic>> _alunosPorId = {};

  @override
  void initState() {
    super.initState();
    _alunosPorId = {for (final a in widget.alunos) a['id'].toString(): a};
    _preparar();
  }

  Future<void> _preparar() async {
    final hoje = DateTime.now();
    final dataStr =
        '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';
    final jaPresentesMap = await firestoreService.getPresencasPorAluno(
      widget.academiaId,
      widget.turmaId,
      dataStr,
    );
    await FaceRecognitionService.preload();
    if (mounted) {
      setState(() {
        _jaPresentes = jaPresentesMap.keys.toSet();
        _carregandoModelo = false;
      });
    }
  }

  List<Map<String, dynamic>> get _alunosElegiveis => widget.alunos
      .where((a) => a['consentimento_reconhecimento_facial'] == true)
      .where((a) => !_jaPresentes.contains(a['id'].toString()))
      .toList();

  Future<void> _tirarFoto() async {
    final picker = ImagePicker();
    final foto = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (foto == null || !mounted) return;

    setState(() {
      _processandoFoto = true;
      _candidatos = [];
    });

    try {
      final referencias = <String, List<List<double>>>{};
      for (final aluno in _alunosElegiveis) {
        final refs = firestoreService.referenciasRostoDoAluno(aluno);
        if (refs.isNotEmpty) referencias[aluno['id'].toString()] = refs;
      }

      final detectados = await FaceRecognitionService.detectFacesInFile(
        foto.path,
      );
      final bytes = await File(foto.path).readAsBytes();
      var decoded = img.decodeImage(bytes);
      if (decoded == null) {
        if (mounted) setState(() => _processandoFoto = false);
        return;
      }
      decoded = img.bakeOrientation(decoded);

      final candidatos = <_FaceCandidato>[];
      for (final face in detectados) {
        final x = face.boundingBox.left.clamp(0, decoded.width - 1).toInt();
        final y = face.boundingBox.top.clamp(0, decoded.height - 1).toInt();
        final w = face.boundingBox.width
            .clamp(1, decoded.width - x)
            .toInt();
        final h = face.boundingBox.height
            .clamp(1, decoded.height - y)
            .toInt();
        final crop = img.copyCrop(decoded, x: x, y: y, width: w, height: h);
        final thumb = Uint8List.fromList(img.encodeJpg(crop, quality: 85));
        candidatos.add(_FaceCandidato(face: face, thumbnail: thumb));
      }

      // Pareamento greedy: calcula todos os scores (rosto detectado x aluno
      // elegível), ordena do melhor pro pior e vai atribuindo — um aluno só
      // pode ficar com um rosto, um rosto só pode ficar com um aluno.
      final candidatosComEmbedding = <int>[];
      for (var i = 0; i < candidatos.length; i++) {
        if (candidatos[i].face.embedding != null) candidatosComEmbedding.add(i);
      }
      final pares = <(int faceIdx, String alunoId, double score)>[];
      for (final i in candidatosComEmbedding) {
        final embedding = candidatos[i].face.embedding!;
        referencias.forEach((alunoId, refs) {
          for (final ref in refs) {
            final score = FaceRecognitionService.cosineSimilarity(
              embedding,
              ref,
            );
            pares.add((i, alunoId, score));
          }
        });
      }
      pares.sort((a, b) => b.$3.compareTo(a.$3));
      const limiar = 0.62;
      final facesUsadas = <int>{};
      final alunosUsados = <String>{};
      for (final par in pares) {
        if (par.$3 < limiar) break;
        if (facesUsadas.contains(par.$1) || alunosUsados.contains(par.$2)) {
          continue;
        }
        candidatos[par.$1].alunoId = par.$2;
        candidatos[par.$1].score = par.$3;
        facesUsadas.add(par.$1);
        alunosUsados.add(par.$2);
      }

      if (mounted) {
        setState(() {
          _candidatos = candidatos;
          _processandoFoto = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _processandoFoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.pfError),
            backgroundColor: context.sem.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _escolherAluno(_FaceCandidato candidato) async {
    final jaEscolhidos = _candidatos
        .where((c) => c != candidato && c.alunoId != null)
        .map((c) => c.alunoId)
        .toSet();
    final disponiveis = _alunosElegiveis
        .where((a) => !jaEscolhidos.contains(a['id'].toString()))
        .toList();

    final selecionado = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: context.c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.pfPickStudent,
              style: TextStyle(
                color: context.c.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.person_off_rounded,
                      color: context.c.onSurfaceVariant,
                    ),
                    title: Text(context.l10n.pfNotInPhoto),
                    onTap: () => Navigator.pop(context, ''),
                  ),
                  for (final a in disponiveis)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: context.c.primary.withAlpha(30),
                        child: Text(
                          (a['nome'] as String? ?? '?').isNotEmpty
                              ? (a['nome'] as String)[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(a['nome'] as String? ?? ''),
                      onTap: () => Navigator.pop(context, a['id'].toString()),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (selecionado == null || !mounted) return;
    setState(() {
      candidato.alunoId = selecionado.isEmpty ? null : selecionado;
      candidato.score = selecionado.isEmpty ? 0 : 1.0; // escolha manual = certeza total
    });
  }

  Future<void> _confirmarTudo() async {
    setState(() => _salvando = true);
    final hoje = DateTime.now();
    final dataStr =
        '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';
    final horaStr =
        '${hoje.hour.toString().padLeft(2, '0')}:${hoje.minute.toString().padLeft(2, '0')}';

    var registrados = 0;
    try {
      for (final c in _candidatos) {
        final alunoId = c.alunoId;
        if (alunoId == null) continue;

        await firestoreService.addPresenca(widget.academiaId, {
          'aluno_id': alunoId,
          'turma_id': widget.turmaId,
          'horario_id': '',
          'data': dataStr,
          'hora_checkin': horaStr,
          'metodo_checkin': metodoCheckinReconhecimentoFacial,
          'confirmado': true,
          'academia_id': widget.academiaId,
        });
        registrados++;

        // Aprendizado progressivo: toda confirmação (automática aceita ou
        // corrigida manualmente) vira mais uma referência pra próxima vez
        // reconhecer melhor — fotos reais da academia valem mais que a
        // foto de perfil sozinha.
        if (c.face.embedding != null) {
          await firestoreService.adicionarEmbeddingRostoConfirmado(
            widget.academiaId,
            alunoId,
            c.face.embedding!,
          );
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.pfSaved(registrados)),
            backgroundColor: context.sem.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.pfError),
            backgroundColor: context.sem.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final confirmaveis = _candidatos.where((c) => c.alunoId != null).length;

    return Scaffold(
      backgroundColor: context.c.surface,
      appBar: AppBar(
        backgroundColor: context.c.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.turmaNome,
          style: TextStyle(color: context.c.onSurface, fontSize: 16),
        ),
      ),
      body: _carregandoModelo
          ? Center(child: CircularProgressIndicator(color: context.c.primary))
          : SafeArea(
              child: Column(
                children: [
                  if (_alunosElegiveis.isEmpty && !_processandoFoto)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        context.l10n.pfNoEligibleStudents,
                        style: TextStyle(color: context.c.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  Expanded(
                    child: _processandoFoto
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  color: context.c.primary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  context.l10n.pfProcessing,
                                  style: TextStyle(
                                    color: context.c.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _candidatos.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.camera_alt_rounded,
                                    size: 56,
                                    color: context.c.outline,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    context.l10n.pfIntro,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: context.c.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _candidatos.length,
                            itemBuilder: (_, i) {
                              final c = _candidatos[i];
                              final aluno = c.alunoId != null
                                  ? _alunosPorId[c.alunoId]
                                  : null;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: context.c.surfaceContainer,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: context.c.outline),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.memory(
                                        c.thumbnail,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            aluno?['nome'] as String? ??
                                                context.l10n.pfUnrecognized,
                                            style: TextStyle(
                                              color: context.c.onSurface,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                          if (aluno != null)
                                            Text(
                                              '${(c.score * 100).round()}% ${context.l10n.pfConfidence}',
                                              style: TextStyle(
                                                color:
                                                    context.c.onSurfaceVariant,
                                                fontSize: 12,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => _escolherAluno(c),
                                      child: Text(
                                        aluno != null
                                            ? context.l10n.commonEdit
                                            : context.l10n.pfIdentify,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _processandoFoto ? null : _tirarFoto,
                            icon: const Icon(Icons.camera_alt_rounded),
                            label: Text(
                              _candidatos.isEmpty
                                  ? context.l10n.pfTakePhoto
                                  : context.l10n.pfRetakePhoto,
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                            ),
                          ),
                        ),
                        if (confirmaveis > 0) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: _salvando ? null : _confirmarTudo,
                              style: FilledButton.styleFrom(
                                backgroundColor: context.c.primary,
                                minimumSize: const Size.fromHeight(52),
                              ),
                              child: _salvando
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: context.c.onPrimary,
                                      ),
                                    )
                                  : Text(context.l10n.pfConfirm(confirmaveis)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
