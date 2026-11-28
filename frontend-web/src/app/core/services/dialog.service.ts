import { Injectable, signal } from '@angular/core';

export interface DialogState {
  mensagem: string;
  titulo?: string;
  textoConfirmar: string;
  /** Ausente = modo "alerta" (só um botão, sem opção de cancelar). */
  textoCancelar?: string;
  perigoso?: boolean;
  /** Valor em destaque com botão "Copiar" (ex.: senha temporária). */
  copiavel?: string;
  textoParaCopiar?: string;
  /** Segunda ação, além de confirmar e cancelar. */
  textoAlternativo?: string;
}

export type DialogEscolha = 'confirmar' | 'alternativa' | 'cancelar';

export interface DialogOptions {
  copiavel?: string;
  textoParaCopiar?: string;
  textoAlternativo?: string;
  titulo?: string;
  textoConfirmar?: string;
  textoCancelar?: string;
  perigoso?: boolean;
}

/**
 * Substitui `window.confirm`/`window.alert` por um modal próprio do
 * sistema (o CRM não pode depender de diálogos nativos do navegador).
 * Renderizado uma única vez em `ShellComponent`, controlado por um
 * signal global — qualquer componente injeta este service e usa
 * `await dialog.confirm(...)` no lugar de `confirm(...)`.
 */
@Injectable({ providedIn: 'root' })
export class DialogService {
  readonly state = signal<DialogState | null>(null);
  private resolver: ((v: DialogEscolha) => void) | null = null;

  confirm(mensagem: string, opts?: DialogOptions): Promise<boolean> {
    this.state.set({
      mensagem,
      titulo: opts?.titulo,
      textoConfirmar: opts?.textoConfirmar ?? 'Confirmar',
      textoCancelar: opts?.textoCancelar ?? 'Cancelar',
      perigoso: opts?.perigoso,
    });
    return new Promise((resolve) => {
      this.resolver = (v) => resolve(v === 'confirmar');
    });
  }

  /** Confirmação com duas ações possíveis, além de cancelar. */
  escolher(mensagem: string, opts: DialogOptions & { textoAlternativo: string }): Promise<DialogEscolha> {
    this.state.set({
      mensagem,
      titulo: opts.titulo,
      textoConfirmar: opts.textoConfirmar ?? 'Confirmar',
      textoAlternativo: opts.textoAlternativo,
      textoCancelar: opts.textoCancelar ?? 'Cancelar',
    });
    return new Promise((resolve) => {
      this.resolver = resolve;
    });
  }

  alert(mensagem: string, opts?: Omit<DialogOptions, 'textoCancelar'>): Promise<void> {
    this.state.set({
      mensagem,
      titulo: opts?.titulo,
      textoConfirmar: opts?.textoConfirmar ?? 'OK',
      textoCancelar: undefined,
      perigoso: opts?.perigoso,
      copiavel: opts?.copiavel,
      textoParaCopiar: opts?.textoParaCopiar,
    });
    return new Promise<void>((resolve) => {
      this.resolver = () => resolve();
    });
  }

  resolveWith(valor: boolean | DialogEscolha): void {
    const resolver = this.resolver;
    this.state.set(null);
    this.resolver = null;
    resolver?.(valor === true ? 'confirmar' : valor === false ? 'cancelar' : valor);
  }
}
