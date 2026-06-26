import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';

class AdminGruposFamiliaresScreen extends StatefulWidget {
  const AdminGruposFamiliaresScreen({super.key});

  @override
  State<AdminGruposFamiliaresScreen> createState() => _AdminGruposFamiliaresScreenState();
}

class _AdminGruposFamiliaresScreenState extends State<AdminGruposFamiliaresScreen> {
  List<Map<String, dynamic>> _grupos = [];
  bool _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _erro = null; });
    try {
      final res = await dio.get('/api/grupos-familiares');
      final dados = res.data['dados'] as List? ?? [];
      if (mounted) setState(() => _grupos = dados.cast<Map<String, dynamic>>());
    } catch (e) {
      if (mounted) setState(() => _erro = 'Erro ao carregar grupos: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _criarGrupo() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Novo Grupo Familiar', style: TextStyle(color: kText1, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: kText1),
          decoration: InputDecoration(
            labelText: 'Nome do grupo (ex: Família Silva)',
            labelStyle: TextStyle(color: kText2),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: kBorder)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: kPrimary)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar', style: TextStyle(color: kText2))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Criar', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true || ctrl.text.trim().isEmpty || !mounted) return;
    try {
      await dio.post('/api/grupos-familiares', data: {'nome': ctrl.text.trim()});
      await _load();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Erro ao criar grupo.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _renomear(Map<String, dynamic> grupo) async {
    final ctrl = TextEditingController(text: grupo['nome'] as String? ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Renomear Grupo', style: TextStyle(color: kText1, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: kText1),
          decoration: InputDecoration(
            labelText: 'Nome',
            labelStyle: TextStyle(color: kText2),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: kBorder)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: kPrimary)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar', style: TextStyle(color: kText2))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Salvar', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok != true || ctrl.text.trim().isEmpty || !mounted) return;
    try {
      await dio.put('/api/grupos-familiares/${grupo['id']}', data: {'nome': ctrl.text.trim()});
      await _load();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Erro ao renomear.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _excluir(Map<String, dynamic> grupo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Excluir grupo?', style: TextStyle(color: kText1)),
        content: Text('Os membros serão desvinculados mas não excluídos.', style: TextStyle(color: kText2)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar', style: TextStyle(color: kText2))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Excluir', style: TextStyle(color: kDanger, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await dio.delete('/api/grupos-familiares/${grupo['id']}');
      await _load();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Erro ao excluir.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _removerMembro(String grupoId, Map<String, dynamic> membro) async {
    try {
      await dio.delete('/api/grupos-familiares/$grupoId/membros/${membro['id']}');
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${membro['nome']} removido do grupo.'), backgroundColor: kSuccess, behavior: SnackBarBehavior.floating));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Erro ao remover membro.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kSurface,
        foregroundColor: kText1,
        elevation: 0,
        title: const Text('Grupos Familiares', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            onPressed: _criarGrupo,
            icon: Icon(Icons.add_rounded, color: kPrimary),
            tooltip: 'Novo grupo',
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: kPrimary))
          : _erro != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_erro!, style: TextStyle(color: kDanger, fontSize: 13)),
                  const SizedBox(height: 12),
                  TextButton(onPressed: _load, child: Text('Tentar novamente', style: TextStyle(color: kPrimary))),
                ]))
              : _grupos.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _grupos.length,
                        itemBuilder: (_, i) => _buildGrupoCard(_grupos[i]),
                      ),
                    ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.family_restroom_rounded, size: 56, color: kText2.withOpacity(0.4)),
      const SizedBox(height: 16),
      Text('Nenhum grupo familiar criado.', style: TextStyle(color: kText2, fontSize: 15, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Text('Crie grupos para vincular membros da mesma família.', style: TextStyle(color: kText2.withOpacity(0.7), fontSize: 13), textAlign: TextAlign.center),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: _criarGrupo,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Criar grupo'),
        style: FilledButton.styleFrom(backgroundColor: kPrimary),
      ),
    ]),
  );

  Widget _buildGrupoCard(Map<String, dynamic> grupo) {
    final membros = (grupo['membros'] as List? ?? []).cast<Map<String, dynamic>>();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: kPrimary.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(Icons.family_restroom_rounded, color: kPrimary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(grupo['nome'] as String? ?? '', style: TextStyle(color: kText1, fontWeight: FontWeight.w700, fontSize: 14)),
                Text('${membros.length} membro${membros.length != 1 ? 's' : ''}', style: TextStyle(color: kText2, fontSize: 12)),
              ])),
              PopupMenuButton<String>(
                color: kSurface,
                icon: Icon(Icons.more_vert_rounded, color: kText2),
                onSelected: (v) {
                  if (v == 'renomear') _renomear(grupo);
                  if (v == 'excluir') _excluir(grupo);
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'renomear', child: Row(children: [Icon(Icons.edit_outlined, color: kPrimary, size: 18), const SizedBox(width: 10), const Text('Renomear')])),
                  PopupMenuItem(value: 'excluir', child: Row(children: [Icon(Icons.delete_outline_rounded, color: kDanger, size: 18), const SizedBox(width: 10), Text('Excluir', style: TextStyle(color: kDanger))])),
                ],
              ),
            ]),
          ),
          if (membros.isNotEmpty) ...[
            const Divider(height: 1),
            ...membros.map((m) => ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: kPrimary.withOpacity(0.15),
                child: Text(
                  (m['nome'] as String? ?? '').split(' ').take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase(),
                  style: TextStyle(color: kPrimary, fontWeight: FontWeight.w800, fontSize: 11),
                ),
              ),
              title: Text(m['nome'] as String? ?? '', style: TextStyle(color: kText1, fontWeight: FontWeight.w600, fontSize: 13)),
              subtitle: Text(m['perfil'] as String? ?? '', style: TextStyle(color: kText2, fontSize: 11)),
              trailing: IconButton(
                icon: Icon(Icons.link_off_rounded, color: kText2, size: 18),
                tooltip: 'Remover do grupo',
                onPressed: () => _removerMembro(grupo['id'] as String, m),
              ),
            )),
          ] else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text('Nenhum membro. Adicione via detalhes do aluno.', style: TextStyle(color: kText2, fontSize: 12, fontStyle: FontStyle.italic)),
            ),
        ],
      ),
    );
  }
}
