import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_storage.dart';
import '../../core/theme/context_ext.dart';
import '../../core/firebase_identity_service.dart';
import '../../core/firestore_service.dart';
import '../../core/paywall_modal.dart';
import '../../core/senha_temporaria_modal.dart';
import '../../core/widgets.dart';

class _PhoneMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue old,
    TextEditingValue next,
  ) {
    final digits = next.text.replaceAll(RegExp(r'\D'), '');
    final d = digits.length > 11 ? digits.substring(0, 11) : digits;
    final buf = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i == 0) buf.write('(');
      if (i == 2) buf.write(') ');
      if (d.length == 11 && i == 7) buf.write('-');
      if (d.length <= 10 && i == 6) buf.write('-');
      buf.write(d[i]);
    }
    final text = buf.toString();
    return next.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class AdminAlunoCriarScreen extends StatefulWidget {
  const AdminAlunoCriarScreen({super.key});

  @override
  State<AdminAlunoCriarScreen> createState() => _AdminAlunoCriarScreenState();
}

class _AdminAlunoCriarScreenState extends State<AdminAlunoCriarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _telefone = TextEditingController();
  final _cpf = TextEditingController();
  final _emergenciaNome = TextEditingController();
  final _emergenciaTel = TextEditingController();
  final _diaVenc = TextEditingController();

  DateTime? _dataNascimento;
  List<Map<String, dynamic>> _planos = [];
  String? _planoId;
  bool _acessoAppAtivo = true;
  bool _salvando = false;
  String? _erro;

  bool get _menorDeIdade {
    if (_dataNascimento == null) return false;
    final hoje = DateTime.now();
    var idade = hoje.year - _dataNascimento!.year;
    if (hoje.month < _dataNascimento!.month ||
        (hoje.month == _dataNascimento!.month &&
            hoje.day < _dataNascimento!.day)) {
      idade--;
    }
    return idade < 18;
  }

  @override
  void initState() {
    super.initState();
    _carregarPlanos();
  }

  Future<void> _carregarPlanos() async {
    try {
      final user = await AuthStorage.getUser();
      final academiaId = user!.academiaId!;
      final list = await firestoreService.getPlanos(academiaId);
      if (mounted) setState(() => _planos = list);
    } catch (_) {}
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataNascimento ?? DateTime(now.year - 10),
      firstDate: DateTime(1920),
      lastDate: now,
      locale: const Locale('pt', 'BR'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: context.c.primary,
            onPrimary: Colors.white,
            surface: context.c.surfaceContainer,
            onSurface: context.c.onSurface,
          ),
          dialogBackgroundColor: context.c.surface,
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dataNascimento = picked);
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

      // Verificar duplicado por e-mail (telefone pode repetir entre irmãos)
      final duplicado = await firestoreService.verificarDuplicadoAluno(
        academiaId,
        email: emailVal.isNotEmpty ? emailVal : null,
      );

      if (duplicado != null && mounted) {
        setState(() => _salvando = false);
        final confirmar = await _confirmarDuplicado(duplicado);
        if (!confirmar) return;
        setState(() {
          _salvando = true;
          _erro = null;
        });
      }

      // Se o telefone já pertence a um Professor/Secretaria/Admin, avisa que
      // isso vai vincular os dois perfis na mesma pessoa (ex: professor que
      // também treina como aluno em outra modalidade).
      if (telDigits.isNotEmpty) {
        final vinculos = await firestoreService.buscarPerfisMesmaAcademia(
          academiaId,
          telDigits,
        );
        final funcionarios = vinculos
            .where((v) => v['_colecao'] == 'funcionarios')
            .toList();
        final funcionario = funcionarios.isNotEmpty ? funcionarios.first : null;
        if (funcionario != null && mounted) {
          setState(() => _salvando = false);
          final confirmar = await _confirmarVinculo(funcionario);
          if (!confirmar) return;
          setState(() {
            _salvando = true;
            _erro = null;
          });
        }
      }

      // Checagem PRÉVIA: se telefone/e-mail já pertence a outra conta que já
      // definiu senha própria, decide ANTES de criar o aluno — cancelar aqui
      // não deixa nenhum cadastro pela metade (diferente de decidir depois
      // que o aluno já existe no banco).
      var confirmarSobrescrita = false;
      var apenasVincular = false;
      if (_acessoAppAtivo && (emailVal.isNotEmpty || telDigits.isNotEmpty)) {
        final checagem = await firebaseIdentityService
            .checkContatoCompartilhado(
              academiaId: academiaId,
              telefone: telDigits,
              email: emailVal,
            );
        if (checagem.conflito) {
          if (!mounted) return;
          setState(() => _salvando = false);
          final escolha = await perguntarComoResolverConflitoSenha(
            context,
            nome: _nome.text.trim(),
          );
          if (escolha == null)
            return; // cancelou: formulário intacto, nada criado.
          setState(() {
            _salvando = true;
            _erro = null;
          });
          confirmarSobrescrita = escolha == ResolucaoConflitoSenha.gerarNova;
          apenasVincular = escolha == ResolucaoConflitoSenha.manterAtual;
        }
      }

      final nascIso = _dataNascimento != null
          ? '${_dataNascimento!.year.toString().padLeft(4, '0')}-'
                '${_dataNascimento!.month.toString().padLeft(2, '0')}-'
                '${_dataNascimento!.day.toString().padLeft(2, '0')}'
          : null;
      final alunoId = await firestoreService.addAluno(academiaId, {
        'nome': _nome.text.trim(),
        'email': emailVal.isEmpty ? null : emailVal,
        'telefone': telVal,
        if (telDigits.isNotEmpty) 'telefone_digits': telDigits,
        if (nascIso != null) 'data_nascimento': nascIso,
        if (_cpf.text.trim().isNotEmpty)
          'cpf': _cpf.text.trim().replaceAll(RegExp(r'\D'), ''),
        if (_emergenciaNome.text.trim().isNotEmpty)
          'contato_emergencia_nome': _emergenciaNome.text.trim(),
        if (_emergenciaTel.text.trim().isNotEmpty)
          'contato_emergencia_telefone': _emergenciaTel.text.trim(),
        if (_planoId != null) 'plano_id': _planoId,
        if (_diaVenc.text.trim().isNotEmpty)
          'dia_vencimento': int.tryParse(_diaVenc.text.trim()),
        if (!_acessoAppAtivo) 'acesso_app_bloqueado': true,
      });

      // Com acesso liberado e havendo telefone ou e-mail, já gera a senha
      // temporária para a academia repassar — o aluno não precisa passar pelo
      // "primeiro acesso". Uma falha aqui não desfaz o cadastro: a academia
      // usa context.l10n.sdGenerateAccess na ficha do aluno depois.
      if (mounted &&
          _acessoAppAtivo &&
          (emailVal.isNotEmpty || telDigits.isNotEmpty)) {
        await provisionarAcessoApp(
          context,
          academiaId: academiaId,
          colecao: 'usuarios',
          usuarioId: alunoId,
          nome: _nome.text.trim(),
          motivo: 'provisao_criacao',
          confirmarSobrescrita: confirmarSobrescrita,
          apenasVincular: apenasVincular,
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      try {
        final data = (e as dynamic).response?.data;
        if (data is Map && data['codigo'] == 'LIMITE_PLANO_GRATUITO') {
          setState(() => _salvando = false);
          mostrarPaywall(context);
          return;
        }
      } catch (_) {}
      setState(() => _erro = context.l10n.acCreateError);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<bool> _confirmarDuplicado(Map<String, dynamic> existente) async {
    final nomeExist = existente['nome'] as String? ?? 'aluno existente';
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: context.c.surfaceContainer,
            title: Text(
              'E-mail já cadastrado',
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
                  'O e-mail informado já pertence a:',
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
                        Icons.person_rounded,
                        color: context.c.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        nomeExist,
                        style: TextStyle(
                          color: context.c.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.acCreateAnywayBody,
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
                  context.l10n.acCreateAnyway,
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

  Future<bool> _confirmarVinculo(Map<String, dynamic> funcionario) async {
    final nome = funcionario['nome'] as String? ?? 'um membro da equipe';
    final perfilNome = funcionario['perfil_nome'] as String? ?? 'Professor';
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
                        Icons.badge_rounded,
                        color: context.c.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$nome ($perfilNome)',
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
                  context.l10n.acLinkStudentQuestion,
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
    _cpf.dispose();
    _emergenciaNome.dispose();
    _emergenciaTel.dispose();
    _diaVenc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nascFormatted = _dataNascimento == null
        ? null
        : '${_dataNascimento!.day.toString().padLeft(2, '0')}/'
              '${_dataNascimento!.month.toString().padLeft(2, '0')}/'
              '${_dataNascimento!.year}';

    return Scaffold(
      backgroundColor: context.c.surface,
      appBar: AppBar(
        backgroundColor: context.c.surfaceContainer,
        foregroundColor: context.c.onSurface,
        elevation: 0,
        title: Text(
          context.l10n.acNewStudent,
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
            _section(context.l10n.sdPersonalData),
            _field(_nome, context.l10n.acFullNameReq, required: true),
            _field(_email, 'E-mail', keyboard: TextInputType.emailAddress),
            _field(
              _telefone,
              context.l10n.sdPhone,
              keyboard: TextInputType.phone,
              formatters: [_PhoneMaskFormatter()],
            ),
            _field(
              _cpf,
              'CPF (opcional)',
              keyboard: TextInputType.number,
              formatters: [CpfInputFormatter()],
            ),

            // Date picker field
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FormField<DateTime>(
                initialValue: _dataNascimento,
                validator: (_) => null,
                builder: (state) => GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: context.c.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.c.outline),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          color: context.c.onSurfaceVariant,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            nascFormatted ?? context.l10n.acBirthDate,
                            style: TextStyle(
                              color: nascFormatted != null
                                  ? context.c.onSurface
                                  : context.c.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (_menorDeIdade)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: context.sem.warning.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              context.l10n.acMinor,
                              style: TextStyle(
                                color: context.sem.warning,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            _sectionWithBadge(context.l10n.sdGuardianEmergency, 'opcional'),
            _field(
              _emergenciaNome,
              _menorDeIdade
                  ? context.l10n.acGuardianName
                  : context.l10n.sdContactName,
            ),
            _field(
              _emergenciaTel,
              _menorDeIdade
                  ? context.l10n.acGuardianPhone
                  : context.l10n.sdContactPhone,
              keyboard: TextInputType.phone,
              formatters: [_PhoneMaskFormatter()],
            ),
            const SizedBox(height: 16),
            _section(context.l10n.sdBillingPlan),
            if (_planos.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: context.c.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.c.outline),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _planoId,
                    dropdownColor: context.c.surfaceContainer,
                    hint: Text(
                      context.l10n.acSelectPlanOptional,
                      style: TextStyle(
                        color: context.c.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                    isExpanded: true,
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          context.l10n.sdNoPlanOption,
                          style: TextStyle(color: context.c.onSurfaceVariant),
                        ),
                      ),
                      ..._planos.map(
                        (p) => DropdownMenuItem<String?>(
                          value: p['id'] as String?,
                          child: Text(
                            p['nome'] ?? '',
                            style: TextStyle(color: context.c.onSurface),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _planoId = v),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            _field(
              _diaVenc,
              context.l10n.sdDueDayField,
              keyboard: TextInputType.number,
            ),
            const SizedBox(height: 24),
            _section(context.l10n.sdAppAccessSection),
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: context.c.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.c.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.vpn_key_rounded,
                    color: context.c.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.l10n.acAppAccessNote,
                      style: TextStyle(
                        color: context.c.onSurfaceVariant,
                        fontSize: 11.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: context.c.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _acessoAppAtivo
                      ? context.c.outline
                      : context.sem.danger.withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _acessoAppAtivo
                        ? Icons.lock_open_rounded
                        : Icons.lock_rounded,
                    color: _acessoAppAtivo
                        ? context.sem.success
                        : context.sem.danger,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _acessoAppAtivo
                              ? context.l10n.acAccessAllowed
                              : context.l10n.acAccessBlocked,
                          style: TextStyle(
                            color: _acessoAppAtivo
                                ? context.sem.success
                                : context.sem.danger,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          _acessoAppAtivo
                              ? context.l10n.acCanLogin
                              : context.l10n.acCannotLogin,
                          style: TextStyle(
                            color: context.c.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _acessoAppAtivo,
                    activeColor: context.sem.success,
                    inactiveThumbColor: context.sem.danger,
                    inactiveTrackColor: context.sem.danger.withOpacity(0.3),
                    onChanged: (v) => setState(() => _acessoAppAtivo = v),
                  ),
                ],
              ),
            ),
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
                        context.l10n.acCreateStudent,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
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

  Widget _sectionWithBadge(
    String label,
    String badge, {
    bool obrigatorio = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.c.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          badge,
          style: TextStyle(
            color: obrigatorio
                ? context.sem.warning
                : context.c.onSurfaceVariant,
            fontSize: 11,
            fontWeight: obrigatorio ? FontWeight.w600 : FontWeight.normal,
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
    List<TextInputFormatter>? formatters,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      inputFormatters: formatters,
      style: TextStyle(color: context.c.onSurface),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty)
                ? context.l10n.acRequiredField
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
