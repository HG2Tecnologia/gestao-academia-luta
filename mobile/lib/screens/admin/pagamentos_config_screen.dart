import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/auth_storage.dart';
import '../../core/payment_request_service.dart';
import '../../core/constants.dart';
import '../../core/firestore_service.dart';

class PagamentosConfigScreen extends StatefulWidget {
  const PagamentosConfigScreen({super.key});

  @override
  State<PagamentosConfigScreen> createState() => _PagamentosConfigScreenState();
}

class _PagamentosConfigScreenState extends State<PagamentosConfigScreen> {
  bool _loading = true;
  bool _processando = false;
  String? _academiaId;
  final _faturamentoCtrl = TextEditingController();
  final _codigoSmsCtrl = TextEditingController();
  final _agenciaCtrl = TextEditingController();
  final _contaCtrl = TextEditingController();
  final _digitoCtrl = TextEditingController();
  String _tipoConta = 'CONTA_CORRENTE';
  String? _bancoSelecionado;

  static const _bancos = [
    ('001', 'Banco do Brasil'),
    ('033', 'Santander'),
    ('077', 'Banco Inter'),
    ('104', 'Caixa Econômica Federal'),
    ('237', 'Bradesco'),
    ('260', 'Nubank'),
    ('336', 'C6 Bank'),
    ('341', 'Itaú'),
    ('290', 'PagBank'),
    ('748', 'Sicredi'),
    ('756', 'Sicoob'),
  ];

  // null = não configurado, 'PENDENTE' = aguardando KYC, 'ATIVO' = funcionando
  String? _status;
  String? _nomeAcademia;
  String? _cnpjAcademia;
  String? _cpfAcademia;
  String? _emailAcademia;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _faturamentoCtrl.dispose();
    _codigoSmsCtrl.dispose();
    _agenciaCtrl.dispose();
    _contaCtrl.dispose();
    _digitoCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; });
    try {
      final user = await AuthStorage.getUser();
      _academiaId = user?.academiaId;
      if (_academiaId == null) { setState(() => _loading = false); return; }

      final results = await Future.wait([
        firestoreService.getAsaasConfig(_academiaId!),
        firestoreService.getAcademia(_academiaId!),
      ]);

      final asaas = results[0] as Map<String, dynamic>?;
      final acad = results[1] as Map<String, dynamic>? ?? {};
      _nomeAcademia = acad['nome'] as String?;
      _cnpjAcademia = acad['cnpj'] as String?;
      _cpfAcademia = acad['cpf'] as String?;
      _emailAcademia = acad['email'] as String?;
      _status = asaas?['status'] as String?;
      final fat = (acad['faturamento_mensal'] as num?)?.toDouble() ?? 0.0;
      if (fat > 0) {
        final cents = (fat * 100).round();
        final intPart = cents ~/ 100;
        final decPart = cents % 100;
        final intStr = intPart.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
        _faturamentoCtrl.text = '$intStr,${decPart.toString().padLeft(2, '0')}';
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _confirmarCodigo() async {
    final codigo = _codigoSmsCtrl.text.trim();
    if (codigo.length < 4) {
      _mostrarSnack('Digite o código recebido por SMS.');
      return;
    }
    setState(() => _processando = true);
    try {
      final data = await PaymentRequestService.adminRequest(
        academiaId: _academiaId!,
        tipo: 'confirmarCodigoSms',
        extra: {'codigo': codigo},
      );
      if (mounted) {
        _codigoSmsCtrl.clear();
        setState(() => _status = data['status'] as String? ?? 'AGUARDANDO_CONTA_BANCARIA');
        _mostrarSnack('Telefone verificado! Agora configure sua conta bancária.', sucesso: true);
      }
    } on PaymentRequestError catch (e) {
      if (mounted) _mostrarSnack(e.message);
    } catch (_) {
      if (mounted) _mostrarSnack('Erro de conexão. Verifique sua internet.');
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  Future<void> _reenviarCodigo() async {
    setState(() => _processando = true);
    try {
      await PaymentRequestService.adminRequest(academiaId: _academiaId!, tipo: 'reenviarCodigoSms');
      if (mounted) _mostrarSnack('Código reenviado por SMS!', sucesso: true);
    } on PaymentRequestError catch (e) {
      if (mounted) _mostrarSnack(e.message);
    } catch (_) {
      if (mounted) _mostrarSnack('Erro ao reenviar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  Future<void> _configurarContaBancaria() async {
    if (_academiaId == null) return;
    if (_bancoSelecionado == null) { _mostrarSnack('Selecione o banco.'); return; }
    if (_agenciaCtrl.text.trim().isEmpty) { _mostrarSnack('Informe a agência.'); return; }
    if (_contaCtrl.text.trim().isEmpty) { _mostrarSnack('Informe o número da conta.'); return; }

    final docFiscal = _docFiscal;
    final nomeTitular = _nomeAcademia ?? '';

    setState(() => _processando = true);
    try {
      final data = await PaymentRequestService.adminRequest(
        academiaId: _academiaId!,
        tipo: 'configurarContaBancaria',
        extra: {
          'codigoBanco': _bancoSelecionado,
          'agencia': _agenciaCtrl.text.trim(),
          'conta': _contaCtrl.text.trim(),
          'digitoConta': _digitoCtrl.text.trim().isEmpty ? '0' : _digitoCtrl.text.trim(),
          'tipoConta': _tipoConta,
          'nomeTitular': nomeTitular,
          'cpfCnpjTitular': docFiscal,
        },
      );
      if (mounted) {
        setState(() => _status = data['status'] as String? ?? 'PENDENTE');
        _mostrarSnack('Conta bancária configurada! Aguardando aprovação do Asaas.', sucesso: true);
      }
    } on PaymentRequestError catch (e) {
      if (mounted) _mostrarSnack(e.message);
    } catch (_) {
      if (mounted) _mostrarSnack('Erro de conexão. Verifique sua internet.');
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  Future<void> _deletarSubconta() async {
    if (_academiaId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Desvincular conta Asaas?', style: TextStyle(color: kText1, fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          'Isso vai excluir a subconta criada no Asaas e desvincular do app. '
          'Para reativar pagamentos você precisará criar uma nova conta no Asaas.',
          style: TextStyle(color: kText2, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar', style: TextStyle(color: kText2))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Desvincular', style: TextStyle(color: kDanger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _processando = true);
    try {
      await PaymentRequestService.adminRequest(academiaId: _academiaId!, tipo: 'deletarSubconta');
      if (mounted) {
        setState(() => _status = null);
        _mostrarSnack('Conta desvinculada com sucesso.', sucesso: true);
      }
    } on PaymentRequestError catch (e) {
      if (mounted) _mostrarSnack(e.message);
    } catch (_) {
      if (mounted) _mostrarSnack('Erro de conexão. Verifique sua internet.');
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  Future<void> _verificarStatus() async {
    if (_academiaId == null) return;
    setState(() => _processando = true);
    try {
      final data = await PaymentRequestService.adminRequest(academiaId: _academiaId!, tipo: 'verificarStatus');
      if (mounted) {
        final novoStatus = data['status'] as String? ?? _status;
        setState(() => _status = novoStatus);
        if (_status == 'ATIVO') {
          _mostrarSnack('Conta aprovada! Pagamentos via PIX já estão ativos.', sucesso: true);
        } else {
          _mostrarSnack('Ainda aguardando aprovação. Tente novamente em alguns minutos.');
        }
      }
    } on PaymentRequestError catch (e) {
      if (mounted) _mostrarSnack(e.message);
    } catch (_) {
      if (mounted) _mostrarSnack('Erro de conexão. Verifique sua internet.');
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  // Retorna o documento fiscal disponível (CPF ou CNPJ), já sem formatação
  String get _docFiscal {
    final cnpj = (_cnpjAcademia ?? '').replaceAll(RegExp(r'\D'), '');
    if (cnpj.length >= 11) return cnpj;
    return (_cpfAcademia ?? '').replaceAll(RegExp(r'\D'), '');
  }

  bool get _temDocFiscal => _docFiscal.length >= 11;

  String get _labelDocFiscal {
    final doc = (_cnpjAcademia ?? '').replaceAll(RegExp(r'\D'), '');
    if (doc.length == 14) return 'CNPJ';
    if (doc.length == 11) return 'CPF';
    final cpf = (_cpfAcademia ?? '').replaceAll(RegExp(r'\D'), '');
    return cpf.length == 11 ? 'CPF' : 'CPF/CNPJ';
  }

  String get _valorDocFiscal {
    final cnpj = _cnpjAcademia ?? '';
    if (cnpj.replaceAll(RegExp(r'\D'), '').length >= 11) return cnpj;
    return _cpfAcademia ?? '—';
  }

  Future<void> _ativarPagamentos() async {
    if (_academiaId == null) return;
    if (!_temDocFiscal) {
      _mostrarSnack('Preencha o CPF ou CNPJ da academia em Configurações antes de ativar pagamentos.');
      return;
    }

    final isPessoaFisica = _docFiscal.length == 11;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Ativar Pagamentos via App', style: TextStyle(color: kText1, fontSize: 16, fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Card explicativo do Asaas
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFD54F)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFFF9A825), size: 16),
                      const SizedBox(width: 6),
                      Text('O que é o Asaas?', style: const TextStyle(color: Color(0xFF6D4C00), fontSize: 12, fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 6),
                    const Text(
                      'O Asaas é uma fintech brasileira regulamentada pelo Banco Central que cuida dos pagamentos por conta da sua academia. '
                      'Quando o aluno paga o PIX, o dinheiro cai direto na sua conta Asaas — você transfere para o seu banco quando quiser. '
                      'O Sensei Manager nunca toca no seu dinheiro.',
                      style: TextStyle(color: Color(0xFF6D4C00), fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Seus dados serão enviados ao Asaas para criar uma conta digital. '
                'Após aprovação, seus alunos poderão pagar via PIX diretamente pelo app.',
                style: TextStyle(color: kText2, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              Text('Dados que serão enviados:', style: TextStyle(color: kText1, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('• Nome: ${_nomeAcademia ?? ""}', style: TextStyle(color: kText2, fontSize: 12)),
              Text('• $_labelDocFiscal: $_valorDocFiscal', style: TextStyle(color: kText2, fontSize: 12)),
              Text('• Tipo: ${isPessoaFisica ? "Pessoa Física" : "Pessoa Jurídica"}', style: TextStyle(color: kText2, fontSize: 12)),
              Text('• E-mail: ${_emailAcademia ?? ""}', style: TextStyle(color: kText2, fontSize: 12)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar', style: TextStyle(color: kText2))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Confirmar e Ativar', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final faturamentoDouble = double.tryParse(
      _faturamentoCtrl.text.replaceAll('.', '').replaceAll(',', '.'),
    ) ?? 0.0;
    if (faturamentoDouble <= 0) {
      _mostrarSnack('Informe o faturamento mensal da academia antes de ativar pagamentos.');
      return;
    }

    setState(() => _processando = true);
    try {
      await firestoreService.updateAcademia(_academiaId!, {'faturamento_mensal': faturamentoDouble});
      final data = await PaymentRequestService.adminRequest(academiaId: _academiaId!, tipo: 'criarSubconta');
      if (mounted) {
        setState(() {
          _status = data['status'] as String? ?? 'PENDENTE';
        });
        _mostrarSnack('Conta criada! Aguardando aprovação do Asaas.', sucesso: true);
      }
    } on PaymentRequestError catch (e) {
      if (mounted) _mostrarSnack(e.message);
    } catch (_) {
      if (mounted) _mostrarSnack('Erro de conexão. Verifique sua internet.');
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  void _mostrarSnack(String msg, {bool sucesso = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: sucesso ? kSuccess : kDanger,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kSurface,
        foregroundColor: kText1,
        elevation: 0,
        title: Text('Pagamentos via App', style: TextStyle(color: kText1, fontSize: 17, fontWeight: FontWeight.w700)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: kBorder),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: kPrimary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 24),
                  _buildInfoCard(),
                  const SizedBox(height: 24),
                  _buildTaxasCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    if (_status == null || _status == 'DESVINCULADO') return _buildNaoConfigurado();
    if (_status == 'AGUARDANDO_SMS') return _buildAguardandoSms();
    if (_status == 'AGUARDANDO_CONTA_BANCARIA') return _buildAguardandoContaBancaria();
    if (_status == 'PENDENTE') return _buildPendente();
    return _buildAtivo();
  }

  Widget _buildNaoConfigurado() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: kPrimary.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(Icons.payments_rounded, color: kPrimary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Pagamentos via App', style: TextStyle(color: kText1, fontSize: 15, fontWeight: FontWeight.w700)),
                Text('Não configurado', style: TextStyle(color: kText2, fontSize: 13)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          Container(height: 1, color: kBorder),
          const SizedBox(height: 16),
          Text(
            'Permita que seus alunos paguem mensalidades, matrículas e taxas diretamente pelo app, via PIX.',
            style: TextStyle(color: kText2, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 8),
          _infoRow(Icons.pix_rounded, 'PIX instantâneo com QR Code automático'),
          _infoRow(Icons.account_balance_rounded, 'Dinheiro vai direto para sua conta'),
          _infoRow(Icons.lock_rounded, 'Seguro e certificado (PCI DSS)'),
          const SizedBox(height: 20),
          TextFormField(
            controller: _faturamentoCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [_MoneyInputFormatter()],
            style: TextStyle(color: kText1, fontSize: 15),
            decoration: InputDecoration(
              labelText: 'Faturamento Mensal (R\$)',
              labelStyle: TextStyle(color: kText2, fontSize: 13),
              prefixIcon: Icon(Icons.attach_money_rounded, color: kText2, size: 18),
              filled: true,
              fillColor: kBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPrimary, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              helperText: 'Faturamento bruto mensal — exigido pelo Asaas',
              helperMaxLines: 2,
              helperStyle: TextStyle(color: kText2, fontSize: 11),
            ),
          ),
          const SizedBox(height: 16),
          if (!_temDocFiscal)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kWarning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kWarning.withOpacity(0.3)),
              ),
              child: Row(children: [
                Icon(Icons.warning_amber_rounded, color: kWarning, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Preencha o CPF (pessoa física) ou CNPJ (pessoa jurídica) da academia em Configurações antes de continuar.',
                    style: TextStyle(color: kWarning, fontSize: 12),
                  ),
                ),
              ]),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _processando ? null : _ativarPagamentos,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _processando
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Ativar Pagamentos via App', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAguardandoSms() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimary.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: kPrimary.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(Icons.sms_rounded, color: kPrimary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Verifique seu telefone', style: TextStyle(color: kText1, fontSize: 15, fontWeight: FontWeight.w700)),
                Text('Código enviado por SMS', style: TextStyle(color: kPrimary, fontSize: 13)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          Container(height: 1, color: kBorder),
          const SizedBox(height: 16),
          Text(
            'O Asaas enviou um código de 6 dígitos via SMS para o telefone cadastrado da academia. Digite o código abaixo para continuar.',
            style: TextStyle(color: kText2, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _codigoSmsCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: TextStyle(color: kText1, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 8),
            decoration: InputDecoration(
              hintText: '------',
              hintStyle: TextStyle(color: kText2.withOpacity(0.4), fontSize: 24, letterSpacing: 8),
              counterText: '',
              filled: true,
              fillColor: kBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPrimary, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _processando ? null : _confirmarCodigo,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _processando
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Confirmar Código', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _processando ? null : _reenviarCodigo,
                child: Text('Reenviar SMS', style: TextStyle(color: kText2, fontSize: 12)),
              ),
              TextButton(
                onPressed: _processando ? null : _deletarSubconta,
                child: Text('Cancelar ativação', style: TextStyle(color: kText2, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAguardandoContaBancaria() {
    InputDecoration fieldDeco(String label, IconData icon) => InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: kText2, fontSize: 14),
      floatingLabelStyle: TextStyle(color: kPrimary, fontSize: 13, fontWeight: FontWeight.w600),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      prefixIcon: Icon(icon, color: kText2, size: 20),
      filled: true,
      fillColor: kBg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPrimary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimary.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: kPrimary.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(Icons.account_balance_rounded, color: kPrimary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Conta bancária de recebimento', style: TextStyle(color: kText1, fontSize: 15, fontWeight: FontWeight.w700)),
                Text('Para onde o dinheiro vai cair', style: TextStyle(color: kPrimary, fontSize: 13)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          Container(height: 1, color: kBorder),
          const SizedBox(height: 16),
          Text(
            'Informe os dados bancários da academia. O Asaas vai transferir os pagamentos recebidos para essa conta.',
            style: TextStyle(color: kText2, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),

          // Banco
          DropdownButtonFormField<String>(
            value: _bancoSelecionado,
            decoration: fieldDeco('Banco', Icons.account_balance_outlined),
            dropdownColor: kSurface,
            style: TextStyle(color: kText1, fontSize: 14),
            hint: Text('Selecione o banco', style: TextStyle(color: kText2, fontSize: 13)),
            items: _bancos.map((b) => DropdownMenuItem(
              value: b.$1,
              child: Text('${b.$1} – ${b.$2}', style: TextStyle(color: kText1, fontSize: 13)),
            )).toList(),
            onChanged: (v) => setState(() => _bancoSelecionado = v),
          ),
          const SizedBox(height: 12),

          // Agência (linha inteira)
          TextField(
            controller: _agenciaCtrl,
            keyboardType: TextInputType.number,
            style: TextStyle(color: kText1, fontSize: 15),
            decoration: fieldDeco('Agência', Icons.domain_rounded),
          ),
          const SizedBox(height: 12),

          // Número da Conta + Dígito
          Row(children: [
            Expanded(
              flex: 4,
              child: TextField(
                controller: _contaCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: kText1, fontSize: 15),
                decoration: fieldDeco('Número da Conta', Icons.credit_card_rounded),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 90,
              child: TextField(
                controller: _digitoCtrl,
                keyboardType: TextInputType.number,
                maxLength: 2,
                style: TextStyle(color: kText1, fontSize: 15),
                decoration: fieldDeco('Dígito', Icons.tag_rounded).copyWith(counterText: ''),
              ),
            ),
          ]),
          const SizedBox(height: 12),

          // Tipo de conta
          Row(children: [
            Expanded(
              child: _tipoContaBtn('Conta Corrente', 'CONTA_CORRENTE'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _tipoContaBtn('Conta Poupança', 'CONTA_POUPANCA'),
            ),
          ]),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _processando ? null : _configurarContaBancaria,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _processando
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Confirmar Dados Bancários', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _processando ? null : _deletarSubconta,
              child: Text('Cancelar ativação', style: TextStyle(color: kText2, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipoContaBtn(String label, String value) {
    final selected = _tipoConta == value;
    return GestureDetector(
      onTap: () => setState(() => _tipoConta = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? kPrimary.withOpacity(0.12) : kBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? kPrimary : kBorder, width: selected ? 1.5 : 1),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? kPrimary : kText2,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPendente() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kWarning.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: kWarning.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(Icons.hourglass_empty_rounded, color: kWarning, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Conta criada — Verificação pendente', style: TextStyle(color: kText1, fontSize: 15, fontWeight: FontWeight.w700)),
                Text('Aguardando aprovação do Asaas', style: TextStyle(color: kWarning, fontSize: 13)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          Container(height: 1, color: kBorder),
          const SizedBox(height: 16),

          _passoItem('1', Icons.check_circle_outline_rounded,
            'Dados enviados ao Asaas',
            'Sua conta e dados bancários foram registrados com sucesso. O Asaas está analisando as informações.'),
          const SizedBox(height: 12),
          _passoItem('2', Icons.hourglass_top_rounded,
            'Análise interna do Asaas',
            'O Asaas verifica identidade e dados bancários. Esse processo costuma levar algumas horas ou até 1 dia útil.'),
          const SizedBox(height: 12),
          _passoItem('3', Icons.check_circle_rounded,
            'Após aprovação, toque em "Verificar Status"',
            'Assim que o Asaas aprovar, o app é atualizado e seus alunos já podem pagar.'),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _processando ? null : _verificarStatus,
              icon: _processando
                  ? SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary))
                  : Icon(Icons.refresh_rounded, color: kPrimary, size: 18),
              label: Text('Verificar Status da Aprovação', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: kPrimary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _processando ? null : _deletarSubconta,
              child: Text('Desvincular conta Asaas', style: TextStyle(color: kText2, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passoItem(String numero, IconData icon, String titulo, String descricao) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(color: kPrimary.withOpacity(0.15), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(numero, style: TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(descricao, style: TextStyle(color: kText2, fontSize: 12, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAtivo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kSuccess.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: kSuccess.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(Icons.check_circle_rounded, color: kSuccess, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Pagamentos Ativos', style: TextStyle(color: kText1, fontSize: 15, fontWeight: FontWeight.w700)),
                Text('PIX, Boleto e Cartão disponíveis', style: TextStyle(color: kSuccess, fontSize: 13)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          Container(height: 1, color: kBorder),
          const SizedBox(height: 16),
          Text(
            'Seus alunos já podem pagar via PIX, Boleto ou Cartão de Crédito diretamente no app. O dinheiro é depositado automaticamente na conta bancária que você cadastrou.',
            style: TextStyle(color: kText2, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kSuccess.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kSuccess.withOpacity(0.2)),
            ),
            child: Row(children: [
              Icon(Icons.info_outline_rounded, color: kSuccess, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'O Asaas realiza as transferências automaticamente. O prazo depende do método de pagamento escolhido pelo aluno.',
                  style: TextStyle(color: kSuccess, fontSize: 12),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: _processando ? null : _deletarSubconta,
              icon: Icon(Icons.link_off_rounded, color: kText2, size: 16),
              label: Text('Desvincular conta Asaas', style: TextStyle(color: kText2, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dados da Academia', style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _dadoRow('Nome', _nomeAcademia ?? '—'),
          _dadoRow(_labelDocFiscal, _valorDocFiscal),
          _dadoRow('E-mail', _emailAcademia ?? '—'),
          const SizedBox(height: 4),
          Text(
            'Esses dados são usados para criar sua conta de recebimento.',
            style: TextStyle(color: kText2, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxasCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Formas de Pagamento', style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Taxas cobradas pelo Asaas, descontadas do valor recebido.', style: TextStyle(color: kText2, fontSize: 11)),
          const SizedBox(height: 14),
          _metodoRow(Icons.pix_rounded, 'PIX', 'Aprovação instantânea', '~R\$ 1,99 / transação'),
          const SizedBox(height: 10),
          _metodoRow(Icons.receipt_long_rounded, 'Boleto Bancário', 'Compensação em até 3 dias', '~R\$ 3,49 / transação'),
          const SizedBox(height: 10),
          _metodoRow(Icons.credit_card_rounded, 'Cartão de Crédito', 'Parcelamento disponível', '~2,99% (à vista)'),
          const SizedBox(height: 14),
          Container(height: 1, color: kBorder),
          const SizedBox(height: 10),
          Row(children: [
            Icon(Icons.favorite_rounded, color: kSuccess, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Comissão do Sensei Manager: R\$ 0,00 — nunca cobramos nada.',
                style: TextStyle(color: kSuccess, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _metodoRow(IconData icon, String titulo, String subtitulo, String taxa) {
    return Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: kPrimary, size: 18),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo, style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w600)),
          Text(subtitulo, style: TextStyle(color: kText2, fontSize: 11)),
        ]),
      ),
      Text(taxa, style: TextStyle(color: kText1, fontSize: 12, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Icon(icon, color: kPrimary, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: kText2, fontSize: 13))),
        ]),
      );

  Widget _dadoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          SizedBox(width: 60, child: Text(label, style: TextStyle(color: kText2, fontSize: 12))),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w500))),
        ]),
      );

  Widget _taxaRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Expanded(child: Text(label, style: TextStyle(color: kText2, fontSize: 13))),
          Text(value, style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      );
}

class _MoneyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return next.copyWith(text: '');
    final value = int.tryParse(digits) ?? 0;
    final intPart = value ~/ 100;
    final decPart = value % 100;
    final intStr = intPart == 0
        ? '0'
        : intPart.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    final result = '$intStr,${decPart.toString().padLeft(2, '0')}';
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}
