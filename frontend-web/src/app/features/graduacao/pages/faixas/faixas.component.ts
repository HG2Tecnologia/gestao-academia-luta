import { Component, inject, signal, computed, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { CdkDragDrop, DragDropModule, moveItemInArray } from '@angular/cdk/drag-drop';
import { GraduacaoService } from '../../../../core/services/graduacao.service';
import { ModalidadeService, ModalidadeDto } from '../../../../core/services/modalidade.service';
import { FaixaDto, CreateFaixaRequest } from '../../../../core/models/graduacao.model';
interface GrupoModalidade {
  modalidadeId: string;
  nomeModalidade: string;
  faixas: FaixaDto[];
}

@Component({
  selector: 'app-faixas',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule, RouterLink, DragDropModule],
  templateUrl: './faixas.component.html',
})
export class FaixasComponent implements OnInit {
  private readonly graduacaoService = inject(GraduacaoService);
  private readonly modalidadeService = inject(ModalidadeService);
  private readonly fb = inject(FormBuilder);

  readonly modalidades = signal<ModalidadeDto[]>([]);
  readonly modalidadeId = signal('');
  readonly faixas = signal<FaixaDto[]>([]);
  readonly carregando = signal(false);
  readonly modalAberto = signal(false);
  readonly salvando = signal(false);
  readonly erro = signal('');
  readonly editandoId = signal<string | null>(null);
  readonly expandidos = signal<Set<string>>(new Set());
  readonly modalEscolherModalidade = signal(false);
  readonly novaFaixaModalidadeId = signal('');

  readonly faixasAgrupadas = computed<GrupoModalidade[]>(() => {
    const grupos = new Map<string, GrupoModalidade>();
    for (const f of this.faixas()) {
      if (!grupos.has(f.modalidadeId)) {
        grupos.set(f.modalidadeId, { modalidadeId: f.modalidadeId, nomeModalidade: f.nomeModalidade, faixas: [] });
      }
      grupos.get(f.modalidadeId)!.faixas.push(f);
    }
    return Array.from(grupos.values());
  });

  readonly form = this.fb.group({
    nome: ['', Validators.required],
    cor: ['#FFFFFF', Validators.required],
    corBarra: ['#000000', Validators.required],
    temGraus: [false],
    maxGraus: [4, [Validators.required, Validators.min(1), Validators.max(10)]],
    ordem: [1, Validators.required],
    requisitosMesesMinimos: [0],
    requisitosPresencasMinimas: [0],
    descricao: [''],
  });

  ngOnInit(): void {
    this.modalidadeService.getAll().subscribe({
      next: (res) => {
        this.modalidades.set(res.dados ?? []);
        const todosExpandidos = new Set<string>((res.dados ?? []).map(m => m.id));
        this.expandidos.set(todosExpandidos);
      },
    });
    this.carregar();
  }

  onModalidadeChange(): void {
    this.faixas.set([]);
    this.carregar();
  }

  carregar(): void {
    this.carregando.set(true);
    const req = this.modalidadeId()
      ? this.graduacaoService.getFaixasByModalidade(this.modalidadeId())
      : this.graduacaoService.getAllFaixas();
    req.subscribe({
      next: (res) => {
        this.faixas.set(res.dados ?? []);
        this.carregando.set(false);
      },
      error: () => this.carregando.set(false),
    });
  }

  toggleExpandido(modalidadeId: string): void {
    const s = new Set(this.expandidos());
    if (s.has(modalidadeId)) s.delete(modalidadeId);
    else s.add(modalidadeId);
    this.expandidos.set(s);
  }

  abrirModalCriar(): void {
    if (this.modalidadeId()) {
      this.abrirModal();
    } else {
      this.novaFaixaModalidadeId.set('');
      this.modalEscolherModalidade.set(true);
    }
  }

  confirmarModalidadeParaCriar(): void {
    if (!this.novaFaixaModalidadeId()) return;
    this.modalidadeId.set(this.novaFaixaModalidadeId());
    this.onModalidadeChange();
    this.modalEscolherModalidade.set(false);
    setTimeout(() => this.abrirModal(), 50);
  }

  abrirModal(faixa?: FaixaDto): void {
    if (faixa) {
      this.editandoId.set(faixa.id);
      this.form.patchValue({ ...faixa });
    } else {
      this.editandoId.set(null);
      this.form.reset({ cor: '#FFFFFF', ordem: this.faixas().length + 1 });
    }
    this.erro.set('');
    this.modalAberto.set(true);
  }

  fecharModal(): void {
    this.modalAberto.set(false);
    this.editandoId.set(null);
  }

  salvar(): void {
    if (this.form.invalid) { this.form.markAllAsTouched(); return; }
    this.salvando.set(true);
    const v = this.form.value;
    const req: CreateFaixaRequest = {
      modalidadeId: this.modalidadeId(),
      nome: v.nome!,
      cor: v.cor!,
      corBarra: v.corBarra!,
      temGraus: !!v.temGraus,
      maxGraus: +v.maxGraus!,
      ordem: +v.ordem!,
      requisitosMesesMinimos: +v.requisitosMesesMinimos!,
      requisitosPresencasMinimas: +v.requisitosPresencasMinimas!,
      descricao: v.descricao ?? undefined,
    };

    const id = this.editandoId();
    const req$ = id
      ? this.graduacaoService.atualizarFaixa(id, req)
      : this.graduacaoService.criarFaixa(req);

    req$.subscribe({
      next: (res) => {
        if (res.sucesso) { this.fecharModal(); this.carregar(); }
        else { this.erro.set(res.mensagem ?? 'Erro'); }
        this.salvando.set(false);
      },
      error: (err) => { this.erro.set(err.error?.mensagem ?? 'Erro'); this.salvando.set(false); },
    });
  }

  remover(id: string): void {
    if (!confirm('Remover esta faixa?')) return;
    this.graduacaoService.deletarFaixa(id).subscribe({
      next: () => this.carregar(),
      error: (err) => alert(err.error?.mensagem ?? 'Erro ao remover.'),
    });
  }

  drop(event: CdkDragDrop<FaixaDto[]>, grupo: GrupoModalidade): void {
    const lista = [...grupo.faixas];
    moveItemInArray(lista, event.previousIndex, event.currentIndex);
    grupo.faixas = lista;
    this.graduacaoService.reordenarFaixas(grupo.modalidadeId, lista.map((f) => f.id)).subscribe();
  }
}
