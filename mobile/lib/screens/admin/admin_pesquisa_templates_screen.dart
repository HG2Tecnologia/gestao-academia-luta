import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/firestore_service.dart';

class AdminPesquisaTemplatesScreen extends StatefulWidget {
  const AdminPesquisaTemplatesScreen({super.key});

  @override
  State<AdminPesquisaTemplatesScreen> createState() => _AdminPesquisaTemplatesScreenState();
}

class _AdminPesquisaTemplatesScreenState extends State<AdminPesquisaTemplatesScreen> {
  List<Map<String, dynamic>> _templates = [];
  bool _loading = true;
  bool _erro = false;
  String? _academiaId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _erro = false; });
    try {
      final user = await AuthStorage.getUser();
      if (user == null) { if (mounted) setState(() { _loading = false; _erro = true; }); return; }
      _academiaId = user.academiaId;
      final list = await firestoreService.getPesquisaTemplates(user.academiaId!);
      if (mounted) setState(() { _templates = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _erro = true; });
    }
  }

  Future<void> _criarOuEditar({Map<String, dynamic>? template}) async {
    final tituloCtrl = TextEditingController(text: template?['titulo'] as String? ?? '');
    final descCtrl = TextEditingController(text: template?['descricao'] as String? ?? '');
    final isEdicao = template != null;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(
                  isEdicao ? 'Editar pesquisa' : 'Nova pesquisa',
                  style: TextStyle(color: kText1, fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: kText2),
                onPressed: () => Navigator.of(ctx).pop(false),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ]),
            const SizedBox(height: 16),
            TextField(
              controller: tituloCtrl,
              style: TextStyle(color: kText1),
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Título da pesquisa *',
                hintStyle: TextStyle(color: kText2, fontSize: 14),
                filled: true,
                fillColor: kBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPrimary)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              style: TextStyle(color: kText1),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Descrição (opcional)',
                hintStyle: TextStyle(color: kText2, fontSize: 14),
                filled: true,
                fillColor: kBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPrimary)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  if (tituloCtrl.text.trim().isEmpty) return;
                  Navigator.of(ctx).pop(true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(isEdicao ? 'Salvar alterações' : 'Criar pesquisa',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );

    if (ok != true || _academiaId == null) return;
    try {
      final data = {
        'titulo': tituloCtrl.text.trim(),
        if (descCtrl.text.trim().isNotEmpty) 'descricao': descCtrl.text.trim(),
        if (!isEdicao) 'ativa': false,
      };
      if (isEdicao) {
        await firestoreService.updatePesquisaTemplate(_academiaId!, template['id'] as String, data);
      } else {
        await firestoreService.addPesquisaTemplate(_academiaId!, data);
      }
      _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Erro ao salvar pesquisa.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _toggleAtivo(Map<String, dynamic> t) async {
    if (_academiaId == null) return;
    final id = t['id'] as String;
    final estaAtiva = t['ativa'] == true;
    try {
      if (estaAtiva) {
        await firestoreService.desativarPesquisaTemplate(_academiaId!, id);
      } else {
        await firestoreService.ativarPesquisaTemplate(_academiaId!, id);
      }
      _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Erro ao alterar status.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _deletar(Map<String, dynamic> t) async {
    if (_academiaId == null) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Excluir pesquisa?', style: TextStyle(color: kText1)),
        content: Text(
          'Ao excluir "${t['titulo']}", os dados de resposta desta pesquisa serão mantidos no histórico, mas o template não estará mais disponível.',
          style: TextStyle(color: kText2, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Cancelar', style: TextStyle(color: kText2))),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Excluir', style: TextStyle(color: kDanger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await firestoreService.deletePesquisaTemplate(_academiaId!, t['id'] as String);
      _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Erro ao excluir pesquisa.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
        );
      }
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
        title: const Text('Gerenciar Pesquisas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: kText1, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _criarOuEditar(),
        backgroundColor: kPrimary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Nova pesquisa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: kPrimary))
          : _erro
              ? Center(child: Text('Erro ao carregar.', style: TextStyle(color: kText2)))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: kPrimary,
                  child: _templates.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6,
                              child: Center(
                                child: Column(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.poll_outlined, color: kBorder, size: 56),
                                  const SizedBox(height: 16),
                                  Text('Nenhuma pesquisa criada ainda', style: TextStyle(color: kText2, fontSize: 14)),
                                  const SizedBox(height: 8),
                                  Text('Toque em "Nova pesquisa" para começar', style: TextStyle(color: kText2, fontSize: 12)),
                                ]),
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          children: [
                            // Aviso sobre pesquisa ativa
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: kPrimary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: kPrimary.withOpacity(0.2)),
                              ),
                              child: Row(children: [
                                Icon(Icons.info_outline_rounded, color: kPrimary, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Apenas uma pesquisa pode estar ativa por vez. A pesquisa ativa é exibida para os alunos no mês corrente.',
                                    style: TextStyle(color: kPrimary, fontSize: 12),
                                  ),
                                ),
                              ]),
                            ),
                            ..._templates.map((t) => _buildTemplateCard(t)),
                          ],
                        ),
                ),
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> t) {
    final ativa = t['ativa'] == true;
    final titulo = t['titulo']?.toString() ?? 'Sem título';
    final descricao = t['descricao']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ativa ? kPrimary.withOpacity(0.5) : kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (ativa)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('ATIVA', style: TextStyle(color: kPrimary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ),
            Expanded(
              child: Text(titulo, style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w700)),
            ),
            Switch(
              value: ativa,
              activeColor: kPrimary,
              onChanged: (_) => _toggleAtivo(t),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ]),
          if (descricao != null && descricao.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(descricao, style: TextStyle(color: kText2, fontSize: 12)),
          ],
          const SizedBox(height: 12),
          Row(children: [
            _acaoBtn(
              Icons.bar_chart_rounded,
              'Ver respostas',
              kPrimary,
              () => context.push('/admin/pesquisa', extra: t),
            ),
            const SizedBox(width: 8),
            _acaoBtn(
              Icons.edit_rounded,
              'Editar',
              kText2,
              () => _criarOuEditar(template: t),
            ),
            const SizedBox(width: 8),
            _acaoBtn(
              Icons.delete_outline_rounded,
              'Excluir',
              kDanger,
              () => _deletar(t),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _acaoBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
