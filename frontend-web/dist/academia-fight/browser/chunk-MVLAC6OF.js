import {
  HorarioService
} from "./chunk-CWZ2LAZG.js";
import {
  TurmaService
} from "./chunk-S4MMSQ6J.js";
import {
  DefaultValueAccessor,
  FormBuilder,
  FormControlName,
  FormGroupDirective,
  NgControlStatus,
  NgControlStatusGroup,
  NgSelectOption,
  ReactiveFormsModule,
  SelectControlValueAccessor,
  Validators,
  ɵNgNoValidate,
  ɵNgSelectMultipleOption
} from "./chunk-JQJL26HT.js";
import "./chunk-Z5CKO2JM.js";
import {
  CommonModule,
  forkJoin,
  inject,
  signal,
  ɵsetClassDebugInfo,
  ɵɵStandaloneFeature,
  ɵɵadvance,
  ɵɵclassProp,
  ɵɵconditional,
  ɵɵdefineComponent,
  ɵɵelement,
  ɵɵelementEnd,
  ɵɵelementStart,
  ɵɵgetCurrentView,
  ɵɵlistener,
  ɵɵnextContext,
  ɵɵproperty,
  ɵɵrepeater,
  ɵɵrepeaterCreate,
  ɵɵrepeaterTrackByIdentity,
  ɵɵresetView,
  ɵɵrestoreView,
  ɵɵstyleProp,
  ɵɵtemplate,
  ɵɵtext,
  ɵɵtextInterpolate,
  ɵɵtextInterpolate1,
  ɵɵtextInterpolate2
} from "./chunk-WZ2AWGAJ.js";
import "./chunk-7G5TR5RR.js";

// src/app/features/horarios/pages/grade/grade-horarios.component.ts
var _forTrack0 = ($index, $item) => $item.id;
var _forTrack1 = ($index, $item) => $item.value;
function GradeHorariosComponent_Conditional_9_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 5);
    \u0275\u0275element(1, "div", 6);
    \u0275\u0275elementEnd();
  }
}
function GradeHorariosComponent_Conditional_10_Template(rf, ctx) {
  if (rf & 1) {
    const _r1 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 7)(1, "p");
    \u0275\u0275text(2);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "button", 8);
    \u0275\u0275listener("click", function GradeHorariosComponent_Conditional_10_Template_button_click_3_listener() {
      \u0275\u0275restoreView(_r1);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.carregar());
    });
    \u0275\u0275text(4, "Tentar novamente");
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext();
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(ctx_r1.erro());
  }
}
function GradeHorariosComponent_Conditional_11_For_2_For_5_Conditional_9_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 20);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const h_r4 = \u0275\u0275nextContext().$implicit;
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(h_r4.sala);
  }
}
function GradeHorariosComponent_Conditional_11_For_2_For_5_Template(rf, ctx) {
  if (rf & 1) {
    const _r3 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 15);
    \u0275\u0275listener("click", function GradeHorariosComponent_Conditional_11_For_2_For_5_Template_div_click_0_listener() {
      const h_r4 = \u0275\u0275restoreView(_r3).$implicit;
      const ctx_r1 = \u0275\u0275nextContext(3);
      return \u0275\u0275resetView(ctx_r1.selecionar(h_r4));
    });
    \u0275\u0275elementStart(1, "div", 16);
    \u0275\u0275text(2);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "div", 17);
    \u0275\u0275text(4);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(5, "div", 18);
    \u0275\u0275text(6);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(7, "div", 19);
    \u0275\u0275text(8);
    \u0275\u0275elementEnd();
    \u0275\u0275template(9, GradeHorariosComponent_Conditional_11_For_2_For_5_Conditional_9_Template, 2, 1, "div", 20);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const h_r4 = ctx.$implicit;
    const ctx_r1 = \u0275\u0275nextContext(3);
    \u0275\u0275styleProp("border-left-color", ctx_r1.corModalidade(h_r4.nomeModalidade));
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate2("", h_r4.horaInicio, " \u2013 ", h_r4.horaFim, "");
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(h_r4.nomeTurma);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(h_r4.nomeModalidade);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate2("", h_r4.totalAlunos, "/", h_r4.capacidadeMaxima, "");
    \u0275\u0275advance();
    \u0275\u0275conditional(9, h_r4.sala ? 9 : -1);
  }
}
function GradeHorariosComponent_Conditional_11_For_2_Conditional_6_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 14);
    \u0275\u0275text(1, "\u2014");
    \u0275\u0275elementEnd();
  }
}
function GradeHorariosComponent_Conditional_11_For_2_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 10)(1, "div", 11);
    \u0275\u0275text(2);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "div", 12);
    \u0275\u0275repeaterCreate(4, GradeHorariosComponent_Conditional_11_For_2_For_5_Template, 10, 9, "div", 13, _forTrack0);
    \u0275\u0275template(6, GradeHorariosComponent_Conditional_11_For_2_Conditional_6_Template, 2, 0, "div", 14);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const dia_r5 = ctx.$implicit;
    const ctx_r1 = \u0275\u0275nextContext(2);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(dia_r5);
    \u0275\u0275advance(2);
    \u0275\u0275repeater(ctx_r1.getDia(dia_r5));
    \u0275\u0275advance(2);
    \u0275\u0275conditional(6, ctx_r1.getDia(dia_r5).length === 0 ? 6 : -1);
  }
}
function GradeHorariosComponent_Conditional_11_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 9);
    \u0275\u0275repeaterCreate(1, GradeHorariosComponent_Conditional_11_For_2_Template, 7, 2, "div", 10, \u0275\u0275repeaterTrackByIdentity);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext();
    \u0275\u0275advance();
    \u0275\u0275repeater(ctx_r1.diasOrdem);
  }
}
function GradeHorariosComponent_Conditional_12_Conditional_24_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "p")(1, "strong");
    \u0275\u0275text(2, "Sala:");
    \u0275\u0275elementEnd();
    \u0275\u0275text(3);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(2);
    \u0275\u0275advance(3);
    \u0275\u0275textInterpolate1(" ", ctx_r1.horarioSelecionado().sala, "");
  }
}
function GradeHorariosComponent_Conditional_12_Template(rf, ctx) {
  if (rf & 1) {
    const _r6 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 21);
    \u0275\u0275listener("click", function GradeHorariosComponent_Conditional_12_Template_div_click_0_listener() {
      \u0275\u0275restoreView(_r6);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.fecharModal());
    });
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(1, "div", 22)(2, "div", 23)(3, "h3");
    \u0275\u0275text(4);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(5, "button", 24);
    \u0275\u0275listener("click", function GradeHorariosComponent_Conditional_12_Template_button_click_5_listener() {
      \u0275\u0275restoreView(_r6);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.fecharModal());
    });
    \u0275\u0275text(6, "\u2715");
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(7, "div", 25)(8, "p")(9, "strong");
    \u0275\u0275text(10, "Modalidade:");
    \u0275\u0275elementEnd();
    \u0275\u0275text(11);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(12, "p")(13, "strong");
    \u0275\u0275text(14, "Professor:");
    \u0275\u0275elementEnd();
    \u0275\u0275text(15);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(16, "p")(17, "strong");
    \u0275\u0275text(18, "Dia:");
    \u0275\u0275elementEnd();
    \u0275\u0275text(19);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(20, "p")(21, "strong");
    \u0275\u0275text(22, "Hor\xE1rio:");
    \u0275\u0275elementEnd();
    \u0275\u0275text(23);
    \u0275\u0275elementEnd();
    \u0275\u0275template(24, GradeHorariosComponent_Conditional_12_Conditional_24_Template, 4, 1, "p");
    \u0275\u0275elementStart(25, "p")(26, "strong");
    \u0275\u0275text(27, "Alunos:");
    \u0275\u0275elementEnd();
    \u0275\u0275text(28);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(29, "div", 26)(30, "button", 27);
    \u0275\u0275listener("click", function GradeHorariosComponent_Conditional_12_Template_button_click_30_listener() {
      \u0275\u0275restoreView(_r6);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.remover(ctx_r1.horarioSelecionado().id));
    });
    \u0275\u0275text(31, "Remover");
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext();
    \u0275\u0275advance(4);
    \u0275\u0275textInterpolate(ctx_r1.horarioSelecionado().nomeTurma);
    \u0275\u0275advance(7);
    \u0275\u0275textInterpolate1(" ", ctx_r1.horarioSelecionado().nomeModalidade, "");
    \u0275\u0275advance(4);
    \u0275\u0275textInterpolate1(" ", ctx_r1.horarioSelecionado().nomeProfessor, "");
    \u0275\u0275advance(4);
    \u0275\u0275textInterpolate1(" ", ctx_r1.horarioSelecionado().diaSemanaLabel, "");
    \u0275\u0275advance(4);
    \u0275\u0275textInterpolate2(" ", ctx_r1.horarioSelecionado().horaInicio, " \u2013 ", ctx_r1.horarioSelecionado().horaFim, "");
    \u0275\u0275advance();
    \u0275\u0275conditional(24, ctx_r1.horarioSelecionado().sala ? 24 : -1);
    \u0275\u0275advance(4);
    \u0275\u0275textInterpolate2(" ", ctx_r1.horarioSelecionado().totalAlunos, "/", ctx_r1.horarioSelecionado().capacidadeMaxima, "");
  }
}
function GradeHorariosComponent_Conditional_13_Conditional_7_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 32);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(2);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(ctx_r1.erroForm());
  }
}
function GradeHorariosComponent_Conditional_13_For_16_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "option", 38);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const t_r8 = ctx.$implicit;
    \u0275\u0275property("value", t_r8.id);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate2("", t_r8.nome, " \xB7 ", t_r8.modalidadeNome, "");
  }
}
function GradeHorariosComponent_Conditional_13_For_22_Template(rf, ctx) {
  if (rf & 1) {
    const _r9 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "button", 48);
    \u0275\u0275listener("click", function GradeHorariosComponent_Conditional_13_For_22_Template_button_click_0_listener() {
      const d_r10 = \u0275\u0275restoreView(_r9).$implicit;
      const ctx_r1 = \u0275\u0275nextContext(2);
      return \u0275\u0275resetView(ctx_r1.toggleDia(d_r10.value));
    });
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const d_r10 = ctx.$implicit;
    const ctx_r1 = \u0275\u0275nextContext(2);
    \u0275\u0275classProp("selected", ctx_r1.isDiaSelecionado(d_r10.value));
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1(" ", d_r10.label, " ");
  }
}
function GradeHorariosComponent_Conditional_13_Template(rf, ctx) {
  if (rf & 1) {
    const _r7 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 28);
    \u0275\u0275listener("click", function GradeHorariosComponent_Conditional_13_Template_div_click_0_listener() {
      \u0275\u0275restoreView(_r7);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.fecharModal());
    });
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(1, "div", 29)(2, "div", 30)(3, "h3");
    \u0275\u0275text(4, "Novo Hor\xE1rio");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(5, "button", 31);
    \u0275\u0275listener("click", function GradeHorariosComponent_Conditional_13_Template_button_click_5_listener() {
      \u0275\u0275restoreView(_r7);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.fecharModal());
    });
    \u0275\u0275text(6, "\u2715");
    \u0275\u0275elementEnd()();
    \u0275\u0275template(7, GradeHorariosComponent_Conditional_13_Conditional_7_Template, 2, 1, "div", 32);
    \u0275\u0275elementStart(8, "form", 33);
    \u0275\u0275listener("ngSubmit", function GradeHorariosComponent_Conditional_13_Template_form_ngSubmit_8_listener() {
      \u0275\u0275restoreView(_r7);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.salvar());
    });
    \u0275\u0275elementStart(9, "div", 34)(10, "label", 35);
    \u0275\u0275text(11, "Turma *");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(12, "select", 36)(13, "option", 37);
    \u0275\u0275text(14, "Selecione a turma");
    \u0275\u0275elementEnd();
    \u0275\u0275repeaterCreate(15, GradeHorariosComponent_Conditional_13_For_16_Template, 2, 3, "option", 38, _forTrack0);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(17, "div", 34)(18, "label", 35);
    \u0275\u0275text(19, "Dias da Semana *");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(20, "div", 39);
    \u0275\u0275repeaterCreate(21, GradeHorariosComponent_Conditional_13_For_22_Template, 2, 3, "button", 40, _forTrack1);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(23, "div", 41)(24, "div", 34)(25, "label", 35);
    \u0275\u0275text(26, "Sala");
    \u0275\u0275elementEnd();
    \u0275\u0275element(27, "input", 42);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(28, "div", 41)(29, "div", 34)(30, "label", 35);
    \u0275\u0275text(31, "In\xEDcio *");
    \u0275\u0275elementEnd();
    \u0275\u0275element(32, "input", 43);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(33, "div", 34)(34, "label", 35);
    \u0275\u0275text(35, "Fim *");
    \u0275\u0275elementEnd();
    \u0275\u0275element(36, "input", 44);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(37, "div", 45)(38, "button", 46);
    \u0275\u0275listener("click", function GradeHorariosComponent_Conditional_13_Template_button_click_38_listener() {
      \u0275\u0275restoreView(_r7);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.fecharModal());
    });
    \u0275\u0275text(39, "Cancelar");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(40, "button", 47);
    \u0275\u0275text(41);
    \u0275\u0275elementEnd()()()();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext();
    \u0275\u0275advance(7);
    \u0275\u0275conditional(7, ctx_r1.erroForm() ? 7 : -1);
    \u0275\u0275advance();
    \u0275\u0275property("formGroup", ctx_r1.form);
    \u0275\u0275advance(7);
    \u0275\u0275repeater(ctx_r1.turmas());
    \u0275\u0275advance(6);
    \u0275\u0275repeater(ctx_r1.diasOpcoes);
    \u0275\u0275advance(19);
    \u0275\u0275property("disabled", ctx_r1.salvando());
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1(" ", ctx_r1.salvando() ? "Salvando..." : "Criar Hor\xE1rio", " ");
  }
}
var GradeHorariosComponent = class _GradeHorariosComponent {
  constructor() {
    this.horarioService = inject(HorarioService);
    this.turmaService = inject(TurmaService);
    this.fb = inject(FormBuilder);
    this.grade = signal(null);
    this.turmas = signal([]);
    this.carregando = signal(true);
    this.erro = signal("");
    this.horarioSelecionado = signal(null);
    this.modalAberto = signal(false);
    this.salvando = signal(false);
    this.erroForm = signal("");
    this.diasSelecionados = signal([]);
    this.diasOrdem = ["Segunda", "Ter\xE7a", "Quarta", "Quinta", "Sexta", "S\xE1bado", "Domingo"];
    this.diasOpcoes = [
      { label: "Seg", value: 1 },
      { label: "Ter", value: 2 },
      { label: "Qua", value: 3 },
      { label: "Qui", value: 4 },
      { label: "Sex", value: 5 },
      { label: "S\xE1b", value: 6 },
      { label: "Dom", value: 0 }
    ];
    this.form = this.fb.group({
      turmaId: ["", Validators.required],
      horaInicio: ["", Validators.required],
      horaFim: ["", Validators.required],
      sala: [""]
    });
  }
  ngOnInit() {
    this.carregar();
    this.turmaService.getAll({ ativo: true }).subscribe({ next: (r) => this.turmas.set(r.dados ?? []) });
  }
  carregar() {
    this.carregando.set(true);
    this.horarioService.getGrade().subscribe({
      next: (res) => {
        this.grade.set(res.dados ?? null);
        this.carregando.set(false);
      },
      error: () => {
        this.erro.set("Erro ao carregar grade.");
        this.carregando.set(false);
      }
    });
  }
  getDia(dia) {
    return this.grade()?.grade[dia] ?? [];
  }
  corModalidade(nome) {
    let hash = 0;
    for (const c of nome)
      hash = hash * 31 + c.charCodeAt(0) & 4294967295;
    const hue = Math.abs(hash) % 360;
    return `hsl(${hue}, 55%, 55%)`;
  }
  abrirModal() {
    this.form.reset();
    this.diasSelecionados.set([]);
    this.erroForm.set("");
    this.modalAberto.set(true);
  }
  fecharModal() {
    this.modalAberto.set(false);
    this.horarioSelecionado.set(null);
  }
  selecionar(h) {
    this.horarioSelecionado.set(h);
  }
  isDiaSelecionado(dia) {
    return this.diasSelecionados().includes(dia);
  }
  toggleDia(dia) {
    this.diasSelecionados.update((dias) => dias.includes(dia) ? dias.filter((d) => d !== dia) : [...dias, dia]);
  }
  remover(id) {
    if (!confirm("Remover este hor\xE1rio?"))
      return;
    this.horarioService.delete(id).subscribe({
      next: () => {
        this.fecharModal();
        this.carregar();
      },
      error: () => alert("Erro ao remover hor\xE1rio.")
    });
  }
  salvar() {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    if (this.diasSelecionados().length === 0) {
      this.erroForm.set("Selecione pelo menos um dia da semana.");
      return;
    }
    this.salvando.set(true);
    this.erroForm.set("");
    const v = this.form.value;
    const requests = this.diasSelecionados().map((dia) => this.horarioService.create({
      turmaId: v.turmaId,
      diaSemana: dia,
      horaInicio: v.horaInicio,
      horaFim: v.horaFim,
      sala: v.sala ?? void 0
    }));
    forkJoin(requests).subscribe({
      next: () => {
        this.fecharModal();
        this.carregar();
        this.salvando.set(false);
      },
      error: (err) => {
        this.erroForm.set(err.error?.mensagem ?? "Conflito de hor\xE1rio detectado.");
        this.carregar();
        this.salvando.set(false);
      }
    });
  }
  static {
    this.\u0275fac = function GradeHorariosComponent_Factory(t) {
      return new (t || _GradeHorariosComponent)();
    };
  }
  static {
    this.\u0275cmp = /* @__PURE__ */ \u0275\u0275defineComponent({ type: _GradeHorariosComponent, selectors: [["app-grade-horarios"]], standalone: true, features: [\u0275\u0275StandaloneFeature], decls: 14, vars: 3, consts: [[1, "page-container"], [1, "page-header"], [1, "page-title"], [1, "page-subtitle"], [1, "btn-primary", 3, "click"], [1, "skeleton-grade"], [1, "skeleton-row", 2, "height", "200px"], [1, "error-card"], [1, "btn-secondary", 3, "click"], [1, "grade-semanal"], [1, "grade-coluna"], [1, "grade-header"], [1, "grade-aulas"], [1, "aula-card", 3, "border-left-color"], [1, "grade-vazio"], [1, "aula-card", 3, "click"], [1, "aula-hora"], [1, "aula-nome"], [1, "aula-meta"], [1, "aula-ocupacao"], [1, "aula-sala"], [1, "drawer-backdrop", 3, "click"], [1, "drawer"], [1, "drawer-header"], [1, "drawer-close", 3, "click"], [1, "drawer-body"], [1, "drawer-actions"], [1, "btn-danger", 3, "click"], [1, "modal-backdrop", 3, "click"], [1, "modal"], [1, "modal-header"], [1, "modal-close", 3, "click"], [1, "alert-error"], [1, "modal-body", 3, "ngSubmit", "formGroup"], [1, "form-group"], [1, "form-label"], ["formControlName", "turmaId", 1, "form-input"], ["value", ""], [3, "value"], [1, "dias-chips"], ["type", "button", 1, "dia-chip", 3, "selected"], [1, "form-row"], ["formControlName", "sala", "placeholder", "Ex: Tatame A", 1, "form-input"], ["formControlName", "horaInicio", "type", "time", 1, "form-input"], ["formControlName", "horaFim", "type", "time", 1, "form-input"], [1, "modal-actions"], ["type", "button", 1, "btn-secondary", 3, "click"], ["type", "submit", 1, "btn-primary", 3, "disabled"], ["type", "button", 1, "dia-chip", 3, "click"]], template: function GradeHorariosComponent_Template(rf, ctx) {
      if (rf & 1) {
        \u0275\u0275elementStart(0, "div", 0)(1, "div", 1)(2, "div")(3, "h1", 2);
        \u0275\u0275text(4, "Grade de Hor\xE1rios");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(5, "p", 3);
        \u0275\u0275text(6, "Vis\xE3o semanal das aulas");
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(7, "button", 4);
        \u0275\u0275listener("click", function GradeHorariosComponent_Template_button_click_7_listener() {
          return ctx.abrirModal();
        });
        \u0275\u0275text(8, "+ Novo Hor\xE1rio");
        \u0275\u0275elementEnd()();
        \u0275\u0275template(9, GradeHorariosComponent_Conditional_9_Template, 2, 0, "div", 5)(10, GradeHorariosComponent_Conditional_10_Template, 5, 1)(11, GradeHorariosComponent_Conditional_11_Template, 3, 0)(12, GradeHorariosComponent_Conditional_12_Template, 32, 9)(13, GradeHorariosComponent_Conditional_13_Template, 42, 4);
        \u0275\u0275elementEnd();
      }
      if (rf & 2) {
        \u0275\u0275advance(9);
        \u0275\u0275conditional(9, ctx.carregando() ? 9 : ctx.erro() ? 10 : 11);
        \u0275\u0275advance(3);
        \u0275\u0275conditional(12, ctx.horarioSelecionado() ? 12 : -1);
        \u0275\u0275advance();
        \u0275\u0275conditional(13, ctx.modalAberto() ? 13 : -1);
      }
    }, dependencies: [CommonModule, ReactiveFormsModule, \u0275NgNoValidate, NgSelectOption, \u0275NgSelectMultipleOption, DefaultValueAccessor, SelectControlValueAccessor, NgControlStatus, NgControlStatusGroup, FormGroupDirective, FormControlName], styles: ["\n\n.grade-semanal[_ngcontent-%COMP%] {\n  display: grid;\n  grid-template-columns: repeat(7, 1fr);\n  gap: 0;\n  overflow-x: auto;\n  background: var(--app-surface);\n  border: 1px solid var(--app-border);\n  border-radius: 8px;\n}\n.grade-coluna[_ngcontent-%COMP%]    + .grade-coluna[_ngcontent-%COMP%] {\n  border-left: 1px solid var(--app-border);\n}\n.grade-coluna[_ngcontent-%COMP%] {\n  min-width: 130px;\n  padding: 0 8px 8px;\n}\n.grade-header[_ngcontent-%COMP%] {\n  font-size: 0.75rem;\n  font-weight: 600;\n  color: var(--color-text-muted, #64748b);\n  text-align: center;\n  padding: 8px 4px;\n  border-bottom: 1px solid var(--color-border, #e2e8f0);\n  margin-bottom: 8px;\n  text-transform: uppercase;\n  letter-spacing: 0.05em;\n}\n.grade-aulas[_ngcontent-%COMP%] {\n  display: flex;\n  flex-direction: column;\n  gap: 6px;\n}\n.aula-card[_ngcontent-%COMP%] {\n  background: var(--color-surface, #fff);\n  border: 1px solid var(--color-border, #e2e8f0);\n  border-left: 4px solid #6366f1;\n  border-radius: 6px;\n  padding: 8px 10px;\n  cursor: pointer;\n  transition: box-shadow 0.15s;\n  font-size: 0.8rem;\n}\n.aula-card[_ngcontent-%COMP%]:hover {\n  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);\n}\n.aula-hora[_ngcontent-%COMP%] {\n  font-weight: 600;\n  color: var(--color-text, #1e293b);\n  font-size: 0.75rem;\n}\n.aula-nome[_ngcontent-%COMP%] {\n  font-weight: 600;\n  margin: 2px 0;\n}\n.aula-meta[_ngcontent-%COMP%] {\n  color: var(--color-text-muted, #64748b);\n  font-size: 0.72rem;\n}\n.aula-ocupacao[_ngcontent-%COMP%] {\n  color: var(--color-text-muted, #64748b);\n  font-size: 0.72rem;\n}\n.aula-sala[_ngcontent-%COMP%] {\n  color: var(--color-text-muted, #64748b);\n  font-size: 0.72rem;\n  font-style: italic;\n}\n.grade-vazio[_ngcontent-%COMP%] {\n  text-align: center;\n  color: var(--color-text-muted, #94a3b8);\n  font-size: 0.8rem;\n  padding: 12px 0;\n}\n.drawer-backdrop[_ngcontent-%COMP%], .modal-backdrop[_ngcontent-%COMP%] {\n  position: fixed;\n  inset: 0;\n  background: rgba(0, 0, 0, 0.4);\n  z-index: 40;\n}\n.drawer[_ngcontent-%COMP%] {\n  position: fixed;\n  top: 0;\n  right: 0;\n  height: 100%;\n  width: 360px;\n  background: var(--color-surface, #fff);\n  z-index: 50;\n  padding: 24px;\n  box-shadow: -4px 0 24px rgba(0, 0, 0, 0.1);\n  display: flex;\n  flex-direction: column;\n  gap: 16px;\n}\n.drawer-header[_ngcontent-%COMP%] {\n  display: flex;\n  justify-content: space-between;\n  align-items: center;\n}\n.drawer-close[_ngcontent-%COMP%] {\n  background: none;\n  border: none;\n  font-size: 1.2rem;\n  cursor: pointer;\n}\n.drawer-body[_ngcontent-%COMP%] {\n  display: flex;\n  flex-direction: column;\n  gap: 8px;\n}\n.drawer-body[_ngcontent-%COMP%]   p[_ngcontent-%COMP%] {\n  font-size: 0.875rem;\n  margin: 0;\n}\n.drawer-actions[_ngcontent-%COMP%] {\n  margin-top: auto;\n}\n.modal[_ngcontent-%COMP%] {\n  position: fixed;\n  top: 50%;\n  left: 50%;\n  transform: translate(-50%, -50%);\n  background: var(--color-surface, #fff);\n  z-index: 50;\n  padding: 24px;\n  border-radius: 12px;\n  width: 100%;\n  max-width: 480px;\n  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.15);\n}\n.modal-header[_ngcontent-%COMP%] {\n  display: flex;\n  justify-content: space-between;\n  align-items: center;\n  margin-bottom: 16px;\n}\n.modal-close[_ngcontent-%COMP%] {\n  background: none;\n  border: none;\n  font-size: 1.2rem;\n  cursor: pointer;\n}\n.modal-body[_ngcontent-%COMP%] {\n  display: flex;\n  flex-direction: column;\n  gap: 12px;\n}\n.modal-actions[_ngcontent-%COMP%] {\n  display: flex;\n  gap: 8px;\n  justify-content: flex-end;\n  margin-top: 8px;\n}\n.btn-danger[_ngcontent-%COMP%] {\n  padding: 8px 16px;\n  background: #ef4444;\n  color: white;\n  border: none;\n  border-radius: 6px;\n  cursor: pointer;\n  font-size: 0.875rem;\n}\n.dias-chips[_ngcontent-%COMP%] {\n  display: flex;\n  flex-wrap: wrap;\n  gap: 6px;\n}\n.dia-chip[_ngcontent-%COMP%] {\n  padding: 6px 12px;\n  border-radius: 99px;\n  font-size: 12px;\n  font-weight: 600;\n  border: 1.5px solid var(--app-border);\n  background: none;\n  cursor: pointer;\n  color: var(--app-text-2);\n  transition: all 0.15s;\n}\n.dia-chip[_ngcontent-%COMP%]:hover {\n  border-color: #6366f1;\n  color: #6366f1;\n}\n.dia-chip.selected[_ngcontent-%COMP%] {\n  background: #6366f1;\n  border-color: #6366f1;\n  color: #fff;\n}\n/*# sourceMappingURL=grade-horarios.component.css.map */"] });
  }
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && \u0275setClassDebugInfo(GradeHorariosComponent, { className: "GradeHorariosComponent" });
})();
export {
  GradeHorariosComponent
};
//# sourceMappingURL=chunk-MVLAC6OF.js.map
