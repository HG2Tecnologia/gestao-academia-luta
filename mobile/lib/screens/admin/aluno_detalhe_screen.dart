import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
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
  String? _meId;
  bool _loading = true;
  String? _erro;
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

      if (mounted) setState(() {
        _aluno = body['dados'] as Map<String, dynamic>?;
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
          if (a != null)
            TextButton(
              onPressed: _toggleAtivo,
              child: Text(
                a['ativo'] == true ? 'Desativar' : 'Ativar',
                style: TextStyle(color: a['ativo'] == true ? kDanger : kSuccess, fontWeight: FontWeight.w700),
              ),
            ),
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
                            _buildAvatar(a['nome'] ?? ''),
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

  Widget _buildAvatar(String nome) {
    final initials = nome.trim().split(RegExp(r'\s+')).take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();
    return Center(
      child: CircleAvatar(
        radius: 32,
        backgroundColor: kPrimary.withOpacity(0.2),
        child: Text(initials.isEmpty ? '?' : initials, style: TextStyle(color: kPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
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
