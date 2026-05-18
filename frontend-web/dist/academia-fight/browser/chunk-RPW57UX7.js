import {
  PresencaService
} from "./chunk-DARYXU3C.js";
import {
  DefaultValueAccessor,
  FormsModule,
  NgControlStatus,
  NgModel
} from "./chunk-JQJL26HT.js";
import {
  AlunoService
} from "./chunk-ZSIQJU4D.js";
import "./chunk-Z5CKO2JM.js";
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

// src/app/features/presencas/pages/historico/historico-presencas.component.ts
var _forTrack0 = ($index, $item) => $item.id;
var _c0 = () => [1, 2, 3, 4];
function HistoricoPresencasComponent_Conditional_10_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 8);
    \u0275\u0275text(1, " Buscando... ");
    \u0275\u0275elementEnd();
  }
}
function HistoricoPresencasComponent_Conditional_11_For_2_Template(rf, ctx) {
  if (rf & 1) {
    const _r1 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "button", 16);
    \u0275\u0275listener("mousedown", function HistoricoPresencasComponent_Conditional_11_For_2_Template_button_mousedown_0_listener() {
      const s_r2 = \u0275\u0275restoreView(_r1).$implicit;
      const ctx_r2 = \u0275\u0275nextContext(2);
      return \u0275\u0275resetView(ctx_r2.selecionarAluno(s_r2));
    });
    \u0275\u0275elementStart(1, "span", 17);
    \u0275\u0275text(2);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "div")(4, "span", 18);
    \u0275\u0275text(5);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(6, "span", 19);
    \u0275\u0275text(7);
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    const s_r2 = ctx.$implicit;
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(s_r2.nome.charAt(0));
    \u0275\u0275advance(3);
    \u0275\u0275textInterpolate(s_r2.nome);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(s_r2.email);
  }
}
function HistoricoPresencasComponent_Conditional_11_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 9);
    \u0275\u0275repeaterCreate(1, HistoricoPresencasComponent_Conditional_11_For_2_Template, 8, 3, "button", 15, _forTrack0);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r2 = \u0275\u0275nextContext();
    \u0275\u0275advance();
    \u0275\u0275repeater(ctx_r2.sugestoes());
  }
}
function HistoricoPresencasComponent_Conditional_12_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 9)(1, "span", 20);
    \u0275\u0275text(2, "Nenhum aluno encontrado");
    \u0275\u0275elementEnd()();
  }
}
function HistoricoPresencasComponent_Conditional_23_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 13)(1, "span");
    \u0275\u0275text(2);
    \u0275\u0275elementStart(3, "strong");
    \u0275\u0275text(4);
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    const ctx_r2 = \u0275\u0275nextContext();
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate1("", ctx_r2.alunoSelecionado().nome, " \xB7 Total no per\xEDodo: ");
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate1("", ctx_r2.presencas().length, " presen\xE7as");
  }
}
function HistoricoPresencasComponent_Conditional_24_For_2_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275element(0, "div", 21);
  }
}
function HistoricoPresencasComponent_Conditional_24_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 14);
    \u0275\u0275repeaterCreate(1, HistoricoPresencasComponent_Conditional_24_For_2_Template, 1, 0, "div", 21, \u0275\u0275repeaterTrackByIdentity);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    \u0275\u0275advance();
    \u0275\u0275repeater(\u0275\u0275pureFunction0(0, _c0));
  }
}
function HistoricoPresencasComponent_Conditional_25_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 22)(1, "p");
    \u0275\u0275text(2);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const ctx_r2 = \u0275\u0275nextContext();
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(ctx_r2.erro());
  }
}
function HistoricoPresencasComponent_Conditional_26_For_14_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "tr")(1, "td");
    \u0275\u0275text(2);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "td");
    \u0275\u0275text(4);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(5, "td");
    \u0275\u0275text(6);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(7, "td");
    \u0275\u0275text(8);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const p_r4 = ctx.$implicit;
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(p_r4.data);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(p_r4.nomeTurma);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(p_r4.horaCheckin);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(p_r4.metodoCheckin);
  }
}
function HistoricoPresencasComponent_Conditional_26_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 23)(1, "table", 24)(2, "thead")(3, "tr")(4, "th");
    \u0275\u0275text(5, "Data");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(6, "th");
    \u0275\u0275text(7, "Turma");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(8, "th");
    \u0275\u0275text(9, "Check-in");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(10, "th");
    \u0275\u0275text(11, "M\xE9todo");
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(12, "tbody");
    \u0275\u0275repeaterCreate(13, HistoricoPresencasComponent_Conditional_26_For_14_Template, 9, 4, "tr", null, _forTrack0);
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    const ctx_r2 = \u0275\u0275nextContext();
    \u0275\u0275advance(13);
    \u0275\u0275repeater(ctx_r2.presencas());
  }
}
function HistoricoPresencasComponent_Conditional_27_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 25)(1, "p");
    \u0275\u0275text(2);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const ctx_r2 = \u0275\u0275nextContext();
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate1("Nenhuma presen\xE7a encontrada no per\xEDodo para ", ctx_r2.alunoSelecionado().nome, ".");
  }
}
var HistoricoPresencasComponent = class _HistoricoPresencasComponent {
  constructor() {
    this.presencaService = inject(PresencaService);
    this.alunoService = inject(AlunoService);
    this.nomeBusca = signal("");
    this.sugestoes = signal([]);
    this.alunoSelecionado = signal(null);
    this.mostrarSugestoes = signal(false);
    this.buscandoAluno = signal(false);
    this.de = signal(new Date(Date.now() - 30 * 864e5).toISOString().split("T")[0]);
    this.ate = signal((/* @__PURE__ */ new Date()).toISOString().split("T")[0]);
    this.presencas = signal([]);
    this.carregando = signal(false);
    this.erro = signal("");
    this.busca$ = new Subject();
    this.destroy$ = new Subject();
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
    this.presencas.set([]);
    this.busca$.next(nome);
  }
  selecionarAluno(aluno) {
    this.alunoSelecionado.set(aluno);
    this.nomeBusca.set(aluno.nome);
    this.mostrarSugestoes.set(false);
    this.sugestoes.set([]);
    this.buscar();
  }
  fecharSugestoes() {
    setTimeout(() => this.mostrarSugestoes.set(false), 200);
  }
  buscar() {
    const aluno = this.alunoSelecionado();
    if (!aluno)
      return;
    this.carregando.set(true);
    this.erro.set("");
    this.presencaService.getHistorico(aluno.id, this.de(), this.ate()).subscribe({
      next: (res) => {
        this.presencas.set(res.dados ?? []);
        this.carregando.set(false);
      },
      error: () => {
        this.erro.set("Erro ao buscar hist\xF3rico.");
        this.carregando.set(false);
      }
    });
  }
  static {
    this.\u0275fac = function HistoricoPresencasComponent_Factory(t) {
      return new (t || _HistoricoPresencasComponent)();
    };
  }
  static {
    this.\u0275cmp = /* @__PURE__ */ \u0275\u0275defineComponent({ type: _HistoricoPresencasComponent, selectors: [["app-historico-presencas"]], standalone: true, features: [\u0275\u0275StandaloneFeature], decls: 28, vars: 9, consts: [[1, "page-container"], [1, "page-header"], [1, "page-title"], [1, "filters-row", 2, "align-items", "flex-end"], [1, "form-group", 2, "position", "relative", "flex", "1", "max-width", "360px"], [1, "form-label"], [2, "position", "relative"], ["placeholder", "Digite o nome do aluno...", "autocomplete", "off", 1, "form-input", 3, "ngModelChange", "blur", "ngModel"], [2, "position", "absolute", "right", "10px", "top", "50%", "transform", "translateY(-50%)", "font-size", "12px", "color", "var(--color-text-secondary)"], [1, "autocomplete-dropdown"], [1, "form-group"], ["type", "date", 1, "form-input", 2, "max-width", "160px", 3, "ngModelChange", "ngModel"], [1, "btn-primary", 3, "click", "disabled"], [1, "summary-card"], [1, "skeleton-list"], ["type", "button", 1, "autocomplete-item"], ["type", "button", 1, "autocomplete-item", 3, "mousedown"], [1, "presenca-avatar", 2, "width", "28px", "height", "28px", "font-size", "12px", "flex-shrink", "0"], [2, "font-weight", "500"], [2, "font-size", "12px", "color", "var(--color-text-secondary)", "display", "block"], [2, "padding", "10px 12px", "display", "block", "color", "var(--color-text-secondary)", "font-size", "13px"], [1, "skeleton-row"], [1, "error-card"], [1, "table-wrapper"], [1, "data-table"], [1, "empty-state"]], template: function HistoricoPresencasComponent_Template(rf, ctx) {
      if (rf & 1) {
        \u0275\u0275elementStart(0, "div", 0)(1, "div", 1)(2, "h1", 2);
        \u0275\u0275text(3, "Hist\xF3rico de Presen\xE7as");
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(4, "div", 3)(5, "div", 4)(6, "label", 5);
        \u0275\u0275text(7, "Buscar aluno");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(8, "div", 6)(9, "input", 7);
        \u0275\u0275listener("ngModelChange", function HistoricoPresencasComponent_Template_input_ngModelChange_9_listener($event) {
          return ctx.onNomeInput($event);
        })("blur", function HistoricoPresencasComponent_Template_input_blur_9_listener() {
          return ctx.fecharSugestoes();
        });
        \u0275\u0275elementEnd();
        \u0275\u0275template(10, HistoricoPresencasComponent_Conditional_10_Template, 2, 0, "span", 8);
        \u0275\u0275elementEnd();
        \u0275\u0275template(11, HistoricoPresencasComponent_Conditional_11_Template, 3, 0, "div", 9)(12, HistoricoPresencasComponent_Conditional_12_Template, 3, 0, "div", 9);
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(13, "div", 10)(14, "label", 5);
        \u0275\u0275text(15, "De");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(16, "input", 11);
        \u0275\u0275listener("ngModelChange", function HistoricoPresencasComponent_Template_input_ngModelChange_16_listener($event) {
          return ctx.de.set($event);
        });
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(17, "div", 10)(18, "label", 5);
        \u0275\u0275text(19, "At\xE9");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(20, "input", 11);
        \u0275\u0275listener("ngModelChange", function HistoricoPresencasComponent_Template_input_ngModelChange_20_listener($event) {
          return ctx.ate.set($event);
        });
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(21, "button", 12);
        \u0275\u0275listener("click", function HistoricoPresencasComponent_Template_button_click_21_listener() {
          return ctx.buscar();
        });
        \u0275\u0275text(22, "Buscar");
        \u0275\u0275elementEnd()();
        \u0275\u0275template(23, HistoricoPresencasComponent_Conditional_23_Template, 5, 2, "div", 13)(24, HistoricoPresencasComponent_Conditional_24_Template, 3, 1, "div", 14)(25, HistoricoPresencasComponent_Conditional_25_Template, 3, 1)(26, HistoricoPresencasComponent_Conditional_26_Template, 15, 0)(27, HistoricoPresencasComponent_Conditional_27_Template, 3, 1);
        \u0275\u0275elementEnd();
      }
      if (rf & 2) {
        \u0275\u0275advance(9);
        \u0275\u0275property("ngModel", ctx.nomeBusca());
        \u0275\u0275advance();
        \u0275\u0275conditional(10, ctx.buscandoAluno() ? 10 : -1);
        \u0275\u0275advance();
        \u0275\u0275conditional(11, ctx.mostrarSugestoes() && ctx.sugestoes().length > 0 ? 11 : -1);
        \u0275\u0275advance();
        \u0275\u0275conditional(12, ctx.mostrarSugestoes() && ctx.sugestoes().length === 0 && ctx.nomeBusca().length >= 2 && !ctx.buscandoAluno() ? 12 : -1);
        \u0275\u0275advance(4);
        \u0275\u0275property("ngModel", ctx.de());
        \u0275\u0275advance(4);
        \u0275\u0275property("ngModel", ctx.ate());
        \u0275\u0275advance();
        \u0275\u0275property("disabled", ctx.carregando() || !ctx.alunoSelecionado());
        \u0275\u0275advance(2);
        \u0275\u0275conditional(23, ctx.alunoSelecionado() && ctx.presencas().length > 0 ? 23 : -1);
        \u0275\u0275advance();
        \u0275\u0275conditional(24, ctx.carregando() ? 24 : ctx.erro() ? 25 : ctx.presencas().length > 0 ? 26 : ctx.alunoSelecionado() ? 27 : -1);
      }
    }, dependencies: [CommonModule, FormsModule, DefaultValueAccessor, NgControlStatus, NgModel], styles: [".autocomplete-dropdown[_ngcontent-%COMP%] {\n    position: absolute;\n    top: 100%;\n    left: 0;\n    right: 0;\n    background: var(--color-surface, #1e1e1e);\n    border: 1px solid var(--color-border, #333);\n    border-radius: 8px;\n    box-shadow: 0 8px 24px rgba(0,0,0,0.3);\n    z-index: 50;\n    overflow: hidden;\n  }\n  .autocomplete-item[_ngcontent-%COMP%] {\n    display: flex;\n    align-items: center;\n    gap: 10px;\n    padding: 8px 12px;\n    width: 100%;\n    text-align: left;\n    background: none;\n    border: none;\n    cursor: pointer;\n    transition: background 0.15s;\n  }\n  .autocomplete-item[_ngcontent-%COMP%]:hover { background: rgba(255,255,255,0.05); }"] });
  }
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && \u0275setClassDebugInfo(HistoricoPresencasComponent, { className: "HistoricoPresencasComponent" });
})();
export {
  HistoricoPresencasComponent
};
//# sourceMappingURL=chunk-RPW57UX7.js.map
