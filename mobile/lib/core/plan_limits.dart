import 'package:flutter/material.dart';
import 'firestore_service.dart';
import 'paywall_modal.dart';
import 'plan_service.dart';

const kLimiteTurmasGratuito = 1;
const kLimiteAlunosGratuito = 5;
const kLimiteFuncionariosGratuito = 1;

enum TipoLimitePlano { turma, aluno, funcionario }

/// Checa se a academia ainda tem vaga nesse limite do plano gratuito, lendo
/// os contadores já mantidos pelas Cloud Functions (mesmos campos que as
/// Firestore rules conferem no servidor — essa checagem aqui é só pra dar
/// uma experiência melhor, a trava de verdade é no servidor). Se não tiver
/// vaga (e a academia não for Pro), abre o paywall e devolve `false` — quem
/// chamou não deve prosseguir com a criação.
Future<bool> podeCriarDentroDoPlano(
  BuildContext context, {
  required String academiaId,
  required TipoLimitePlano tipo,
}) async {
  if (PlanService.instance.isPro) return true;

  final academia = await firestoreService.getAcademia(academiaId);
  final (campo, limite) = switch (tipo) {
    TipoLimitePlano.turma => ('turmas_ativas_contagem', kLimiteTurmasGratuito),
    TipoLimitePlano.aluno => ('alunos_ativos_contagem', kLimiteAlunosGratuito),
    TipoLimitePlano.funcionario => (
      'funcionarios_contagem',
      kLimiteFuncionariosGratuito,
    ),
  };
  final atual = (academia?[campo] as num?)?.toInt() ?? 0;
  if (atual < limite) return true;

  if (!context.mounted) return false;
  await mostrarPaywall(context);
  return false;
}
