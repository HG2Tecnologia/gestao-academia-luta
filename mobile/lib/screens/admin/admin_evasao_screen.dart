import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/auth_storage.dart';
import '../../core/theme/context_ext.dart';
import '../../core/firestore_service.dart';
import '../../core/phone_normalizer.dart';
import '../../core/widgets.dart';

class AdminEvasaoScreen extends StatefulWidget {
  const AdminEvasaoScreen({super.key});

  @override
  State<AdminEvasaoScreen> createState() => _AdminEvasaoScreenState();
}

class _AdminEvasaoScreenState extends State<AdminEvasaoScreen> {
  bool _loading = true;
  bool _erro = false;
  List<Map<String, dynamic>> _lista = [];
  String _mensagem = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final user = await AuthStorage.getUser();
      final academiaId = user!.academiaId!;

      final results = await Future.wait([
        firestoreService.getAlunos(academiaId, ativosOnly: true),
        firestoreService.getPresencas(academiaId),
        firestoreService.getMatriculas(academiaId, ativasOnly: true),
        firestoreService.getTurmas(academiaId),
        firestoreService.getAcademia(academiaId),
      ]);
      final alunos = (results[0] as List).cast<Map<String, dynamic>>();
      final presencas = (results[1] as List).cast<Map<String, dynamic>>();
      final matriculas = (results[2] as List).cast<Map<String, dynamic>>();
      final turmas = (results[3] as List).cast<Map<String, dynamic>>();
      final academia = results[4] as Map<String, dynamic>?;

      final msg = (academia?['mensagem_evasao'] as String?)?.trim();
      if (msg != null && msg.isNotEmpty) _mensagem = msg;

      final turmaNome = {
        for (final t in turmas)
          t['id'].toString(): (t['nome']?.toString() ?? ''),
      };
      final turmasPorAluno = <String, List<String>>{};
      for (final m in matriculas) {
        final aId = m['aluno_id']?.toString() ?? '';
        final tId = m['turma_id']?.toString() ?? '';
        if (aId.isEmpty) continue;
        final nome = turmaNome[tId];
        if (nome != null && nome.isNotEmpty) {
          turmasPorAluno.putIfAbsent(aId, () => []).add(nome);
        }
      }

      final now = DateTime.now();
      final limite7 = now.subtract(const Duration(days: 7));
      final ultimaPresenca = <String, DateTime>{};
      final presencas7 = <String, int>{};
      for (final p in presencas) {
        final aId = p['aluno_id']?.toString() ?? '';
        if (aId.isEmpty) continue;
        final d = DateTime.tryParse(
          (p['data'] ?? p['data_presenca'] ?? '').toString(),
        );
        if (d == null) continue;
        final atual = ultimaPresenca[aId];
        if (atual == null || d.isAfter(atual)) ultimaPresenca[aId] = d;
        if (d.isAfter(limite7)) presencas7[aId] = (presencas7[aId] ?? 0) + 1;
      }

      final lista = <Map<String, dynamic>>[];
      for (final a in alunos) {
        final aId = a['id']?.toString() ?? '';
        if (aId.isEmpty) continue;
        final ultima = ultimaPresenca[aId];
        if (ultima == null) continue; // nunca treinou → não é evasão
        if ((presencas7[aId] ?? 0) >= 4) continue; // voltou com força
        final dias = now.difference(ultima).inDays;
        if (dias < 7) continue;
        lista.add({
          'id': aId,
          'nome': a['nome']?.toString() ?? '',
          'telefone': a['telefone']?.toString() ?? '',
          'telefone_digits': a['telefone_digits']?.toString() ?? '',
          'dias': dias,
          'turmas': (turmasPorAluno[aId] ?? const []).join(' · '),
        });
      }
      lista.sort((a, b) => (b['dias'] as int).compareTo(a['dias'] as int));

      if (mounted) setState(() => _lista = lista);
    } catch (_) {
      if (mounted) setState(() => _erro = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _abrirWhatsApp(Map<String, dynamic> aluno) async {
    final bruto = (aluno['telefone'] as String?) ?? '';
    final digits =
        PhoneNormalizer.digits(bruto) ??
        (aluno['telefone_digits'] as String? ?? '').replaceAll(
          RegExp(r'\D'),
          '',
        );
    if (digits.isEmpty) return;
    final primeiroNome = (aluno['nome'] as String? ?? '')
        .trim()
        .split(' ')
        .first;
    final base = _mensagem.isNotEmpty
        ? _mensagem
        : context.l10n.evasaoDefaultMsg('{nome}', '{dias}');
    final texto = base
        .replaceAll('{nome}', primeiroNome)
        .replaceAll('{dias}', '${aluno['dias']}');
    final uri = Uri.parse(
      'https://wa.me/$digits?text=${Uri.encodeComponent(texto)}',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.commonCantOpenWhatsapp),
          backgroundColor: context.sem.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: context.c.surface,
        body: Center(
          child: CircularProgressIndicator(color: context.c.primary),
        ),
      );
    }
    if (_erro && _lista.isEmpty) {
      return Scaffold(
        backgroundColor: context.c.surface,
        body: SafeArea(
          child: ErroConexao(
            onRetry: () {
              setState(() {
                _loading = true;
                _erro = false;
              });
              _load();
            },
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.c.surface,
      body: RefreshIndicator(
        onRefresh: _load,
        color: context.c.primary,
        child: SafeArea(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: context.c.onSurface,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.evasaoRiskTitle,
                          style: TextStyle(
                            color: context.c.onSurface,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '${_lista.length} ${_lista.length == 1 ? 'aluno' : 'alunos'} sem treinar há 7+ dias',
                          style: TextStyle(
                            color: context.c.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_lista.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Column(
                    children: [
                      Icon(
                        Icons.celebration_rounded,
                        color: context.c.outline,
                        size: 56,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        context.l10n.evasaoNobodyAtRisk,
                        style: TextStyle(
                          color: context.c.onSurfaceVariant,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ..._lista.map(_tile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(Map<String, dynamic> a) {
    final dias = a['dias'] as int;
    final vermelho = dias >= 14;
    final temTel =
        (a['telefone'] as String).trim().isNotEmpty ||
        (a['telefone_digits'] as String).trim().isNotEmpty;
    final nome = a['nome'] as String;
    final iniciais = nome
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0])
        .join()
        .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.c.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.c.outline),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor:
                (vermelho ? context.sem.danger : context.sem.warning)
                    .withValues(alpha: 0.16),
            child: Text(
              iniciais.isEmpty ? '?' : iniciais,
              style: TextStyle(
                color: vermelho ? context.sem.danger : context.sem.warning,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: TextStyle(
                    color: context.c.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if ((a['turmas'] as String).isNotEmpty)
                  Text(
                    a['turmas'] as String,
                    style: TextStyle(
                      color: context.c.onSurfaceVariant,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 2),
                Text(
                  '$dias dias sem treinar',
                  style: TextStyle(
                    color: vermelho ? context.sem.danger : context.sem.warning,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (temTel)
            IconButton(
              onPressed: () => _abrirWhatsApp(a),
              icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 22),
              color: const Color(0xFF25D366),
              tooltip: context.l10n.evasaoCallWhatsapp,
            ),
        ],
      ),
    );
  }
}
