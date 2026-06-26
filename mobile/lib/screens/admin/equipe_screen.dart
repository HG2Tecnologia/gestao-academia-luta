import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/ad_banner.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../core/drawer_helper.dart';

class AdminEquipeScreen extends StatefulWidget {
  const AdminEquipeScreen({super.key});

  @override
  State<AdminEquipeScreen> createState() => _AdminEquipeScreenState();
}

class _AdminEquipeScreenState extends State<AdminEquipeScreen> {
  List<Map<String, dynamic>> _funcs = [];
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
      final res = await dio.get('/api/funcionarios');
      final body = res.data as Map<String, dynamic>;
      final dados = body['dados'];
      final list = dados is List ? dados : [];
      if (mounted) setState(() => _funcs = list.cast<Map<String, dynamic>>());
    } catch (e) {
      if (mounted) setState(() => _erro = 'Erro ao carregar equipe: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _abrirOpcoes(Map<String, dynamic> f) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                CircleAvatar(radius: 18, backgroundColor: kPrimary, child: Text(
                  (f['nome'] as String? ?? '').split(' ').take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                )),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(f['nome'] ?? '', style: TextStyle(color: kText1, fontWeight: FontWeight.w700)),
                  Text(f['perfil'] ?? '', style: TextStyle(color: kText2, fontSize: 12)),
                ])),
              ]),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: kPrimary),
              title: Text('Editar', style: TextStyle(color: kText1, fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(context);
                await _editarFuncionario(f);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: kDanger),
              title: Text('Remover da equipe', style: TextStyle(color: kDanger, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _remover(f['id'] as String? ?? '', f['nome'] as String? ?? '');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _editarFuncionario(Map<String, dynamic> f) async {
    final nomeCtrl = TextEditingController(text: f['nome'] as String? ?? '');
    final cargoCtrl = TextEditingController(text: f['cargo'] as String? ?? '');
    String perfil = f['perfil'] as String? ?? 'Professor';
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Editar membro', style: TextStyle(color: kText1, fontWeight: FontWeight.w800)),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: nomeCtrl,
              style: TextStyle(color: kText1),
              decoration: InputDecoration(labelText: 'Nome', labelStyle: TextStyle(color: kText2), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: kBorder)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: kPrimary))),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: cargoCtrl,
              style: TextStyle(color: kText1),
              decoration: InputDecoration(labelText: 'Cargo (opcional)', labelStyle: TextStyle(color: kText2), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: kBorder)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: kPrimary))),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: perfil,
              dropdownColor: kSurface,
              style: TextStyle(color: kText1),
              decoration: InputDecoration(labelText: 'Perfil', labelStyle: TextStyle(color: kText2), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: kBorder)), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: kPrimary))),
              items: ['Professor', 'Secretaria', 'Admin'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (v) { if (v != null) setSt(() => perfil = v); },
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar', style: TextStyle(color: kText2))),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: Text('Salvar', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700)),
          ),
        ],
      )),
    );

    if (ok != true || !mounted) return;
    try {
      await dio.put('/api/funcionarios/${f['id']}', data: {
        'nome': nomeCtrl.text.trim(),
        'cargo': cargoCtrl.text.trim().isEmpty ? null : cargoCtrl.text.trim(),
        'perfil': perfil,
      });
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Membro atualizado!'), backgroundColor: kSuccess, behavior: SnackBarBehavior.floating));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Erro ao atualizar.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _remover(String id, String nome) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Remover', style: TextStyle(color: kText1)),
        content: Text('Remover $nome da equipe?', style: TextStyle(color: kText2)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Cancelar', style: TextStyle(color: kText2))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text('Remover', style: TextStyle(color: kDanger))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await dio.delete('/api/funcionarios/$id');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Funcionário removido.'), backgroundColor: kSuccess, behavior: SnackBarBehavior.floating),
        );
        await _load();
      }
    } catch (e) {
      if (mounted) {
        String msg = 'Não foi possível remover.';
        try {
          final body = (e as dynamic).response?.data as Map?;
          msg = body?['mensagem'] as String? ?? msg;
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/admin/equipe/novo');
          _load();
        },
        backgroundColor: kPrimary,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Row(children: [
                Text('Equipe', style: TextStyle(color: kText1, fontSize: 22, fontWeight: FontWeight.w800)),
                const Spacer(),
                GestureDetector(onTap: openAppDrawer, child: Icon(Icons.menu_rounded, color: kText1, size: 26)),
              ]),
            ),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: kPrimary))
                  : _erro != null
                      ? Center(child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_erro!, style: TextStyle(color: kDanger, fontSize: 13), textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              TextButton(onPressed: _load, child: Text('Tentar novamente', style: TextStyle(color: kPrimary))),
                            ],
                          ),
                        ))
                      : _funcs.isEmpty
                          ? Center(child: Text('Nenhum funcionário cadastrado.', style: TextStyle(color: kText2)))
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _funcs.length,
                                itemBuilder: (_, i) {
                                  final f = _funcs[i];
                                  final nome = f['nome'] as String? ?? '';
                                  final initials = nome.trim().split(RegExp(r'\s+')).take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();
                                  return GestureDetector(
                                    onTap: () => _abrirOpcoes(f),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: kSurface,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: kBorder),
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 22,
                                            backgroundColor: kPrimary,
                                            child: Text(initials.isEmpty ? '?' : initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(f['nome'] ?? '', style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w700)),
                                                Text(
                                                  [f['perfil'], f['cargo']].where((s) => s != null && s != '').join(' · '),
                                                  style: TextStyle(color: kText2, fontSize: 12),
                                                ),
                                                if (f['email'] != null && (f['email'] as String).isNotEmpty)
                                                  Text(f['email'], style: TextStyle(color: kText2, fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                          Icon(Icons.more_vert_rounded, color: kText2, size: 20),
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
