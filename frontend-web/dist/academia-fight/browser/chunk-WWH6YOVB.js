import {
  BadgeFaixaComponent
} from "./chunk-ZVPVJ4B3.js";
import {
  GraduacaoService
} from "./chunk-GPQPM6NQ.js";
import {
  UsuarioService
} from "./chunk-P4PGH6V4.js";
import {
  ModalidadeService
} from "./chunk-ZN4AZHLY.js";
import {
  CheckboxControlValueAccessor,
  DefaultValueAccessor,
  FormBuilder,
  FormControlName,
  FormGroupDirective,
  FormsModule,
  NgControlStatus,
  NgControlStatusGroup,
  NgModel,
  NgSelectOption,
  ReactiveFormsModule,
  SelectControlValueAccessor,
  Validators,
  ɵNgNoValidate,
  ɵNgSelectMultipleOption
} from "./chunk-JQJL26HT.js";
import {
  AlunoService
} from "./chunk-ZSIQJU4D.js";
import "./chunk-Z5CKO2JM.js";
import {
  Router,
  RouterLink
} from "./chunk-AXNOULNC.js";
import {
  CommonModule,
  Subject,
  debounceTime,
  distinctUntilChanged,
  inject,
  of,
  signal,
  switchMap,
  takeUntil,
  ɵsetClassDebugInfo,
  ɵɵStandaloneFeature,
  ɵɵadvance,
  ɵɵattribute,
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

// src/app/features/graduacao/pages/registrar/registrar-graduacao.component.ts
var _forTrack0 = ($index, $item) => $item.id;
var _c0 = () => ({ standalone: true });
function RegistrarGraduacaoComponent_Conditional_6_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 4);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(ctx_r0.erro());
  }
}
function RegistrarGraduacaoComponent_Conditional_13_For_2_Conditional_7_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275text(0);
  }
  if (rf & 2) {
    const s_r3 = \u0275\u0275nextContext().$implicit;
    \u0275\u0275textInterpolate1(" ", s_r3.turmas.join(", "), " ");
  }
}
function RegistrarGraduacaoComponent_Conditional_13_For_2_Conditional_8_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275text(0);
  }
  if (rf & 2) {
    const s_r3 = \u0275\u0275nextContext().$implicit;
    \u0275\u0275textInterpolate1(" ", s_r3.email, " ");
  }
}
function RegistrarGraduacaoComponent_Conditional_13_For_2_Conditional_9_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275text(0, " Sem turma ");
  }
}
function RegistrarGraduacaoComponent_Conditional_13_For_2_Template(rf, ctx) {
  if (rf & 1) {
    const _r2 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "button", 26);
    \u0275\u0275listener("mousedown", function RegistrarGraduacaoComponent_Conditional_13_For_2_Template_button_mousedown_0_listener() {
      const s_r3 = \u0275\u0275restoreView(_r2).$implicit;
      const ctx_r0 = \u0275\u0275nextContext(2);
      return \u0275\u0275resetView(ctx_r0.selecionarAluno(s_r3));
    });
    \u0275\u0275elementStart(1, "span", 27);
    \u0275\u0275text(2);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "div")(4, "span", 28);
    \u0275\u0275text(5);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(6, "span", 29);
    \u0275\u0275template(7, RegistrarGraduacaoComponent_Conditional_13_For_2_Conditional_7_Template, 1, 1)(8, RegistrarGraduacaoComponent_Conditional_13_For_2_Conditional_8_Template, 1, 1)(9, RegistrarGraduacaoComponent_Conditional_13_For_2_Conditional_9_Template, 1, 0);
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    const s_r3 = ctx.$implicit;
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(s_r3.nome.charAt(0));
    \u0275\u0275advance(3);
    \u0275\u0275textInterpolate(s_r3.nome);
    \u0275\u0275advance(2);
    \u0275\u0275conditional(7, s_r3.turmas.length ? 7 : s_r3.email ? 8 : 9);
  }
}
function RegistrarGraduacaoComponent_Conditional_13_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 10);
    \u0275\u0275repeaterCreate(1, RegistrarGraduacaoComponent_Conditional_13_For_2_Template, 10, 3, "button", 25, _forTrack0);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance();
    \u0275\u0275repeater(ctx_r0.sugestoes());
  }
}
function RegistrarGraduacaoComponent_For_21_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "option", 14);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const p_r4 = ctx.$implicit;
    \u0275\u0275property("value", p_r4.id);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(p_r4.nome);
  }
}
function RegistrarGraduacaoComponent_For_30_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "option", 14);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const m_r5 = ctx.$implicit;
    \u0275\u0275property("value", m_r5.id);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(m_r5.nome);
  }
}
function RegistrarGraduacaoComponent_For_38_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "option", 14);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const f_r6 = ctx.$implicit;
    \u0275\u0275property("value", f_r6.id);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(f_r6.nome);
  }
}
function RegistrarGraduacaoComponent_Conditional_39_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 17)(1, "h4");
    \u0275\u0275text(2, "Requisitos da Faixa");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "div", 30);
    \u0275\u0275element(4, "app-badge-faixa", 31);
    \u0275\u0275elementStart(5, "span");
    \u0275\u0275text(6);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(7, "p");
    \u0275\u0275text(8, "Meses m\xEDnimos: ");
    \u0275\u0275elementStart(9, "strong");
    \u0275\u0275text(10);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(11, "p");
    \u0275\u0275text(12, "Presen\xE7as m\xEDnimas: ");
    \u0275\u0275elementStart(13, "strong");
    \u0275\u0275text(14);
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance(4);
    \u0275\u0275property("cor", ctx_r0.faixaSelecionada().cor)("nome", ctx_r0.faixaSelecionada().nome);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(ctx_r0.faixaSelecionada().nome);
    \u0275\u0275advance(4);
    \u0275\u0275textInterpolate(ctx_r0.faixaSelecionada().requisitosMesesMinimos);
    \u0275\u0275advance(4);
    \u0275\u0275textInterpolate(ctx_r0.faixaSelecionada().requisitosPresencasMinimas);
  }
}
var RegistrarGraduacaoComponent = class _RegistrarGraduacaoComponent {
  constructor() {
    this.graduacaoService = inject(GraduacaoService);
    this.modalidadeService = inject(ModalidadeService);
    this.usuarioService = inject(UsuarioService);
    this.alunoService = inject(AlunoService);
    this.fb = inject(FormBuilder);
    this.router = inject(Router);
    this.modalidades = signal([]);
    this.professores = signal([]);
    this.faixas = signal([]);
    this.faixaSelecionada = signal(null);
    this.salvando = signal(false);
    this.erro = signal("");
    this.nomeBusca = signal("");
    this.sugestoes = signal([]);
    this.alunoSelecionado = signal(null);
    this.mostrarSugestoes = signal(false);
    this.buscandoAluno = signal(false);
    this.busca$ = new Subject();
    this.destroy$ = new Subject();
    this.form = this.fb.group({
      alunoId: ["", Validators.required],
      modalidadeId: ["", Validators.required],
      faixaId: ["", Validators.required],
      dataExame: ["", Validators.required],
      professorId: ["", Validators.required],
      aprovado: [true],
      observacoes: [""]
    });
    this.modalidadeService.getAll().subscribe({ next: (r) => this.modalidades.set(r.dados ?? []) });
    this.usuarioService.getProfessores().subscribe({ next: (r) => this.professores.set(r.dados ?? []) });
    this.busca$.pipe(debounceTime(400), distinctUntilChanged(), switchMap((nome) => {
      if (nome.length < 2) {
        this.sugestoes.set([]);
        this.mostrarSugestoes.set(false);
        return of(null);
      }
      this.buscandoAluno.set(true);
      return this.alunoService.buscarPorNome(nome);
    }), takeUntil(this.destroy$)).subscribe({
      next: (res) => {
        if (res) {
          this.sugestoes.set(res.dados?.itens ?? []);
          this.mostrarSugestoes.set(true);
        }
        this.buscandoAluno.set(false);
      },
      error: () => this.buscandoAluno.set(false)
    });
  }
  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }
  onNomeInput(nome) {
    this.nomeBusca.set(nome);
    this.alunoSelecionado.set(null);
    this.form.patchValue({ alunoId: "" });
    this.busca$.next(nome);
  }
  selecionarAluno(aluno) {
    this.alunoSelecionado.set(aluno);
    this.nomeBusca.set(aluno.nome);
    this.mostrarSugestoes.set(false);
    this.form.patchValue({ alunoId: aluno.id });
  }
  fecharSugestoes() {
    setTimeout(() => this.mostrarSugestoes.set(false), 200);
  }
  carregarFaixas() {
    const modalidadeId = this.form.get("modalidadeId")?.value;
    if (!modalidadeId)
      return;
    this.faixas.set([]);
    this.faixaSelecionada.set(null);
    this.form.patchValue({ faixaId: "" });
    this.graduacaoService.getFaixasByModalidade(modalidadeId).subscribe({
      next: (res) => this.faixas.set(res.dados ?? [])
    });
  }
  onFaixaChange() {
    const faixaId = this.form.get("faixaId")?.value;
    this.faixaSelecionada.set(this.faixas().find((f) => f.id === faixaId) ?? null);
  }
  submit() {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    this.salvando.set(true);
    this.erro.set("");
    const v = this.form.value;
    this.graduacaoService.registrar({
      alunoId: v.alunoId,
      faixaId: v.faixaId,
      dataExame: v.dataExame,
      professorId: v.professorId,
      aprovado: v.aprovado,
      observacoes: v.observacoes ?? void 0
    }).subscribe({
      next: (res) => {
        if (res.sucesso)
          this.router.navigate(["/app/graduacao"]);
        else {
          this.erro.set(res.mensagem ?? "Erro");
          this.salvando.set(false);
        }
      },
      error: (err) => {
        this.erro.set(err.error?.mensagem ?? "Erro");
        this.salvando.set(false);
      }
    });
  }
  static {
    this.\u0275fac = function RegistrarGraduacaoComponent_Factory(t) {
      return new (t || _RegistrarGraduacaoComponent)();
    };
  }
  static {
    this.\u0275cmp = /* @__PURE__ */ \u0275\u0275defineComponent({ type: _RegistrarGraduacaoComponent, selectors: [["app-registrar-graduacao"]], standalone: true, features: [\u0275\u0275StandaloneFeature], decls: 58, vars: 13, consts: [[1, "page-container"], [1, "page-header"], [1, "page-title"], ["routerLink", "/app/graduacao", 1, "btn-secondary"], [1, "alert-error"], [1, "form-card", 3, "ngSubmit", "formGroup"], [1, "form-row"], [1, "form-group", 2, "position", "relative", "flex", "1"], [1, "form-label"], ["placeholder", "Digite o nome do aluno...", "autocomplete", "off", 1, "form-input", 3, "ngModelChange", "blur", "ngModel", "ngModelOptions"], [1, "autocomplete-dropdown"], [1, "form-group"], ["formControlName", "professorId", 1, "form-input"], ["value", ""], [3, "value"], ["formControlName", "modalidadeId", 1, "form-input", 3, "change"], ["formControlName", "faixaId", 1, "form-input", 3, "change"], [1, "requisitos-card"], ["formControlName", "dataExame", "type", "date", 1, "form-input"], [1, "form-label", "checkbox-label", 2, "margin-top", "28px"], ["formControlName", "aprovado", "type", "checkbox", 1, "form-checkbox"], ["formControlName", "observacoes", "rows", "3", 1, "form-input"], [1, "form-actions"], ["type", "button", "routerLink", "/app/graduacao", 1, "btn-secondary"], ["type", "submit", 1, "btn-primary", 3, "disabled"], ["type", "button", 1, "autocomplete-item"], ["type", "button", 1, "autocomplete-item", 3, "mousedown"], [1, "presenca-avatar", 2, "width", "28px", "height", "28px", "font-size", "12px", "flex-shrink", "0"], [2, "font-weight", "500"], [2, "font-size", "12px", "color", "var(--app-text-3)", "display", "block"], [1, "req-row"], ["tamanho", "lg", 3, "cor", "nome"]], template: function RegistrarGraduacaoComponent_Template(rf, ctx) {
      if (rf & 1) {
        \u0275\u0275elementStart(0, "div", 0)(1, "div", 1)(2, "h1", 2);
        \u0275\u0275text(3, "Registrar Gradua\xE7\xE3o");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(4, "a", 3);
        \u0275\u0275text(5, "\u2190 Voltar");
        \u0275\u0275elementEnd()();
        \u0275\u0275template(6, RegistrarGraduacaoComponent_Conditional_6_Template, 2, 1, "div", 4);
        \u0275\u0275elementStart(7, "form", 5);
        \u0275\u0275listener("ngSubmit", function RegistrarGraduacaoComponent_Template_form_ngSubmit_7_listener() {
          return ctx.submit();
        });
        \u0275\u0275elementStart(8, "div", 6)(9, "div", 7)(10, "label", 8);
        \u0275\u0275text(11, "Aluno *");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(12, "input", 9);
        \u0275\u0275listener("ngModelChange", function RegistrarGraduacaoComponent_Template_input_ngModelChange_12_listener($event) {
          return ctx.onNomeInput($event);
        })("blur", function RegistrarGraduacaoComponent_Template_input_blur_12_listener() {
          return ctx.fecharSugestoes();
        });
        \u0275\u0275elementEnd();
        \u0275\u0275template(13, RegistrarGraduacaoComponent_Conditional_13_Template, 3, 0, "div", 10);
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(14, "div", 11)(15, "label", 8);
        \u0275\u0275text(16, "Professor *");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(17, "select", 12)(18, "option", 13);
        \u0275\u0275text(19, "Selecione o professor...");
        \u0275\u0275elementEnd();
        \u0275\u0275repeaterCreate(20, RegistrarGraduacaoComponent_For_21_Template, 2, 2, "option", 14, _forTrack0);
        \u0275\u0275elementEnd()()();
        \u0275\u0275elementStart(22, "div", 6)(23, "div", 11)(24, "label", 8);
        \u0275\u0275text(25, "Modalidade *");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(26, "select", 15);
        \u0275\u0275listener("change", function RegistrarGraduacaoComponent_Template_select_change_26_listener() {
          return ctx.carregarFaixas();
        });
        \u0275\u0275elementStart(27, "option", 13);
        \u0275\u0275text(28, "Selecione a modalidade...");
        \u0275\u0275elementEnd();
        \u0275\u0275repeaterCreate(29, RegistrarGraduacaoComponent_For_30_Template, 2, 2, "option", 14, _forTrack0);
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(31, "div", 11)(32, "label", 8);
        \u0275\u0275text(33, "Faixa *");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(34, "select", 16);
        \u0275\u0275listener("change", function RegistrarGraduacaoComponent_Template_select_change_34_listener() {
          return ctx.onFaixaChange();
        });
        \u0275\u0275elementStart(35, "option", 13);
        \u0275\u0275text(36);
        \u0275\u0275elementEnd();
        \u0275\u0275repeaterCreate(37, RegistrarGraduacaoComponent_For_38_Template, 2, 2, "option", 14, _forTrack0);
        \u0275\u0275elementEnd()()();
        \u0275\u0275template(39, RegistrarGraduacaoComponent_Conditional_39_Template, 15, 5, "div", 17);
        \u0275\u0275elementStart(40, "div", 6)(41, "div", 11)(42, "label", 8);
        \u0275\u0275text(43, "Data do Exame *");
        \u0275\u0275elementEnd();
        \u0275\u0275element(44, "input", 18);
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(45, "div", 11)(46, "label", 19);
        \u0275\u0275element(47, "input", 20);
        \u0275\u0275text(48, " Aprovado ");
        \u0275\u0275elementEnd()()();
        \u0275\u0275elementStart(49, "div", 11)(50, "label", 8);
        \u0275\u0275text(51, "Observa\xE7\xF5es");
        \u0275\u0275elementEnd();
        \u0275\u0275element(52, "textarea", 21);
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(53, "div", 22)(54, "button", 23);
        \u0275\u0275text(55, "Cancelar");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(56, "button", 24);
        \u0275\u0275text(57);
        \u0275\u0275elementEnd()()()();
      }
      if (rf & 2) {
        let tmp_2_0;
        \u0275\u0275advance(6);
        \u0275\u0275conditional(6, ctx.erro() ? 6 : -1);
        \u0275\u0275advance();
        \u0275\u0275property("formGroup", ctx.form);
        \u0275\u0275advance(5);
        \u0275\u0275classProp("input-error", ((tmp_2_0 = ctx.form.get("alunoId")) == null ? null : tmp_2_0.invalid) && ((tmp_2_0 = ctx.form.get("alunoId")) == null ? null : tmp_2_0.touched));
        \u0275\u0275property("ngModel", ctx.nomeBusca())("ngModelOptions", \u0275\u0275pureFunction0(12, _c0));
        \u0275\u0275advance();
        \u0275\u0275conditional(13, ctx.mostrarSugestoes() && ctx.sugestoes().length > 0 ? 13 : -1);
        \u0275\u0275advance(7);
        \u0275\u0275repeater(ctx.professores());
        \u0275\u0275advance(9);
        \u0275\u0275repeater(ctx.modalidades());
        \u0275\u0275advance(5);
        \u0275\u0275attribute("disabled", ctx.faixas().length === 0 ? true : null);
        \u0275\u0275advance(2);
        \u0275\u0275textInterpolate(ctx.faixas().length === 0 ? "Selecione a modalidade primeiro" : "Selecione a faixa...");
        \u0275\u0275advance();
        \u0275\u0275repeater(ctx.faixas());
        \u0275\u0275advance(2);
        \u0275\u0275conditional(39, ctx.faixaSelecionada() ? 39 : -1);
        \u0275\u0275advance(17);
        \u0275\u0275property("disabled", ctx.salvando());
        \u0275\u0275advance();
        \u0275\u0275textInterpolate1(" ", ctx.salvando() ? "Registrando..." : "Registrar Gradua\xE7\xE3o", " ");
      }
    }, dependencies: [CommonModule, FormsModule, \u0275NgNoValidate, NgSelectOption, \u0275NgSelectMultipleOption, DefaultValueAccessor, CheckboxControlValueAccessor, SelectControlValueAccessor, NgControlStatus, NgControlStatusGroup, NgModel, ReactiveFormsModule, FormGroupDirective, FormControlName, RouterLink, BadgeFaixaComponent], styles: [".autocomplete-dropdown[_ngcontent-%COMP%] {\n    position: absolute;\n    top: 100%;\n    left: 0;\n    right: 0;\n    background: var(--color-surface, #1e1e1e);\n    border: 1px solid var(--color-border, #333);\n    border-radius: 8px;\n    box-shadow: 0 8px 24px rgba(0,0,0,0.3);\n    z-index: 50;\n    overflow: hidden;\n  }\n  .autocomplete-item[_ngcontent-%COMP%] {\n    display: flex;\n    align-items: center;\n    gap: 10px;\n    padding: 8px 12px;\n    width: 100%;\n    text-align: left;\n    background: none;\n    border: none;\n    cursor: pointer;\n    transition: background 0.15s;\n  }\n  .autocomplete-item[_ngcontent-%COMP%]:hover { background: rgba(255,255,255,0.05); }\n  .input-error[_ngcontent-%COMP%] { border-color: var(--color-danger, #ef4444) !important; }"] });
  }
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && \u0275setClassDebugInfo(RegistrarGraduacaoComponent, { className: "RegistrarGraduacaoComponent" });
})();
export {
  RegistrarGraduacaoComponent
};
//# sourceMappingURL=chunk-WWH6YOVB.js.map
