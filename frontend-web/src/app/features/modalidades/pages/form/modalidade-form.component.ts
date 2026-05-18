import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import { Router, ActivatedRoute, RouterLink } from '@angular/router';
import { ModalidadeService } from '../../../../core/services/modalidade.service';

@Component({
  selector: 'app-modalidade-form',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  templateUrl: './modalidade-form.component.html',
})
export class ModalidadeFormComponent implements OnInit {
  private readonly modalidadeService = inject(ModalidadeService);
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);
  private readonly fb = inject(FormBuilder);

  readonly editandoId = signal<string | null>(null);
  readonly salvando = signal(false);
  readonly carregando = signal(false);
  readonly erro = signal('');

  readonly form = this.fb.group({
    nome: ['', [Validators.required, Validators.minLength(2)]],
    descricao: [''],
    ativo: [true],
  });

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      this.editandoId.set(id);
      this.carregando.set(true);
      this.modalidadeService.getById(id).subscribe({
        next: (res) => {
          if (res.dados) {
            this.form.patchValue({
              nome: res.dados.nome,
              descricao: res.dados.descricao ?? '',
              ativo: res.dados.ativo,
            });
          }
          this.carregando.set(false);
        },
        error: () => { this.erro.set('Erro ao carregar modalidade.'); this.carregando.set(false); },
      });
    }
  }

  salvar(): void {
    if (this.form.invalid) { this.form.markAllAsTouched(); return; }
    this.salvando.set(true);
    this.erro.set('');
    const v = this.form.value;
    const id = this.editandoId();

    const req$ = id
      ? this.modalidadeService.update(id, { nome: v.nome!, descricao: v.descricao ?? undefined, ativo: v.ativo! })
      : this.modalidadeService.create({ nome: v.nome!, descricao: v.descricao ?? undefined });

    req$.subscribe({
      next: (res) => {
        if (res.sucesso) this.router.navigate(['/app/modalidades']);
        else { this.erro.set(res.mensagem ?? 'Erro ao salvar.'); this.salvando.set(false); }
      },
      error: (err) => { this.erro.set(err.error?.mensagem ?? 'Erro ao salvar.'); this.salvando.set(false); },
    });
  }
}
