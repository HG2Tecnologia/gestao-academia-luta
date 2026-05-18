import { Component, inject, signal, computed, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { ContratoService } from '../../../../core/services/contrato.service';
import { ModeloContratoService } from '../../../../core/services/modelo-contrato.service';
import { AlunoService } from '../../../../core/services/aluno.service';
import { ContratoDto, ModeloContratoDto } from '../../../../core/models/contrato.model';
import { AlunoListaDto } from '../../../../core/models/aluno.model';

@Component({
  selector: 'app-contratos-lista',
  standalone: true,
  imports: [CommonModule, RouterLink, FormsModule],
  templateUrl: './contratos-lista.component.html',
})
export class ContratosListaComponent implements OnInit {
  private readonly contratoService = inject(ContratoService);
  private readonly modeloService = inject(ModeloContratoService);
  private readonly alunoService = inject(AlunoService);

  readonly carregando = signal(true);
  readonly erro = signal('');
  readonly contratos = signal<ContratoDto[]>([]);
  readonly alunos = signal<AlunoListaDto[]>([]);
  readonly modelos = signal<ModeloContratoDto[]>([]);
  readonly filtroStatus = signal<'' | '1' | '2' | '3'>('');
  readonly filtroBusca = signal('');

  readonly modalNovoAberto = signal(false);
  readonly criando = signal(false);
  readonly erroCriacao = signal('');
  readonly novoAlunoId = signal('');
  readonly novoModeloId = signal('');

  readonly contratosFiltrados = computed(() => {
    let lista = this.contratos();
    const status = this.filtroStatus();
    const busca = this.filtroBusca().toLowerCase();
    if (status) lista = lista.filter(c => String(c.status) === status);
    if (busca) lista = lista.filter(c => c.nomeAluno.toLowerCase().includes(busca));
    return lista;
  });

  ngOnInit(): void {
    this.carregarContratos();
    this.carregarAlunos();
    this.carregarModelos();
  }

  private carregarContratos(): void {
    this.carregando.set(true);
    this.contratoService.listar().subscribe({
      next: res => { this.contratos.set(res.dados ?? []); this.carregando.set(false); },
      error: () => { this.erro.set('Erro ao carregar contratos.'); this.carregando.set(false); },
    });
  }

  private carregarAlunos(): void {
    this.alunoService.getAll({ ativo: true, pageSize: 500 }).subscribe({
      next: res => this.alunos.set(res.dados?.itens ?? []),
    });
  }

  private carregarModelos(): void {
    this.modeloService.listar().subscribe({
      next: res => this.modelos.set(res.dados ?? []),
    });
  }

  abrirModalNovo(): void {
    this.novoAlunoId.set('');
    this.novoModeloId.set('');
    this.erroCriacao.set('');
    this.modalNovoAberto.set(true);
  }

  fecharModalNovo(): void { this.modalNovoAberto.set(false); }

  criarContrato(): void {
    if (!this.novoAlunoId()) { this.erroCriacao.set('Selecione um aluno.'); return; }
    this.criando.set(true);
    this.erroCriacao.set('');
    this.contratoService.criar({
      alunoId: this.novoAlunoId(),
      modeloContratoId: this.novoModeloId() || undefined,
    }).subscribe({
      next: res => {
        this.criando.set(false);
        if (res.sucesso) { this.fecharModalNovo(); this.carregarContratos(); }
        else this.erroCriacao.set(res.mensagem ?? 'Erro ao criar contrato.');
      },
      error: err => { this.criando.set(false); this.erroCriacao.set(err.error?.mensagem ?? 'Erro ao criar contrato.'); },
    });
  }

  cancelarContrato(id: string, event: Event): void {
    event.stopPropagation();
    if (!confirm('Cancelar este contrato?')) return;
    this.contratoService.cancelar(id).subscribe({
      next: () => this.carregarContratos(),
    });
  }

  badgeClass(status: number): string {
    if (status === 2) return 'badge-assinado';
    if (status === 3) return 'badge-cancelado';
    return 'badge-pendente';
  }

  formatarData(d?: string): string {
    if (!d) return '—';
    return new Date(d).toLocaleDateString('pt-BR');
  }
}
