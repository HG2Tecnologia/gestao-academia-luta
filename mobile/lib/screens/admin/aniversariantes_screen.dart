import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';

class AdminAniversariantesScreen extends StatefulWidget {
  const AdminAniversariantesScreen({super.key});

  @override
  State<AdminAniversariantesScreen> createState() => _AdminAniversariantesScreenState();
}

class _AdminAniversariantesScreenState extends State<AdminAniversariantesScreen> {
  List<Map<String, dynamic>> _alunos = [];
  bool _loading = true;
  bool _erro = false;
  int _mes = DateTime.now().month;

  static const _meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
  static const _mesesFull = ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _erro = false; });
    try {
      final res = await dio.get('/api/alunos/aniversariantes', queryParameters: {'mes': _mes});
      final dados = res.data['dados'] as List? ?? [];
      if (mounted) setState(() {
        _alunos = dados.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _erro = true; });
    }
  }

  bool get _ehMesAtual => _mes == DateTime.now().month;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back, color: kText1),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                Icon(Icons.cake_rounded, color: kWarning, size: 22),
                const SizedBox(width: 8),
                Expanded(child: Text('Aniversariantes', style: TextStyle(color: kText1, fontSize: 22, fontWeight: FontWeight.w800))),
              ]),
            ),

            // Seletor de mês
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: 12,
                itemBuilder: (_, i) {
                  final selected = _mes == i + 1;
                  return GestureDetector(
                    onTap: () { setState(() => _mes = i + 1); _load(); },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? kPrimary : kSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: selected ? kPrimary : kBorder),
                      ),
                      child: Text(
                        _meses[i],
                        style: TextStyle(
                          color: selected ? Colors.white : kText2,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(children: [
                Text(
                  _mesesFull[_mes - 1],
                  style: TextStyle(color: kText1, fontSize: 15, fontWeight: FontWeight.w700),
                ),
                if (_ehMesAtual) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: kWarning.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                    child: Text('Mês atual', style: TextStyle(color: kWarning, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
              ]),
            ),

            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: kPrimary))
                  : _erro
                      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.error_outline, color: kDanger, size: 36),
                          const SizedBox(height: 8),
                          Text('Erro ao carregar', style: TextStyle(color: kText2)),
                          TextButton(onPressed: _load, child: Text('Tentar novamente', style: TextStyle(color: kPrimary))),
                        ]))
                      : _alunos.isEmpty
                          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.cake_outlined, color: kText2, size: 48),
                              const SizedBox(height: 12),
                              Text('Nenhum aniversariante em ${_mesesFull[_mes - 1]}', style: TextStyle(color: kText2, fontSize: 14), textAlign: TextAlign.center),
                            ]))
                          : RefreshIndicator(
                              onRefresh: _load,
                              color: kPrimary,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: _alunos.length,
                                itemBuilder: (_, i) => _AlunoCard(a: _alunos[i], mes: _mes, mesAtual: _ehMesAtual),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlunoCard extends StatelessWidget {
  final Map<String, dynamic> a;
  final int mes;
  final bool mesAtual;

  const _AlunoCard({required this.a, required this.mes, required this.mesAtual});

  bool get _ehHoje {
    if (!mesAtual) return false;
    return (a['diaNascimento'] as int?) == DateTime.now().day;
  }

  @override
  Widget build(BuildContext context) {
    final dia = a['diaNascimento'] as int? ?? 0;
    final nome = a['nome'] as String? ?? '—';
    final initials = nome.trim().split(' ').take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
    final dataFormatada = '${dia.toString().padLeft(2, '0')}/${mes.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _ehHoje ? kWarning.withOpacity(0.08) : kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _ehHoje ? kWarning.withOpacity(0.4) : kBorder),
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: kPrimary.withOpacity(0.15),
          ),
          child: Center(child: Text(initials, style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 14))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(nome, style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(dataFormatada, style: TextStyle(color: kText2, fontSize: 12)),
        ])),
        if (_ehHoje) ...[
          Text('🎂', style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 4),
        ],
        if (!_ehHoje)
          Text(dataFormatada, style: TextStyle(color: kText2, fontSize: 16, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
