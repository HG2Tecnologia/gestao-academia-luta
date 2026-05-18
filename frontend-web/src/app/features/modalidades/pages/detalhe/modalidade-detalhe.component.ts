import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink, ActivatedRoute, Router } from '@angular/router';
import { forkJoin } from 'rxjs';
import { ModalidadeService, ModalidadeDto } from '../../../../core/services/modalidade.service';
import { GraduacaoService } from '../../../../core/services/graduacao.service';
import { TurmaService } from '../../../../core/services/turma.service';
import { FaixaDto } from '../../../../core/models/graduacao.model';
import { TurmaDto } from '../../../../core/models/turma.model';

@Component({
  selector: 'app-modalidade-detalhe',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './modalidade-detalhe.component.html',
})
export class ModalidadeDetalheComponent implements OnInit {
  private readonly modalidadeService = inject(ModalidadeService);
  private readonly graduacaoService = inject(GraduacaoService);
  private readonly turmaService = inject(TurmaService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);

  readonly modalidade = signal<ModalidadeDto | null>(null);
  readonly faixas = signal<FaixaDto[]>([]);
  readonly turmas = signal<TurmaDto[]>([]);
  readonly carregando = signal(true);
  readonly erro = signal('');

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id')!;
    forkJoin({
      modalidade: this.modalidadeService.getById(id),
      faixas: this.graduacaoService.getFaixasByModalidade(id),
      turmas: this.turmaService.getAll({ modalidadeId: id }),
    }).subscribe({
      next: (res) => {
        this.modalidade.set(res.modalidade.dados ?? null);
        this.faixas.set(res.faixas.dados ?? []);
        this.turmas.set(res.turmas.dados ?? []);
        this.carregando.set(false);
      },
      error: () => { this.erro.set('Erro ao carregar modalidade.'); this.carregando.set(false); },
    });
  }

  corFaixa(cor?: string): string { return cor ?? '#94a3b8'; }

  voltar(): void { this.router.navigate(['/app/modalidades']); }
}
