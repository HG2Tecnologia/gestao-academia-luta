import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { ModalidadeService, ModalidadeDto } from '../../../../core/services/modalidade.service';

type TipoAcao = 'arquivar' | 'excluir';

@Component({
  selector: 'app-modalidades-lista',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './modalidades-lista.component.html',
})
export class ModalidadesListaComponent implements OnInit {
  private readonly modalidadeService = inject(ModalidadeService);

  readonly modalidades = signal<ModalidadeDto[]>([]);
  readonly carregando = signal(true);
  readonly erro = signal('');
  readonly seeding = signal(false);
  readonly seedSucesso = signal(false);

  readonly confirmando = signal<{ tipo: TipoAcao; modalidade: ModalidadeDto } | null>(null);
  readonly executando = signal(false);
  readonly erroModal = signal('');

  ngOnInit(): void {
    this.carregar();
  }

  carregar(): void {
    this.carregando.set(true);
    this.modalidadeService.getAll().subscribe({
      next: (res) => { this.modalidades.set(res.dados ?? []); this.carregando.set(false); },
      error: () => { this.erro.set('Erro ao carregar modalidades.'); this.carregando.set(false); },
    });
  }

  abrirConfirmacao(tipo: TipoAcao, m: ModalidadeDto): void {
    this.erroModal.set('');
    this.confirmando.set({ tipo, modalidade: m });
  }

  fecharConfirmacao(): void {
    if (this.executando()) return;
    this.confirmando.set(null);
  }

  executarAcao(): void {
    const acao = this.confirmando();
    if (!acao) return;
    this.executando.set(true);
    this.erroModal.set('');

    const sucesso = () => { this.confirmando.set(null); this.executando.set(false); this.carregar(); };
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const falha = (err: any) => {
      this.erroModal.set(err.error?.mensagem ?? (acao.tipo === 'excluir' ? 'Não é possível excluir: verifique se há faixas ou turmas vinculadas.' : 'Erro ao arquivar.'));
      this.executando.set(false);
    };

    if (acao.tipo === 'arquivar') {
      this.modalidadeService.update(acao.modalidade.id, { nome: acao.modalidade.nome, descricao: acao.modalidade.descricao, ativo: false }).subscribe({ next: sucesso, error: falha });
    } else {
      this.modalidadeService.delete(acao.modalidade.id).subscribe({ next: sucesso, error: falha });
    }
  }

  reativar(m: ModalidadeDto): void {
    this.modalidadeService.update(m.id, { nome: m.nome, descricao: m.descricao, ativo: true }).subscribe({
      next: () => this.carregar(),
    });
  }

  carregarModalidadesPadrao(): void {
    this.seeding.set(true);
    this.seedSucesso.set(false);
    this.modalidadeService.seed().subscribe({
      next: () => {
        this.seeding.set(false);
        this.seedSucesso.set(true);
        this.carregar();
        setTimeout(() => this.seedSucesso.set(false), 4000);
      },
      error: () => this.seeding.set(false),
    });
  }
}
