import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/firestore_service.dart';
import '../../core/paywall_modal.dart';
import '../../core/plan_service.dart';
import 'modalidades_screen.dart';
import 'planos_screen.dart';

class AdminConfiguracoesScreen extends StatefulWidget {
  const AdminConfiguracoesScreen({super.key});

  @override
  State<AdminConfiguracoesScreen> createState() => _AdminConfiguracoesScreenState();
}

class _AdminConfiguracoesScreenState extends State<AdminConfiguracoesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _cnpjCtrl = TextEditingController();

  bool _loading = true;
  bool _salvando = false;
  bool _erro = false;
  String _subdominio = '';
  String? _logoBase64;
  bool _bloqueioCheckinAtivo = false;
  int _carenciaDias = 3;
  bool _pesquisaAtiva = false;
  int _pesquisaXpRecompensa = 50;
  bool _taxaAtrasoAtiva = false;
  int _taxaAtrasoTipo = 0; // 0=percentual, 1=fixo
  final _taxaAtrasoValorCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _telefoneCtrl.dispose();
    _cnpjCtrl.dispose();
    _taxaAtrasoValorCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _erro = false; });
    try {
      final user = await AuthStorage.getUser();
      final academiaId = user!.academiaId!;
      final dados = await firestoreService.getAcademia(academiaId) ?? {};
      _nomeCtrl.text = dados['nome'] as String? ?? '';
      _emailCtrl.text = dados['email'] as String? ?? '';
      _telefoneCtrl.text = dados['telefone'] as String? ?? '';
      _cnpjCtrl.text = dados['cnpj'] as String? ?? '';
      _subdominio = dados['subdominio'] as String? ?? '';
      _logoBase64 = dados['logoUrl'] as String?;
      _bloqueioCheckinAtivo = dados['bloqueio_checkin_ativo'] as bool? ?? false;
      _carenciaDias = (dados['bloqueio_checkin_carencia_dias'] as num?)?.toInt() ?? 3;
      _pesquisaAtiva = dados['pesquisa_satisfacao_ativa'] as bool? ?? false;
      _pesquisaXpRecompensa = (dados['pesquisa_xp_recompensa'] as num?)?.toInt() ?? 50;
      _taxaAtrasoAtiva = dados['taxa_atraso_ativa'] as bool? ?? false;
      _taxaAtrasoTipo = (dados['taxa_atraso_tipo'] as num?)?.toInt() ?? 0;
      _taxaAtrasoValorCtrl.text = ((dados['taxa_atraso_valor'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2).replaceAll('.', ',');
      if (mounted) setState(() { _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _erro = true; _loading = false; });
    }
  }

  Future<void> _escolherLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;
    final bytes = result.files.single.bytes!;
    final ext = (result.files.single.extension ?? 'jpg').toLowerCase();
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
    setState(() => _logoBase64 = 'data:$mime;base64,${base64Encode(bytes)}');
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _salvando = true; });
    try {
      final user = await AuthStorage.getUser();
      final academiaId = user!.academiaId!;
      await firestoreService.updateAcademia(academiaId, {
        'nome': _nomeCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'telefone': _telefoneCtrl.text.trim().isEmpty ? null : _telefoneCtrl.text.trim(),
        'cnpj': _cnpjCtrl.text.trim().isEmpty ? null : _cnpjCtrl.text.trim(),
        'logoUrl': _logoBase64,
        'bloqueio_checkin_ativo': _bloqueioCheckinAtivo,
        'bloqueio_checkin_carencia_dias': _carenciaDias,
        'pesquisa_satisfacao_ativa': _pesquisaAtiva,
        'pesquisa_xp_recompensa': _pesquisaXpRecompensa,
        'taxa_atraso_ativa': _taxaAtrasoAtiva,
        'taxa_atraso_tipo': _taxaAtrasoTipo,
        'taxa_atraso_valor': double.tryParse(_taxaAtrasoValorCtrl.text.replaceAll(',', '.')) ?? 0.0,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Configurações salvas com sucesso!'),
          backgroundColor: kSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Erro ao salvar configurações'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() { _salvando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: kText1, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('Configurações da Academia', style: TextStyle(color: kText1, fontSize: 17, fontWeight: FontWeight.w800)),
        actions: [
          if (!_loading && !_erro)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _salvando
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : TextButton(
                      onPressed: _salvar,
                      style: TextButton.styleFrom(
                        backgroundColor: kPrimary.withOpacity(0.12),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Salvar', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700)),
                    ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erro
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded, color: kDanger, size: 52),
                      const SizedBox(height: 14),
                      Text('Não foi possível carregar', style: TextStyle(color: kText2)),
                      const SizedBox(height: 18),
                      OutlinedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Tentar novamente'),
                        style: OutlinedButton.styleFrom(foregroundColor: kPrimary),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PlanStatusTile(),
                        const SizedBox(height: 24),
                        _SectionLabel('Logo da Academia'),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _escolherLogo,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: kSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kBorder),
                            ),
                            child: Row(children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: _logoBase64 != null && _logoBase64!.contains(',')
                                    ? Image.memory(
                                        base64Decode(_logoBase64!.split(',').last),
                                        width: 52, height: 52, fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: 52, height: 52,
                                        decoration: BoxDecoration(
                                          color: kPrimary.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(Icons.add_photo_alternate_rounded, color: kPrimary, size: 26),
                                      ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(
                                  _logoBase64 != null ? 'Logo definida' : 'Adicionar logo',
                                  style: TextStyle(color: kText1, fontWeight: FontWeight.w700),
                                ),
                                Text('Toque para alterar a imagem', style: TextStyle(color: kText2, fontSize: 12)),
                              ])),
                              if (_logoBase64 != null)
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, color: kDanger, size: 20),
                                  tooltip: 'Remover logo',
                                  onPressed: () => setState(() => _logoBase64 = null),
                                ),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _SectionLabel('Informações Gerais'),
                        const SizedBox(height: 12),
                        _Field(
                          controller: _nomeCtrl,
                          label: 'Nome da Academia',
                          icon: Icons.sports_martial_arts_rounded,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                        ),
                        const SizedBox(height: 12),
                        _Field(
                          controller: _emailCtrl,
                          label: 'E-mail',
                          icon: Icons.email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Obrigatório';
                            if (!v.contains('@')) return 'E-mail inválido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _Field(
                          controller: _telefoneCtrl,
                          label: 'Telefone',
                          icon: Icons.phone_rounded,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        _Field(
                          controller: _cnpjCtrl,
                          label: 'CNPJ',
                          icon: Icons.business_rounded,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 24),
                        _SectionLabel('Alunos'),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('Bloquear check-in por mensalidade vencida', style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text('Impede check-in de alunos com pagamento vencido', style: TextStyle(color: kText2, fontSize: 12)),
                                ])),
                                Switch(
                                  value: _bloqueioCheckinAtivo,
                                  onChanged: (v) => setState(() => _bloqueioCheckinAtivo = v),
                                  activeColor: kPrimary,
                                ),
                              ]),
                              if (_bloqueioCheckinAtivo) ...[
                                const Divider(height: 20),
                                Row(children: [
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('Dias de carência', style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w600)),
                                    Text('Bloqueia após este número de dias do vencimento', style: TextStyle(color: kText2, fontSize: 12)),
                                  ])),
                                  Row(children: [
                                    IconButton(
                                      icon: Icon(Icons.remove_circle_outline_rounded, color: _carenciaDias > 0 ? kPrimary : kBorder),
                                      onPressed: _carenciaDias > 0 ? () => setState(() => _carenciaDias--) : null,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Text('$_carenciaDias', style: TextStyle(color: kText1, fontSize: 18, fontWeight: FontWeight.w800)),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.add_circle_outline_rounded, color: _carenciaDias < 30 ? kPrimary : kBorder),
                                      onPressed: _carenciaDias < 30 ? () => setState(() => _carenciaDias++) : null,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ]),
                                ]),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _SectionLabel('Financeiro'),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPlanosScreen())),
                          child: _NavTile(
                            icon: Icons.credit_card_rounded,
                            iconColor: kSuccess,
                            label: 'Planos de Pagamento',
                            subtitle: 'Criar, editar e excluir planos de mensalidade',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kBorder),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Taxa de atraso', style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w600)),
                                Text('Valor extra exibido em cobranças vencidas', style: TextStyle(color: kText2, fontSize: 12)),
                              ])),
                              Switch(
                                value: _taxaAtrasoAtiva,
                                onChanged: (v) => setState(() => _taxaAtrasoAtiva = v),
                                activeColor: kPrimary,
                              ),
                            ]),
                            if (_taxaAtrasoAtiva) ...[
                              const Divider(height: 20),
                              Row(children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _taxaAtrasoTipo = 0),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: _taxaAtrasoTipo == 0 ? kPrimary : kBg,
                                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                                        border: Border.all(color: _taxaAtrasoTipo == 0 ? kPrimary : kBorder),
                                      ),
                                      child: Text('Percentual (%)', textAlign: TextAlign.center,
                                          style: TextStyle(color: _taxaAtrasoTipo == 0 ? Colors.white : kText2, fontSize: 13, fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _taxaAtrasoTipo = 1),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: _taxaAtrasoTipo == 1 ? kPrimary : kBg,
                                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                                        border: Border.all(color: _taxaAtrasoTipo == 1 ? kPrimary : kBorder),
                                      ),
                                      child: Text('Valor fixo (R\$)', textAlign: TextAlign.center,
                                          style: TextStyle(color: _taxaAtrasoTipo == 1 ? Colors.white : kText2, fontSize: 13, fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _taxaAtrasoValorCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: TextStyle(color: kText1),
                                decoration: InputDecoration(
                                  labelText: _taxaAtrasoTipo == 0 ? 'Percentual de atraso' : 'Valor fixo de atraso',
                                  labelStyle: TextStyle(color: kText2, fontSize: 13),
                                  prefixText: _taxaAtrasoTipo == 1 ? 'R\$ ' : null,
                                  suffixText: _taxaAtrasoTipo == 0 ? '%' : null,
                                  filled: true,
                                  fillColor: kBg,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kPrimary)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  helperText: _taxaAtrasoTipo == 0
                                      ? 'Ex: 2,00 = 2% sobre o valor da cobrança'
                                      : 'Ex: 20,00 = R\$ 20,00 a mais no vencimento',
                                  helperStyle: TextStyle(color: kText2, fontSize: 11),
                                ),
                              ),
                            ],
                          ]),
                        ),
                        const SizedBox(height: 24),
                        _SectionLabel('Graduações'),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => context.push('/admin/dashboard/faixas'),
                          child: _NavTile(
                            icon: Icons.military_tech_rounded,
                            iconColor: kWarning,
                            label: 'Gestão de Faixas',
                            subtitle: 'Cadastrar e editar graduações por modalidade',
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminModalidadesScreen())),
                          child: _NavTile(
                            icon: Icons.category_rounded,
                            iconColor: kPrimary,
                            label: 'Gestão de Modalidades',
                            subtitle: 'Ativar, desativar ou criar modalidades da academia',
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => context.push('/admin/dashboard/contratos'),
                          child: _NavTile(
                            icon: Icons.description_rounded,
                            iconColor: kPrimary,
                            label: 'Modelos de Contrato',
                            subtitle: 'Criar e editar templates de contrato',
                          ),
                        ),
                        const SizedBox(height: 24),
                        _SectionLabel('Comunicação'),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => context.push('/admin/noticias'),
                          child: _NavTile(
                            icon: Icons.newspaper_rounded,
                            iconColor: const Color(0xFFC9A020),
                            label: 'Notícias',
                            subtitle: 'Publicar notícias e comunicados para alunos e professores',
                          ),
                        ),
                        const SizedBox(height: 24),
                        _SectionLabel('Pesquisa de Satisfação'),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kBorder),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Ativar pesquisa mensal', style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w600)),
                                Text('Alunos serão convidados a avaliar a academia 1x/mês', style: TextStyle(color: kText2, fontSize: 11)),
                              ])),
                              Switch(
                                value: _pesquisaAtiva,
                                onChanged: (v) => setState(() => _pesquisaAtiva = v),
                                activeColor: kPrimary,
                              ),
                            ]),
                            if (_pesquisaAtiva) ...[
                              const Divider(height: 20),
                              Row(children: [
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('XP por resposta', style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w600)),
                                  Text('Pontos XP concedidos ao aluno após responder', style: TextStyle(color: kText2, fontSize: 11)),
                                ])),
                                Row(children: [
                                  IconButton(
                                    icon: Icon(Icons.remove_circle_outline_rounded, color: _pesquisaXpRecompensa > 0 ? kPrimary : kBorder),
                                    onPressed: _pesquisaXpRecompensa >= 25 ? () => setState(() => _pesquisaXpRecompensa -= 25) : null,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text('$_pesquisaXpRecompensa', style: TextStyle(color: kText1, fontSize: 18, fontWeight: FontWeight.w800)),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.add_circle_outline_rounded, color: _pesquisaXpRecompensa < 500 ? kPrimary : kBorder),
                                    onPressed: _pesquisaXpRecompensa < 500 ? () => setState(() => _pesquisaXpRecompensa += 25) : null,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ]),
                              ]),
                            ],
                          ]),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => context.push('/admin/pesquisa/templates'),
                          child: _NavTile(
                            icon: Icons.poll_rounded,
                            iconColor: kPrimary,
                            label: 'Gerenciar pesquisas',
                            subtitle: 'Criar, ativar e ver resultados por tipo de pesquisa',
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => context.push('/admin/pesquisa'),
                          child: _NavTile(
                            icon: Icons.bar_chart_rounded,
                            iconColor: kPrimary,
                            label: 'Ver todas as respostas',
                            subtitle: 'Visualizar avaliações e comentários dos alunos',
                          ),
                        ),
                        const SizedBox(height: 24),
                        _SectionLabel('Informações do Sistema'),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kBorder),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.link_rounded, color: kText2, size: 18),
                              const SizedBox(width: 10),
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Subdomínio', style: TextStyle(color: kText2, fontSize: 11)),
                                Text(_subdominio.isEmpty ? '—' : _subdominio,
                                    style: TextStyle(color: kText1, fontWeight: FontWeight.w600)),
                              ]),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _SectionLabel('Legal'),
                        const SizedBox(height: 12),
                        _LegalTile(
                          icon: Icons.privacy_tip_outlined,
                          label: 'Política de Privacidade',
                          subtitle: 'Como tratamos seus dados (LGPD)',
                          url: 'https://senseimanager.com.br/privacidade',
                        ),
                        const SizedBox(height: 8),
                        _LegalTile(
                          icon: Icons.gavel_rounded,
                          label: 'Termos de Uso',
                          subtitle: 'Condições de uso do Sensei Manager',
                          url: 'https://senseimanager.com.br/termos',
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _salvando ? null : _salvar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _salvando
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Salvar Configurações', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(height: 32),
                        _SectionLabel('Conta'),
                        const SizedBox(height: 12),
                        _BotaoSair(),
                        const SizedBox(height: 16),
                        _SectionLabel('Zona de Perigo'),
                        const SizedBox(height: 12),
                        _BotaoExcluirConta(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.icon, required this.iconColor, required this.label, required this.subtitle});
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(color: kText1, fontWeight: FontWeight.w700)),
              Text(subtitle, style: TextStyle(color: kText2, fontSize: 11)),
            ]),
          ),
          Icon(Icons.chevron_right_rounded, color: kText2),
        ],
      ),
    );
  }
}

class _LegalTile extends StatelessWidget {
  const _LegalTile({required this.icon, required this.label, required this.subtitle, required this.url});
  final IconData icon;
  final String label;
  final String subtitle;
  final String url;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: kPrimary.withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: kPrimary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: kText1, fontWeight: FontWeight.w700)),
            Text(subtitle, style: TextStyle(color: kText2, fontSize: 11)),
          ])),
          Icon(Icons.open_in_new_rounded, color: kText2, size: 16),
        ]),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.4));
  }
}

class _BotaoSair extends StatefulWidget {
  @override
  State<_BotaoSair> createState() => _BotaoSairState();
}

class _BotaoSairState extends State<_BotaoSair> {
  bool _loading = false;

  Future<void> _sair() async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Sair', style: TextStyle(color: kText1, fontWeight: FontWeight.w800)),
        content: Text('Deseja encerrar sua sessão?', style: TextStyle(color: kText2)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: Text('Cancelar', style: TextStyle(color: kText2))),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text('Sair', style: TextStyle(color: kDanger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirma != true || !mounted) return;
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    await AuthStorage.clear();
    if (!mounted) return;
    context.go('/boas-vindas');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _loading ? null : _sair,
        icon: _loading
            ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: kDanger))
            : Icon(Icons.logout_rounded, color: kDanger, size: 18),
        label: const Text('Sair da conta', style: TextStyle(fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(
          foregroundColor: kDanger,
          side: BorderSide(color: kDanger.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _BotaoExcluirConta extends StatefulWidget {
  @override
  State<_BotaoExcluirConta> createState() => _BotaoExcluirContaState();
}

class _BotaoExcluirContaState extends State<_BotaoExcluirConta> {
  bool _loading = false;

  Future<void> _excluir() async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Excluir conta?', style: TextStyle(color: kText1, fontWeight: FontWeight.w800)),
        content: Text(
          'Seus dados pessoais serão removidos permanentemente. Esta ação não pode ser desfeita.',
          style: TextStyle(color: kText2),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: Text('Cancelar', style: TextStyle(color: kText2))),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text('Excluir', style: TextStyle(color: kDanger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirma != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.currentUser?.delete();
      await AuthStorage.clear();
      if (!mounted) return;
      context.go('/boas-vindas');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Erro ao excluir conta. Tente novamente.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _loading ? null : _excluir,
        style: OutlinedButton.styleFrom(
          foregroundColor: kDanger,
          side: BorderSide(color: kDanger.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _loading
            ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: kDanger))
            : const Text('Excluir minha conta', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ─── Plan status tile ────────────────────────────────────────────────────────

class _PlanStatusTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final plan = PlanService.instance;
    final isPro = plan.isPro;
    final isInTrial = plan.isInTrial;
    final days = plan.daysLeftInTrial;
    final displayName = plan.planDisplayName;

    final Color borderColor = isPro
        ? const Color(0xFF6C3FFF)
        : isInTrial
            ? const Color(0xFF6C3FFF)
            : kWarning;
    final Color iconColor = isPro ? const Color(0xFFFFD700) : isInTrial ? kPrimary : kWarning;
    final IconData icon = isPro
        ? Icons.workspace_premium_rounded
        : isInTrial
            ? Icons.hourglass_top_rounded
            : Icons.lock_outline_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor.withOpacity(0.5)),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(displayName,
              style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w800)),
          if (isPro)
            Text('Acesso completo sem anúncios', style: TextStyle(color: kText2, fontSize: 12))
          else if (isInTrial)
            Text(days <= 1 ? 'Último dia do trial!' : '$days dias restantes no trial',
                style: TextStyle(color: kText2, fontSize: 12))
          else
            Text('3 turmas · 10 alunos/turma · anúncios', style: TextStyle(color: kText2, fontSize: 12)),
        ])),
        if (!isPro) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              final ok = await mostrarPaywall(context);
              if (ok == true) await PlanService.instance.refresh();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Assinar PRO',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ]),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: kText1, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: kText2, fontSize: 13),
        prefixIcon: Icon(icon, color: kText2, size: 18),
        filled: true,
        fillColor: kSurface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPrimary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kDanger)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kDanger, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
