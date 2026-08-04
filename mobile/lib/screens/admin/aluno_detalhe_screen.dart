import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/firestore_service.dart';
import '../../core/widgets.dart';

class AdminAlunoDetalheScreen extends StatefulWidget {
  final String alunoId;
  const AdminAlunoDetalheScreen({super.key, required this.alunoId});

  @override
  State<AdminAlunoDetalheScreen> createState() => _AdminAlunoDetalheScreenState();
}

class _AdminAlunoDetalheScreenState extends State<AdminAlunoDetalheScreen> {
  Map<String, dynamic>? _aluno;
  Map<String, dynamic>? _atestado;
  Map<String, dynamic>? _parq;
  Map<String, dynamic>? _grupoFamiliar;
  List<Map<String, dynamic>> _membrosGrupo = [];
  Map<String, dynamic>? _plano;
  String? _meId;
  String? _academiaId;
  bool _loading = true;
  String? _erro;
  bool _uploadingAtestado = false;
  // Faixa mais recente aprovada por modalidade: { nomeModalidade -> { nome, cor } }
  Map<String, Map<String, dynamic>> _faixasPorModalidade = {};
  List<Map<String, dynamic>> _graduacoes = [];
  String? _histModFiltro; // null = todas as modalidades

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _erro = null; });
    try {
      final user = await AuthStorage.getUser();
      final academiaId = user?.academiaId;
      if (academiaId == null) throw Exception('Academia não identificada');
      _academiaId = academiaId;
      _meId = user?.id;

      final results = await Future.wait([
        firestoreService.getAluno(academiaId, widget.alunoId),
        firestoreService.getGraduacoes(academiaId, alunoId: widget.alunoId, detalhadas: true),
        firestoreService.getAtestadoAluno(academiaId, widget.alunoId),
        firestoreService.getParQ(academiaId, widget.alunoId),
        firestoreService.getGruposFamiliares(academiaId),
        firestoreService.getFaixas(academiaId),
        firestoreService.getMatriculas(academiaId, alunoId: widget.alunoId, ativasOnly: false),
        firestoreService.getTurmas(academiaId),
      ]);

      final alunoRaw = results[0] as Map<String, dynamic>?;
      if (alunoRaw == null) throw Exception('Aluno não encontrado');
      final graduacoesRaw = (results[1] as List).cast<Map<String, dynamic>>();
      final atestadoRaw = results[2] as Map<String, dynamic>?;
      final parqRaw = results[3] as Map<String, dynamic>?;
      final grupos = (results[4] as List).cast<Map<String, dynamic>>();
      final faixas = (results[5] as List).cast<Map<String, dynamic>>();
      final matriculas = (results[6] as List).cast<Map<String, dynamic>>();
      final todasTurmas = (results[7] as List).cast<Map<String, dynamic>>();

      final faixaMap = <String, Map<String, dynamic>>{
        for (final f in faixas) f['id'].toString(): f,
      };
      final turmaMap = <String, Map<String, dynamic>>{
        for (final t in todasTurmas) t['id'].toString(): t,
      };
      final matriculaIds = matriculas
          .map((m) => m['turma_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
      final alunoTurmas = matriculaIds
          .map((id) => turmaMap[id])
          .whereType<Map<String, dynamic>>()
          .toList();
      final turmaNomes = alunoTurmas
          .map((t) => t['nome']?.toString() ?? '')
          .where((n) => n.isNotEmpty)
          .toList();
      final turmasDetails = alunoTurmas.map((t) => <String, dynamic>{
        'modalidadeId': (t['modalidadeId'] ?? t['modalidade_id'])?.toString() ?? '',
        'modalidadeNome': (t['modalidadeNome'] ?? t['modalidade_nome'])?.toString() ?? '',
        'nome': t['nome'],
      }).toList();

      // Normaliza aluno (snake_case → camelCase para compatibilidade com UI)
      final aluno = <String, dynamic>{
        ...alunoRaw,
        'dataNascimento': alunoRaw['data_nascimento'],
        'diaVencimento': alunoRaw['dia_vencimento'],
        'xpTotal': alunoRaw['xp_total'],
        'contatoEmergenciaNome': alunoRaw['contato_emergencia_nome'],
        'contatoEmergenciaTelefone': alunoRaw['contato_emergencia_telefone'],
        'fotoBase64': alunoRaw['fotoBase64'] ?? alunoRaw['foto_base64'],
        'planoId': alunoRaw['plano_id'],
        'planoNome': alunoRaw['plano_nome'],
        'tipoPlano': alunoRaw['tipo_plano'],
        'turmas': turmaNomes,
        'turmasDetalhes': turmasDetails,
      };

      // Enriquece graduações com dados da faixa
      final enrichedGraduacoes = graduacoesRaw.map((g) {
        final faixaId = g['faixa_id']?.toString() ?? '';
        final f = faixaMap[faixaId] ?? {};
        return <String, dynamic>{
          ...g,
          'faixaId': faixaId,
          'nomeFaixa': f['nome'] ?? '',
          'corFaixa': f['cor'] ?? '#FFFFFF',
          'corBarraFaixa': f['cor_barra'] ?? '#000000',
          'faixaTemGraus': f['tem_graus'] == true,
          'faixaMaxGraus': (f['max_graus'] as num?)?.toInt() ?? 4,
          'faixaOrdem': (f['ordem'] as num?)?.toInt() ?? 0,
          'nomeModalidade': g['nomeModalidade'] ?? f['modalidade_nome'] ?? 'Modalidade',
          'dataExame': g['data_exame'] ?? '',
          'nomeProfessor': '',
          'grau': (g['grau'] as num?)?.toInt() ?? 0,
          'aprovado': g['aprovado'] == true,
        };
      }).toList();

      final Map<String, Map<String, dynamic>> faixasMod = {};
      for (final g in enrichedGraduacoes) {
        if (g['aprovado'] != true) continue;
        final modNome = g['nomeModalidade']?.toString() ?? 'Sem modalidade';
        final faixaOrdem = (g['faixaOrdem'] as num?)?.toInt() ?? 0;
        final grau = (g['grau'] as num?)?.toInt() ?? 0;
        final existing = faixasMod[modNome];
        final existingOrdem = (existing?['_faixaOrdem'] as int?) ?? -1;
        final existingGrau = (existing?['grau'] as int?) ?? -1;
        if (existing == null || faixaOrdem > existingOrdem || (faixaOrdem == existingOrdem && grau > existingGrau)) {
          faixasMod[modNome] = {
            'id': g['faixaId']?.toString() ?? '',
            'nome': g['nomeFaixa'] ?? '',
            'cor': g['corFaixa'] ?? '#FFFFFF',
            'corBarra': g['corBarraFaixa'] ?? '#000000',
            'temGraus': g['faixaTemGraus'] == true,
            'maxGraus': (g['faixaMaxGraus'] as num?)?.toInt() ?? 4,
            '_faixaOrdem': faixaOrdem,
            'grau': grau,
          };
        }
      }

      // Normaliza PAR-Q
      final parq = parqRaw == null ? null : <String, dynamic>{
        ...parqRaw,
        'nomeCompleto': parqRaw['nome_completo'],
        'dataPreenchimento': parqRaw['data_preenchimento'],
        'requerAvaliacaoMedica': parqRaw['requer_avaliacao_medica'] == true,
        'r1': parqRaw['r1'] == true, 'r2': parqRaw['r2'] == true,
        'r3': parqRaw['r3'] == true, 'r4': parqRaw['r4'] == true,
        'r5': parqRaw['r5'] == true, 'r6': parqRaw['r6'] == true,
        'r7': parqRaw['r7'] == true, 'r8': parqRaw['r8'] == true,
        'r9': parqRaw['r9'] == true, 'r10': parqRaw['r10'] == true,
      };

      // Normaliza atestado
      final atestado = atestadoRaw == null ? null : <String, dynamic>{
        ...atestadoRaw,
        'arquivoBase64': atestadoRaw['arquivo_base64'],
        'arquivoMimeType': atestadoRaw['arquivo_mime_type'],
        'dataValidade': atestadoRaw['data_validade'],
        'motivoRejeicao': atestadoRaw['motivo_rejeicao'],
        'status': (atestadoRaw['status'] as num?)?.toInt() ?? 0,
      };

      // Encontra grupo familiar pelo campo grupo_familiar_id do aluno
      Map<String, dynamic>? grupoFamiliar;
      List<Map<String, dynamic>> membrosGrupo = [];
      final grupoIdAluno = alunoRaw['grupo_familiar_id']?.toString() ?? '';
      if (grupoIdAluno.isNotEmpty) {
        try {
          grupoFamiliar = grupos.firstWhere((g) => g['id']?.toString() == grupoIdAluno);
        } catch (_) {}
        try {
          membrosGrupo = await firestoreService.getMembrosGrupo(academiaId, grupoIdAluno);
        } catch (_) {}
      }

      // Carrega dados completos do plano (incluindo valor_mensal)
      Map<String, dynamic>? planoData;
      final planoId = alunoRaw['plano_id']?.toString() ?? '';
      if (planoId.isNotEmpty) {
        try {
          planoData = await firestoreService.getPlano(academiaId, planoId);
        } catch (_) {}
      }

      if (mounted) setState(() {
        _aluno = aluno;
        _atestado = atestado;
        _parq = parq;
        _grupoFamiliar = grupoFamiliar;
        _membrosGrupo = membrosGrupo;
        _plano = planoData;
        _faixasPorModalidade = faixasMod;
        _graduacoes = List.of(enrichedGraduacoes)
          ..sort((a, b) {
            try {
              return DateTime.parse(b['dataExame'].toString())
                  .compareTo(DateTime.parse(a['dataExame'].toString()));
            } catch (_) { return 0; }
          });
      });
    } catch (_) {
      if (mounted) setState(() => _erro = 'Erro ao carregar aluno.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleAtivo() async {
    final a = _aluno;
    if (a == null) return;
    final novoStatus = !(a['ativo'] == true);
    final acao = novoStatus ? 'ativar' : 'desativar';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Confirmar', style: TextStyle(color: kText1)),
        content: Text('Deseja $acao ${a['nome']}?', style: TextStyle(color: kText2)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Cancelar', style: TextStyle(color: kText2))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text('Confirmar', style: TextStyle(color: kPrimary))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await firestoreService.updateAluno(_academiaId!, widget.alunoId, {'ativo': novoStatus});
      _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Erro ao alterar status.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _toggleAcessoApp() async {
    final a = _aluno;
    if (a == null) return;
    final bloqueado = a['acesso_app_bloqueado'] == true;
    final acao = bloqueado ? 'liberar' : 'bloquear';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Confirmar', style: TextStyle(color: kText1)),
        content: Text('Deseja $acao o acesso ao app de ${a['nome']}?', style: TextStyle(color: kText2)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Cancelar', style: TextStyle(color: kText2))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text('Confirmar', style: TextStyle(color: kPrimary))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await firestoreService.updateAluno(_academiaId!, widget.alunoId, {'acesso_app_bloqueado': !bloqueado});
      _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Erro ao alterar acesso.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  // ── PAR-Q ────────────────────────────────────────────

  static const _perguntas = [
    'Algum médico já disse que você possui algum problema de coração ou pressão arterial, e que somente deveria realizar atividade física supervisionado por profissionais de saúde?',
    'Você sente dores no peito quando pratica atividade física?',
    'No último mês, você sentiu dores no peito ao praticar atividade física?',
    'Você apresenta algum desequilíbrio devido à tontura e/ou perda momentânea da consciência?',
    'Você possui algum problema ósseo ou articular, que pode ser afetado ou agravado pela atividade física?',
    'Você toma atualmente algum tipo de medicação de uso contínuo?',
    'Você realiza algum tipo de tratamento médico para pressão arterial ou problemas cardíacos?',
    'Você realiza algum tratamento médico contínuo, que possa ser afetado ou prejudicado com a atividade física?',
    'Você já se submeteu a algum tipo de cirurgia, que comprometa de alguma forma a atividade física?',
    'Sabe de alguma outra razão pela qual a atividade física possa eventualmente comprometer sua saúde?',
  ];

  Future<void> _criarGrupoFamiliar() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Criar Grupo Familiar', style: TextStyle(color: kText1, fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('O aluno será adicionado automaticamente ao grupo.', style: TextStyle(color: kText2, fontSize: 13)),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            autofocus: true,
            style: TextStyle(color: kText1),
            decoration: InputDecoration(
              hintText: 'Ex: Família Silva',
              hintStyle: TextStyle(color: kText2),
              filled: true, fillColor: kBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: kBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: kBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: kPrimary)),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Cancelar', style: TextStyle(color: kText2))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text('Criar', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok != true || ctrl.text.trim().isEmpty) return;
    try {
      final grupoId = await firestoreService.addGrupoFamiliar(_academiaId!, {
        'nome': ctrl.text.trim(), 'academia_id': _academiaId!, 'membros': [],
      });
      await firestoreService.adicionarMembroGrupo(_academiaId!, grupoId, widget.alunoId);
      _load();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Erro ao criar grupo.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _vincularGrupoExistente() async {
    List<Map<String, dynamic>> grupos = [];
    try {
      grupos = await firestoreService.getGruposFamiliares(_academiaId!);
    } catch (_) {}
    if (!mounted) return;
    if (grupos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhum grupo cadastrado ainda.'), behavior: SnackBarBehavior.floating));
      return;
    }
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 16), decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text('Selecionar Grupo', style: TextStyle(color: kText1, fontSize: 16, fontWeight: FontWeight.w700))),
        const SizedBox(height: 8),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: grupos.length,
            itemBuilder: (_, i) {
              final g = grupos[i];
              final qtd = (g['membros'] as List? ?? []).length;
              return ListTile(
                leading: Icon(Icons.family_restroom_rounded, color: kPrimary),
                title: Text(g['nome'] as String? ?? '', style: TextStyle(color: kText1, fontWeight: FontWeight.w600)),
                subtitle: Text('$qtd membro${qtd != 1 ? 's' : ''}', style: TextStyle(color: kText2, fontSize: 12)),
                onTap: () => Navigator.of(ctx).pop(g),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ]),
    );
    if (selected == null) return;
    try {
      await firestoreService.adicionarMembroGrupo(_academiaId!, selected['id'], widget.alunoId);
      _load();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Erro ao vincular grupo.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _adicionarMembroAoGrupo() async {
    final grupo = _grupoFamiliar;
    if (grupo == null) return;
    List<Map<String, dynamic>> alunos = [];
    try {
      final membrosIds = _membrosGrupo.map((m) => m['id']?.toString() ?? '').toSet();
      final todos = await firestoreService.getAlunos(_academiaId!);
      alunos = todos.cast<Map<String, dynamic>>()
          .where((a) => !membrosIds.contains(a['id']?.toString()))
          .toList();
    } catch (_) {}
    if (!mounted) return;
    String busca = '';
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(builder: (ctx2, setS) {
        final filtrados = busca.isEmpty ? alunos : alunos.where((a) => (a['nome'] as String? ?? '').toLowerCase().contains(busca.toLowerCase())).toList();
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          builder: (_, sc) => Column(children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 16), decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2))),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text('Adicionar Membro', style: TextStyle(color: kText1, fontSize: 16, fontWeight: FontWeight.w700))),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                autofocus: true,
                style: TextStyle(color: kText1, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Buscar aluno...',
                  hintStyle: TextStyle(color: kText2),
                  filled: true, fillColor: kBg,
                  prefixIcon: Icon(Icons.search_rounded, color: kText2, size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: kBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: kBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: kPrimary)),
                ),
                onChanged: (v) => setS(() => busca = v),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtrados.isEmpty
                  ? Center(child: Text('Nenhum aluno encontrado.', style: TextStyle(color: kText2)))
                  : ListView.builder(
                      controller: sc,
                      itemCount: filtrados.length,
                      itemBuilder: (_, i) {
                        final a = filtrados[i];
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: kPrimary.withOpacity(0.15),
                            child: Text((a['nome'] as String? ?? 'A').substring(0, 1).toUpperCase(), style: TextStyle(color: kPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                          ),
                          title: Text(a['nome'] as String? ?? '', style: TextStyle(color: kText1, fontWeight: FontWeight.w500, fontSize: 14)),
                          onTap: () => Navigator.of(ctx2).pop(a),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
          ]),
        );
      }),
    );
    if (selected == null) return;
    try {
      await firestoreService.adicionarMembroGrupo(_academiaId!, grupo['id'], selected['id']);
      _load();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Erro ao adicionar membro.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _removerMembroDoGrupo(String membroId, String membroNome) async {
    final grupo = _grupoFamiliar;
    if (grupo == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Remover membro', style: TextStyle(color: kText1, fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('Remover $membroNome do grupo?', style: TextStyle(color: kText2, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Cancelar', style: TextStyle(color: kText2))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text('Remover', style: TextStyle(color: kDanger, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await firestoreService.removerMembroGrupo(_academiaId!, grupo['id'], membroId);
      _load();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Erro ao remover membro.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _sairDoGrupoFamiliar() async {
    final grupo = _grupoFamiliar;
    if (grupo == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Sair do grupo', style: TextStyle(color: kText1, fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('Remover este aluno do grupo "${grupo['nome']}"?', style: TextStyle(color: kText2, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Cancelar', style: TextStyle(color: kText2))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text('Remover', style: TextStyle(color: kDanger, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await firestoreService.removerMembroGrupo(_academiaId!, grupo['id'], widget.alunoId);
      _load();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Erro ao sair do grupo.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _definirResponsavel(String membroId, String membroNome) async {
    if (_academiaId == null || _grupoFamiliar == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Definir responsável', style: TextStyle(color: kText1, fontWeight: FontWeight.w700)),
        content: Text('Definir $membroNome como responsável financeiro do grupo?', style: TextStyle(color: kText2)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Cancelar', style: TextStyle(color: kText2))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text('Confirmar', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await firestoreService.definirResponsavelGrupo(_academiaId!, _grupoFamiliar!['id']?.toString() ?? '', membroId);
      _load();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Erro ao definir responsável.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating));
    }
  }

  Widget _buildGrupoFamiliarCard() {
    final grupo = _grupoFamiliar;
    final responsavelId = grupo?['responsavel_id']?.toString() ?? '';
    final membros = _membrosGrupo
        .where((m) => m['id']?.toString() != widget.alunoId)
        .toList();

    return _buildCard([
      Row(children: [
        Expanded(child: _sectionTitle('Grupo Familiar')),
        if (grupo != null) ...[
          GestureDetector(
            onTap: _adicionarMembroAoGrupo,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: kPrimary.withOpacity(0.3))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.person_add_rounded, size: 13, color: kPrimary),
                const SizedBox(width: 4),
                Text('Adicionar', style: TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sairDoGrupoFamiliar,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: kDanger.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: kDanger.withOpacity(0.25))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.logout_rounded, size: 13, color: kDanger),
                const SizedBox(width: 4),
                Text('Sair', style: TextStyle(color: kDanger, fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ],
      ]),
      const SizedBox(height: 8),
      if (grupo == null) ...[
        Text('Não vinculado a nenhum grupo familiar.', style: TextStyle(color: kText2, fontSize: 13)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: _criarGrupoFamiliar,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: kPrimary.withOpacity(0.3))),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.add_rounded, size: 15, color: kPrimary),
                  const SizedBox(width: 6),
                  Text('Criar grupo', style: TextStyle(color: kPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: _vincularGrupoExistente,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(8), border: Border.all(color: kBorder)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.link_rounded, size: 15, color: kText2),
                  const SizedBox(width: 6),
                  Text('Vincular existente', style: TextStyle(color: kText2, fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ),
        ]),
      ] else ...[
        Row(children: [
          Icon(Icons.family_restroom_rounded, color: kPrimary, size: 16),
          const SizedBox(width: 6),
          Text(grupo['nome'] as String? ?? '', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
        if (membros.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...membros.map((m) {
            final mId = m['id']?.toString() ?? '';
            final mNome = m['nome'] as String? ?? '';
            final isResp = responsavelId == mId;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Icon(isResp ? Icons.star_rounded : Icons.person_outline_rounded, color: isResp ? kPrimary : kText2, size: 14),
                const SizedBox(width: 6),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(mNome, style: TextStyle(color: kText1, fontSize: 12, fontWeight: isResp ? FontWeight.w700 : FontWeight.normal)),
                  if (isResp) Text('Responsável', style: TextStyle(color: kPrimary, fontSize: 10)),
                ])),
                if (!isResp)
                  GestureDetector(
                    onTap: () => _definirResponsavel(mId, mNome),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(6), border: Border.all(color: kPrimary.withOpacity(0.25))),
                      child: Text('Responsável', style: TextStyle(color: kPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  ),
                GestureDetector(
                  onTap: () => _removerMembroDoGrupo(mId, mNome),
                  child: Icon(Icons.close_rounded, size: 16, color: kDanger.withOpacity(0.7)),
                ),
              ]),
            );
          }),
        ] else ...[
          const SizedBox(height: 6),
          Text('Nenhum outro membro no grupo.', style: TextStyle(color: kText2, fontSize: 12, fontStyle: FontStyle.italic)),
        ],
      ],
    ]);
  }

  Widget _buildParQCard() {
    final p = _parq;
    final requer = p?['requerAvaliacaoMedica'] as bool? ?? false;
    final dataRaw = p?['dataPreenchimento'] as String?;
    DateTime? data;
    if (dataRaw != null) { try { data = DateTime.parse(dataRaw).toLocal(); } catch (_) {} }

    return _buildCard([
      Row(children: [
        Expanded(child: _sectionTitle('PAR-Q')),
        if (p != null) ...[
          GestureDetector(
            onTap: () => _abrirParQForm(readOnly: true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kBorder),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.visibility_rounded, size: 13, color: kText2),
                const SizedBox(width: 4),
                Text('Visualizar', style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
          const SizedBox(width: 8),
        ],
        GestureDetector(
          onTap: () => _abrirParQForm(readOnly: false),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kPrimary.withOpacity(0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(p == null ? Icons.add_rounded : Icons.edit_rounded, size: 13, color: kPrimary),
              const SizedBox(width: 4),
              Text(p == null ? 'Preencher' : 'Editar', style: TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ]),
      const SizedBox(height: 6),
      if (p == null)
        Text('PAR-Q não preenchido.', style: TextStyle(color: kText2, fontSize: 13))
      else
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: requer ? kWarning.withOpacity(0.08) : kSuccess.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: requer ? kWarning.withOpacity(0.3) : kSuccess.withOpacity(0.3)),
          ),
          child: Row(children: [
            Icon(requer ? Icons.warning_amber_rounded : Icons.check_circle_rounded, color: requer ? kWarning : kSuccess, size: 15),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(requer ? 'Avaliação médica recomendada' : 'Sem indicações de risco',
                  style: TextStyle(color: requer ? kWarning : kSuccess, fontWeight: FontWeight.w700, fontSize: 12)),
              if (data != null)
                Text('Preenchido em ${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}',
                    style: TextStyle(color: kText2, fontSize: 11)),
            ])),
          ]),
        ),
    ]);
  }

  Future<void> _abrirParQForm({bool readOnly = false}) async {
    final p = _parq;
    final respostas = List<bool>.generate(10, (i) => p?['r${i + 1}'] as bool? ?? false);
    final nomeCtrl = TextEditingController(text: p?['nomeCompleto'] as String? ?? (_aluno?['nome'] as String? ?? ''));
    final cpfCtrl = TextEditingController(text: p?['cpf'] as String? ?? '');
    bool salvando = false;

    String titulo;
    if (readOnly) {
      titulo = 'PAR-Q';
    } else if (p == null) {
      titulo = 'Preencher PAR-Q';
    } else {
      titulo = 'Editar PAR-Q';
    }

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
                  Text(titulo, style: TextStyle(color: kText1, fontSize: 18, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.of(ctx).pop(), icon: Icon(Icons.close, color: kText2)),
                ]),
                Text(_aluno?['nome'] ?? '', style: TextStyle(color: kText2, fontSize: 13)),
                const Divider(height: 20),
                if (!readOnly) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: kPrimary.withOpacity(0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: kPrimary.withOpacity(0.2))),
                    child: Text('Responda "Sim" ou "Não" a cada pergunta. Preenchimento feito pela academia em nome do aluno.',
                        style: TextStyle(color: kText2, fontSize: 12, height: 1.4)),
                  ),
                  const SizedBox(height: 16),
                ],
                Text('QUESTIONÁRIO', style: TextStyle(color: kText2, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                const SizedBox(height: 10),
                ...List.generate(_perguntas.length, (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: readOnly
                      ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(
                            width: 22, height: 22,
                            decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(5)),
                            child: Center(child: Text('${i + 1}', style: TextStyle(color: kPrimary, fontSize: 11, fontWeight: FontWeight.w800))),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_perguntas[i], style: TextStyle(color: kText1, fontSize: 12, height: 1.4))),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: respostas[i] ? kWarning.withOpacity(0.12) : kSuccess.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(respostas[i] ? 'Sim' : 'Não',
                                style: TextStyle(color: respostas[i] ? kWarning : kSuccess, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        ])
                      : Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: kBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: respostas[i] ? kWarning.withOpacity(0.4) : kBorder),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Container(
                                width: 22, height: 22,
                                decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                                child: Center(child: Text('${i + 1}', style: TextStyle(color: kPrimary, fontSize: 11, fontWeight: FontWeight.w800))),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_perguntas[i], style: TextStyle(color: kText1, fontSize: 12, height: 1.4))),
                            ]),
                            const SizedBox(height: 10),
                            Row(children: [
                              _ParQOpcao(label: 'Não', selected: !respostas[i], cor: kSuccess,
                                  onTap: () => setModal(() => respostas[i] = false)),
                              const SizedBox(width: 8),
                              _ParQOpcao(label: 'Sim', selected: respostas[i], cor: kWarning,
                                  onTap: () => setModal(() => respostas[i] = true)),
                            ]),
                          ]),
                        ),
                )),
                const Divider(height: 24),
                if (readOnly) ...[
                  _row('Nome', p?['nomeCompleto']),
                  _row('CPF', p?['cpf']),
                ] else ...[
                  Text('TERMO DE RESPONSABILIDADE', style: TextStyle(color: kText2, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
                    child: Text('Declaro que estou ciente de que é recomendável conversar com um médico, antes de iniciar ou aumentar o nível de atividade física pretendido, assumindo plena responsabilidade pela realização de qualquer atividade física sem o atendimento desta recomendação.',
                        style: TextStyle(color: kText2, fontSize: 12, height: 1.5)),
                  ),
                  const SizedBox(height: 14),
                  _ParQCampo(ctrl: nomeCtrl, label: 'Nome completo *'),
                  const SizedBox(height: 10),
                  _ParQCampo(ctrl: cpfCtrl, label: 'CPF *', keyboard: TextInputType.number),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      onPressed: salvando ? null : () async {
                        if (nomeCtrl.text.trim().isEmpty || cpfCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: const Text('Preencha nome e CPF.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating));
                          return;
                        }
                        setModal(() => salvando = true);
                        try {
                          await firestoreService.addParQ(_academiaId!, {
                            'aluno_id': widget.alunoId,
                            'academia_id': _academiaId!,
                            'r1': respostas[0], 'r2': respostas[1], 'r3': respostas[2],
                            'r4': respostas[3], 'r5': respostas[4], 'r6': respostas[5],
                            'r7': respostas[6], 'r8': respostas[7], 'r9': respostas[8],
                            'r10': respostas[9],
                            'nome_completo': nomeCtrl.text.trim(),
                            'cpf': cpfCtrl.text.trim(),
                            'requer_avaliacao_medica': respostas.any((r) => r),
                            'data_preenchimento': DateTime.now().toIso8601String(),
                          });
                          if (ctx.mounted) Navigator.of(ctx).pop();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: const Text('PAR-Q salvo com sucesso!'),
                              backgroundColor: kSuccess,
                              behavior: SnackBarBehavior.floating,
                            ));
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) _load();
                            });
                          }
                        } catch (_) {
                          if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: const Text('Erro ao salvar PAR-Q.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating));
                        } finally {
                          setModal(() => salvando = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: salvando
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(p == null ? 'Salvar PAR-Q' : 'Atualizar PAR-Q',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    nomeCtrl.dispose();
    cpfCtrl.dispose();
  }

  // ── Plano ─────────────────────────────────────────────

  Widget _buildPlanoCard(Map<String, dynamic> a) {
    final planoNome = _plano?['nome'] as String? ?? a['planoNome'] as String?;
    final valorMensal = (_plano?['valor_mensal'] as num?)?.toDouble();
    final diaVenc = a['diaVencimento'];

    if (planoNome == null && valorMensal == null && diaVenc == null) {
      return _buildCard([
        _sectionTitle('Plano'),
        Text('Nenhum plano vinculado.', style: TextStyle(color: kText2, fontSize: 13)),
      ]);
    }

    return _buildCard([
      _sectionTitle('Plano'),
      if (planoNome != null) _row('Plano', planoNome),
      if (valorMensal != null)
        _row('Valor mensal', 'R\$ ${valorMensal.toStringAsFixed(2).replaceAll('.', ',')}'),
      if (diaVenc != null) _row('Vencimento', 'Todo dia $diaVenc'),
    ]);
  }

  // ── Acesso ao App ─────────────────────────────────────

  Widget _buildAcessoAppCard(Map<String, dynamic> a) {
    final bloqueado = a['acesso_app_bloqueado'] == true;
    return _buildCard([
      _sectionTitle('Acesso ao App'),
      Row(
        children: [
          Icon(
            bloqueado ? Icons.lock_rounded : Icons.lock_open_rounded,
            color: bloqueado ? kDanger : kSuccess,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bloqueado ? 'Acesso bloqueado' : 'Acesso liberado',
                  style: TextStyle(
                    color: bloqueado ? kDanger : kSuccess,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  bloqueado
                      ? 'Aluno não consegue entrar no app.'
                      : 'Aluno pode usar o app normalmente.',
                  style: TextStyle(color: kText2, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: !bloqueado,
            activeColor: kSuccess,
            inactiveThumbColor: kDanger,
            inactiveTrackColor: kDanger.withOpacity(0.3),
            onChanged: (_) => _toggleAcessoApp(),
          ),
        ],
      ),
    ]);
  }

  // ── Atestado Médico ──────────────────────────────────

  Future<void> _visualizarAtestado() async {
    final at = _atestado;
    if (at == null) return;

    final base64Str = at['arquivoBase64'] as String?;
    final mime = at['arquivoMimeType'] as String? ?? 'application/pdf';

    String? b64 = base64Str;

    if (b64 == null || b64.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Arquivo não disponível.'), backgroundColor: kWarning, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    try {
      final bytes = base64Decode(b64);
      final ext = mime.contains('pdf') ? 'pdf' : mime.contains('png') ? 'png' : 'jpg';
      final tempFile = File('${Directory.systemTemp.path}/atestado_${widget.alunoId}.$ext');
      await tempFile.writeAsBytes(bytes, flush: true);
      final uri = Uri.file(tempFile.path);
      if (!await launchUrl(uri)) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Não foi possível abrir o arquivo.'), backgroundColor: kWarning, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Erro ao abrir o arquivo.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _avaliarAtestado(bool aprovado) async {
    if (_atestado == null) return;
    String? motivo;

    if (!aprovado) {
      final ctrl = TextEditingController();
      motivo = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: kSurface,
          title: Text('Motivo da rejeição', style: TextStyle(color: kText1, fontWeight: FontWeight.w700)),
          content: TextField(
            controller: ctrl,
            style: TextStyle(color: kText1),
            decoration: InputDecoration(
              hintText: 'Ex: atestado inválido, fora da validade...',
              hintStyle: TextStyle(color: kText2),
              filled: true,
              fillColor: kBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar', style: TextStyle(color: kText2))),
            TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: Text('Rejeitar', style: TextStyle(color: kDanger, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
      if (motivo == null || motivo.isEmpty) return;
    }

    try {
      await firestoreService.avaliarAtestado(_academiaId!, _atestado!['id']?.toString() ?? '', {'status': aprovado ? 1 : 2});
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(aprovado ? 'Atestado aprovado!' : 'Atestado rejeitado.'),
          backgroundColor: aprovado ? kSuccess : kDanger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {}
  }

  Future<void> _enviarLembrete() async {
    if (_academiaId == null) return;
    try {
      await firestoreService.addNotificacao(_academiaId!, {
        'aluno_id': widget.alunoId,
        'tipo': 'atestado_pendente',
        'titulo': 'Atestado médico pendente',
        'mensagem': 'Apresente seu atestado médico à academia para regularizar sua situação.',
        'lida': false,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Lembrete enviado ao aluno!'), backgroundColor: kSuccess, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)),
      );
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Erro ao enviar lembrete.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _uploadAtestadoAcademia() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    if (file.size > 5 * 1024 * 1024) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Arquivo muito grande. Máx 5 MB.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _uploadingAtestado = true);
    try {
      final mime = file.extension?.toLowerCase() == 'pdf' ? 'application/pdf'
          : file.extension?.toLowerCase() == 'png' ? 'image/png' : 'image/jpeg';
      await firestoreService.addAtestado(_academiaId!, {
        'aluno_id': widget.alunoId,
        'academia_id': _academiaId!,
        'arquivo_base64': base64Encode(file.bytes!),
        'arquivo_mime_type': mime,
        'arquivo_nome': file.name,
        'status': 1,
        'data_validade': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
      });
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Atestado anexado e aprovado!'), backgroundColor: kSuccess, behavior: SnackBarBehavior.floating));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Erro ao anexar atestado.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _uploadingAtestado = false);
    }
  }

  Widget _buildAtestadoCard() {
    final at = _atestado;
    final status = at?['status'] as int?;

    final (label, color) = at == null
        ? ('Sem atestado', kDanger)
        : switch (status) {
            0 => ('Aguardando aprovação', kWarning),
            1 => ('Aprovado', kSuccess),
            2 => ('Rejeitado', kDanger),
            3 => ('Expirado', kDanger),
            _ => ('Desconhecido', kText2),
          };

    final dataValidade = at != null ? DateTime.tryParse(at['dataValidade']?.toString() ?? '') : null;
    final fmt = dataValidade != null
        ? '${dataValidade.day.toString().padLeft(2,'0')}/${dataValidade.month.toString().padLeft(2,'0')}/${dataValidade.year}'
        : null;

    return _buildCard([
      Row(children: [
        Expanded(child: _sectionTitle('Atestado Médico')),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.4))),
          child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
      ]),
      if (fmt != null) _row('Validade', fmt),
      if (at?['motivoRejeicao'] != null) _row('Motivo', at!['motivoRejeicao']),
      const SizedBox(height: 10),
      if (at != null) ...[
        OutlinedButton.icon(
          onPressed: _visualizarAtestado,
          icon: const Icon(Icons.visibility_rounded, size: 16),
          label: const Text('Ver Atestado'),
          style: OutlinedButton.styleFrom(
            foregroundColor: kPrimary,
            side: BorderSide(color: kPrimary.withOpacity(0.4)),
            minimumSize: const Size(double.infinity, 40),
          ),
        ),
        const SizedBox(height: 8),
      ],
      if (status == 0) ...[
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: () => _avaliarAtestado(true),
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Aprovar'),
            style: OutlinedButton.styleFrom(foregroundColor: kSuccess, side: BorderSide(color: kSuccess.withOpacity(0.5))),
          )),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton.icon(
            onPressed: () => _avaliarAtestado(false),
            icon: const Icon(Icons.close_rounded, size: 16),
            label: const Text('Rejeitar'),
            style: OutlinedButton.styleFrom(foregroundColor: kDanger, side: BorderSide(color: kDanger.withOpacity(0.5))),
          )),
        ]),
      ],
      if (at == null) ...[
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: _uploadingAtestado ? null : _uploadAtestadoAcademia,
            icon: _uploadingAtestado
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.upload_file_rounded, size: 16),
            label: const Text('Anexar'),
            style: OutlinedButton.styleFrom(foregroundColor: kPrimary, side: BorderSide(color: kPrimary.withOpacity(0.4))),
          )),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton.icon(
            onPressed: _enviarLembrete,
            icon: const Icon(Icons.notifications_outlined, size: 16),
            label: const Text('Lembrar'),
            style: OutlinedButton.styleFrom(foregroundColor: kText2, side: BorderSide(color: kBorder)),
          )),
        ]),
      ],
    ]);
  }

  // ── Helpers ──────────────────────────────────────────

  int _maxGrausFaixa(String? nomeFaixa) {
    final nome = (nomeFaixa ?? '').toLowerCase().trim();
    if (nome.contains('vermelha')) return 9;
    if (nome.contains('coral')) return 8;
    if (nome.contains('preta')) return 6;
    return 4;
  }

  // ── Graduar ──────────────────────────────────────────

  Future<void> _abrirGraduar() async {
    List<Map<String, dynamic>> faixas = [];
    Map<String, String> modIdToNome = {};
    try {
      final results = await Future.wait([
        firestoreService.getFaixas(_academiaId!),
        firestoreService.getModalidades(_academiaId!),
      ]);
      final rawFaixas = results[0];
      final rawMods = results[1];
      for (final m in rawMods) {
        final id = m['id']?.toString() ?? '';
        if (id.isNotEmpty) modIdToNome[id] = m['nome']?.toString() ?? '';
      }
      faixas = rawFaixas.map((f) => <String, dynamic>{
        ...f,
        'temGraus': f['tem_graus'] == true,
        'maxGraus': (f['max_graus'] as num?)?.toInt() ?? 4,
      }).toList();
    } catch (_) {}
    if (!mounted) return;

    final turmasDetalhes = (_aluno?['turmasDetalhes'] as List? ?? []).cast<Map<String, dynamic>>();
    final modalidadesAluno = <String>{
      for (final t in turmasDetalhes)
        if ((t['modalidadeId'] as String?)?.isNotEmpty == true)
          t['modalidadeId'].toString(),
    };

    final Map<String, Map<String, dynamic>> modMap = {};
    for (final f in faixas) {
      final modId = f['modalidadeId']?.toString() ?? '';
      if (modalidadesAluno.isNotEmpty && !modalidadesAluno.contains(modId)) continue;
      modMap.putIfAbsent(modId, () => {
        'id': modId,
        'nome': modIdToNome[modId] ?? 'Sem modalidade',
        'faixas': <Map<String, dynamic>>[],
      });
      (modMap[modId]!['faixas'] as List<Map<String, dynamic>>).add(f);
    }
    if (modMap.isEmpty) {
      for (final f in faixas) {
        final modId = f['modalidadeId']?.toString() ?? '';
        modMap.putIfAbsent(modId, () => {
          'id': modId,
          'nome': modIdToNome[modId] ?? 'Sem modalidade',
          'faixas': <Map<String, dynamic>>[],
        });
        (modMap[modId]!['faixas'] as List<Map<String, dynamic>>).add(f);
      }
    }

    final mods = modMap.values.toList();
    for (final m in mods) {
      (m['faixas'] as List<Map<String, dynamic>>)
          .sort((a, b) => (a['ordem'] as int? ?? 0).compareTo(b['ordem'] as int? ?? 0));
    }

    // step -1: choose type (dar grau / nova faixa)
    // step 0: select modality (skip if only 1)
    // step 1: select belt (skip for "dar grau")
    // step 2: confirm degree / details
    String? tipoGraduacao; // 'darGrau' or 'novaFaixa'
    int step = -1;
    Map<String, dynamic>? modSel = mods.length <= 1 && mods.isNotEmpty ? mods.first : null;
    Map<String, dynamic>? faixaSel;
    int grauSel = 0;
    int currentGrauForDarGrau = 0; // grau que o aluno já tem (chips ≤ esse ficam desabilitados)
    final obsCtrl = TextEditingController();
    bool gerarCobranca = false;
    final valorCtrl = TextEditingController();
    bool salvando = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          // for progress indicator: step -1 maps to 0, 0 → 1, 1 → 2, 2 → 3
          final totalSteps = tipoGraduacao == 'darGrau' ? 2 : (mods.length <= 1 ? 3 : 4);
          final activeStep = step + 1;
          final canGoBack = step >= 0;

          Widget stepContent;
          if (step == -1) {
            // Choose graduation type
            final temFaixaAtual = _faixasPorModalidade.isNotEmpty;
            stepContent = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('O que deseja fazer?', style: TextStyle(color: kText2, fontSize: 13)),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: temFaixaAtual ? () {
                    setModal(() {
                      tipoGraduacao = 'darGrau';
                      // Auto-select modality if only 1 modality
                      if (_faixasPorModalidade.length == 1) {
                        final modNome = _faixasPorModalidade.keys.first;
                        final faixaAtual = _faixasPorModalidade[modNome]!;
                        // Match from loaded faixas list
                        faixaSel = faixas.firstWhere(
                          (f) => f['id']?.toString() == faixaAtual['id']?.toString(),
                          orElse: () => faixaAtual,
                        );
                        // Ensure temGraus and maxGraus come from current belt data
                        final currentGrau = (faixaAtual['grau'] as num?)?.toInt() ?? 0;
                        if (faixaAtual['temGraus'] == true || currentGrau > 0) {
                          final apiMax = (faixaAtual['maxGraus'] as num?)?.toInt() ?? 0;
                          final nameMax = _maxGrausFaixa(faixaAtual['nome']?.toString());
                          final effectiveMax = apiMax > 0 ? apiMax : nameMax;
                          faixaSel = Map<String, dynamic>.from(faixaSel!)
                            ..['temGraus'] = true
                            ..['maxGraus'] = effectiveMax.clamp(1, 99);
                        }
                        final apiMaxG = (faixaAtual['maxGraus'] as num?)?.toInt() ?? 0;
                        final maxG = (apiMaxG > 0 ? apiMaxG : _maxGrausFaixa(faixaAtual['nome']?.toString())).clamp(1, 99);
                        currentGrauForDarGrau = currentGrau;
                        grauSel = (currentGrau + 1).clamp(1, maxG);
                        modSel = mods.isNotEmpty ? mods.first : null;
                      }
                      step = mods.length <= 1 ? 2 : 0;
                    });
                  } : null,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: temFaixaAtual ? kBg : kBorder.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: temFaixaAtual ? kPrimary.withOpacity(0.4) : kBorder),
                    ),
                    child: Row(children: [
                      Container(width: 40, height: 40, decoration: BoxDecoration(color: kPrimary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.grade_rounded, color: temFaixaAtual ? kPrimary : kText2, size: 22)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Dar Grau', style: TextStyle(color: temFaixaAtual ? kText1 : kText2, fontSize: 15, fontWeight: FontWeight.w700)),
                        Text('Incrementar grau na mesma faixa atual', style: TextStyle(color: kText2, fontSize: 11)),
                      ])),
                      Icon(Icons.chevron_right_rounded, color: temFaixaAtual ? kText2 : kBorder),
                    ]),
                  ),
                ),
                GestureDetector(
                  onTap: () => setModal(() {
                    tipoGraduacao = 'novaFaixa';
                    faixaSel = null;
                    step = mods.length <= 1 ? 1 : 0;
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kWarning.withOpacity(0.4))),
                    child: Row(children: [
                      Container(width: 40, height: 40, decoration: BoxDecoration(color: kWarning.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.military_tech_rounded, color: kWarning, size: 22)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Nova Faixa', style: TextStyle(color: kText1, fontSize: 15, fontWeight: FontWeight.w700)),
                        Text('Selecionar uma faixa diferente', style: TextStyle(color: kText2, fontSize: 11)),
                      ])),
                      Icon(Icons.chevron_right_rounded, color: kText2),
                    ]),
                  ),
                ),
              ],
            );
          } else if (step == 0) {
            stepContent = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selecione a modalidade', style: TextStyle(color: kText2, fontSize: 13)),
                const SizedBox(height: 14),
                ...mods.map((m) => GestureDetector(
                  onTap: () => setModal(() {
                    modSel = m;
                    step = tipoGraduacao == 'darGrau' ? 2 : 1;
                    if (tipoGraduacao == 'darGrau') {
                      final modNome = m['nome']?.toString() ?? '';
                      final faixaAtual = _faixasPorModalidade[modNome];
                      if (faixaAtual != null) {
                        faixaSel = faixas.firstWhere(
                          (f) => f['id']?.toString() == faixaAtual['id']?.toString(),
                          orElse: () => faixaAtual,
                        );
                        final currentGrau2 = (faixaAtual['grau'] as num?)?.toInt() ?? 0;
                        if (faixaAtual['temGraus'] == true || currentGrau2 > 0) {
                          final apiMax2 = (faixaAtual['maxGraus'] as num?)?.toInt() ?? 0;
                          final nameMax2 = _maxGrausFaixa(faixaAtual['nome']?.toString());
                          final eff2 = apiMax2 > 0 ? apiMax2 : nameMax2;
                          faixaSel = Map<String, dynamic>.from(faixaSel!)
                            ..['temGraus'] = true
                            ..['maxGraus'] = eff2.clamp(1, 99);
                        }
                        final apiMaxG2 = (faixaAtual['maxGraus'] as num?)?.toInt() ?? 0;
                        final maxG2 = (apiMaxG2 > 0 ? apiMaxG2 : _maxGrausFaixa(faixaAtual['nome']?.toString())).clamp(1, 99);
                        currentGrauForDarGrau = currentGrau2;
                        grauSel = (currentGrau2 + 1).clamp(1, maxG2);
                      }
                    }
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
                    child: Row(children: [
                      Icon(Icons.sports_martial_arts_rounded, color: kPrimary, size: 22),
                      const SizedBox(width: 12),
                      Expanded(child: Text(m['nome']?.toString() ?? '', style: TextStyle(color: kText1, fontSize: 15, fontWeight: FontWeight.w700))),
                      Icon(Icons.chevron_right_rounded, color: kText2),
                    ]),
                  ),
                )),
              ],
            );
          } else if (step == 1) {
            final faixasMod = (modSel?['faixas'] as List? ?? []).cast<Map<String, dynamic>>();
            stepContent = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selecione a faixa — ${modSel?['nome'] ?? ''}', style: TextStyle(color: kText2, fontSize: 13)),
                const SizedBox(height: 14),
                if (faixasMod.isEmpty)
                  Text('Nenhuma faixa disponível.', style: TextStyle(color: kText2))
                else
                  ...faixasMod.map((f) {
                    final cor = _parseCor(f['cor']?.toString());
                    final sel = faixaSel?['id'] == f['id'];
                    return GestureDetector(
                      onTap: () => setModal(() => faixaSel = f),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: sel ? kPrimary.withOpacity(0.15) : kBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: sel ? kPrimary : kBorder),
                        ),
                        child: Row(children: [
                          Container(width: 14, height: 14, decoration: BoxDecoration(shape: BoxShape.circle, color: cor)),
                          const SizedBox(width: 10),
                          Expanded(child: Text(f['nome'] ?? '', style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w600))),
                          if (sel) Icon(Icons.check_circle_rounded, color: kPrimary, size: 18),
                        ]),
                      ),
                    );
                  }),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton(
                    onPressed: faixaSel == null ? null : () => setModal(() => step = 2),
                    style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Próximo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            );
          } else {
            stepContent = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: kPrimary.withOpacity(0.3))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: _parseCor(faixaSel?['cor']?.toString()))),
                    const SizedBox(width: 8),
                    Text('${modSel?['nome']} · ${faixaSel?['nome'] ?? ''}', style: TextStyle(color: kPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                  ]),
                ),
                if (faixaSel != null && (faixaSel!['temGraus'] == true || tipoGraduacao == 'darGrau')) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(Icons.grade_rounded, size: 14, color: kText2),
                        const SizedBox(width: 6),
                        Text('Grau', style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text(grauSel == 0 ? 'Sem grau' : '${grauSel}° Grau', style: TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                      ]),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: List.generate(((faixaSel!['maxGraus'] as num? ?? 4).toInt().clamp(1, 99)) + 1, (i) {
                          final sel = grauSel == i;
                          // Para "darGrau": desabilita "–" e qualquer grau já conquistado
                          final isDisabled = tipoGraduacao == 'darGrau' && (i == 0 || i <= currentGrauForDarGrau);
                          return GestureDetector(
                            onTap: isDisabled ? null : () => setModal(() => grauSel = i),
                            child: Container(
                              width: 44, height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: sel ? kPrimary : isDisabled ? kBorder.withOpacity(0.25) : kSurface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: sel ? kPrimary : isDisabled ? kBorder.withOpacity(0.4) : kBorder),
                              ),
                              child: Text(i == 0 ? '—' : '$i°', style: TextStyle(
                                color: sel ? Colors.white : isDisabled ? kText2.withOpacity(0.4) : kText1,
                                fontSize: 13, fontWeight: FontWeight.w700,
                                decoration: isDisabled && i > 0 ? TextDecoration.lineThrough : null,
                              )),
                            ),
                          );
                        }),
                      ),
                    ]),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: obsCtrl,
                  style: TextStyle(color: kText1),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Observação (opcional)',
                    hintStyle: TextStyle(color: kText2),
                    filled: true, fillColor: kBg,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kPrimary)),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder)),
                  child: Row(children: [
                    Expanded(child: Text('Gerar cobrança financeira', style: TextStyle(color: kText1, fontSize: 13))),
                    Switch(value: gerarCobranca, activeColor: kPrimary, onChanged: (v) => setModal(() => gerarCobranca = v)),
                  ]),
                ),
                if (gerarCobranca) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: valorCtrl,
                    style: TextStyle(color: kText1),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                    decoration: InputDecoration(
                      hintText: 'Valor da cobrança (R\$)',
                      hintStyle: TextStyle(color: kText2),
                      prefixText: 'R\$ ',
                      prefixStyle: TextStyle(color: kText2),
                      filled: true, fillColor: kBg,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kPrimary)),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: salvando ? null : () async {
                      setModal(() => salvando = true);
                      try {
                        final hoje = DateTime.now();
                        final dataExame = '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';
                        final temGraus = faixaSel!['temGraus'] == true;
                        final grauFinal = (tipoGraduacao == 'darGrau' || temGraus) ? grauSel : 0;
                        await firestoreService.addGraduacao(_academiaId!, {
                          'aluno_id': widget.alunoId,
                          'faixa_id': faixaSel!['id'],
                          'data_exame': dataExame,
                          'professor_id': _meId,
                          'aprovado': true,
                          'grau': grauFinal,
                          'observacoes': obsCtrl.text.trim(),
                          'academia_id': _academiaId!,
                        });
                        // Atualiza faixasAtuais no doc do aluno (mapa por modalidade, usado nas listas)
                        final modId = modSel?['id']?.toString() ?? '';
                        final modNome = modSel?['nome']?.toString() ?? '';
                        if (modId.isNotEmpty) {
                          final jaTemPrincipal = (_aluno?['faixaPrincipalModalidadeId'] as String?)?.isNotEmpty == true;
                          final updateData = <String, dynamic>{
                            'faixasAtuais.$modId': {
                              'modalidadeId': modId,
                              'modalidadeNome': modNome,
                              'faixaNome': faixaSel!['nome'],
                              'faixaCor': faixaSel!['cor'],
                              'faixaCorBarra': faixaSel!['corBarra'] ?? faixaSel!['cor_barra'],
                              'faixaTemGraus': faixaSel!['temGraus'] == true,
                              'faixaMaxGraus': (faixaSel!['maxGraus'] as num?)?.toInt() ?? 4,
                              'grau': grauFinal,
                            },
                            if (!jaTemPrincipal) 'faixaPrincipalModalidadeId': modId,
                          };
                          await firestoreService.updateAluno(_academiaId!, widget.alunoId, updateData);
                        }
                        if (gerarCobranca && valorCtrl.text.isNotEmpty) {
                          final valor = double.tryParse(valorCtrl.text.replaceAll(',', '.')) ?? 0;
                          if (valor > 0) {
                            final hj = DateTime.now();
                            final venc = '${hj.year}-${hj.month.toString().padLeft(2, '0')}-${hj.day.toString().padLeft(2, '0')}';
                            await firestoreService.addPagamento(_academiaId!, {
                              'aluno_id': widget.alunoId,
                              'tipo': 5,
                              'status': 2,
                              'valor': valor,
                              'descricao': 'Graduação - ${faixaSel!['nome']}',
                              'data_vencimento': venc,
                              'academia_id': _academiaId!,
                            });
                          }
                        }
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${_aluno?['nome']} graduado para ${faixaSel!['nome']}!'), backgroundColor: kSuccess, behavior: SnackBarBehavior.floating),
                          );
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) _load();
                          });
                        }
                      } catch (e) {
                        String msg = 'Erro ao graduar.';
                        try { msg = ((e as dynamic).response?.data as Map?)?['mensagem'] ?? msg; } catch (_) {}
                        if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(msg), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
                        );
                      } finally {
                        setModal(() => salvando = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: salvando
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Confirmar Graduação', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            );
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (canGoBack)
                        GestureDetector(
                          onTap: () => setModal(() {
                            if (tipoGraduacao == 'darGrau' && step == 2) {
                              // "darGrau" skips step 1 (faixa selection), so back goes to modality or type select
                              step = mods.length <= 1 ? -1 : 0;
                              if (step == -1) { tipoGraduacao = null; modSel = mods.length <= 1 && mods.isNotEmpty ? mods.first : null; faixaSel = null; grauSel = 0; }
                              else { modSel = null; faixaSel = null; grauSel = 0; }
                            } else {
                              step--;
                              if (step == -1) { tipoGraduacao = null; modSel = mods.length <= 1 && mods.isNotEmpty ? mods.first : null; faixaSel = null; grauSel = 0; }
                              else if (step == 0) { modSel = null; faixaSel = null; }
                              else if (step == 1) faixaSel = null;
                            }
                          }),
                          child: const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF94A3B8), size: 18),
                          ),
                        ),
                      Text(
                        step == -1 ? 'Graduar Aluno' : tipoGraduacao == 'darGrau' ? 'Dar Grau' : 'Nova Faixa',
                        style: TextStyle(color: kText1, fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(totalSteps, (i) => Container(
                          margin: const EdgeInsets.only(left: 4),
                          width: i == activeStep ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == activeStep ? kPrimary : kBorder,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        )),
                      ),
                      const SizedBox(width: 4),
                      IconButton(onPressed: () => Navigator.of(ctx).pop(), icon: Icon(Icons.close, color: kText2)),
                    ],
                  ),
                  Text(_aluno?['nome'] ?? '', style: TextStyle(color: kText2, fontSize: 13)),
                  const Divider(height: 20),
                  stepContent,
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Vincular Turma ───────────────────────────────────

  Future<void> _abrirVincularTurma() async {
    List<Map<String, dynamic>> turmas = [];
    try {
      final raw = await firestoreService.getTurmas(_academiaId!);
      turmas = raw.map((t) => <String, dynamic>{
        ...t,
        'modalidadeNome': t['modalidade_nome'],
      }).toList();
    } catch (_) {}

    if (!mounted) return;

    Map<String, dynamic>? turmaSel;
    bool salvando = false;

    // Turmas já vinculadas
    final turmasAtuais = (_aluno?['turmas'] as List? ?? []).map((t) => t.toString()).toSet();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    Text('Vincular a uma Turma', style: TextStyle(color: kText1, fontSize: 18, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.of(ctx).pop(), icon: Icon(Icons.close, color: kText2)),
                  ],
                ),
              ),
              Flexible(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shrinkWrap: true,
                  itemCount: turmas.length,
                  itemBuilder: (_, i) {
                    final t = turmas[i];
                    final nomeT = t['nome']?.toString() ?? '';
                    final jaVinculado = turmasAtuais.contains(nomeT);
                    final sel = turmaSel?['id'] == t['id'];
                    return GestureDetector(
                      onTap: jaVinculado ? null : () => setModal(() => turmaSel = t),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: jaVinculado ? kBorder.withOpacity(0.3) : sel ? kPrimary.withOpacity(0.15) : kBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: sel ? kPrimary : kBorder),
                        ),
                        child: Row(children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(nomeT, style: TextStyle(color: jaVinculado ? kText2 : kText1, fontSize: 13, fontWeight: FontWeight.w600)),
                                if (t['modalidadeNome'] != null)
                                  Text(t['modalidadeNome'], style: TextStyle(color: kText2, fontSize: 11)),
                              ],
                            ),
                          ),
                          if (jaVinculado)
                            Text('Já vinculado', style: TextStyle(color: kText2, fontSize: 11))
                          else if (sel)
                            Icon(Icons.check_circle_rounded, color: kPrimary, size: 18),
                        ]),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (salvando || turmaSel == null) ? null : () async {
                      setModal(() => salvando = true);
                      try {
                        await firestoreService.addMatricula(_academiaId!, {
                          'aluno_id': widget.alunoId,
                          'turma_id': turmaSel!['id'],
                          'academia_id': _academiaId!,
                          'ativo': true,
                        });
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Vinculado à ${turmaSel!['nome']}!'), backgroundColor: kSuccess, behavior: SnackBarBehavior.floating),
                          );
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) _load();
                          });
                        }
                      } catch (e) {
                        String msg = 'Erro ao vincular.';
                        try { msg = ((e as dynamic).response?.data as Map?)?['mensagem'] ?? msg; } catch (_) {}
                        if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(msg), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
                        );
                      } finally {
                        setModal(() => salvando = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: salvando
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Vincular', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseCor(String? hex) {
    try { return Color(int.parse((hex ?? '').replaceAll('#', '0xFF'))); } catch (_) { return kPrimary; }
  }

  Color _finCor(String? s) {
    if (s == 'Inadimplente') return kDanger;
    if (s == 'Pendente') return kWarning;
    return kSuccess;
  }

  String _formatFin(String? s) {
    if (s == 'EmDia') return 'Em Dia';
    return s ?? '';
  }

  // ── Editar Aluno ─────────────────────────────────────

  String? _isoToDdMmAaaa(dynamic raw) {
    if (raw == null) return null;
    try {
      final dt = DateTime.parse(raw.toString());
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) { return null; }
  }

  String _toIsoDate(String ddmmaaaa) {
    final parts = ddmmaaaa.split('/');
    if (parts.length != 3) return ddmmaaaa;
    return '${parts[2]}-${parts[1]}-${parts[0]}';
  }

  Widget _editSection(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Text(label, style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
  );

  Widget _editField(TextEditingController ctrl, String hint, {TextInputType? keyboard, List<TextInputFormatter>? formatters}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: ctrl,
      keyboardType: keyboard,
      inputFormatters: formatters,
      style: TextStyle(color: kText1),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: kText2, fontSize: 14),
        filled: true, fillColor: kBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPrimary)),
      ),
    ),
  );

  Future<void> _editarAluno() async {
    final a = _aluno;
    if (a == null) return;

    List<Map<String, dynamic>> planos = [];
    try {
      planos = await firestoreService.getPlanos(_academiaId!);
    } catch (_) {}
    if (!mounted) return;

    final nomeCtrl = TextEditingController(text: a['nome']?.toString() ?? '');
    final emailCtrl = TextEditingController(text: a['email']?.toString() ?? '');
    final telefoneCtrl = TextEditingController(text: a['telefone']?.toString() ?? '');
    final nascCtrl = TextEditingController(text: _isoToDdMmAaaa(a['dataNascimento']) ?? '');
    final emergNomeCtrl = TextEditingController(text: a['contatoEmergenciaNome']?.toString() ?? '');
    final emergTelCtrl = TextEditingController(text: a['contatoEmergenciaTelefone']?.toString() ?? '');
    final diaVencCtrl = TextEditingController(text: a['diaVencimento']?.toString() ?? '');
    String? planoIdSel = a['planoId']?.toString();
    bool salvando = false;
    String? erro;

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
                  Text('Editar Aluno', style: TextStyle(color: kText1, fontSize: 18, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.of(ctx).pop(), icon: Icon(Icons.close, color: kText2)),
                ]),
                Text(a['nome']?.toString() ?? '', style: TextStyle(color: kText2, fontSize: 13)),
                const Divider(height: 20),
                _editSection('Dados pessoais'),
                _editField(nomeCtrl, 'Nome completo *'),
                _editField(emailCtrl, 'E-mail', keyboard: TextInputType.emailAddress),
                _editField(telefoneCtrl, 'Telefone', keyboard: TextInputType.phone, formatters: [_PhoneMaskFormatter()]),
                _editField(nascCtrl, 'Data de nascimento (DD/MM/AAAA)', keyboard: TextInputType.number, formatters: [_DateMaskFormatter()]),
                _editSection('Contato de emergência'),
                _editField(emergNomeCtrl, 'Nome do contato'),
                _editField(emergTelCtrl, 'Telefone do contato', keyboard: TextInputType.phone, formatters: [_PhoneMaskFormatter()]),
                _editSection('Plano financeiro'),
                if (planos.isNotEmpty) ...[
                  GestureDetector(
                    onTap: () async {
                      final sel = await showDialog<String>(
                        context: context,
                        builder: (dCtx) => SimpleDialog(
                          backgroundColor: kSurface,
                          title: Text('Selecionar Plano', style: TextStyle(color: kText1, fontWeight: FontWeight.w700, fontSize: 16)),
                          children: [
                            SimpleDialogOption(
                              onPressed: () => Navigator.of(dCtx).pop('__none__'),
                              child: Text('Sem plano', style: TextStyle(color: kText2, fontSize: 14)),
                            ),
                            const Divider(height: 1),
                            ...planos.map((p) => SimpleDialogOption(
                              onPressed: () => Navigator.of(dCtx).pop(p['id']?.toString() ?? '__none__'),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                                Text(p['nome']?.toString() ?? '', style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w600)),
                                if (p['valor_mensal'] != null)
                                  Text('R\$ ${(p['valor_mensal'] as num).toDouble().toStringAsFixed(2).replaceAll('.', ',')} / mês',
                                      style: TextStyle(color: kText2, fontSize: 12)),
                              ]),
                            )),
                          ],
                        ),
                      );
                      if (sel != null) setModal(() => planoIdSel = sel == '__none__' ? null : sel);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
                      child: Row(children: [
                        Expanded(
                          child: Text(
                            planoIdSel == null
                                ? 'Selecionar plano'
                                : planos.where((p) => p['id']?.toString() == planoIdSel).map((p) => p['nome']?.toString() ?? '').firstOrNull ?? 'Selecionar plano',
                            style: TextStyle(color: planoIdSel == null ? kText2 : kText1, fontSize: 14),
                          ),
                        ),
                        Icon(Icons.expand_more_rounded, color: kText2, size: 20),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                _editField(diaVencCtrl, 'Dia de vencimento (1-31)', keyboard: TextInputType.number),
                if (erro != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: kDanger.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                    child: Text(erro!, style: TextStyle(color: kDanger, fontSize: 13)),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: salvando ? null : () async {
                      if (nomeCtrl.text.trim().isEmpty) {
                        setModal(() => erro = 'Nome é obrigatório.');
                        return;
                      }
                      setModal(() { salvando = true; erro = null; });
                      try {
                        final nascText = nascCtrl.text.trim();
                        await firestoreService.updateAluno(_academiaId!, widget.alunoId, {
                          'nome': nomeCtrl.text.trim(),
                          'email': emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                          'telefone': telefoneCtrl.text.trim(),
                          if (nascText.length == 10) 'data_nascimento': _toIsoDate(nascText),
                          if (emergNomeCtrl.text.trim().isNotEmpty) 'contato_emergencia_nome': emergNomeCtrl.text.trim(),
                          if (emergTelCtrl.text.trim().isNotEmpty) 'contato_emergencia_telefone': emergTelCtrl.text.trim(),
                          'plano_id': planoIdSel,
                          if (diaVencCtrl.text.trim().isNotEmpty) 'dia_vencimento': int.tryParse(diaVencCtrl.text.trim()),
                          'ativo': a['ativo'] == true,
                        });
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: const Text('Aluno atualizado com sucesso!'),
                            backgroundColor: kSuccess,
                            behavior: SnackBarBehavior.floating,
                          ));
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) _load();
                          });
                        }
                      } catch (e) {
                        String msg = 'Erro ao atualizar aluno.';
                        try { msg = ((e as dynamic).response?.data as Map?)?['mensagem'] ?? msg; } catch (_) {}
                        setModal(() { salvando = false; erro = msg; });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: salvando
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Salvar alterações', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    nomeCtrl.dispose();
    emailCtrl.dispose();
    telefoneCtrl.dispose();
    nascCtrl.dispose();
    emergNomeCtrl.dispose();
    emergTelCtrl.dispose();
    diaVencCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = _aluno;
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kSurface,
        foregroundColor: kText1,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: kText1, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(a?['nome'] ?? 'Aluno', style: TextStyle(color: kText1, fontWeight: FontWeight.w700)),
        actions: [
          if (a != null) ...[
            IconButton(
              onPressed: _editarAluno,
              icon: Icon(Icons.edit_rounded, color: kPrimary, size: 20),
              tooltip: 'Editar',
            ),
            TextButton(
              onPressed: _toggleAtivo,
              child: Text(
                a['ativo'] == true ? 'Desativar' : 'Ativar',
                style: TextStyle(color: a['ativo'] == true ? kDanger : kSuccess, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: kPrimary))
          : _erro != null
              ? Center(child: Text(_erro!, style: TextStyle(color: kDanger)))
              : a == null
                  ? Center(child: Text('Aluno não encontrado.', style: TextStyle(color: kText2)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildCard([
                            _buildAvatar(a),
                            const SizedBox(height: 12),
                            _row('Nome', a['nome']),
                            _row('Email', a['email']),
                            _rowWhatsApp('Telefone', a['telefone'], a['nome']?.toString() ?? ''),
                            _row('Nascimento', _formatDate(a['dataNascimento'])),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _statusBadge(a['ativo'] == true),
                                if (a['situacaoFinanceira'] != null)
                                  Text(_formatFin(a['situacaoFinanceira'] as String?),
                                      style: TextStyle(color: _finCor(a['situacaoFinanceira'] as String?), fontSize: 13, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ]),
                          const SizedBox(height: 12),
                          // Graduação com botão
                          _buildCard([
                            Row(
                              children: [
                                Expanded(child: _sectionTitle('Graduação')),
                                TextButton.icon(
                                  onPressed: _abrirGraduar,
                                  icon: Icon(Icons.military_tech_rounded, size: 16, color: kPrimary),
                                  label: Text('Graduar', style: TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ),
                            if (_faixasPorModalidade.isEmpty)
                              _row('Faixa atual', a['faixaAtualNome'])
                            else
                              ..._faixasPorModalidade.entries.map((e) {
                                final eGrau = (e.value['grau'] as num?)?.toInt() ?? 0;
                                final eMaxGraus = (e.value['maxGraus'] as num?)?.toInt() ?? 4;
                                final eEffectiveMax = eMaxGraus > 0 ? eMaxGraus : (eGrau > 0 ? eGrau : 4);
                                return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(e.key, style: TextStyle(color: kText2, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        BeltBadge(
                                          cor: _parseCor(e.value['cor']?.toString()),
                                          corBarra: _parseCor(e.value['corBarra']?.toString() ?? '#000000'),
                                          temGraus: e.value['temGraus'] == true || eGrau > 0,
                                          grau: eGrau,
                                          maxGraus: eEffectiveMax,
                                          height: 14,
                                          minWidth: 32,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          eGrau > 0
                                              ? '${e.value['nome']} · $eGrau° Grau'
                                              : e.value['nome']?.toString() ?? '-',
                                          style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                              }),
                            _row('Nível / XP', a['nivel'] != null ? '${a['nivel']} · ${a['xpTotal'] ?? 0} XP' : null),
                          ]),
                          const SizedBox(height: 12),
                          _buildPlanoCard(a),
                          const SizedBox(height: 12),
                          _buildAcessoAppCard(a),
                          const SizedBox(height: 12),
                          _buildAtestadoCard(),
                          const SizedBox(height: 12),
                          _buildGrupoFamiliarCard(),
                          const SizedBox(height: 12),
                          _buildParQCard(),
                          // Turmas com botão vincular
                          const SizedBox(height: 12),
                          // Histórico de graduações
                          _buildCard([
                            _sectionTitle('Histórico de Graduações'),
                            if (_graduacoes.isEmpty)
                              Text('Nenhuma graduação registrada.',
                                  style: TextStyle(color: kText2, fontSize: 13))
                            else
                              Builder(builder: (_) {
                                final mods = _graduacoes
                                    .map((g) => g['nomeModalidade']?.toString() ?? '')
                                    .where((m) => m.isNotEmpty)
                                    .toSet()
                                    .toList()
                                  ..sort();
                                final multiMod = mods.length > 1;
                                final selected = multiMod
                                    ? (mods.contains(_histModFiltro) ? _histModFiltro! : mods.first)
                                    : null;
                                final filtered = selected == null
                                    ? _graduacoes
                                    : _graduacoes.where((g) => g['nomeModalidade']?.toString() == selected).toList();
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    if (multiMod)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: DropdownButtonFormField<String>(
                                          value: selected,
                                          onChanged: (v) { if (v != null) setState(() => _histModFiltro = v); },
                                          dropdownColor: kSurface,
                                          style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w600),
                                          decoration: InputDecoration(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                            filled: true,
                                            fillColor: kBg,
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kPrimary)),
                                          ),
                                          icon: Icon(Icons.keyboard_arrow_down_rounded, color: kText2),
                                          items: mods.map((m) => DropdownMenuItem<String>(
                                            value: m,
                                            child: Text(m, overflow: TextOverflow.ellipsis, style: TextStyle(color: kText1, fontSize: 13)),
                                          )).toList(),
                                        ),
                                      ),
                                    ...filtered.map((g) => _buildGraduacaoItem(g)),
                                  ],
                                );
                              }),
                          ]),
                          const SizedBox(height: 12),
                          _buildCard([
                            Row(
                              children: [
                                Expanded(child: _sectionTitle('Turmas')),
                                TextButton.icon(
                                  onPressed: _abrirVincularTurma,
                                  icon: Icon(Icons.add_circle_outline_rounded, size: 16, color: kPrimary),
                                  label: Text('Vincular', style: TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ),
                            if ((a['turmas'] as List?)?.isEmpty != false)
                              Text('Nenhuma turma vinculada.', style: TextStyle(color: kText2, fontSize: 13))
                            else
                              ...(a['turmas'] as List).map((t) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.circle, color: kPrimary, size: 6),
                                    const SizedBox(width: 8),
                                    Text(t.toString(), style: TextStyle(color: kText1, fontSize: 13)),
                                  ],
                                ),
                              )),
                          ]),
                                          const SizedBox(height: 12),
                          _buildCard([
                            Row(
                              children: [
                                Expanded(child: _sectionTitle('Rankings')),
                                TextButton.icon(
                                  onPressed: _abrirLancarPontos,
                                  icon: Icon(Icons.add_circle_outline_rounded, size: 16, color: kPrimary),
                                  label: Text('Pontos', style: TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ),
                            Text('Toque em "Pontos" para lançar pontos em um ranking personalizado.',
                                style: TextStyle(color: kText2, fontSize: 12)),
                          ]),
                          if (a['contatoEmergenciaNome'] != null) ...[
                            const SizedBox(height: 12),
                            _buildCard([
                              _sectionTitle(_eMenorDeIdade(a['dataNascimento']) ? 'Responsável' : 'Contato de Emergência'),
                              _row('Nome', a['contatoEmergenciaNome']),
                              if (_eMenorDeIdade(a['dataNascimento']))
                                _rowWhatsApp('Telefone', a['contatoEmergenciaTelefone'], a['contatoEmergenciaNome']?.toString() ?? '')
                              else
                                _row('Telefone', a['contatoEmergenciaTelefone']),
                            ]),
                          ],
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
    );
  }

  // ── Lançar Pontos em Ranking ─────────────────────────
  Future<void> _abrirLancarPontos() async {
    List<Map<String, dynamic>> rankings = [];
    try {
      final raw = await firestoreService.getRankingsCustom(_academiaId!);
      rankings = raw
          .map((r) => <String, dynamic>{...r, 'incluirPontosManuais': r['incluir_pontos_manuais']})
          .where((r) => r['incluirPontosManuais'] == true && r['ativo'] != false)
          .toList();
    } catch (_) {}

    if (!mounted) return;

    if (rankings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Nenhum ranking com pontos manuais ativo.'),
        backgroundColor: kWarning,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    Map<String, dynamic>? rankingSel = rankings.length == 1 ? rankings.first : null;
    final pontosCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool salvando = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                  Text('Lançar Pontos', style: TextStyle(color: kText1, fontSize: 18, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.of(ctx).pop(), icon: Icon(Icons.close, color: kText2)),
                ]),
                Text(_aluno?['nome'] ?? '', style: TextStyle(color: kText2, fontSize: 13)),
                const Divider(height: 20),
                if (rankings.length > 1) ...[
                  Text('Ranking', style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...rankings.map((r) {
                    final sel = rankingSel?['id'] == r['id'];
                    return GestureDetector(
                      onTap: () => setModal(() => rankingSel = r),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: sel ? kPrimary.withOpacity(0.12) : kBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: sel ? kPrimary : kBorder),
                        ),
                        child: Row(children: [
                          Expanded(child: Text(r['nome'] ?? '', style: TextStyle(color: sel ? kPrimary : kText1, fontSize: 13, fontWeight: FontWeight.w600))),
                          if (sel) Icon(Icons.check_circle_rounded, color: kPrimary, size: 18),
                        ]),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                ] else if (rankings.length == 1) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: kPrimary.withOpacity(0.3))),
                    child: Text(rankingSel?['nome'] ?? '', style: TextStyle(color: kPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: pontosCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: kText1),
                  decoration: InputDecoration(
                    hintText: 'Quantidade de pontos',
                    hintStyle: TextStyle(color: kText2),
                    filled: true, fillColor: kBg,
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kPrimary)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  style: TextStyle(color: kText1),
                  decoration: InputDecoration(
                    hintText: 'Descrição (opcional)',
                    hintStyle: TextStyle(color: kText2),
                    filled: true, fillColor: kBg,
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kPrimary)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: (salvando || rankingSel == null || pontosCtrl.text.trim().isEmpty) ? null : () async {
                      final pts = int.tryParse(pontosCtrl.text.trim());
                      if (pts == null || pts <= 0) return;
                      setModal(() => salvando = true);
                      try {
                        await firestoreService.addLancamentoPonto(_academiaId!, {
                          'ranking_id': rankingSel!['id'],
                          'aluno_id': widget.alunoId,
                          'pontos': pts,
                          if (descCtrl.text.trim().isNotEmpty) 'descricao': descCtrl.text.trim(),
                          'academia_id': _academiaId!,
                          'criado_por': _meId,
                        });
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('$pts pontos lançados com sucesso!'),
                          backgroundColor: kSuccess,
                          behavior: SnackBarBehavior.floating,
                        ));
                      } catch (e) {
                        String msg = 'Erro ao lançar pontos.';
                        try { msg = ((e as dynamic).response?.data as Map?)?['mensagem'] ?? msg; } catch (_) {}
                        if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg), backgroundColor: kDanger, behavior: SnackBarBehavior.floating));
                      } finally {
                        setModal(() => salvando = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: salvando
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Lançar Pontos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGraduacaoItem(Map<String, dynamic> g) {
    final grau = (g['grau'] as num?)?.toInt() ?? 0;
    final nomeFaixa = g['nomeFaixa']?.toString() ?? '-';
    final nomeMod = g['nomeModalidade']?.toString() ?? '';
    final nomeProfessor = g['nomeProfessor']?.toString() ?? '';
    final aprovado = g['aprovado'] == true;
    final corFaixa = _parseCor(g['corFaixa']?.toString());
    final corBarra = _parseCor(g['corBarraFaixa']?.toString() ?? '#000000');
    final temGraus = g['faixaTemGraus'] == true || grau > 0;
    final maxGrausRaw = (g['faixaMaxGraus'] as num?)?.toInt() ?? 0;
    final maxGraus = maxGrausRaw > 0 ? maxGrausRaw : (grau > 0 ? grau : 4);
    final dataStr = _formatDate(g['dataExame']) ?? '';
    final label = grau > 0 ? '$nomeFaixa · $grau° Grau' : nomeFaixa;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot + line
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: aprovado ? corFaixa : kBorder,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    BeltBadge(
                      cor: corFaixa,
                      corBarra: corBarra,
                      temGraus: temGraus,
                      grau: grau,
                      maxGraus: maxGraus,
                      height: 10,
                      minWidth: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: kText1,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (dataStr.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(dataStr, style: TextStyle(color: kText2, fontSize: 11)),
                    ],
                    if (!aprovado) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: kWarning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Pendente', style: TextStyle(color: kWarning, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(List<Widget> children) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Future<void> _escolherFotoAdmin() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result == null || result.files.single.bytes == null || !mounted) return;
    final bytes = result.files.single.bytes!;
    final ext = (result.files.single.extension ?? 'jpg').toLowerCase();
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
    final fotoBase64 = 'data:$mime;base64,${base64Encode(bytes)}';
    try {
      await firestoreService.updateAluno(_academiaId!, widget.alunoId, {'foto_base64': fotoBase64});
      if (mounted) setState(() { _aluno = {...?_aluno, 'fotoBase64': fotoBase64, 'foto_base64': fotoBase64}; });
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Erro ao salvar foto.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating),
      );
    }
  }

  Widget _buildAvatar(Map<String, dynamic> aluno) {
    final nome = aluno['nome']?.toString() ?? '';
    final foto = aluno['fotoBase64'] as String?;
    final initials = nome.trim().split(RegExp(r'\s+')).take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();
    return Center(
      child: GestureDetector(
        onTap: _escolherFotoAdmin,
        child: Stack(
          children: [
            foto != null && foto.startsWith('data:')
                ? CircleAvatar(
                    radius: 32,
                    backgroundColor: kPrimary.withOpacity(0.2),
                    backgroundImage: MemoryImage(base64Decode(foto.split(',').last)),
                  )
                : CircleAvatar(
                    radius: 32,
                    backgroundColor: kPrimary.withOpacity(0.2),
                    child: Text(initials.isEmpty ? '?' : initials, style: TextStyle(color: kPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
                  ),
            Positioned(
              bottom: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: kPrimary, shape: BoxShape.circle,
                  border: Border.all(color: kBg, width: 2),
                ),
                child: const Icon(Icons.camera_alt_rounded, size: 10, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: TextStyle(color: kText2, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      );

  bool _eMenorDeIdade(dynamic dataNascimento) {
    final nasc = DateTime.tryParse(dataNascimento?.toString() ?? '');
    if (nasc == null) return false;
    return DateTime.now().difference(nasc).inDays < 365 * 18;
  }

  void _abrirWhatsApp(String? telefone, String nome) async {
    if (telefone == null || telefone.isEmpty) return;
    final digits = telefone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return;
    final ddi = digits.startsWith('55') ? digits : '55$digits';
    final msg = Uri.encodeComponent('Olá $nome, ');
    final url = Uri.parse('https://wa.me/$ddi?text=$msg');
    launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Widget _row(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: TextStyle(color: kText2, fontSize: 13))),
          Expanded(child: Text(value.toString(), style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _rowWhatsApp(String label, dynamic value, String nome) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
    final tel = value.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: TextStyle(color: kText2, fontSize: 13))),
          Expanded(child: Text(tel, style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w600))),
          GestureDetector(
            onTap: () => _abrirWhatsApp(tel, nome),
            child: const FaIcon(FontAwesomeIcons.whatsapp, color: Color(0xFF25D366), size: 18),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(bool ativo) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: ativo ? kSuccess.withOpacity(0.15) : kText2.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(ativo ? 'Ativo' : 'Inativo',
            style: TextStyle(color: ativo ? kSuccess : kText2, fontSize: 12, fontWeight: FontWeight.w700)),
      );

  String? _formatDate(dynamic raw) {
    if (raw == null) return null;
    try {
      final dt = DateTime.parse(raw.toString());
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return raw.toString();
    }
  }
}

class _ParQOpcao extends StatelessWidget {
  final String label;
  final bool selected;
  final Color cor;
  final VoidCallback onTap;
  const _ParQOpcao({required this.label, required this.selected, required this.cor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? cor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? cor : kBorder, width: selected ? 1.5 : 1),
        ),
        child: Text(label, style: TextStyle(color: selected ? cor : kText2, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, fontSize: 13)),
      ),
    );
  }
}

class _ParQCampo extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final TextInputType keyboard;
  const _ParQCampo({required this.ctrl, required this.label, this.keyboard = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: TextStyle(color: kText1),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: kText2),
        filled: true,
        fillColor: kBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPrimary, width: 1.5)),
      ),
    );
  }
}

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

class _DateMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll(RegExp(r'\D'), '');
    final d = digits.length > 8 ? digits.substring(0, 8) : digits;
    final buf = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i == 2 || i == 4) buf.write('/');
      buf.write(d[i]);
    }
    final text = buf.toString();
    return next.copyWith(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
