import {
  TurmaService
} from "./chunk-S4MMSQ6J.js";
import {
  FormsModule,
  NgSelectOption,
  ɵNgSelectMultipleOption
} from "./chunk-JQJL26HT.js";
import "./chunk-Z5CKO2JM.js";
import {
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
  ɵɵclassMap,
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
  ɵɵpureFunction1,
  ɵɵrepeater,
  ɵɵrepeaterCreate,
  ɵɵrepeaterTrackByIdentity,
  ɵɵresetView,
  ɵɵrestoreView,
  ɵɵstyleProp,
  ɵɵtemplate,
  ɵɵtext,
  ɵɵtextInterpolate,
  ɵɵtextInterpolate1
} from "./chunk-WZ2AWGAJ.js";
import "./chunk-7G5TR5RR.js";

// src/app/features/turmas/pages/lista/turmas-lista.component.ts
var _forTrack0 = ($index, $item) => $item.id;
var _c0 = () => [1, 2, 3, 4, 5];
var _c1 = (a0) => [a0];
var _c2 = (a0) => [a0, "editar"];
function TurmasListaComponent_Conditional_17_For_2_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275element(0, "div", 11);
  }
}
function TurmasListaComponent_Conditional_17_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 10);
    \u0275\u0275repeaterCreate(1, TurmasListaComponent_Conditional_17_For_2_Template, 1, 0, "div", 11, \u0275\u0275repeaterTrackByIdentity);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    \u0275\u0275advance();
    \u0275\u0275repeater(\u0275\u0275pureFunction0(0, _c0));
  }
}
function TurmasListaComponent_Conditional_18_Template(rf, ctx) {
  if (rf & 1) {
    const _r1 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 12)(1, "p");
    \u0275\u0275text(2);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "button", 13);
    \u0275\u0275listener("click", function TurmasListaComponent_Conditional_18_Template_button_click_3_listener() {
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
function TurmasListaComponent_Conditional_19_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 14);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(1, "svg", 15);
    \u0275\u0275element(2, "path", 16)(3, "circle", 17)(4, "path", 18);
    \u0275\u0275elementEnd();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(5, "p");
    \u0275\u0275text(6, "Nenhuma turma encontrada");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(7, "a", 4);
    \u0275\u0275text(8, "Criar primeira turma");
    \u0275\u0275elementEnd()();
  }
}
function TurmasListaComponent_Conditional_20_For_20_Conditional_19_Conditional_12_Template(rf, ctx) {
  if (rf & 1) {
    const _r6 = \u0275\u0275getCurrentView();
    \u0275\u0275element(0, "div", 32);
    \u0275\u0275elementStart(1, "button", 33);
    \u0275\u0275listener("click", function TurmasListaComponent_Conditional_20_For_20_Conditional_19_Conditional_12_Template_button_click_1_listener() {
      \u0275\u0275restoreView(_r6);
      const turma_r4 = \u0275\u0275nextContext(2).$implicit;
      const ctx_r1 = \u0275\u0275nextContext(2);
      ctx_r1.arquivar(turma_r4.id);
      return \u0275\u0275resetView(ctx_r1.fecharDropdown());
    });
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(2, "svg", 27);
    \u0275\u0275element(3, "polyline", 34)(4, "rect", 35)(5, "line", 36);
    \u0275\u0275elementEnd();
    \u0275\u0275text(6, " Arquivar ");
    \u0275\u0275elementEnd();
  }
}
function TurmasListaComponent_Conditional_20_For_20_Conditional_19_Template(rf, ctx) {
  if (rf & 1) {
    const _r5 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 24);
    \u0275\u0275listener("click", function TurmasListaComponent_Conditional_20_For_20_Conditional_19_Template_div_click_0_listener() {
      \u0275\u0275restoreView(_r5);
      const ctx_r1 = \u0275\u0275nextContext(3);
      return \u0275\u0275resetView(ctx_r1.fecharDropdown());
    });
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(1, "div", 25)(2, "a", 26);
    \u0275\u0275listener("click", function TurmasListaComponent_Conditional_20_For_20_Conditional_19_Template_a_click_2_listener() {
      \u0275\u0275restoreView(_r5);
      const ctx_r1 = \u0275\u0275nextContext(3);
      return \u0275\u0275resetView(ctx_r1.fecharDropdown());
    });
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(3, "svg", 27);
    \u0275\u0275element(4, "path", 28)(5, "circle", 29);
    \u0275\u0275elementEnd();
    \u0275\u0275text(6, " Ver detalhes ");
    \u0275\u0275elementEnd();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(7, "a", 26);
    \u0275\u0275listener("click", function TurmasListaComponent_Conditional_20_For_20_Conditional_19_Template_a_click_7_listener() {
      \u0275\u0275restoreView(_r5);
      const ctx_r1 = \u0275\u0275nextContext(3);
      return \u0275\u0275resetView(ctx_r1.fecharDropdown());
    });
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(8, "svg", 27);
    \u0275\u0275element(9, "path", 30)(10, "path", 31);
    \u0275\u0275elementEnd();
    \u0275\u0275text(11, " Editar ");
    \u0275\u0275elementEnd();
    \u0275\u0275template(12, TurmasListaComponent_Conditional_20_For_20_Conditional_19_Conditional_12_Template, 7, 0);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const turma_r4 = \u0275\u0275nextContext().$implicit;
    const ctx_r1 = \u0275\u0275nextContext(2);
    \u0275\u0275advance();
    \u0275\u0275styleProp("top", ctx_r1.dropdownPos().top, "px")("right", ctx_r1.dropdownPos().right, "px");
    \u0275\u0275advance();
    \u0275\u0275property("routerLink", \u0275\u0275pureFunction1(7, _c1, turma_r4.id));
    \u0275\u0275advance(5);
    \u0275\u0275property("routerLink", \u0275\u0275pureFunction1(9, _c2, turma_r4.id));
    \u0275\u0275advance(5);
    \u0275\u0275conditional(12, turma_r4.ativo ? 12 : -1);
  }
}
function TurmasListaComponent_Conditional_20_For_20_Template(rf, ctx) {
  if (rf & 1) {
    const _r3 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "tr")(1, "td", 22);
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
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(9, "td");
    \u0275\u0275text(10);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(11, "td")(12, "span");
    \u0275\u0275text(13);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(14, "td")(15, "div")(16, "button", 23);
    \u0275\u0275listener("click", function TurmasListaComponent_Conditional_20_For_20_Template_button_click_16_listener($event) {
      const turma_r4 = \u0275\u0275restoreView(_r3).$implicit;
      const ctx_r1 = \u0275\u0275nextContext(2);
      ctx_r1.toggleDropdown(turma_r4.id, $event);
      return \u0275\u0275resetView($event.stopPropagation());
    });
    \u0275\u0275elementStart(17, "span");
    \u0275\u0275text(18, "\u22EF");
    \u0275\u0275elementEnd()();
    \u0275\u0275template(19, TurmasListaComponent_Conditional_20_For_20_Conditional_19_Template, 13, 11);
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    let tmp_14_0;
    const turma_r4 = ctx.$implicit;
    const ctx_r1 = \u0275\u0275nextContext(2);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(turma_r4.nome);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(turma_r4.modalidadeNome);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(turma_r4.professorNome);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate((tmp_14_0 = turma_r4.nivel) !== null && tmp_14_0 !== void 0 ? tmp_14_0 : "\u2014");
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(turma_r4.capacidadeMaxima);
    \u0275\u0275advance(2);
    \u0275\u0275classMap(turma_r4.ativo ? "badge-ativo" : "badge-inativo");
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1(" ", turma_r4.ativo ? "Ativa" : "Inativa", " ");
    \u0275\u0275advance(6);
    \u0275\u0275conditional(19, ctx_r1.dropdownAbertoId() === turma_r4.id ? 19 : -1);
  }
}
function TurmasListaComponent_Conditional_20_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 19)(1, "table", 20)(2, "thead")(3, "tr")(4, "th");
    \u0275\u0275text(5, "Nome");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(6, "th");
    \u0275\u0275text(7, "Modalidade");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(8, "th");
    \u0275\u0275text(9, "Professor");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(10, "th");
    \u0275\u0275text(11, "N\xEDvel");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(12, "th");
    \u0275\u0275text(13, "Alunos");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(14, "th");
    \u0275\u0275text(15, "Status");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(16, "th", 21);
    \u0275\u0275text(17, "A\xE7\xF5es");
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(18, "tbody");
    \u0275\u0275repeaterCreate(19, TurmasListaComponent_Conditional_20_For_20_Template, 20, 9, "tr", null, _forTrack0);
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext();
    \u0275\u0275advance(19);
    \u0275\u0275repeater(ctx_r1.turmasFiltradas());
  }
}
var TurmasListaComponent = class _TurmasListaComponent {
  constructor() {
    this.turmaService = inject(TurmaService);
    this.turmas = signal([]);
    this.carregando = signal(true);
    this.erro = signal("");
    this.dropdownAbertoId = signal(null);
    this.dropdownPos = signal({ top: 0, right: 0 });
    this.filtroModalidade = signal("");
    this.filtroAtivo = signal(null);
    this.turmasFiltradas = computed(() => {
      let lista = this.turmas();
      if (this.filtroModalidade())
        lista = lista.filter((t) => t.modalidadeId === this.filtroModalidade());
      if (this.filtroAtivo() !== null)
        lista = lista.filter((t) => t.ativo === this.filtroAtivo());
      return lista;
    });
  }
  ngOnInit() {
    this.carregar();
  }
  carregar() {
    this.carregando.set(true);
    this.turmaService.getAll().subscribe({
      next: (res) => {
        this.turmas.set(res.dados ?? []);
        this.carregando.set(false);
      },
      error: () => {
        this.erro.set("Erro ao carregar turmas.");
        this.carregando.set(false);
      }
    });
  }
  setFiltroAtivo(valor) {
    if (valor === "")
      this.filtroAtivo.set(null);
    else
      this.filtroAtivo.set(valor === "true");
  }
  toggleDropdown(id, event) {
    const rect = event.currentTarget.getBoundingClientRect();
    this.dropdownPos.set({ top: rect.bottom + 4, right: window.innerWidth - rect.right });
    this.dropdownAbertoId.update((atual) => atual === id ? null : id);
  }
  fecharDropdown() {
    this.dropdownAbertoId.set(null);
  }
  arquivar(id) {
    if (!confirm("Tem certeza que deseja arquivar esta turma?"))
      return;
    this.turmaService.delete(id).subscribe({
      next: () => this.carregar(),
      error: () => alert("Erro ao arquivar turma.")
    });
  }
  static {
    this.\u0275fac = function TurmasListaComponent_Factory(t) {
      return new (t || _TurmasListaComponent)();
    };
  }
  static {
    this.\u0275cmp = /* @__PURE__ */ \u0275\u0275defineComponent({ type: _TurmasListaComponent, selectors: [["app-turmas-lista"]], standalone: true, features: [\u0275\u0275StandaloneFeature], decls: 21, vars: 1, consts: [[1, "page-container"], [1, "page-header"], [1, "page-title"], [1, "page-subtitle"], ["routerLink", "novo", 1, "btn-primary"], [1, "filters-row"], [1, "filter-select", 3, "change"], ["value", ""], ["value", "true"], ["value", "false"], [1, "skeleton-list"], [1, "skeleton-row"], [1, "error-card"], [1, "btn-secondary", 3, "click"], [1, "empty-state"], ["width", "48", "height", "48", "viewBox", "0 0 24 24", "fill", "none", "stroke", "currentColor", "stroke-width", "1.5"], ["d", "M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"], ["cx", "9", "cy", "7", "r", "4"], ["d", "M23 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"], [1, "table-wrapper"], [1, "data-table"], [2, "width", "60px"], [1, "font-medium"], ["title", "A\xE7\xF5es", 1, "btn-dots", 3, "click"], [1, "acao-overlay", 3, "click"], [1, "acao-dropdown"], [1, "acao-item", 3, "click", "routerLink"], ["width", "14", "height", "14", "fill", "none", "stroke", "currentColor", "stroke-width", "2", "viewBox", "0 0 24 24"], ["d", "M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"], ["cx", "12", "cy", "12", "r", "3"], ["d", "M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"], ["d", "M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"], [1, "acao-separator"], [1, "acao-item", "danger-item", 3, "click"], ["points", "21 8 21 21 3 21 3 8"], ["x", "1", "y", "3", "width", "22", "height", "5"], ["x1", "10", "y1", "12", "x2", "14", "y2", "12"]], template: function TurmasListaComponent_Template(rf, ctx) {
      if (rf & 1) {
        \u0275\u0275elementStart(0, "div", 0)(1, "div", 1)(2, "div")(3, "h1", 2);
        \u0275\u0275text(4, "Turmas");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(5, "p", 3);
        \u0275\u0275text(6, "Gerencie as turmas da academia");
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(7, "a", 4);
        \u0275\u0275text(8, "+ Nova Turma");
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(9, "div", 5)(10, "select", 6);
        \u0275\u0275listener("change", function TurmasListaComponent_Template_select_change_10_listener($event) {
          return ctx.setFiltroAtivo($event.target.value);
        });
        \u0275\u0275elementStart(11, "option", 7);
        \u0275\u0275text(12, "Todos os status");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(13, "option", 8);
        \u0275\u0275text(14, "Ativas");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(15, "option", 9);
        \u0275\u0275text(16, "Inativas");
        \u0275\u0275elementEnd()()();
        \u0275\u0275template(17, TurmasListaComponent_Conditional_17_Template, 3, 1, "div", 10)(18, TurmasListaComponent_Conditional_18_Template, 5, 1)(19, TurmasListaComponent_Conditional_19_Template, 9, 0)(20, TurmasListaComponent_Conditional_20_Template, 21, 0);
        \u0275\u0275elementEnd();
      }
      if (rf & 2) {
        \u0275\u0275advance(17);
        \u0275\u0275conditional(17, ctx.carregando() ? 17 : ctx.erro() ? 18 : ctx.turmasFiltradas().length === 0 ? 19 : 20);
      }
    }, dependencies: [CommonModule, RouterLink, FormsModule, NgSelectOption, \u0275NgSelectMultipleOption], styles: [".btn-dots[_ngcontent-%COMP%] { background: none; border: 1px solid transparent; border-radius: 6px; cursor: pointer; padding: 4px 8px; font-size: 18px; color: var(--app-text-3); line-height: 1; transition: all 0.15s; }\n  .btn-dots[_ngcontent-%COMP%]:hover { background: var(--app-border-light); border-color: var(--app-border); color: var(--app-text-1); }\n  .acao-overlay[_ngcontent-%COMP%] { position: fixed; inset: 0; z-index: 10; }\n  .acao-dropdown[_ngcontent-%COMP%] { position: fixed; background: var(--app-surface); border: 1px solid var(--app-border); border-radius: 8px; box-shadow: 0 4px 20px rgba(0,0,0,0.12); z-index: 200; min-width: 160px; padding: 4px; }\n  .acao-item[_ngcontent-%COMP%] { display: flex; align-items: center; gap: 8px; width: 100%; padding: 7px 10px; border: none; background: none; cursor: pointer; font-size: 13px; color: var(--app-text-1); text-decoration: none; border-radius: 6px; transition: background 0.1s; text-align: left; }\n  .acao-item[_ngcontent-%COMP%]:hover { background: var(--app-border-light); }\n  .acao-separator[_ngcontent-%COMP%] { height: 1px; background: var(--app-border); margin: 4px 0; }\n  .danger-item[_ngcontent-%COMP%] { color: #ef4444; }"] });
  }
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && \u0275setClassDebugInfo(TurmasListaComponent, { className: "TurmasListaComponent" });
})();
export {
  TurmasListaComponent
};
//# sourceMappingURL=chunk-6IHFLHLS.js.map
