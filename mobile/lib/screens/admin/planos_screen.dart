import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/firestore_service.dart';

class AdminPlanosScreen extends StatefulWidget {
  const AdminPlanosScreen({super.key});

  @override
  State<AdminPlanosScreen> createState() => _AdminPlanosScreenState();
}

class _AdminPlanosScreenState extends State<AdminPlanosScreen> {
  List<Map<String, dynamic>> _planos = [];
  String? _academiaId;
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
      final user = await AuthStorage.getUser();
      _academiaId = user?.academiaId;
      if (_academiaId == null) throw Exception('Academia não identificada');
      final planos = await firestoreService.getPlanos(_academiaId!);
      if (mounted) setState(() => _planos = planos);
    } catch (_) {
      if (mounted) setState(() => _erro = 'Erro ao carregar planos.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _abrirFormulario({Map<String, dynamic>? plano}) async {
    final nomeCtrl = TextEditingController(text: plano?['nome']?.toString() ?? '');
    final valorCtrl = TextEditingController(
      text: plano != null
          ? (plano['valor_mensal'] as num?)?.toDouble().toStringAsFixed(2) ?? ''
          : '',
    );
    final descCtrl = TextEditingController(text: plano?['descricao']?.toString() ?? '');
    bool salvando = false;
    String? erro;
    final isEdit = plano != null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(isEdit ? 'Editar Plano' : 'Novo Plano',
                      style: TextStyle(color: kText1, fontSize: 18, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.of(ctx).pop(), icon: Icon(Icons.close, color: kText2)),
                ]),
                const Divider(height: 20),
                _campo(nomeCtrl, 'Nome do plano *', TextInputType.text),
                const SizedBox(height: 10),
                _campo(valorCtrl, 'Valor mensal (R\$) *', const TextInputType.numberWithOptions(decimal: true),
                    formatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                    prefix: 'R\$ '),
                const SizedBox(height: 10),
                _campo(descCtrl, 'Descrição (opcional)', TextInputType.multiline, maxLines: 3),
                if (erro != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: kDanger.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                    child: Text(erro!, style: TextStyle(color: kDanger, fontSize: 13)),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: salvando ? null : () async {
                      final nome = nomeCtrl.text.trim();
                      final valorStr = valorCtrl.text.trim().replaceAll(',', '.');
                      final valor = double.tryParse(valorStr);
                      if (nome.isEmpty) {
                        setModal(() => erro = 'Nome é obrigatório.');
                        return;
                      }
                      if (valor == null || valor <= 0) {
                        setModal(() => erro = 'Informe um valor mensal válido.');
                        return;
                      }
                      setModal(() { salvando = true; erro = null; });
                      try {
                        final data = {
                          'nome': nome,
                          'valor_mensal': valor,
                          'descricao': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                        };
                        if (isEdit) {
                          await firestoreService.updatePlano(_academiaId!, plano['id'], data);
                        } else {
                          await firestoreService.addPlano(_academiaId!, data);
                        }
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(isEdit ? 'Plano atualizado!' : 'Plano criado!'),
                            backgroundColor: kSuccess,
                            behavior: SnackBarBehavior.floating,
                          ));
                          _load();
                        }
                      } catch (_) {
                        setModal(() { salvando = false; erro = 'Erro ao salvar plano.'; });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: salvando
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(isEdit ? 'Salvar alterações' : 'Criar plano',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // NÃO faz dispose aqui: `await showModalBottomSheet` resolve assim que o
    // modal é fechado (pop), mas o widget continua montado e desenhando
    // frames durante a animação de saída (~250ms). Destruir os controllers
    // nesse meio tempo derruba o app ("TextEditingController usado após
    // dispose"). Controllers locais sem listeners pendentes não vazam de
    // forma relevante ao deixar de ser destruídos.
  }

  Future<void> _confirmarExclusao(Map<String, dynamic> plano) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Excluir plano', style: TextStyle(color: kText1, fontWeight: FontWeight.w700)),
        content: Text('Excluir o plano "${plano['nome']}"?\nAlunos vinculados não serão afetados.',
            style: TextStyle(color: kText2, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Cancelar', style: TextStyle(color: kText2))),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Excluir', style: TextStyle(color: kDanger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await firestoreService.deletePlano(_academiaId!, plano['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Plano excluído.'),
          backgroundColor: kSuccess,
          behavior: SnackBarBehavior.floating,
        ));
        _load();
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Erro ao excluir plano.'),
        backgroundColor: kDanger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Widget _campo(TextEditingController ctrl, String hint, TextInputType keyboard,
      {List<TextInputFormatter>? formatters, String? prefix, int maxLines = 1}) =>
      TextField(
        controller: ctrl,
        keyboardType: keyboard,
        inputFormatters: formatters,
        maxLines: maxLines,
        style: TextStyle(color: kText1),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: kText2, fontSize: 14),
          prefixText: prefix,
          prefixStyle: TextStyle(color: kText2),
          filled: true, fillColor: kBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPrimary)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kSurface,
        foregroundColor: kText1,
        elevation: 0,
        title: Text('Planos de Pagamento', style: TextStyle(color: kText1, fontWeight: FontWeight.w700)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => _abrirFormulario(),
              icon: Icon(Icons.add_rounded, color: kPrimary, size: 18),
              label: Text('Novo', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: kPrimary))
          : _erro != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.error_outline_rounded, color: kDanger, size: 48),
                  const SizedBox(height: 12),
                  Text(_erro!, style: TextStyle(color: kText2)),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh_rounded), label: const Text('Tentar novamente'),
                      style: OutlinedButton.styleFrom(foregroundColor: kPrimary)),
                ]))
              : _planos.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.credit_card_off_rounded, color: kText2, size: 52),
                      const SizedBox(height: 14),
                      Text('Nenhum plano cadastrado.', style: TextStyle(color: kText2, fontSize: 15)),
                      const SizedBox(height: 8),
                      Text('Crie planos para vincular aos alunos.', style: TextStyle(color: kText2, fontSize: 13)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _abrirFormulario(),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Criar primeiro plano'),
                        style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _planos.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final p = _planos[i];
                          final valor = (p['valor_mensal'] as num?)?.toDouble();
                          final desc = p['descricao'] as String?;
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: kSurface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: kBorder),
                            ),
                            child: Row(children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: kPrimary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.credit_card_rounded, color: kPrimary, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(p['nome']?.toString() ?? '', style: TextStyle(color: kText1, fontSize: 15, fontWeight: FontWeight.w700)),
                                if (valor != null)
                                  Text(
                                    'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')} / mês',
                                    style: TextStyle(color: kPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                if (desc != null && desc.isNotEmpty)
                                  Text(desc, style: TextStyle(color: kText2, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ])),
                              IconButton(
                                icon: Icon(Icons.edit_rounded, color: kText2, size: 18),
                                onPressed: () => _abrirFormulario(plano: p),
                                tooltip: 'Editar',
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline_rounded, color: kDanger, size: 18),
                                onPressed: () => _confirmarExclusao(p),
                                tooltip: 'Excluir',
                              ),
                            ]),
                          );
                        },
                      ),
                    ),
    );
  }
}
