import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormsModule, FormBuilder, Validators } from '@angular/forms';
import { PlanoService } from '../../../../core/services/plano.service';
import { PlanoDto } from '../../../../core/models/plano.model';

@Component({
  selector: 'app-planos-lista',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, FormsModule],
  templateUrl: './planos-lista.component.html',
})
export class PlanosListaComponent implements OnInit {
  private readonly planoService = inject(PlanoService);
  private readonly fb = inject(FormBuilder);

  readonly planos = signal<PlanoDto[]>([]);
  readonly carregando = signal(true);
  readonly erro = signal('');

  readonly modalAberto = signal(false);
  readonly editandoId = signal<string | null>(null);
  readonly salvando = signal(false);
  readonly erroModal = signal('');

  readonly confirmandoExcluir = signal<PlanoDto | null>(null);
  readonly excluindo = signal(false);
  readonly erroExcluir = signal('');

  readonly form = this.fb.group({
    nome: ['', [Validators.required, Validators.minLength(2)]],
    descricao: [''],
    valorMensal: [null as number | null, [Validators.required, Validators.min(0.01)]],
    taxaMatricula: [null as number | null],
  });

  ngOnInit(): void {
    this.carregar();
  }

  carregar(): void {
    this.carregando.set(true);
    this.planoService.listar().subscribe({
      next: (r) => { this.planos.set(r.dados ?? []); this.carregando.set(false); },
      error: () => { this.erro.set('Erro ao carregar planos.'); this.carregando.set(false); },
    });
  }

  abrirNovo(): void {
    this.editandoId.set(null);
    this.erroModal.set('');
    this.form.reset({ nome: '', descricao: '', valorMensal: null, taxaMatricula: null });
    this.modalAberto.set(true);
  }

  abrirEditar(p: PlanoDto): void {
    this.editandoId.set(p.id);
    this.erroModal.set('');
    this.form.patchValue({ nome: p.nome, descricao: p.descricao ?? '', valorMensal: p.valorMensal, taxaMatricula: p.taxaMatricula ?? null });
    this.modalAberto.set(true);
  }

  fecharModal(): void {
    if (this.salvando()) return;
    this.modalAberto.set(false);
  }

  salvar(): void {
    if (this.form.invalid) { this.form.markAllAsTouched(); return; }
    this.salvando.set(true);
    this.erroModal.set('');
    const v = this.form.value;
    const id = this.editandoId();

    const req$ = id
      ? this.planoService.atualizar(id, { nome: v.nome!, descricao: v.descricao || undefined, valorMensal: v.valorMensal!, taxaMatricula: v.taxaMatricula ?? undefined, ativo: true })
      : this.planoService.criar({ nome: v.nome!, descricao: v.descricao || undefined, valorMensal: v.valorMensal!, taxaMatricula: v.taxaMatricula ?? undefined });

    req$.subscribe({
      next: (r) => {
        if (!r.sucesso) { this.erroModal.set(r.mensagem ?? 'Erro ao salvar.'); this.salvando.set(false); return; }
        this.modalAberto.set(false);
        this.salvando.set(false);
        this.carregar();
      },
      error: (err) => { this.erroModal.set(err.error?.mensagem ?? 'Erro ao salvar.'); this.salvando.set(false); },
    });
  }

  toggleAtivo(p: PlanoDto): void {
    this.planoService.atualizar(p.id, { nome: p.nome, descricao: p.descricao, valorMensal: p.valorMensal, taxaMatricula: p.taxaMatricula ?? undefined, ativo: !p.ativo }).subscribe({
      next: () => this.carregar(),
    });
  }

  confirmarExcluir(p: PlanoDto): void {
    this.erroExcluir.set('');
    this.confirmandoExcluir.set(p);
  }

  fecharExcluir(): void {
    if (this.excluindo()) return;
    this.confirmandoExcluir.set(null);
  }

  formatarMoeda(valor: number): string {
    return valor.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
  }

  executarExcluir(): void {
    const p = this.confirmandoExcluir();
    if (!p) return;
    this.excluindo.set(true);
    this.erroExcluir.set('');
    this.planoService.deletar(p.id).subscribe({
      next: (r) => {
        if (!r.sucesso) { this.erroExcluir.set(r.mensagem ?? 'Erro ao excluir.'); this.excluindo.set(false); return; }
        this.confirmandoExcluir.set(null);
        this.excluindo.set(false);
        this.carregar();
      },
      error: (err) => { this.erroExcluir.set(err.error?.mensagem ?? 'Não é possível excluir: verifique se há alunos vinculados.'); this.excluindo.set(false); },
    });
  }
}
