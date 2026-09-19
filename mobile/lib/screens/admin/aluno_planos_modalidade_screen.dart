import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/context_ext.dart';
import '../../l10n/app_localizations.dart';
import '../../core/firestore_service.dart';

/// Gestão de planos por modalidade de UM aluno — só faz sentido quando a
/// academia ativou `cobranca_por_modalidade_ativa` em Configurações. Tela
/// própria e independente do formulário legado de "Plano" (um único
/// plano/vencimento por aluno, em `_editarAluno` de aluno_detalhe_screen):
/// os dois modelos coexistem sem se misturar — o legado nunca é alterado
/// por aqui, e esta tela nunca aparece pro fluxo antigo.
class AlunoPlanosModalidadeScreen extends StatefulWidget {
  final String academiaId;
  final String alunoId;
  final String alunoNome;

  const AlunoPlanosModalidadeScreen({
    super.key,
    required this.academiaId,
    required this.alunoId,
    required this.alunoNome,
  });

  @override
  State<AlunoPlanosModalidadeScreen> createState() =>
      _AlunoPlanosModalidadeScreenState();
}

class _AlunoPlanosModalidadeScreenState
    extends State<AlunoPlanosModalidadeScreen> {
  AppLocalizations get _l => context.l10n;

  bool _loading = true;
  bool _cobrancaPorModalidadeAtiva = false;
  List<Map<String, dynamic>> _matriculas = [];
  List<Map<String, dynamic>> _modalidades = [];
  List<Map<String, dynamic>> _planos = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        firestoreService.getAcademia(widget.academiaId),
        firestoreService.getPlanosModalidadeDoAluno(
          widget.academiaId,
          widget.alunoId,
        ),
        firestoreService.getModalidades(widget.academiaId),
        firestoreService.getPlanos(widget.academiaId),
      ]);
      final academia = results[0] as Map<String, dynamic>?;
      if (mounted) {
        setState(() {
          _cobrancaPorModalidadeAtiva =
              academia?['cobranca_por_modalidade_ativa'] as bool? ?? false;
          _matriculas = (results[1] as List).cast<Map<String, dynamic>>();
          _modalidades = (results[2] as List)
              .cast<Map<String, dynamic>>()
              .where((m) => m['ativo'] == true)
              .toList();
          _planos = (results[3] as List).cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _nomeModalidade(String id) => _modalidades
      .firstWhere((m) => m['id'] == id, orElse: () => const {})['nome']
      ?.toString() ??
      id;

  String _nomePlano(String id) => _planos
      .firstWhere((p) => p['id'] == id, orElse: () => const {})['nome']
      ?.toString() ??
      id;

  Future<void> _abrirFormulario({Map<String, dynamic>? matricula}) async {
    final isEdit = matricula != null;
    String? modalidadeId = matricula?['modalidade_id']?.toString();
    String? planoId = matricula?['plano_id']?.toString();
    final diaVencCtrl = TextEditingController(
      text: matricula?['dia_vencimento']?.toString() ?? '',
    );
    String? erro;
    bool salvando = false;

    // Modalidades que o aluno já tem matrícula ativa (exceto a que está
    // sendo editada agora) não podem ser escolhidas de novo — evita 2
    // cobranças para a mesma modalidade.
    final modalidadesJaUsadas = _matriculas
        .where((m) => m['id'] != matricula?['id'])
        .map((m) => m['modalidade_id']?.toString())
        .toSet();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.c.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isEdit ? _l.apmEditTitle : _l.apmNewTitle,
                      style: TextStyle(
                        color: context.c.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: Icon(Icons.close, color: context.c.onSurfaceVariant),
                    ),
                  ],
                ),
                const Divider(height: 20),
                DropdownButtonFormField<String?>(
                  initialValue: modalidadeId,
                  isExpanded: true,
                  decoration: _decoration(_l.apmModalityField),
                  items: [
                    for (final m in _modalidades)
                      DropdownMenuItem<String?>(
                        value: m['id'] as String,
                        enabled: !modalidadesJaUsadas.contains(m['id']),
                        child: Text(
                          m['nome']?.toString() ?? '',
                          style: TextStyle(
                            color: modalidadesJaUsadas.contains(m['id'])
                                ? context.c.onSurfaceVariant
                                : null,
                          ),
                        ),
                      ),
                  ],
                  onChanged: (v) => setModal(() => modalidadeId = v),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String?>(
                  initialValue: planoId,
                  isExpanded: true,
                  decoration: _decoration(_l.apmPlanField),
                  items: [
                    for (final p in _planos)
                      DropdownMenuItem<String?>(
                        value: p['id'] as String,
                        child: Text(p['nome']?.toString() ?? ''),
                      ),
                  ],
                  onChanged: (v) => setModal(() => planoId = v),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: diaVencCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(color: context.c.onSurface),
                  decoration: _decoration(_l.apmDueDayField),
                ),
                if (erro != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    erro!,
                    style: TextStyle(color: context.sem.danger, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: salvando
                        ? null
                        : () async {
                            final diaVenc = int.tryParse(diaVencCtrl.text.trim());
                            if (modalidadeId == null || planoId == null) {
                              setModal(() => erro = _l.apmSelectRequired);
                              return;
                            }
                            if (diaVenc == null || diaVenc < 1 || diaVenc > 28) {
                              setModal(() => erro = _l.apmInvalidDueDay);
                              return;
                            }
                            setModal(() {
                              salvando = true;
                              erro = null;
                            });
                            try {
                              final data = {
                                'aluno_id': widget.alunoId,
                                'modalidade_id': modalidadeId,
                                'plano_id': planoId,
                                'dia_vencimento': diaVenc,
                              };
                              if (isEdit) {
                                await firestoreService.updatePlanoModalidade(
                                  widget.academiaId,
                                  matricula['id'],
                                  data,
                                );
                              } else {
                                await firestoreService.addPlanoModalidade(
                                  widget.academiaId,
                                  data,
                                );
                              }
                              if (ctx.mounted) Navigator.of(ctx).pop();
                              if (mounted) _load();
                            } catch (_) {
                              setModal(() {
                                salvando = false;
                                erro = _l.apmSaveError;
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.c.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: salvando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isEdit ? _l.sdSaveChanges : _l.apmCreateBtn,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: context.c.onSurfaceVariant, fontSize: 14),
    filled: true,
    fillColor: context.c.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: context.c.outline),
    ),
  );

  Future<void> _encerrar(Map<String, dynamic> matricula) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.c.surfaceContainer,
        title: Text(_l.apmEndTitle, style: TextStyle(color: context.c.onSurface)),
        content: Text(
          _l.apmEndBody(_nomeModalidade(matricula['modalidade_id']?.toString() ?? '')),
          style: TextStyle(color: context.c.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(_l.commonCancel, style: TextStyle(color: context.c.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(_l.commonDelete, style: TextStyle(color: context.sem.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await firestoreService.deletePlanoModalidade(widget.academiaId, matricula['id']);
      _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_l.apmSaveError),
            backgroundColor: context.sem.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.surface,
      appBar: AppBar(
        backgroundColor: context.c.surfaceContainer,
        foregroundColor: context.c.onSurface,
        elevation: 0,
        title: Text(
          _l.apmTitle,
          style: TextStyle(color: context.c.onSurface, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_cobrancaPorModalidadeAtiva)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: _modalidades.isEmpty || _planos.isEmpty
                    ? null
                    : () => _abrirFormulario(),
                icon: Icon(Icons.add_rounded, color: context.c.primary, size: 18),
                label: Text(
                  _l.commonNew,
                  style: TextStyle(color: context.c.primary, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: context.c.primary))
          : !_cobrancaPorModalidadeAtiva
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline_rounded, color: context.c.onSurfaceVariant, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      _l.apmFeatureDisabled,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.c.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            )
          : _matriculas.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.category_outlined, color: context.c.onSurfaceVariant, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      _l.apmEmpty(widget.alunoNome),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.c.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _matriculas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final m = _matriculas[i];
                final plano = _planos.firstWhere(
                  (p) => p['id'] == m['plano_id'],
                  orElse: () => const {},
                );
                final valor = (plano['valor_mensal'] as num?)?.toDouble();
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.c.surfaceContainer,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.c.outline),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nomeModalidade(m['modalidade_id']?.toString() ?? ''),
                              style: TextStyle(
                                color: context.c.onSurface,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _nomePlano(m['plano_id']?.toString() ?? ''),
                              style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 12),
                            ),
                            if (valor != null)
                              Text(
                                _l.plnPerMonth(valor.toStringAsFixed(2).replaceAll('.', ',')),
                                style: TextStyle(
                                  color: context.c.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            Text(
                              _l.sdEveryDayN(m['dia_vencimento']),
                              style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit_rounded, color: context.c.onSurfaceVariant, size: 18),
                        onPressed: () => _abrirFormulario(matricula: m),
                        tooltip: _l.commonEdit,
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded, color: context.sem.danger, size: 18),
                        onPressed: () => _encerrar(m),
                        tooltip: _l.commonDelete,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
