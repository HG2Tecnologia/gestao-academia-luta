import { Component, inject, signal, computed, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { TurmaService } from '../../../../core/services/turma.service';
import { TurmaDto } from '../../../../core/models/turma.model';

@Component({
  selector: 'app-turmas-lista',
  standalone: true,
  imports: [CommonModule, RouterLink, FormsModule],
  templateUrl: './turmas-lista.component.html',
})
export class TurmasListaComponent implements OnInit {
  private readonly turmaService = inject(TurmaService);

  readonly turmas = signal<TurmaDto[]>([]);
  readonly carregando = signal(true);
  readonly erro = signal('');
  readonly dropdownAbertoId = signal<string | null>(null);
  readonly dropdownPos = signal({ top: 0, right: 0 });
  readonly filtroModalidade = signal('');
  readonly filtroAtivo = signal<boolean | null>(null);

  readonly turmasFiltradas = computed(() => {
    let lista = this.turmas();
    if (this.filtroModalidade())
      lista = lista.filter((t) => t.modalidadeId === this.filtroModalidade());
    if (this.filtroAtivo() !== null)
      lista = lista.filter((t) => t.ativo === this.filtroAtivo());
    return lista;
  });

  ngOnInit(): void {
    this.carregar();
  }

  carregar(): void {
    this.carregando.set(true);
    this.turmaService.getAll().subscribe({
      next: (res) => {
        this.turmas.set(res.dados ?? []);
        this.carregando.set(false);
      },
      error: () => {
        this.erro.set('Erro ao carregar turmas.');
        this.carregando.set(false);
      },
    });
  }

  setFiltroAtivo(valor: string): void {
    if (valor === '') this.filtroAtivo.set(null);
    else this.filtroAtivo.set(valor === 'true');
  }

  toggleDropdown(id: string, event: MouseEvent): void {
    const rect = (event.currentTarget as HTMLElement).getBoundingClientRect();
    this.dropdownPos.set({ top: rect.bottom + 4, right: window.innerWidth - rect.right });
    this.dropdownAbertoId.update((atual) => atual === id ? null : id);
  }

  fecharDropdown(): void { this.dropdownAbertoId.set(null); }

  arquivar(id: string): void {
    if (!confirm('Tem certeza que deseja arquivar esta turma?')) return;
    this.turmaService.delete(id).subscribe({
      next: () => this.carregar(),
      error: () => alert('Erro ao arquivar turma.'),
    });
  }
}
