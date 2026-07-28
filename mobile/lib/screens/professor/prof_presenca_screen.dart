import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/drawer_helper.dart';
import '../../core/firestore_service.dart';

class ProfPresencaScreen extends StatefulWidget {
  const ProfPresencaScreen({super.key});

  @override
  State<ProfPresencaScreen> createState() => _ProfPresencaScreenState();
}

class _ProfPresencaScreenState extends State<ProfPresencaScreen> {
  List<Map<String, dynamic>> _turmas = [];
  Map<String, dynamic>? _turmaSel;
  List<Map<String, dynamic>> _alunos = [];
  final _selecionados = <String>{};
  final _jaPresentes = <String>{};
  final _presencaIds = <String, String>{};
  int _step = 0;
  bool _loading = true;
  bool _saving = false;
  DateTime _dataSel = DateTime.now();
  String? _academiaId;

  @override
  void initState() {
    super.initState();
    _loadTurmas();
  }

  Future<void> _loadTurmas() async {
    try {
      final user = await AuthStorage.getUser();
      if (user == null) return;
      _academiaId = user.academiaId;
      final list = await firestoreService.getTurmas(user.academiaId!, professorId: user.id);
      if (mounted) setState(() => _turmas = list);
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selecionarTurma(Map<String, dynamic> t) async {
    setState(() {
      _turmaSel = t;
      _loading = true;
      _step = 1;
      _selecionados.clear();
      _jaPresentes.clear();
      _alunos = [];
    });
    await _carregarAlunos();
  }

  Future<void> _carregarAlunos() async {
    if (_turmaSel == null || _academiaId == null) return;
    setState(() => _loading = true);
    try {
      final turmaId = _turmaSel!['id'].toString();
      // Carrega matrículas e alunos em paralelo com presenças já registradas
      final results = await Future.wait([
        firestoreService.getMatriculas(_academiaId!, turmaId: turmaId),
        firestoreService.getPresencasPorAluno(_academiaId!, turmaId, _dataStr),
      ]);
      final matriculas = results[0] as List<Map<String, dynamic>>;
      final presencasPorAluno = results[1] as Map<String, String>;
      final jaPresentes = presencasPorAluno.keys.toSet();

      final alunos = <Map<String, dynamic>>[];
      for (final m in matriculas) {
        final alunoId = m['aluno_id'] as String? ?? '';
        if (alunoId.isEmpty) continue;
        final aluno = await firestoreService.getAluno(_academiaId!, alunoId);
        if (aluno != null) {
          alunos.add({'id': alunoId, 'nome': aluno['nome'] ?? ''});
        }
      }
      alunos.sort((a, b) => (a['nome'] as String).compareTo(b['nome'] as String));
      if (mounted) {
        setState(() {
          _alunos = alunos;
          _jaPresentes
            ..clear()
            ..addAll(jaPresentes);
          _presencaIds
            ..clear()
            ..addAll(presencasPorAluno);
          // Pré-selecionar quem já tem presença (exibição travada)
          _selecionados
            ..clear()
            ..addAll(jaPresentes);
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _mudarDia(int delta) async {
    final nova = DateTime(_dataSel.year, _dataSel.month, _dataSel.day).add(Duration(days: delta));
    final hoje = DateTime.now();
    final hojeNorm = DateTime(hoje.year, hoje.month, hoje.day);
    final minima = hojeNorm.subtract(const Duration(days: 90));
    if (nova.isAfter(hojeNorm)) return;
    if (nova.isBefore(minima)) return;
    setState(() {
      _dataSel = nova;
      _selecionados.clear();
      _jaPresentes.clear();
    });
    if (_step == 1) await _carregarAlunos();
  }

  String get _dataStr {
    return '${_dataSel.year}-${_dataSel.month.toString().padLeft(2, '0')}-${_dataSel.day.toString().padLeft(2, '0')}';
  }

  String get _dataLabel {
    final hoje = DateTime.now();
    final diff = DateTime(hoje.year, hoje.month, hoje.day)
        .difference(DateTime(_dataSel.year, _dataSel.month, _dataSel.day))
        .inDays;
    if (diff == 0) return 'Hoje';
    if (diff == 1) return 'Ontem';
    return '${_dataSel.day.toString().padLeft(2, '0')}/${_dataSel.month.toString().padLeft(2, '0')}/${_dataSel.year}';
  }

  Future<void> _registrar() async {
    // Só registra alunos que NÃO têm presença ainda
    final novos = _selecionados.difference(_jaPresentes);
    if (novos.isEmpty || _academiaId == null) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final horaStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    try {
      final bloqueios = await Future.wait(
        novos.map((id) => firestoreService.motivoBloqueioCheckin(_academiaId!, id)),
      );
      final liberados = <String>[];
      var bloqueados = 0;
      var i = 0;
      for (final alunoId in novos) {
        if (bloqueios[i++] == null) {
          liberados.add(alunoId);
        } else {
          bloqueados++;
        }
      }
      final novosIds = await Future.wait(liberados.map((alunoId) =>
          firestoreService.addPresenca(_academiaId!, {
            'aluno_id': alunoId,
            'turma_id': _turmaSel!['id'].toString(),
            'horario_id': '',
            'data': _dataStr,
            'hora_checkin': horaStr,
            'metodo_checkin': 1,
            'confirmado': true,
            'academia_id': _academiaId,
          })));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(bloqueados == 0
                ? '${liberados.length} presença(s) registrada(s)!'
                : '${liberados.length} registrada(s); $bloqueados bloqueada(s) por pendência financeira.'),
            backgroundColor: bloqueados == 0 ? kSuccess : kWarning,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _jaPresentes.addAll(liberados);
          for (var j = 0; j < liberados.length; j++) {
            _presencaIds[liberados[j]] = novosIds[j];
          }
          _selecionados
            ..clear()
            ..addAll(_jaPresentes);
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Erro ao registrar.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _removerPresenca(String alunoId, String nome) async {
    final presencaId = _presencaIds[alunoId];
    if (presencaId == null || _academiaId == null) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Remover presença', style: TextStyle(color: kText1, fontWeight: FontWeight.w700)),
        content: Text('Deseja remover a presença de $nome em $_dataLabel?', style: TextStyle(color: kText2)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Cancelar', style: TextStyle(color: kText2))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text('Remover', style: TextStyle(color: kDanger, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirmar != true) return;
    setState(() => _saving = true);
    try {
      await firestoreService.deletePresenca(_academiaId!, presencaId);
      if (mounted) {
        setState(() {
          _jaPresentes.remove(alunoId);
          _selecionados.remove(alunoId);
          _presencaIds.remove(alunoId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Presença removida.'), backgroundColor: kSuccess, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Não foi possível remover a presença.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Row(children: [
                if (_step == 0)
                  GestureDetector(onTap: openAppDrawer, child: Icon(Icons.menu_rounded, color: kText1, size: 26))
                else
                  IconButton(
                    onPressed: () => setState(() {
                      _step = 0;
                      _turmaSel = null;
                      _selecionados.clear();
                      _jaPresentes.clear();
                    }),
                    icon: Icon(Icons.arrow_back, color: kText1),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                const SizedBox(width: 8),
                Expanded(child: Text('Registrar Presença', style: TextStyle(color: kText1, fontSize: 22, fontWeight: FontWeight.w800))),
                IconButton(
                  onPressed: () => context.push('/scan-qr'),
                  icon: Icon(Icons.qr_code_scanner_rounded, color: kPrimary, size: 26),
                  tooltip: 'Escanear QR Code',
                ),
              ]),
            ),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: kPrimary))
                  : _step == 0
                      ? RefreshIndicator(
                          onRefresh: _loadTurmas,
                          color: kPrimary,
                          child: _stepTurma(),
                        )
                      : _stepAlunos(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepTurma() => ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _turmas.length,
        itemBuilder: (_, i) {
          final t = _turmas[i];
          return GestureDetector(
            onTap: () => _selecionarTurma(t),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t['nome'] ?? '', style: TextStyle(color: kText1, fontSize: 15, fontWeight: FontWeight.w600)),
                        if (t['modalidade_nome'] != null || t['modalidadeNome'] != null)
                          Text((t['modalidade_nome'] ?? t['modalidadeNome'] ?? '').toString(), style: TextStyle(color: kText2, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: kText2),
                ],
              ),
            ),
          );
        },
      );

  Widget _stepAlunos() => Column(
        children: [
          // Navegação de data por setas
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kPrimary.withAlpha(100)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _mudarDia(-1),
                    icon: Icon(Icons.chevron_left_rounded, color: kPrimary, size: 28),
                    splashRadius: 24,
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dataSel,
                          firstDate: DateTime.now().subtract(const Duration(days: 90)),
                          lastDate: DateTime.now(),
                          builder: (ctx, child) => Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: ColorScheme.dark(primary: kPrimary, surface: kSurface),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null && mounted) {
                          setState(() {
                            _dataSel = picked;
                            _selecionados.clear();
                            _jaPresentes.clear();
                          });
                          if (_step == 1) await _carregarAlunos();
                        }
                      },
                      child: Text(
                        _dataLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: kPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _mudarDia(1),
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      color: _dataSel.day == DateTime.now().day &&
                              _dataSel.month == DateTime.now().month &&
                              _dataSel.year == DateTime.now().year
                          ? kText2.withAlpha(80)
                          : kPrimary,
                      size: 28,
                    ),
                    splashRadius: 24,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Text('Marque quem esteve presente', style: TextStyle(color: kText2, fontSize: 13)),
                const Spacer(),
                Text('${_selecionados.length}/${_alunos.length}', style: TextStyle(color: kPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _alunos.length,
              itemBuilder: (_, i) {
                final a = _alunos[i];
                final alunoId = (a['id'] ?? '').toString();
                final nome = (a['nome'] ?? '').toString();
                final jaPresente = _jaPresentes.contains(alunoId);
                final sel = _selecionados.contains(alunoId);
                final initials = nome.trim().split(RegExp(r'\s+')).take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();
                return GestureDetector(
                  onTap: jaPresente
                      ? () => _removerPresenca(alunoId, nome)
                      : () => setState(() => sel ? _selecionados.remove(alunoId) : _selecionados.add(alunoId)),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: jaPresente
                          ? kSuccess.withAlpha(30)
                          : sel
                              ? kPrimary.withAlpha(38)
                              : kSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: jaPresente ? kSuccess.withAlpha(120) : sel ? kPrimary : kBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: jaPresente
                              ? kSuccess.withAlpha(60)
                              : sel
                                  ? kPrimary.withAlpha(76)
                                  : kPrimary.withAlpha(25),
                          child: Text(initials.isEmpty ? '?' : initials,
                              style: TextStyle(color: jaPresente ? kSuccess : kPrimary, fontSize: 11, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(nome, style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w600)),
                              if (jaPresente)
                                Text('Presença registrada · toque para remover', style: TextStyle(color: kSuccess, fontSize: 11)),
                            ],
                          ),
                        ),
                        if (jaPresente)
                          Icon(Icons.check_circle_rounded, color: kSuccess)
                        else if (sel)
                          Icon(Icons.check_circle_rounded, color: kPrimary),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Botão só ativo se há alunos novos a registrar
          Builder(builder: (_) {
            final novos = _selecionados.difference(_jaPresentes).length;
            return Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: _saving || novos == 0 ? null : _registrar,
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimary,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text('Registrar $novos presença(s)', style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            );
          }),
        ],
      );
}
