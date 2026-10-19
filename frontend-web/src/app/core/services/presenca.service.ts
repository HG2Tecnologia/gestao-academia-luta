import { Injectable, inject } from '@angular/core';
import { Observable, from, map } from 'rxjs';
import { collection, doc, getDoc, getDocs, addDoc, query, where, serverTimestamp } from 'firebase/firestore';
import { db } from '../firebase/firebase';
import { FirebaseAuthService } from './firebase-auth.service';
import { BaseResponse } from '../models/auth.model';
import {
  PresencaDto,
  RegistrarPresencaRequest,
  PresencaRelatorioDto,
  AlunoFrequenciaDto,
} from '../models/presenca.model';
import { dataLocalISO } from '../utils/date.util';

function ok<T>(dados: T): BaseResponse<T> {
  return { sucesso: true, dados, erros: [] };
}

/** Mesmo mapa real de `metodo_checkin` gravado por `addPresenca` em `firestore_service.dart` (1-4). */
const METODO_CHECKIN_LABEL: Record<string, string> = {
  '1': 'Lista/QR da turma',
  '2': 'Marcado pelo admin',
  '3': 'QR pessoal (escaneado)',
  '4': 'Manual, sem QR',
};

/**
 * Espelho de `academias/{id}/presencas` e de `addPresenca` em
 * `mobile/lib/core/firestore_service.dart` — mesmos campos
 * (snake_case), mesmos valores de `metodo_checkin`. Não replica as
 * regras de bloqueio (`bloqueio_checkin_ativo`, limite de dias/semana)
 * — essas regras continuam só no mobile por ora, o CRM só registra.
 */
@Injectable({ providedIn: 'root' })
export class PresencaService {
  private readonly authService = inject(FirebaseAuthService);

  private get academiaId(): string {
    const id = this.authService.currentUser()?.academiaId;
    if (!id) throw new Error('Sem academia associada à sessão atual.');
    return id;
  }

  registrar(data: RegistrarPresencaRequest): Observable<BaseResponse<PresencaDto>> {
    return from(this.registrarEDevolver(data)).pipe(map((dto) => ok(dto)));
  }

  private async registrarEDevolver(data: RegistrarPresencaRequest): Promise<PresencaDto> {
    const academiaId = this.academiaId;
    const turmaId = await this.resolverTurmaId(academiaId, data.horarioId);
    const agora = new Date();
    const dataStr = data.data ?? dataLocalISO(agora);
    const payload = {
      aluno_id: data.alunoId,
      turma_id: turmaId,
      horario_id: data.horarioId ?? null,
      data: dataStr,
      hora_checkin: agora.toTimeString().slice(0, 8),
      metodo_checkin: data.metodoCheckin,
      confirmado: true,
      observacoes_professor: data.observacoesProfessor ?? null,
      criado_em: serverTimestamp(),
    };
    const [ref, alunoSnap, turmaSnap] = await Promise.all([
      addDoc(collection(db, 'academias', academiaId, 'presencas'), payload),
      getDoc(doc(db, 'academias', academiaId, 'usuarios', data.alunoId)),
      turmaId ? getDoc(doc(db, 'academias', academiaId, 'turmas', turmaId)) : Promise.resolve(null),
    ]);
    return {
      id: ref.id,
      alunoId: data.alunoId,
      nomeAluno: alunoSnap.data()?.['nome'] ?? '',
      horarioId: data.horarioId ?? '',
      nomeTurma: turmaSnap?.data()?.['nome'] ?? '',
      data: dataStr,
      horaCheckin: payload.hora_checkin,
      metodoCheckin: METODO_CHECKIN_LABEL[String(data.metodoCheckin)] ?? String(data.metodoCheckin),
      confirmado: true,
      observacoesProfessor: data.observacoesProfessor,
    };
  }

  private async resolverTurmaId(academiaId: string, horarioId?: string): Promise<string> {
    if (!horarioId) return '';
    const snap = await getDoc(doc(db, 'academias', academiaId, 'horarios', horarioId));
    return String(snap.data()?.['turma_id'] ?? '');
  }

  /**
   * Espelho de `qr_scan_screen.dart`: o QR pessoal do aluno é só a
   * string estática `"{academiaId}:{alunoId}"` — sem token, sem
   * expiração. Resolve a turma "acontecendo agora" a partir das
   * matrículas ativas do aluno + horário de hoje, igual o mobile faz,
   * já que o scanner não sabe de antemão qual aula está em curso.
   */
  registrarQrCode(codigoQr: string): Observable<BaseResponse<PresencaDto>> {
    return from(this.registrarPorQr(codigoQr)).pipe(map((dto) => ok(dto)));
  }

  private async registrarPorQr(codigoQr: string): Promise<PresencaDto> {
    const partes = codigoQr.split(':').filter(Boolean);
    const alunoId = partes.length > 1 ? partes[1] : partes[0];
    if (!alunoId) throw new Error('QR Code inválido.');

    const academiaId = this.academiaId;
    const horarioId = await this.encontrarAulaAgora(academiaId, alunoId);
    if (!horarioId) throw new Error('Nenhuma aula no horário atual para este aluno.');
    return this.registrarEDevolver({ alunoId, horarioId, metodoCheckin: 3 });
  }

  private async encontrarAulaAgora(academiaId: string, alunoId: string): Promise<string | null> {
    const matriculasSnap = await getDocs(
      query(
        collection(db, 'academias', academiaId, 'matriculas'),
        where('aluno_id', '==', alunoId),
        where('ativo', '==', true),
      ),
    );
    const turmaIds = new Set(matriculasSnap.docs.map((d) => String(d.data()['turma_id'] ?? '')));
    if (turmaIds.size === 0) return null;

    const hoje = new Date();
    const diaSemana = hoje.getDay();
    const minutosAgora = hoje.getHours() * 60 + hoje.getMinutes();

    const horariosSnap = await getDocs(collection(db, 'academias', academiaId, 'horarios'));
    let melhorId: string | null = null;
    let melhorDiff = Infinity;
    horariosSnap.forEach((d) => {
      const h = d.data();
      if (!turmaIds.has(String(h['turma_id'] ?? ''))) return;
      if (Number(h['dia_semana'] ?? -1) !== diaSemana) return;
      const [hh, mm] = String(h['hora_inicio'] ?? '0:0').split(':').map((n) => Number(n) || 0);
      const diff = Math.abs(minutosAgora - (hh * 60 + mm));
      if (diff <= 90 && diff < melhorDiff) {
        melhorDiff = diff;
        melhorId = d.id;
      }
    });
    return melhorId;
  }

  getHistorico(alunoId: string, de: string, ate: string): Observable<BaseResponse<PresencaDto[]>> {
    const academiaId = this.academiaId;
    return from(this.carregarComNomeTurma(academiaId, { aluno_id: alunoId })).pipe(
      map((lista) => {
        const filtrada = lista.filter((p) => p.data >= de && p.data <= ate);
        filtrada.sort((a, b) => b.data.localeCompare(a.data) || b.horaCheckin.localeCompare(a.horaCheckin));
        return ok(filtrada);
      }),
    );
  }

  getPresencasAula(horarioId: string, data: string): Observable<BaseResponse<PresencaDto[]>> {
    const academiaId = this.academiaId;
    return from(this.carregarComNomeTurma(academiaId, { horario_id: horarioId, data })).pipe(map((lista) => ok(lista)));
  }

  private async carregarComNomeTurma(academiaId: string, filtros: Record<string, string>): Promise<PresencaDto[]> {
    const presencasRef = collection(db, 'academias', academiaId, 'presencas');
    const constraints = Object.entries(filtros).map(([campo, valor]) => where(campo, '==', valor));
    const [presencasSnap, turmasSnap] = await Promise.all([
      getDocs(query(presencasRef, ...constraints)),
      getDocs(collection(db, 'academias', academiaId, 'turmas')),
    ]);
    const nomeTurmaPorId = new Map<string, string>();
    turmasSnap.forEach((d) => nomeTurmaPorId.set(d.id, d.data()['nome'] ?? ''));
    return presencasSnap.docs.map((d) => this.toDto(d.id, d.data(), nomeTurmaPorId));
  }

  /** Espelho de `montarRelatorioPresencas` em `mobile/lib/core/relatorio_presencas.dart`. */
  getRelatorio(turmaId: string, de: string, ate: string): Observable<BaseResponse<PresencaRelatorioDto>> {
    const academiaId = this.academiaId;
    return from(this.montarRelatorio(academiaId, turmaId, de, ate)).pipe(map((r) => ok(r)));
  }

  private async montarRelatorio(academiaId: string, turmaId: string, de: string, ate: string): Promise<PresencaRelatorioDto> {
    const [presencasSnap, matriculasSnap] = await Promise.all([
      getDocs(query(collection(db, 'academias', academiaId, 'presencas'), where('turma_id', '==', turmaId))),
      getDocs(query(collection(db, 'academias', academiaId, 'matriculas'), where('turma_id', '==', turmaId), where('ativo', '==', true))),
    ]);
    const presencas = presencasSnap.docs.map((d) => d.data()).filter((p) => p['data'] >= de && p['data'] <= ate);

    const diasComAula = new Set(presencas.map((p) => p['data']));
    const totalAulas = diasComAula.size;

    const diasPorAluno = new Map<string, Set<string>>();
    for (const p of presencas) {
      const alunoId = String(p['aluno_id'] ?? '');
      if (!diasPorAluno.has(alunoId)) diasPorAluno.set(alunoId, new Set());
      diasPorAluno.get(alunoId)!.add(p['data']);
    }

    const alunoIds = new Set<string>([
      ...matriculasSnap.docs.map((d) => String(d.data()['aluno_id'] ?? '')),
      ...diasPorAluno.keys(),
    ]);

    const alunos: AlunoFrequenciaDto[] = await Promise.all(
      Array.from(alunoIds)
        .filter(Boolean)
        .map(async (alunoId) => {
          const snap = await getDoc(doc(db, 'academias', academiaId, 'usuarios', alunoId));
          const totalPresencas = diasPorAluno.get(alunoId)?.size ?? 0;
          const faltas = Math.max(0, totalAulas - totalPresencas);
          return {
            alunoId,
            nomeAluno: snap.data()?.['nome'] ?? '',
            presencas: totalPresencas,
            faltas,
            percentual: totalAulas > 0 ? (totalPresencas / totalAulas) * 100 : 0,
          };
        }),
    );
    alunos.sort((a, b) => b.percentual - a.percentual || a.nomeAluno.localeCompare(b.nomeAluno, 'pt-BR'));

    const mediaFrequencia = alunos.length > 0 ? alunos.reduce((s, a) => s + a.percentual, 0) / alunos.length : 0;
    return { totalAulas, mediaFrequencia, alunos };
  }

  private toDto(id: string, p: Record<string, any>, nomeTurmaPorId: Map<string, string>): PresencaDto {
    return {
      id,
      alunoId: p['aluno_id'] ?? '',
      nomeAluno: '',
      horarioId: p['horario_id'] ?? '',
      nomeTurma: nomeTurmaPorId.get(String(p['turma_id'] ?? '')) ?? '',
      data: p['data'] ?? '',
      horaCheckin: p['hora_checkin'] ?? '',
      metodoCheckin: METODO_CHECKIN_LABEL[String(p['metodo_checkin'] ?? '')] ?? String(p['metodo_checkin'] ?? ''),
      confirmado: p['confirmado'] !== false,
      observacoesProfessor: p['observacoes_professor'] ?? undefined,
    };
  }
}
