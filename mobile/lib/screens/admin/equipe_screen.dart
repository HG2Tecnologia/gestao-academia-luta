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
                GestureDetector(onTap: openAppDrawer, child: Icon(Icons.menu_rounded, color: kText1, size: 26)),
                const SizedBox(width: 14),
                Text('Equipe', style: TextStyle(color: kText1, fontSize: 22, fontWeight: FontWeight.w800)),
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
                                  return Container(
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
                                        IconButton(
                                          onPressed: () => _remover(f['id'] as String? ?? '', f['nome'] as String? ?? ''),
                                          icon: Icon(Icons.close, color: kDanger),
                                          style: IconButton.styleFrom(backgroundColor: kDanger.withOpacity(0.12)),
                                        ),
                                      ],
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
