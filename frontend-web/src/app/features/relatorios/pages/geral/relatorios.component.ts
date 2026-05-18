import { Component, inject, signal, computed, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { FinanceiroService } from '../../../../core/services/financeiro.service';
import { RelatorioAnualDto } from '../../../../core/models/financeiro.model';

const MESES = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];

@Component({
  selector: 'app-relatorios',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './relatorios.component.html',
})
export class RelatoriosComponent implements OnInit {
  private readonly financeiroService = inject(FinanceiroService);

  readonly anoAtual = new Date().getFullYear();
  readonly anos = Array.from({ length: 5 }, (_, i) => this.anoAtual - i);
  readonly meses = MESES;

  readonly anoSelecionado = signal(this.anoAtual);
  readonly carregando = signal(true);
  readonly erro = signal('');
  readonly relatorio = signal<RelatorioAnualDto | null>(null);

  readonly maxRecebido = computed(() => {
    const r = this.relatorio();
    if (!r) return 1;
    return Math.max(...r.receitaMensal.flatMap(m => [m.recebido, m.pendente, m.atrasado]), 1);
  });

  readonly maxPresencas = computed(() => {
    const r = this.relatorio();
    if (!r) return 1;
    return Math.max(...r.frequenciaMensal.map(m => m.totalPresencas), 1);
  });

  readonly totalDevido = computed(() =>
    this.relatorio()?.inadimplentes.reduce((s, i) => s + i.totalDevido, 0) ?? 0
  );

  ngOnInit(): void {
    this.carregar();
  }

  carregar(): void {
    this.carregando.set(true);
    this.erro.set('');
    this.financeiroService.getRelatorioAnual(this.anoSelecionado()).subscribe({
      next: (res) => {
        this.relatorio.set(res.dados ?? null);
        this.carregando.set(false);
      },
      error: () => { this.erro.set('Erro ao carregar relatório.'); this.carregando.set(false); },
    });
  }

  onAnoChange(ano: number): void {
    this.anoSelecionado.set(Number(ano));
    this.carregar();
  }

  barH(valor: number, max: number): number {
    return max > 0 ? Math.round((valor / max) * 100) : 0;
  }

  formatarMoeda(valor: number): string {
    return valor.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
  }

  formatarData(d?: string): string {
    if (!d) return '—';
    const [y, m, day] = d.split('-');
    return `${day}/${m}/${y}`;
  }

  exportarCSV(): void {
    const r = this.relatorio();
    if (!r) return;

    const linhas: string[][] = [
      ['Mês', 'Recebido (R$)', 'Pendente (R$)', 'Atrasado (R$)', 'Presenças', 'Alunos únicos'],
    ];
    for (let i = 0; i < 12; i++) {
      const rec = r.receitaMensal[i];
      const freq = r.frequenciaMensal[i];
      linhas.push([
        MESES[i],
        rec.recebido.toFixed(2),
        rec.pendente.toFixed(2),
        rec.atrasado.toFixed(2),
        String(freq.totalPresencas),
        String(freq.alunosUnicos),
      ]);
    }
    linhas.push([]);
    linhas.push(['Inadimplentes', 'Total devido (R$)', 'Dias atraso', 'Último vencimento']);
    for (const ind of r.inadimplentes) {
      linhas.push([ind.nomeAluno, ind.totalDevido.toFixed(2), String(ind.diasAtraso), ind.ultimoVencimento ?? '']);
    }

    const csv = linhas.map(l => l.map(c => `"${c}"`).join(',')).join('\n');
    const blob = new Blob(['﻿' + csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `relatorio-${r.ano}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  }

  imprimirPDF(): void {
    window.print();
  }
}
