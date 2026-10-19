import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import { Router, ActivatedRoute, RouterLink } from '@angular/router';
import { FuncionarioService } from '../../../../core/services/funcionario.service';
import { PERMISSOES_INFO, PERMISSOES_DEFAULT, PerfilComPermissoes } from '../../../../core/models/permissoes.model';

/**
 * Mesmas chaves de permissão granular do app mobile (`permissoes.model.ts`,
 * espelho de `mobile/lib/core/permissoes.dart`) — ANTES este form usava uma
 * lista de "módulos" (Alunos/Turmas/...) que não correspondia a NENHUMA
 * permissão de verdade checada em lugar nenhum (nem no app, nem nos guards
 * do próprio CRM). Perfil "Recepcionista" também não existe no app — o
 * perfil real é "Secretaria".
 */
const CHAVES_PERMISSAO = Object.keys(PERMISSOES_INFO);

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
  readonly permissoesInfo = CHAVES_PERMISSAO.map((chave) => ({ chave, ...PERMISSOES_INFO[chave] }));

  readonly form = this.fb.group({
    nome: ['', [Validators.required, Validators.minLength(3)]],
    email: ['', Validators.email],
    telefone: ['', Validators.required],
    cargo: ['', Validators.required],
    perfil: ['Professor', Validators.required],
    permissoes: this.fb.group(
      Object.fromEntries(CHAVES_PERMISSAO.map((c) => [c, [false]])) as Record<string, [boolean]>,
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
            const permPatch = Object.fromEntries(CHAVES_PERMISSAO.map((c) => [c, d.permissoes?.[c] ?? false]));
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
    } else {
      this.onPerfilChange(this.form.get('perfil')!.value!);
    }
  }

  /** Admin não tem chave nenhuma marcada aqui de propósito — ele ignora `permissoes` e sempre tem acesso total (ver `temPermissao`). */
  onPerfilChange(perfil: string): void {
    if (this.editandoId()) return;
    const defaults =
      perfil === 'Admin' ? {} : PERMISSOES_DEFAULT[perfil as PerfilComPermissoes] ?? {};
    const patch = Object.fromEntries(CHAVES_PERMISSAO.map((c) => [c, defaults[c] === true]));
    this.form.get('permissoes')?.patchValue(patch);
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
