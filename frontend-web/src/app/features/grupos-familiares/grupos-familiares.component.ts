import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { GruposFamiliaresService, GrupoFamiliarDto } from '../../core/services/grupos-familiares.service';
import { AlunoService } from '../../core/services/aluno.service';
import { AlunoListaDto } from '../../core/models/aluno.model';

@Component({
  selector: 'app-grupos-familiares',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './grupos-familiares.component.html',
})
export class GruposFamiliaresComponent implements OnInit {
  private readonly svc = inject(GruposFamiliaresService);
  private readonly alunoSvc = inject(AlunoService);

  readonly grupos = signal<GrupoFamiliarDto[]>([]);
  readonly carregando = signal(true);
  readonly erro = signal('');

  // Modal criar/renomear
  readonly modalAberto = signal(false);
  readonly modalTipo = signal<'criar' | 'renomear'>('criar');
  readonly modalNome = signal('');
  readonly grupoEditando = signal<GrupoFamiliarDto | null>(null);
  readonly salvando = signal(false);
  readonly erroModal = signal('');

  // Modal excluir
  readonly modalExcluirAberto = signal(false);
  readonly grupoParaExcluir = signal<GrupoFamiliarDto | null>(null);
  readonly excluindo = signal(false);

  // Modal adicionar membro
  readonly modalMembroAberto = signal(false);
  readonly grupoParaMembro = signal<GrupoFamiliarDto | null>(null);
  readonly buscaAluno = signal('');
  readonly alunosBusca = signal<AlunoListaDto[]>([]);
  readonly buscando = signal(false);
  readonly adicionando = signal(false);
  private buscaTimer: ReturnType<typeof setTimeout> | null = null;

  ngOnInit(): void {
    this.carregar();
  }

  carregar(): void {
    this.carregando.set(true);
    this.erro.set('');
    this.svc.listar().subscribe({
      next: res => {
        this.grupos.set(res.dados ?? []);
        this.carregando.set(false);
      },
      error: () => {
        this.erro.set('Erro ao carregar grupos familiares.');
        this.carregando.set(false);
      },
    });
  }

  abrirCriar(): void {
    this.modalTipo.set('criar');
    this.modalNome.set('');
    this.grupoEditando.set(null);
    this.erroModal.set('');
    this.modalAberto.set(true);
  }

  abrirRenomear(grupo: GrupoFamiliarDto): void {
    this.modalTipo.set('renomear');
    this.modalNome.set(grupo.nome);
    this.grupoEditando.set(grupo);
    this.erroModal.set('');
    this.modalAberto.set(true);
  }

  salvarModal(): void {
    if (!this.modalNome().trim()) {
      this.erroModal.set('Nome é obrigatório.');
      return;
    }
    this.salvando.set(true);
    this.erroModal.set('');
    const obs = this.modalTipo() === 'criar'
      ? this.svc.criar(this.modalNome().trim())
      : this.svc.renomear(this.grupoEditando()!.id, this.modalNome().trim());

    obs.subscribe({
      next: () => { this.modalAberto.set(false); this.salvando.set(false); this.carregar(); },
      error: () => { this.erroModal.set('Erro ao salvar. Tente novamente.'); this.salvando.set(false); },
    });
  }

  fecharModal(): void { this.modalAberto.set(false); }

  abrirExcluir(grupo: GrupoFamiliarDto): void {
    this.grupoParaExcluir.set(grupo);
    this.modalExcluirAberto.set(true);
  }

  confirmarExcluir(): void {
    const grupo = this.grupoParaExcluir();
    if (!grupo) return;
    this.excluindo.set(true);
    this.svc.excluir(grupo.id).subscribe({
      next: () => { this.modalExcluirAberto.set(false); this.excluindo.set(false); this.carregar(); },
      error: () => { this.excluindo.set(false); },
    });
  }

  fecharExcluir(): void { this.modalExcluirAberto.set(false); }

  removerMembro(grupo: GrupoFamiliarDto, membroId: string): void {
    this.svc.removerMembro(grupo.id, membroId).subscribe({
      next: () => this.carregar(),
    });
  }

  abrirAdicionarMembro(grupo: GrupoFamiliarDto): void {
    this.grupoParaMembro.set(grupo);
    this.buscaAluno.set('');
    this.alunosBusca.set([]);
    this.modalMembroAberto.set(true);
  }

  onBuscaAluno(valor: string): void {
    this.buscaAluno.set(valor);
    if (this.buscaTimer) clearTimeout(this.buscaTimer);
    if (!valor.trim()) { this.alunosBusca.set([]); return; }
    this.buscaTimer = setTimeout(() => {
      this.buscando.set(true);
      this.alunoSvc.buscarPorNome(valor).subscribe({
        next: res => { this.alunosBusca.set(res.dados?.itens ?? []); this.buscando.set(false); },
        error: () => this.buscando.set(false),
      });
    }, 350);
  }

  adicionarMembro(aluno: AlunoListaDto): void {
    const grupo = this.grupoParaMembro();
    if (!grupo) return;
    this.adicionando.set(true);
    this.svc.adicionarMembro(grupo.id, aluno.id).subscribe({
      next: () => {
        this.modalMembroAberto.set(false);
        this.adicionando.set(false);
        this.carregar();
      },
      error: () => this.adicionando.set(false),
    });
  }

  fecharMembro(): void { this.modalMembroAberto.set(false); }

  iniciais(nome: string): string {
    return nome.split(' ').slice(0, 2).map(w => w[0] ?? '').join('').toUpperCase();
  }
}
