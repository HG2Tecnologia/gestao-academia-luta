import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AuthService } from '../../core/services/auth.service';
import { DashboardService, DashboardResumoDto } from '../../core/services/dashboard.service';
import { AlunoService } from '../../core/services/aluno.service';
import { AniversarianteDto } from '../../core/models/aluno.model';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './dashboard.component.html',
  styleUrls: ['./dashboard.component.css'],
})
export class DashboardComponent implements OnInit {
  readonly authService = inject(AuthService);
  private readonly dashboardService = inject(DashboardService);
  private readonly alunoService = inject(AlunoService);

  readonly resumo = signal<DashboardResumoDto | null>(null);
  readonly aniversariantes = signal<AniversarianteDto[]>([]);
  readonly carregando = signal(true);
  readonly erro = signal('');

  readonly mesNomes = ['Janeiro','Fevereiro','Março','Abril','Maio','Junho','Julho','Agosto','Setembro','Outubro','Novembro','Dezembro'];
  readonly mesAtual = new Date().getMonth(); // 0-based

  ngOnInit(): void {
    this.carregar();
    this.alunoService.getAniversariantes().subscribe({
      next: (res) => this.aniversariantes.set(res.dados ?? []),
    });
  }

  carregar(): void {
    this.carregando.set(true);
    this.erro.set('');
    this.dashboardService.getResumo().subscribe({
      next: (res) => { this.resumo.set(res.dados ?? null); this.carregando.set(false); },
      error: () => { this.erro.set('Erro ao carregar dados.'); this.carregando.set(false); },
    });
  }
}
