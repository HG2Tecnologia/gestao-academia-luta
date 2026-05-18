import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { CatracaService, CatracaValidacaoDto } from '../../core/services/catraca.service';

interface LogEntry {
  hora: string;
  tipo: 'manual' | 'validacao';
  nome: string;
  sucesso: boolean;
  motivo?: string;
  turmaNome?: string;
}

@Component({
  selector: 'app-catraca',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './catraca.component.html',
})
export class CatracaComponent {
  private readonly catracaService = inject(CatracaService);

  readonly abrindo = signal(false);
  readonly ultimaAbertura = signal<string | null>(null);
  readonly log = signal<LogEntry[]>([]);

  readonly buscando = signal(false);
  readonly identificador = signal('');
  readonly resultadoBusca = signal<CatracaValidacaoDto | null>(null);

  abrirManualmente(): void {
    this.abrindo.set(true);
    this.catracaService.abrirManualmente().subscribe({
      next: (res) => {
        const hora = new Date().toLocaleTimeString('pt-BR');
        this.ultimaAbertura.set(hora);
        this.log.update((l) => [
          { hora, tipo: 'manual', nome: res.dados?.operadorNome ?? 'Operador', sucesso: true },
          ...l.slice(0, 19),
        ]);
        this.abrindo.set(false);
      },
      error: () => {
        this.abrindo.set(false);
      },
    });
  }

  buscarAluno(): void {
    if (!this.identificador().trim()) return;
    this.buscando.set(true);
    this.resultadoBusca.set(null);
    this.catracaService.validar(this.identificador()).subscribe({
      next: (res) => {
        const resultado = res.dados ?? null;
        this.resultadoBusca.set(resultado);
        const hora = new Date().toLocaleTimeString('pt-BR');
        this.log.update((l) => [
          {
            hora,
            tipo: 'validacao',
            nome: resultado?.nomeAluno ?? this.identificador(),
            sucesso: resultado?.permitido ?? false,
            motivo: resultado?.motivo ?? undefined,
            turmaNome: resultado?.turmaNome ?? undefined,
          },
          ...l.slice(0, 19),
        ]);
        this.buscando.set(false);
      },
      error: () => {
        this.buscando.set(false);
      },
    });
  }

  limparBusca(): void {
    this.identificador.set('');
    this.resultadoBusca.set(null);
  }
}
