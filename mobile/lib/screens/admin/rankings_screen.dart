import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';

class AdminRankingsScreen extends StatefulWidget {
  const AdminRankingsScreen({super.key});

  @override
  State<AdminRankingsScreen> createState() => _AdminRankingsScreenState();
}

class _AdminRankingsScreenState extends State<AdminRankingsScreen> {
  List<Map<String, dynamic>> _rankings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await dio.get('/api/ranking/custom', queryParameters: {'incluirInativos': true});
      final body = res.data as Map<String, dynamic>;
      final dados = body['dados'] ?? body;
      setState(() => _rankings = (dados is List ? dados : []).cast<Map<String, dynamic>>());
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _novoRanking() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => CriarRankingSheet(onSalvo: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kSurface,
        foregroundColor: kText1,
        elevation: 0,
        title: const Text('Rankings', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.add_rounded), onPressed: _novoRanking, tooltip: 'Novo ranking'),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rankings.isEmpty
              ? _empty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _rankings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _RankingCard(
                      ranking: _rankings[i],
                      onTap: () async {
                        await context.push('/admin/rankings/${_rankings[i]['id']}', extra: _rankings[i]);
                        _load();
                      },
                      onToggleAtivo: () => _toggleAtivo(_rankings[i]),
                    ),
                  ),
                ),
    );
  }

  Future<void> _toggleAtivo(Map<String, dynamic> r) async {
    final ativo = r['ativo'] as bool;
    try {
      if (ativo) {
        await dio.delete('/api/ranking/custom/${r['id']}');
      } else {
        await dio.put('/api/ranking/custom/${r['id']}', data: {
          ...r,
          'ativo': true,
        });
      }
      _load();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.response?.data?['mensagem'] ?? 'Erro ao atualizar'),
          backgroundColor: kDanger,
        ));
      }
    }
  }

  Widget _empty() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.emoji_events_outlined, size: 56, color: kText2.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text('Nenhum ranking criado', style: TextStyle(color: kText2, fontSize: 15)),
          const SizedBox(height: 6),
          Text('Toque em + para criar seu primeiro ranking', style: TextStyle(color: kText2.withOpacity(0.6), fontSize: 12)),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _novoRanking,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Criar ranking'),
            style: FilledButton.styleFrom(backgroundColor: kPrimary),
          ),
        ]),
      );
}

class _RankingCard extends StatelessWidget {
  final Map<String, dynamic> ranking;
  final VoidCallback onTap;
  final VoidCallback onToggleAtivo;

  const _RankingCard({required this.ranking, required this.onTap, required this.onToggleAtivo});

  @override
  Widget build(BuildContext context) {
    final ativo = ranking['ativo'] as bool? ?? true;
    final incPresencas = ranking['incluirPresencas'] as bool? ?? false;
    final incManuais = ranking['incluirPontosManuais'] as bool? ?? false;

    final tags = <String>[];
    if (incPresencas) tags.add('Presenças ×${ranking['pesoPresencas'] ?? 1}');
    if (incManuais) tags.add('Pontos manuais ×${ranking['pesoManuais'] ?? 1}');

    final dataInicio = ranking['dataInicio'] != null
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(ranking['dataInicio']))
        : null;
    final dataFim = ranking['dataFim'] != null
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(ranking['dataFim']))
        : null;
    final periodoLabel = dataInicio != null || dataFim != null
        ? '${dataInicio ?? '...'} → ${dataFim ?? '...'}'
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: ativo ? 1.0 : 0.6,
        child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ativo ? kBorder : kBorder.withOpacity(0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.emoji_events_rounded, color: ativo ? kPrimary : kText2, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                ranking['nome'] ?? '',
                style: TextStyle(color: ativo ? kText1 : kText2, fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
            if (ranking['visivelParaAluno'] == true)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: kSuccess.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                child: Text('Visível aluno', style: TextStyle(color: kSuccess, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onToggleAtivo,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ativo ? kSuccess.withOpacity(0.12) : kDanger.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(ativo ? 'Ativo' : 'Inativo',
                    style: TextStyle(color: ativo ? kSuccess : kDanger, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
          if (ranking['descricao'] != null && (ranking['descricao'] as String).isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(ranking['descricao'], style: TextStyle(color: kText2, fontSize: 12)),
          ],
          if (tags.isNotEmpty || periodoLabel != null) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 4, children: [
              ...tags.map((t) => _tag(t)),
              if (periodoLabel != null)
                _tag(periodoLabel, color: kWarning),
            ]),
          ],
          const SizedBox(height: 10),
          Row(children: [
            Icon(Icons.chevron_right_rounded, color: kText2, size: 16),
            Text('Ver leaderboard e lançar pontos', style: TextStyle(color: kText2, fontSize: 12)),
          ]),
        ]),
      ),
      ),
    );
  }

  Widget _tag(String label, {Color? color}) {
    final c = color ?? kPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Bottom Sheet: Criar/Editar Ranking ─────────────────────────────────────

class CriarRankingSheet extends StatefulWidget {
  final Map<String, dynamic>? ranking;
  final VoidCallback onSalvo;

  const CriarRankingSheet({super.key, this.ranking, required this.onSalvo});

  @override
  State<CriarRankingSheet> createState() => _CriarRankingSheetState();
}

class _CriarRankingSheetState extends State<CriarRankingSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _descricao = TextEditingController();
  final _pesoPresencas = TextEditingController(text: '1');
  final _pesoManuais = TextEditingController(text: '1');

  bool _incPresencas = true;
  bool _incManuais = true;
  bool _visivel = false;
  bool _salvando = false;
  String? _erro;

  DateTime? _dataInicio;
  DateTime? _dataFim;

  @override
  void initState() {
    super.initState();
    final r = widget.ranking;
    if (r != null) {
      _nome.text = r['nome'] ?? '';
      _descricao.text = r['descricao'] ?? '';
      _incPresencas = r['incluirPresencas'] ?? true;
      _incManuais = r['incluirPontosManuais'] ?? true;
      _pesoPresencas.text = (r['pesoPresencas'] ?? 1).toString();
      _pesoManuais.text = (r['pesoManuais'] ?? 1).toString();
      _visivel = r['visivelParaAluno'] ?? false;
      if (r['dataInicio'] != null) _dataInicio = DateTime.tryParse(r['dataInicio']);
      if (r['dataFim'] != null) _dataFim = DateTime.tryParse(r['dataFim']);
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _descricao.dispose();
    _pesoPresencas.dispose();
    _pesoManuais.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _salvando = true; _erro = null; });
    try {
      final body = {
        'nome': _nome.text.trim(),
        'descricao': _descricao.text.trim().isEmpty ? null : _descricao.text.trim(),
        'incluirPresencas': _incPresencas,
        'incluirPontosManuais': _incManuais,
        'pesoPresencas': int.tryParse(_pesoPresencas.text) ?? 1,
        'pesoManuais': int.tryParse(_pesoManuais.text) ?? 1,
        'visivelParaAluno': _visivel,
        'dataInicio': _dataInicio != null ? DateFormat('yyyy-MM-dd').format(_dataInicio!) : null,
        'dataFim': _dataFim != null ? DateFormat('yyyy-MM-dd').format(_dataFim!) : null,
        if (widget.ranking != null) 'ativo': widget.ranking!['ativo'],
      };

      if (widget.ranking == null) {
        await dio.post('/api/ranking/custom', data: body);
      } else {
        await dio.put('/api/ranking/custom/${widget.ranking!['id']}', data: body);
      }

      widget.onSalvo();
      if (mounted) Navigator.of(context).pop();
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data['mensagem'] ?? e.response!.data.toString())
          : 'Erro ${e.response?.statusCode ?? "de conexão"}.';
      setState(() => _erro = msg);
    } catch (e) {
      setState(() => _erro = 'Erro inesperado: $e');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(
                child: Text(
                  widget.ranking == null ? 'Novo ranking' : 'Editar ranking',
                  style: TextStyle(color: kText1, fontWeight: FontWeight.w700, fontSize: 17),
                ),
              ),
              IconButton(icon: Icon(Icons.close, color: kText2), onPressed: () => Navigator.of(context).pop()),
            ]),
            const SizedBox(height: 16),

            _field(_nome, 'Nome do ranking *', required: true),
            const SizedBox(height: 10),
            _field(_descricao, 'Descrição (opcional)'),
            const SizedBox(height: 20),

            Text('Composição dos pontos', style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            const SizedBox(height: 12),

            _toggleRow(
              'Incluir presenças',
              'Cada presença conta como pontos',
              _incPresencas,
              (v) => setState(() => _incPresencas = v),
            ),
            if (_incPresencas) ...[
              const SizedBox(height: 8),
              Row(children: [
                const SizedBox(width: 16),
                Text('Peso de cada presença:', style: TextStyle(color: kText2, fontSize: 13)),
                const SizedBox(width: 10),
                SizedBox(width: 60, child: _fieldNum(_pesoPresencas)),
              ]),
            ],
            const SizedBox(height: 10),

            _toggleRow(
              'Incluir pontos manuais',
              'Pontos lançados manualmente pelo professor/admin',
              _incManuais,
              (v) => setState(() => _incManuais = v),
            ),
            if (_incManuais) ...[
              const SizedBox(height: 8),
              Row(children: [
                const SizedBox(width: 16),
                Text('Peso dos pontos manuais:', style: TextStyle(color: kText2, fontSize: 13)),
                const SizedBox(width: 10),
                SizedBox(width: 60, child: _fieldNum(_pesoManuais)),
              ]),
            ],
            const SizedBox(height: 20),

            Text('Visibilidade', style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            const SizedBox(height: 12),
            _toggleRow(
              'Visível para os alunos',
              'Os alunos poderão ver este ranking no app',
              _visivel,
              (v) => setState(() => _visivel = v),
            ),
            const SizedBox(height: 20),

            Text('Período de validade', style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text('Presenças fora deste período serão ignoradas no cálculo.',
                style: TextStyle(color: kText2.withOpacity(0.7), fontSize: 11)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _datePicker(
                label: _dataInicio != null ? DateFormat('dd/MM/yyyy').format(_dataInicio!) : 'Data início',
                set: (d) => setState(() => _dataInicio = d),
                clear: () => setState(() => _dataInicio = null),
              )),
              const SizedBox(width: 10),
              const Text('→', style: TextStyle(color: Colors.white54)),
              const SizedBox(width: 10),
              Expanded(child: _datePicker(
                label: _dataFim != null ? DateFormat('dd/MM/yyyy').format(_dataFim!) : 'Data fim',
                set: (d) => setState(() => _dataFim = d),
                clear: () => setState(() => _dataFim = null),
              )),
            ]),

            if (_erro != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: kDanger.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Text(_erro!, style: TextStyle(color: kDanger, fontSize: 13)),
              ),
            ],

            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _salvando ? null : _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _salvando
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(widget.ranking == null ? 'Criar ranking' : 'Salvar alterações',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, {bool required = false}) => TextFormField(
        controller: ctrl,
        style: TextStyle(color: kText1),
        validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null : null,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: kText2, fontSize: 14),
          filled: true,
          fillColor: kBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kPrimary)),
        ),
      );

  Widget _fieldNum(TextEditingController ctrl) => TextFormField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        style: TextStyle(color: kText1, fontSize: 14),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          filled: true,
          fillColor: kBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: kBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: kBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: kPrimary)),
        ),
      );

  Widget _datePicker({required String label, required ValueChanged<DateTime?> set, required VoidCallback clear}) {
    final hasDate = !label.contains('/') ? false : true;
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (ctx, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: ColorScheme.dark(primary: kPrimary, surface: kSurface),
            ),
            child: child!,
          ),
        );
        if (picked != null) set(picked);
      },
      onLongPress: clear,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: kBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: hasDate ? kPrimary.withOpacity(0.6) : kBorder),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_rounded, size: 14, color: hasDate ? kPrimary : kText2),
          const SizedBox(width: 6),
          Expanded(child: Text(label,
              style: TextStyle(color: hasDate ? kPrimary : kText2, fontSize: 12),
              overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }

  Widget _toggleRow(String titulo, String sub, bool value, ValueChanged<bool> onChange) => Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(titulo, style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w600)),
              Text(sub, style: TextStyle(color: kText2, fontSize: 11)),
            ]),
          ),
          Switch(
            value: value,
            onChanged: onChange,
            activeColor: kPrimary,
            inactiveThumbColor: kText2,
            inactiveTrackColor: kBorder,
          ),
        ],
      );
}
