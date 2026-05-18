import {
  UsuarioService
} from "./chunk-P4PGH6V4.js";
import {
  ModalidadeService
} from "./chunk-ZN4AZHLY.js";
import {
  TurmaService
} from "./chunk-S4MMSQ6J.js";
import {
  CheckboxControlValueAccessor,
  DefaultValueAccessor,
  FormBuilder,
  FormControlName,
  FormGroupDirective,
  FormsModule,
  MinValidator,
  NgControlStatus,
  NgControlStatusGroup,
  NgModel,
  NgSelectOption,
  NumberValueAccessor,
  ReactiveFormsModule,
  SelectControlValueAccessor,
  Validators,
  ɵNgNoValidate,
  ɵNgSelectMultipleOption
} from "./chunk-JQJL26HT.js";
import "./chunk-Z5CKO2JM.js";
import {
  ActivatedRoute,
  Router,
  RouterLink
} from "./chunk-AXNOULNC.js";
import {
  CommonModule,
  computed,
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
  ɵɵnamespaceHTML,
  ɵɵnamespaceSVG,
  ɵɵnextContext,
  ɵɵproperty,
  ɵɵpureFunction0,
  ɵɵrepeater,
  ɵɵrepeaterCreate,
  ɵɵresetView,
  ɵɵrestoreView,
  ɵɵtemplate,
  ɵɵtext,
  ɵɵtextInterpolate,
  ɵɵtextInterpolate1
} from "./chunk-WZ2AWGAJ.js";
import "./chunk-7G5TR5RR.js";

// src/app/features/turmas/pages/form/turma-form.component.ts
var _forTrack0 = ($index, $item) => $item.id;
var _c0 = () => ({ standalone: true });
function TurmaFormComponent_Conditional_9_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 5);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(1, "svg", 31);
    \u0275\u0275element(2, "circle", 32)(3, "line", 33)(4, "line", 34);
    \u0275\u0275elementEnd();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(5, "div")(6, "strong");
    \u0275\u0275text(7, "Nenhuma modalidade cadastrada.");
    \u0275\u0275elementEnd();
    \u0275\u0275text(8, " Voc\xEA precisa criar uma modalidade antes de criar uma turma. ");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(9, "a", 35);
    \u0275\u0275text(10, "Criar modalidade");
    \u0275\u0275elementEnd()();
  }
}
function TurmaFormComponent_Conditional_10_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 6);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(ctx_r0.erro());
  }
}
function TurmaFormComponent_Conditional_16_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 11);
    \u0275\u0275text(1, "Nome obrigat\xF3rio (m\xEDn. 3 caracteres)");
    \u0275\u0275elementEnd();
  }
}
function TurmaFormComponent_For_25_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "option", 15);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const m_r2 = ctx.$implicit;
    \u0275\u0275property("value", m_r2.id);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(m_r2.nome);
  }
}
function TurmaFormComponent_Conditional_26_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 11);
    \u0275\u0275text(1, "Selecione uma modalidade");
    \u0275\u0275elementEnd();
  }
}
function TurmaFormComponent_Conditional_46_Template(rf, ctx) {
  if (rf & 1) {
    const _r3 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "button", 36);
    \u0275\u0275listener("click", function TurmaFormComponent_Conditional_46_Template_button_click_0_listener() {
      \u0275\u0275restoreView(_r3);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.buscaProfessor.set(""));
    });
    \u0275\u0275text(1, "\u2715");
    \u0275\u0275elementEnd();
  }
}
function TurmaFormComponent_For_49_Conditional_8_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 41);
    \u0275\u0275text(1, "\u2713");
    \u0275\u0275elementEnd();
  }
}
function TurmaFormComponent_For_49_Template(rf, ctx) {
  if (rf & 1) {
    const _r4 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "button", 37);
    \u0275\u0275listener("click", function TurmaFormComponent_For_49_Template_button_click_0_listener() {
      let tmp_11_0;
      const p_r5 = \u0275\u0275restoreView(_r4).$implicit;
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView((tmp_11_0 = ctx_r0.form.get("professorId")) == null ? null : tmp_11_0.setValue(p_r5.id));
    });
    \u0275\u0275elementStart(1, "div", 38);
    \u0275\u0275text(2);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "div")(4, "div", 39);
    \u0275\u0275text(5);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(6, "div", 40);
    \u0275\u0275text(7);
    \u0275\u0275elementEnd()();
    \u0275\u0275template(8, TurmaFormComponent_For_49_Conditional_8_Template, 2, 0, "span", 41);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    let tmp_10_0;
    let tmp_14_0;
    const p_r5 = ctx.$implicit;
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275classProp("selected", ((tmp_10_0 = ctx_r0.form.get("professorId")) == null ? null : tmp_10_0.value) === p_r5.id);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(p_r5.nome.charAt(0));
    \u0275\u0275advance(3);
    \u0275\u0275textInterpolate(p_r5.nome);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(p_r5.email);
    \u0275\u0275advance();
    \u0275\u0275conditional(8, ((tmp_14_0 = ctx_r0.form.get("professorId")) == null ? null : tmp_14_0.value) === p_r5.id ? 8 : -1);
  }
}
function TurmaFormComponent_ForEmpty_50_Conditional_0_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 42)(1, "span", 43);
    \u0275\u0275text(2, "Nenhum professor cadastrado ainda.");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "a", 44);
    \u0275\u0275text(4, "Cadastrar professor");
    \u0275\u0275elementEnd()();
  }
}
function TurmaFormComponent_ForEmpty_50_Conditional_1_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 45);
    \u0275\u0275text(1, "Nenhum professor encontrado.");
    \u0275\u0275elementEnd();
  }
}
function TurmaFormComponent_ForEmpty_50_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275template(0, TurmaFormComponent_ForEmpty_50_Conditional_0_Template, 5, 0, "div", 42)(1, TurmaFormComponent_ForEmpty_50_Conditional_1_Template, 2, 0);
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275conditional(0, ctx_r0.professores().length === 0 ? 0 : 1);
  }
}
function TurmaFormComponent_Conditional_51_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 11);
    \u0275\u0275text(1, "Selecione um professor");
    \u0275\u0275elementEnd();
  }
}
function TurmaFormComponent_Conditional_57_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 11);
    \u0275\u0275text(1, "Capacidade deve ser maior que 0");
    \u0275\u0275elementEnd();
  }
}
function TurmaFormComponent_Conditional_58_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 27)(1, "label", 46);
    \u0275\u0275element(2, "input", 47);
    \u0275\u0275text(3, " Turma ativa ");
    \u0275\u0275elementEnd()();
  }
}
function TurmaFormComponent_Conditional_63_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275text(0, " Salvando... ");
  }
}
function TurmaFormComponent_Conditional_64_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275text(0);
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275textInterpolate1(" ", ctx_r0.modoEdicao() ? "Salvar altera\xE7\xF5es" : "Criar turma", " ");
  }
}
var TurmaFormComponent = class _TurmaFormComponent {
  constructor() {
    this.fb = inject(FormBuilder);
    this.turmaService = inject(TurmaService);
    this.modalidadeService = inject(ModalidadeService);
    this.usuarioService = inject(UsuarioService);
    this.router = inject(Router);
    this.route = inject(ActivatedRoute);
    this.turmaId = signal(null);
    this.carregando = signal(false);
    this.erro = signal("");
    this.modoEdicao = signal(false);
    this.modalidades = signal([]);
    this.professores = signal([]);
    this.buscaProfessor = signal("");
    this.professoresFiltrados = computed(() => {
      const q = this.buscaProfessor().toLowerCase();
      return q ? this.professores().filter((p) => p.nome.toLowerCase().includes(q)) : this.professores();
    });
    this.form = this.fb.group({
      nome: ["", [Validators.required, Validators.minLength(3)]],
      modalidadeId: ["", Validators.required],
      professorId: ["", Validators.required],
      nivel: [""],
      capacidadeMaxima: [20, [Validators.required, Validators.min(1)]],
      ativo: [true]
    });
  }
  ngOnInit() {
    this.modalidadeService.getAll().subscribe({ next: (r) => this.modalidades.set(r.dados ?? []) });
    this.usuarioService.getProfessores().subscribe({ next: (r) => this.professores.set(r.dados ?? []) });
    const id = this.route.snapshot.paramMap.get("id");
    if (id) {
      this.turmaId.set(id);
      this.modoEdicao.set(true);
      this.carregarTurma(id);
    }
  }
  carregarTurma(id) {
    this.carregando.set(true);
    this.turmaService.getById(id).subscribe({
      next: (res) => {
        if (res.dados) {
          this.form.patchValue({
            nome: res.dados.nome,
            modalidadeId: res.dados.modalidadeId,
            professorId: res.dados.professorId,
            nivel: res.dados.nivel ?? "",
            capacidadeMaxima: res.dados.capacidadeMaxima,
            ativo: res.dados.ativo
          });
        }
        this.carregando.set(false);
      },
      error: () => {
        this.erro.set("Erro ao carregar turma.");
        this.carregando.set(false);
      }
    });
  }
  submit() {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    const dados = this.form.value;
    this.carregando.set(true);
    this.erro.set("");
    const id = this.turmaId();
    const request$ = id ? this.turmaService.update(id, {
      nome: dados.nome,
      modalidadeId: dados.modalidadeId,
      professorId: dados.professorId,
      nivel: dados.nivel ?? void 0,
      capacidadeMaxima: dados.capacidadeMaxima,
      ativo: dados.ativo
    }) : this.turmaService.create({
      nome: dados.nome,
      modalidadeId: dados.modalidadeId,
      professorId: dados.professorId,
      nivel: dados.nivel ?? void 0,
      capacidadeMaxima: dados.capacidadeMaxima
    });
    request$.subscribe({
      next: (res) => {
        if (res.sucesso && res.dados) {
          this.router.navigate(["/app/turmas", res.dados.id]);
        } else {
          this.erro.set(res.mensagem ?? "Erro ao salvar turma.");
          this.carregando.set(false);
        }
      },
      error: (err) => {
        this.erro.set(err.error?.mensagem ?? err.error?.title ?? "Erro ao salvar turma.");
        this.carregando.set(false);
      }
    });
  }
  static {
    this.\u0275fac = function TurmaFormComponent_Factory(t) {
      return new (t || _TurmaFormComponent)();
    };
  }
  static {
    this.\u0275cmp = /* @__PURE__ */ \u0275\u0275defineComponent({ type: _TurmaFormComponent, selectors: [["app-turma-form"]], standalone: true, features: [\u0275\u0275StandaloneFeature], decls: 65, vars: 19, consts: [[1, "page-container"], [1, "page-header"], [1, "breadcrumb"], ["routerLink", "/app/turmas", 1, "breadcrumb-link"], [1, "page-title"], [1, "alerta-prereq"], [1, "alert-error", 2, "margin-bottom", "16px"], [1, "form-card", 3, "ngSubmit", "formGroup"], [1, "form-group"], [1, "form-label"], ["formControlName", "nome", "placeholder", "Ex: Jiu-Jitsu Adulto A", 1, "form-input"], [1, "form-error"], [1, "form-row"], ["formControlName", "modalidadeId", 1, "form-input"], ["value", ""], [3, "value"], ["formControlName", "nivel", 1, "form-input"], ["value", "Iniciante"], ["value", "Intermedi\xE1rio"], ["value", "Avan\xE7ado"], ["value", "Competi\xE7\xE3o"], [1, "professor-search-wrapper"], ["placeholder", "Buscar professor pelo nome...", 1, "form-input", "professor-search-input", 3, "ngModelChange", "ngModel", "ngModelOptions"], ["type", "button", 1, "professor-clear"], [1, "professor-list"], ["type", "button", 1, "professor-option", 3, "selected"], ["formControlName", "capacidadeMaxima", "type", "number", "min", "1", 1, "form-input"], [1, "form-group", 2, "justify-content", "flex-end", "padding-top", "22px"], [1, "form-actions"], ["type", "button", "routerLink", "/app/turmas", 1, "btn-secondary"], ["type", "submit", 1, "btn-primary", 3, "disabled"], ["width", "18", "height", "18", "fill", "none", "stroke", "currentColor", "stroke-width", "2", "viewBox", "0 0 24 24"], ["cx", "12", "cy", "12", "r", "10"], ["x1", "12", "y1", "8", "x2", "12", "y2", "12"], ["x1", "12", "y1", "16", "x2", "12.01", "y2", "16"], ["routerLink", "/app/modalidades/novo", 1, "btn-primary", 2, "white-space", "nowrap", "font-size", "13px", "padding", "8px 14px"], ["type", "button", 1, "professor-clear", 3, "click"], ["type", "button", 1, "professor-option", 3, "click"], [1, "professor-avatar"], [2, "font-weight", "500", "font-size", "13px"], [2, "font-size", "11px", "color", "var(--color-text-secondary)"], [1, "check-icon", 2, "margin-left", "auto"], [1, "professor-empty", 2, "display", "flex", "flex-direction", "column", "align-items", "center", "gap", "8px", "padding", "16px"], [2, "color", "var(--app-text-3)", "font-size", "13px"], ["routerLink", "/app/funcionarios/novo", 1, "btn-primary", 2, "font-size", "12px", "padding", "6px 12px"], [1, "professor-empty"], [1, "form-label", "checkbox-label"], ["formControlName", "ativo", "type", "checkbox", 1, "form-checkbox"]], template: function TurmaFormComponent_Template(rf, ctx) {
      if (rf & 1) {
        \u0275\u0275elementStart(0, "div", 0)(1, "div", 1)(2, "div")(3, "div", 2)(4, "a", 3);
        \u0275\u0275text(5, "Turmas");
        \u0275\u0275elementEnd();
        \u0275\u0275text(6);
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(7, "h1", 4);
        \u0275\u0275text(8);
        \u0275\u0275elementEnd()()();
        \u0275\u0275template(9, TurmaFormComponent_Conditional_9_Template, 11, 0, "div", 5)(10, TurmaFormComponent_Conditional_10_Template, 2, 1, "div", 6);
        \u0275\u0275elementStart(11, "form", 7);
        \u0275\u0275listener("ngSubmit", function TurmaFormComponent_Template_form_ngSubmit_11_listener() {
          return ctx.submit();
        });
        \u0275\u0275elementStart(12, "div", 8)(13, "label", 9);
        \u0275\u0275text(14, "Nome *");
        \u0275\u0275elementEnd();
        \u0275\u0275element(15, "input", 10);
        \u0275\u0275template(16, TurmaFormComponent_Conditional_16_Template, 2, 0, "span", 11);
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(17, "div", 12)(18, "div", 8)(19, "label", 9);
        \u0275\u0275text(20, "Modalidade *");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(21, "select", 13)(22, "option", 14);
        \u0275\u0275text(23, "Selecione a modalidade");
        \u0275\u0275elementEnd();
        \u0275\u0275repeaterCreate(24, TurmaFormComponent_For_25_Template, 2, 2, "option", 15, _forTrack0);
        \u0275\u0275elementEnd();
        \u0275\u0275template(26, TurmaFormComponent_Conditional_26_Template, 2, 0, "span", 11);
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(27, "div", 8)(28, "label", 9);
        \u0275\u0275text(29, "N\xEDvel");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(30, "select", 16)(31, "option", 14);
        \u0275\u0275text(32, "Sem n\xEDvel");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(33, "option", 17);
        \u0275\u0275text(34, "Iniciante");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(35, "option", 18);
        \u0275\u0275text(36, "Intermedi\xE1rio");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(37, "option", 19);
        \u0275\u0275text(38, "Avan\xE7ado");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(39, "option", 20);
        \u0275\u0275text(40, "Competi\xE7\xE3o");
        \u0275\u0275elementEnd()()()();
        \u0275\u0275elementStart(41, "div", 8)(42, "label", 9);
        \u0275\u0275text(43, "Professor *");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(44, "div", 21)(45, "input", 22);
        \u0275\u0275listener("ngModelChange", function TurmaFormComponent_Template_input_ngModelChange_45_listener($event) {
          return ctx.buscaProfessor.set($event);
        });
        \u0275\u0275elementEnd();
        \u0275\u0275template(46, TurmaFormComponent_Conditional_46_Template, 2, 0, "button", 23);
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(47, "div", 24);
        \u0275\u0275repeaterCreate(48, TurmaFormComponent_For_49_Template, 9, 6, "button", 25, _forTrack0, false, TurmaFormComponent_ForEmpty_50_Template, 2, 1);
        \u0275\u0275elementEnd();
        \u0275\u0275template(51, TurmaFormComponent_Conditional_51_Template, 2, 0, "span", 11);
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(52, "div", 12)(53, "div", 8)(54, "label", 9);
        \u0275\u0275text(55, "Capacidade M\xE1xima *");
        \u0275\u0275elementEnd();
        \u0275\u0275element(56, "input", 26);
        \u0275\u0275template(57, TurmaFormComponent_Conditional_57_Template, 2, 0, "span", 11);
        \u0275\u0275elementEnd();
        \u0275\u0275template(58, TurmaFormComponent_Conditional_58_Template, 4, 0, "div", 27);
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(59, "div", 28)(60, "button", 29);
        \u0275\u0275text(61, "Cancelar");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(62, "button", 30);
        \u0275\u0275template(63, TurmaFormComponent_Conditional_63_Template, 1, 0)(64, TurmaFormComponent_Conditional_64_Template, 1, 1);
        \u0275\u0275elementEnd()()()();
      }
      if (rf & 2) {
        let tmp_5_0;
        let tmp_7_0;
        let tmp_13_0;
        let tmp_14_0;
        \u0275\u0275advance(6);
        \u0275\u0275textInterpolate1(" / ", ctx.modoEdicao() ? "Editar" : "Nova", "");
        \u0275\u0275advance(2);
        \u0275\u0275textInterpolate(ctx.modoEdicao() ? "Editar Turma" : "Nova Turma");
        \u0275\u0275advance();
        \u0275\u0275conditional(9, !ctx.modoEdicao() && ctx.modalidades().length === 0 && !ctx.carregando() ? 9 : -1);
        \u0275\u0275advance();
        \u0275\u0275conditional(10, ctx.erro() ? 10 : -1);
        \u0275\u0275advance();
        \u0275\u0275property("formGroup", ctx.form);
        \u0275\u0275advance(5);
        \u0275\u0275conditional(16, ((tmp_5_0 = ctx.form.get("nome")) == null ? null : tmp_5_0.invalid) && ((tmp_5_0 = ctx.form.get("nome")) == null ? null : tmp_5_0.touched) ? 16 : -1);
        \u0275\u0275advance(8);
        \u0275\u0275repeater(ctx.modalidades());
        \u0275\u0275advance(2);
        \u0275\u0275conditional(26, ((tmp_7_0 = ctx.form.get("modalidadeId")) == null ? null : tmp_7_0.invalid) && ((tmp_7_0 = ctx.form.get("modalidadeId")) == null ? null : tmp_7_0.touched) ? 26 : -1);
        \u0275\u0275advance(19);
        \u0275\u0275property("ngModel", ctx.buscaProfessor())("ngModelOptions", \u0275\u0275pureFunction0(18, _c0));
        \u0275\u0275advance();
        \u0275\u0275conditional(46, ctx.buscaProfessor() ? 46 : -1);
        \u0275\u0275advance();
        \u0275\u0275classProp("has-results", ctx.professoresFiltrados().length > 0);
        \u0275\u0275advance();
        \u0275\u0275repeater(ctx.professoresFiltrados());
        \u0275\u0275advance(3);
        \u0275\u0275conditional(51, ((tmp_13_0 = ctx.form.get("professorId")) == null ? null : tmp_13_0.invalid) && ((tmp_13_0 = ctx.form.get("professorId")) == null ? null : tmp_13_0.touched) ? 51 : -1);
        \u0275\u0275advance(6);
        \u0275\u0275conditional(57, ((tmp_14_0 = ctx.form.get("capacidadeMaxima")) == null ? null : tmp_14_0.invalid) && ((tmp_14_0 = ctx.form.get("capacidadeMaxima")) == null ? null : tmp_14_0.touched) ? 57 : -1);
        \u0275\u0275advance();
        \u0275\u0275conditional(58, ctx.modoEdicao() ? 58 : -1);
        \u0275\u0275advance(4);
        \u0275\u0275property("disabled", ctx.carregando());
        \u0275\u0275advance();
        \u0275\u0275conditional(63, ctx.carregando() ? 63 : 64);
      }
    }, dependencies: [CommonModule, FormsModule, \u0275NgNoValidate, NgSelectOption, \u0275NgSelectMultipleOption, DefaultValueAccessor, NumberValueAccessor, CheckboxControlValueAccessor, SelectControlValueAccessor, NgControlStatus, NgControlStatusGroup, MinValidator, NgModel, ReactiveFormsModule, FormGroupDirective, FormControlName, RouterLink], styles: [".alerta-prereq[_ngcontent-%COMP%] { display: flex; align-items: center; gap: 12px; background: #fffbeb; border: 1px solid #fbbf24; border-radius: 10px; padding: 14px 16px; margin-bottom: 16px; color: #92400e; font-size: 13px; flex-wrap: wrap; }\n  .alerta-prereq[_ngcontent-%COMP%]   svg[_ngcontent-%COMP%] { flex-shrink: 0; color: #f59e0b; }\n  .alerta-prereq[_ngcontent-%COMP%]   div[_ngcontent-%COMP%] { flex: 1; }\n  .form-error[_ngcontent-%COMP%] { font-size: 12px; color: var(--color-danger, #ef4444); margin-top: 4px; display: block; }\n  .professor-search-wrapper[_ngcontent-%COMP%] { position: relative; }\n  .professor-search-input[_ngcontent-%COMP%] { padding-right: 36px; }\n  .professor-clear[_ngcontent-%COMP%] { position: absolute; right: 10px; top: 50%; transform: translateY(-50%); background: none; border: none; cursor: pointer; color: var(--color-text-secondary); font-size: 14px; padding: 4px; line-height: 1; }\n  .professor-list[_ngcontent-%COMP%] { border: 1px solid var(--color-border); border-radius: 8px; max-height: 220px; overflow-y: auto; margin-top: 6px; background: var(--color-surface); }\n  .professor-option[_ngcontent-%COMP%] { display: flex; align-items: center; gap: 10px; width: 100%; padding: 10px 12px; border: none; background: none; cursor: pointer; text-align: left; transition: background 0.15s; border-bottom: 1px solid var(--color-border); }\n  .professor-option[_ngcontent-%COMP%]:last-child { border-bottom: none; }\n  .professor-option[_ngcontent-%COMP%]:hover { background: rgba(99,102,241,0.06); }\n  .professor-option.selected[_ngcontent-%COMP%] { background: rgba(99,102,241,0.1); }\n  .professor-avatar[_ngcontent-%COMP%] { width: 30px; height: 30px; border-radius: 50%; background: var(--color-primary, #6366f1); color: white; display: flex; align-items: center; justify-content: center; font-size: 13px; font-weight: 700; flex-shrink: 0; }\n  .professor-empty[_ngcontent-%COMP%] { padding: 14px 12px; font-size: 13px; color: var(--color-text-secondary); text-align: center; }\n  .check-icon[_ngcontent-%COMP%] { color: var(--color-primary, #6366f1); font-weight: 700; }"] });
  }
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && \u0275setClassDebugInfo(TurmaFormComponent, { className: "TurmaFormComponent" });
})();
export {
  TurmaFormComponent
};
//# sourceMappingURL=chunk-EFKAJ3N7.js.map
