import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:url_launcher/url_launcher.dart';
import '../../core/auth_storage.dart';
import '../../core/constants.dart';
import '../../core/drawer_helper.dart';
import '../../core/firestore_service.dart';
import '../../core/tab_refresh.dart';
import '../../core/widgets.dart';
import 'aluno_atestado_screen.dart';
import 'aluno_qrcode_sheet.dart';

// Roda em isolate separado via compute() para não travar a UI
List<int>? _comprimirFoto(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  final resized = img.copyResize(decoded,
      width: decoded.width > decoded.height ? 300 : -1,
      height: decoded.width > decoded.height ? -1 : 300);
  return img.encodeJpg(resized, quality: 75);
}

class AlunoPerfilScreen extends StatefulWidget {
  const AlunoPerfilScreen({super.key});

  @override
  State<AlunoPerfilScreen> createState() => _AlunoPerfilScreenState();
}

class _AlunoPerfilScreenState extends State<AlunoPerfilScreen> {
  Map<String, dynamic>? _aluno;
  Map<String, dynamic>? _atestado;
  Map<String, dynamic>? _parq;
  List<Map<String, dynamic>> _noticias = [];
  List<Map<String, dynamic>> _presencasRecentes = [];
  bool _loading = true;
  bool _uploadingFoto = false;

  @override
  void initState() {
    super.initState();
    alunoTabNotifier.addListener(_onTabChanged);
    alunoDrawerActionNotifier.addListener(_onDrawerAction);
    _load();
  }

  @override
  void dispose() {
    alunoTabNotifier.removeListener(_onTabChanged);
    alunoDrawerActionNotifier.removeListener(_onDrawerAction);
    super.dispose();
  }

  void _onTabChanged() {
    if (alunoTabNotifier.value == 0) _load();
  }

  void _onDrawerAction() {
    final action = alunoDrawerActionNotifier.value;
    if (action.isEmpty) return;
    alunoDrawerActionNotifier.value = '';
    if (action == 'editarPerfil') _editarPerfil();
    if (action == 'qr') _mostrarQrCode();
  }

  Future<void> _escolherFoto() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result == null || result.files.single.bytes == null || !mounted) return;
    final rawBytes = result.files.single.bytes!;

    // Redimensiona em background thread (max 300px, JPEG q75 ≈ 15–40 KB)
    final compressed = await compute(_comprimirFoto, rawBytes);
    if (compressed == null) return;
    final fotoBase64 = 'data:image/jpeg;base64,${base64Encode(compressed)}';

    final user = await AuthStorage.getUser();
    if (user == null) return;

    // Atualiza otimisticamente antes de salvar no Firestore
    if (mounted) setState(() { _uploadingFoto = true; _aluno = {...?_aluno, 'fotoBase64': fotoBase64}; });
    try {
      await firestoreService.updateAluno(user.academiaId!, user.id, {'fotoBase64': fotoBase64});
    } catch (e) {
      // Reverte se o servidor rejeitou
      if (mounted) {
        setState(() { _aluno = {...?_aluno}..remove('fotoBase64'); });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Erro ao salvar foto.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) setState(() => _uploadingFoto = false);
    }
  }

  Future<void> _load() async {
    try {
      final user = await AuthStorage.getUser();
      if (user == null) return;
      final academiaId = user.academiaId!;

      final results = await Future.wait([
        firestoreService.getAluno(academiaId, user.id),
        firestoreService.getAtestadoAluno(academiaId, user.id).catchError((_) => null),
        firestoreService.getParQ(academiaId, user.id).catchError((_) => null),
      ]);

      final dados = results[0] as Map<String, dynamic>?;
      final atestadoDados = results[1] as Map<String, dynamic>?;
      final parqDados = results[2] as Map<String, dynamic>?;

      if (mounted) setState(() {
        // Preserva a foto local se o upload ainda está em andamento ou Firestore ainda não confirmou
        final fotoAtual = _aluno?['fotoBase64'] as String?;
        _aluno = dados == null ? null : {
          ...dados,
          if (dados['fotoBase64'] == null && fotoAtual != null) 'fotoBase64': fotoAtual,
        };
        _atestado = atestadoDados;
        _parq = parqDados;
      });

      try {
        final lista = await firestoreService.getNoticias(academiaId);
        if (mounted) setState(() => _noticias = lista.take(5).toList());
      } catch (_) {}

      if (dados != null) {
        try {
          final lista = await firestoreService.getPresencas(academiaId, alunoId: user.id);
          if (mounted) setState(() => _presencasRecentes = lista.take(7).toList());
        } catch (_) {}
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'</h[1-6]>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'</li>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&lt;'), '<')
        .replaceAll(RegExp(r'&gt;'), '>')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  Color _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.black;
    try { return Color(int.parse(hex.replaceAll('#', '0xFF'))); } catch (_) { return Colors.black; }
  }

  Map<String, dynamic>? _primaryFaixaData() {
    final faixasAtuais = _aluno?['faixasAtuais'] as Map<String, dynamic>?;
    if (faixasAtuais == null || faixasAtuais.isEmpty) return null;
    final principalId = _aluno?['faixaPrincipalModalidadeId'] as String?;
    if (principalId != null && principalId.isNotEmpty && faixasAtuais.containsKey(principalId)) {
      return faixasAtuais[principalId] as Map<String, dynamic>?;
    }
    return faixasAtuais.values.first as Map<String, dynamic>?;
  }

  int _faixasCount() {
    final faixasAtuais = _aluno?['faixasAtuais'] as Map<String, dynamic>?;
    return faixasAtuais?.length ?? 0;
  }

  Future<void> _escolherFaixaPrincipal() async {
    final faixasAtuais = _aluno?['faixasAtuais'] as Map<String, dynamic>?;
    if (faixasAtuais == null || faixasAtuais.length <= 1) return;
    final principalAtual = _aluno?['faixaPrincipalModalidadeId'] as String?;

    final modId = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(color: kSurface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2)))),
            Text('Faixa Principal', style: TextStyle(color: kText1, fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Escolha qual graduação exibir no seu perfil', style: TextStyle(color: kText2, fontSize: 13)),
            const SizedBox(height: 16),
            ...faixasAtuais.entries.map((entry) {
              final id = entry.key;
              final f = entry.value as Map<String, dynamic>;
              final cor = _parseHex(f['faixaCor'] as String?);
              final corBarra = _parseHex(f['faixaCorBarra'] as String?);
              final grau = (f['grau'] as num?)?.toInt() ?? 0;
              final temGraus = f['faixaTemGraus'] == true || grau > 0;
              final maxGraus = ((f['faixaMaxGraus'] as num?)?.toInt() ?? 0).clamp(1, 99);
              final isPrincipal = id == principalAtual;
              return GestureDetector(
                onTap: () => Navigator.pop(context, id),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isPrincipal ? kPrimary.withOpacity(0.08) : kBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isPrincipal ? kPrimary.withOpacity(0.4) : kBorder),
                  ),
                  child: Row(children: [
                    BeltBadge(cor: cor, corBarra: corBarra, temGraus: temGraus, grau: grau, maxGraus: maxGraus > 0 ? maxGraus : 4, height: 14, minWidth: 32),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(f['modalidadeNome'] as String? ?? '', style: TextStyle(color: kText2, fontSize: 11, fontWeight: FontWeight.w600)),
                      Text(grau > 0 ? '${f['faixaNome']} · $grau° Grau' : (f['faixaNome'] as String? ?? ''),
                          style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w700)),
                    ])),
                    if (isPrincipal) Icon(Icons.check_circle_rounded, color: kPrimary, size: 20),
                  ]),
                ),
              );
            }),
          ],
        ),
      ),
    );

    if (modId != null && mounted) {
      setState(() {
        _aluno = {...?_aluno, 'faixaPrincipalModalidadeId': modId};
      });
      final user = await AuthStorage.getUser();
      if (user == null || !mounted) return;
      await firestoreService.updateAluno(user.academiaId!, user.id, {'faixaPrincipalModalidadeId': modId});
      _load();
    }
  }

  void _mostrarQrCode() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const AlunoQrCodeSheet(),
    );
  }

  void _editarPerfil() {
    final nomeCtrl = TextEditingController(text: _aluno?['nome'] as String? ?? '');
    final telCtrl = TextEditingController(text: _aluno?['telefone'] as String? ?? '');
    bool salvando = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: BoxDecoration(color: kSurface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2)))),
              Row(children: [
                Container(width: 38, height: 38,
                  decoration: BoxDecoration(color: kPrimary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.person_rounded, color: kPrimary, size: 20)),
                const SizedBox(width: 12),
                Text('Editar Perfil', style: TextStyle(color: kText1, fontSize: 17, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 20),
              TextField(
                controller: nomeCtrl, style: TextStyle(color: kText1),
                decoration: InputDecoration(
                  labelText: 'Nome completo', labelStyle: TextStyle(color: kText2, fontSize: 13),
                  prefixIcon: Icon(Icons.badge_rounded, color: kText2, size: 18),
                  filled: true, fillColor: kBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPrimary, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: telCtrl, style: TextStyle(color: kText1),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Telefone', labelStyle: TextStyle(color: kText2, fontSize: 13),
                  prefixIcon: Icon(Icons.phone_rounded, color: kText2, size: 18),
                  filled: true, fillColor: kBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kPrimary, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: salvando ? null : () async {
                    setModal(() => salvando = true);
                    try {
                      final user = await AuthStorage.getUser();
                      if (user == null) return;
                      await firestoreService.updateAluno(user.academiaId!, user.id, {
                        'nome': nomeCtrl.text.trim(),
                        'telefone': telCtrl.text.trim().isEmpty ? null : telCtrl.text.trim(),
                      });
                      if (!mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Perfil atualizado!'), backgroundColor: kSuccess, behavior: SnackBarBehavior.floating));
                      _load();
                    } catch (_) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Erro ao salvar.'), backgroundColor: kDanger, behavior: SnackBarBehavior.floating));
                    } finally { setModal(() => salvando = false); }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: salvando
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Salvar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _deveExibirBannerAtestado() {
    if (_atestado == null) return true;
    final status = _atestado!['status'] as int? ?? 0;
    if (status == 2 || status == 3) return true;
    if (status == 1) {
      final val = _atestado!['dataValidade'] as String?;
      if (val == null) return false;
      final dt = DateTime.tryParse(val);
      if (dt == null) return false;
      return dt.isBefore(DateTime.now().add(const Duration(days: 7)));
    }
    return false;
  }

  String _labelAtestado() {
    if (_atestado == null) return 'Atestado médico pendente';
    final status = _atestado!['status'] as int? ?? 0;
    if (status == 2) return 'Atestado rejeitado — envie um novo';
    if (status == 3) return 'Atestado expirado — envie um novo';
    return 'Atestado vencendo em breve';
  }

  Widget _buildSemanaWidget() {
    final hoje = DateTime.now();
    final dias = List.generate(7, (i) => hoje.subtract(Duration(days: 6 - i)));
    final fmt = (DateTime d) => '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
    final diasPresenca = _presencasRecentes.map((p) => (p['data']?.toString() ?? '').substring(0, 10)).toSet();
    const nomes = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    final total = diasPresenca.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('FREQUÊNCIA — 7 DIAS', style: TextStyle(color: kText2, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
            const Spacer(),
            Text('$total ${total == 1 ? 'presença' : 'presenças'}', style: TextStyle(color: kPrimary, fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final dia = dias[i];
              final presente = diasPresenca.contains(fmt(dia));
              final ehHoje = i == 6;
              final nomeIdx = (dia.weekday - 1) % 7;
              return Column(children: [
                Text(nomes[nomeIdx], style: TextStyle(
                  color: ehHoje ? kText1 : kText2,
                  fontSize: 10, fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 6),
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: presente ? kPrimary : (ehHoje ? kPrimary.withOpacity(0.08) : kBg),
                    border: Border.all(
                      color: presente ? kPrimary : (ehHoje ? kPrimary.withOpacity(0.3) : kBorder),
                      width: ehHoje ? 1.5 : 1,
                    ),
                  ),
                  child: presente
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                      : Center(child: Text('${dia.day}', style: TextStyle(
                          color: ehHoje ? kPrimary : kText2,
                          fontSize: 11, fontWeight: ehHoje ? FontWeight.w800 : FontWeight.w500,
                        ))),
                ),
              ]);
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(backgroundColor: kBg, body: Center(child: CircularProgressIndicator(color: kPrimary)));
    }

    final a = _aluno ?? {};
    final nome = a['nome'] as String? ?? '';
    final initials = nome.trim().split(RegExp(r'\s+')).take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();
    final primaryFaixa = _primaryFaixaData();
    final faixasCount = _faixasCount();
    final faixaCor = primaryFaixa != null
        ? _parseHex(primaryFaixa['faixaCor'] as String?)
        : (() { final hex = a['faixaAtualCor'] as String? ?? ''; try { return Color(int.parse(hex.replaceAll('#', '0xFF'))); } catch (_) { return kPrimary; } })();
    final faixaNome = primaryFaixa?['faixaNome'] as String? ?? a['faixaAtualNome'] as String? ?? 'Sem faixa';
    final grauAtual = ((primaryFaixa != null ? primaryFaixa['grau'] : a['grauAtual']) as num?)?.toInt() ?? 0;
    final faixaCorBarra = _parseHex(primaryFaixa?['faixaCorBarra'] as String? ?? a['faixaAtualCorBarra'] as String?);
    final faixaTemGraus = (primaryFaixa != null ? primaryFaixa['faixaTemGraus'] == true : (a['faixaAtualTemGraus'] as bool? ?? false)) || grauAtual > 0;
    final maxGrausRaw = ((primaryFaixa != null ? primaryFaixa['faixaMaxGraus'] : a['faixaAtualMaxGraus']) as num?)?.toInt() ?? 4;
    final faixaMaxGraus = maxGrausRaw > 0 ? maxGrausRaw : (grauAtual > 0 ? grauAtual : 4);
    final turmasDetalhes = (a['turmasDetalhes'] as List? ?? []).cast<Map<String, dynamic>>();
    final finRaw = a['situacaoFinanceira'] as String?;
    final fin = finRaw == 'EmDia' ? 'Em Dia' : finRaw;
    final parqPreenchido = _parq != null;

    Color finCor() {
      if (fin == 'Inadimplente') return kDanger;
      if (fin == 'Pendente') return kWarning;
      if (fin == 'Em Dia') return kSuccess;
      return kText2;
    }

    final beltColor = faixaCor.computeLuminance() > 0.5 ? kPrimary : faixaCor;
    final accentLight = Color.lerp(beltColor, Colors.white, 0.25)!;

    return Scaffold(
      backgroundColor: kBg,
      body: RefreshIndicator(
        onRefresh: _load,
        color: kPrimary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
          // ── Hero header ──────────────────────────────────
          SliverToBoxAdapter(
            child: Stack(
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [beltColor.withOpacity(0.30), kBg],
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      // Top bar: QR + hamburguer à direita
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            const Spacer(),
                            GestureDetector(
                              onTap: _mostrarQrCode,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                                ),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  const Icon(Icons.qr_code_rounded, size: 14, color: Colors.white70),
                                  const SizedBox(width: 6),
                                  Text('QR Presença', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                                ]),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: openAppDrawer,
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.menu_rounded, color: Colors.white70, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Avatar com foto
                      GestureDetector(
                        onTap: _uploadingFoto ? null : _escolherFoto,
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [accentLight, beltColor.withOpacity(0.5)],
                                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                                ),
                              ),
                              child: () {
                                final foto = _aluno?['fotoBase64'] as String?;
                                if (foto != null && foto.startsWith('data:')) {
                                  return CircleAvatar(
                                    radius: 46, backgroundColor: kSurface,
                                    backgroundImage: MemoryImage(base64Decode(foto.split(',').last)),
                                  );
                                }
                                return CircleAvatar(
                                  radius: 46, backgroundColor: kSurface,
                                  child: Text(initials.isEmpty ? '?' : initials,
                                    style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
                                );
                              }(),
                            ),
                            if (_uploadingFoto)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black.withOpacity(0.45),
                                  ),
                                  child: const Center(
                                    child: SizedBox(width: 22, height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                                  ),
                                ),
                              ),
                            if (!_uploadingFoto)
                              Positioned(
                                bottom: 2, right: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: kPrimary, shape: BoxShape.circle,
                                    border: Border.all(color: kBg, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(nome.isEmpty ? 'Aluno' : nome,
                        style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      // Belt badge
                      GestureDetector(
                        onTap: faixasCount > 1 ? _escolherFaixaPrincipal : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: beltColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: beltColor.withOpacity(0.5)),
                          ),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Text(
                                grauAtual > 0 ? '$faixaNome · ${grauAtual}° Grau' : faixaNome,
                                style: TextStyle(color: accentLight, fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                              if (faixasCount > 1) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text('+${faixasCount - 1}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ]),
                            const SizedBox(height: 6),
                            BeltBadge(
                              cor: faixaCor, corBarra: faixaCorBarra,
                              temGraus: faixaTemGraus, grau: grauAtual, maxGraus: faixaMaxGraus,
                              height: 14, minWidth: 52,
                            ),
                            if (faixasCount > 1) ...[
                              const SizedBox(height: 4),
                              Text('Toque para escolher', style: TextStyle(color: Colors.white54, fontSize: 10)),
                            ],
                          ]),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Frequência semanal ──
          SliverToBoxAdapter(child: _buildSemanaWidget()),

          // ── Situação financeira ──
          if (fin == 'Inadimplente' || fin == 'Pendente')
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: finCor().withOpacity(0.08), borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: finCor().withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    Icon(Icons.warning_amber_rounded, color: finCor(), size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Situação: $fin', style: TextStyle(color: finCor(), fontSize: 13, fontWeight: FontWeight.w700)),
                      Text('Entre em contato com a secretaria.', style: TextStyle(color: kText2, fontSize: 12)),
                    ])),
                  ]),
                ),
              ),
            ),

          // ── Banner de atestado médico ──
          if (_deveExibirBannerAtestado())
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AlunoAtestadoScreen())).then((_) => _load()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: kDanger.withOpacity(0.08), borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kDanger.withOpacity(0.35)),
                    ),
                    child: Row(children: [
                      Icon(Icons.medical_information_rounded, color: kDanger, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_labelAtestado(), style: TextStyle(color: kDanger, fontSize: 13, fontWeight: FontWeight.w700)),
                        Text('Toque para resolver', style: TextStyle(color: kText2, fontSize: 12)),
                      ])),
                      Icon(Icons.chevron_right, color: kDanger, size: 20),
                    ]),
                  ),
                ),
              ),
            ),

          // ── Graduações ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: GestureDetector(
                onTap: () => context.push('/aluno/perfil/graduacoes'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: kSurface, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: beltColor.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    Icon(Icons.military_tech_rounded, color: beltColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Histórico de Graduações', style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w700)),
                      Text('Ver todas as faixas e exames', style: TextStyle(color: kText2, fontSize: 11)),
                    ])),
                    Icon(Icons.chevron_right, color: kText2, size: 20),
                  ]),
                ),
              ),
            ),
          ),

          // ── PAR-Q (só aparece se não preenchido) ──
          if (!parqPreenchido)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: GestureDetector(
                  onTap: () => context.push('/aluno/parq').then((_) => _load()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: kSurface, borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kWarning.withOpacity(0.4)),
                    ),
                    child: Row(children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: kWarning.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.assignment_rounded, color: kWarning, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('PAR-Q pendente', style: TextStyle(color: kWarning, fontSize: 13, fontWeight: FontWeight.w700)),
                        Text('Preencha o questionário de saúde', style: TextStyle(color: kText2, fontSize: 11)),
                      ])),
                      Icon(Icons.chevron_right, color: kWarning, size: 20),
                    ]),
                  ),
                ),
              ),
            ),

          // ── Turmas ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
              child: Text('MINHAS TURMAS', style: TextStyle(color: kText2, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            ),
          ),

          if (turmasDetalhes.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
                  child: Text('Nenhuma turma matriculada.', style: TextStyle(color: kText2, fontSize: 13)),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final t = turmasDetalhes[i];
                  final tNome = t['nome'] as String? ?? '';
                  final presencas = (t['totalPresencas'] as num?)?.toInt() ?? 0;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
                      child: Row(children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: beltColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                          child: Icon(Icons.groups_rounded, color: beltColor, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Text(tNome, style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w600))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: beltColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Column(children: [
                            Text('$presencas', style: TextStyle(color: beltColor, fontSize: 15, fontWeight: FontWeight.w800)),
                            Text('presenças', style: TextStyle(color: kText2, fontSize: 9)),
                          ]),
                        ),
                      ]),
                    ),
                  );
                },
                childCount: turmasDetalhes.length,
              ),
            ),

          // ── Notícias (carrossel horizontal) ──
          if (_noticias.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
                child: Row(children: [
                  Expanded(child: Text('NOTÍCIAS', style: TextStyle(color: kText2, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2))),
                  GestureDetector(
                    onTap: () => context.push('/noticias'),
                    child: Text('Ver todas', style: TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 130,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _noticias.length,
                  itemBuilder: (_, i) {
                    final n = _noticias[i];
                    final titulo = n['titulo'] as String? ?? '';
                    final resumo = n['resumo'] as String? ?? '';
                    final publicadaEm = n['criado_em'] as String? ?? n['publicadaEm'] as String?;
                    String dataLabel = '';
                    if (publicadaEm != null) {
                      try {
                        final dt = DateTime.parse(publicadaEm).toLocal();
                        dataLabel = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
                      } catch (_) {}
                    }
                    return GestureDetector(
                      onTap: () => context.push('/noticias'),
                      child: Container(
                        width: 240,
                        margin: EdgeInsets.only(right: i < _noticias.length - 1 ? 10 : 0),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: kSurface, borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: kBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(color: kPrimary.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                                child: Icon(Icons.campaign_rounded, color: kPrimary, size: 15),
                              ),
                              const Spacer(),
                              if (dataLabel.isNotEmpty)
                                Text(dataLabel, style: TextStyle(color: kText2, fontSize: 10)),
                            ]),
                            const SizedBox(height: 8),
                            Text(titulo, style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
                            if (resumo.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(resumo, style: TextStyle(color: kText2, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          // ── Legal ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
              child: Text('LEGAL', style: TextStyle(color: kText2, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
                child: Column(children: [
                  _AlunoLegalTile(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Política de Privacidade',
                    subtitle: 'Como seus dados são tratados',
                    url: 'https://senseimanager.com.br/privacidade',
                  ),
                  Divider(height: 1, color: kBorder),
                  _AlunoLegalTile(
                    icon: Icons.gavel_rounded,
                    label: 'Termos de Uso',
                    subtitle: 'Regras e condições de uso do app',
                    url: 'https://senseimanager.com.br/termos',
                  ),
                ]),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    ),
    );
  }
}

class _AlunoLegalTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final String url;
  const _AlunoLegalTile({required this.icon, required this.label, required this.subtitle, required this.url});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: kPrimary, size: 22),
      title: Text(label, style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: kText2, fontSize: 12)),
      trailing: Icon(Icons.open_in_new_rounded, color: kText2, size: 16),
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
      },
    );
  }
}
