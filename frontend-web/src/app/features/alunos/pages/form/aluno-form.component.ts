import { Component, inject, signal, OnInit, OnDestroy, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormsModule, FormBuilder, Validators } from '@angular/forms';
import { Router, ActivatedRoute, RouterLink } from '@angular/router';
import { Subject, takeUntil } from 'rxjs';
import { AlunoService } from '../../../../core/services/aluno.service';
import { TurmaService } from '../../../../core/services/turma.service';
import { GraduacaoService } from '../../../../core/services/graduacao.service';
import { ModalidadeService } from '../../../../core/services/modalidade.service';
import { FirebaseAuthService } from '../../../../core/services/firebase-auth.service';
import { PlanoService } from '../../../../core/services/plano.service';
import { PlanoLimiteService } from '../../../../core/services/plano-limite.service';
import { AcessoService, PedidoAcesso } from '../../../../core/services/acesso.service';
import { DialogService } from '../../../../core/services/dialog.service';
import { TurmaDto } from '../../../../core/models/turma.model';
import { FaixaDto } from '../../../../core/models/graduacao.model';
import { PlanoDto } from '../../../../core/models/plano.model';
import { dataLocalISO } from '../../../../core/utils/date.util';

interface ModalidadeResumo { id: string; nome: string; }

@Component({
  selector: 'app-aluno-form',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, FormsModule, RouterLink],
  templateUrl: './aluno-form.component.html',
})
export class AlunoFormComponent implements OnInit, OnDestroy {
  private readonly alunoService = inject(AlunoService);
  private readonly turmaService = inject(TurmaService);
  private readonly graduacaoService = inject(GraduacaoService);
  private readonly modalidadeService = inject(ModalidadeService);
  private readonly authService = inject(FirebaseAuthService);
  private readonly planoService = inject(PlanoService);
  private readonly planoLimiteService = inject(PlanoLimiteService);
  private readonly acessoService = inject(AcessoService);
  private readonly dialogService = inject(DialogService);

  /** "Acesso ao app" do cadastro — liberado por padrão, como no app. */
  readonly acessoAppAtivo = signal(true);
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);
  private readonly fb = inject(FormBuilder);
  private readonly destroy$ = new Subject<void>();

  readonly editandoId = signal<string | null>(null);
  readonly matricula = signal<string | null>(null);
  readonly salvando = signal(false);
  readonly carregando = signal(false);
  readonly erro = signal('');

  // Opcionais de cadastro
  readonly turmas = signal<TurmaDto[]>([]);
  readonly modalidades = signal<ModalidadeResumo[]>([]);
  readonly faixas = signal<FaixaDto[]>([]);
  readonly planosDisponiveis = signal<PlanoDto[]>([]);
  readonly turmaInicialId = signal('');
  readonly modalidadeInicialId = signal('');
  readonly faixaInicialId = signal('');
  readonly planoSelecionadoId = signal('');
  readonly diaVencimento = signal<number | null>(null);
  readonly dataNascimentoSignal = signal('');

  // Graduação no modo edição
  readonly modalidadeGradId = signal('');
  readonly faixaGradId = signal('');
  readonly faixasGrad = signal<FaixaDto[]>([]);
  readonly dataGrad = signal(dataLocalISO());
  readonly registrandoGrad = signal(false);
  readonly gradSucesso = signal(false);
  readonly erroGrad = signal('');

  readonly form = this.fb.group({
    nome: ['', Validators.required],
    email: ['', Validators.email],
    telefone: [''],
    cpf: [''],
    dataNascimento: [''],
    contatoEmergenciaNome: [''],
    contatoEmergenciaTelefone: [''],
    tipoPlano: [''],
    ativo: [true],
  });

  readonly menorDeIdade = computed(() => this.calcularMenorDeIdade(this.dataNascimentoSignal()));

  ngOnInit(): void {
    this.form.get('dataNascimento')!.valueChanges.pipe(takeUntil(this.destroy$)).subscribe(val => {
      this.dataNascimentoSignal.set(val ?? '');
    });

    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      this.editandoId.set(id);
      this.carregando.set(true);
      this.alunoService.getById(id).subscribe({
        next: (res) => {
          if (res.dados) {
            const d = res.dados;
            this.matricula.set((d as any).matricula ?? null);
            this.form.patchValue({
              nome: d.nome, email: d.email ?? '', telefone: d.telefone ?? '',
              dataNascimento: d.dataNascimento ?? '',
              contatoEmergenciaNome: d.contatoEmergenciaNome ?? '',
              contatoEmergenciaTelefone: d.contatoEmergenciaTelefone ?? '',
              tipoPlano: (d as any).tipoPlano ?? '', ativo: d.ativo,
            });
            this.dataNascimentoSignal.set(d.dataNascimento ?? '');
            this.planoSelecionadoId.set((d as any).planoId ?? '');
            this.diaVencimento.set((d as any).diaVencimento ?? null);
          }
          this.carregando.set(false);
        },
        error: () => { this.erro.set('Erro ao carregar dados do aluno.'); this.carregando.set(false); },
      });
    }

    // Carregar planos e turmas sempre (para vincular no edit também)
    this.planoService.listar().subscribe({ next: (r) => this.planosDisponiveis.set((r.dados ?? []).filter(p => p.ativo)) });
    if (!this.editandoId()) {
      this.turmaService.getAll({ ativo: true }).subscribe({ next: (r) => this.turmas.set(r.dados ?? []) });
    }
    // Modalidades carregadas sempre (usadas em criar e para registrar graduação no editar)
    this.modalidadeService.getAll().subscribe({ next: (r) => this.modalidades.set(r.dados ?? []) });
  }

  ngOnDestroy(): void { this.destroy$.next(); this.destroy$.complete(); }

  onTurmaChange(turmaId: string): void {
    this.turmaInicialId.set(turmaId);
    if (!turmaId) return;
    const turma = this.turmas().find(t => t.id === turmaId);
    if (turma?.modalidadeId) {
      this.onModalidadeChange(turma.modalidadeId);
    }
  }

  onModalidadeChange(modalidadeId: string): void {
    this.modalidadeInicialId.set(modalidadeId);
    this.faixaInicialId.set('');
    this.faixas.set([]);
    if (!modalidadeId) return;
    this.graduacaoService.getFaixasByModalidade(modalidadeId).subscribe({
      next: (r) => this.faixas.set(r.dados ?? []),
    });
  }

  onModalidadeGradChange(modalidadeId: string): void {
    this.modalidadeGradId.set(modalidadeId);
    this.faixaGradId.set('');
    this.faixasGrad.set([]);
    if (!modalidadeId) return;
    this.graduacaoService.getFaixasByModalidade(modalidadeId).subscribe({
      next: (r) => this.faixasGrad.set(r.dados ?? []),
    });
  }

  registrarGraduacao(): void {
    const alunoId = this.editandoId();
    const faixaId = this.faixaGradId();
    const professorId = this.authService.currentUser()?.id;
    if (!alunoId || !faixaId || !professorId) { this.erroGrad.set('Selecione modalidade e faixa.'); return; }
    this.registrandoGrad.set(true);
    this.erroGrad.set('');
    this.gradSucesso.set(false);
    this.graduacaoService.registrar({ alunoId, faixaId, dataExame: this.dataGrad(), professorId, aprovado: true, grau: 0 }).subscribe({
      next: () => {
        this.registrandoGrad.set(false);
        this.gradSucesso.set(true);
        this.modalidadeGradId.set('');
        this.faixaGradId.set('');
        this.faixasGrad.set([]);
      },
      error: (err) => { this.erroGrad.set(err.error?.mensagem ?? 'Erro ao registrar graduação.'); this.registrandoGrad.set(false); },
    });
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

  mascaraEmergTel(event: Event): void {
    const input = event.target as HTMLInputElement;
    const nums = input.value.replace(/\D/g, '').slice(0, 11);
    let v = '';
    if (nums.length > 6) v = `(${nums.slice(0,2)}) ${nums.slice(2,7)}-${nums.slice(7)}`;
    else if (nums.length > 2) v = `(${nums.slice(0,2)}) ${nums.slice(2)}`;
    else if (nums.length > 0) v = `(${nums}`;
    input.value = v;
    this.form.get('contatoEmergenciaTelefone')?.setValue(v, { emitEvent: false });
  }

  /**
   * Avisos que o app faz antes de criar o aluno. Devolve `null` se a pessoa
   * cancelar — nada é gravado.
   */
  private async checagensAntesDeCriar(): Promise<Partial<PedidoAcesso> | null> {
    const { nome, email, telefone } = this.form.value;
    const emailLimpo = (email ?? '').trim().toLowerCase();
    const digitos = (telefone ?? '').replace(/\D/g, '');

    if (emailLimpo) {
      const existente = await this.alunoService.alunoComEmail(emailLimpo);
      if (existente !== null && !(await this.dialogService.confirm(
        `O e-mail informado já pertence a: ${existente}.\n\nDeseja cadastrar mesmo assim?\nAo fazer o primeiro acesso com esse contato, o aluno poderá escolher entre os perfis (grupo familiar).`,
        { titulo: 'E-mail já cadastrado', textoConfirmar: 'Cadastrar mesmo assim' },
      ))) return null;
    }

    if (digitos) {
      const equipe = await this.acessoService.perfilComMesmoTelefone('funcionarios', telefone ?? '').catch(() => null);
      if (equipe && !(await this.dialogService.confirm(
        `Esse telefone já pertence a: ${equipe.nome} (${equipe.perfil}).\n\nDeseja vincular esse cadastro de Aluno ao mesmo contato? A pessoa poderá trocar entre os perfis dentro do app.`,
        { titulo: 'Vincular perfis?', textoConfirmar: 'Vincular também' },
      ))) return null;
    }

    if (this.acessoAppAtivo() && (emailLimpo || digitos)
      && (await this.acessoService.contatoJaTemSenha(digitos, emailLimpo))) {
      const escolha = await this.acessoService.perguntarConflito(nome ?? '');
      if (!escolha) return null;
      return { confirmarSobrescrita: escolha === 'gerarNova', apenasVincular: escolha === 'manterAtual' };
    }
    return {};
  }

  async salvar(): Promise<void> {
    if (this.form.invalid) { this.form.markAllAsTouched(); return; }
    if (this.salvando()) return;
    this.salvando.set(true);
    let opcoesAcesso: Partial<PedidoAcesso> = {};
    if (!this.editandoId()) {
      try {
        const resultado = await this.checagensAntesDeCriar();
        if (!resultado) { this.salvando.set(false); return; }
        opcoesAcesso = resultado;
      } catch {
        this.erro.set('Erro ao verificar os dados do aluno. Tente novamente.');
        this.salvando.set(false);
        return;
      }
    }
    this.erro.set('');
    const v = this.form.value;
    const id = this.editandoId();

    const base = {
      nome: v.nome!, email: v.email || undefined, telefone: v.telefone ?? '',
      cpf: v.cpf || undefined,
      acessoAppBloqueado: !id && !this.acessoAppAtivo(),
      dataNascimento: v.dataNascimento || undefined,
      contatoEmergenciaNome: v.contatoEmergenciaNome || undefined,
      contatoEmergenciaTelefone: v.contatoEmergenciaTelefone || undefined,
      tipoPlano: v.tipoPlano || undefined,
      planoId: this.planoSelecionadoId() || undefined,
      diaVencimento: this.diaVencimento() ?? undefined,
    } as any;

    const req$ = id
      ? this.alunoService.update(id, { ...base, ativo: v.ativo! })
      : this.alunoService.create(base);

    req$.subscribe({
      next: async (res) => {
        if (!res.sucesso) { this.erro.set(res.mensagem ?? 'Erro ao salvar.'); this.salvando.set(false); return; }
        if (id) { this.router.navigate(['/app/alunos']); return; }
        const alunoId = res.dados!.id;
        // Como no app: com acesso liberado e contato, já gera a senha
        // temporária para a academia repassar. Falha não desfaz o cadastro.
        if (this.acessoAppAtivo() && (v.email || (v.telefone ?? '').replace(/\D/g, ''))) {
          await this.acessoService.gerarEMostrar({
            colecao: 'usuarios', usuarioId: alunoId, nome: v.nome!, motivo: 'provisao_criacao', ...opcoesAcesso,
          });
        }
        this.vincularOpcionais(alunoId);
      },
      error: async (err) => {
        const limite = id ? null : await this.planoLimiteService.mensagemSeAtingido(err, 'aluno');
        this.erro.set(limite ?? err.error?.mensagem ?? 'Erro ao salvar.');
        this.salvando.set(false);
      },
    });
  }

  private vincularOpcionais(alunoId: string): void {
    const turmaId = this.turmaInicialId();
    const faixaId = this.faixaInicialId();
    const professorId = this.authService.currentUser()?.id;
    const hoje = dataLocalISO();

    const pendentes: Promise<any>[] = [];

    if (turmaId) {
      pendentes.push(this.turmaService.matricular(turmaId, alunoId).toPromise());
    }
    if (faixaId && professorId) {
      pendentes.push(this.graduacaoService.registrar({
        alunoId, faixaId,
        dataExame: hoje,
        professorId,
        aprovado: true,
        grau: 0,
      }).toPromise());
    }

    Promise.allSettled(pendentes).then(() => {
      this.router.navigate(['/app/alunos', alunoId]);
    });
  }

  private calcularMenorDeIdade(dataNasc: string | null | undefined): boolean {
    if (!dataNasc) return false;
    const nasc = new Date(dataNasc);
    const hoje = new Date();
    const aniv = new Date(hoje.getFullYear(), nasc.getMonth(), nasc.getDate());
    const idade = hoje.getFullYear() - nasc.getFullYear() - (hoje < aniv ? 1 : 0);
    return idade < 18;
  }

}
