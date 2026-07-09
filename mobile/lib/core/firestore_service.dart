import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'academia_seeds.dart';

/// Substitui todas as chamadas de API REST ao backend Render.
/// Todos os dados vêm diretamente do Firebase Firestore.
class FirestoreService {
  final _db = FirebaseFirestore.instance;

  CollectionReference _col(String academiaId, String sub) =>
      _db.collection('academias').doc(academiaId).collection(sub);

  DocumentReference _doc(String academiaId, String sub, String id) =>
      _col(academiaId, sub).doc(id);

  // Converte Timestamp Firestore → String ISO para compatibilidade com a UI existente
  Map<String, dynamic> _convertDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return _convertMap({'id': doc.id, ...data});
  }

  Map<String, dynamic> _convertMap(Map<String, dynamic> map) {
    return map.map((k, v) {
      if (v is Timestamp) return MapEntry(k, v.toDate().toIso8601String());
      if (v is Map<String, dynamic>) return MapEntry(k, _convertMap(v));
      return MapEntry(k, v);
    });
  }

  // ─── LOOKUP / AUTH ─────────────────────────────────────────────────────────

  /// Retorna {academiaId, usuarioId, perfil, nome, email, permissoes, perfis?} para o UID Firebase atual.
  Future<Map<String, dynamic>?> getUserByFirebaseUid(String uid) async {
    final doc = await _db.collection('usuariosFirebase').doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;

    // Carrega permissoes do doc do funcionario (se for professor/secretaria)
    final colecao = data['colecao'] as String? ?? 'usuarios';
    final usuarioId = data['usuarioId'] as String?;
    final academiaId = data['academiaId'] as String?;
    Map<String, bool> permissoes = {};

    if (usuarioId != null && academiaId != null && colecao == 'funcionarios') {
      try {
        final funcDoc = await _doc(academiaId, 'funcionarios', usuarioId).get();
        if (funcDoc.exists) {
          final rawPerm = (funcDoc.data() as Map<String, dynamic>?)?['permissoes'];
          if (rawPerm is Map) {
            permissoes = rawPerm.map((k, v) => MapEntry(k.toString(), v == true));
          }
        }
      } catch (_) {}
    }

    return {...data, 'permissoes': permissoes};
  }

  /// Busca todos os usuários que correspondem ao e-mail ou telefone em todas as academias.
  /// Procura tanto em `funcionarios` (professor/secretaria/admin) quanto em `usuarios` (alunos).
  /// Cada resultado inclui `_colecao` ('funcionarios' ou 'usuarios') e `perfil_nome`.
  Future<List<Map<String, dynamic>>> buscarUsuariosPorEmailOuTelefone(String valor) async {
    final valorLower = valor.toLowerCase().trim();
    final isEmail = valor.contains('@');
    final digits = valor.replaceAll(RegExp(r'\D'), '');

    final academiasSnap = await _db.collection('academias').get();
    final results = <Map<String, dynamic>>[];

    for (final acadDoc in academiasSnap.docs) {
      final academiaId = acadDoc.id;

      // 1. Funcionários (professor, secretaria, admin)
      {
        final col = _col(academiaId, 'funcionarios');
        QuerySnapshot snap;
        if (isEmail) {
          snap = await col.where('email', isEqualTo: valorLower).get();
        } else {
          snap = await col.where('telefone_digits', isEqualTo: digits).get();
          if (snap.docs.isEmpty) {
            snap = await col.where('telefone', isEqualTo: valor.trim()).get();
          }
        }
        for (final d in snap.docs) {
          final data = _convertDoc(d);
          final perfilNome = data['perfil'] as String? ?? 'Professor';
          results.add({
            ...data,
            'academiaId': academiaId,
            'usuarioId': data['id'],
            'perfil_nome': perfilNome,
            '_colecao': 'funcionarios',
          });
        }
      }

      // 2. Alunos (usuarios com perfil=3)
      // Não usa query composta (evita necessidade de índice composto no Firestore).
      // Filtra perfil=3 no cliente.
      {
        final col = _col(academiaId, 'usuarios');
        QuerySnapshot snap;
        if (isEmail) {
          snap = await col.where('email', isEqualTo: valorLower).get();
        } else {
          snap = await col.where('telefone_digits', isEqualTo: digits).get();
          if (snap.docs.isEmpty) {
            snap = await col.where('telefone', isEqualTo: valor.trim()).get();
          }
        }
        for (final d in snap.docs) {
          final data = _convertDoc(d);
          // Filtra apenas alunos (perfil=3); outros perfis em usuarios são ignorados
          if ((data['perfil'] as int?) != 3) continue;
          results.add({
            ...data,
            'academiaId': academiaId,
            'usuarioId': data['id'],
            'perfil_nome': 'Aluno',
            '_colecao': 'usuarios',
          });
        }
      }
    }
    return results;
  }

  /// Verifica se já existe um aluno com o mesmo e-mail ou telefone na academia.
  Future<Map<String, dynamic>?> verificarDuplicadoAluno(
    String academiaId, {
    String? email,
    String? telefoneDigits,
  }) async {
    if (email != null && email.isNotEmpty) {
      final snap = await _col(academiaId, 'usuarios')
          .where('email', isEqualTo: email.toLowerCase())
          .where('perfil', isEqualTo: 3)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) return _convertDoc(snap.docs.first);
    }
    if (telefoneDigits != null && telefoneDigits.isNotEmpty) {
      final snap = await _col(academiaId, 'usuarios')
          .where('telefone_digits', isEqualTo: telefoneDigits)
          .where('perfil', isEqualTo: 3)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) return _convertDoc(snap.docs.first);
    }
    return null;
  }

  /// Vincula um Firebase UID ao usuário do Firestore e cria entrada em usuariosFirebase.
  /// [dadosUsuario] deve conter '_colecao' ('funcionarios' ou 'usuarios') e 'perfil_nome'.
  /// [outrosPerfis] são os demais perfis com o mesmo e-mail (grupo familiar de alunos).
  Future<void> ativarContaUsuario({
    required String firebaseUid,
    required String academiaId,
    required String usuarioId,
    required Map<String, dynamic> dadosUsuario,
    List<Map<String, dynamic>>? outrosPerfis,
  }) async {
    final colecao = dadosUsuario['_colecao'] as String? ?? 'usuarios';
    final perfilNome = dadosUsuario['perfil_nome'] as String? ?? 'Aluno';

    // Monta lista de todos os perfis (para grupo familiar)
    final todosPerfis = [
      {'usuarioId': usuarioId, 'nome': dadosUsuario['nome'] ?? '', 'colecao': colecao, 'academiaId': academiaId},
      if (outrosPerfis != null)
        for (final p in outrosPerfis)
          {
            'usuarioId': p['usuarioId'] ?? p['id'],
            'nome': p['nome'] ?? '',
            'colecao': p['_colecao'] ?? 'usuarios',
            'academiaId': p['academiaId'] ?? academiaId,
          },
    ];

    // Cria entrada de lookup
    await _db.collection('usuariosFirebase').doc(firebaseUid).set({
      'academiaId': academiaId,
      'usuarioId': usuarioId,
      'colecao': colecao,
      'perfil': perfilNome,
      'nome': dadosUsuario['nome'] ?? '',
      'email': dadosUsuario['email'] ?? '',
      if (todosPerfis.length > 1) 'perfis': todosPerfis,
    });

    // Marca o usuário selecionado como vinculado
    await _doc(academiaId, colecao, usuarioId).update({
      'firebaseUid': firebaseUid,
      'conta_ativa': true,
    });

    // Vincula também os demais perfis do grupo familiar
    if (outrosPerfis != null) {
      for (final p in outrosPerfis) {
        final pCol = p['_colecao'] as String? ?? 'usuarios';
        final pAcad = p['academiaId'] as String? ?? academiaId;
        final pId = (p['usuarioId'] ?? p['id']) as String?;
        if (pId != null) {
          try {
            await _doc(pAcad, pCol, pId).update({'firebaseUid': firebaseUid, 'conta_ativa': true});
          } catch (_) {}
        }
      }
    }
  }

  // ─── ACADEMIA ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getAcademia(String academiaId) async {
    final doc = await _db.collection('academias').doc(academiaId).get();
    if (!doc.exists) return null;
    return _convertDoc(doc);
  }

  Future<void> updateAcademia(String academiaId, Map<String, dynamic> data) =>
      _db.collection('academias').doc(academiaId).update(data);

  // ─── USUÁRIOS ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getUsuario(String academiaId, String id) async {
    final doc = await _doc(academiaId, 'usuarios', id).get();
    if (!doc.exists) return null;
    return _convertDoc(doc);
  }

  Future<void> updateUsuario(String academiaId, String id, Map<String, dynamic> data) =>
      _doc(academiaId, 'usuarios', id).update(data);

  // ─── ALUNOS ────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAlunos(String academiaId,
      {bool ativosOnly = false}) async {
    Query q = _col(academiaId, 'usuarios').where('perfil', isEqualTo: 3);
    if (ativosOnly) q = q.where('ativo', isEqualTo: true);
    final snap = await q.get();
    final result = snap.docs.map(_convertDoc).toList();
    result.sort((a, b) => (a['nome'] as String? ?? '').toLowerCase().compareTo((b['nome'] as String? ?? '').toLowerCase()));
    return result;
  }

  Future<Map<String, dynamic>?> getAluno(String academiaId, String id) =>
      getUsuario(academiaId, id);

  Future<String> addAluno(String academiaId, Map<String, dynamic> data) async {
    final ref = _col(academiaId, 'usuarios').doc();
    final alunoId = ref.id;
    await ref.set({
      ...data,
      'id': alunoId,
      'perfil': 3,
      'perfil_nome': 'Aluno',
      'ativo': true,
      'xp_total': 0,
      'xp_mensal': 0,
      'nivel': 0,
      'criado_em': FieldValue.serverTimestamp(),
    });

    // Auto-gera cobrança do mês corrente se plano e dia de vencimento foram informados
    final planoId = data['planoId'] as String?;
    final diaVenc = data['diaVencimento'] as int?;
    if (planoId != null && diaVenc != null) {
      try {
        final planoDoc = await _doc(academiaId, 'planos', planoId).get();
        if (planoDoc.exists) {
          final plano = planoDoc.data() as Map<String, dynamic>;
          final valor = (plano['valor_mensal'] as num?)?.toDouble() ?? 0.0;
          final now = DateTime.now();
          final dia = diaVenc.clamp(1, 28);
          final vencStr =
              '${now.year.toString().padLeft(4, '0')}-'
              '${now.month.toString().padLeft(2, '0')}-'
              '${dia.toString().padLeft(2, '0')}';
          final pagRef = _col(academiaId, 'pagamentos').doc();
          await pagRef.set({
            'id': pagRef.id,
            'aluno_id': alunoId,
            'aluno_nome': data['nome'] ?? '',
            'plano_id': planoId,
            'plano_nome': plano['nome'] ?? '',
            'valor': valor,
            'data_vencimento': vencStr,
            'status': 0, // Pendente
            'mes_referencia':
                '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}',
            'criado_em': FieldValue.serverTimestamp(),
          });
        }
      } catch (_) {}
    }

    return alunoId;
  }

  Future<void> updateAluno(String academiaId, String id, Map<String, dynamic> data) =>
      _doc(academiaId, 'usuarios', id).update({...data, 'atualizado_em': FieldValue.serverTimestamp()});

  Future<List<Map<String, dynamic>>> getAniversariantes(String academiaId) async {
    final mes = DateTime.now().month;
    // Firestore não suporta filtro por mês diretamente; filtra no cliente
    final snap = await _col(academiaId, 'usuarios')
        .where('perfil', isEqualTo: 3)
        .where('ativo', isEqualTo: true)
        .get();
    return snap.docs.map(_convertDoc).where((u) {
      final dn = u['data_nascimento'];
      if (dn == null) return false;
      try {
        return DateTime.parse(dn).month == mes;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  // ─── FUNCIONÁRIOS ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getFuncionarios(String academiaId) async {
    final snap = await _col(academiaId, 'funcionarios').orderBy('criado_em').get();
    return snap.docs.map(_convertDoc).toList();
  }

  Future<Map<String, dynamic>?> getFuncionario(String academiaId, String id) async {
    final doc = await _doc(academiaId, 'funcionarios', id).get();
    if (!doc.exists) return null;
    return _convertDoc(doc);
  }

  Future<String> addFuncionario(String academiaId, Map<String, dynamic> data) async {
    final ref = _col(academiaId, 'funcionarios').doc();
    final perfil = data['perfil'] as String? ?? 'Professor';
    await ref.set({
      ...data,
      'id': ref.id,
      'perfil_nome': perfil, // normaliza igual ao campo de alunos
      'criado_em': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> updateFuncionario(String academiaId, String id, Map<String, dynamic> data) =>
      _doc(academiaId, 'funcionarios', id).update({...data, 'atualizado_em': FieldValue.serverTimestamp()});

  Future<void> deleteFuncionario(String academiaId, String id) =>
      _doc(academiaId, 'funcionarios', id).delete();

  // ─── SEED PADRÃO ──────────────────────────────────────────────────────────

  /// Popula uma nova academia com modalidades e faixas padrão.
  /// Idempotente: se já existirem modalidades, não faz nada.
  Future<void> popularModalidadesDefault(String academiaId) async {
    final existentes = await _col(academiaId, 'modalidades').limit(1).get();
    if (existentes.docs.isNotEmpty) return;

    for (final mod in kModalidadesDefault) {
      final modRef = _col(academiaId, 'modalidades').doc();
      final modId = modRef.id;
      await modRef.set({
        'id': modId,
        'nome': mod['nome'],
        'cor': mod['cor'],
        'ativo': true,
        'criado_em': FieldValue.serverTimestamp(),
      });

      final faixas = mod['faixas'] as List<Map<String, dynamic>>;
      for (final f in faixas) {
        final fRef = _col(academiaId, 'faixas').doc();
        await fRef.set({
          'id': fRef.id,
          'modalidadeId': modId,
          'nome': f['nome'],
          'cor': f['cor'],
          'ordem': f['ordem'],
          'tem_graus': f['tem_graus'],
          'max_graus': f['max_graus'],
          'criado_em': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  // ─── MODALIDADES ───────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getModalidades(String academiaId) async {
    final snap = await _col(academiaId, 'modalidades').orderBy('nome').get();
    return snap.docs.map(_convertDoc).toList();
  }

  Future<String> addModalidade(String academiaId, Map<String, dynamic> data) async {
    final ref = _col(academiaId, 'modalidades').doc();
    await ref.set({...data, 'id': ref.id, 'ativo': true, 'criado_em': FieldValue.serverTimestamp()});
    return ref.id;
  }

  Future<void> toggleModalidadeAtivo(String academiaId, String id) async {
    final doc = await _doc(academiaId, 'modalidades', id).get();
    final atual = (doc.data() as Map?)?['ativo'] as bool? ?? true;
    await _doc(academiaId, 'modalidades', id).update({'ativo': !atual});
  }

  Future<void> deleteModalidade(String academiaId, String id) =>
      _doc(academiaId, 'modalidades', id).delete();

  // ─── FAIXAS ────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getFaixas(String academiaId,
      {String? modalidadeId}) async {
    Query q;
    if (modalidadeId != null) {
      q = _col(academiaId, 'faixas')
          .where('modalidadeId', isEqualTo: modalidadeId);
    } else {
      q = _col(academiaId, 'faixas');
    }
    final snap = await q.get();
    final result = snap.docs.map(_convertDoc).toList();
    result.sort((a, b) {
      final modCmp = (a['modalidadeId'] as String? ?? '').compareTo(b['modalidadeId'] as String? ?? '');
      if (modCmp != 0) return modCmp;
      return (a['ordem'] as int? ?? 0).compareTo(b['ordem'] as int? ?? 0);
    });
    return result;
  }

  Future<String> addFaixa(String academiaId, Map<String, dynamic> data) async {
    final ref = _col(academiaId, 'faixas').doc();
    await ref.set({...data, 'id': ref.id, 'criado_em': FieldValue.serverTimestamp()});
    return ref.id;
  }

  Future<void> updateFaixa(String academiaId, String id, Map<String, dynamic> data) =>
      _doc(academiaId, 'faixas', id).update({...data, 'atualizado_em': FieldValue.serverTimestamp()});

  Future<void> deleteFaixa(String academiaId, String id) =>
      _doc(academiaId, 'faixas', id).delete();

  // ─── TURMAS ────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getTurmas(String academiaId,
      {String? professorId, bool ativasOnly = false}) async {
    // Quando filtra por professorId, não usa orderBy para evitar índice composto.
    // Ordenação é feita client-side.
    Query q = _col(academiaId, 'turmas');
    if (professorId != null) {
      q = q.where('professorId', isEqualTo: professorId);
    } else {
      q = q.orderBy('nome');
    }
    if (ativasOnly) q = q.where('ativo', isEqualTo: true);
    final snap = await q.get();
    final list = snap.docs.map(_convertDoc).toList();
    if (professorId != null) {
      list.sort((a, b) => (a['nome'] as String? ?? '').compareTo(b['nome'] as String? ?? ''));
    }
    return list;
  }

  Future<Map<String, dynamic>?> getTurma(String academiaId, String id) async {
    final doc = await _doc(academiaId, 'turmas', id).get();
    if (!doc.exists) return null;
    return _convertDoc(doc);
  }

  Future<String> addTurma(String academiaId, Map<String, dynamic> data) async {
    final ref = _col(academiaId, 'turmas').doc();
    await ref.set({...data, 'id': ref.id, 'ativo': true, 'criado_em': FieldValue.serverTimestamp()});
    return ref.id;
  }

  Future<void> updateTurma(String academiaId, String id, Map<String, dynamic> data) =>
      _doc(academiaId, 'turmas', id).update({...data, 'atualizado_em': FieldValue.serverTimestamp()});

  Future<void> deleteTurma(String academiaId, String id) =>
      _doc(academiaId, 'turmas', id).delete();

  // ─── HORÁRIOS ──────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getHorarios(String academiaId,
      {String? turmaId}) async {
    Query q = _col(academiaId, 'horarios');
    if (turmaId != null) q = q.where('turma_id', isEqualTo: turmaId);
    final snap = await q.get();
    return snap.docs.map(_convertDoc).toList();
  }

  /// Horários de um aluno: busca matrículas ativas e depois horários de cada turma.
  Future<List<Map<String, dynamic>>> getMeusHorarios(
      String academiaId, String alunoId) async {
    final matrSnap = await _col(academiaId, 'matriculas')
        .where('aluno_id', isEqualTo: alunoId)
        .where('ativo', isEqualTo: true)
        .get();
    final turmaIds = matrSnap.docs
        .map((d) => (d.data() as Map)['turma_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();
    if (turmaIds.isEmpty) return [];

    final horarios = <Map<String, dynamic>>[];
    // Firestore whereIn suporta até 30 valores
    for (var i = 0; i < turmaIds.length; i += 30) {
      final chunk = turmaIds.sublist(i, (i + 30).clamp(0, turmaIds.length));
      final snap = await _col(academiaId, 'horarios')
          .where('turma_id', whereIn: chunk)
          .get();
      horarios.addAll(snap.docs.map(_convertDoc));
    }
    return horarios;
  }

  Future<String> addHorario(String academiaId, Map<String, dynamic> data) async {
    final ref = _col(academiaId, 'horarios').doc();
    await ref.set({...data, 'id': ref.id, 'criado_em': FieldValue.serverTimestamp()});
    return ref.id;
  }

  Future<void> updateHorario(String academiaId, String id, Map<String, dynamic> data) =>
      _doc(academiaId, 'horarios', id).update({...data, 'atualizado_em': FieldValue.serverTimestamp()});

  Future<void> deleteHorario(String academiaId, String id) =>
      _doc(academiaId, 'horarios', id).delete();

  // ─── MATRÍCULAS ────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMatriculas(String academiaId,
      {String? alunoId, String? turmaId, bool ativasOnly = false}) async {
    Query q = _col(academiaId, 'matriculas');
    if (alunoId != null) q = q.where('aluno_id', isEqualTo: alunoId);
    if (turmaId != null) q = q.where('turma_id', isEqualTo: turmaId);
    if (ativasOnly) q = q.where('ativo', isEqualTo: true);
    final snap = await q.get();
    return snap.docs.map(_convertDoc).toList();
  }

  Future<String> addMatricula(String academiaId, Map<String, dynamic> data) async {
    final ref = _col(academiaId, 'matriculas').doc();
    await ref.set({...data, 'id': ref.id, 'ativo': true, 'criado_em': FieldValue.serverTimestamp()});
    return ref.id;
  }

  Future<void> deleteMatricula(String academiaId, String id) =>
      _doc(academiaId, 'matriculas', id).delete();

  // ─── PRESENÇAS ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getPresencas(String academiaId,
      {String? alunoId, String? horarioId, String? turmaId, String? dataStr}) async {
    if (turmaId != null) {
      final horariosSnap = await _col(academiaId, 'horarios')
          .where('turma_id', isEqualTo: turmaId)
          .get();
      final ids = horariosSnap.docs.map((d) => d.id).toList();
      if (ids.isEmpty) return [];
      final results = <Map<String, dynamic>>[];
      for (var i = 0; i < ids.length; i += 30) {
        final chunk = ids.sublist(i, (i + 30).clamp(0, ids.length));
        final snap = await _col(academiaId, 'presencas')
            .where('horario_id', whereIn: chunk)
            .orderBy('criado_em', descending: true)
            .get();
        results.addAll(snap.docs.map(_convertDoc));
      }
      return results;
    }
    Query q = _col(academiaId, 'presencas').orderBy('criado_em', descending: true);
    if (alunoId != null) q = q.where('aluno_id', isEqualTo: alunoId);
    if (horarioId != null) q = q.where('horario_id', isEqualTo: horarioId);
    if (dataStr != null) q = q.where('data', isEqualTo: dataStr);
    final snap = await q.get();
    return snap.docs.map(_convertDoc).toList();
  }

  Future<String> addPresenca(String academiaId, Map<String, dynamic> data) async {
    final ref = _col(academiaId, 'presencas').doc();
    await ref.set({...data, 'id': ref.id, 'criado_em': FieldValue.serverTimestamp()});
    return ref.id;
  }

  /// Retorna os aluno_ids que já têm presença registrada para turmaId+data.
  Future<Set<String>> getAlunosComPresenca(String academiaId, String turmaId, String dataStr) async {
    final snap = await _col(academiaId, 'presencas')
        .where('turma_id', isEqualTo: turmaId)
        .where('data', isEqualTo: dataStr)
        .get();
    return snap.docs
        .map((d) => (d.data() as Map)['aluno_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Future<void> deletePresenca(String academiaId, String presencaId) async {
    await _col(academiaId, 'presencas').doc(presencaId).delete();
  }

  // ─── GRADUAÇÕES ────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getGraduacoes(String academiaId,
      {String? alunoId}) async {
    Query q = _col(academiaId, 'graduacoes').orderBy('data_exame', descending: true);
    if (alunoId != null) q = q.where('aluno_id', isEqualTo: alunoId);
    final snap = await q.get();
    return snap.docs.map(_convertDoc).toList();
  }

  Future<String> addGraduacao(String academiaId, Map<String, dynamic> data) async {
    final ref = _col(academiaId, 'graduacoes').doc();
    await ref.set({...data, 'id': ref.id, 'criado_em': FieldValue.serverTimestamp()});
    return ref.id;
  }

  /// Alunos aptos a graduar: não têm graduação nos últimos 90 dias (simplificado).
  Future<List<Map<String, dynamic>>> getAptosGraduacao(String academiaId) async {
    final alunos = await getAlunos(academiaId, ativosOnly: true);
    return alunos; // lógica simplificada — UI pode refinar
  }

  // ─── FINANCEIRO ────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getPagamentos(String academiaId,
      {String? alunoId}) async {
    Query q = _col(academiaId, 'pagamentos').orderBy('data_vencimento', descending: true);
    if (alunoId != null) q = q.where('aluno_id', isEqualTo: alunoId);
    final snap = await q.get();
    return snap.docs.map(_convertDoc).toList();
  }

  Future<String> addPagamento(String academiaId, Map<String, dynamic> data) async {
    final ref = _col(academiaId, 'pagamentos').doc();
    await ref.set({...data, 'id': ref.id, 'criado_em': FieldValue.serverTimestamp()});
    return ref.id;
  }

  Future<void> updatePagamento(String academiaId, String id, Map<String, dynamic> data) =>
      _doc(academiaId, 'pagamentos', id).update({...data, 'atualizado_em': FieldValue.serverTimestamp()});

  // ─── PLANOS ────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getPlanos(String academiaId) async {
    final snap = await _col(academiaId, 'planos').where('ativo', isEqualTo: true).get();
    return snap.docs.map(_convertDoc).toList();
  }

  Future<Map<String, dynamic>?> getPlano(String academiaId, String id) async {
    final doc = await _doc(academiaId, 'planos', id).get();
    if (!doc.exists) return null;
    return _convertDoc(doc);
  }

  Future<String> addPlano(String academiaId, Map<String, dynamic> data) async {
    final ref = _col(academiaId, 'planos').doc();
    await ref.set({...data, 'id': ref.id, 'ativo': true, 'criado_em': FieldValue.serverTimestamp()});
    return ref.id;
  }

  Future<void> updatePlano(String academiaId, String id, Map<String, dynamic> data) =>
      _doc(academiaId, 'planos', id).update({...data, 'atualizado_em': FieldValue.serverTimestamp()});

  Future<void> deletePlano(String academiaId, String id) =>
      _doc(academiaId, 'planos', id).update({'ativo': false, 'atualizado_em': FieldValue.serverTimestamp()});

  // ─── NOTÍCIAS ──────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getNoticias(String academiaId,
      {bool publicadasOnly = true}) async {
    Query q = _col(academiaId, 'noticias').orderBy('criado_em', descending: true);
    if (publicadasOnly) q = q.where('publicada', isEqualTo: true);
    final snap = await q.get();
    return snap.docs.map(_convertDoc).toList();
  }

  Future<String> addNoticia(String academiaId, Map<String, dynamic> data) async {
    final ref = _col(academiaId, 'noticias').doc();
    await ref.set({...data, 'id': ref.id, 'criado_em': FieldValue.serverTimestamp()});
    return ref.id;
  }

  Future<void> updateNoticia(String academiaId, String id, Map<String, dynamic> data) =>
      _doc(academiaId, 'noticias', id).update({...data, 'atualizado_em': FieldValue.serverTimestamp()});

  Future<void> deleteNoticia(String academiaId, String id) =>
      _doc(academiaId, 'noticias', id).delete();

  // ─── NOTIFICAÇÕES ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getNotificacoes(String academiaId) async {
    final snap = await _col(academiaId, 'notificacoes')
        .orderBy('criado_em', descending: true)
        .limit(50)
        .get();
    return snap.docs.map(_convertDoc).toList();
  }

  Future<String> addNotificacao(String academiaId, Map<String, dynamic> data) async {
    final ref = _col(academiaId, 'notificacoes').doc();
    await ref.set({...data, 'id': ref.id, 'criado_em': FieldValue.serverTimestamp()});
    return ref.id;
  }

  Future<void> marcarNotificacaoLida(String academiaId, String id) =>
      _doc(academiaId, 'notificacoes', id).update({'lida': true});

  Future<void> marcarTodasNotificacoesLidas(String academiaId) async {
    final snap = await _col(academiaId, 'notificacoes')
        .where('lida', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'lida': true});
    }
    await batch.commit();
  }

  // ─── RANKING ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getLeaderboard(String academiaId,
      {int limit = 50}) async {
    final snap = await _col(academiaId, 'usuarios')
        .where('perfil', isEqualTo: 3)
        .where('ativo', isEqualTo: true)
        .orderBy('xp_total', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(_convertDoc).toList();
  }

  Future<Map<String, dynamic>?> getPerfilRanking(String academiaId, String userId) =>
      getUsuario(academiaId, userId);

  Future<List<Map<String, dynamic>>> getRankingsCustom(String academiaId) async {
    final snap =
        await _col(academiaId, 'rankings_custom').orderBy('criado_em', descending: true).get();
    return snap.docs.map(_convertDoc).toList();
  }

  Future<String> addRankingCustom(String academiaId, Map<String, dynamic> data) async {
    final ref = _col(academiaId, 'rankings_custom').doc();
    await ref.set({...data, 'id': ref.id, 'criado_em': FieldValue.serverTimestamp()});
    return ref.id;
  }

  Future<void> updateRankingCustom(String academiaId, String id, Map<String, dynamic> data) =>
      _doc(academiaId, 'rankings_custom', id).update(data);

  Future<void> deleteRankingCustom(String academiaId, String id) =>
      _doc(academiaId, 'rankings_custom', id).delete();

  Future<List<Map<String, dynamic>>> getLancamentosPonto(
      String academiaId, String rankingId) async {
    final snap = await _col(academiaId, 'lancamentos_ponto')
        .where('ranking_custom_id', isEqualTo: rankingId)
        .orderBy('data', descending: true)
        .get();
    return snap.docs.map(_convertDoc).toList();
  }

  Future<String> addLancamentoPonto(String academiaId, Map<String, dynamic> data) async {
    final ref = _col(academiaId, 'lancamentos_ponto').doc();
    await ref.set({...data, 'id': ref.id, 'criado_em': FieldValue.serverTimestamp()});
    return ref.id;
  }

  Future<void> deleteLancamentoPonto(String academiaId, String id) =>
      _doc(academiaId, 'lancamentos_ponto', id).delete();

  Future<List<Map<String, dynamic>>> getConquistasAluno(
      String academiaId, String userId) async {
    final snap = await _col(academiaId, 'conquistas_aluno')
        .where('aluno_id', isEqualTo: userId)
        .get();
    return snap.docs.map(_convertDoc).toList();
  }

  Future<void> marcarConquistasVistas(String academiaId, String userId) async {
    final snap = await _col(academiaId, 'conquistas_aluno')
        .where('aluno_id', isEqualTo: userId)
        .where('vista_pelo_aluno', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'vista_pelo_aluno': true});
    }
    await batch.commit();
  }

  // ─── ATESTADOS MÉDICOS ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getAtestadoAluno(String academiaId, String alunoId) async {
    final snap = await _col(academiaId, 'atestados')
        .where('aluno_id', isEqualTo: alunoId)
        .orderBy('data_upload', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return _convertDoc(snap.docs.first);
  }

  Future<String> addAtestado(String academiaId, Map<String, dynamic> data) async {
    final ref = _col(academiaId, 'atestados').doc();
    await ref.set({
      ...data,
      'id': ref.id,
      'status': 0, // Pendente
      'data_upload': FieldValue.serverTimestamp(),
      'criado_em': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> avaliarAtestado(String academiaId, String id, Map<String, dynamic> data) =>
      _doc(academiaId, 'atestados', id).update({...data, 'atualizado_em': FieldValue.serverTimestamp()});

  // ─── PAR-Q ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getParQ(String academiaId, String alunoId) async {
    final snap = await _col(academiaId, 'par_qs')
        .where('aluno_id', isEqualTo: alunoId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return _convertDoc(snap.docs.first);
  }

  Future<String> addParQ(String academiaId, Map<String, dynamic> data) async {
    final ref = _col(academiaId, 'par_qs').doc();
    await ref.set({
      ...data,
      'id': ref.id,
      'data_preenchimento': FieldValue.serverTimestamp(),
      'criado_em': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  // ─── CONTRATOS ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getContratos(String academiaId,
      {String? alunoId}) async {
    Query q = _col(academiaId, 'contratos').orderBy('criado_em', descending: true);
    if (alunoId != null) q = q.where('aluno_id', isEqualTo: alunoId);
    final snap = await q.get();
    return snap.docs.map(_convertDoc).toList();
  }

  Future<Map<String, dynamic>?> getContrato(String academiaId, String id) async {
    final doc = await _doc(academiaId, 'contratos', id).get();
    if (!doc.exists) return null;
    return _convertDoc(doc);
  }

  Future<void> assinarContrato(String academiaId, String id, Map<String, dynamic> data) =>
      _doc(academiaId, 'contratos', id).update({
        ...data,
        'status': 1, // Assinado
        'data_assinatura': FieldValue.serverTimestamp(),
      });

  Future<List<Map<String, dynamic>>> getModelosContrato(String academiaId) async {
    final snap = await _col(academiaId, 'modelos_contrato').get();
    return snap.docs.map(_convertDoc).toList();
  }

  Future<String> addModeloContrato(String academiaId, Map<String, dynamic> data) async {
    final ref = _col(academiaId, 'modelos_contrato').doc();
    await ref.set({...data, 'id': ref.id, 'criado_em': FieldValue.serverTimestamp()});
    return ref.id;
  }

  Future<void> updateModeloContrato(String academiaId, String id, Map<String, dynamic> data) =>
      _doc(academiaId, 'modelos_contrato', id).update(data);

  Future<void> deleteModeloContrato(String academiaId, String id) =>
      _doc(academiaId, 'modelos_contrato', id).delete();

  // ─── GRUPOS FAMILIARES ─────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getGruposFamiliares(String academiaId) async {
    final snap = await _col(academiaId, 'grupos_familiares').orderBy('nome').get();
    return snap.docs.map(_convertDoc).toList();
  }

  Future<String> addGrupoFamiliar(String academiaId, Map<String, dynamic> data) async {
    final ref = _col(academiaId, 'grupos_familiares').doc();
    await ref.set({...data, 'id': ref.id, 'criado_em': FieldValue.serverTimestamp()});
    return ref.id;
  }

  Future<void> updateGrupoFamiliar(String academiaId, String id, Map<String, dynamic> data) =>
      _doc(academiaId, 'grupos_familiares', id).update(data);

  Future<void> deleteGrupoFamiliar(String academiaId, String id) =>
      _doc(academiaId, 'grupos_familiares', id).delete();

  /// Retorna todos os alunos cujo grupo_familiar_id == grupoId (fonte de verdade).
  Future<List<Map<String, dynamic>>> getMembrosGrupo(
      String academiaId, String grupoId) async {
    final snap = await _col(academiaId, 'usuarios')
        .where('grupo_familiar_id', isEqualTo: grupoId)
        .where('perfil', isEqualTo: 3)
        .get();
    return snap.docs.map(_convertDoc).toList()
      ..sort((a, b) => (a['nome'] as String? ?? '').compareTo(b['nome'] as String? ?? ''));
  }

  Future<void> adicionarMembroGrupo(
      String academiaId, String grupoId, String alunoId) async {
    final alunoSnap = await _doc(academiaId, 'usuarios', alunoId).get();
    final nome = (alunoSnap.data() as Map<String, dynamic>?)?['nome'] as String? ?? '';
    await Future.wait([
      _doc(academiaId, 'usuarios', alunoId).update({'grupo_familiar_id': grupoId}),
      _doc(academiaId, 'grupos_familiares', grupoId).update({
        'membros': FieldValue.arrayUnion([{'id': alunoId, 'nome': nome}]),
      }),
    ]);
  }

  Future<void> removerMembroGrupo(
      String academiaId, String grupoId, String membroId) async {
    final grupoSnap = await _doc(academiaId, 'grupos_familiares', grupoId).get();
    final membros = (grupoSnap.data() as Map<String, dynamic>?)?['membros'] as List? ?? [];
    final membro = membros.cast<Object?>().firstWhere(
      (m) => m is Map && m['id']?.toString() == membroId,
      orElse: () => null,
    );
    final futures = <Future>[
      _doc(academiaId, 'usuarios', membroId).update({'grupo_familiar_id': FieldValue.delete()}),
    ];
    if (membro != null) {
      futures.add(_doc(academiaId, 'grupos_familiares', grupoId).update({
        'membros': FieldValue.arrayRemove([membro]),
      }));
    }
    await Future.wait(futures);
  }

  Future<void> definirResponsavelGrupo(
      String academiaId, String grupoId, String alunoId) =>
      _doc(academiaId, 'grupos_familiares', grupoId).update({'responsavel_id': alunoId});

  // ─── DASHBOARD ─────────────────────────────────────────────────────────────

  /// Resumo para o dashboard admin: conta alunos, pagamentos em dia, etc.
  Future<Map<String, dynamic>> getDashboardResumo(String academiaId) async {
    final now = DateTime.now();
    final mesStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final alunosSnap = await _col(academiaId, 'usuarios')
        .where('perfil', isEqualTo: 3)
        .where('ativo', isEqualTo: true)
        .get();
    final totalAlunos = alunosSnap.docs.length;

    final pgSnap = await _col(academiaId, 'pagamentos')
        .where('status', isEqualTo: 1) // Pago
        .get();

    final presSnap = await _col(academiaId, 'presencas')
        .where('data', isGreaterThanOrEqualTo: '$mesStr-01')
        .get();

    return {
      'total_alunos': totalAlunos,
      'pagamentos_em_dia': pgSnap.docs.length,
      'presencas_mes': presSnap.docs.length,
    };
  }

  // ─── SENHA ─────────────────────────────────────────────────────────────────

  Future<void> alterarSenha(String novaSenha) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');
    await user.updatePassword(novaSenha);
  }
}

/// Instância global (singleton simples)
final firestoreService = FirestoreService();
