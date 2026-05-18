import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import { Router, ActivatedRoute, RouterLink } from '@angular/router';
import { FuncionarioService } from '../../../../core/services/funcionario.service';

const MODULOS = [
  'Alunos', 'Turmas', 'Horários', 'Presenças', 'Graduação',
  'Ranking', 'Planos', 'Financeiro', 'Contratos', 'Relatórios',
  'Catraca', 'Configurações',
] as const;

type Modulo = typeof MODULOS[number];

@Component({
  selector: 'app-funcionario-form',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  templateUrl: './funcionario-form.component.html',
})
export class FuncionarioFormComponent implements OnInit {
  private readonly funcionarioService = inject(FuncionarioService);
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);
  private readonly fb = inject(FormBuilder);

  readonly editandoId = signal<string | null>(null);
  readonly salvando = signal(false);
  readonly carregando = signal(false);
  readonly erro = signal('');
  readonly modulos = MODULOS;

  readonly form = this.fb.group({
    nome: ['', [Validators.required, Validators.minLength(3)]],
    email: ['', Validators.email],
    telefone: ['', Validators.required],
    cargo: ['', Validators.required],
    perfil: ['Professor', Validators.required],
    permissoes: this.fb.group(
      Object.fromEntries(MODULOS.map(m => [m, [false]])) as Record<Modulo, [boolean]>
    ),
    ativo: [true],
  });

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      this.editandoId.set(id);
      this.carregando.set(true);
      this.funcionarioService.getById(id).subscribe({
        next: (res) => {
          if (res.dados) {
            const d = res.dados;
            const permPatch = Object.fromEntries(
              MODULOS.map(m => [m, d.permissoes?.[m] ?? false])
            );
            this.form.patchValue({
              nome: d.nome,
              email: d.email,
              telefone: d.telefone ?? '',
              cargo: d.cargo,
              perfil: d.perfil,
              ativo: d.ativo,
              permissoes: permPatch,
            });
          }
          this.carregando.set(false);
        },
        error: () => { this.erro.set('Erro ao carregar dados.'); this.carregando.set(false); },
      });
    }
  }

  mascaraTelefone(event: Event): void {
    const input = event.target as HTMLInputElement;
    const nums = input.value.replace(/\D/g, '').slice(0, 11);
    let v = '';
    if (nums.length > 6) v = `(${nums.slice(0,2)}) ${nums.slice(2,7)}-${nums.slice(7)}`;
    else if (nums.length > 2) v = `(${nums.slice(0,2)}) ${nums.slice(2)}`;
    else if (nums.length > 0) v = `(${nums}`;
    input.value = v;
    this.form.get('telefone')?.setValue(v, { emitEvent: false });
  }

  salvar(): void {
    if (this.form.invalid) { this.form.markAllAsTouched(); return; }
    this.salvando.set(true);
    this.erro.set('');
    const v = this.form.value;
    const id = this.editandoId();

    const permissoes = (v.permissoes ?? {}) as Record<string, boolean>;

    const req$ = id
      ? this.funcionarioService.update(id, {
          nome: v.nome!, email: v.email || undefined, telefone: v.telefone!,
          cargo: v.cargo!, perfil: v.perfil!, permissoes, ativo: v.ativo!,
        })
      : this.funcionarioService.create({
          nome: v.nome!, email: v.email || undefined, telefone: v.telefone!,
          cargo: v.cargo!, perfil: v.perfil!, permissoes,
        });

    req$.subscribe({
      next: (res) => {
        if (res.sucesso) this.router.navigate(['/app/funcionarios']);
        else { this.erro.set(res.mensagem ?? 'Erro ao salvar.'); this.salvando.set(false); }
      },
      error: (err) => { this.erro.set(err.error?.mensagem ?? 'Erro ao salvar.'); this.salvando.set(false); },
    });
  }
}
