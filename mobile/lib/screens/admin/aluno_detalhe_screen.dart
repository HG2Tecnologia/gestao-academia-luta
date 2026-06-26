import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../core/widgets.dart';

class AdminAlunoDetalheScreen extends StatefulWidget {
  final String alunoId;
  const AdminAlunoDetalheScreen({super.key, required this.alunoId});

  @override
  State<AdminAlunoDetalheScreen> createState() => _AdminAlunoDetalheScreenState();
}

class _AdminAlunoDetalheScreenState extends State<AdminAlunoDetalheScreen> {
  Map<String, dynamic>? _aluno;
  Map<String, dynamic>? _atestado;
  Map<String, dynamic>? _parq;
  Map<String, dynamic>? _grupoFamiliar;
  String? _meId;
  bool _loading = true;
  String? _erro;
  bool _uploadingAtestado = false;
  // Faixa mais recente aprovada por modalidade: { nomeModalidade -> { nome, cor } }
  Map<String, Map<String, dynamic>> _faixasPorModalidade = {};
  List<Map<String, dynamic>> _graduacoes = [];
  String? _histModFiltro; // null = todas as modalidades

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _erro = null; });
    try {
      final results = await Future.wait([
        dio.get('/api/alunos/${widget.alunoId}'),
        dio.get('/api/usuarios/me'),
        dio.get('/api/graduacoes', queryParameters: {'alunoId': widget.alunoId}),
        dio.get('/api/atestados/aluno/${widget.alunoId}').catchError((_) => Response(requestOptions: RequestOptions(path: ''), data: {'dados': null})),
        dio.get('/api/parq/aluno/${widget.alunoId}').catchError((_) => Response(requestOptions: RequestOptions(path: ''), data: {'dados': null})),
        dio.get('/api/grupos-familiares/aluno/${widget.alunoId}').catchError((_) => Response(requestOptions: RequestOptions(path: ''), data: {'dados': null})),
      ]);
      final body = results[0].data as Map<String, dynamic>;
      final meBody = results[1].data as Map<String, dynamic>;
      final gradBody = results[2].data as Map<String, dynamic>;

      // Agrupa graduações por modalidade, mantendo a de maior ordem (hierarquia da faixa)
      final graduacoes = (gradBody['dados'] as List? ?? []).cast<Map<String, dynamic>>();
      final Map<String, Map<String, dynamic>> faixasMod = {};
      for (final g in graduacoes) {
        final modNome = g['nomeModalidade']?.toString() ?? 'Sem modalidade';
        final faixaOrdem = (g['faixaOrdem'] as num?)?.toInt() ?? 0;
        final grau = (g['grau'] as num?)?.toInt() ?? 0;
        final existing = faixasMod[modNome];
        final existingOrdem = (existing?['_faixaOrdem'] as int?) ?? -1;
        final existingGrau = (existing?['grau'] as int?) ?? -1;
        if (existing == null || faixaOrdem > existingOrdem || (faixaOrdem == existingOrdem && grau > existingGrau)) {
          faixasMod[modNome] = {
            'id': g['faixaId']?.toString() ?? '',
            'nome': g['nomeFaixa'] ?? '',
            'cor': g['corFaixa'] ?? '#FFFFFF',
            'corBarra': g['corBarraFaixa'] ?? '#000000',
            'temGraus': g['faixaTemGraus'] == true,
            'maxGraus': (g['faixaMaxGraus'] as num?)?.toInt() ?? 4,
            '_faixaOrdem': faixaOrdem,
            'grau': grau,
          };
        }
      }

      final atestadoData = results.length > 3
          ? (results[3].data['dados'] as Map<String, dynamic>?)
          : null;
      final parqData = results.length > 4
          ? (results[4].data['dados'] as Map<String, dynamic>?)
          : null;

      final grupoData = results.length > 5
          ? (results[5].data['dados'] as Map<String, dynamic>?)
          : null;

      if (mounted) setState(() {
        _aluno = body['dados'] as Map<String, dynamic>?;
        _atestado = atestadoData;
        _parq = parqData;
        _grupoFamiliar = grupoData;
        _meId = (meBody['dados'] as Map<String, dynamic>?)?['id']?.toString();
        _faixasPorModalidade = faixasMod;
        _graduacoes = List.of(graduacoes)
          ..sort((a, b) {
            try {
              return DateTime.parse(b['dataExame'].toString())
                  .compareTo(DateTime.parse(a['dataExame'].toString()));
            } catch (_) {
              return 0;
            }
          });
      });
    } catch (_) {
      if (mounted) setState(() => _erro = 'Erro ao carregar aluno.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleAtivo() async {
    final a = _aluno;
    if (a == null) return;
    final novoStatus = !(a['ativo'] == true);
    final acao = novoStatus ? 'ativar' : 'desativar';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Confirmar', style: TextStyle(color: kText1)),
        content: Text('Deseja $acao ${a['nome']}?', style: TextStyle(color: kText2)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Cancelar', style: TextStyle(color: kText2))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text('Confirmar', style: TextStyle(color: kPrimary))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await dio.patch('/api/alunos/${widget.alunoId}/status', data: {'ativo': novoStatus});
      _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Erro ao alterar status.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  // ── PAR-Q ────────────────────────────────────────────

  static const _perguntas = [
    'Algum médico já disse que você possui algum problema de coração ou pressão arterial, e que somente deveria realizar atividade física supervisionado por profissionais de saúde?',
    'Você sente dores no peito quando pratica atividade física?',
    'No último mês, você sentiu dores no peito ao praticar atividade física?',
    'Você apresenta algum desequilíbrio devido à tontura e/ou perda momentânea da consciência?',
    'Você possui algum problema ósseo ou articular, que pode ser afetado ou agravado pela atividade física?',
    'Você toma atualmente algum tipo de medicação de uso contínuo?',
    'Você realiza algum tipo de tratamento médico para pressão arterial ou problemas cardíacos?',
    'Você realiza algum tratamento médico contínuo, que possa ser afetado ou prejudicado com a atividade física?',
    'Você já se submeteu a algum tipo de cirurgia, que comprometa de alguma forma a atividade física?',
    'Sabe de alguma outra razão pela qual a atividade física possa eventualmente comprometer sua saúde?',
  ];

  Widget _buildGrupoFamiliarCard() {
    final grupo = _grupoFamiliar;
    final membros = (grupo?['membros'] as List? ?? []).cast<Map<String, dynamic>>()
        .where((m) => m['id']?.toString() != widget.alunoId)
        .toList();

    return _buildCard([
      Row(children: [
        Expanded(child: _sectionTitle('Grupo Familiar')),
        GestureDetector(
          onTap: () => context.push('/admin/grupos-familiares'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(8), border: Border.all(color: kBorder)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.settings_rounded, size: 13, color: kText2),
              const SizedBox(width: 4),
              Text('Gerenciar', style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ]),
      if (grupo == null) ...[
        const SizedBox(height: 8),
        Text('Não vinculado a nenhum grupo familiar.', style: TextStyle(color: kText2, fontSize: 13)),
      ] else ...[
        const SizedBox(height: 6),
        Row(children: [
          Icon(Icons.family_restroom_rounded, color: kPrimary, size: 16),
          const SizedBox(width: 6),
          Text(grupo['nome'] as String? ?? '', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
        if (membros.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...membros.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              Icon(Icons.person_outline_rounded, color: kText2, size: 14),
              const SizedBox(width: 6),
              Text(m['nome'] as String? ?? '', style: TextStyle(color: kText2, fontSize: 12)),
            ]),
          )),
        ],
      ],
    ]);
  }

  Widget _buildParQCard() {
    final p = _parq;
    final requer = p?['requerAvaliacaoMedica'] as bool? ?? false;
    final dataRaw = p?['dataPreenchimento'] as String?;
    DateTime? data;
    if (dataRaw != null) { try { data = DateTime.parse(dataRaw).toLocal(); } catch (_) {} }

    return _buildCard([
      Row(children: [
        Expanded(child: _sectionTitle('PAR-Q')),
        if (p != null) ...[
          GestureDetector(
            onTap: () => _abrirParQForm(readOnly: true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kBorder),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.visibility_rounded, size: 13, color: kText2),
                const SizedBox(width: 4),
                Text('Visualizar', style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
          const SizedBox(width: 8),
        ],
        GestureDetector(
          onTap: () => _abrirParQForm(readOnly: false),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kPrimary.withOpacity(0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(p == null ? Icons.add_rounded : Icons.edit_rounded, size: 13, color: kPrimary),
              const SizedBox(width: 4),
              Text(p == null ? 'Preencher' : 'Editar', style: TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ]),
      const SizedBox(height: 6),
      if (p == null)
        Text('PAR-Q não preenchido.', style: TextStyle(color: kText2, fontSize: 13))
      else
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: requer ? kWarning.withOpacity(0.08) : kSuccess.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: requer ? kWarning.withOpacity(0.3) : kSuccess.withOpacity(0.3)),
          ),
          child: Row(children: [
            Icon(requer ? Icons.warning_amber_rounded : Icons.check_circle_rounded, color: requer ? kWarning : kSuccess, size: 15),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(requer ? 'Avaliação médica recomendada' : 'Sem indicações de risco',
                  style: TextStyle(color: requer ? kWarning : kSuccess, fontWeight: FontWeight.w700, fontSize: 12)),
              if (data != null)
                Text('Preenchido em ${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}',
                    style: TextStyle(color: kText2, fontSize: 11)),
            ])),
          ]),
        ),
    ]);
  }

  Future<void> _abrirParQForm({bool readOnly = false}) async {
    final p = _parq;
    final respostas = List<bool>.generate(10, (i) => p?['r${i + 1}'] as bool? ?? false);
    final nomeCtrl = TextEditingController(text: p?['nomeCompleto'] as String? ?? (_aluno?['nome'] as String? ?? ''));
    final cpfCtrl = TextEditingController(text: p?['cpf'] as String? ?? '');
    bool salvando = false;

    String titulo;
    if (readOnly) {
      titulo = 'PAR-Q';
    } else if (p == null) {
      titulo = 'Preencher PAR-Q';
    } else {
      titulo = 'Editar PAR-Q';
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(titulo, style: TextStyle(color: kText1, fontSize: 18, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.of(ctx).pop(), icon: Icon(Icons.close, color: kText2)),
                ]),
                Text(_aluno?['nome'] ?? '', style: TextStyle(color: kText2, fontSize: 13)),
                const Divider(height: 20),
                if (!readOnly) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: kPrimary.withOpacity(0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: kPrimary.withOpacity(0.2))),
                    child: Text('Responda "Sim" ou "Não" a cada pergunta. Preenchimento feito pela academia em nome do aluno.',
                        style: TextStyle(color: kText2, fontSize: 12, height: 1.4)),
                  ),
                  const SizedBox(height: 16),
                ],
                Text('QUESTIONÁRIO', style: TextStyle(color: kText2, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                const SizedBox(height: 10),
                ...List.generate(_perguntas.length, (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: readOnly
                      ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(
                            width: 22, height: 22,
                            decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(5)),
                            child: Center(child: Text('${i + 1}', style: TextStyle(color: kPrimary, fontSize: 11, fontWeight: FontWeight.w800))),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_perguntas[i], style: TextStyle(color: kText1, fontSize: 12, height: 1.4))),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: respostas[i] ? kWarning.withOpacity(0.12) : kSuccess.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(respostas[i] ? 'Sim' : 'Não',
                                style: TextStyle(color: respostas[i] ? kWarning : kSuccess, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        ])
                      : Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: kBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: respostas[i] ? kWarning.withOpacity(0.4) : kBorder),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Container(
                                width: 22, height: 22,
                                decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                                child: Center(child: Text('${i + 1}', style: TextStyle(color: kPrimary, fontSize: 11, fontWeight: FontWeight.w800))),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_perguntas[i], style: TextStyle(color: kText1, fontSize: 12, height: 1.4))),
                            ]),
                            const SizedBox(height: 10),
                            Row(children: [
                              _ParQOpcao(label: 'Não', selected: !respostas[i], cor: kSuccess,
                                  onTap: () => setModal(() => respostas[i] = false)),
                              const SizedBox(width: 8),
                              _ParQOpcao(label: 'Sim', selected: respostas[i], cor: kWarning,
                                  onTap: () => setModal(() => respostas[i] = true)),
                            ]),
                          ]),
                        ),
                )),
                const Divider(height: 24),
                if (readOnly) ...[
                  _row('Nome', p?['nomeCompleto']),
                  _row('CPF', p?['cpf']),
                ] else ...[
                  Text('TERMO DE RESPONSABILIDADE', style: TextStyle(color: kText2, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
                    child: Text('Declaro que estou ciente de que é recomendável conversar com um médico, antes de iniciar ou aumentar o nível de atividade física pretendido, assumindo plena responsabilidade pela realização de qualquer atividade física sem o atendimento desta recomendação.',
                        style: TextStyle(color: kText2, fontSize: 12, height: 1.5)),
                  ),
                  const SizedBox(height: 14),
                  _ParQCampo(ctrl: nomeCtrl, label: 'Nome completo *'),
                  const SizedBox(height: 10),
                  _ParQCampo(ctrl: cpfCtrl, label: 'CPF *', keyboard: TextInputType.number),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      onPressed: salvando ? null : () async {
                        if (nomeCtrl.text.trim().isEmpty || cpfCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: const Text('Preencha nome e CPF.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating));
                          return;
                        }
                        setModal(() => salvando = true);
                        try {
                          await dio.post('/api/parq/aluno/${widget.alunoId}', data: {
                            'r1': respostas[0], 'r2': respostas[1], 'r3': respostas[2],
                            'r4': respostas[3], 'r5': respostas[4], 'r6': respostas[5],
                            'r7': respostas[6], 'r8': respostas[7], 'r9': respostas[8],
                            'r10': respostas[9],
                            'nomeCompleto': nomeCtrl.text.trim(),
                            'cpf': cpfCtrl.text.trim(),
                          });
                          if (ctx.mounted) Navigator.of(ctx).pop();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: const Text('PAR-Q salvo com sucesso!'),
                              backgroundColor: kSuccess,
                              behavior: SnackBarBehavior.floating,
                            ));
                            _load();
                          }
                        } catch (_) {
                          if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: const Text('Erro ao salvar PAR-Q.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating));
                        } finally {
                          setModal(() => salvando = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: salvando
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(p == null ? 'Salvar PAR-Q' : 'Atualizar PAR-Q',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    nomeCtrl.dispose();
    cpfCtrl.dispose();
  }

  // ── Atestado Médico ──────────────────────────────────

  Future<void> _visualizarAtestado() async {
    final at = _atestado;
    if (at == null) return;

    final base64Str = at['arquivoBase64'] as String?;
    final mime = at['arquivoMimeType'] as String? ?? 'application/pdf';

    String? b64 = base64Str;
    if (b64 == null || b64.isEmpty) {
      try {
        final res = await dio.get('/api/atestados/aluno/${widget.alunoId}');
        final data = res.data['dados'] as Map<String, dynamic>?;
        b64 = data?['arquivoBase64'] as String?;
      } catch (_) {}
    }

    if (b64 == null || b64.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Arquivo não disponível.'), backgroundColor: kWarning, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    try {
      final bytes = base64Decode(b64);
      final ext = mime.contains('pdf') ? 'pdf' : mime.contains('png') ? 'png' : 'jpg';
      final tempFile = File('${Directory.systemTemp.path}/atestado_${widget.alunoId}.$ext');
      await tempFile.writeAsBytes(bytes, flush: true);
      final uri = Uri.file(tempFile.path);
      if (!await launchUrl(uri)) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Não foi possível abrir o arquivo.'), backgroundColor: kWarning, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Erro ao abrir o arquivo.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _avaliarAtestado(bool aprovado) async {
    if (_atestado == null) return;
    String? motivo;

    if (!aprovado) {
      final ctrl = TextEditingController();
      motivo = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: kSurface,
          title: Text('Motivo da rejeição', style: TextStyle(color: kText1, fontWeight: FontWeight.w700)),
          content: TextField(
            controller: ctrl,
            style: TextStyle(color: kText1),
            decoration: InputDecoration(
              hintText: 'Ex: atestado inválido, fora da validade...',
              hintStyle: TextStyle(color: kText2),
              filled: true,
              fillColor: kBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar', style: TextStyle(color: kText2))),
            TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: Text('Rejeitar', style: TextStyle(color: kDanger, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
      if (motivo == null || motivo.isEmpty) return;
    }

    try {
      await dio.patch('/api/atestados/${_atestado!['id']}/avaliar', data: {
        'aprovado': aprovado,
        if (!aprovado) 'motivoRejeicao': motivo,
      });
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(aprovado ? 'Atestado aprovado!' : 'Atestado rejeitado.'),
          backgroundColor: aprovado ? kSuccess : kDanger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {}
  }

  Future<void> _enviarLembrete() async {
    try {
      await dio.post('/api/atestados/aluno/${widget.alunoId}/lembrete');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Lembrete enviado ao aluno.'),
          backgroundColor: kSuccess,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {}
  }

  Future<void> _uploadAtestadoAcademia() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    if (file.size > 5 * 1024 * 1024) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Arquivo muito grande. Máx 5 MB.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _uploadingAtestado = true);
    try {
      final mime = file.extension?.toLowerCase() == 'pdf' ? 'application/pdf'
          : file.extension?.toLowerCase() == 'png' ? 'image/png' : 'image/jpeg';
      await dio.post('/api/atestados/academia', data: {
        'alunoId': widget.alunoId,
        'arquivoBase64': base64Encode(file.bytes!),
        'arquivoMimeType': mime,
        'arquivoNome': file.name,
      });
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Atestado anexado e aprovado!'), backgroundColor: kSuccess, behavior: SnackBarBehavior.floating));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Erro ao anexar atestado.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _uploadingAtestado = false);
    }
  }

  Widget _buildAtestadoCard() {
    final at = _atestado;
    final status = at?['status'] as int?;

    final (label, color) = at == null
        ? ('Sem atestado', kDanger)
        : switch (status) {
            0 => ('Aguardando aprovação', kWarning),
            1 => ('Aprovado', kSuccess),
            2 => ('Rejeitado', kDanger),
            3 => ('Expirado', kDanger),
            _ => ('Desconhecido', kText2),
          };

    final dataValidade = at != null ? DateTime.tryParse(at['dataValidade']?.toString() ?? '') : null;
    final fmt = dataValidade != null
        ? '${dataValidade.day.toString().padLeft(2,'0')}/${dataValidade.month.toString().padLeft(2,'0')}/${dataValidade.year}'
        : null;

    return _buildCard([
      Row(children: [
        Expanded(child: _sectionTitle('Atestado Médico')),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.4))),
          child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
      ]),
      if (fmt != null) _row('Validade', fmt),
      if (at?['motivoRejeicao'] != null) _row('Motivo', at!['motivoRejeicao']),
      const SizedBox(height: 10),
      if (at != null) ...[
        OutlinedButton.icon(
          onPressed: _visualizarAtestado,
          icon: const Icon(Icons.visibility_rounded, size: 16),
          label: const Text('Ver Atestado'),
          style: OutlinedButton.styleFrom(
            foregroundColor: kPrimary,
            side: BorderSide(color: kPrimary.withOpacity(0.4)),
            minimumSize: const Size(double.infinity, 40),
          ),
        ),
        const SizedBox(height: 8),
      ],
      if (status == 0) ...[
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: () => _avaliarAtestado(true),
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Aprovar'),
            style: OutlinedButton.styleFrom(foregroundColor: kSuccess, side: BorderSide(color: kSuccess.withOpacity(0.5))),
          )),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton.icon(
            onPressed: () => _avaliarAtestado(false),
            icon: const Icon(Icons.close_rounded, size: 16),
            label: const Text('Rejeitar'),
            style: OutlinedButton.styleFrom(foregroundColor: kDanger, side: BorderSide(color: kDanger.withOpacity(0.5))),
          )),
        ]),
      ],
      if (at == null) ...[
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: _uploadingAtestado ? null : _uploadAtestadoAcademia,
            icon: _uploadingAtestado
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.upload_file_rounded, size: 16),
            label: const Text('Anexar'),
            style: OutlinedButton.styleFrom(foregroundColor: kPrimary, side: BorderSide(color: kPrimary.withOpacity(0.4))),
          )),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton.icon(
            onPressed: _enviarLembrete,
            icon: const Icon(Icons.notifications_outlined, size: 16),
            label: const Text('Lembrar'),
            style: OutlinedButton.styleFrom(foregroundColor: kText2, side: BorderSide(color: kBorder)),
          )),
        ]),
      ],
    ]);
  }

  // ── Helpers ──────────────────────────────────────────

  int _maxGrausFaixa(String? nomeFaixa) {
    final nome = (nomeFaixa ?? '').toLowerCase().trim();
    if (nome.contains('vermelha')) return 9;
    if (nome.contains('coral')) return 8;
    if (nome.contains('preta')) return 6;
    return 4;
  }

  // ── Graduar ──────────────────────────────────────────

  Future<void> _abrirGraduar() async {
    List<Map<String, dynamic>> faixas = [];
    try {
      final res = await dio.get('/api/faixas');
      faixas = (res.data['dados'] as List? ?? []).cast<Map<String, dynamic>>();
    } catch (_) {}
    if (!mounted) return;

    final turmasDetalhes = (_aluno?['turmasDetalhes'] as List? ?? []).cast<Map<String, dynamic>>();
    final modalidadesAluno = <String>{
      for (final t in turmasDetalhes)
        if (t['modalidadeId'] != null) t['modalidadeId'].toString(),
    };

    final Map<String, Map<String, dynamic>> modMap = {};
    for (final f in faixas) {
      final modId = f['modalidadeId']?.toString() ?? '';
      if (modalidadesAluno.isNotEmpty && !modalidadesAluno.contains(modId)) continue;
      modMap.putIfAbsent(modId, () => {
        'id': modId,
        'nome': f['nomeModalidade']?.toString() ?? 'Sem modalidade',
        'faixas': <Map<String, dynamic>>[],
      });
      (modMap[modId]!['faixas'] as List<Map<String, dynamic>>).add(f);
    }
    if (modMap.isEmpty) {
      for (final f in faixas) {
        final modId = f['modalidadeId']?.toString() ?? '';
        modMap.putIfAbsent(modId, () => {
          'id': modId,
          'nome': f['nomeModalidade']?.toString() ?? 'Sem modalidade',
          'faixas': <Map<String, dynamic>>[],
        });
        (modMap[modId]!['faixas'] as List<Map<String, dynamic>>).add(f);
      }
    }

    final mods = modMap.values.toList();
    for (final m in mods) {
      (m['faixas'] as List<Map<String, dynamic>>)
          .sort((a, b) => (a['ordem'] as int? ?? 0).compareTo(b['ordem'] as int? ?? 0));
    }

    // step -1: choose type (dar grau / nova faixa)
    // step 0: select modality (skip if only 1)
    // step 1: select belt (skip for "dar grau")
    // step 2: confirm degree / details
    String? tipoGraduacao; // 'darGrau' or 'novaFaixa'
    int step = -1;
    Map<String, dynamic>? modSel = mods.length <= 1 && mods.isNotEmpty ? mods.first : null;
    Map<String, dynamic>? faixaSel;
    int grauSel = 0;
    int currentGrauForDarGrau = 0; // grau que o aluno já tem (chips ≤ esse ficam desabilitados)
    final obsCtrl = TextEditingController();
    bool gerarCobranca = false;
    final valorCtrl = TextEditingController();
    bool salvando = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          // for progress indicator: step -1 maps to 0, 0 → 1, 1 → 2, 2 → 3
          final totalSteps = tipoGraduacao == 'darGrau' ? 2 : (mods.length <= 1 ? 3 : 4);
          final activeStep = step + 1;
          final canGoBack = step >= 0;

          Widget stepContent;
          if (step == -1) {
            // Choose graduation type
            final temFaixaAtual = _faixasPorModalidade.isNotEmpty;
            stepContent = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('O que deseja fazer?', style: TextStyle(color: kText2, fontSize: 13)),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: temFaixaAtual ? () {
                    setModal(() {
                      tipoGraduacao = 'darGrau';
                      // Auto-select modality if only 1 modality
                      if (_faixasPorModalidade.length == 1) {
                        final modNome = _faixasPorModalidade.keys.first;
                        final faixaAtual = _faixasPorModalidade[modNome]!;
                        // Match from loaded faixas list
                        faixaSel = faixas.firstWhere(
                          (f) => f['id']?.toString() == faixaAtual['id']?.toString(),
                          orElse: () => faixaAtual,
                        );
                        // Ensure temGraus and maxGraus come from current belt data
                        final currentGrau = (faixaAtual['grau'] as num?)?.toInt() ?? 0;
                        if (faixaAtual['temGraus'] == true || currentGrau > 0) {
                          final apiMax = (faixaAtual['maxGraus'] as num?)?.toInt() ?? 0;
                          final nameMax = _maxGrausFaixa(faixaAtual['nome']?.toString());
                          final effectiveMax = apiMax > 0 ? apiMax : nameMax;
                          faixaSel = Map<String, dynamic>.from(faixaSel!)
                            ..['temGraus'] = true
                            ..['maxGraus'] = effectiveMax.clamp(1, 99);
                        }
                        final apiMaxG = (faixaAtual['maxGraus'] as num?)?.toInt() ?? 0;
                        final maxG = (apiMaxG > 0 ? apiMaxG : _maxGrausFaixa(faixaAtual['nome']?.toString())).clamp(1, 99);
                        currentGrauForDarGrau = currentGrau;
                        grauSel = (currentGrau + 1).clamp(1, maxG);
                        modSel = mods.isNotEmpty ? mods.first : null;
                      }
                      step = mods.length <= 1 ? 2 : 0;
                    });
                  } : null,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: temFaixaAtual ? kBg : kBorder.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: temFaixaAtual ? kPrimary.withOpacity(0.4) : kBorder),
                    ),
                    child: Row(children: [
                      Container(width: 40, height: 40, decoration: BoxDecoration(color: kPrimary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.grade_rounded, color: temFaixaAtual ? kPrimary : kText2, size: 22)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Dar Grau', style: TextStyle(color: temFaixaAtual ? kText1 : kText2, fontSize: 15, fontWeight: FontWeight.w700)),
                        Text('Incrementar grau na mesma faixa atual', style: TextStyle(color: kText2, fontSize: 11)),
                      ])),
                      Icon(Icons.chevron_right_rounded, color: temFaixaAtual ? kText2 : kBorder),
                    ]),
                  ),
                ),
                GestureDetector(
                  onTap: () => setModal(() {
                    tipoGraduacao = 'novaFaixa';
                    faixaSel = null;
                    step = mods.length <= 1 ? 1 : 0;
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kWarning.withOpacity(0.4))),
                    child: Row(children: [
                      Container(width: 40, height: 40, decoration: BoxDecoration(color: kWarning.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.military_tech_rounded, color: kWarning, size: 22)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Nova Faixa', style: TextStyle(color: kText1, fontSize: 15, fontWeight: FontWeight.w700)),
                        Text('Selecionar uma faixa diferente', style: TextStyle(color: kText2, fontSize: 11)),
                      ])),
                      Icon(Icons.chevron_right_rounded, color: kText2),
                    ]),
                  ),
                ),
              ],
            );
          } else if (step == 0) {
            stepContent = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selecione a modalidade', style: TextStyle(color: kText2, fontSize: 13)),
                const SizedBox(height: 14),
                ...mods.map((m) => GestureDetector(
                  onTap: () => setModal(() {
                    modSel = m;
                    step = tipoGraduacao == 'darGrau' ? 2 : 1;
                    if (tipoGraduacao == 'darGrau') {
                      final modNome = m['nome']?.toString() ?? '';
                      final faixaAtual = _faixasPorModalidade[modNome];
                      if (faixaAtual != null) {
                        faixaSel = faixas.firstWhere(
                          (f) => f['id']?.toString() == faixaAtual['id']?.toString(),
                          orElse: () => faixaAtual,
                        );
                        final currentGrau2 = (faixaAtual['grau'] as num?)?.toInt() ?? 0;
                        if (faixaAtual['temGraus'] == true || currentGrau2 > 0) {
                          final apiMax2 = (faixaAtual['maxGraus'] as num?)?.toInt() ?? 0;
                          final nameMax2 = _maxGrausFaixa(faixaAtual['nome']?.toString());
                          final eff2 = apiMax2 > 0 ? apiMax2 : nameMax2;
                          faixaSel = Map<String, dynamic>.from(faixaSel!)
                            ..['temGraus'] = true
                            ..['maxGraus'] = eff2.clamp(1, 99);
                        }
                        final apiMaxG2 = (faixaAtual['maxGraus'] as num?)?.toInt() ?? 0;
                        final maxG2 = (apiMaxG2 > 0 ? apiMaxG2 : _maxGrausFaixa(faixaAtual['nome']?.toString())).clamp(1, 99);
                        currentGrauForDarGrau = currentGrau2;
                        grauSel = (currentGrau2 + 1).clamp(1, maxG2);
                      }
                    }
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
                    child: Row(children: [
                      Icon(Icons.sports_martial_arts_rounded, color: kPrimary, size: 22),
                      const SizedBox(width: 12),
                      Expanded(child: Text(m['nome']?.toString() ?? '', style: TextStyle(color: kText1, fontSize: 15, fontWeight: FontWeight.w700))),
                      Icon(Icons.chevron_right_rounded, color: kText2),
                    ]),
                  ),
                )),
              ],
            );
          } else if (step == 1) {
            final faixasMod = (modSel?['faixas'] as List? ?? []).cast<Map<String, dynamic>>();
            stepContent = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selecione a faixa — ${modSel?['nome'] ?? ''}', style: TextStyle(color: kText2, fontSize: 13)),
                const SizedBox(height: 14),
                if (faixasMod.isEmpty)
                  Text('Nenhuma faixa disponível.', style: TextStyle(color: kText2))
                else
                  ...faixasMod.map((f) {
                    final cor = _parseCor(f['cor']?.toString());
                    final sel = faixaSel?['id'] == f['id'];
                    return GestureDetector(
                      onTap: () => setModal(() => faixaSel = f),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: sel ? kPrimary.withOpacity(0.15) : kBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: sel ? kPrimary : kBorder),
                        ),
                        child: Row(children: [
                          Container(width: 14, height: 14, decoration: BoxDecoration(shape: BoxShape.circle, color: cor)),
                          const SizedBox(width: 10),
                          Expanded(child: Text(f['nome'] ?? '', style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w600))),
                          if (sel) Icon(Icons.check_circle_rounded, color: kPrimary, size: 18),
                        ]),
                      ),
                    );
                  }),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton(
                    onPressed: faixaSel == null ? null : () => setModal(() => step = 2),
                    style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Próximo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            );
          } else {
            stepContent = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: kPrimary.withOpacity(0.3))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: _parseCor(faixaSel?['cor']?.toString()))),
                    const SizedBox(width: 8),
                    Text('${modSel?['nome']} · ${faixaSel?['nome'] ?? ''}', style: TextStyle(color: kPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                  ]),
                ),
                if (faixaSel != null && (faixaSel!['temGraus'] == true || tipoGraduacao == 'darGrau')) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(Icons.grade_rounded, size: 14, color: kText2),
                        const SizedBox(width: 6),
                        Text('Grau', style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text(grauSel == 0 ? 'Sem grau' : '${grauSel}° Grau', style: TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                      ]),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: List.generate(((faixaSel!['maxGraus'] as num? ?? 4).toInt().clamp(1, 99)) + 1, (i) {
                          final sel = grauSel == i;
                          // Para "darGrau": desabilita "–" e qualquer grau já conquistado
                          final isDisabled = tipoGraduacao == 'darGrau' && (i == 0 || i <= currentGrauForDarGrau);
                          return GestureDetector(
                            onTap: isDisabled ? null : () => setModal(() => grauSel = i),
                            child: Container(
                              width: 44, height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: sel ? kPrimary : isDisabled ? kBorder.withOpacity(0.25) : kSurface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: sel ? kPrimary : isDisabled ? kBorder.withOpacity(0.4) : kBorder),
                              ),
                              child: Text(i == 0 ? '—' : '$i°', style: TextStyle(
                                color: sel ? Colors.white : isDisabled ? kText2.withOpacity(0.4) : kText1,
                                fontSize: 13, fontWeight: FontWeight.w700,
                                decoration: isDisabled && i > 0 ? TextDecoration.lineThrough : null,
                              )),
                            ),
                          );
                        }),
                      ),
                    ]),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: obsCtrl,
                  style: TextStyle(color: kText1),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Observação (opcional)',
                    hintStyle: TextStyle(color: kText2),
                    filled: true, fillColor: kBg,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kPrimary)),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
                  child: Row(children: [
                    Expanded(child: Text('Gerar cobrança financeira', style: TextStyle(color: kText1, fontSize: 13))),
                    Switch(value: gerarCobranca, activeColor: kPrimary, onChanged: (v) => setModal(() => gerarCobranca = v)),
                  ]),
                ),
                if (gerarCobranca) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: valorCtrl,
                    style: TextStyle(color: kText1),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                    decoration: InputDecoration(
                      hintText: 'Valor da cobrança (R\$)',
                      hintStyle: TextStyle(color: kText2),
                      prefixText: 'R\$ ',
                      prefixStyle: TextStyle(color: kText2),
                      filled: true, fillColor: kBg,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kPrimary)),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: salvando ? null : () async {
                      setModal(() => salvando = true);
                      try {
                        final hoje = DateTime.now();
                        final dataExame = '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';
                        final temGraus = faixaSel!['temGraus'] == true;
                        await dio.post('/api/graduacoes', data: {
                          'alunoId': widget.alunoId,
                          'faixaId': faixaSel!['id'],
                          'dataExame': dataExame,
                          'professorId': _meId,
                          'aprovado': true,
                          'grau': (tipoGraduacao == 'darGrau' || temGraus) ? grauSel : 0,
                          'observacoes': obsCtrl.text.trim(),
                        });
                        if (gerarCobranca && valorCtrl.text.isNotEmpty) {
                          final valor = double.tryParse(valorCtrl.text.replaceAll(',', '.')) ?? 0;
                          if (valor > 0) {
                            final hj = DateTime.now();
                            final venc = '${hj.year}-${hj.month.toString().padLeft(2, '0')}-${hj.day.toString().padLeft(2, '0')}';
                            await dio.post('/api/financeiro', data: {
                              'alunoId': widget.alunoId,
                              'tipo': 5,
                              'status': 2,
                              'valor': valor,
                              'descricao': 'Graduação - ${faixaSel!['nome']}',
                              'dataVencimento': venc,
                            });
                          }
                        }
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${_aluno?['nome']} graduado para ${faixaSel!['nome']}!'), backgroundColor: kSuccess, behavior: SnackBarBehavior.floating),
                          );
                          _load();
                        }
                      } catch (e) {
                        String msg = 'Erro ao graduar.';
                        try { msg = ((e as dynamic).response?.data as Map?)?['mensagem'] ?? msg; } catch (_) {}
                        if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(msg), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
                        );
                      } finally {
                        setModal(() => salvando = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: salvando
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Confirmar Graduação', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            );
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (canGoBack)
                        GestureDetector(
                          onTap: () => setModal(() {
                            if (tipoGraduacao == 'darGrau' && step == 2) {
                              // "darGrau" skips step 1 (faixa selection), so back goes to modality or type select
                              step = mods.length <= 1 ? -1 : 0;
                              if (step == -1) { tipoGraduacao = null; modSel = mods.length <= 1 && mods.isNotEmpty ? mods.first : null; faixaSel = null; grauSel = 0; }
                              else { modSel = null; faixaSel = null; grauSel = 0; }
                            } else {
                              step--;
                              if (step == -1) { tipoGraduacao = null; modSel = mods.length <= 1 && mods.isNotEmpty ? mods.first : null; faixaSel = null; grauSel = 0; }
                              else if (step == 0) { modSel = null; faixaSel = null; }
                              else if (step == 1) faixaSel = null;
                            }
                          }),
                          child: const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF94A3B8), size: 18),
                          ),
                        ),
                      Text(
                        step == -1 ? 'Graduar Aluno' : tipoGraduacao == 'darGrau' ? 'Dar Grau' : 'Nova Faixa',
                        style: TextStyle(color: kText1, fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(totalSteps, (i) => Container(
                          margin: const EdgeInsets.only(left: 4),
                          width: i == activeStep ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == activeStep ? kPrimary : kBorder,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        )),
                      ),
                      const SizedBox(width: 4),
                      IconButton(onPressed: () => Navigator.of(ctx).pop(), icon: Icon(Icons.close, color: kText2)),
                    ],
                  ),
                  Text(_aluno?['nome'] ?? '', style: TextStyle(color: kText2, fontSize: 13)),
                  const Divider(height: 20),
                  stepContent,
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Vincular Turma ───────────────────────────────────

  Future<void> _abrirVincularTurma() async {
    List<Map<String, dynamic>> turmas = [];
    try {
      final res = await dio.get('/api/turmas');
      final dados = res.data['dados'];
      final list = dados is List ? dados : (dados is Map ? dados['items'] as List? ?? [] : []);
      turmas = list.cast<Map<String, dynamic>>();
    } catch (_) {}

    if (!mounted) return;

    Map<String, dynamic>? turmaSel;
    bool salvando = false;

    // Turmas já vinculadas
    final turmasAtuais = (_aluno?['turmas'] as List? ?? []).map((t) => t.toString()).toSet();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    Text('Vincular a uma Turma', style: TextStyle(color: kText1, fontSize: 18, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.of(ctx).pop(), icon: Icon(Icons.close, color: kText2)),
                  ],
                ),
              ),
              Flexible(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shrinkWrap: true,
                  itemCount: turmas.length,
                  itemBuilder: (_, i) {
                    final t = turmas[i];
                    final nomeT = t['nome']?.toString() ?? '';
                    final jaVinculado = turmasAtuais.contains(nomeT);
                    final sel = turmaSel?['id'] == t['id'];
                    return GestureDetector(
                      onTap: jaVinculado ? null : () => setModal(() => turmaSel = t),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: jaVinculado ? kBorder.withOpacity(0.3) : sel ? kPrimary.withOpacity(0.15) : kBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: sel ? kPrimary : kBorder),
                        ),
                        child: Row(children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(nomeT, style: TextStyle(color: jaVinculado ? kText2 : kText1, fontSize: 13, fontWeight: FontWeight.w600)),
                                if (t['modalidadeNome'] != null)
                                  Text(t['modalidadeNome'], style: TextStyle(color: kText2, fontSize: 11)),
                              ],
                            ),
                          ),
                          if (jaVinculado)
                            Text('Já vinculado', style: TextStyle(color: kText2, fontSize: 11))
                          else if (sel)
                            Icon(Icons.check_circle_rounded, color: kPrimary, size: 18),
                        ]),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (salvando || turmaSel == null) ? null : () async {
                      setModal(() => salvando = true);
                      try {
                        await dio.post('/api/matriculas', data: {
                          'alunoId': widget.alunoId,
                          'turmaId': turmaSel!['id'],
                        });
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Vinculado à ${turmaSel!['nome']}!'), backgroundColor: kSuccess, behavior: SnackBarBehavior.floating),
                          );
                          _load();
                        }
                      } catch (e) {
                        String msg = 'Erro ao vincular.';
                        try { msg = ((e as dynamic).response?.data as Map?)?['mensagem'] ?? msg; } catch (_) {}
                        if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(msg), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
                        );
                      } finally {
                        setModal(() => salvando = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: salvando
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Vincular', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseCor(String? hex) {
    try { return Color(int.parse((hex ?? '').replaceAll('#', '0xFF'))); } catch (_) { return kPrimary; }
  }

  Color _finCor(String? s) {
    if (s == 'Inadimplente') return kDanger;
    if (s == 'Pendente') return kWarning;
    return kSuccess;
  }

  String _formatFin(String? s) {
    if (s == 'EmDia') return 'Em Dia';
    return s ?? '';
  }

  // ── Editar Aluno ─────────────────────────────────────

  String? _isoToDdMmAaaa(dynamic raw) {
    if (raw == null) return null;
    try {
      final dt = DateTime.parse(raw.toString());
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) { return null; }
  }

  String _toIsoDate(String ddmmaaaa) {
    final parts = ddmmaaaa.split('/');
    if (parts.length != 3) return ddmmaaaa;
    return '${parts[2]}-${parts[1]}-${parts[0]}';
  }

  Widget _editSection(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Text(label, style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
  );

  Widget _editField(TextEditingController ctrl, String hint, {TextInputType? keyboard, List<TextInputFormatter>? formatters}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: ctrl,
      keyboardType: keyboard,
      inputFormatters: formatters,
      style: TextStyle(color: kText1),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: kText2, fontSize: 14),
        filled: true, fillColor: kBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPrimary)),
      ),
    ),
  );

  Future<void> _editarAluno() async {
    final a = _aluno;
    if (a == null) return;

    List<Map<String, dynamic>> planos = [];
    try {
      final res = await dio.get('/api/planos');
      final body = res.data as Map<String, dynamic>;
      final dados = body['dados'];
      final list = dados is List ? dados : (dados is Map ? (dados['itens'] as List? ?? []) : []);
      planos = list.cast<Map<String, dynamic>>();
    } catch (_) {}
    if (!mounted) return;

    final nomeCtrl = TextEditingController(text: a['nome']?.toString() ?? '');
    final emailCtrl = TextEditingController(text: a['email']?.toString() ?? '');
    final telefoneCtrl = TextEditingController(text: a['telefone']?.toString() ?? '');
    final nascCtrl = TextEditingController(text: _isoToDdMmAaaa(a['dataNascimento']) ?? '');
    final emergNomeCtrl = TextEditingController(text: a['contatoEmergenciaNome']?.toString() ?? '');
    final emergTelCtrl = TextEditingController(text: a['contatoEmergenciaTelefone']?.toString() ?? '');
    final diaVencCtrl = TextEditingController(text: a['diaVencimento']?.toString() ?? '');
    String? planoIdSel = a['planoId']?.toString();
    bool salvando = false;
    String? erro;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('Editar Aluno', style: TextStyle(color: kText1, fontSize: 18, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.of(ctx).pop(), icon: Icon(Icons.close, color: kText2)),
                ]),
                Text(a['nome']?.toString() ?? '', style: TextStyle(color: kText2, fontSize: 13)),
                const Divider(height: 20),
                _editSection('Dados pessoais'),
                _editField(nomeCtrl, 'Nome completo *'),
                _editField(emailCtrl, 'E-mail', keyboard: TextInputType.emailAddress),
                _editField(telefoneCtrl, 'Telefone', keyboard: TextInputType.phone, formatters: [_PhoneMaskFormatter()]),
                _editField(nascCtrl, 'Data de nascimento (DD/MM/AAAA)', keyboard: TextInputType.number, formatters: [_DateMaskFormatter()]),
                _editSection('Contato de emergência'),
                _editField(emergNomeCtrl, 'Nome do contato'),
                _editField(emergTelCtrl, 'Telefone do contato', keyboard: TextInputType.phone, formatters: [_PhoneMaskFormatter()]),
                _editSection('Plano financeiro'),
                if (planos.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: planoIdSel,
                        dropdownColor: kSurface,
                        isExpanded: true,
                        style: TextStyle(color: kText1, fontSize: 14),
                        hint: Text('Selecionar plano', style: TextStyle(color: kText2, fontSize: 14)),
                        items: [
                          DropdownMenuItem<String?>(value: null, child: Text('Sem plano', style: TextStyle(color: kText2))),
                          ...planos.map((p) => DropdownMenuItem<String?>(
                            value: p['id']?.toString(),
                            child: Text(p['nome']?.toString() ?? '', style: TextStyle(color: kText1)),
                          )),
                        ],
                        onChanged: (v) => setModal(() => planoIdSel = v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                _editField(diaVencCtrl, 'Dia de vencimento (1-31)', keyboard: TextInputType.number),
                if (erro != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: kDanger.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                    child: Text(erro!, style: TextStyle(color: kDanger, fontSize: 13)),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: salvando ? null : () async {
                      if (nomeCtrl.text.trim().isEmpty) {
                        setModal(() => erro = 'Nome é obrigatório.');
                        return;
                      }
                      setModal(() { salvando = true; erro = null; });
                      try {
                        final nascText = nascCtrl.text.trim();
                        await dio.put('/api/alunos/${widget.alunoId}', data: {
                          'nome': nomeCtrl.text.trim(),
                          'email': emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                          'telefone': telefoneCtrl.text.trim(),
                          if (nascText.length == 10) 'dataNascimento': _toIsoDate(nascText),
                          if (emergNomeCtrl.text.trim().isNotEmpty) 'contatoEmergenciaNome': emergNomeCtrl.text.trim(),
                          if (emergTelCtrl.text.trim().isNotEmpty) 'contatoEmergenciaTelefone': emergTelCtrl.text.trim(),
                          'planoId': planoIdSel,
                          if (diaVencCtrl.text.trim().isNotEmpty) 'diaVencimento': int.tryParse(diaVencCtrl.text.trim()),
                          'ativo': a['ativo'] == true,
                        });
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: const Text('Aluno atualizado com sucesso!'),
                            backgroundColor: kSuccess,
                            behavior: SnackBarBehavior.floating,
                          ));
                          _load();
                        }
                      } catch (e) {
                        String msg = 'Erro ao atualizar aluno.';
                        try { msg = ((e as dynamic).response?.data as Map?)?['mensagem'] ?? msg; } catch (_) {}
                        setModal(() { salvando = false; erro = msg; });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: salvando
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Salvar alterações', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    nomeCtrl.dispose();
    emailCtrl.dispose();
    telefoneCtrl.dispose();
    nascCtrl.dispose();
    emergNomeCtrl.dispose();
    emergTelCtrl.dispose();
    diaVencCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = _aluno;
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kSurface,
        foregroundColor: kText1,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: kText1, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(a?['nome'] ?? 'Aluno', style: TextStyle(color: kText1, fontWeight: FontWeight.w700)),
        actions: [
          if (a != null) ...[
            IconButton(
              onPressed: _editarAluno,
              icon: Icon(Icons.edit_rounded, color: kPrimary, size: 20),
              tooltip: 'Editar',
            ),
            TextButton(
              onPressed: _toggleAtivo,
              child: Text(
                a['ativo'] == true ? 'Desativar' : 'Ativar',
                style: TextStyle(color: a['ativo'] == true ? kDanger : kSuccess, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: kPrimary))
          : _erro != null
              ? Center(child: Text(_erro!, style: TextStyle(color: kDanger)))
              : a == null
                  ? Center(child: Text('Aluno não encontrado.', style: TextStyle(color: kText2)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildCard([
                            _buildAvatar(a),
                            const SizedBox(height: 12),
                            _row('Nome', a['nome']),
                            _row('Email', a['email']),
                            _row('Telefone', a['telefone']),
                            _row('Nascimento', _formatDate(a['dataNascimento'])),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _statusBadge(a['ativo'] == true),
                                if (a['situacaoFinanceira'] != null)
                                  Text(_formatFin(a['situacaoFinanceira'] as String?),
                                      style: TextStyle(color: _finCor(a['situacaoFinanceira'] as String?), fontSize: 13, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ]),
                          const SizedBox(height: 12),
                          // Graduação com botão
                          _buildCard([
                            Row(
                              children: [
                                Expanded(child: _sectionTitle('Graduação')),
                                TextButton.icon(
                                  onPressed: _abrirGraduar,
                                  icon: Icon(Icons.military_tech_rounded, size: 16, color: kPrimary),
                                  label: Text('Graduar', style: TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ),
                            if (_faixasPorModalidade.isEmpty)
                              _row('Faixa atual', a['faixaAtualNome'])
                            else
                              ..._faixasPorModalidade.entries.map((e) {
                                final eGrau = (e.value['grau'] as num?)?.toInt() ?? 0;
                                final eMaxGraus = (e.value['maxGraus'] as num?)?.toInt() ?? 4;
                                final eEffectiveMax = eMaxGraus > 0 ? eMaxGraus : (eGrau > 0 ? eGrau : 4);
                                return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(e.key, style: TextStyle(color: kText2, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        BeltBadge(
                                          cor: _parseCor(e.value['cor']?.toString()),
                                          corBarra: _parseCor(e.value['corBarra']?.toString() ?? '#000000'),
                                          temGraus: e.value['temGraus'] == true || eGrau > 0,
                                          grau: eGrau,
                                          maxGraus: eEffectiveMax,
                                          height: 14,
                                          minWidth: 32,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          eGrau > 0
                                              ? '${e.value['nome']} · $eGrau° Grau'
                                              : e.value['nome']?.toString() ?? '-',
                                          style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                              }),
                            _row('Nível / XP', a['nivel'] != null ? '${a['nivel']} · ${a['xpTotal'] ?? 0} XP' : null),
                          ]),
                          const SizedBox(height: 12),
                          _buildCard([
                            _sectionTitle('Plano'),
                            _row('Plano', a['planoNome']),
                            _row('Tipo', a['tipoPlano']),
                            _row('Vencimento', a['diaVencimento'] != null ? 'Dia ${a['diaVencimento']}' : null),
                          ]),
                          const SizedBox(height: 12),
                          _buildAtestadoCard(),
                          const SizedBox(height: 12),
                          _buildGrupoFamiliarCard(),
                          const SizedBox(height: 12),
                          _buildParQCard(),
                          // Turmas com botão vincular
                          const SizedBox(height: 12),
                          // Histórico de graduações
                          _buildCard([
                            _sectionTitle('Histórico de Graduações'),
                            if (_graduacoes.isEmpty)
                              Text('Nenhuma graduação registrada.',
                                  style: TextStyle(color: kText2, fontSize: 13))
                            else
                              Builder(builder: (_) {
                                final mods = _graduacoes
                                    .map((g) => g['nomeModalidade']?.toString() ?? '')
                                    .where((m) => m.isNotEmpty)
                                    .toSet()
                                    .toList()
                                  ..sort();
                                final multiMod = mods.length > 1;
                                final selected = multiMod
                                    ? (mods.contains(_histModFiltro) ? _histModFiltro! : mods.first)
                                    : null;
                                final filtered = selected == null
                                    ? _graduacoes
                                    : _graduacoes.where((g) => g['nomeModalidade']?.toString() == selected).toList();
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    if (multiMod)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: DropdownButtonFormField<String>(
                                          value: selected,
                                          onChanged: (v) { if (v != null) setState(() => _histModFiltro = v); },
                                          dropdownColor: kSurface,
                                          style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w600),
                                          decoration: InputDecoration(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                            filled: true,
                                            fillColor: kBg,
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kPrimary)),
                                          ),
                                          icon: Icon(Icons.keyboard_arrow_down_rounded, color: kText2),
                                          items: mods.map((m) => DropdownMenuItem<String>(
                                            value: m,
                                            child: Text(m, overflow: TextOverflow.ellipsis, style: TextStyle(color: kText1, fontSize: 13)),
                                          )).toList(),
                                        ),
                                      ),
                                    ...filtered.map((g) => _buildGraduacaoItem(g)),
                                  ],
                                );
                              }),
                          ]),
                          const SizedBox(height: 12),
                          _buildCard([
                            Row(
                              children: [
                                Expanded(child: _sectionTitle('Turmas')),
                                TextButton.icon(
                                  onPressed: _abrirVincularTurma,
                                  icon: Icon(Icons.add_circle_outline_rounded, size: 16, color: kPrimary),
                                  label: Text('Vincular', style: TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ),
                            if ((a['turmas'] as List?)?.isEmpty != false)
                              Text('Nenhuma turma vinculada.', style: TextStyle(color: kText2, fontSize: 13))
                            else
                              ...(a['turmas'] as List).map((t) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.circle, color: kPrimary, size: 6),
                                    const SizedBox(width: 8),
                                    Text(t.toString(), style: TextStyle(color: kText1, fontSize: 13)),
                                  ],
                                ),
                              )),
                          ]),
                                          const SizedBox(height: 12),
                          _buildCard([
                            Row(
                              children: [
                                Expanded(child: _sectionTitle('Rankings')),
                                TextButton.icon(
                                  onPressed: _abrirLancarPontos,
                                  icon: Icon(Icons.add_circle_outline_rounded, size: 16, color: kPrimary),
                                  label: Text('Pontos', style: TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ),
                            Text('Toque em "Pontos" para lançar pontos em um ranking personalizado.',
                                style: TextStyle(color: kText2, fontSize: 12)),
                          ]),
                          if (a['contatoEmergenciaNome'] != null) ...[
                            const SizedBox(height: 12),
                            _buildCard([
                              _sectionTitle('Contato de Emergência'),
                              _row('Nome', a['contatoEmergenciaNome']),
                              _row('Telefone', a['contatoEmergenciaTelefone']),
                            ]),
                          ],
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
    );
  }

  // ── Lançar Pontos em Ranking ─────────────────────────
  Future<void> _abrirLancarPontos() async {
    List<Map<String, dynamic>> rankings = [];
    try {
      final res = await dio.get('/api/ranking/custom');
      final data = res.data;
      final list = data is List
          ? data.cast<Map<String, dynamic>>()
          : (data is Map ? ((data['dados'] ?? data['itens'] ?? []) as List).cast<Map<String, dynamic>>() : <Map<String, dynamic>>[]);
      rankings = list.where((r) => r['incluirPontosManuais'] == true && r['ativo'] != false).toList();
    } catch (_) {}

    if (!mounted) return;

    if (rankings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Nenhum ranking com pontos manuais ativo.'),
        backgroundColor: kWarning,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    Map<String, dynamic>? rankingSel = rankings.length == 1 ? rankings.first : null;
    final pontosCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool salvando = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('Lançar Pontos', style: TextStyle(color: kText1, fontSize: 18, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.of(ctx).pop(), icon: Icon(Icons.close, color: kText2)),
                ]),
                Text(_aluno?['nome'] ?? '', style: TextStyle(color: kText2, fontSize: 13)),
                const Divider(height: 20),
                if (rankings.length > 1) ...[
                  Text('Ranking', style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...rankings.map((r) {
                    final sel = rankingSel?['id'] == r['id'];
                    return GestureDetector(
                      onTap: () => setModal(() => rankingSel = r),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: sel ? kPrimary.withOpacity(0.12) : kBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: sel ? kPrimary : kBorder),
                        ),
                        child: Row(children: [
                          Expanded(child: Text(r['nome'] ?? '', style: TextStyle(color: sel ? kPrimary : kText1, fontSize: 13, fontWeight: FontWeight.w600))),
                          if (sel) Icon(Icons.check_circle_rounded, color: kPrimary, size: 18),
                        ]),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                ] else if (rankings.length == 1) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: kPrimary.withOpacity(0.3))),
                    child: Text(rankingSel?['nome'] ?? '', style: TextStyle(color: kPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: pontosCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: kText1),
                  decoration: InputDecoration(
                    hintText: 'Quantidade de pontos',
                    hintStyle: TextStyle(color: kText2),
                    filled: true, fillColor: kBg,
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kPrimary)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  style: TextStyle(color: kText1),
                  decoration: InputDecoration(
                    hintText: 'Descrição (opcional)',
                    hintStyle: TextStyle(color: kText2),
                    filled: true, fillColor: kBg,
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kPrimary)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: (salvando || rankingSel == null || pontosCtrl.text.trim().isEmpty) ? null : () async {
                      final pts = int.tryParse(pontosCtrl.text.trim());
                      if (pts == null || pts <= 0) return;
                      setModal(() => salvando = true);
                      try {
                        await dio.post('/api/ranking/custom/${rankingSel!['id']}/pontuar', data: {
                          'alunoId': widget.alunoId,
                          'pontos': pts,
                          'descricao': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                        });
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('$pts pontos lançados com sucesso!'),
                          backgroundColor: kSuccess,
                          behavior: SnackBarBehavior.floating,
                        ));
                      } catch (e) {
                        String msg = 'Erro ao lançar pontos.';
                        try { msg = ((e as dynamic).response?.data as Map?)?['mensagem'] ?? msg; } catch (_) {}
                        if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg), backgroundColor: kDanger, behavior: SnackBarBehavior.floating));
                      } finally {
                        setModal(() => salvando = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: salvando
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Lançar Pontos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGraduacaoItem(Map<String, dynamic> g) {
    final grau = (g['grau'] as num?)?.toInt() ?? 0;
    final nomeFaixa = g['nomeFaixa']?.toString() ?? '-';
    final nomeMod = g['nomeModalidade']?.toString() ?? '';
    final nomeProfessor = g['nomeProfessor']?.toString() ?? '';
    final aprovado = g['aprovado'] == true;
    final corFaixa = _parseCor(g['corFaixa']?.toString());
    final corBarra = _parseCor(g['corBarraFaixa']?.toString() ?? '#000000');
    final temGraus = g['faixaTemGraus'] == true || grau > 0;
    final maxGrausRaw = (g['faixaMaxGraus'] as num?)?.toInt() ?? 0;
    final maxGraus = maxGrausRaw > 0 ? maxGrausRaw : (grau > 0 ? grau : 4);
    final dataStr = _formatDate(g['dataExame']) ?? '';
    final label = grau > 0 ? '$nomeFaixa · $grau° Grau' : nomeFaixa;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot + line
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: aprovado ? corFaixa : kBorder,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    BeltBadge(
                      cor: corFaixa,
                      corBarra: corBarra,
                      temGraus: temGraus,
                      grau: grau,
                      maxGraus: maxGraus,
                      height: 10,
                      minWidth: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: kText1,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (dataStr.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(dataStr, style: TextStyle(color: kText2, fontSize: 11)),
                    ],
                    if (!aprovado) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: kWarning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Pendente', style: TextStyle(color: kWarning, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(List<Widget> children) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Future<void> _escolherFotoAdmin() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result == null || result.files.single.bytes == null || !mounted) return;
    final bytes = result.files.single.bytes!;
    final ext = (result.files.single.extension ?? 'jpg').toLowerCase();
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
    final fotoBase64 = 'data:$mime;base64,${base64Encode(bytes)}';
    try {
      await dio.patch('/api/alunos/${widget.alunoId}/foto', data: {'fotoBase64': fotoBase64});
      if (mounted) setState(() { _aluno = {...?_aluno, 'fotoBase64': fotoBase64}; });
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Erro ao salvar foto.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
      );
    }
  }

  Widget _buildAvatar(Map<String, dynamic> aluno) {
    final nome = aluno['nome']?.toString() ?? '';
    final foto = aluno['fotoBase64'] as String?;
    final initials = nome.trim().split(RegExp(r'\s+')).take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();
    return Center(
      child: GestureDetector(
        onTap: _escolherFotoAdmin,
        child: Stack(
          children: [
            foto != null && foto.startsWith('data:')
                ? CircleAvatar(
                    radius: 32,
                    backgroundColor: kPrimary.withOpacity(0.2),
                    backgroundImage: MemoryImage(base64Decode(foto.split(',').last)),
                  )
                : CircleAvatar(
                    radius: 32,
                    backgroundColor: kPrimary.withOpacity(0.2),
                    child: Text(initials.isEmpty ? '?' : initials, style: TextStyle(color: kPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
                  ),
            Positioned(
              bottom: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: kPrimary, shape: BoxShape.circle,
                  border: Border.all(color: kBg, width: 2),
                ),
                child: const Icon(Icons.camera_alt_rounded, size: 10, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      );

  Widget _row(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: TextStyle(color: kText2, fontSize: 13))),
          Expanded(child: Text(value.toString(), style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _statusBadge(bool ativo) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: ativo ? kSuccess.withOpacity(0.15) : kText2.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(ativo ? 'Ativo' : 'Inativo',
            style: TextStyle(color: ativo ? kSuccess : kText2, fontSize: 12, fontWeight: FontWeight.w700)),
      );

  String? _formatDate(dynamic raw) {
    if (raw == null) return null;
    try {
      final dt = DateTime.parse(raw.toString());
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return raw.toString();
    }
  }
}

class _ParQOpcao extends StatelessWidget {
  final String label;
  final bool selected;
  final Color cor;
  final VoidCallback onTap;
  const _ParQOpcao({required this.label, required this.selected, required this.cor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? cor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? cor : kBorder, width: selected ? 1.5 : 1),
        ),
        child: Text(label, style: TextStyle(color: selected ? cor : kText2, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, fontSize: 13)),
      ),
    );
  }
}

class _ParQCampo extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final TextInputType keyboard;
  const _ParQCampo({required this.ctrl, required this.label, this.keyboard = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: TextStyle(color: kText1),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: kText2),
        filled: true,
        fillColor: kBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPrimary, width: 1.5)),
      ),
    );
  }
}

class _PhoneMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll(RegExp(r'\D'), '');
    final d = digits.length > 11 ? digits.substring(0, 11) : digits;
    final buf = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i == 0) buf.write('(');
      if (i == 2) buf.write(') ');
      if (d.length == 11 && i == 7) buf.write('-');
      if (d.length <= 10 && i == 6) buf.write('-');
      buf.write(d[i]);
    }
    final text = buf.toString();
    return next.copyWith(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

class _DateMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll(RegExp(r'\D'), '');
    final d = digits.length > 8 ? digits.substring(0, 8) : digits;
    final buf = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i == 2 || i == 4) buf.write('/');
      buf.write(d[i]);
    }
    final text = buf.toString();
    return next.copyWith(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
