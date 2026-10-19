import { Injectable, PLATFORM_ID, inject } from '@angular/core';
import { DOCUMENT, isPlatformBrowser } from '@angular/common';
import { ConsentService } from './consent.service';

export type ClassificacaoOrigem = 'identificada' | 'direta_presumida' | 'nao_identificada';

export interface AtribuicaoOrigem {
  classificacao: ClassificacaoOrigem;
  utm_source: string | null;
  utm_medium: string | null;
  utm_campaign: string | null;
  utm_term: string | null;
  utm_content: string | null;
  click_id: string | null;
  click_id_type: 'gclid' | 'gbraid' | 'wbraid' | null;
  referrer_host: string | null;
  capturado_em: string;
}

const STORAGE_KEY = 'sm_attrib_v1';
const PARAMS_CLICK_ID: Array<AtribuicaoOrigem['click_id_type']> = ['gclid', 'gbraid', 'wbraid'];

/**
 * Captura a origem de quem chega no CRM — uma vez, na primeira página
 * carregada da visita — e deixa disponível pro resto da jornada (até o
 * cadastro terminar). Não decide nada de UI: só lê a URL/referrer e
 * resolve se grava (`ConsentService`), igual o `SeoService`/`AnalyticsService`
 * fazem com outras responsabilidades parecidas.
 *
 * Importante: ausência de UTM NUNCA é tratada como "orgânico" — são 3
 * categorias (`identificada` / `direta_presumida` / `nao_identificada`),
 * nunca um rótulo de canal específico que a gente não pode comprovar.
 */
@Injectable({ providedIn: 'root' })
export class AttributionService {
  private readonly document = inject(DOCUMENT);
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));
  private readonly consent = inject(ConsentService);

  private capturado = false;
  /** Classificação da visita atual, em memória, independente de consentimento — só vira persistência (sessionStorage) se/quando houver consentimento. */
  private atribuicaoDaVisita: AtribuicaoOrigem | null = null;

  /** Chamado uma vez no bootstrap (`AppComponent`), depois do `ConsentService.iniciar()`. */
  capturarNaChegada(): void {
    if (this.capturado || !this.isBrowser) return;
    this.capturado = true;

    // Já existe uma captura desta sessão (ex.: navegou de /?utm=... pra
    // /cadastro) — não recaptura e não apaga o que já tinha, mesmo que a
    // página atual não tenha nenhum parâmetro.
    if (this.lerDoStorage()) return;

    this.atribuicaoDaVisita = this.classificar();
    this.persistirSeConsentido(this.atribuicaoDaVisita);
  }

  /**
   * Chamado pelo `AppComponent` sempre que `analytics_storage` passa a
   * `granted` (ex.: usuário aceitou o banner alguns segundos depois de
   * chegar) — sem isso, a classificação real da visita (com UTM/gclid) se
   * perderia porque `capturarNaChegada()` só roda uma vez.
   */
  persistirAposConsentimento(): void {
    if (!this.isBrowser || !this.atribuicaoDaVisita || this.lerDoStorage()) return;
    this.persistirSeConsentido(this.atribuicaoDaVisita);
  }

  /**
   * Chamado pelo `CadastroComponent` depois que `cadastrarAcademia()`
   * confirma sucesso. O que foi capturado no navegador é só uma PROPOSTA —
   * a Cloud Function `registrarAtribuicaoCadastro` decide de verdade o que
   * grava, validando que quem chama é o próprio dono da academia recém
   * criada (ver `functions/attribution-functions.js`). Erros aqui nunca
   * devem travar o cadastro em si — por isso engole a falha.
   *
   * Importa o SDK de Functions dinamicamente, não no topo do arquivo: este
   * service é injetado eager no `AppComponent` (pra capturar atribuição já
   * na home), e um import estático do Firebase Functions aqui colocaria o
   * SDK inteiro de volta no bundle inicial — o mesmo problema que os guards
   * de rota já resolveram com `import()` dinâmico (ver `app.routes.ts`).
   */
  async registrarNoCadastro(academiaId: string): Promise<void> {
    if (!this.isBrowser) return;
    const atribuicao = this.lerDoStorage();
    if (!atribuicao) return;
    try {
      const [{ httpsCallable }, { functions }] = await Promise.all([
        import('firebase/functions'),
        import('../firebase/firebase'),
      ]);
      const registrar = httpsCallable(functions, 'registrarAtribuicaoCadastro');
      await registrar({
        academiaId,
        atribuicao,
        // A function não confia só em "o cliente decidiu chamar" como
        // prova de consentimento — exige essa declaração explícita.
        consentimentoAnalytics: this.consent.estado().analytics_storage === 'granted',
      });
    } catch (erro) {
      // Nunca propaga — atribuição é complementar ao cadastro, não pode
      // bloquear a criação da academia. Mas registra no console pra não
      // mascarar diagnóstico (ex.: function não deployada ainda, regra do
      // Firestore rejeitando, academia fora da janela de 30min).
      console.warn('[AttributionService] Falha ao registrar atribuição do cadastro:', erro);
    }
  }

  private classificar(): AtribuicaoOrigem {
    const url = new URL(this.document.location.href);
    const params = url.searchParams;

    const utm_source = params.get('utm_source');
    const utm_medium = params.get('utm_medium');
    const utm_campaign = params.get('utm_campaign');
    const utm_term = params.get('utm_term');
    const utm_content = params.get('utm_content');

    let click_id: string | null = null;
    let click_id_type: AtribuicaoOrigem['click_id_type'] = null;
    for (const tipo of PARAMS_CLICK_ID) {
      const valor = params.get(tipo!);
      if (valor) {
        click_id = valor;
        click_id_type = tipo;
        break;
      }
    }

    const referrer = this.document.referrer || '';
    let referrerHost: string | null = null;
    let referrerExterno = false;
    if (referrer) {
      try {
        const referrerUrl = new URL(referrer);
        referrerHost = referrerUrl.hostname;
        referrerExterno = referrerHost !== this.document.location.hostname;
      } catch {
        // referrer malformado/opaco — trata como ausente, não como externo confiável
      }
    }

    const temParametro = Boolean(utm_source || utm_medium || utm_campaign || click_id);

    let classificacao: ClassificacaoOrigem;
    if (temParametro || referrerExterno) {
      // Parâmetro de campanha OU referência de outro domínio (ex.: veio de
      // um link na HG2, mesmo sem UTM) — origem rastreável.
      classificacao = 'identificada';
    } else if (!referrer) {
      // Sem parâmetro, sem referrer nenhum — acesso direto presumido (URL
      // digitada, favorito, app). "Presumido" porque navegadores/extensões
      // também apagam o referrer por privacidade — não dá pra ter certeza.
      classificacao = 'direta_presumida';
    } else {
      // Tem referrer mas é do próprio domínio, ou não foi possível
      // interpretar — não temos como afirmar nem "direto" nem "identificada".
      classificacao = 'nao_identificada';
    }

    return {
      classificacao,
      utm_source,
      utm_medium,
      utm_campaign,
      utm_term,
      utm_content,
      click_id,
      click_id_type,
      referrer_host: referrerExterno ? referrerHost : null,
      capturado_em: new Date().toISOString(),
    };
  }

  private persistirSeConsentido(atribuicao: AtribuicaoOrigem): void {
    if (this.consent.estado().analytics_storage !== 'granted') return;
    try {
      sessionStorage.setItem(STORAGE_KEY, JSON.stringify(atribuicao));
    } catch {
      // storage bloqueado — segue sem atribuição persistida, sem quebrar nada
    }
  }

  private lerDoStorage(): AtribuicaoOrigem | null {
    try {
      const bruto = sessionStorage.getItem(STORAGE_KEY);
      return bruto ? JSON.parse(bruto) : null;
    } catch {
      return null;
    }
  }
}
