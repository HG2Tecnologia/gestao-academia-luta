import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';

class AdminModalidadesScreen extends StatefulWidget {
  const AdminModalidadesScreen({super.key});

  @override
  State<AdminModalidadesScreen> createState() => _AdminModalidadesScreenState();
}

class _AdminModalidadesScreenState extends State<AdminModalidadesScreen> {
  List<Map<String, dynamic>> _modalidades = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    try {
      final res = await dio.get('/api/modalidades');
      final dados = res.data['dados'] as List? ?? [];
      setState(() => _modalidades = dados.cast<Map<String, dynamic>>());
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(Map<String, dynamic> m) async {
    try {
      await dio.patch('/api/modalidades/${m['id']}/toggle-ativo');
      await _carregar();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Erro ao alterar modalidade.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _excluir(Map<String, dynamic> m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Excluir "${m['nome']}"?', style: TextStyle(color: kText1, fontWeight: FontWeight.w800)),
        content: Text('Esta modalidade será removida permanentemente desta academia. Não é possível excluir modalidades com turmas cadastradas.', style: TextStyle(color: kText2)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar', style: TextStyle(color: kText2))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Excluir', style: TextStyle(color: kDanger, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await dio.delete('/api/modalidades/${m['id']}');
      await _carregar();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Não é possível excluir. Verifique se há turmas cadastradas.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _novaModalidade() async {
    final nomeCtrl = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: kSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Nova Modalidade', style: TextStyle(color: kText1, fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextField(
              controller: nomeCtrl,
              autofocus: true,
              style: TextStyle(color: kText1),
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Nome da modalidade',
                labelStyle: TextStyle(color: kText2),
                filled: true, fillColor: kBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPrimary, width: 1.5)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: kPrimary, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Criar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );

    if (ok != true || nomeCtrl.text.trim().isEmpty) return;
    try {
      await dio.post('/api/modalidades', data: {'nome': nomeCtrl.text.trim(), 'ativo': true});
      await _carregar();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Modalidade criada!'), backgroundColor: kSuccess, behavior: SnackBarBehavior.floating));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Erro ao criar modalidade.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ativas = _modalidades.where((m) => m['ativo'] == true).toList();
    final inativas = _modalidades.where((m) => m['ativo'] != true).toList();

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kSurface,
        foregroundColor: kText1,
        title: const Text('Modalidades', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: Icon(Icons.add_rounded, color: kPrimary), onPressed: _novaModalidade, tooltip: 'Nova modalidade'),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregar,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E40AF).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Modalidades ativas aparecem na gestão de faixas, turmas e demais telas. Inativas ficam ocultas mas não são excluídas.',
                      style: TextStyle(color: kText2, fontSize: 13, height: 1.5),
                    ),
                  ),

                  if (ativas.isNotEmpty) ...[
                    Text('ATIVAS (${ativas.length})', style: TextStyle(color: kText2, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    ...ativas.map((m) => _ModalidadeCard(m: m, onToggle: () => _toggle(m), onExcluir: () => _excluir(m))),
                    const SizedBox(height: 20),
                  ],

                  if (inativas.isNotEmpty) ...[
                    Text('INATIVAS (${inativas.length})', style: TextStyle(color: kText2, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    ...inativas.map((m) => _ModalidadeCard(m: m, onToggle: () => _toggle(m), onExcluir: () => _excluir(m))),
                  ],

                  if (_modalidades.isEmpty)
                    Center(child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Text('Nenhuma modalidade cadastrada.', style: TextStyle(color: kText2)),
                    )),
                ],
              ),
            ),
    );
  }
}

class _ModalidadeCard extends StatelessWidget {
  final Map<String, dynamic> m;
  final VoidCallback onToggle;
  final VoidCallback onExcluir;

  const _ModalidadeCard({required this.m, required this.onToggle, required this.onExcluir});

  @override
  Widget build(BuildContext context) {
    final ativo = m['ativo'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ativo ? kBorder : kBorder.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              m['nome'] as String? ?? '',
              style: TextStyle(
                color: ativo ? kText1 : kText2,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: ativo ? kSuccess.withValues(alpha: 0.12) : kBorder.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ativo ? kSuccess.withValues(alpha: 0.4) : kBorder),
              ),
              child: Text(
                ativo ? 'Ativa' : 'Inativa',
                style: TextStyle(color: ativo ? kSuccess : kText2, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onExcluir,
            child: Icon(Icons.delete_outline_rounded, color: kDanger.withValues(alpha: 0.6), size: 20),
          ),
        ],
      ),
    );
  }
}
