import { Injectable, inject } from '@angular/core';
import { Observable, from, map } from 'rxjs';
import {
  collection,
  doc,
  getDoc,
  getDocs,
  addDoc,
  updateDoc,
  deleteDoc,
  query,
  where,
  serverTimestamp,
} from 'firebase/firestore';
import { db } from '../firebase/firebase';
import { FirebaseAuthService } from './firebase-auth.service';
import {
  ConquistaDto,
  LancamentoPontoDto,
  LeaderboardCustomDto,
  LeaderboardCustomItemDto,
  LeaderboardDto,
  LeaderboardItemDto,
  PerfilGamificadoDto,
  RankingCustomDto,
} from '../models/ranking.model';

const PAGE_SIZE = 20;

/**
 * Espelho de `academias/{id}/rankings_custom` e `lancamentos_ponto`
 * em `mobile/lib/core/firestore_service.dart`. O "ranking geral"
 * (XP/nível/conquistas) existe no schema mas é, na prática, vestigial
 * no app mobile: só há UM ponto em todo o código que incrementa XP
 * (recompensa por responder pesquisa de satisfação em
 * `aluno_perfil_screen.dart`), `nivel` nunca é recalculado a partir do
 * XP, e a collection `conquistas_aluno` nunca é escrita por nenhuma
 * regra — só é lida. Por isso aqui a aba geral lê os campos reais
 * (`xp_total`/`xp_mensal`/`nivel`) honestamente esparsos, em vez de
 * fabricar um motor de gamificação que não existe no Firestore.
 *
 * Bug conhecido do mobile, corrigido aqui: os 3 pontos de escrita de
 * `lancamentos_ponto` gravam o campo `ranking_id`, mas a leitura no
 * mobile (`getLancamentosPonto`) filtra por `ranking_custom_id` —
 * então o leaderboard de ranking customizado nunca encontra nada lá.
 * Aqui filtramos por `ranking_id` (o campo que de fato é gravado).
 */
@Injectable({ providedIn: 'root' })
export class RankingService {
  private readonly authService = inject(FirebaseAuthService);

  private get academiaId(): string {
    const id = this.authService.currentUser()?.academiaId;
    if (!id) throw new Error('Sem academia associada à sessão atual.');
    return id;
  }

  // ── Ranking geral (XP) ───────────────────────────────────────────

  getLeaderboardAcademia(periodo: 'mensal' | 'historico', pagina = 1): Observable<LeaderboardDto> {
    return from(this.montarLeaderboardGeral(periodo, pagina));
  }

  getLeaderboardTurma(turmaId: string, periodo: 'mensal' | 'historico', pagina = 1): Observable<LeaderboardDto> {
    return from(this.montarLeaderboardGeral(periodo, pagina, turmaId));
  }

  private async montarLeaderboardGeral(periodo: 'mensal' | 'historico', pagina: number, turmaId?: string): Promise<LeaderboardDto> {
    const academiaId = this.academiaId;
    let alunoIdsPermitidos: Set<string> | null = null;
    if (turmaId) {
      const matriculasSnap = await getDocs(
        query(collection(db, 'academias', academiaId, 'matriculas'), where('turma_id', '==', turmaId), where('ativo', '==', true)),
      );
      alunoIdsPermitidos = new Set(matriculasSnap.docs.map((d) => String(d.data()['aluno_id'] ?? '')));
    }

    const usuariosSnap = await getDocs(
      query(collection(db, 'academias', academiaId, 'usuarios'), where('perfil', '==', 3), where('ativo', '==', true)),
    );
    const campoXp = periodo === 'mensal' ? 'xp_mensal' : 'xp_total';
    const todos = usuariosSnap.docs
      .filter((d) => !alunoIdsPermitidos || alunoIdsPermitidos.has(d.id))
      .map((d) => {
        const a = d.data();
        return {
          posicao: 0,
          alunoId: d.id,
          nomeAluno: a['nome'] ?? '',
          avatarUrl: a['avatar_url'] ?? undefined,
          nivel: String(a['nivel'] ?? '0'),
          xpPeriodo: a[campoXp] ?? 0,
          xpTotal: a['xp_total'] ?? 0,
          totalConquistas: 0,
          variacao: 0,
        } satisfies LeaderboardItemDto;
      });
    todos.sort((a, b) => b.xpPeriodo - a.xpPeriodo);
    todos.forEach((item, i) => (item.posicao = i + 1));

    const totalParticipantes = todos.length;
    const totalPaginas = Math.max(1, Math.ceil(totalParticipantes / PAGE_SIZE));
    const inicio = (pagina - 1) * PAGE_SIZE;
    return {
      periodo,
      totalParticipantes,
      pagina,
      tamanhoPagina: PAGE_SIZE,
      totalPaginas,
      items: todos.slice(inicio, inicio + PAGE_SIZE),
    };
  }

  getPerfilGamificado(alunoId: string): Observable<PerfilGamificadoDto> {
    return from(this.montarPerfilGamificado(alunoId));
  }

  private async montarPerfilGamificado(alunoId: string): Promise<PerfilGamificadoDto> {
    const academiaId = this.academiaId;
    const [snap, geral, conquistas] = await Promise.all([
      getDoc(doc(db, 'academias', academiaId, 'usuarios', alunoId)),
      this.montarLeaderboardGeral('historico', 1),
      this.carregarConquistas(alunoId),
    ]);
    const a = snap.data() ?? {};
    const posicaoGlobal = geral.items.find((i) => i.alunoId === alunoId)?.posicao ?? 0;
    return {
      alunoId,
      nome: a['nome'] ?? '',
      nivel: String(a['nivel'] ?? '0'),
      xpTotal: a['xp_total'] ?? 0,
      xpMensal: a['xp_mensal'] ?? 0,
      xpParaProximoNivel: 0,
      posicaoGlobal,
      posicaoTurma: 0,
      sequenciaAtual: 0,
      conquistasDesbloqueadas: conquistas,
      historicoXp: [],
    };
  }

  getConquistas(alunoId: string): Observable<ConquistaDto[]> {
    return from(this.carregarConquistas(alunoId));
  }

  private async carregarConquistas(alunoId: string): Promise<ConquistaDto[]> {
    const academiaId = this.academiaId;
    const snap = await getDocs(query(collection(db, 'academias', academiaId, 'conquistas_aluno'), where('aluno_id', '==', alunoId)));
    return snap.docs.map((d) => {
      const c = d.data();
      return {
        id: d.id,
        tipo: c['tipo'] ?? '',
        nome: c['nome'] ?? '',
        descricao: c['descricao'] ?? '',
        iconeUrl: c['icone_url'] ?? '',
        pontosXpBonus: c['pontos_xp_bonus'] ?? 0,
        desbloqueada: true,
        desbloqueadaEm: c['desbloqueada_em'] ?? c['criado_em']?.toDate?.()?.toISOString?.(),
      } as ConquistaDto;
    });
  }

  marcarConquistasVistas(alunoId: string): Observable<void> {
    const academiaId = this.academiaId;
    return from(this.marcarVistas(academiaId, alunoId)).pipe(map(() => undefined));
  }

  private async marcarVistas(academiaId: string, alunoId: string): Promise<void> {
    const snap = await getDocs(query(collection(db, 'academias', academiaId, 'conquistas_aluno'), where('aluno_id', '==', alunoId)));
    await Promise.all(snap.docs.map((d) => updateDoc(d.ref, { vista: true })));
  }

  // ── Rankings customizados ────────────────────────────────────────

  listarRankingsCustom(incluirInativos = false): Observable<RankingCustomDto[]> {
    const academiaId = this.academiaId;
    return from(getDocs(collection(db, 'academias', academiaId, 'rankings_custom'))).pipe(
      map((snap) => {
        let lista = snap.docs.map((d) => this.rankingDto(d.id, d.data()));
        if (!incluirInativos) lista = lista.filter((r) => r.ativo);
        lista.sort((a, b) => b.criadoEm.localeCompare(a.criadoEm));
        return lista;
      }),
    );
  }

  criarRankingCustom(req: Partial<RankingCustomDto>): Observable<RankingCustomDto> {
    const academiaId = this.academiaId;
    const payload = {
      nome: req.nome,
      descricao: req.descricao ?? null,
      incluirPresencas: req.incluirPresencas ?? true,
      incluirPontosManuais: req.incluirPontosManuais ?? true,
      pesoPresencas: req.pesoPresencas ?? 1,
      pesoManuais: req.pesoManuais ?? 1,
      visivelParaAluno: req.visivelParaAluno ?? true,
      dataInicio: req.dataInicio ?? null,
      dataFim: req.dataFim ?? null,
      ativo: true,
      criado_em: serverTimestamp(),
    };
    return from(addDoc(collection(db, 'academias', academiaId, 'rankings_custom'), payload)).pipe(
      map((ref) => this.rankingDto(ref.id, { ...payload, criado_em: { toDate: () => new Date() } })),
    );
  }

  atualizarRankingCustom(id: string, req: Partial<RankingCustomDto>): Observable<RankingCustomDto> {
    const academiaId = this.academiaId;
    const payload = {
      nome: req.nome,
      descricao: req.descricao ?? null,
      incluirPresencas: req.incluirPresencas ?? true,
      incluirPontosManuais: req.incluirPontosManuais ?? true,
      pesoPresencas: req.pesoPresencas ?? 1,
      pesoManuais: req.pesoManuais ?? 1,
      visivelParaAluno: req.visivelParaAluno ?? true,
      dataInicio: req.dataInicio ?? null,
      dataFim: req.dataFim ?? null,
    };
    return from(updateDoc(doc(db, 'academias', academiaId, 'rankings_custom', id), payload)).pipe(
      map(() => this.rankingDto(id, { ...payload, criado_em: { toDate: () => new Date() } })),
    );
  }

  /** Mesmo comportamento real do mobile: "desativar" apaga o doc de fato (não é soft-delete, apesar do nome na UI). */
  desativarRankingCustom(id: string): Observable<void> {
    const academiaId = this.academiaId;
    return from(deleteDoc(doc(db, 'academias', academiaId, 'rankings_custom', id))).pipe(map(() => undefined));
  }

  getLeaderboardCustom(id: string, pagina = 1): Observable<LeaderboardCustomDto> {
    return from(this.montarLeaderboardCustom(id, pagina));
  }

  private async montarLeaderboardCustom(id: string, pagina: number): Promise<LeaderboardCustomDto> {
    const academiaId = this.academiaId;
    const [rankingSnap, lancamentosSnap] = await Promise.all([
      getDoc(doc(db, 'academias', academiaId, 'rankings_custom', id)),
      getDocs(query(collection(db, 'academias', academiaId, 'lancamentos_ponto'), where('ranking_id', '==', id))),
    ]);
    const r = rankingSnap.data() ?? {};

    const porAluno = new Map<string, LeaderboardCustomItemDto>();
    lancamentosSnap.forEach((d) => {
      const l = d.data();
      const alunoId = String(l['aluno_id'] ?? '');
      if (!alunoId) return;
      if (!porAluno.has(alunoId)) {
        porAluno.set(alunoId, {
          posicao: 0,
          alunoId,
          nomeAluno: l['nome_aluno'] ?? '',
          pontosPresencas: 0,
          pontosManuais: 0,
          totalPontos: 0,
        });
      }
      const item = porAluno.get(alunoId)!;
      const pontos = l['pontos'] ?? 0;
      if (l['tipo'] === 'presenca') item.pontosPresencas += pontos;
      else item.pontosManuais += pontos;
      item.totalPontos += pontos;
    });

    const itens = Array.from(porAluno.values()).sort((a, b) => b.totalPontos - a.totalPontos);
    itens.forEach((item, i) => (item.posicao = i + 1));

    const totalPaginas = Math.max(1, Math.ceil(itens.length / PAGE_SIZE));
    const inicio = (pagina - 1) * PAGE_SIZE;
    return {
      rankingId: id,
      nomeRanking: r['nome'] ?? '',
      descricao: r['descricao'] ?? undefined,
      incluirPresencas: r['incluirPresencas'] === true,
      incluirPontosManuais: r['incluirPontosManuais'] === true,
      pesoPresencas: r['pesoPresencas'] ?? 1,
      pesoManuais: r['pesoManuais'] ?? 1,
      dataInicio: r['dataInicio'] ?? undefined,
      dataFim: r['dataFim'] ?? undefined,
      totalParticipantes: itens.length,
      pagina,
      tamanhoPagina: PAGE_SIZE,
      totalPaginas,
      items: itens.slice(inicio, inicio + PAGE_SIZE),
    };
  }

  listarLancamentos(rankingId: string, alunoId?: string): Observable<LancamentoPontoDto[]> {
    const academiaId = this.academiaId;
    const constraints = [where('ranking_id', '==', rankingId)];
    if (alunoId) constraints.push(where('aluno_id', '==', alunoId));
    return from(getDocs(query(collection(db, 'academias', academiaId, 'lancamentos_ponto'), ...constraints))).pipe(
      map((snap) => {
        const lista = snap.docs.map((d) => this.lancamentoDto(d.id, d.data()));
        lista.sort((a, b) => b.criadoEm.localeCompare(a.criadoEm));
        return lista;
      }),
    );
  }

  lancarPontos(
    rankingId: string,
    req: { alunoId: string; pontos: number; descricao?: string; data?: string },
  ): Observable<LancamentoPontoDto> {
    return from(this.registrarLancamento(rankingId, req)).pipe(map((dto) => dto));
  }

  private async registrarLancamento(
    rankingId: string,
    req: { alunoId: string; pontos: number; descricao?: string; data?: string },
  ): Promise<LancamentoPontoDto> {
    const academiaId = this.academiaId;
    const user = this.authService.currentUser();
    const alunoSnap = await getDoc(doc(db, 'academias', academiaId, 'usuarios', req.alunoId));
    const payload = {
      aluno_id: req.alunoId,
      nome_aluno: alunoSnap.data()?.['nome'] ?? '',
      ranking_id: rankingId,
      pontos: req.pontos,
      descricao: req.descricao ?? '',
      tipo: 'manual',
      registrado_por: user?.id ?? '',
      nome_registrado_por: user?.nome ?? '',
      data: req.data ?? new Date().toISOString(),
      criado_em: serverTimestamp(),
    };
    const ref = await addDoc(collection(db, 'academias', academiaId, 'lancamentos_ponto'), payload);
    return this.lancamentoDto(ref.id, { ...payload, criado_em: { toDate: () => new Date() } });
  }

  removerLancamento(lancamentoId: string): Observable<void> {
    const academiaId = this.academiaId;
    return from(deleteDoc(doc(db, 'academias', academiaId, 'lancamentos_ponto', lancamentoId))).pipe(map(() => undefined));
  }

  // ── Helpers ───────────────────────────────────────────────────────

  private rankingDto(id: string, r: Record<string, any>): RankingCustomDto {
    return {
      id,
      nome: r['nome'] ?? '',
      descricao: r['descricao'] ?? undefined,
      incluirPresencas: r['incluirPresencas'] === true,
      incluirPontosManuais: r['incluirPontosManuais'] === true,
      pesoPresencas: r['pesoPresencas'] ?? 1,
      pesoManuais: r['pesoManuais'] ?? 1,
      visivelParaAluno: r['visivelParaAluno'] === true,
      ativo: r['ativo'] !== false,
      dataInicio: r['dataInicio'] ?? undefined,
      dataFim: r['dataFim'] ?? undefined,
      criadoEm: r['criado_em']?.toDate?.()?.toISOString?.() ?? new Date().toISOString(),
    };
  }

  private lancamentoDto(id: string, l: Record<string, any>): LancamentoPontoDto {
    return {
      id,
      alunoId: l['aluno_id'] ?? '',
      nomeAluno: l['nome_aluno'] ?? '',
      pontos: l['pontos'] ?? 0,
      descricao: l['descricao'] ?? undefined,
      nomeRegistradoPor: l['nome_registrado_por'] ?? '',
      data: l['data'] ?? '',
      criadoEm: l['criado_em']?.toDate?.()?.toISOString?.() ?? '',
    };
  }
}
