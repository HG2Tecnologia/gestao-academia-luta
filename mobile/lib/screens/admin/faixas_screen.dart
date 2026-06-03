import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';

class AdminFaixasScreen extends StatefulWidget {
  const AdminFaixasScreen({super.key});

  @override
  State<AdminFaixasScreen> createState() => _AdminFaixasScreenState();
}

class _AdminFaixasScreenState extends State<AdminFaixasScreen> {
  List<Map<String, dynamic>> _modalidades = [];
  List<Map<String, dynamic>> _faixas = [];
  String? _modalidadeId;
  bool _loading = true;
  bool _erro = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() { _loading = true; _erro = false; });
    try {
      final res = await dio.get('/api/modalidades');
      final raw = res.data['dados'];
      final list = raw is List ? raw : (raw as Map?)?['items'] as List? ?? [];
      final modalidades = list.cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() { _modalidades = modalidades; });
      if (modalidades.isNotEmpty) {
        _modalidadeId = modalidades.first['id']?.toString();
        await _loadFaixas();
      } else {
        setState(() { _loading = false; });
      }
    } catch (_) {
      if (mounted) setState(() { _erro = true; _loading = false; });
    }
  }

  Future<void> _loadFaixas() async {
    if (_modalidadeId == null) return;
    setState(() { _loading = true; });
    try {
      final res = await dio.get('/api/faixas', queryParameters: {'modalidadeId': _modalidadeId});
      final raw = res.data['dados'];
      final list = raw is List ? raw : (raw as Map?)?['items'] as List? ?? [];
      final faixas = list.cast<Map<String, dynamic>>();
      faixas.sort((a, b) => (a['ordem'] as int? ?? 0).compareTo(b['ordem'] as int? ?? 0));
      if (mounted) setState(() { _faixas = faixas; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _erro = true; _loading = false; });
    }
  }

  Future<void> _deletar(Map<String, dynamic> faixa) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Remover Faixa', style: TextStyle(color: kText1, fontWeight: FontWeight.w800)),
        content: Text('Deseja remover a faixa "${faixa['nome']}"?', style: TextStyle(color: kText2)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar', style: TextStyle(color: kText2))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remover', style: TextStyle(color: kDanger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await dio.delete('/api/faixas/${faixa['id']}');
      await _loadFaixas();
    } catch (e) {
      if (!mounted) return;
      String msg = 'Erro ao remover faixa';
      try {
        final data = (e as dynamic).response?.data;
        if (data is Map && data['mensagem'] != null) msg = data['mensagem'].toString();
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _abrirForm({Map<String, dynamic>? faixa}) {
    if (_modalidadeId == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FaixaFormSheet(
        modalidadeId: _modalidadeId!,
        faixa: faixa,
        proximaOrdem: _faixas.isEmpty ? 1 : (_faixas.last['ordem'] as int? ?? 0) + 1,
        onSalvo: _loadFaixas,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: kText1, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('Gestão de Faixas', style: TextStyle(color: kText1, fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      floatingActionButton: (!_loading && !_erro && _modalidadeId != null)
          ? FloatingActionButton.extended(
              onPressed: () => _abrirForm(),
              backgroundColor: kPrimary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Nova Faixa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            )
          : null,
      body: Column(
        children: [
          if (_modalidades.isNotEmpty)
            Container(
              color: kSurface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: DropdownButtonFormField<String>(
                value: _modalidadeId,
                dropdownColor: kSurface,
                style: TextStyle(color: kText1, fontSize: 14),
                iconEnabledColor: kText2,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  filled: true,
                  fillColor: kBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kPrimary, width: 1.5)),
                  prefixIcon: Icon(Icons.sports_martial_arts_rounded, color: kPrimary, size: 18),
                ),
                items: _modalidades.map((m) => DropdownMenuItem<String>(
                  value: m['id']?.toString(),
                  child: Text(m['nome']?.toString() ?? '', style: TextStyle(color: kText1)),
                )).toList(),
                onChanged: (id) {
                  if (id == null) return;
                  setState(() { _modalidadeId = id; });
                  _loadFaixas();
                },
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _erro
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline_rounded, color: kDanger, size: 52),
                            const SizedBox(height: 14),
                            Text('Não foi possível carregar', style: TextStyle(color: kText2)),
                            const SizedBox(height: 18),
                            OutlinedButton.icon(
                              onPressed: _init,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Tentar novamente'),
                              style: OutlinedButton.styleFrom(foregroundColor: kPrimary),
                            ),
                          ],
                        ),
                      )
                    : _modalidades.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.sports_martial_arts_rounded, color: kText2, size: 52),
                                const SizedBox(height: 14),
                                Text('Nenhuma modalidade cadastrada', style: TextStyle(color: kText2)),
                              ],
                            ),
                          )
                        : _faixas.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.military_tech_rounded, color: kText2, size: 52),
                                    const SizedBox(height: 14),
                                    Text('Nenhuma faixa cadastrada', style: TextStyle(color: kText2)),
                                    const SizedBox(height: 8),
                                    Text('Toque em + para adicionar', style: TextStyle(color: kText2.withOpacity(0.6), fontSize: 12)),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                                itemCount: _faixas.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (_, i) => _FaixaCard(
                                  faixa: _faixas[i],
                                  onEdit: () => _abrirForm(faixa: _faixas[i]),
                                  onDelete: () => _deletar(_faixas[i]),
                                ),
                              ),
          ),
        ],
      ),
    );
  }
}

class _FaixaCard extends StatelessWidget {
  const _FaixaCard({required this.faixa, required this.onEdit, required this.onDelete});
  final Map<String, dynamic> faixa;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color _parseColor(String? hex) {
    try {
      if (hex == null) return Colors.grey;
      final h = hex.replaceFirst('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cor = _parseColor(faixa['cor']?.toString());
    final ordem = faixa['ordem'] as int? ?? 0;
    final meses = faixa['requisitosMesesMinimos'] as int? ?? 0;
    final presencas = faixa['requisitosPresencasMinimas'] as int? ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: cor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cor, width: 2),
          ),
          child: Center(
            child: Text(
              '$ordem',
              style: TextStyle(color: cor, fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
            ),
            Expanded(
              child: Text(
                faixa['nome']?.toString() ?? '',
                style: TextStyle(color: kText1, fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 8,
            children: [
              if (meses > 0)
                _Tag(Icons.calendar_month_rounded, '$meses meses', kWarning),
              if (presencas > 0)
                _Tag(Icons.check_circle_outline_rounded, '$presencas presenças', kSuccess),
              if (faixa['descricao'] != null && (faixa['descricao'] as String).isNotEmpty)
                _Tag(Icons.info_outline_rounded, faixa['descricao'].toString(), kText2),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onEdit,
              icon: Icon(Icons.edit_rounded, color: kPrimary, size: 20),
              tooltip: 'Editar',
            ),
            IconButton(
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline_rounded, color: kDanger, size: 20),
              tooltip: 'Remover',
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.icon, this.text, this.color);
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Flexible(
          child: Text(text, style: TextStyle(color: color, fontSize: 11), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _FaixaFormSheet extends StatefulWidget {
  const _FaixaFormSheet({
    required this.modalidadeId,
    required this.onSalvo,
    required this.proximaOrdem,
    this.faixa,
  });

  final String modalidadeId;
  final Map<String, dynamic>? faixa;
  final int proximaOrdem;
  final VoidCallback onSalvo;

  @override
  State<_FaixaFormSheet> createState() => _FaixaFormSheetState();
}

class _FaixaFormSheetState extends State<_FaixaFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _mesesCtrl = TextEditingController();
  final _presencasCtrl = TextEditingController();
  final _ordemCtrl = TextEditingController();
  String _cor = '#FF0000';
  bool _salvando = false;

  static const _cores = [
    '#FFFFFF', '#F5F5DC', '#FFFF00', '#FFA500',
    '#008000', '#0000FF', '#8B00FF', '#8B4513',
    '#FF0000', '#000000',
  ];

  @override
  void initState() {
    super.initState();
    final f = widget.faixa;
    if (f != null) {
      _nomeCtrl.text = f['nome']?.toString() ?? '';
      _descCtrl.text = f['descricao']?.toString() ?? '';
      _mesesCtrl.text = (f['requisitosMesesMinimos'] as int? ?? 0).toString();
      _presencasCtrl.text = (f['requisitosPresencasMinimas'] as int? ?? 0).toString();
      _ordemCtrl.text = (f['ordem'] as int? ?? 1).toString();
      _cor = f['cor']?.toString() ?? '#FF0000';
    } else {
      _mesesCtrl.text = '0';
      _presencasCtrl.text = '0';
      _ordemCtrl.text = widget.proximaOrdem.toString();
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _descCtrl.dispose();
    _mesesCtrl.dispose();
    _presencasCtrl.dispose();
    _ordemCtrl.dispose();
    super.dispose();
  }

  Color _parseColor(String hex) {
    try {
      final h = hex.replaceFirst('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _salvando = true; });
    try {
      final data = {
        'modalidadeId': widget.modalidadeId,
        'nome': _nomeCtrl.text.trim(),
        'cor': _cor,
        'ordem': int.tryParse(_ordemCtrl.text) ?? 1,
        'requisitosMesesMinimos': int.tryParse(_mesesCtrl.text) ?? 0,
        'requisitosPresencasMinimas': int.tryParse(_presencasCtrl.text) ?? 0,
        'descricao': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      };
      if (widget.faixa != null) {
        await dio.put('/api/faixas/${widget.faixa!['id']}', data: data);
      } else {
        await dio.post('/api/faixas', data: data);
      }
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSalvo();
    } catch (e) {
      if (!mounted) return;
      String msg = 'Erro ao salvar faixa';
      try {
        final d = (e as dynamic).response?.data;
        if (d is Map && d['mensagem'] != null) msg = d['mensagem'].toString();
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() { _salvando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.faixa != null;
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.military_tech_rounded, color: kPrimary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEdit ? 'Editar Faixa' : 'Nova Faixa',
                    style: TextStyle(color: kText1, fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nomeCtrl,
                style: TextStyle(color: kText1),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                decoration: _inputDeco('Nome da Faixa', Icons.label_rounded),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ordemCtrl,
                      style: TextStyle(color: kText1),
                      keyboardType: TextInputType.number,
                      validator: (v) => (v == null || int.tryParse(v) == null) ? 'Número inválido' : null,
                      decoration: _inputDeco('Ordem', Icons.format_list_numbered_rounded),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _mesesCtrl,
                      style: TextStyle(color: kText1),
                      keyboardType: TextInputType.number,
                      decoration: _inputDeco('Meses mínimos', Icons.calendar_month_rounded),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _presencasCtrl,
                      style: TextStyle(color: kText1),
                      keyboardType: TextInputType.number,
                      decoration: _inputDeco('Presenças mín.', Icons.check_circle_outline_rounded),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                style: TextStyle(color: kText1),
                decoration: _inputDeco('Descrição (opcional)', Icons.notes_rounded),
              ),
              const SizedBox(height: 16),
              Text('Cor da Faixa', style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _cores.map((hex) {
                  final selected = hex == _cor;
                  final color = _parseColor(hex);
                  return GestureDetector(
                    onTap: () => setState(() { _cor = hex; }),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? kPrimary : kBorder,
                          width: selected ? 3 : 1.5,
                        ),
                        boxShadow: selected
                            ? [BoxShadow(color: kPrimary.withOpacity(0.4), blurRadius: 6)]
                            : null,
                      ),
                      child: selected
                          ? Icon(Icons.check_rounded,
                              size: 18,
                              color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _salvando ? null : _salvar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _salvando
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(isEdit ? 'Salvar Alterações' : 'Criar Faixa',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: kText2, fontSize: 12),
    prefixIcon: Icon(icon, color: kText2, size: 17),
    filled: true,
    fillColor: kBg,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPrimary, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kDanger)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kDanger, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );
}
