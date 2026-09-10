import 'package:flutter/material.dart';
import '../../core/auth_storage.dart';
import '../../core/theme/context_ext.dart';
import '../../core/drawer_helper.dart';
import '../../core/firestore_service.dart';

class ProfGraduacaoScreen extends StatefulWidget {
  const ProfGraduacaoScreen({super.key});

  @override
  State<ProfGraduacaoScreen> createState() => _ProfGraduacaoScreenState();
}

class _ProfGraduacaoScreenState extends State<ProfGraduacaoScreen> {
  List<Map<String, dynamic>> _turmas = [];
  List<Map<String, dynamic>> _alunos = [];
  List<Map<String, dynamic>> _faixas = [];
  List<String> _aptosIds = [];
  Map<String, dynamic>? _turmaSel;
  Map<String, dynamic>? _alunoSel;
  Map<String, dynamic>? _faixaSel;
  int _grauSel = 0;
  final _obsCtrl = TextEditingController();
  int _step = 0;
  bool _loading = true;
  bool _saving = false;
  bool _sucesso = false;
  String? _academiaId;
  String? _profId;

  @override
  void initState() {
    super.initState();
    _loadTurmas();
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTurmas() async {
    try {
      final user = await AuthStorage.getUser();
      if (user == null) return;
      _academiaId = user.academiaId;
      _profId = user.id;
      final list = await firestoreService.getTurmas(
        user.academiaId!,
        professorId: user.id,
      );
      if (mounted)
        setState(
          () => _turmas = list.where((t) => t['deleted_at'] == null).toList(),
        );
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selecionarTurma(Map<String, dynamic> t) async {
    setState(() {
      _turmaSel = t;
      _loading = true;
      _step = 1;
      _aptosIds = [];
    });
    try {
      final academiaId = _academiaId!;
      final modalidadeId =
          (t['modalidade_id'] ?? t['modalidadeId'] as String? ?? '').toString();

      // Get students via matriculas
      final matriculas = await firestoreService.getMatriculas(
        academiaId,
        turmaId: t['id'] as String,
      );
      final alunos = <Map<String, dynamic>>[];
      for (final m in matriculas) {
        final alunoId = (m['aluno_id'] as String? ?? '').toString();
        if (alunoId.isEmpty) continue;
        final aluno = await firestoreService.getAluno(academiaId, alunoId);
        if (aluno != null) {
          alunos.add({
            'id': alunoId,
            'nome': aluno['nome'] ?? '',
            'alunoId': alunoId,
          });
        }
      }

      // Load faixas and aptos if modalidade known
      if (modalidadeId.isNotEmpty) {
        try {
          final faixasList = await firestoreService.getFaixas(
            academiaId,
            modalidadeId: modalidadeId,
          );
          if (faixasList.isNotEmpty) {
            final aptos = await firestoreService.getAptosGraduacao(academiaId);
            _aptosIds = aptos
                .map((a) => (a['id'] ?? a['aluno_id'] ?? '').toString())
                .toList();
          }
        } catch (_) {}
      }

      if (mounted) setState(() => _alunos = alunos);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selecionarAluno(Map<String, dynamic> a) async {
    setState(() {
      _alunoSel = a;
      _loading = true;
      _step = 2;
    });
    try {
      final modalidadeId =
          (_turmaSel?['modalidade_id'] ?? _turmaSel?['modalidadeId'] ?? '')
              .toString();
      final list = await firestoreService.getFaixas(
        _academiaId!,
        modalidadeId: modalidadeId,
      );
      if (mounted) setState(() => _faixas = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _promover() async {
    if (_faixaSel == null || _academiaId == null) return;
    setState(() => _saving = true);
    try {
      final hoje = DateTime.now();
      final dataExame =
          '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';
      await firestoreService.addGraduacao(_academiaId!, {
        'aluno_id': _alunoSel!['id'],
        'faixa_id': _faixaSel!['id'],
        'data_exame': dataExame,
        'professor_id': _profId,
        'aprovado': true,
        'grau': _grauSel,
        'observacoes': _obsCtrl.text.trim(),
        'academia_id': _academiaId,
      });
      if (mounted) {
        setState(() {
          _sucesso = true;
        });
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          final nomeAluno = _alunoSel!['nome'];
          final nomeFaixa = _faixaSel!['nome'];
          setState(() {
            _sucesso = false;
            _step = 0;
            _turmaSel = null;
            _alunoSel = null;
            _faixaSel = null;
            _obsCtrl.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$nomeAluno promovido para $nomeFaixa!'),
              backgroundColor: context.sem.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.sdPromoteError)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _back() => setState(() {
    if (_step == 2) {
      _step = 1;
      _faixaSel = null;
      _grauSel = 0;
    } else if (_step == 1) {
      _step = 0;
      _turmaSel = null;
    }
  });

  Color _hexCor(String? hex) {
    if (hex == null || hex.isEmpty) return context.c.primary;
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return context.c.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sucesso) {
      final cor = _hexCor(_faixaSel?['cor'] as String?);
      return Scaffold(
        backgroundColor: context.c.surface,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cor.withOpacity(0.2),
                      border: Border.all(color: cor.withOpacity(0.5), width: 3),
                    ),
                    child: Icon(
                      Icons.military_tech_rounded,
                      color: cor,
                      size: 52,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    context.l10n.profPromotionRecorded,
                    style: TextStyle(
                      color: context.c.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${_alunoSel?['nome'] ?? ''} foi promovido(a) para',
                    style: TextStyle(
                      color: context.c.onSurfaceVariant,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: cor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cor.withOpacity(0.4)),
                    ),
                    child: Text(
                      _faixaSel?['nome'] ?? '',
                      style: TextStyle(
                        color: cor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.c.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.c.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Row(
                children: [
                  if (_step == 0)
                    GestureDetector(
                      onTap: openAppDrawer,
                      child: Icon(
                        Icons.menu_rounded,
                        color: context.c.onSurface,
                        size: 26,
                      ),
                    )
                  else
                    IconButton(
                      onPressed: _back,
                      icon: Icon(Icons.arrow_back, color: context.c.onSurface),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.profPromotion,
                    style: TextStyle(
                      color: context.c.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: context.c.primary,
                      ),
                    )
                  : _step == 0
                  ? RefreshIndicator(
                      onRefresh: _loadTurmas,
                      color: context.c.primary,
                      child: _stepTurma(),
                    )
                  : [_stepTurma, _stepAluno, _stepFaixa][_step](),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepTurma() =>
      _lista(_turmas, (t) => _selecionarTurma(t), (t) => t['nome'] ?? '');
  Widget _stepAluno() => _lista(
    _alunos,
    (a) => _selecionarAluno(a),
    (a) => a['nome'] ?? '',
    badge: (a) {
      final id = (a['id'] ?? a['alunoId'] ?? '').toString();
      return _aptosIds.contains(id);
    },
  );

  Widget _lista(
    List<Map<String, dynamic>> items,
    void Function(Map<String, dynamic>) onTap,
    String Function(Map<String, dynamic>) title, {
    bool Function(Map<String, dynamic>)? badge,
  }) => ListView.builder(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    itemCount: items.length,
    itemBuilder: (_, i) {
      final isApto = badge != null && badge(items[i]);
      return GestureDetector(
        onTap: () => onTap(items[i]),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.c.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.c.outline),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title(items[i]),
                  style: TextStyle(
                    color: context.c.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isApto)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: context.sem.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Apto',
                    style: TextStyle(
                      color: context.sem.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Icon(Icons.chevron_right, color: context.c.onSurfaceVariant),
            ],
          ),
        ),
      );
    },
  );

  Widget _stepFaixa() => Column(
    children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            ..._faixas.map(
              (f) => GestureDetector(
                onTap: () => setState(() {
                  _faixaSel = f;
                  _grauSel = 0;
                }),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _faixaSel?['id'] == f['id']
                        ? context.c.primary.withOpacity(0.15)
                        : context.c.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _faixaSel?['id'] == f['id']
                          ? context.c.primary
                          : context.c.outline,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (f['cor'] != null)
                        Container(
                          width: 16,
                          height: 16,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(
                              int.tryParse(
                                    f['cor'].toString().replaceAll('#', '0xFF'),
                                  ) ??
                                  0xFF94A3B8,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          f['nome'] ?? '',
                          style: TextStyle(
                            color: context.c.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (_faixaSel?['id'] == f['id'])
                        Icon(
                          Icons.check_circle_rounded,
                          color: context.c.primary,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (_faixaSel != null && _faixaSel!['tem_graus'] == true) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.c.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.c.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.military_tech_rounded,
                          color: context.c.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Grau',
                          style: TextStyle(
                            color: context.c.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: context.c.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _grauSel == 0
                                ? context.l10n.sdNoStripe
                                : '$_grauSel° grau',
                            style: TextStyle(
                              color: context.c.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(
                        (_faixaSel!['max_graus'] as num? ??
                                    _faixaSel!['maxGraus'] as num? ??
                                    4)
                                .toInt() +
                            1,
                        (i) => GestureDetector(
                          onTap: () => setState(() => _grauSel = i),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _grauSel == i
                                  ? context.c.primary
                                  : context.c.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _grauSel == i
                                    ? context.c.primary
                                    : context.c.outline,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                i == 0 ? '—' : '$i',
                                style: TextStyle(
                                  color: _grauSel == i
                                      ? Colors.white
                                      : context.c.onSurfaceVariant,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _obsCtrl,
              style: TextStyle(color: context.c.onSurface),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: context.l10n.sdNotesOptional,
                hintStyle: TextStyle(color: context.c.onSurfaceVariant),
                filled: true,
                fillColor: context.c.surfaceContainer,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.c.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.c.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.c.primary),
                ),
              ),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: _saving || _faixaSel == null ? null : _promover,
          style: FilledButton.styleFrom(
            backgroundColor: context.c.primary,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _saving
              ? const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.sdPromote,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    if (_alunoSel != null && _aptosIds.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Icon(
                        _aptosIds.contains(
                              (_alunoSel!['id'] ?? _alunoSel!['alunoId'] ?? '')
                                  .toString(),
                            )
                            ? Icons.verified_rounded
                            : Icons.warning_amber_rounded,
                        size: 16,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    ],
  );
}
