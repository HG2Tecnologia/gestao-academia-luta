import {
  FuncionarioService
} from "./chunk-UQMVK7T6.js";
import {
  CheckboxControlValueAccessor,
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
  ActivatedRoute,
  Router,
  RouterLink
} from "./chunk-AXNOULNC.js";
import {
  CommonModule,
  inject,
  signal,
  ɵsetClassDebugInfo,
  ɵɵStandaloneFeature,
  ɵɵadvance,
  ɵɵconditional,
  ɵɵdefineComponent,
  ɵɵelement,
  ɵɵelementEnd,
  ɵɵelementStart,
  ɵɵgetCurrentView,
  ɵɵlistener,
  ɵɵnextContext,
  ɵɵproperty,
  ɵɵpureFunction0,
  ɵɵrepeater,
  ɵɵrepeaterCreate,
  ɵɵrepeaterTrackByIdentity,
  ɵɵresetView,
  ɵɵrestoreView,
  ɵɵtemplate,
  ɵɵtext,
  ɵɵtextInterpolate,
  ɵɵtextInterpolate1
} from "./chunk-WZ2AWGAJ.js";
import "./chunk-7G5TR5RR.js";

// src/app/features/funcionarios/pages/form/funcionario-form.component.ts
var _c0 = () => [1, 2, 3];
function FuncionarioFormComponent_Conditional_6_For_2_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275element(0, "div", 5);
  }
}
function FuncionarioFormComponent_Conditional_6_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 4);
    \u0275\u0275repeaterCreate(1, FuncionarioFormComponent_Conditional_6_For_2_Template, 1, 0, "div", 5, \u0275\u0275repeaterTrackByIdentity);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    \u0275\u0275advance();
    \u0275\u0275repeater(\u0275\u0275pureFunction0(0, _c0));
  }
}
function FuncionarioFormComponent_Conditional_7_Conditional_0_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 6);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(2);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(ctx_r1.erro());
  }
}
function FuncionarioFormComponent_Conditional_7_Conditional_7_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 12);
    \u0275\u0275text(1, "Nome \xE9 obrigat\xF3rio (m\xEDnimo 3 caracteres)");
    \u0275\u0275elementEnd();
  }
}
function FuncionarioFormComponent_Conditional_7_Conditional_12_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 12);
    \u0275\u0275text(1, "Telefone \xE9 obrigat\xF3rio");
    \u0275\u0275elementEnd();
  }
}
function FuncionarioFormComponent_Conditional_7_Conditional_18_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 12);
    \u0275\u0275text(1, "E-mail inv\xE1lido");
    \u0275\u0275elementEnd();
  }
}
function FuncionarioFormComponent_Conditional_7_Conditional_23_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 12);
    \u0275\u0275text(1, "Cargo \xE9 obrigat\xF3rio");
    \u0275\u0275elementEnd();
  }
}
function FuncionarioFormComponent_Conditional_7_Conditional_53_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 28)(1, "label", 31)(2, "div", 32);
    \u0275\u0275element(3, "input", 33)(4, "span", 34);
    \u0275\u0275elementEnd();
    \u0275\u0275text(5, " Funcion\xE1rio ativo ");
    \u0275\u0275elementEnd()();
  }
}
function FuncionarioFormComponent_Conditional_7_Template(rf, ctx) {
  if (rf & 1) {
    const _r1 = \u0275\u0275getCurrentView();
    \u0275\u0275template(0, FuncionarioFormComponent_Conditional_7_Conditional_0_Template, 2, 1, "div", 6);
    \u0275\u0275elementStart(1, "form", 7);
    \u0275\u0275listener("ngSubmit", function FuncionarioFormComponent_Conditional_7_Template_form_ngSubmit_1_listener() {
      \u0275\u0275restoreView(_r1);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.salvar());
    });
    \u0275\u0275elementStart(2, "div", 8)(3, "div", 9)(4, "label", 10);
    \u0275\u0275text(5, "Nome completo *");
    \u0275\u0275elementEnd();
    \u0275\u0275element(6, "input", 11);
    \u0275\u0275template(7, FuncionarioFormComponent_Conditional_7_Conditional_7_Template, 2, 0, "span", 12);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(8, "div", 13)(9, "label", 10);
    \u0275\u0275text(10, "Telefone *");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(11, "input", 14);
    \u0275\u0275listener("input", function FuncionarioFormComponent_Conditional_7_Template_input_input_11_listener($event) {
      \u0275\u0275restoreView(_r1);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.mascaraTelefone($event));
    });
    \u0275\u0275elementEnd();
    \u0275\u0275template(12, FuncionarioFormComponent_Conditional_7_Conditional_12_Template, 2, 0, "span", 12);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(13, "div", 8)(14, "div", 9)(15, "label", 10);
    \u0275\u0275text(16, "E-mail");
    \u0275\u0275elementEnd();
    \u0275\u0275element(17, "input", 15);
    \u0275\u0275template(18, FuncionarioFormComponent_Conditional_7_Conditional_18_Template, 2, 0, "span", 12);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(19, "div", 9)(20, "label", 10);
    \u0275\u0275text(21, "Cargo *");
    \u0275\u0275elementEnd();
    \u0275\u0275element(22, "input", 16);
    \u0275\u0275template(23, FuncionarioFormComponent_Conditional_7_Conditional_23_Template, 2, 0, "span", 12);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(24, "div", 13)(25, "label", 10);
    \u0275\u0275text(26, "Perfil *");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(27, "select", 17)(28, "option", 18);
    \u0275\u0275text(29, "Admin");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(30, "option", 19);
    \u0275\u0275text(31, "Professor");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(32, "option", 20);
    \u0275\u0275text(33, "Recepcionista");
    \u0275\u0275elementEnd()()()();
    \u0275\u0275elementStart(34, "div", 21);
    \u0275\u0275text(35, "Permiss\xF5es de acesso");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(36, "div", 22)(37, "label", 23);
    \u0275\u0275element(38, "input", 24);
    \u0275\u0275elementStart(39, "span");
    \u0275\u0275text(40, "Alunos");
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(41, "label", 23);
    \u0275\u0275element(42, "input", 25);
    \u0275\u0275elementStart(43, "span");
    \u0275\u0275text(44, "Turmas");
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(45, "label", 23);
    \u0275\u0275element(46, "input", 26);
    \u0275\u0275elementStart(47, "span");
    \u0275\u0275text(48, "Financeiro");
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(49, "label", 23);
    \u0275\u0275element(50, "input", 27);
    \u0275\u0275elementStart(51, "span");
    \u0275\u0275text(52, "Configura\xE7\xF5es");
    \u0275\u0275elementEnd()()();
    \u0275\u0275template(53, FuncionarioFormComponent_Conditional_7_Conditional_53_Template, 6, 0, "div", 28);
    \u0275\u0275elementStart(54, "div", 29)(55, "a", 3);
    \u0275\u0275text(56, "Cancelar");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(57, "button", 30);
    \u0275\u0275text(58);
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    let tmp_3_0;
    let tmp_4_0;
    let tmp_5_0;
    let tmp_6_0;
    const ctx_r1 = \u0275\u0275nextContext();
    \u0275\u0275conditional(0, ctx_r1.erro() ? 0 : -1);
    \u0275\u0275advance();
    \u0275\u0275property("formGroup", ctx_r1.form);
    \u0275\u0275advance(6);
    \u0275\u0275conditional(7, ((tmp_3_0 = ctx_r1.form.get("nome")) == null ? null : tmp_3_0.invalid) && ((tmp_3_0 = ctx_r1.form.get("nome")) == null ? null : tmp_3_0.touched) ? 7 : -1);
    \u0275\u0275advance(5);
    \u0275\u0275conditional(12, ((tmp_4_0 = ctx_r1.form.get("telefone")) == null ? null : tmp_4_0.invalid) && ((tmp_4_0 = ctx_r1.form.get("telefone")) == null ? null : tmp_4_0.touched) ? 12 : -1);
    \u0275\u0275advance(6);
    \u0275\u0275conditional(18, ((tmp_5_0 = ctx_r1.form.get("email")) == null ? null : tmp_5_0.invalid) && ((tmp_5_0 = ctx_r1.form.get("email")) == null ? null : tmp_5_0.touched) ? 18 : -1);
    \u0275\u0275advance(5);
    \u0275\u0275conditional(23, ((tmp_6_0 = ctx_r1.form.get("cargo")) == null ? null : tmp_6_0.invalid) && ((tmp_6_0 = ctx_r1.form.get("cargo")) == null ? null : tmp_6_0.touched) ? 23 : -1);
    \u0275\u0275advance(30);
    \u0275\u0275conditional(53, ctx_r1.editandoId() ? 53 : -1);
    \u0275\u0275advance(4);
    \u0275\u0275property("disabled", ctx_r1.salvando());
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1(" ", ctx_r1.salvando() ? "Salvando..." : "Salvar", " ");
  }
}
var MODULOS = ["Alunos", "Turmas", "Financeiro", "Configura\xE7\xF5es"];
var FuncionarioFormComponent = class _FuncionarioFormComponent {
  constructor() {
    this.funcionarioService = inject(FuncionarioService);
    this.router = inject(Router);
    this.route = inject(ActivatedRoute);
    this.fb = inject(FormBuilder);
    this.editandoId = signal(null);
    this.salvando = signal(false);
    this.carregando = signal(false);
    this.erro = signal("");
    this.modulos = MODULOS;
    this.form = this.fb.group({
      nome: ["", [Validators.required, Validators.minLength(3)]],
      email: ["", Validators.email],
      telefone: ["", Validators.required],
      cargo: ["", Validators.required],
      perfil: ["Professor", Validators.required],
      permAlunos: [false],
      permTurmas: [false],
      permFinanceiro: [false],
      permConfiguracoes: [false],
      ativo: [true]
    });
  }
  ngOnInit() {
    const id = this.route.snapshot.paramMap.get("id");
    if (id) {
      this.editandoId.set(id);
      this.carregando.set(true);
      this.funcionarioService.getById(id).subscribe({
        next: (res) => {
          if (res.dados) {
            const d = res.dados;
            this.form.patchValue({
              nome: d.nome,
              email: d.email,
              telefone: d.telefone ?? "",
              cargo: d.cargo,
              perfil: d.perfil,
              ativo: d.ativo,
              permAlunos: d.permissoes?.["Alunos"] ?? false,
              permTurmas: d.permissoes?.["Turmas"] ?? false,
              permFinanceiro: d.permissoes?.["Financeiro"] ?? false,
              permConfiguracoes: d.permissoes?.["Configura\xE7\xF5es"] ?? false
            });
          }
          this.carregando.set(false);
        },
        error: () => {
          this.erro.set("Erro ao carregar dados.");
          this.carregando.set(false);
        }
      });
    }
  }
  mascaraTelefone(event) {
    const input = event.target;
    const nums = input.value.replace(/\D/g, "").slice(0, 11);
    let v = "";
    if (nums.length > 6)
      v = `(${nums.slice(0, 2)}) ${nums.slice(2, 7)}-${nums.slice(7)}`;
    else if (nums.length > 2)
      v = `(${nums.slice(0, 2)}) ${nums.slice(2)}`;
    else if (nums.length > 0)
      v = `(${nums}`;
    input.value = v;
    this.form.get("telefone")?.setValue(v, { emitEvent: false });
  }
  salvar() {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    this.salvando.set(true);
    this.erro.set("");
    const v = this.form.value;
    const id = this.editandoId();
    const permissoes = {
      Alunos: v.permAlunos ?? false,
      Turmas: v.permTurmas ?? false,
      Financeiro: v.permFinanceiro ?? false,
      "Configura\xE7\xF5es": v.permConfiguracoes ?? false
    };
    const req$ = id ? this.funcionarioService.update(id, {
      nome: v.nome,
      email: v.email || void 0,
      telefone: v.telefone,
      cargo: v.cargo,
      perfil: v.perfil,
      permissoes,
      ativo: v.ativo
    }) : this.funcionarioService.create({
      nome: v.nome,
      email: v.email || void 0,
      telefone: v.telefone,
      cargo: v.cargo,
      perfil: v.perfil,
      permissoes
    });
    req$.subscribe({
      next: (res) => {
        if (res.sucesso)
          this.router.navigate(["/app/funcionarios"]);
        else {
          this.erro.set(res.mensagem ?? "Erro ao salvar.");
          this.salvando.set(false);
        }
      },
      error: (err) => {
        this.erro.set(err.error?.mensagem ?? "Erro ao salvar.");
        this.salvando.set(false);
      }
    });
  }
  static {
    this.\u0275fac = function FuncionarioFormComponent_Factory(t) {
      return new (t || _FuncionarioFormComponent)();
    };
  }
  static {
    this.\u0275cmp = /* @__PURE__ */ \u0275\u0275defineComponent({ type: _FuncionarioFormComponent, selectors: [["app-funcionario-form"]], standalone: true, features: [\u0275\u0275StandaloneFeature], decls: 8, vars: 2, consts: [[1, "page-container"], [1, "page-header"], [1, "page-title"], ["routerLink", "/app/funcionarios", 1, "btn-secondary"], [1, "skeleton-list"], [1, "skeleton-row"], [1, "alert-error"], [1, "form-card", 3, "ngSubmit", "formGroup"], [1, "form-row"], [1, "form-group", 2, "flex", "2"], [1, "form-label"], ["formControlName", "nome", "placeholder", "Nome do funcion\xE1rio", 1, "form-input"], [1, "form-error"], [1, "form-group"], ["formControlName", "telefone", "placeholder", "(11) 99999-9999", "inputmode", "numeric", 1, "form-input", 3, "input"], ["formControlName", "email", "type", "email", "placeholder", "email@academia.com", 1, "form-input"], ["formControlName", "cargo", "placeholder", "Ex: Professor de Jiu-Jitsu", 1, "form-input"], ["formControlName", "perfil", 1, "form-input"], ["value", "Admin"], ["value", "Professor"], ["value", "Recepcionista"], [1, "form-section-title"], [1, "permissoes-grid"], [1, "perm-item"], ["formControlName", "permAlunos", "type", "checkbox"], ["formControlName", "permTurmas", "type", "checkbox"], ["formControlName", "permFinanceiro", "type", "checkbox"], ["formControlName", "permConfiguracoes", "type", "checkbox"], [1, "form-group", 2, "margin-top", "16px"], [1, "form-actions"], ["type", "submit", 1, "btn-primary", 3, "disabled"], [1, "toggle-label"], [1, "toggle-switch"], ["formControlName", "ativo", "type", "checkbox"], [1, "toggle-slider"]], template: function FuncionarioFormComponent_Template(rf, ctx) {
      if (rf & 1) {
        \u0275\u0275elementStart(0, "div", 0)(1, "div", 1)(2, "h1", 2);
        \u0275\u0275text(3);
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(4, "a", 3);
        \u0275\u0275text(5, "\u2190 Voltar");
        \u0275\u0275elementEnd()();
        \u0275\u0275template(6, FuncionarioFormComponent_Conditional_6_Template, 3, 1, "div", 4)(7, FuncionarioFormComponent_Conditional_7_Template, 59, 9);
        \u0275\u0275elementEnd();
      }
      if (rf & 2) {
        \u0275\u0275advance(3);
        \u0275\u0275textInterpolate(ctx.editandoId() ? "Editar Funcion\xE1rio" : "Novo Funcion\xE1rio");
        \u0275\u0275advance(3);
        \u0275\u0275conditional(6, ctx.carregando() ? 6 : 7);
      }
    }, dependencies: [CommonModule, ReactiveFormsModule, \u0275NgNoValidate, NgSelectOption, \u0275NgSelectMultipleOption, DefaultValueAccessor, CheckboxControlValueAccessor, SelectControlValueAccessor, NgControlStatus, NgControlStatusGroup, FormGroupDirective, FormControlName, RouterLink], styles: [".form-section-title[_ngcontent-%COMP%] { font-size: 13px; font-weight: 600; color: var(--color-text-secondary); text-transform: uppercase; letter-spacing: 0.05em; margin: 16px 0 8px; }\n  .form-error[_ngcontent-%COMP%] { font-size: 12px; color: var(--color-danger, #ef4444); margin-top: 4px; display: block; }\n  .permissoes-grid[_ngcontent-%COMP%] { display: grid; grid-template-columns: repeat(auto-fill, minmax(140px, 1fr)); gap: 8px; }\n  .perm-item[_ngcontent-%COMP%] { display: flex; align-items: center; gap: 8px; padding: 10px 12px; background: var(--color-surface); border: 1px solid var(--color-border); border-radius: 8px; cursor: pointer; font-size: 13px; }\n  .perm-item[_ngcontent-%COMP%]:has(input:checked) { border-color: var(--color-primary, #6366f1); background: rgba(99,102,241,0.08); }\n  .toggle-label[_ngcontent-%COMP%] { display: flex; align-items: center; gap: 12px; cursor: pointer; font-size: 14px; }\n  .toggle-switch[_ngcontent-%COMP%] { position: relative; width: 40px; height: 22px; }\n  .toggle-switch[_ngcontent-%COMP%]   input[_ngcontent-%COMP%] { opacity: 0; width: 0; height: 0; }\n  .toggle-slider[_ngcontent-%COMP%] { position: absolute; inset: 0; background: var(--color-border); border-radius: 99px; transition: background 0.2s; cursor: pointer; }\n  .toggle-slider[_ngcontent-%COMP%]::before { content: ''; position: absolute; height: 16px; width: 16px; left: 3px; top: 3px; background: white; border-radius: 50%; transition: transform 0.2s; }\n  .toggle-switch[_ngcontent-%COMP%]   input[_ngcontent-%COMP%]:checked    + .toggle-slider[_ngcontent-%COMP%] { background: var(--color-primary, #6366f1); }\n  .toggle-switch[_ngcontent-%COMP%]   input[_ngcontent-%COMP%]:checked    + .toggle-slider[_ngcontent-%COMP%]::before { transform: translateX(18px); }"] });
  }
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && \u0275setClassDebugInfo(FuncionarioFormComponent, { className: "FuncionarioFormComponent" });
})();
export {
  FuncionarioFormComponent
};
//# sourceMappingURL=chunk-QO7DDKFO.js.map
