import { Injectable, inject } from '@angular/core';
import { Observable, from, map } from 'rxjs';
import { collection, doc, getDocs, addDoc, updateDoc, query, where, serverTimestamp } from 'firebase/firestore';
import { db } from '../firebase/firebase';
import { FirebaseAuthService } from './firebase-auth.service';
import { BaseResponse } from '../models/auth.model';
import { PlanoDto, CreatePlanoRequest, UpdatePlanoRequest } from '../models/plano.model';

function ok<T>(dados: T): BaseResponse<T> {
  return { sucesso: true, dados, erros: [] };
}

/**
 * Espelho de `academias/{id}/planos` em `mobile/lib/core/firestore_service.dart`
 * — mesmos campos (`nome`, `descricao`, `valor_mensal`, `ativo`). Exclusão é
 * soft-delete (igual o mobile), e também desvincula qualquer
 * `planos_modalidade`/aluno legado que ainda apontava pro plano apagado —
 * mesma regra que corrigimos no app mobile pra não deixar vínculo órfão.
 */
@Injectable({ providedIn: 'root' })
export class PlanoService {
  private readonly authService = inject(FirebaseAuthService);

  private get academiaId(): string {
    const id = this.authService.currentUser()?.academiaId;
    if (!id) throw new Error('Sem academia associada à sessão atual.');
    return id;
  }

  private async carregarTodos(): Promise<PlanoDto[]> {
    const academiaId = this.academiaId;
    const [planosSnap, usuariosSnap, vinculosSnap] = await Promise.all([
      getDocs(collection(db, 'academias', academiaId, 'planos')),
      getDocs(collection(db, 'academias', academiaId, 'usuarios')),
      getDocs(query(collection(db, 'academias', academiaId, 'planos_modalidade'), where('ativo', '==', true))),
    ]);

    const contagemPorPlano = new Map<string, number>();
    usuariosSnap.forEach((d) => {
      const planoId = d.data()['plano_id'];
      if (planoId) contagemPorPlano.set(planoId, (contagemPorPlano.get(planoId) ?? 0) + 1);
    });
    vinculosSnap.forEach((d) => {
      const planoId = d.data()['plano_id'];
      if (planoId) contagemPorPlano.set(planoId, (contagemPorPlano.get(planoId) ?? 0) + 1);
    });

    return planosSnap.docs.map((d) => {
      const p = d.data();
      return {
        id: d.id,
        nome: p['nome'] ?? '',
        descricao: p['descricao'] ?? undefined,
        valorMensal: (p['valor_mensal'] as number) ?? 0,
        taxaMatricula: p['taxa_matricula'] ?? undefined,
        ativo: p['ativo'] === true,
        totalAlunos: contagemPorPlano.get(d.id) ?? 0,
      };
    });
  }

  listar(): Observable<BaseResponse<PlanoDto[]>> {
    return from(this.carregarTodos()).pipe(
      map((lista) => {
        lista.sort((a, b) => a.nome.localeCompare(b.nome, 'pt-BR'));
        return ok(lista);
      }),
    );
  }

  criar(dto: CreatePlanoRequest): Observable<BaseResponse<PlanoDto>> {
    const academiaId = this.academiaId;
    const payload = {
      nome: dto.nome,
      descricao: dto.descricao ?? null,
      valor_mensal: dto.valorMensal,
      taxa_matricula: dto.taxaMatricula ?? null,
      ativo: true,
      criado_em: serverTimestamp(),
    };
    return from(addDoc(collection(db, 'academias', academiaId, 'planos'), payload)).pipe(
      map((ref) =>
        ok<PlanoDto>({
          id: ref.id,
          nome: dto.nome,
          descricao: dto.descricao,
          valorMensal: dto.valorMensal,
          taxaMatricula: dto.taxaMatricula,
          ativo: true,
          totalAlunos: 0,
        }),
      ),
    );
  }

  atualizar(id: string, dto: UpdatePlanoRequest): Observable<BaseResponse<PlanoDto>> {
    const academiaId = this.academiaId;
    const payload = {
      nome: dto.nome,
      descricao: dto.descricao ?? null,
      valor_mensal: dto.valorMensal,
      taxa_matricula: dto.taxaMatricula ?? null,
      ativo: dto.ativo,
      atualizado_em: serverTimestamp(),
    };
    return from(updateDoc(doc(db, 'academias', academiaId, 'planos', id), payload)).pipe(
      map(() =>
        ok<PlanoDto>({
          id,
          nome: dto.nome,
          descricao: dto.descricao,
          valorMensal: dto.valorMensal,
          taxaMatricula: dto.taxaMatricula,
          ativo: dto.ativo,
          totalAlunos: 0,
        }),
      ),
    );
  }

  /**
   * Soft-delete + desvincula qualquer `planos_modalidade`/aluno legado que
   * ainda apontava pro plano (mesma correção feita no mobile em
   * `firestore_service.dart::_desvincularPlanoExcluido`) — sem isso sobra
   * card órfão mostrando o ID do plano em vez do nome.
   */
  deletar(id: string): Observable<BaseResponse<boolean>> {
    return from(this.excluirComDesvinculo(id)).pipe(map(() => ok(true)));
  }

  private async excluirComDesvinculo(id: string): Promise<void> {
    const academiaId = this.academiaId;
    await updateDoc(doc(db, 'academias', academiaId, 'planos', id), {
      ativo: false,
      atualizado_em: serverTimestamp(),
    });

    const [vinculosSnap, usuariosSnap, cobrancasSnap] = await Promise.all([
      getDocs(query(collection(db, 'academias', academiaId, 'planos_modalidade'), where('plano_id', '==', id), where('ativo', '==', true))),
      getDocs(query(collection(db, 'academias', academiaId, 'usuarios'), where('plano_id', '==', id))),
      // status 0 = Pendente (inclui "Atrasado", que é só um estado derivado, nunca persistido).
      getDocs(query(collection(db, 'academias', academiaId, 'pagamentos'), where('plano_id', '==', id), where('status', '==', 0))),
    ]);
    await Promise.all([
      ...vinculosSnap.docs.map((d) => updateDoc(d.ref, { ativo: false, atualizado_em: serverTimestamp() })),
      ...usuariosSnap.docs.map((d) => updateDoc(d.ref, { plano_id: null, atualizado_em: serverTimestamp() })),
      ...cobrancasSnap.docs.map((d) => updateDoc(d.ref, { status: 4, atualizado_em: serverTimestamp() })),
    ]);
  }
}
