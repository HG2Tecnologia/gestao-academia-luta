import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/ad_banner.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../core/drawer_helper.dart';
import '../../core/paywall_modal.dart';

class AdminTurmasScreen extends StatefulWidget {
  const AdminTurmasScreen({super.key});

  @override
  State<AdminTurmasScreen> createState() => _AdminTurmasScreenState();
}

class _AdminTurmasScreenState extends State<AdminTurmasScreen> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _turmas = [];
  List<Map<String, dynamic>> _filtradas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _ctrl.addListener(_filtrar);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await dio.get('/api/turmas');
      final body = res.data as Map<String, dynamic>;
      final dados = body['dados'];
      final list = dados is List ? dados : (dados is Map ? (dados['itens'] as List? ?? []) : []);
      if (mounted) {
        setState(() {
          _turmas = list.cast<Map<String, dynamic>>();
          _filtrar();
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _abrirForm({Map<String, dynamic>? turma}) async {
    final criou = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TurmaFormSheet(turma: turma),
    );
    if (criou == true) _load();
  }

  void _filtrar() {
    final q = _ctrl.text.trim().toLowerCase();
    setState(() {
      _filtradas = q.isEmpty
          ? List.from(_turmas)
          : _turmas.where((t) {
              final nome = (t['nome'] as String? ?? '').toLowerCase();
              final mod = (t['modalidadeNome'] as String? ?? '').toLowerCase();
              final prof = (t['professorNome'] as String? ?? '').toLowerCase();
              return nome.contains(q) || mod.contains(q) || prof.contains(q);
            }).toList();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirForm(),
        backgroundColor: kPrimary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                children: [
                  Text('Turmas', style: TextStyle(color: kText1, fontSize: 22, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.push('/admin/turmas/relatorio'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: kSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_alt_rounded, color: kText2, size: 14),
                          const SizedBox(width: 5),
                          Text('Presenças', style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(onTap: openAppDrawer, child: Icon(Icons.menu_rounded, color: kText1, size: 26)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _ctrl,
                style: TextStyle(color: kText1),
                decoration: InputDecoration(
                  hintText: 'Buscar turma...',
                  hintStyle: TextStyle(color: kText2),
                  prefixIcon: Icon(Icons.search, color: kText2),
                  filled: true,
                  fillColor: kSurface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPrimary)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: kPrimary))
                  : _filtradas.isEmpty
                      ? Center(child: Text('Nenhuma turma encontrada.', style: TextStyle(color: kText2)))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filtradas.length,
                            itemBuilder: (_, i) {
                              final t = _filtradas[i];
                              final ativa = t['ativo'] == true;
                              final total = t['totalAlunos'] ?? 0;
                              final cap = t['capacidadeMaxima'] ?? 0;
                              return GestureDetector(
                                onTap: () => context.push('/admin/turmas/${t['id']}', extra: t),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: kSurface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: kBorder),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(t['nome'] ?? '', style: TextStyle(color: kText1, fontSize: 15, fontWeight: FontWeight.w700)),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: ativa ? kSuccess.withOpacity(0.15) : kText2.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              ativa ? 'Ativa' : 'Inativa',
                                              style: TextStyle(color: ativa ? kSuccess : kText2, fontSize: 11, fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        [t['modalidadeNome'], t['nivel']].where((s) => s != null && s != '').join(' · '),
                                        style: TextStyle(color: kText2, fontSize: 13),
                                      ),
                                      if (t['professorNome'] != null && (t['professorNome'] as String).isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text('Prof. ${t['professorNome']}', style: TextStyle(color: kPrimary, fontSize: 12)),
                                      ],
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Text('$total', style: TextStyle(color: kPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
                                          Text(' / $cap alunos', style: TextStyle(color: kText2, fontSize: 13)),
                                          const Spacer(),
                                          GestureDetector(
                                            onTap: () => _abrirForm(turma: t),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: kPrimary.withOpacity(0.10),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(Icons.edit_rounded, color: kPrimary, size: 16),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(Icons.chevron_right, color: kText2, size: 18),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
            const AdBannerWidget(),
          ],
        ),
      ),
    );
  }
}

// ── Formulário de Turma ──────────────────────────────────────────────────────

class TurmaFormSheet extends StatefulWidget {
  const TurmaFormSheet({this.turma});
  final Map<String, dynamic>? turma;

  @override
  State<TurmaFormSheet> createState() => TurmaFormSheetState();
}

class TurmaFormSheetState extends State<TurmaFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _capCtrl = TextEditingController();

  List<Map<String, dynamic>> _modalidades = [];
  List<Map<String, dynamic>> _professores = [];

  String? _modalidadeId;
  String? _professorId;
  String? _nivel;
  bool _ativo = true;
  bool _loading = true;
  bool _salvando = false;

  static const _niveis = ['Iniciante', 'Intermediário', 'Avançado', 'Todos os níveis'];

  bool get _editando => widget.turma != null;

  @override
  void initState() {
    super.initState();
    if (_editando) {
      final t = widget.turma!;
      _nomeCtrl.text = t['nome'] as String? ?? '';
      _capCtrl.text = (t['capacidadeMaxima'] ?? '').toString();
      _nivel = t['nivel'] as String?;
      _ativo = t['ativo'] == true;
    }
    _loadDados();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _capCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDados() async {
    try {
      final results = await Future.wait([
        dio.get('/api/modalidades'),
        dio.get('/api/funcionarios'),
      ]);

      final mods = (results[0].data['dados'] as List? ?? []).cast<Map<String, dynamic>>();
      final funcs = (results[1].data['dados'] as List? ?? []).cast<Map<String, dynamic>>();
      final profs = funcs.where((f) {
        final cargo = f['cargo']?.toString().toLowerCase() ?? '';
        final perfil = f['perfil']?.toString().toLowerCase() ?? '';
        return cargo.contains('professor') || perfil.contains('professor');
      }).toList();

      if (mounted) {
        setState(() {
          _modalidades = mods;
          _professores = profs;

          if (_editando) {
            final t = widget.turma!;
            // Match modalidade by name if ID not present
            final modNome = t['modalidadeNome']?.toString() ?? '';
            final modId = t['modalidadeId']?.toString();
            _modalidadeId = modId ?? mods.firstWhere(
              (m) => m['nome']?.toString() == modNome,
              orElse: () => {},
            )['id']?.toString();

            // Match professor by name if ID not present
            final profNome = t['professorNome']?.toString() ?? '';
            final profId = t['professorId']?.toString();
            _professorId = profId ?? profs.firstWhere(
              (p) => p['nome']?.toString() == profNome || p['nomeUsuario']?.toString() == profNome,
              orElse: () => {},
            )['usuarioId']?.toString() ?? profs.firstWhere(
              (p) => p['nome']?.toString() == profNome,
              orElse: () => {},
            )['id']?.toString();
          }

          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      final body = {
        'nome': _nomeCtrl.text.trim(),
        'modalidadeId': _modalidadeId,
        if (_professorId != null && _professorId!.isNotEmpty) 'professorId': _professorId,
        'capacidadeMaxima': int.tryParse(_capCtrl.text.trim()) ?? 30,
        if (_nivel != null) 'nivel': _nivel,
        'ativo': _ativo,
      };

      if (_editando) {
        await dio.put('/api/turmas/${widget.turma!['id']}', data: body);
      } else {
        await dio.post('/api/turmas', data: body);
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      try {
        final data = (e as dynamic).response?.data;
        if (data is Map && data['codigo'] == 'LIMITE_PLANO_GRATUITO') {
          setState(() => _salvando = false);
          mostrarPaywall(context);
          return;
        }
        if (data is Map && data['mensagem'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['mensagem'].toString()), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
          );
          return;
        }
      } catch (_) {}
      final msg = _editando ? 'Erro ao editar turma' : 'Erro ao criar turma';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                _editando ? 'Editar Turma' : 'Nova Turma',
                style: TextStyle(color: kText1, fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              if (_salvando)
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              else
                TextButton(
                  onPressed: _salvar,
                  style: TextButton.styleFrom(
                    backgroundColor: kPrimary.withOpacity(0.12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Salvar', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(),
            )
          else
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _field(_nomeCtrl, 'Nome da Turma', Icons.groups_rounded,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null),
                  const SizedBox(height: 14),
                  // Modalidade dropdown
                  DropdownButtonFormField<String>(
                    value: _modalidadeId,
                    decoration: _inputDecoration('Modalidade', Icons.sports_martial_arts_rounded),
                    dropdownColor: kSurface,
                    style: TextStyle(color: kText1, fontSize: 15),
                    items: (_editando ? _modalidades : _modalidades.where((m) => m['ativo'] == true).toList()).map((m) => DropdownMenuItem(
                      value: m['id']?.toString(),
                      child: Text(m['nome']?.toString() ?? '', style: TextStyle(color: kText1)),
                    )).toList(),
                    onChanged: (v) => setState(() => _modalidadeId = v),
                    validator: (v) => v == null ? 'Selecione a modalidade' : null,
                  ),
                  const SizedBox(height: 14),
                  // Nível dropdown
                  DropdownButtonFormField<String>(
                    value: _niveis.contains(_nivel) ? _nivel : null,
                    decoration: _inputDecoration('Nível', Icons.bar_chart_rounded),
                    dropdownColor: kSurface,
                    style: TextStyle(color: kText1, fontSize: 15),
                    items: _niveis.map((n) => DropdownMenuItem(
                      value: n,
                      child: Text(n, style: TextStyle(color: kText1)),
                    )).toList(),
                    onChanged: (v) => setState(() => _nivel = v),
                  ),
                  const SizedBox(height: 14),
                  // Professor dropdown (opcional)
                  DropdownButtonFormField<String>(
                    value: _professores.any((p) =>
                        (p['usuarioId'] ?? p['id'])?.toString() == _professorId)
                        ? _professorId
                        : null,
                    decoration: _inputDecoration('Professor (opcional)', Icons.person_rounded),
                    dropdownColor: kSurface,
                    style: TextStyle(color: kText1, fontSize: 15),
                    items: [
                      DropdownMenuItem<String>(value: null, child: Text('Sem professor', style: TextStyle(color: kText2))),
                      ..._professores.map((p) {
                        final id = (p['usuarioId'] ?? p['id'])?.toString();
                        final nome = p['nome']?.toString() ?? p['nomeUsuario']?.toString() ?? '';
                        return DropdownMenuItem(
                          value: id,
                          child: Text(nome, style: TextStyle(color: kText1)),
                        );
                      }),
                    ],
                    onChanged: (v) => setState(() => _professorId = v),
                  ),
                  const SizedBox(height: 14),
                  _field(_capCtrl, 'Capacidade máxima', Icons.people_rounded,
                      keyboard: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Obrigatório';
                        if (int.tryParse(v.trim()) == null) return 'Número inválido';
                        return null;
                      }),
                  if (_editando) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: kSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.toggle_on_rounded, color: kText2, size: 18),
                          const SizedBox(width: 10),
                          Expanded(child: Text('Turma ativa', style: TextStyle(color: kText1))),
                          Switch(
                            value: _ativo,
                            onChanged: (v) => setState(() => _ativo = v),
                            activeColor: kPrimary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        validator: validator,
        style: TextStyle(color: kText1, fontSize: 15),
        decoration: _inputDecoration(label, icon),
      );

  InputDecoration _inputDecoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: kText2, fontSize: 13),
        prefixIcon: Icon(icon, color: kText2, size: 18),
        filled: true,
        fillColor: kSurface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPrimary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kDanger)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kDanger, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
}
