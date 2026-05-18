import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink, ActivatedRoute, Router } from '@angular/router';
import { FuncionarioService } from '../../../../core/services/funcionario.service';
import { FuncionarioListaDto } from '../../../../core/models/funcionario.model';

const MODULOS = [
  'Alunos', 'Turmas', 'Horários', 'Presenças', 'Graduação',
  'Ranking', 'Planos', 'Financeiro', 'Contratos', 'Relatórios',
  'Catraca', 'Configurações',
] as const;

@Component({
  selector: 'app-funcionario-detalhe',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './funcionario-detalhe.component.html',
})
export class FuncionarioDetalheComponent implements OnInit {
  private readonly funcionarioService = inject(FuncionarioService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);

  readonly funcionario = signal<FuncionarioListaDto | null>(null);
  readonly carregando = signal(true);
  readonly erro = signal('');

  readonly modulos = MODULOS;

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id')!;
    this.funcionarioService.getById(id).subscribe({
      next: (res) => { this.funcionario.set(res.dados ?? null); this.carregando.set(false); },
      error: () => { this.erro.set('Funcionário não encontrado.'); this.carregando.set(false); },
    });
  }

  perfilCor(perfil: string): string {
    const map: Record<string, string> = { Admin: '#a855f7', Professor: '#3b82f6', Recepcionista: '#22c55e' };
    return map[perfil] ?? '#94a3b8';
  }

  avatarInicial(nome: string): string { return (nome ?? 'F').charAt(0).toUpperCase(); }

  formatarData(d?: string): string {
    if (!d) return '—';
    const [y, m, day] = d.split('T')[0].split('-');
    return `${day}/${m}/${y}`;
  }

  temPermissao(modulo: string): boolean {
    return this.funcionario()?.permissoes?.[modulo] === true;
  }

  wppLink(telefone: string): string {
    return `https://wa.me/55${telefone.replace(/\D/g, '')}`;
  }

  voltar(): void { this.router.navigate(['/app/funcionarios']); }
}
