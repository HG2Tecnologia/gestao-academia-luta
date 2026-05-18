import {
  ModalidadeService
} from "./chunk-ZN4AZHLY.js";
import {
  CheckboxControlValueAccessor,
  DefaultValueAccessor,
  FormBuilder,
  FormControlName,
  FormGroupDirective,
  NgControlStatus,
  NgControlStatusGroup,
  ReactiveFormsModule,
  Validators,
  ɵNgNoValidate
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

// src/app/features/modalidades/pages/form/modalidade-form.component.ts
var _c0 = () => [1, 2, 3];
function ModalidadeFormComponent_Conditional_6_For_2_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275element(0, "div", 5);
  }
}
function ModalidadeFormComponent_Conditional_6_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 4);
    \u0275\u0275repeaterCreate(1, ModalidadeFormComponent_Conditional_6_For_2_Template, 1, 0, "div", 5, \u0275\u0275repeaterTrackByIdentity);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    \u0275\u0275advance();
    \u0275\u0275repeater(\u0275\u0275pureFunction0(0, _c0));
  }
}
function ModalidadeFormComponent_Conditional_7_Conditional_0_Template(rf, ctx) {
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
function ModalidadeFormComponent_Conditional_7_Conditional_6_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 11);
    \u0275\u0275text(1, "Nome \xE9 obrigat\xF3rio (m\xEDnimo 2 caracteres)");
    \u0275\u0275elementEnd();
  }
}
function ModalidadeFormComponent_Conditional_7_Conditional_11_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 8)(1, "label", 15)(2, "div", 16);
    \u0275\u0275element(3, "input", 17)(4, "span", 18);
    \u0275\u0275elementEnd();
    \u0275\u0275text(5, " Modalidade ativa ");
    \u0275\u0275elementEnd()();
  }
}
function ModalidadeFormComponent_Conditional_7_Template(rf, ctx) {
  if (rf & 1) {
    const _r1 = \u0275\u0275getCurrentView();
    \u0275\u0275template(0, ModalidadeFormComponent_Conditional_7_Conditional_0_Template, 2, 1, "div", 6);
    \u0275\u0275elementStart(1, "form", 7);
    \u0275\u0275listener("ngSubmit", function ModalidadeFormComponent_Conditional_7_Template_form_ngSubmit_1_listener() {
      \u0275\u0275restoreView(_r1);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.salvar());
    });
    \u0275\u0275elementStart(2, "div", 8)(3, "label", 9);
    \u0275\u0275text(4, "Nome *");
    \u0275\u0275elementEnd();
    \u0275\u0275element(5, "input", 10);
    \u0275\u0275template(6, ModalidadeFormComponent_Conditional_7_Conditional_6_Template, 2, 0, "span", 11);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(7, "div", 8)(8, "label", 9);
    \u0275\u0275text(9, "Descri\xE7\xE3o");
    \u0275\u0275elementEnd();
    \u0275\u0275element(10, "textarea", 12);
    \u0275\u0275elementEnd();
    \u0275\u0275template(11, ModalidadeFormComponent_Conditional_7_Conditional_11_Template, 6, 0, "div", 8);
    \u0275\u0275elementStart(12, "div", 13)(13, "a", 3);
    \u0275\u0275text(14, "Cancelar");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(15, "button", 14);
    \u0275\u0275text(16);
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    let tmp_3_0;
    const ctx_r1 = \u0275\u0275nextContext();
    \u0275\u0275conditional(0, ctx_r1.erro() ? 0 : -1);
    \u0275\u0275advance();
    \u0275\u0275property("formGroup", ctx_r1.form);
    \u0275\u0275advance(5);
    \u0275\u0275conditional(6, ((tmp_3_0 = ctx_r1.form.get("nome")) == null ? null : tmp_3_0.invalid) && ((tmp_3_0 = ctx_r1.form.get("nome")) == null ? null : tmp_3_0.touched) ? 6 : -1);
    \u0275\u0275advance(5);
    \u0275\u0275conditional(11, ctx_r1.editandoId() ? 11 : -1);
    \u0275\u0275advance(4);
    \u0275\u0275property("disabled", ctx_r1.salvando() || ctx_r1.form.invalid);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1(" ", ctx_r1.salvando() ? "Salvando..." : "Salvar", " ");
  }
}
var ModalidadeFormComponent = class _ModalidadeFormComponent {
  constructor() {
    this.modalidadeService = inject(ModalidadeService);
    this.router = inject(Router);
    this.route = inject(ActivatedRoute);
    this.fb = inject(FormBuilder);
    this.editandoId = signal(null);
    this.salvando = signal(false);
    this.carregando = signal(false);
    this.erro = signal("");
    this.form = this.fb.group({
      nome: ["", [Validators.required, Validators.minLength(2)]],
      descricao: [""],
      ativo: [true]
    });
  }
  ngOnInit() {
    const id = this.route.snapshot.paramMap.get("id");
    if (id) {
      this.editandoId.set(id);
      this.carregando.set(true);
      this.modalidadeService.getById(id).subscribe({
        next: (res) => {
          if (res.dados) {
            this.form.patchValue({
              nome: res.dados.nome,
              descricao: res.dados.descricao ?? "",
              ativo: res.dados.ativo
            });
          }
          this.carregando.set(false);
        },
        error: () => {
          this.erro.set("Erro ao carregar modalidade.");
          this.carregando.set(false);
        }
      });
    }
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
    const req$ = id ? this.modalidadeService.update(id, { nome: v.nome, descricao: v.descricao ?? void 0, ativo: v.ativo }) : this.modalidadeService.create({ nome: v.nome, descricao: v.descricao ?? void 0 });
    req$.subscribe({
      next: (res) => {
        if (res.sucesso)
          this.router.navigate(["/app/modalidades"]);
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
    this.\u0275fac = function ModalidadeFormComponent_Factory(t) {
      return new (t || _ModalidadeFormComponent)();
    };
  }
  static {
    this.\u0275cmp = /* @__PURE__ */ \u0275\u0275defineComponent({ type: _ModalidadeFormComponent, selectors: [["app-modalidade-form"]], standalone: true, features: [\u0275\u0275StandaloneFeature], decls: 8, vars: 2, consts: [[1, "page-container"], [1, "page-header"], [1, "page-title"], ["routerLink", "/app/modalidades", 1, "btn-secondary"], [1, "skeleton-list"], [1, "skeleton-row"], [1, "alert-error"], [1, "form-card", 3, "ngSubmit", "formGroup"], [1, "form-group"], [1, "form-label"], ["formControlName", "nome", "placeholder", "Ex: Jiu-Jitsu, Muay Thai, Boxe...", 1, "form-input"], [1, "form-error"], ["formControlName", "descricao", "rows", "3", "placeholder", "Descreva a modalidade...", 1, "form-input"], [1, "form-actions"], ["type", "submit", 1, "btn-primary", 3, "disabled"], [1, "toggle-label"], [1, "toggle-switch"], ["formControlName", "ativo", "type", "checkbox"], [1, "toggle-slider"]], template: function ModalidadeFormComponent_Template(rf, ctx) {
      if (rf & 1) {
        \u0275\u0275elementStart(0, "div", 0)(1, "div", 1)(2, "h1", 2);
        \u0275\u0275text(3);
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(4, "a", 3);
        \u0275\u0275text(5, "\u2190 Voltar");
        \u0275\u0275elementEnd()();
        \u0275\u0275template(6, ModalidadeFormComponent_Conditional_6_Template, 3, 1, "div", 4)(7, ModalidadeFormComponent_Conditional_7_Template, 17, 6);
        \u0275\u0275elementEnd();
      }
      if (rf & 2) {
        \u0275\u0275advance(3);
        \u0275\u0275textInterpolate(ctx.editandoId() ? "Editar Modalidade" : "Nova Modalidade");
        \u0275\u0275advance(3);
        \u0275\u0275conditional(6, ctx.carregando() ? 6 : 7);
      }
    }, dependencies: [CommonModule, ReactiveFormsModule, \u0275NgNoValidate, DefaultValueAccessor, CheckboxControlValueAccessor, NgControlStatus, NgControlStatusGroup, FormGroupDirective, FormControlName, RouterLink], styles: [".toggle-label[_ngcontent-%COMP%] { display: flex; align-items: center; gap: 12px; cursor: pointer; font-size: 14px; }\n  .toggle-switch[_ngcontent-%COMP%] { position: relative; width: 40px; height: 22px; }\n  .toggle-switch[_ngcontent-%COMP%]   input[_ngcontent-%COMP%] { opacity: 0; width: 0; height: 0; }\n  .toggle-slider[_ngcontent-%COMP%] {\n    position: absolute; inset: 0; background: var(--color-border);\n    border-radius: 99px; transition: background 0.2s; cursor: pointer;\n  }\n  .toggle-slider[_ngcontent-%COMP%]::before {\n    content: ''; position: absolute; height: 16px; width: 16px;\n    left: 3px; top: 3px; background: white; border-radius: 50%; transition: transform 0.2s;\n  }\n  .toggle-switch[_ngcontent-%COMP%]   input[_ngcontent-%COMP%]:checked    + .toggle-slider[_ngcontent-%COMP%] { background: var(--color-primary, #6366f1); }\n  .toggle-switch[_ngcontent-%COMP%]   input[_ngcontent-%COMP%]:checked    + .toggle-slider[_ngcontent-%COMP%]::before { transform: translateX(18px); }\n  .form-error[_ngcontent-%COMP%] { font-size: 12px; color: var(--color-danger, #ef4444); margin-top: 4px; display: block; }"] });
  }
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && \u0275setClassDebugInfo(ModalidadeFormComponent, { className: "ModalidadeFormComponent" });
})();
export {
  ModalidadeFormComponent
};
//# sourceMappingURL=chunk-IBD3FMXH.js.map
