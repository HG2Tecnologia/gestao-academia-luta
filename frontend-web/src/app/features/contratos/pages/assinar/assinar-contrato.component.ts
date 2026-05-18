import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute } from '@angular/router';
import { Title } from '@angular/platform-browser';
import { DomSanitizer, SafeHtml } from '@angular/platform-browser';
import { ContratoService } from '../../../../core/services/contrato.service';
import { ContratoPublicoDto } from '../../../../core/models/contrato.model';

@Component({
  selector: 'app-assinar-contrato',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './assinar-contrato.component.html',
})
export class AssinarContratoComponent implements OnInit {
  private readonly route = inject(ActivatedRoute);
  private readonly contratoService = inject(ContratoService);
  private readonly sanitizer = inject(DomSanitizer);
  private readonly titleService = inject(Title);

  readonly carregando = signal(true);
  readonly erro = signal('');
  readonly contrato = signal<ContratoPublicoDto | null>(null);
  readonly conteudoSafe = signal<SafeHtml>('');

  readonly nomeCompleto = signal('');
  readonly aceito = signal(false);
  readonly assinando = signal(false);
  readonly erroAssinatura = signal('');
  readonly assinado = signal(false);

  ngOnInit(): void {
    const token = this.route.snapshot.paramMap.get('token')!;
    this.contratoService.obterPublico(token).subscribe({
      next: res => {
        if (res.dados) {
          this.contrato.set(res.dados);
          this.conteudoSafe.set(this.sanitizer.bypassSecurityTrustHtml(res.dados.conteudoHtml));
          this.titleService.setTitle(`Assinatura de Contrato — ${res.dados.nomeAcademia}`);
          if (res.dados.status !== 1) this.erro.set('');
        } else {
          this.erro.set(res.mensagem ?? 'Contrato não encontrado.');
        }
        this.carregando.set(false);
      },
      error: () => { this.erro.set('Contrato não encontrado ou link inválido.'); this.carregando.set(false); },
    });
  }

  confirmarAssinatura(): void {
    if (!this.aceito()) { this.erroAssinatura.set('Você precisa marcar que leu e concorda.'); return; }
    if (!this.nomeCompleto().trim()) { this.erroAssinatura.set('Informe seu nome completo.'); return; }
    const token = this.route.snapshot.paramMap.get('token')!;
    this.assinando.set(true);
    this.erroAssinatura.set('');
    this.contratoService.assinarPublico(token, { nomeCompleto: this.nomeCompleto() }).subscribe({
      next: res => {
        this.assinando.set(false);
        if (res.sucesso) {
          this.assinado.set(true);
        } else {
          this.erroAssinatura.set(res.mensagem ?? 'Erro ao assinar.');
        }
      },
      error: err => { this.assinando.set(false); this.erroAssinatura.set(err.error?.mensagem ?? 'Erro ao assinar.'); },
    });
  }

  wppAssinadoLink(): string {
    const msg = encodeURIComponent('Olá! Acabei de assinar meu contrato digitalmente. 📄✅');
    return `https://wa.me/?text=${msg}`;
  }

  formatarData(d?: string): string {
    if (!d) return '—';
    return new Date(d).toLocaleString('pt-BR');
  }
}
