import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentRequestError implements Exception {
  final String message;
  PaymentRequestError(this.message);
  @override
  String toString() => message;
}

class PaymentRequestService {
  static Future<Map<String, dynamic>> criarCobranca({
    required String academiaId,
    required String pagamentoId,
    required double valor,
    required String descricao,
    required String alunoNome,
    String? alunoCpf,
    String? alunoEmail,
    required String billingType,
    Map<String, dynamic>? creditCard,
    Map<String, dynamic>? creditCardHolderInfo,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw PaymentRequestError('Sessão expirada. Faça login novamente.');

    final reqRef = FirebaseFirestore.instance
        .collection('academias')
        .doc(academiaId)
        .collection('cobrancas_req')
        .doc();

    final payload = <String, dynamic>{
      'pagamentoId': pagamentoId,
      'billingType': billingType,
      'valor': valor,
      'descricao': descricao,
      'alunoNome': alunoNome,
      'alunoCpf': alunoCpf ?? '',
      'alunoEmail': alunoEmail ?? '',
      'uid': user.uid,
      'status': 'processing',
      'criadoEm': FieldValue.serverTimestamp(),
    };
    if (creditCard != null) payload['creditCard'] = creditCard;
    if (creditCardHolderInfo != null) payload['creditCardHolderInfo'] = creditCardHolderInfo;

    await reqRef.set(payload);
    return _aguardarResultado(reqRef);
  }

  static Future<Map<String, dynamic>> adminRequest({
    required String academiaId,
    required String tipo,
    Map<String, dynamic>? extra,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw PaymentRequestError('Sessão expirada. Faça login novamente.');

    final reqRef = FirebaseFirestore.instance
        .collection('academias')
        .doc(academiaId)
        .collection('admin_req')
        .doc();

    await reqRef.set({
      'tipo': tipo,
      'uid': user.uid,
      'status': 'processing',
      'criadoEm': FieldValue.serverTimestamp(),
      if (extra != null) ...extra,
    });

    return _aguardarResultado(reqRef);
  }

  static Future<Map<String, dynamic>> _aguardarResultado(DocumentReference ref) {
    final completer = Completer<Map<String, dynamic>>();
    late StreamSubscription<DocumentSnapshot> sub;

    final timer = Timer(const Duration(seconds: 40), () {
      if (!completer.isCompleted) {
        sub.cancel();
        completer.completeError(
          PaymentRequestError('Tempo esgotado. Verifique sua conexão e tente novamente.'),
        );
      }
    });

    sub = ref.snapshots().listen(
      (snap) {
        if (!snap.exists || completer.isCompleted) return;
        final data = snap.data() as Map<String, dynamic>?;
        final status = data?['status'] as String?;

        if (status == 'done') {
          timer.cancel();
          sub.cancel();
          final resultado = data?['resultado'];
          completer.complete(
            resultado is Map ? Map<String, dynamic>.from(resultado) : <String, dynamic>{},
          );
        } else if (status == 'error') {
          timer.cancel();
          sub.cancel();
          completer.completeError(
            PaymentRequestError(data?['erro'] as String? ?? 'Erro desconhecido.'),
          );
        }
      },
      onError: (e) {
        if (!completer.isCompleted) {
          timer.cancel();
          completer.completeError(
            PaymentRequestError('Erro de conexão. Verifique sua internet.'),
          );
        }
      },
    );

    return completer.future;
  }
}
