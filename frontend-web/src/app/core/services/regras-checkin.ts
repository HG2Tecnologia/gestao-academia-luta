import { collection, doc, getDoc, getDocs, query, where } from 'firebase/firestore';
import { db } from '../firebase/firebase';
import { dataLocalISO } from '../utils/date.util';

/** Check-in recusado por uma regra da academia — a mensagem vai pra tela. */
export class CheckinBloqueadoError extends Error {}

/**
 * Espelho de `motivoBloqueioCheckin` (`firestore_service.dart`): cadastro
 * inativo ou, se a academia ligou o bloqueio, mensalidade vencida além da
 * carência.
 */
export async function motivoBloqueioCheckin(academiaId: string, alunoId: string): Promise<string | null> {
  const alunoSnap = await getDoc(doc(db, 'academias', academiaId, 'usuarios', alunoId));
  if (!alunoSnap.exists()) return 'Aluno não encontrado.';
  if (alunoSnap.data()['ativo'] === false) return 'Cadastro inativo. Procure a secretaria da academia.';

  const academia = (await getDoc(doc(db, 'academias', academiaId))).data() ?? {};
  if (academia['bloqueio_checkin_ativo'] !== true) return null;

  const carencia = Number(academia['bloqueio_checkin_carencia_dias'] ?? 0);
  const limite = new Date();
  limite.setHours(0, 0, 0, 0);
  limite.setDate(limite.getDate() - carencia);

  const pagamentos = await getDocs(
    query(collection(db, 'academias', academiaId, 'pagamentos'), where('aluno_id', '==', alunoId)),
  );
  for (const d of pagamentos.docs) {
    const p = d.data();
    if (Number(p['status']) === 1) continue;
    const vencimento = lerData(p['data_vencimento'] ?? p['dataVencimento']);
    if (!vencimento || vencimento >= limite) continue;
    const dias = Math.round((limite.getTime() - vencimento.getTime()) / 86400000) + carencia;
    return `Check-in bloqueado: mensalidade vencida há ${dias} dias. Procure a secretaria.`;
  }
  return null;
}

/**
 * Espelho de `_verificarLimiteDiasSemana`: limite de dias por semana do plano.
 * `modo` 'bloqueio' impede o check-in; 'aviso' só avisa.
 */
export async function verificarLimiteDiasSemana(
  academiaId: string,
  alunoId: string,
  turmaId: string,
): Promise<{ modo: string; mensagem: string } | null> {
  if (!turmaId) return null;
  const academia = (await getDoc(doc(db, 'academias', academiaId))).data() ?? {};
  const modo = String(academia['limite_dias_semana_modo'] ?? 'off');
  if (modo === 'off') return null;

  const turma = (await getDoc(doc(db, 'academias', academiaId, 'turmas', turmaId))).data() ?? {};
  const modalidadeId = String(turma['modalidadeId'] ?? turma['modalidade_id'] ?? '');

  let planoId = '';
  if (academia['cobranca_por_modalidade_ativa'] === true && modalidadeId) {
    const vinculos = await getDocs(query(
      collection(db, 'academias', academiaId, 'planos_modalidade'),
      where('aluno_id', '==', alunoId),
      where('modalidade_id', '==', modalidadeId),
      where('ativo', '==', true),
    ));
    planoId = String(vinculos.docs[0]?.data()['plano_id'] ?? '');
  } else {
    const aluno = (await getDoc(doc(db, 'academias', academiaId, 'usuarios', alunoId))).data();
    planoId = String(aluno?.['plano_id'] ?? '');
  }
  if (!planoId) return null;

  const plano = (await getDoc(doc(db, 'academias', academiaId, 'planos', planoId))).data();
  const limite = Number(plano?.['limite_dias_semana'] ?? 0);
  if (limite <= 0) return null;

  const hoje = new Date();
  const segunda = new Date(hoje);
  segunda.setDate(hoje.getDate() - ((hoje.getDay() + 6) % 7));
  const presencas = await getDocs(query(
    collection(db, 'academias', academiaId, 'presencas'),
    where('aluno_id', '==', alunoId),
    where('data', '>=', dataLocalISO(segunda)),
    where('data', '<=', dataLocalISO(hoje)),
  ));

  let contadas = presencas.docs.map((d) => d.data());
  if (modalidadeId) {
    // Só conta presença de turma da mesma modalidade.
    const turmas = await getDocs(collection(db, 'academias', academiaId, 'turmas'));
    const modalidadePorTurma = new Map(
      turmas.docs.map((d) => [d.id, String(d.data()['modalidadeId'] ?? d.data()['modalidade_id'] ?? '')]),
    );
    contadas = contadas.filter((p) => modalidadePorTurma.get(String(p['turma_id'] ?? '')) === modalidadeId);
  }
  const dias = new Set(contadas.map((p) => String(p['data'] ?? '')).filter(Boolean));
  if (dias.size < limite) return null;
  return {
    modo,
    mensagem: `Limite semanal do plano atingido (${limite} dia${limite === 1 ? '' : 's'}/semana). Procure a secretaria da academia.`,
  };
}

/** 'AAAA-MM-DD' é lido como data local (o `new Date` puro leria como UTC). */
function lerData(valor: any): Date | null {
  if (!valor) return null;
  if (typeof valor.toDate === 'function') return valor.toDate();
  const partes = String(valor).match(/^(\d{4})-(\d{2})-(\d{2})/);
  return partes ? new Date(+partes[1], +partes[2] - 1, +partes[3]) : null;
}
