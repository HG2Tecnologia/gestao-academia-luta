import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/drawer_helper.dart';

class ProfTurmasScreen extends StatefulWidget {
  const ProfTurmasScreen({super.key});

  @override
  State<ProfTurmasScreen> createState() => _ProfTurmasScreenState();
}

class _ProfTurmasScreenState extends State<ProfTurmasScreen> {
  List<Map<String, dynamic>> _turmas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final me = await dio.get('/api/usuarios/me');
      final uid = (me.data['dados'] as Map<String, dynamic>?)?['id'] ?? '';
      final res = await dio.get('/api/turmas', queryParameters: {'professorId': uid});
      final body = res.data as Map<String, dynamic>;
      final dados = body['dados'];
      final list = dados is List ? dados : (dados is Map ? dados['items'] as List? ?? [] : []);
      if (mounted) setState(() => _turmas = list.cast<Map<String, dynamic>>());
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
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
                GestureDetector(onTap: openAppDrawer, child: Icon(Icons.menu_rounded, color: kText1, size: 26)),
                const SizedBox(width: 14),
                Text('Minhas Turmas', style: TextStyle(color: kText1, fontSize: 22, fontWeight: FontWeight.w800)),
              ]),
            ),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: kPrimary))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: kPrimary,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _turmas.length,
                      itemBuilder: (_, i) {
                        final t = _turmas[i];
                        return Container(
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
                              Text(t['nome'] ?? '', style: TextStyle(color: kText1, fontSize: 15, fontWeight: FontWeight.w700)),
                              if (t['nomeModalidade'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(t['nomeModalidade'], style: TextStyle(color: kText2, fontSize: 13)),
                                ),
                              const SizedBox(height: 8),
                              Row(children: [
                                Text('${t['totalAlunos'] ?? 0}', style: TextStyle(color: kPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
                                Text(' / ${t['capacidadeMaxima'] ?? 0} alunos', style: TextStyle(color: kText2, fontSize: 13)),
                              ]),
                            ],
                          ),
                        );
                      },
                    ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
