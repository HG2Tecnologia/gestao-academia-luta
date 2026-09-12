import 'package:tatame/core/firestore_service.dart';

/// Substituto de teste para [FirestoreService]. Sobrescreve só os métodos que
/// as telas testadas chamam ao carregar/salvar — o resto herda da classe
/// real, mas nunca é exercitado nestes testes.
///
/// Uso: `firestoreService = FakeFirestoreService(pagamentos: [...]);` antes de
/// montar a tela, e `firestoreService = FirestoreService();` no tearDown.
class FakeFirestoreService extends FirestoreService {
  FakeFirestoreService({
    this.pagamentos = const [],
    this.academia = const {},
    List<Map<String, dynamic>> alunos = const [],
    this.graduacoes = const [],
    this.atestado,
    this.parq,
    this.gruposFamiliares = const [],
    this.faixas = const [],
    this.matriculas = const [],
    this.turmas = const [],
    this.planos = const [],
    List<Map<String, dynamic>> notificacoes = const [],
  }) : alunos = List.of(alunos),
       notificacoes = List.of(notificacoes);

  List<Map<String, dynamic>> pagamentos;
  Map<String, dynamic> academia;
  List<Map<String, dynamic>> alunos;
  List<Map<String, dynamic>> graduacoes;
  Map<String, dynamic>? atestado;
  Map<String, dynamic>? parq;
  List<Map<String, dynamic>> gruposFamiliares;
  List<Map<String, dynamic>> faixas;
  List<Map<String, dynamic>> matriculas;
  List<Map<String, dynamic>> turmas;
  List<Map<String, dynamic>> planos;
  List<Map<String, dynamic>> notificacoes;

  /// Toda chamada a [marcarNotificacaoLida], na ordem.
  final List<String> marcarNotificacaoLidaCalls = [];

  /// Toda chamada a [updateAluno] recebida, na ordem — para o teste poder
  /// afirmar o que foi (ou não) persistido.
  final List<Map<String, dynamic>> updateAlunoCalls = [];

  @override
  Future<List<Map<String, dynamic>>> getPagamentos(
    String academiaId, {
    String? alunoId,
  }) async {
    if (alunoId == null) return pagamentos;
    return pagamentos.where((p) => p['aluno_id'] == alunoId).toList();
  }

  @override
  Future<Map<String, dynamic>?> getAcademia(String academiaId) async =>
      academia;

  @override
  Future<List<Map<String, dynamic>>> getAlunos(
    String academiaId, {
    bool ativosOnly = false,
  }) async {
    if (!ativosOnly) return alunos;
    return alunos.where((a) => a['ativo'] == true).toList();
  }

  @override
  Future<Map<String, dynamic>?> getAluno(String academiaId, String id) async {
    try {
      return alunos.firstWhere((a) => a['id']?.toString() == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateAluno(
    String academiaId,
    String id,
    Map<String, dynamic> data,
  ) async {
    updateAlunoCalls.add({'id': id, ...data});
    final idx = alunos.indexWhere((a) => a['id']?.toString() == id);
    if (idx != -1) alunos[idx] = {...alunos[idx], ...data};
  }

  @override
  Future<List<Map<String, dynamic>>> getGraduacoes(
    String academiaId, {
    String? alunoId,
    bool detalhadas = false,
  }) async {
    if (alunoId == null) return graduacoes;
    return graduacoes.where((g) => g['aluno_id'] == alunoId).toList();
  }

  @override
  Future<Map<String, dynamic>?> getAtestadoAluno(
    String academiaId,
    String alunoId,
  ) async => atestado;

  @override
  Future<Map<String, dynamic>?> getParQ(
    String academiaId,
    String alunoId,
  ) async => parq;

  @override
  Future<List<Map<String, dynamic>>> getGruposFamiliares(
    String academiaId,
  ) async => gruposFamiliares;

  @override
  Future<List<Map<String, dynamic>>> getFaixas(
    String academiaId, {
    String? modalidadeId,
  }) async => faixas;

  @override
  Future<List<Map<String, dynamic>>> getMatriculas(
    String academiaId, {
    String? alunoId,
    String? turmaId,
    bool ativasOnly = false,
  }) async {
    var result = matriculas;
    if (alunoId != null) {
      result = result.where((m) => m['aluno_id'] == alunoId).toList();
    }
    if (ativasOnly) {
      result = result.where((m) => m['ativo'] == true).toList();
    }
    return result;
  }

  @override
  Future<List<Map<String, dynamic>>> getTurmas(
    String academiaId, {
    String? professorId,
    bool ativasOnly = false,
  }) async => turmas;

  @override
  Future<List<Map<String, dynamic>>> getPlanos(String academiaId) async =>
      planos;

  @override
  Future<Map<String, dynamic>?> getPlano(String academiaId, String id) async {
    try {
      return planos.firstWhere((p) => p['id']?.toString() == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getNotificacoes(String academiaId) async =>
      notificacoes.where((n) => n['aluno_id'] == null).toList();

  @override
  Future<List<Map<String, dynamic>>> getNotificacoesAluno(
    String academiaId,
    String alunoId,
  ) async =>
      notificacoes.where((n) => n['aluno_id']?.toString() == alunoId).toList();

  @override
  Future<void> marcarNotificacaoLida(String academiaId, String id) async {
    marcarNotificacaoLidaCalls.add(id);
    final idx = notificacoes.indexWhere((n) => n['id']?.toString() == id);
    if (idx != -1) notificacoes[idx] = {...notificacoes[idx], 'lida': true};
  }

  @override
  Future<void> marcarTodasNotificacoesLidas(String academiaId) async {
    notificacoes = notificacoes.map((n) => {...n, 'lida': true}).toList();
  }
}
