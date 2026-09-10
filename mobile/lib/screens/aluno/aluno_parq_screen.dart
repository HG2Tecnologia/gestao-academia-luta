import 'package:flutter/material.dart';
import '../../core/auth_storage.dart';
import '../../core/theme/context_ext.dart';
import '../../core/firestore_service.dart';

class AlunoParQScreen extends StatefulWidget {
  const AlunoParQScreen({super.key});

  @override
  State<AlunoParQScreen> createState() => _AlunoParQScreenState();
}

class _AlunoParQScreenState extends State<AlunoParQScreen> {
  bool _loading = true;
  bool _salvando = false;
  Map<String, dynamic>? _parq;

  final List<bool> _respostas = List.filled(10, false);
  final _nomeCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();

  List<String> get _perguntas => [
    context.l10n.sdParqQ1,
    context.l10n.sdParqQ2,
    context.l10n.sdParqQ3,
    context.l10n.sdParqQ4,
    context.l10n.sdParqQ5,
    context.l10n.sdParqQ6,
    context.l10n.sdParqQ7,
    context.l10n.sdParqQ8,
    context.l10n.sdParqQ9,
    context.l10n.sdParqQ10,
  ];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _cpfCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    try {
      final user = await AuthStorage.getUser();
      if (user == null) {
        setState(() => _loading = false);
        return;
      }
      final dados = await firestoreService.getParQ(user.academiaId!, user.id);
      if (dados != null) {
        setState(() {
          _parq = dados;
          _respostas[0] = dados['r1'] as bool? ?? false;
          _respostas[1] = dados['r2'] as bool? ?? false;
          _respostas[2] = dados['r3'] as bool? ?? false;
          _respostas[3] = dados['r4'] as bool? ?? false;
          _respostas[4] = dados['r5'] as bool? ?? false;
          _respostas[5] = dados['r6'] as bool? ?? false;
          _respostas[6] = dados['r7'] as bool? ?? false;
          _respostas[7] = dados['r8'] as bool? ?? false;
          _respostas[8] = dados['r9'] as bool? ?? false;
          _respostas[9] = dados['r10'] as bool? ?? false;
          _nomeCtrl.text = dados['nomeCompleto'] as String? ?? '';
          _cpfCtrl.text = dados['cpf'] as String? ?? '';
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _salvar() async {
    if (_nomeCtrl.text.trim().isEmpty || _cpfCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.sdParqFillNameCpf),
          backgroundColor: context.sem.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _salvando = true);
    try {
      final user = await AuthStorage.getUser();
      if (user == null) return;
      await firestoreService.addParQ(user.academiaId!, {
        'aluno_id': user.id,
        'academia_id': user.academiaId,
        'r1': _respostas[0],
        'r2': _respostas[1],
        'r3': _respostas[2],
        'r4': _respostas[3],
        'r5': _respostas[4],
        'r6': _respostas[5],
        'r7': _respostas[6],
        'r8': _respostas[7],
        'r9': _respostas[8],
        'r10': _respostas[9],
        'nomeCompleto': _nomeCtrl.text.trim(),
        'cpf': _cpfCtrl.text.trim(),
        'requerAvaliacaoMedica': _respostas.any((r) => r),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.sdParqSaved),
            backgroundColor: context.sem.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _carregar();
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.sdParqSaveError),
            backgroundColor: context.sem.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.surface,
      appBar: AppBar(
        backgroundColor: context.c.surfaceContainer,
        foregroundColor: context.c.onSurface,
        title: Text(
          'PAR-Q',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: _salvando ? null : _salvar,
            child: _salvando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    context.l10n.commonSave,
                    style: TextStyle(
                      color: context.c.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: context.c.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.c.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: context.c.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: context.c.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.l10n.apParqInstruction,
                            style: TextStyle(
                              color: context.c.onSurfaceVariant,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Status
                  if (_parq != null) ...[
                    _buildStatusBadge(),
                    const SizedBox(height: 16),
                  ],

                  // Perguntas
                  Text(
                    context.l10n.sdParqQuestionnaire,
                    style: TextStyle(
                      color: context.c.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (int i = 0; i < _perguntas.length; i++) ...[
                    _PerguntaItem(
                      numero: i + 1,
                      pergunta: _perguntas[i],
                      valor: _respostas[i],
                      onChanged: (v) => setState(() => _respostas[i] = v),
                    ),
                    if (i < _perguntas.length - 1) const SizedBox(height: 10),
                  ],

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Termo de responsabilidade
                  Text(
                    context.l10n.sdParqTerm,
                    style: TextStyle(
                      color: context.c.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.c.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.c.outline),
                    ),
                    child: Text(
                      context.l10n.sdParqTermBody,
                      style: TextStyle(
                        color: context.c.onSurfaceVariant,
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _campo(_nomeCtrl, context.l10n.apParqFullNameReq),
                  const SizedBox(height: 12),
                  _campo(_cpfCtrl, 'CPF *', keyboard: TextInputType.number),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _salvando ? null : _salvar,
                      style: FilledButton.styleFrom(
                        backgroundColor: context.c.primary,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _salvando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _parq != null
                                  ? context.l10n.sdParqUpdateBtn
                                  : context.l10n.apParqSignSend,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusBadge() {
    final requer = _parq!['requerAvaliacaoMedica'] as bool? ?? false;
    final data = _parq!['dataPreenchimento'] as String?;
    DateTime? dt;
    if (data != null) {
      try {
        dt = DateTime.parse(data).toLocal();
      } catch (_) {}
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: requer
            ? context.sem.warning.withOpacity(0.08)
            : context.sem.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: requer
              ? context.sem.warning.withOpacity(0.3)
              : context.sem.success.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            requer ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
            color: requer ? context.sem.warning : context.sem.success,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  requer
                      ? context.l10n.sdParqMedicalRecommended
                      : context.l10n.sdParqNoRisk,
                  style: TextStyle(
                    color: requer ? context.sem.warning : context.sem.success,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (dt != null)
                  Text(
                    context.l10n.sdParqFilledOn(
                      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}',
                    ),
                    style: TextStyle(
                      color: context.c.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _campo(
    TextEditingController c,
    String label, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      style: TextStyle(color: context.c.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: context.c.onSurfaceVariant),
        filled: true,
        fillColor: context.c.surfaceContainer,
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
          borderSide: BorderSide(color: context.c.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _PerguntaItem extends StatelessWidget {
  final int numero;
  final String pergunta;
  final bool valor;
  final ValueChanged<bool> onChanged;

  const _PerguntaItem({
    required this.numero,
    required this.pergunta,
    required this.valor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.c.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: valor
              ? context.sem.warning.withOpacity(0.4)
              : context.c.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: context.c.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '$numero',
                    style: TextStyle(
                      color: context.c.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  pergunta,
                  style: TextStyle(
                    color: context.c.onSurface,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _OpcaoBtn(
                label: 'Não',
                selected: !valor,
                onTap: () => onChanged(false),
                cor: context.sem.success,
              ),
              const SizedBox(width: 10),
              _OpcaoBtn(
                label: 'Sim',
                selected: valor,
                onTap: () => onChanged(true),
                cor: context.sem.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OpcaoBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color cor;
  const _OpcaoBtn({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.cor,
  });

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
          border: Border.all(
            color: selected ? cor : context.c.outline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? cor : context.c.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
