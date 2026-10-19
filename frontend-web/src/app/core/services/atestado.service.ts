import { Injectable, inject } from '@angular/core';
import { Observable, from, map } from 'rxjs';
import { collection, doc, getDoc, getDocs, addDoc, updateDoc, query, where, orderBy, limit, serverTimestamp } from 'firebase/firestore';
import { db } from '../firebase/firebase';
import { FirebaseAuthService } from './firebase-auth.service';
import { BaseResponse } from '../models/auth.model';
import {
  AtestadoMedicoDto,
  AtestadoMedicoComArquivoDto,
  AvaliarAtestadoRequest,
  UploadAtestadoPorAcademiaRequest,
} from '../models/atestado.model';

function ok<T>(dados: T): BaseResponse<T> {
  return { sucesso: true, dados, erros: [] };
}

/**
 * Espelho de `academias/{id}/atestados` em
 * `mobile/lib/core/firestore_service.dart`. Investigação prévia
 * confirmou uma inconsistência REAL no mobile: quando o aluno envia
 * pelo próprio app, os campos do arquivo vêm em camelCase
 * (`arquivoBase64`/`arquivoMimeType`/`arquivoNome`); quando é a
 * academia que anexa (único caminho que o CRM usa, já que não há
 * login de aluno aqui), são snake_case
 * (`arquivo_base64`/`arquivo_mime_type`/`arquivo_nome`). O CRM
 * sempre ESCREVE no formato snake_case (convenção do admin, e a que
 * prevalece no resto do schema), mas LÊ com fallback pros dois
 * formatos, pra não perder atestados que algum aluno já tenha
 * enviado via mobile antes da academia ter o CRM.
 *
 * Também corrigido, não replicado: no mobile, `motivo_rejeicao` é lido
 * mas nunca de fato escrito em nenhum fluxo (bug confirmado) — aqui o
 * CRM grava esse campo ao rejeitar, o que só melhora a leitura no
 * mobile também (ele já normaliza esse campo ao exibir).
 */
@Injectable({ providedIn: 'root' })
export class AtestadoService {
  private readonly authService = inject(FirebaseAuthService);

  private get academiaId(): string {
    const id = this.authService.currentUser()?.academiaId;
    if (!id) throw new Error('Sem academia associada à sessão atual.');
    return id;
  }

  obterDoAluno(alunoId: string): Observable<BaseResponse<AtestadoMedicoComArquivoDto>> {
    const academiaId = this.academiaId;
    return from(this.carregarMaisRecente(academiaId, alunoId)).pipe(map((dto) => ok(dto as AtestadoMedicoComArquivoDto)));
  }

  private async carregarMaisRecente(academiaId: string, alunoId: string): Promise<AtestadoMedicoComArquivoDto | null> {
    const snap = await getDocs(
      query(collection(db, 'academias', academiaId, 'atestados'), where('aluno_id', '==', alunoId), orderBy('data_upload', 'desc'), limit(1)),
    );
    if (snap.empty) return null;
    const d = snap.docs[0];
    return this.toDto(d.id, d.data());
  }

  private toDto(id: string, a: Record<string, any>): AtestadoMedicoComArquivoDto {
    const dataValidade = a['data_validade'] ?? a['dataValidade'] ?? '';
    const vencendoEmBreve =
      !!dataValidade && new Date(dataValidade).getTime() - Date.now() < 30 * 86400000 && new Date(dataValidade).getTime() > Date.now();
    return {
      id,
      alunoId: a['aluno_id'] ?? '',
      alunoNome: a['aluno_nome'] ?? '',
      status: a['status'] ?? 0,
      motivoRejeicao: a['motivo_rejeicao'] ?? a['motivoRejeicao'] ?? undefined,
      dataUpload: a['data_upload']?.toDate?.()?.toISOString?.() ?? '',
      dataValidade,
      anexadoPorAcademia: a['anexado_por_academia'] === true,
      arquivoMimeType: a['arquivo_mime_type'] ?? a['arquivoMimeType'] ?? '',
      arquivoNome: a['arquivo_nome'] ?? a['arquivoNome'] ?? undefined,
      criadoEm: a['criado_em']?.toDate?.()?.toISOString?.() ?? '',
      vencendoEmBreve,
      arquivoBase64: a['arquivo_base64'] ?? a['arquivoBase64'] ?? '',
    };
  }

  avaliar(id: string, req: AvaliarAtestadoRequest): Observable<BaseResponse<void>> {
    const academiaId = this.academiaId;
    const payload: Record<string, any> = {
      status: req.aprovado ? 1 : 2,
      atualizado_em: serverTimestamp(),
    };
    if (!req.aprovado) payload['motivo_rejeicao'] = req.motivoRejeicao ?? null;
    return from(updateDoc(doc(db, 'academias', academiaId, 'atestados', id), payload)).pipe(map(() => ok(undefined)));
  }

  uploadPorAcademia(req: UploadAtestadoPorAcademiaRequest): Observable<BaseResponse<AtestadoMedicoDto>> {
    const academiaId = this.academiaId;
    return from(this.criarUpload(academiaId, req)).pipe(map((dto) => ok(dto)));
  }

  private async criarUpload(academiaId: string, req: UploadAtestadoPorAcademiaRequest): Promise<AtestadoMedicoDto> {
    const alunoSnap = await getDoc(doc(db, 'academias', academiaId, 'usuarios', req.alunoId));
    const dataValidade = req.dataValidade ?? new Date(Date.now() + 365 * 86400000).toISOString().split('T')[0];
    const payload = {
      aluno_id: req.alunoId,
      aluno_nome: alunoSnap.data()?.['nome'] ?? '',
      academia_id: academiaId,
      arquivo_base64: req.arquivoBase64,
      arquivo_mime_type: req.arquivoMimeType,
      arquivo_nome: req.arquivoNome ?? null,
      anexado_por_academia: true,
      status: 1,
      data_validade: dataValidade,
      data_upload: serverTimestamp(),
      criado_em: serverTimestamp(),
    };
    const ref = await addDoc(collection(db, 'academias', academiaId, 'atestados'), payload);
    return {
      id: ref.id,
      alunoId: req.alunoId,
      alunoNome: payload.aluno_nome,
      status: 1,
      dataUpload: new Date().toISOString(),
      dataValidade,
      anexadoPorAcademia: true,
      arquivoMimeType: req.arquivoMimeType,
      arquivoNome: req.arquivoNome,
      criadoEm: new Date().toISOString(),
      vencendoEmBreve: false,
    };
  }

  /** Não existe canal de lembrete automático pra isso no mobile (nem push, nem e-mail) — aqui só confirma a ação pra UI, sem side-effect real ainda. */
  enviarLembrete(_alunoId: string): Observable<BaseResponse<void>> {
    return from(Promise.resolve()).pipe(map(() => ok(undefined)));
  }
}
