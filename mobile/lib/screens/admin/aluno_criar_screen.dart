import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/firestore_service.dart';
import '../../core/paywall_modal.dart';

class _PhoneMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
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
    return next.copyWith(text: text, selection: TextSelection.collapsed(offset: text.length));
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
        (hoje.month == _dataNascimento!.month && hoje.day < _dataNascimento!.day)) {
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
            primary: kPrimary,
            onPrimary: Colors.white,
            surface: kSurface,
            onSurface: kText1,
          ),
          dialogBackgroundColor: kBg,
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dataNascimento = picked);
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _salvando = true; _erro = null; });
    try {
      final user = await AuthStorage.getUser();
      final academiaId = user!.academiaId!;
      final emailVal = _email.text.trim().toLowerCase();
      final telVal = _telefone.text.trim();
      final telDigits = telVal.replaceAll(RegExp(r'\D'), '');

      // Verificar duplicados por e-mail ou telefone
      final duplicado = await firestoreService.verificarDuplicadoAluno(
        academiaId,
        email: emailVal.isNotEmpty ? emailVal : null,
        telefoneDigits: telDigits.isNotEmpty ? telDigits : null,
      );

      if (duplicado != null && mounted) {
        setState(() => _salvando = false);
        final confirmar = await _confirmarDuplicado(duplicado);
        if (!confirmar) return;
        setState(() { _salvando = true; _erro = null; });
      }

      final nascIso = _dataNascimento != null
          ? '${_dataNascimento!.year.toString().padLeft(4, '0')}-'
            '${_dataNascimento!.month.toString().padLeft(2, '0')}-'
            '${_dataNascimento!.day.toString().padLeft(2, '0')}'
          : null;
      await firestoreService.addAluno(academiaId, {
        'nome': _nome.text.trim(),
        'email': emailVal.isEmpty ? null : emailVal,
        'telefone': telVal,
        if (telDigits.isNotEmpty) 'telefone_digits': telDigits,
        if (nascIso != null) 'dataNascimento': nascIso,
        if (_emergenciaNome.text.trim().isNotEmpty) 'contatoEmergenciaNome': _emergenciaNome.text.trim(),
        if (_emergenciaTel.text.trim().isNotEmpty) 'contatoEmergenciaTelefone': _emergenciaTel.text.trim(),
        if (_planoId != null) 'planoId': _planoId,
        if (_diaVenc.text.trim().isNotEmpty) 'diaVencimento': int.tryParse(_diaVenc.text.trim()),
        if (!_acessoAppAtivo) 'acesso_app_bloqueado': true,
      });
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
      setState(() => _erro = 'Erro ao cadastrar aluno. Verifique os dados.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<bool> _confirmarDuplicado(Map<String, dynamic> existente) async {
    final nomeExist = existente['nome'] as String? ?? 'aluno existente';
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Contato já cadastrado', style: TextStyle(color: kText1, fontWeight: FontWeight.w700, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('O e-mail ou telefone informado já pertence a:', style: TextStyle(color: kText2, fontSize: 13)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Icon(Icons.person_rounded, color: kPrimary, size: 20),
                const SizedBox(width: 8),
                Text(nomeExist, style: TextStyle(color: kText1, fontWeight: FontWeight.w700)),
              ]),
            ),
            const SizedBox(height: 12),
            Text(
              'Deseja cadastrar mesmo assim?\n'
              'Ao fazer o primeiro acesso com esse contato, o aluno poderá escolher entre os perfis (grupo familiar).',
              style: TextStyle(color: kText2, fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar', style: TextStyle(color: kText2)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Cadastrar mesmo assim', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _telefone.dispose();
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
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kSurface,
        foregroundColor: kText1,
        elevation: 0,
        title: Text('Novo Aluno', style: TextStyle(color: kText1, fontWeight: FontWeight.w700)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section('Dados pessoais'),
            _field(_nome, 'Nome completo *', required: true),
            _field(_email, 'E-mail', keyboard: TextInputType.emailAddress),
            _field(_telefone, 'Telefone', keyboard: TextInputType.phone, formatters: [_PhoneMaskFormatter()]),

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
                      color: kSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kBorder),
                    ),
                    child: Row(children: [
                      Icon(Icons.calendar_today_rounded, color: kText2, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          nascFormatted ?? 'Data de nascimento',
                          style: TextStyle(
                            color: nascFormatted != null ? kText1 : kText2,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (_menorDeIdade)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: kWarning.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('Menor de idade', style: TextStyle(color: kWarning, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                    ]),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            _sectionWithBadge(
              'Contato de emergência',
              _menorDeIdade ? '* obrigatório' : 'opcional',
              obrigatorio: _menorDeIdade,
            ),
            _field(
              _emergenciaNome,
              _menorDeIdade ? 'Nome do responsável *' : 'Nome do contato',
              required: _menorDeIdade,
            ),
            _field(
              _emergenciaTel,
              _menorDeIdade ? 'Telefone do responsável *' : 'Telefone do contato',
              keyboard: TextInputType.phone,
              formatters: [_PhoneMaskFormatter()],
              required: _menorDeIdade,
            ),
            const SizedBox(height: 16),
            _section('Plano financeiro'),
            if (_planos.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _planoId,
                    dropdownColor: kSurface,
                    hint: Text('Selecionar plano (opcional)', style: TextStyle(color: kText2, fontSize: 14)),
                    isExpanded: true,
                    items: [
                      DropdownMenuItem<String?>(value: null, child: Text('Sem plano', style: TextStyle(color: kText2))),
                      ..._planos.map((p) => DropdownMenuItem<String?>(
                            value: p['id'] as String?,
                            child: Text(p['nome'] ?? '', style: TextStyle(color: kText1)),
                          )),
                    ],
                    onChanged: (v) => setState(() => _planoId = v),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            _field(_diaVenc, 'Dia de vencimento (1-31)', keyboard: TextInputType.number),
            const SizedBox(height: 24),
            _section('Acesso ao App'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _acessoAppAtivo ? kBorder : kDanger.withOpacity(0.5)),
              ),
              child: Row(children: [
                Icon(
                  _acessoAppAtivo ? Icons.lock_open_rounded : Icons.lock_rounded,
                  color: _acessoAppAtivo ? kSuccess : kDanger,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    _acessoAppAtivo ? 'Acesso ao app liberado' : 'Acesso ao app bloqueado',
                    style: TextStyle(
                      color: _acessoAppAtivo ? kSuccess : kDanger,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _acessoAppAtivo
                        ? 'Aluno poderá fazer login normalmente'
                        : 'Aluno não conseguirá entrar no app',
                    style: TextStyle(color: kText2, fontSize: 11),
                  ),
                ])),
                Switch(
                  value: _acessoAppAtivo,
                  activeColor: kSuccess,
                  inactiveThumbColor: kDanger,
                  inactiveTrackColor: kDanger.withOpacity(0.3),
                  onChanged: (v) => setState(() => _acessoAppAtivo = v),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            if (_erro != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: kDanger.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Text(_erro!, style: TextStyle(color: kDanger, fontSize: 13)),
              ),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _salvando ? null : _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _salvando
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Cadastrar aluno', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(label, style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      );

  Widget _sectionWithBadge(String label, String badge, {bool obrigatorio = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Text(label, style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          const SizedBox(width: 8),
          Text(
            badge,
            style: TextStyle(
              color: obrigatorio ? kWarning : kText2,
              fontSize: 11,
              fontWeight: obrigatorio ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ]),
      );

  Widget _field(
    TextEditingController ctrl,
    String hint, {
    bool required = false,
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextFormField(
          controller: ctrl,
          keyboardType: keyboard,
          inputFormatters: formatters,
          style: TextStyle(color: kText1),
          validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: kText2, fontSize: 14),
            filled: true,
            fillColor: kSurface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPrimary)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kDanger)),
          ),
        ),
      );
}
