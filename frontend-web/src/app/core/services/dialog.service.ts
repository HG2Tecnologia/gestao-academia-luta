import { Injectable, signal } from '@angular/core';

export interface DialogState {
  mensagem: string;
  titulo?: string;
  textoConfirmar: string;
  /** Ausente = modo "alerta" (só um botão, sem opção de cancelar). */
  textoCancelar?: string;
  perigoso?: boolean;
}

export interface DialogOptions {
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
  private resolver: ((v: boolean) => void) | null = null;

  confirm(mensagem: string, opts?: DialogOptions): Promise<boolean> {
    this.state.set({
      mensagem,
      titulo: opts?.titulo,
      textoConfirmar: opts?.textoConfirmar ?? 'Confirmar',
      textoCancelar: opts?.textoCancelar ?? 'Cancelar',
      perigoso: opts?.perigoso,
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
    });
    return new Promise<void>((resolve) => {
      this.resolver = () => resolve();
    });
  }

  resolveWith(valor: boolean): void {
    const resolver = this.resolver;
    this.state.set(null);
    this.resolver = null;
    resolver?.(valor);
  }
}
