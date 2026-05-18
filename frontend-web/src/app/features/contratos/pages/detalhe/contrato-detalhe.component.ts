import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { DomSanitizer, SafeHtml } from '@angular/platform-browser';
import { ContratoService } from '../../../../core/services/contrato.service';
import { AlunoService } from '../../../../core/services/aluno.service';
import { ContratoDetalheDto } from '../../../../core/models/contrato.model';

@Component({
  selector: 'app-contrato-detalhe',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './contrato-detalhe.component.html',
})
export class ContratoDetalheComponent implements OnInit {
  private readonly route = inject(ActivatedRoute);
  private readonly contratoService = inject(ContratoService);
  private readonly alunoService = inject(AlunoService);
  private readonly sanitizer = inject(DomSanitizer);

  readonly carregando = signal(true);
  readonly erro = signal('');
  readonly contrato = signal<ContratoDetalheDto | null>(null);
  readonly conteudoSafe = signal<SafeHtml>('');
  readonly telefoneAluno = signal('');
  readonly linkCopiado = signal(false);

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id')!;
    this.contratoService.obter(id).subscribe({
      next: res => {
        if (res.dados) {
          this.contrato.set(res.dados);
          this.conteudoSafe.set(this.sanitizer.bypassSecurityTrustHtml(res.dados.conteudoHtml));
          this.carregarTelefone(res.dados.alunoId);
        } else {
          this.erro.set(res.mensagem ?? 'Contrato não encontrado.');
        }
        this.carregando.set(false);
      },
      error: () => { this.erro.set('Erro ao carregar contrato.'); this.carregando.set(false); },
    });
  }

  private carregarTelefone(alunoId: string): void {
    this.alunoService.getById(alunoId).subscribe({
      next: res => { if (res.dados?.telefone) this.telefoneAluno.set(res.dados.telefone); },
    });
  }

  linkPublico(): string {
    const token = this.contrato()?.tokenPublico;
    return token ? `${window.location.origin}/assinar/${token}` : '';
  }

  enviarWhatsApp(): void {
    const telefone = this.telefoneAluno().replace(/\D/g, '');
    const link = this.linkPublico();
    const texto = encodeURIComponent(`Olá ${this.contrato()?.nomeAluno}, segue o link para assinar seu contrato:\n${link}`);
    window.open(`https://wa.me/55${telefone}?text=${texto}`, '_blank');
  }

  copiarLink(): void {
    navigator.clipboard.writeText(this.linkPublico()).then(() => {
      this.linkCopiado.set(true);
      setTimeout(() => this.linkCopiado.set(false), 2500);
    });
  }

  imprimirContrato(): void {
    const html = this.contrato()?.conteudoHtml ?? '';
    const nomeAcademia = document.title;
    const janela = window.open('', '_blank', 'width=800,height=900');
    if (!janela) return;
    janela.document.write(`<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <title>Contrato</title>
  <style>
    body { font-family: Arial, sans-serif; padding: 40px 60px; font-size: 14px; line-height: 1.7; color: #111; }
    h2 { font-size: 20px; margin-bottom: 12px; }
    h3 { font-size: 15px; margin: 20px 0 8px; }
    p { margin-bottom: 6px; }
    hr { border: none; border-top: 1px solid #ccc; margin: 16px 0; }
  </style>
</head>
<body>${html}</body>
</html>`);
    janela.document.close();
    janela.onload = () => { janela.print(); };
  }

  formatarData(d?: string): string {
    if (!d) return '—';
    return new Date(d).toLocaleString('pt-BR');
  }
}
