import {
  ModalidadeService
} from "./chunk-ZN4AZHLY.js";
import "./chunk-Z5CKO2JM.js";
import {
  RouterLink
} from "./chunk-AXNOULNC.js";
import {
  CommonModule,
  inject,
  signal,
  ɵsetClassDebugInfo,
  ɵɵStandaloneFeature,
  ɵɵadvance,
  ɵɵclassMap,
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
  ɵɵpureFunction1,
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

// src/app/features/modalidades/pages/lista/modalidades-lista.component.ts
var _forTrack0 = ($index, $item) => $item.id;
var _c0 = () => [1, 2, 3, 4];
var _c1 = (a0) => [a0, "editar"];
function ModalidadesListaComponent_Conditional_9_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 5);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(ctx_r0.erro());
  }
}
function ModalidadesListaComponent_Conditional_10_For_2_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275element(0, "div", 7);
  }
}
function ModalidadesListaComponent_Conditional_10_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 6);
    \u0275\u0275repeaterCreate(1, ModalidadesListaComponent_Conditional_10_For_2_Template, 1, 0, "div", 7, \u0275\u0275repeaterTrackByIdentity);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    \u0275\u0275advance();
    \u0275\u0275repeater(\u0275\u0275pureFunction0(0, _c0));
  }
}
function ModalidadesListaComponent_Conditional_11_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 8);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(1, "svg", 9);
    \u0275\u0275element(2, "path", 10);
    \u0275\u0275elementEnd();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(3, "h3");
    \u0275\u0275text(4, "Nenhuma modalidade cadastrada");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(5, "p");
    \u0275\u0275text(6, "Crie a primeira modalidade para come\xE7ar");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(7, "a", 4);
    \u0275\u0275text(8, "Criar primeira modalidade");
    \u0275\u0275elementEnd()();
  }
}
function ModalidadesListaComponent_Conditional_12_For_14_Conditional_18_Template(rf, ctx) {
  if (rf & 1) {
    const _r4 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "button", 25);
    \u0275\u0275listener("click", function ModalidadesListaComponent_Conditional_12_For_14_Conditional_18_Template_button_click_0_listener() {
      \u0275\u0275restoreView(_r4);
      const m_r3 = \u0275\u0275nextContext().$implicit;
      const ctx_r0 = \u0275\u0275nextContext(2);
      return \u0275\u0275resetView(ctx_r0.abrirConfirmacao("excluir", m_r3));
    });
    \u0275\u0275text(1, "Excluir");
    \u0275\u0275elementEnd();
  }
}
function ModalidadesListaComponent_Conditional_12_For_14_Template(rf, ctx) {
  if (rf & 1) {
    const _r2 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "tr")(1, "td", 15)(2, "div", 16)(3, "div", 17);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(4, "svg", 18);
    \u0275\u0275element(5, "path", 10);
    \u0275\u0275elementEnd()();
    \u0275\u0275text(6);
    \u0275\u0275elementEnd()();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(7, "td", 19);
    \u0275\u0275text(8);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(9, "td")(10, "button", 20);
    \u0275\u0275listener("click", function ModalidadesListaComponent_Conditional_12_For_14_Template_button_click_10_listener() {
      const m_r3 = \u0275\u0275restoreView(_r2).$implicit;
      const ctx_r0 = \u0275\u0275nextContext(2);
      return \u0275\u0275resetView(m_r3.ativo ? ctx_r0.abrirConfirmacao("arquivar", m_r3) : ctx_r0.reativar(m_r3));
    });
    \u0275\u0275element(11, "div", 21);
    \u0275\u0275elementStart(12, "span");
    \u0275\u0275text(13);
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(14, "td")(15, "div", 22)(16, "a", 23);
    \u0275\u0275text(17, "Editar");
    \u0275\u0275elementEnd();
    \u0275\u0275template(18, ModalidadesListaComponent_Conditional_12_For_14_Conditional_18_Template, 2, 0, "button", 24);
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    const m_r3 = ctx.$implicit;
    \u0275\u0275classProp("row-inativa", !m_r3.ativo);
    \u0275\u0275advance(6);
    \u0275\u0275textInterpolate1(" ", m_r3.nome, " ");
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(m_r3.descricao || "\u2014");
    \u0275\u0275advance(2);
    \u0275\u0275classProp("ativo", m_r3.ativo);
    \u0275\u0275property("title", m_r3.ativo ? "Clique para inativar" : "Clique para ativar");
    \u0275\u0275advance(3);
    \u0275\u0275textInterpolate(m_r3.ativo ? "Ativa" : "Inativa");
    \u0275\u0275advance(3);
    \u0275\u0275property("routerLink", \u0275\u0275pureFunction1(10, _c1, m_r3.id));
    \u0275\u0275advance(2);
    \u0275\u0275conditional(18, !m_r3.ativo ? 18 : -1);
  }
}
function ModalidadesListaComponent_Conditional_12_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 11)(1, "table", 12)(2, "thead")(3, "tr")(4, "th");
    \u0275\u0275text(5, "Nome");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(6, "th");
    \u0275\u0275text(7, "Descri\xE7\xE3o");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(8, "th");
    \u0275\u0275text(9, "Status");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(10, "th", 13);
    \u0275\u0275text(11, "A\xE7\xF5es");
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(12, "tbody");
    \u0275\u0275repeaterCreate(13, ModalidadesListaComponent_Conditional_12_For_14_Template, 19, 12, "tr", 14, _forTrack0);
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance(13);
    \u0275\u0275repeater(ctx_r0.modalidades());
  }
}
function ModalidadesListaComponent_Conditional_13_Conditional_3_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(0, "svg", 29);
    \u0275\u0275element(1, "path", 36);
    \u0275\u0275elementEnd();
  }
}
function ModalidadesListaComponent_Conditional_13_Conditional_4_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(0, "svg", 29);
    \u0275\u0275element(1, "path", 37);
    \u0275\u0275elementEnd();
  }
}
function ModalidadesListaComponent_Conditional_13_Conditional_8_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275text(0, " A modalidade ");
    \u0275\u0275elementStart(1, "strong");
    \u0275\u0275text(2);
    \u0275\u0275elementEnd();
    \u0275\u0275text(3, " ser\xE1 inativada e ficar\xE1 oculta para novos cadastros. ");
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext(2);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(ctx_r0.confirmando().modalidade.nome);
  }
}
function ModalidadesListaComponent_Conditional_13_Conditional_9_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275text(0, " A modalidade ");
    \u0275\u0275elementStart(1, "strong");
    \u0275\u0275text(2);
    \u0275\u0275elementEnd();
    \u0275\u0275text(3, " ser\xE1 removida permanentemente. Isso falhar\xE1 se houver faixas ou turmas vinculadas. ");
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext(2);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(ctx_r0.confirmando().modalidade.nome);
  }
}
function ModalidadesListaComponent_Conditional_13_Conditional_10_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "p", 32);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext(2);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(ctx_r0.erroModal());
  }
}
function ModalidadesListaComponent_Conditional_13_Template(rf, ctx) {
  if (rf & 1) {
    const _r5 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 26);
    \u0275\u0275listener("click", function ModalidadesListaComponent_Conditional_13_Template_div_click_0_listener() {
      \u0275\u0275restoreView(_r5);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.fecharConfirmacao());
    });
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(1, "div", 27)(2, "div", 28);
    \u0275\u0275template(3, ModalidadesListaComponent_Conditional_13_Conditional_3_Template, 2, 0, ":svg:svg", 29)(4, ModalidadesListaComponent_Conditional_13_Conditional_4_Template, 2, 0);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(5, "h3", 30);
    \u0275\u0275text(6);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(7, "p", 31);
    \u0275\u0275template(8, ModalidadesListaComponent_Conditional_13_Conditional_8_Template, 4, 1)(9, ModalidadesListaComponent_Conditional_13_Conditional_9_Template, 4, 1);
    \u0275\u0275elementEnd();
    \u0275\u0275template(10, ModalidadesListaComponent_Conditional_13_Conditional_10_Template, 2, 1, "p", 32);
    \u0275\u0275elementStart(11, "div", 33)(12, "button", 34);
    \u0275\u0275listener("click", function ModalidadesListaComponent_Conditional_13_Template_button_click_12_listener() {
      \u0275\u0275restoreView(_r5);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.fecharConfirmacao());
    });
    \u0275\u0275text(13, "Cancelar");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(14, "button", 35);
    \u0275\u0275listener("click", function ModalidadesListaComponent_Conditional_13_Template_button_click_14_listener() {
      \u0275\u0275restoreView(_r5);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.executarAcao());
    });
    \u0275\u0275text(15);
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance(2);
    \u0275\u0275classProp("icon-warn", ctx_r0.confirmando().tipo === "arquivar")("icon-danger", ctx_r0.confirmando().tipo === "excluir");
    \u0275\u0275advance();
    \u0275\u0275conditional(3, ctx_r0.confirmando().tipo === "arquivar" ? 3 : 4);
    \u0275\u0275advance(3);
    \u0275\u0275textInterpolate1(" ", ctx_r0.confirmando().tipo === "arquivar" ? "Inativar modalidade?" : "Excluir permanentemente?", " ");
    \u0275\u0275advance(2);
    \u0275\u0275conditional(8, ctx_r0.confirmando().tipo === "arquivar" ? 8 : 9);
    \u0275\u0275advance(2);
    \u0275\u0275conditional(10, ctx_r0.erroModal() ? 10 : -1);
    \u0275\u0275advance(2);
    \u0275\u0275property("disabled", ctx_r0.executando());
    \u0275\u0275advance(2);
    \u0275\u0275classMap(ctx_r0.confirmando().tipo === "excluir" ? "btn-danger" : "btn-warn");
    \u0275\u0275property("disabled", ctx_r0.executando());
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1(" ", ctx_r0.executando() ? "Aguarde..." : ctx_r0.confirmando().tipo === "arquivar" ? "Inativar" : "Excluir", " ");
  }
}
var ModalidadesListaComponent = class _ModalidadesListaComponent {
  constructor() {
    this.modalidadeService = inject(ModalidadeService);
    this.modalidades = signal([]);
    this.carregando = signal(true);
    this.erro = signal("");
    this.confirmando = signal(null);
    this.executando = signal(false);
    this.erroModal = signal("");
  }
  ngOnInit() {
    this.carregar();
  }
  carregar() {
    this.carregando.set(true);
    this.modalidadeService.getAll().subscribe({
      next: (res) => {
        this.modalidades.set(res.dados ?? []);
        this.carregando.set(false);
      },
      error: () => {
        this.erro.set("Erro ao carregar modalidades.");
        this.carregando.set(false);
      }
    });
  }
  abrirConfirmacao(tipo, m) {
    this.erroModal.set("");
    this.confirmando.set({ tipo, modalidade: m });
  }
  fecharConfirmacao() {
    if (this.executando())
      return;
    this.confirmando.set(null);
  }
  executarAcao() {
    const acao = this.confirmando();
    if (!acao)
      return;
    this.executando.set(true);
    this.erroModal.set("");
    const sucesso = () => {
      this.confirmando.set(null);
      this.executando.set(false);
      this.carregar();
    };
    const falha = (err) => {
      this.erroModal.set(err.error?.mensagem ?? (acao.tipo === "excluir" ? "N\xE3o \xE9 poss\xEDvel excluir: verifique se h\xE1 faixas ou turmas vinculadas." : "Erro ao arquivar."));
      this.executando.set(false);
    };
    if (acao.tipo === "arquivar") {
      this.modalidadeService.update(acao.modalidade.id, { nome: acao.modalidade.nome, descricao: acao.modalidade.descricao, ativo: false }).subscribe({ next: sucesso, error: falha });
    } else {
      this.modalidadeService.delete(acao.modalidade.id).subscribe({ next: sucesso, error: falha });
    }
  }
  reativar(m) {
    this.modalidadeService.update(m.id, { nome: m.nome, descricao: m.descricao, ativo: true }).subscribe({
      next: () => this.carregar()
    });
  }
  static {
    this.\u0275fac = function ModalidadesListaComponent_Factory(t) {
      return new (t || _ModalidadesListaComponent)();
    };
  }
  static {
    this.\u0275cmp = /* @__PURE__ */ \u0275\u0275defineComponent({ type: _ModalidadesListaComponent, selectors: [["app-modalidades-lista"]], standalone: true, features: [\u0275\u0275StandaloneFeature], decls: 14, vars: 3, consts: [[1, "page-container"], [1, "page-header"], [1, "page-title"], [1, "page-subtitle"], ["routerLink", "novo", 1, "btn-primary"], [1, "alert-error"], [1, "skeleton-list"], [1, "skeleton-row"], [1, "empty-state"], ["width", "56", "height", "56", "fill", "none", "stroke", "currentColor", "stroke-width", "1.5", "viewBox", "0 0 24 24"], ["d", "M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"], [1, "table-wrapper"], [1, "data-table"], [2, "width", "120px"], [3, "row-inativa"], [1, "font-medium"], [2, "display", "flex", "align-items", "center", "gap", "10px"], [1, "mod-icon"], ["width", "16", "height", "16", "fill", "none", "stroke", "currentColor", "stroke-width", "1.5", "viewBox", "0 0 24 24"], [2, "color", "var(--app-text-2)", "font-size", "13px"], [1, "toggle-status", 3, "click", "title"], [1, "toggle-knob"], [2, "display", "flex", "gap", "8px"], [1, "action-link", 3, "routerLink"], ["title", "Remover permanentemente", 1, "action-link", "danger"], ["title", "Remover permanentemente", 1, "action-link", "danger", 3, "click"], [1, "modal-backdrop", 3, "click"], ["role", "dialog", 1, "modal-box"], [1, "modal-icon"], ["width", "22", "height", "22", "fill", "none", "stroke", "currentColor", "stroke-width", "2", "viewBox", "0 0 24 24"], [1, "modal-title"], [1, "modal-desc"], [1, "modal-erro"], [1, "modal-footer"], [1, "btn-ghost", 3, "click", "disabled"], [3, "click", "disabled"], ["d", "M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"], ["d", "M12 9v2m0 4h.01M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z"]], template: function ModalidadesListaComponent_Template(rf, ctx) {
      if (rf & 1) {
        \u0275\u0275elementStart(0, "div", 0)(1, "div", 1)(2, "div")(3, "h1", 2);
        \u0275\u0275text(4, "Modalidades");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(5, "p", 3);
        \u0275\u0275text(6, "Estilos de luta praticados na academia");
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(7, "a", 4);
        \u0275\u0275text(8, "+ Nova Modalidade");
        \u0275\u0275elementEnd()();
        \u0275\u0275template(9, ModalidadesListaComponent_Conditional_9_Template, 2, 1, "div", 5)(10, ModalidadesListaComponent_Conditional_10_Template, 3, 1, "div", 6)(11, ModalidadesListaComponent_Conditional_11_Template, 9, 0)(12, ModalidadesListaComponent_Conditional_12_Template, 15, 0);
        \u0275\u0275elementEnd();
        \u0275\u0275template(13, ModalidadesListaComponent_Conditional_13_Template, 16, 13);
      }
      if (rf & 2) {
        \u0275\u0275advance(9);
        \u0275\u0275conditional(9, ctx.erro() ? 9 : -1);
        \u0275\u0275advance();
        \u0275\u0275conditional(10, ctx.carregando() ? 10 : ctx.modalidades().length === 0 ? 11 : 12);
        \u0275\u0275advance(3);
        \u0275\u0275conditional(13, ctx.confirmando() ? 13 : -1);
      }
    }, dependencies: [CommonModule, RouterLink], styles: [".row-inativa[_ngcontent-%COMP%] { opacity: 0.6; }\n  .mod-icon[_ngcontent-%COMP%] { width: 30px; height: 30px; border-radius: 7px; background: rgba(99,102,241,0.1); color: #6366f1; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }\n\n  \n\n  .toggle-status[_ngcontent-%COMP%] { display: inline-flex; align-items: center; gap: 7px; padding: 4px 10px 4px 4px; border: 1px solid var(--app-border); border-radius: 99px; background: var(--app-surface); cursor: pointer; font-size: 12px; font-weight: 500; color: var(--app-text-2); transition: all 0.2s; }\n  .toggle-status[_ngcontent-%COMP%]   .toggle-knob[_ngcontent-%COMP%] { width: 18px; height: 18px; border-radius: 50%; background: var(--app-border); transition: background 0.2s; }\n  .toggle-status.ativo[_ngcontent-%COMP%] { border-color: rgba(34,197,94,0.4); color: #16a34a; }\n  .toggle-status.ativo[_ngcontent-%COMP%]   .toggle-knob[_ngcontent-%COMP%] { background: #22c55e; }\n  .toggle-status[_ngcontent-%COMP%]:hover { opacity: 0.8; }\n\n  \n\n  .modal-backdrop[_ngcontent-%COMP%] { position: fixed; inset: 0; background: rgba(0,0,0,0.5); z-index: 100; }\n  .modal-box[_ngcontent-%COMP%] { position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%); z-index: 101; background: var(--app-surface); border: 1px solid var(--app-border); border-radius: 16px; width: 400px; max-width: calc(100vw - 32px); padding: 28px 28px 24px; display: flex; flex-direction: column; align-items: center; gap: 12px; box-shadow: 0 20px 60px rgba(0,0,0,0.4); text-align: center; }\n  .modal-icon[_ngcontent-%COMP%] { width: 52px; height: 52px; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin-bottom: 4px; }\n  .icon-warn[_ngcontent-%COMP%] { background: rgba(245,158,11,0.12); color: #f59e0b; }\n  .icon-danger[_ngcontent-%COMP%] { background: rgba(239,68,68,0.1); color: #ef4444; }\n  .modal-title[_ngcontent-%COMP%] { font-size: 1.05rem; font-weight: 700; color: var(--app-text-1); margin: 0; }\n  .modal-desc[_ngcontent-%COMP%] { font-size: 0.875rem; color: var(--app-text-2); margin: 0; line-height: 1.6; }\n  .modal-erro[_ngcontent-%COMP%] { font-size: 0.8rem; color: #ef4444; font-weight: 500; margin: 0; }\n  .modal-footer[_ngcontent-%COMP%] { display: flex; gap: 10px; margin-top: 8px; width: 100%; justify-content: flex-end; }\n  .btn-ghost[_ngcontent-%COMP%] { padding: 9px 18px; background: transparent; border: 1px solid var(--app-border); border-radius: 8px; font-size: 0.875rem; font-weight: 500; color: var(--app-text-2); cursor: pointer; }\n  .btn-ghost[_ngcontent-%COMP%]:disabled { opacity: 0.6; cursor: not-allowed; }\n  .btn-ghost[_ngcontent-%COMP%]:hover:not(:disabled) { background: var(--app-border); }\n  .btn-danger[_ngcontent-%COMP%] { padding: 9px 18px; background: #ef4444; color: #fff; border: none; border-radius: 8px; font-size: 0.875rem; font-weight: 600; cursor: pointer; }\n  .btn-danger[_ngcontent-%COMP%]:disabled, .btn-warn[_ngcontent-%COMP%]:disabled { opacity: 0.6; cursor: not-allowed; }\n  .btn-danger[_ngcontent-%COMP%]:hover:not(:disabled) { opacity: 0.88; }\n  .btn-warn[_ngcontent-%COMP%] { padding: 9px 18px; background: #f59e0b; color: #fff; border: none; border-radius: 8px; font-size: 0.875rem; font-weight: 600; cursor: pointer; }\n  .btn-warn[_ngcontent-%COMP%]:hover:not(:disabled) { opacity: 0.88; }"] });
  }
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && \u0275setClassDebugInfo(ModalidadesListaComponent, { className: "ModalidadesListaComponent" });
})();
export {
  ModalidadesListaComponent
};
//# sourceMappingURL=chunk-5TH6LAEF.js.map
