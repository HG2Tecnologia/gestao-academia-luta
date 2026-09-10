import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/auth_storage.dart';
import '../../core/theme/context_ext.dart';
import '../../core/firestore_service.dart';

String _mesCurto(BuildContext c, int m) {
  final loc = Localizations.localeOf(c).languageCode;
  final s = DateFormat.MMM(loc).format(DateTime(2000, m.clamp(1, 12)));
  return s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

String _mesLongo(BuildContext c, int m) {
  final loc = Localizations.localeOf(c).languageCode;
  final s = DateFormat.MMMM(loc).format(DateTime(2000, m.clamp(1, 12)));
  return s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

class AdminAniversariantesScreen extends StatefulWidget {
  const AdminAniversariantesScreen({super.key});

  @override
  State<AdminAniversariantesScreen> createState() =>
      _AdminAniversariantesScreenState();
}

class _AdminAniversariantesScreenState
    extends State<AdminAniversariantesScreen> {
  List<Map<String, dynamic>> _alunos = [];
  bool _loading = true;
  bool _erro = false;
  int _mes = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted)
      setState(() {
        _loading = true;
        _erro = false;
      });
    try {
      final user = await AuthStorage.getUser();
      final academiaId = user!.academiaId!;
      final todos = await firestoreService.getAlunos(academiaId);
      final aniversariantes = todos
          .where((a) {
            final dn = a['dataNascimento'] ?? a['data_nascimento'];
            if (dn == null) return false;
            try {
              return DateTime.parse(dn.toString()).month == _mes;
            } catch (_) {
              return false;
            }
          })
          .map((a) {
            final dn = a['dataNascimento'] ?? a['data_nascimento'];
            int dia = 0;
            try {
              dia = DateTime.parse(dn.toString()).day;
            } catch (_) {}
            return {...a, 'diaNascimento': dia};
          })
          .toList();
      aniversariantes.sort(
        (a, b) => ((a['diaNascimento'] as int?) ?? 0).compareTo(
          (b['diaNascimento'] as int?) ?? 0,
        ),
      );
      if (mounted)
        setState(() {
          _alunos = aniversariantes;
          _loading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _erro = true;
        });
    }
  }

  bool get _ehMesAtual => _mes == DateTime.now().month;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back, color: context.c.onSurface),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.cake_rounded,
                    color: context.sem.warning,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.birthdaysTitle,
                      style: TextStyle(
                        color: context.c.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Seletor de mês
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: 12,
                itemBuilder: (_, i) {
                  final selected = _mes == i + 1;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _mes = i + 1);
                      _load();
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? context.c.primary
                            : context.c.surfaceContainer,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? context.c.primary
                              : context.c.outline,
                        ),
                      ),
                      child: Text(
                        _mesCurto(context, i + 1),
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : context.c.onSurfaceVariant,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Text(
                    _mesLongo(context, _mes),
                    style: TextStyle(
                      color: context.c.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_ehMesAtual) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: context.sem.warning.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        context.l10n.birthdaysCurrentMonth,
                        style: TextStyle(
                          color: context.sem.warning,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: context.c.primary,
                      ),
                    )
                  : _erro
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: context.sem.danger,
                            size: 36,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.l10n.ctLoadError,
                            style: TextStyle(color: context.c.onSurfaceVariant),
                          ),
                          TextButton(
                            onPressed: _load,
                            child: Text(
                              context.l10n.commonRetry,
                              style: TextStyle(color: context.c.primary),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _alunos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cake_outlined,
                            color: context.c.onSurfaceVariant,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.l10n.birthdaysNoneInMonth(
                              _mesLongo(context, _mes),
                            ),
                            style: TextStyle(
                              color: context.c.onSurfaceVariant,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: context.c.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: _alunos.length,
                        itemBuilder: (_, i) => _AlunoCard(
                          a: _alunos[i],
                          mes: _mes,
                          mesAtual: _ehMesAtual,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlunoCard extends StatelessWidget {
  final Map<String, dynamic> a;
  final int mes;
  final bool mesAtual;

  const _AlunoCard({
    required this.a,
    required this.mes,
    required this.mesAtual,
  });

  bool get _ehHoje {
    if (!mesAtual) return false;
    return (a['diaNascimento'] as int?) == DateTime.now().day;
  }

  @override
  Widget build(BuildContext context) {
    final dia = a['diaNascimento'] as int? ?? 0;
    final nome = a['nome'] as String? ?? '—';
    final initials = nome
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
    final dataFormatada =
        '${dia.toString().padLeft(2, '0')}/${mes.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _ehHoje
            ? context.sem.warning.withOpacity(0.08)
            : context.c.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _ehHoje
              ? context.sem.warning.withOpacity(0.4)
              : context.c.outline,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.c.primary.withOpacity(0.15),
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  color: context.c.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dataFormatada,
                  style: TextStyle(
                    color: context.c.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (_ehHoje) ...[
            Text('🎂', style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 4),
          ],
          if (!_ehHoje)
            Text(
              dataFormatada,
              style: TextStyle(
                color: context.c.onSurfaceVariant,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}
