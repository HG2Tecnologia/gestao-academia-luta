import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/payment_request_service.dart';
import '../../core/constants.dart';

class CartaoPagamentoSheet extends StatefulWidget {
  final String academiaId;
  final String pagamentoId;
  final double valor;
  final String descricao;
  final String alunoNome;
  final String? alunoCpf;
  final String? alunoEmail;

  const CartaoPagamentoSheet({
    super.key,
    required this.academiaId,
    required this.pagamentoId,
    required this.valor,
    required this.descricao,
    required this.alunoNome,
    this.alunoCpf,
    this.alunoEmail,
  });

  static Future<bool> show(
    BuildContext context, {
    required String academiaId,
    required String pagamentoId,
    required double valor,
    required String descricao,
    required String alunoNome,
    String? alunoCpf,
    String? alunoEmail,
  }) async {
    final pago = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CartaoPagamentoSheet(
        academiaId: academiaId,
        pagamentoId: pagamentoId,
        valor: valor,
        descricao: descricao,
        alunoNome: alunoNome,
        alunoCpf: alunoCpf,
        alunoEmail: alunoEmail,
      ),
    );
    return pago == true;
  }

  @override
  State<CartaoPagamentoSheet> createState() => _CartaoPagamentoSheetState();
}

class _CartaoPagamentoSheetState extends State<CartaoPagamentoSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nomeCtrl = TextEditingController(text: widget.alunoNome);
  final _numeroCtrl = TextEditingController();
  final _validadeCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  late final _cpfCtrl = TextEditingController(text: widget.alunoCpf ?? '');
  final _cepCtrl = TextEditingController();
  final _endNumCtrl = TextEditingController();
  final _telCtrl = TextEditingController();

  bool _loading = false;
  String? _erroMsg;
  bool _pago = false;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _numeroCtrl.dispose();
    _validadeCtrl.dispose();
    _cvvCtrl.dispose();
    _cpfCtrl.dispose();
    _cepCtrl.dispose();
    _endNumCtrl.dispose();
    _telCtrl.dispose();
    super.dispose();
  }

  String get _valorFormatado =>
      'R\$ ${widget.valor.toStringAsFixed(2).replaceAll('.', ',')}';

  Future<void> _pagar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _erroMsg = null; });

    final numero = _numeroCtrl.text.replaceAll(' ', '');
    final validade = _validadeCtrl.text;
    final mes = validade.substring(0, 2);
    final ano = validade.length >= 5 ? '20${validade.substring(3)}' : '';
    final cpf = _cpfCtrl.text.replaceAll(RegExp(r'\D'), '');
    final cep = _cepCtrl.text.replaceAll(RegExp(r'\D'), '');
    final tel = _telCtrl.text.replaceAll(RegExp(r'\D'), '');

    try {
      await PaymentRequestService.criarCobranca(
        academiaId: widget.academiaId,
        pagamentoId: widget.pagamentoId,
        valor: widget.valor,
        descricao: widget.descricao,
        alunoNome: widget.alunoNome,
        alunoCpf: widget.alunoCpf,
        alunoEmail: widget.alunoEmail,
        billingType: 'CREDIT_CARD',
        creditCard: {
          'holderName': _nomeCtrl.text.trim().toUpperCase(),
          'number': numero,
          'expiryMonth': mes,
          'expiryYear': ano,
          'ccv': _cvvCtrl.text.trim(),
        },
        creditCardHolderInfo: {
          'name': _nomeCtrl.text.trim(),
          'email': widget.alunoEmail ?? '',
          'cpfCnpj': cpf,
          'postalCode': cep,
          'addressNumber': _endNumCtrl.text.trim(),
          'phone': tel,
        },
      );

      if (mounted) setState(() { _pago = true; _loading = false; });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.of(context).pop(true);
    } on PaymentRequestError catch (e) {
      if (mounted) setState(() { _erroMsg = e.message; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _erroMsg = 'Erro de conexão. Verifique sua internet.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              if (_pago)
                _buildPago()
              else ...[
                Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: const Color(0xFF7B1FA2).withOpacity(0.12), shape: BoxShape.circle),
                    child: const Icon(Icons.credit_card_rounded, color: Color(0xFF7B1FA2), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Cartão de Crédito', style: TextStyle(color: kText1, fontSize: 17, fontWeight: FontWeight.w800)),
                      Text(widget.descricao, style: TextStyle(color: kText2, fontSize: 12)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 14),
                Text(_valorFormatado, style: TextStyle(color: kText1, fontSize: 28, fontWeight: FontWeight.w900)),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('DADOS DO CARTÃO'),
                      const SizedBox(height: 10),
                      _campo(_numeroCtrl, 'Número do cartão', hint: '0000 0000 0000 0000',
                        keyboardType: TextInputType.number,
                        inputFormatters: [_CardNumberFormatter()],
                        validator: (v) => (v ?? '').replaceAll(' ', '').length < 16 ? 'Número inválido' : null,
                      ),
                      const SizedBox(height: 12),
                      _campo(_nomeCtrl, 'Nome impresso no cartão', hint: 'NOME SOBRENOME',
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) => (v ?? '').trim().isEmpty ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _campo(_validadeCtrl, 'Validade', hint: 'MM/AA',
                          keyboardType: TextInputType.number,
                          inputFormatters: [_ExpiryFormatter()],
                          validator: (v) {
                            if ((v ?? '').length < 5) return 'Inválida';
                            final mes = int.tryParse(v!.substring(0, 2)) ?? 0;
                            if (mes < 1 || mes > 12) return 'Mês inválido';
                            return null;
                          },
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _campo(_cvvCtrl, 'CVV', hint: '123',
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                          validator: (v) => (v ?? '').length < 3 ? 'CVV inválido' : null,
                        )),
                      ]),
                      const SizedBox(height: 20),
                      _label('DADOS DO TITULAR'),
                      const SizedBox(height: 10),
                      _campo(_cpfCtrl, 'CPF do titular', hint: '000.000.000-00',
                        keyboardType: TextInputType.number,
                        inputFormatters: [_CpfFormatter()],
                        validator: (v) => (v ?? '').replaceAll(RegExp(r'\D'), '').length < 11 ? 'CPF inválido' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(flex: 2, child: _campo(_cepCtrl, 'CEP', hint: '00000-000',
                          keyboardType: TextInputType.number,
                          inputFormatters: [_CepFormatter()],
                          validator: (v) => (v ?? '').replaceAll(RegExp(r'\D'), '').length < 8 ? 'CEP inválido' : null,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _campo(_endNumCtrl, 'Número', hint: '42',
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (v) => (v ?? '').trim().isEmpty ? 'Obrigatório' : null,
                        )),
                      ]),
                      const SizedBox(height: 12),
                      _campo(_telCtrl, 'Telefone', hint: '(11) 99999-9999',
                        keyboardType: TextInputType.phone,
                        inputFormatters: [_TelFormatter()],
                        validator: (v) => (v ?? '').replaceAll(RegExp(r'\D'), '').length < 10 ? 'Telefone inválido' : null,
                      ),
                      if (_erroMsg != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: kDanger.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: kDanger.withOpacity(0.3)),
                          ),
                          child: Text(_erroMsg!, style: TextStyle(color: kDanger, fontSize: 13, height: 1.4)),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _pagar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7B1FA2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            disabledBackgroundColor: const Color(0xFF7B1FA2).withOpacity(0.5),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  'Pagar $_valorFormatado',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.lock_outline_rounded, size: 12, color: kText2),
                        const SizedBox(width: 4),
                        Text('Pagamento seguro via Asaas', style: TextStyle(color: kText2, fontSize: 11)),
                      ]),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPago() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: kSuccess.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(Icons.check_circle_rounded, color: kSuccess, size: 40),
          ),
          const SizedBox(height: 16),
          Text('Pagamento Aprovado!', style: TextStyle(color: kText1, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(_valorFormatado, style: TextStyle(color: kSuccess, fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('Seu pagamento foi processado com sucesso.', style: TextStyle(color: kText2, fontSize: 13)),
        ]),
      );

  Widget _label(String text) => Text(
        text,
        style: TextStyle(color: kText2, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0),
      );

  Widget _campo(
    TextEditingController ctrl,
    String label, {
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.words,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      textCapitalization: textCapitalization,
      style: TextStyle(color: kText1, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: kText2, fontSize: 13),
        hintStyle: TextStyle(color: kText2.withOpacity(0.5), fontSize: 14),
        filled: true,
        fillColor: kBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kPrimary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kDanger)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kDanger, width: 2)),
      ),
    );
  }
}

// ── Input Formatters ──────────────────────────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < text.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < text.length && i < 4; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(text[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}

class _CpfFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < text.length && i < 11; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(text[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}

class _CepFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < text.length && i < 8; i++) {
      if (i == 5) buffer.write('-');
      buffer.write(text[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}

class _TelFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < text.length && i < 11; i++) {
      if (i == 0) buffer.write('(');
      if (i == 2) buffer.write(') ');
      if (text.length == 11 && i == 7) buffer.write('-');
      if (text.length <= 10 && i == 6) buffer.write('-');
      buffer.write(text[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}
