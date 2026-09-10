import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/auth_storage.dart';
import '../../core/theme/context_ext.dart';
import '../../l10n/app_localizations.dart';
import '../../core/firestore_service.dart';

class AdminPlanosScreen extends StatefulWidget {
  const AdminPlanosScreen({super.key});

  @override
  State<AdminPlanosScreen> createState() => _AdminPlanosScreenState();
}

class _AdminPlanosScreenState extends State<AdminPlanosScreen> {
  AppLocalizations get _l => context.l10n;
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
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final user = await AuthStorage.getUser();
      _academiaId = user?.academiaId;
      if (_academiaId == null) throw Exception('Academia não identificada');
      final planos = await firestoreService.getPlanos(_academiaId!);
      if (mounted) setState(() => _planos = planos);
    } catch (_) {
      if (mounted) setState(() => _erro = _l.plnLoadError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _abrirFormulario({Map<String, dynamic>? plano}) async {
    final nomeCtrl = TextEditingController(
      text: plano?['nome']?.toString() ?? '',
    );
    final valorCtrl = TextEditingController(
      text: plano != null
          ? (plano['valor_mensal'] as num?)?.toDouble().toStringAsFixed(2) ?? ''
          : '',
    );
    final descCtrl = TextEditingController(
      text: plano?['descricao']?.toString() ?? '',
    );
    bool salvando = false;
    String? erro;
    final isEdit = plano != null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.c.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isEdit ? _l.plnEditTitle : _l.plnNewTitle,
                      style: TextStyle(
                        color: context.c.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: Icon(
                        Icons.close,
                        color: context.c.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                _campo(nomeCtrl, _l.plnNameField, TextInputType.text),
                const SizedBox(height: 10),
                _campo(
                  valorCtrl,
                  _l.plnMonthlyValueField,
                  const TextInputType.numberWithOptions(decimal: true),
                  formatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                  ],
                  prefix: 'R\$ ',
                ),
                const SizedBox(height: 10),
                _campo(
                  descCtrl,
                  _l.commonDescriptionOptional,
                  TextInputType.multiline,
                  maxLines: 3,
                ),
                if (erro != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.sem.danger.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      erro!,
                      style: TextStyle(color: context.sem.danger, fontSize: 13),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: salvando
                        ? null
                        : () async {
                            final nome = nomeCtrl.text.trim();
                            final valorStr = valorCtrl.text.trim().replaceAll(
                              ',',
                              '.',
                            );
                            final valor = double.tryParse(valorStr);
                            if (nome.isEmpty) {
                              setModal(() => erro = _l.plnNameRequired);
                              return;
                            }
                            if (valor == null || valor <= 0) {
                              setModal(() => erro = _l.plnInvalidValue);
                              return;
                            }
                            setModal(() {
                              salvando = true;
                              erro = null;
                            });
                            try {
                              final data = {
                                'nome': nome,
                                'valor_mensal': valor,
                                'descricao': descCtrl.text.trim().isEmpty
                                    ? null
                                    : descCtrl.text.trim(),
                              };
                              if (isEdit) {
                                await firestoreService.updatePlano(
                                  _academiaId!,
                                  plano['id'],
                                  data,
                                );
                              } else {
                                await firestoreService.addPlano(
                                  _academiaId!,
                                  data,
                                );
                              }
                              if (ctx.mounted) Navigator.of(ctx).pop();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isEdit ? _l.plnUpdated : _l.plnCreated,
                                    ),
                                    backgroundColor: context.sem.success,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                _load();
                              }
                            } catch (_) {
                              setModal(() {
                                salvando = false;
                                erro = _l.plnSaveError;
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.c.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: salvando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isEdit ? _l.sdSaveChanges : _l.plnCreateBtn,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
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
        backgroundColor: context.c.surfaceContainer,
        title: Text(
          _l.plnDeleteTitle,
          style: TextStyle(
            color: context.c.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          _l.plnDeleteBody(plano['nome']?.toString() ?? ''),
          style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              _l.commonCancel,
              style: TextStyle(color: context.c.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              _l.commonDelete,
              style: TextStyle(
                color: context.sem.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await firestoreService.deletePlano(_academiaId!, plano['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_l.plnDeleted),
            backgroundColor: context.sem.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _load();
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_l.plnDeleteError),
            backgroundColor: context.sem.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Widget _campo(
    TextEditingController ctrl,
    String hint,
    TextInputType keyboard, {
    List<TextInputFormatter>? formatters,
    String? prefix,
    int maxLines = 1,
  }) => TextField(
    controller: ctrl,
    keyboardType: keyboard,
    inputFormatters: formatters,
    maxLines: maxLines,
    style: TextStyle(color: context.c.onSurface),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: context.c.onSurfaceVariant, fontSize: 14),
      prefixText: prefix,
      prefixStyle: TextStyle(color: context.c.onSurfaceVariant),
      filled: true,
      fillColor: context.c.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.c.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.c.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.c.primary),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.surface,
      appBar: AppBar(
        backgroundColor: context.c.surfaceContainer,
        foregroundColor: context.c.onSurface,
        elevation: 0,
        title: Text(
          _l.plnTitle,
          style: TextStyle(
            color: context.c.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => _abrirFormulario(),
              icon: Icon(Icons.add_rounded, color: context.c.primary, size: 18),
              label: Text(
                _l.commonNew,
                style: TextStyle(
                  color: context.c.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: context.c.primary))
          : _erro != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: context.sem.danger,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _erro!,
                    style: TextStyle(color: context.c.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _load,
                    icon: Icon(Icons.refresh_rounded),
                    label: Text(_l.commonRetry),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.c.primary,
                    ),
                  ),
                ],
              ),
            )
          : _planos.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.credit_card_off_rounded,
                    color: context.c.onSurfaceVariant,
                    size: 52,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _l.plnEmpty,
                    style: TextStyle(
                      color: context.c.onSurfaceVariant,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _l.plnEmptyHint,
                    style: TextStyle(
                      color: context.c.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _abrirFormulario(),
                    icon: Icon(Icons.add_rounded),
                    label: Text(_l.plnCreateFirst),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.c.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            )
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
                      color: context.c.surfaceContainer,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.c.outline),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: context.c.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.credit_card_rounded,
                            color: context.c.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p['nome']?.toString() ?? '',
                                style: TextStyle(
                                  color: context.c.onSurface,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (valor != null)
                                Text(
                                  _l.plnPerMonth(
                                    valor
                                        .toStringAsFixed(2)
                                        .replaceAll('.', ','),
                                  ),
                                  style: TextStyle(
                                    color: context.c.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              if (desc != null && desc.isNotEmpty)
                                Text(
                                  desc,
                                  style: TextStyle(
                                    color: context.c.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.edit_rounded,
                            color: context.c.onSurfaceVariant,
                            size: 18,
                          ),
                          onPressed: () => _abrirFormulario(plano: p),
                          tooltip: _l.commonEdit,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: context.sem.danger,
                            size: 18,
                          ),
                          onPressed: () => _confirmarExclusao(p),
                          tooltip: _l.commonDelete,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
