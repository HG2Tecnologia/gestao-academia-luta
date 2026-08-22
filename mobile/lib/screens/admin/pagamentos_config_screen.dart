import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '../../core/auth_storage.dart';
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

  // null = não configurado, 'PENDENTE' = aguardando KYC, 'ATIVO' = funcionando
  String? _status;
  String? _nomeAcademia;
  String? _cnpjAcademia;
  String? _emailAcademia;

  @override
  void initState() {
    super.initState();
    _load();
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
      _emailAcademia = acad['email'] as String?;
      _status = asaas?['status'] as String?;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _verificarStatus() async {
    if (_academiaId == null) return;
    setState(() => _processando = true);
    try {
      final fn = FirebaseFunctions.instanceFor(region: 'us-central1');
      final result = await fn.httpsCallable('verificarStatusAsaas').call({'academiaId': _academiaId});
      final data = result.data as Map;
      if (mounted) {
        final novoStatus = data['status'] as String? ?? _status;
        setState(() => _status = novoStatus);
        if (_status == 'ATIVO') {
          _mostrarSnack('Conta aprovada! Pagamentos via PIX já estão ativos.', sucesso: true);
        } else {
          _mostrarSnack('Ainda aguardando aprovação. Tente novamente em alguns minutos.');
        }
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) _mostrarSnack(e.message ?? 'Erro ao verificar status.');
    } catch (_) {
      if (mounted) _mostrarSnack('Erro de conexão. Verifique sua internet.');
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  Future<void> _ativarPagamentos() async {
    if (_academiaId == null) return;
    if ((_cnpjAcademia ?? '').replaceAll(RegExp(r'\D'), '').length < 11) {
      _mostrarSnack('Preencha o CNPJ da academia em Configurações antes de ativar pagamentos.');
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Ativar Pagamentos via App', style: TextStyle(color: kText1, fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          'Seus dados (nome, CNPJ, e-mail) serão enviados ao Asaas para criar uma conta digital. '
          'Após aprovação, seus alunos poderão pagar via PIX diretamente pelo app.\n\n'
          'Dados que serão enviados:\n'
          '• Nome: ${_nomeAcademia ?? ""}\n'
          '• CNPJ: ${_cnpjAcademia ?? ""}\n'
          '• E-mail: ${_emailAcademia ?? ""}',
          style: TextStyle(color: kText2, fontSize: 13),
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

    setState(() => _processando = true);
    try {
      final fn = FirebaseFunctions.instanceFor(region: 'us-central1');
      final result = await fn.httpsCallable('criarSubcontaAcademia').call({'academiaId': _academiaId});
      final data = result.data as Map;
      if (mounted) {
        setState(() {
          _status = data['status'] as String? ?? 'PENDENTE';
        });
        _mostrarSnack(
          'Conta criada! Aguardando aprovação do Asaas.',
          sucesso: true,
        );
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) _mostrarSnack(e.message ?? 'Erro ao criar conta.');
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
    if (_status == null) return _buildNaoConfigurado();
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
          if ((_cnpjAcademia ?? '').isEmpty)
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
                    'Preencha o CNPJ da academia em Configurações antes de continuar.',
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
                Text('Aguardando Aprovação', style: TextStyle(color: kText1, fontSize: 15, fontWeight: FontWeight.w700)),
                Text('Verificação em andamento', style: TextStyle(color: kWarning, fontSize: 13)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          Container(height: 1, color: kBorder),
          const SizedBox(height: 16),
          Text(
            'Seus dados foram enviados ao Asaas. A aprovação costuma acontecer em minutos no sandbox. '
            'Em produção pode levar até 24h.',
            style: TextStyle(color: kText2, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _processando ? null : _verificarStatus,
              icon: _processando
                  ? SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary))
                  : Icon(Icons.refresh_rounded, color: kPrimary, size: 18),
              label: Text('Verificar Status', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: kPrimary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
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
                Text('PIX disponível para alunos', style: TextStyle(color: kSuccess, fontSize: 13)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          Container(height: 1, color: kBorder),
          const SizedBox(height: 16),
          Text(
            'Seus alunos já podem pagar via PIX diretamente no app. O dinheiro é depositado automaticamente na sua conta Asaas e transferido para o banco que você configurar no painel do Asaas.',
            style: TextStyle(color: kText2, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kBorder),
            ),
            child: Row(children: [
              Icon(Icons.info_outline_rounded, color: kText2, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Para configurar sua conta bancária de recebimento, acesse o painel Asaas em sandbox.asaas.com',
                  style: TextStyle(color: kText2, fontSize: 12),
                ),
              ),
            ]),
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
          _dadoRow('CNPJ', _cnpjAcademia ?? '—'),
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
          Text('Taxas por Transação', style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Cobradas pelo Asaas, descontadas do valor recebido.', style: TextStyle(color: kText2, fontSize: 11)),
          const SizedBox(height: 12),
          _taxaRow('PIX', '~R\$ 1,99 por transação'),
          _taxaRow('Cartão crédito (à vista)', '~2,99%'),
          _taxaRow('Nossa comissão', 'R\$ 0,00 — nunca cobramos'),
        ],
      ),
    );
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
