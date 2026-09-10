import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_storage.dart';
import '../../core/theme/context_ext.dart';
import '../../core/firestore_service.dart';
import '../../core/permissoes.dart';
import '../../core/senha_temporaria_modal.dart';

class _PhoneMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue old,
    TextEditingValue current,
  ) {
    final digits = current.text.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length && i < 11; i++) {
      if (i == 0) buf.write('(');
      if (i == 2) buf.write(') ');
      if (digits.length == 11) {
        if (i == 7) buf.write('-');
      } else {
        if (i == 6) buf.write('-');
      }
      buf.write(digits[i]);
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class AdminEquipeCriarScreen extends StatefulWidget {
  const AdminEquipeCriarScreen({super.key});

  @override
  State<AdminEquipeCriarScreen> createState() => _AdminEquipeCriarScreenState();
}

class _AdminEquipeCriarScreenState extends State<AdminEquipeCriarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _telefone = TextEditingController();
  final _cargo = TextEditingController();
  String _perfil = 'Professor';
  bool _salvando = false;
  String? _erro;

  // Permissões configuráveis (admin = sem restrição, sem UI de permissão)
  Map<String, bool> _permissoes = permissoesParaPerfil('Professor');

  static const _perfis = ['Professor', 'Secretaria', 'Admin'];

  void _onPerfilChanged(String novoPerfil) {
    setState(() {
      _perfil = novoPerfil;
      // Reseta para defaults do perfil selecionado
      _permissoes = permissoesParaPerfil(novoPerfil);
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      final user = await AuthStorage.getUser();
      final academiaId = user!.academiaId!;
      final emailVal = _email.text.trim().toLowerCase();
      final telVal = _telefone.text.trim();
      final telDigits = telVal.replaceAll(RegExp(r'\D'), '');

      // Se o telefone já pertence a um Aluno, avisa que isso vai vincular os
      // dois perfis na mesma pessoa (ex: aluno que também dá aula).
      if (telDigits.isNotEmpty) {
        final vinculos = await firestoreService.buscarPerfisMesmaAcademia(
          academiaId,
          telDigits,
        );
        final alunos = vinculos
            .where((v) => v['_colecao'] == 'usuarios')
            .toList();
        final aluno = alunos.isNotEmpty ? alunos.first : null;
        if (aluno != null && mounted) {
          setState(() => _salvando = false);
          final confirmar = await _confirmarVinculo(aluno);
          if (!confirmar) return;
          setState(() {
            _salvando = true;
            _erro = null;
          });
        }
      }

      final funcId = await firestoreService.addFuncionario(academiaId, {
        'nome': _nome.text.trim(),
        'email': emailVal.isEmpty ? null : emailVal,
        'telefone': telVal,
        if (telDigits.isNotEmpty) 'telefone_digits': telDigits,
        'cargo': _cargo.text.trim().isEmpty ? _perfil : _cargo.text.trim(),
        'perfil': _perfil,
        // Admin tem tudo, não precisa salvar mapa
        'permissoes': _perfil == 'Admin' ? <String, bool>{} : _permissoes,
      });

      // Tendo telefone ou e-mail, já gera a senha temporária para a academia
      // repassar — o funcionário não precisa passar pelo "primeiro acesso".
      // Falha aqui não desfaz o cadastro.
      if (mounted && (emailVal.isNotEmpty || telDigits.isNotEmpty)) {
        await provisionarAcessoApp(
          context,
          academiaId: academiaId,
          colecao: 'funcionarios',
          usuarioId: funcId,
          nome: _nome.text.trim(),
          motivo: 'provisao_criacao',
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) setState(() => _erro = context.l10n.stfCreateError);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<bool> _confirmarVinculo(Map<String, dynamic> aluno) async {
    final nome = aluno['nome'] as String? ?? 'um aluno';
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: context.c.surfaceContainer,
            title: Text(
              context.l10n.stfLinkProfiles,
              style: TextStyle(
                color: context.c.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.stfPhoneBelongsTo,
                  style: TextStyle(
                    color: context.c.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.c.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.sports_martial_arts,
                        color: context.c.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$nome (Aluno)',
                          style: TextStyle(
                            color: context.c.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.stfLinkStaffQuestion,
                  style: TextStyle(
                    color: context.c.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  context.l10n.commonCancel,
                  style: TextStyle(color: context.c.onSurfaceVariant),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                  context.l10n.stfLinkAlso,
                  style: TextStyle(
                    color: context.c.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _telefone.dispose();
    _cargo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.surface,
      appBar: AppBar(
        backgroundColor: context.c.surfaceContainer,
        foregroundColor: context.c.onSurface,
        elevation: 0,
        title: Text(
          context.l10n.stfNewStaff,
          style: TextStyle(
            color: context.c.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section(context.l10n.stfPersonalData),
            _field(_nome, context.l10n.stfFullNameReq, required: true),
            _field(_email, 'E-mail', keyboard: TextInputType.emailAddress),
            _field(
              _telefone,
              context.l10n.stfPhoneReq,
              keyboard: TextInputType.phone,
              required: true,
              phoneMask: true,
            ),
            _infoBox(context.l10n.stfTempPasswordNote),
            const SizedBox(height: 16),
            _section(context.l10n.stfRoleAndProfile),
            _field(_cargo, context.l10n.stfRoleExample),
            const SizedBox(height: 10),
            // Perfil selector via dialog (evita DropdownButton dentro de scroll)
            GestureDetector(
              onTap: () async {
                final sel = await showDialog<String>(
                  context: context,
                  builder: (dCtx) => SimpleDialog(
                    backgroundColor: context.c.surfaceContainer,
                    title: Text(
                      context.l10n.stfProfile,
                      style: TextStyle(
                        color: context.c.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    children: _perfis
                        .map(
                          (p) => SimpleDialogOption(
                            onPressed: () => Navigator.of(dCtx).pop(p),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                p,
                                style: TextStyle(
                                  color: context.c.onSurface,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                );
                if (sel != null) _onPerfilChanged(sel);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: context.c.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.c.outline),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _perfil,
                        style: TextStyle(
                          color: context.c.onSurface,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.expand_more_rounded,
                      color: context.c.onSurfaceVariant,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            // Permissões (só para professor e secretaria)
            if (_perfil != 'Admin') ...[
              const SizedBox(height: 24),
              _section(context.l10n.stfPermissions),
              _infoBox(context.l10n.stfPermissionsHint),
              const SizedBox(height: 12),
              _permissoesWidget(),
            ],
            const SizedBox(height: 24),
            if (_erro != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: context.sem.danger.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _erro!,
                  style: TextStyle(color: context.sem.danger, fontSize: 13),
                ),
              ),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _salvando ? null : _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.c.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _salvando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        context.l10n.stfCreateStaff,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _permissoesWidget() {
    // Agrupa telas e ações
    final telasKeys = kPermissoesInfo.keys
        .where((k) => k.startsWith('tela_'))
        .toList();
    final acoesKeys = kPermissoesInfo.keys
        .where((k) => k.startsWith('acao_'))
        .toList();
    final acessoKeys = kPermissoesInfo.keys
        .where((k) => k.startsWith('acesso_'))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _permissaoGrupo(context.l10n.stfVisibleScreens, telasKeys),
        const SizedBox(height: 12),
        _permissaoGrupo(context.l10n.stfAllowedActions, acoesKeys),
        const SizedBox(height: 12),
        _permissaoGrupo(context.l10n.stfAdvancedAccess, acessoKeys),
      ],
    );
  }

  Widget _permissaoGrupo(String titulo, List<String> chaves) {
    return Container(
      decoration: BoxDecoration(
        color: context.c.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.c.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              titulo,
              style: TextStyle(
                color: context.c.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          for (int i = 0; i < chaves.length; i++) ...[
            if (i > 0) Divider(height: 1, color: context.c.outline, indent: 16),
            _permissaoTile(chaves[i]),
          ],
        ],
      ),
    );
  }

  Widget _permissaoTile(String chave) {
    final info = kPermissoesInfo[chave]!;
    final label = info.$1;
    final desc = info.$2;
    final valor = _permissoes[chave] ?? false;

    return SwitchListTile(
      value: valor,
      onChanged: (v) => setState(() => _permissoes[chave] = v),
      activeColor: context.c.primary,
      title: Text(
        label,
        style: TextStyle(
          color: context.c.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        desc,
        style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      dense: true,
    );
  }

  Widget _section(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      label,
      style: TextStyle(
        color: context.c.onSurfaceVariant,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    ),
  );

  Widget _infoBox(String msg) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: context.c.primary.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: context.c.primary.withOpacity(0.2)),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline_rounded, color: context.c.primary, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            msg,
            style: TextStyle(color: context.c.primary, fontSize: 12),
          ),
        ),
      ],
    ),
  );

  Widget _field(
    TextEditingController ctrl,
    String hint, {
    bool required = false,
    TextInputType? keyboard,
    bool phoneMask = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      inputFormatters: phoneMask ? [_PhoneMaskFormatter()] : null,
      style: TextStyle(color: context.c.onSurface),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty)
                ? context.l10n.stfRequiredField
                : null
          : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: context.c.onSurfaceVariant, fontSize: 14),
        filled: true,
        fillColor: context.c.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.sem.danger),
        ),
      ),
    ),
  );
}
