import {
  FormsModule
} from "./chunk-JQJL26HT.js";
import {
  environment
} from "./chunk-Z5CKO2JM.js";
import {
  CommonModule,
  HttpClient,
  inject,
  signal,
  ɵsetClassDebugInfo,
  ɵɵStandaloneFeature,
  ɵɵadvance,
  ɵɵclassProp,
  ɵɵconditional,
  ɵɵdefineComponent,
  ɵɵdefineInjectable,
  ɵɵelement,
  ɵɵelementEnd,
  ɵɵelementStart,
  ɵɵgetCurrentView,
  ɵɵlistener,
  ɵɵnamespaceHTML,
  ɵɵnamespaceSVG,
  ɵɵnextContext,
  ɵɵproperty,
  ɵɵrepeater,
  ɵɵrepeaterCreate,
  ɵɵrepeaterTrackByIndex,
  ɵɵresetView,
  ɵɵrestoreView,
  ɵɵtemplate,
  ɵɵtext,
  ɵɵtextInterpolate,
  ɵɵtextInterpolate1
} from "./chunk-WZ2AWGAJ.js";
import "./chunk-7G5TR5RR.js";

// src/app/core/services/catraca.service.ts
var CatracaService = class _CatracaService {
  constructor() {
    this.http = inject(HttpClient);
    this.api = `${environment.apiUrl}/api/catraca`;
  }
  validar(identificador) {
    return this.http.post(`${this.api}/validar`, { identificador });
  }
  abrirManualmente() {
    return this.http.post(`${this.api}/abrir`, {});
  }
  static {
    this.\u0275fac = function CatracaService_Factory(t) {
      return new (t || _CatracaService)();
    };
  }
  static {
    this.\u0275prov = /* @__PURE__ */ \u0275\u0275defineInjectable({ token: _CatracaService, factory: _CatracaService.\u0275fac, providedIn: "root" });
  }
};

// src/app/features/catraca/catraca.component.ts
function CatracaComponent_Conditional_29_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275element(0, "span", 30);
    \u0275\u0275text(1, " Abrindo... ");
  }
}
function CatracaComponent_Conditional_30_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(0, "svg", 31);
    \u0275\u0275element(1, "path", 32)(2, "path", 33)(3, "line", 34)(4, "line", 35)(5, "line", 36);
    \u0275\u0275elementEnd();
    \u0275\u0275text(6, " Liberar catraca ");
  }
}
function CatracaComponent_Conditional_31_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "p", 20);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1(" \xDAltima abertura \xE0s ", ctx_r0.ultimaAbertura(), " ");
  }
}
function CatracaComponent_Conditional_47_Conditional_2_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275namespaceSVG();
    \u0275\u0275element(0, "path", 41)(1, "polyline", 42);
  }
}
function CatracaComponent_Conditional_47_Conditional_3_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275namespaceSVG();
    \u0275\u0275element(0, "circle", 7)(1, "line", 43)(2, "line", 44);
  }
}
function CatracaComponent_Conditional_47_Template(rf, ctx) {
  if (rf & 1) {
    const _r2 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 37);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(1, "svg", 6);
    \u0275\u0275template(2, CatracaComponent_Conditional_47_Conditional_2_Template, 2, 0)(3, CatracaComponent_Conditional_47_Conditional_3_Template, 3, 0);
    \u0275\u0275elementEnd();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(4, "div")(5, "div", 38);
    \u0275\u0275text(6);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(7, "div", 39);
    \u0275\u0275text(8);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(9, "button", 40);
    \u0275\u0275listener("click", function CatracaComponent_Conditional_47_Template_button_click_9_listener() {
      \u0275\u0275restoreView(_r2);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.limparBusca());
    });
    \u0275\u0275text(10, "\u2715");
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    let tmp_5_0;
    let tmp_6_0;
    const r_r3 = ctx;
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275classProp("resultado-ok", r_r3.permitido)("resultado-nok", !r_r3.permitido);
    \u0275\u0275advance(2);
    \u0275\u0275conditional(2, r_r3.permitido ? 2 : 3);
    \u0275\u0275advance(4);
    \u0275\u0275textInterpolate((tmp_5_0 = r_r3.nomeAluno) !== null && tmp_5_0 !== void 0 ? tmp_5_0 : ctx_r0.identificador());
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(r_r3.permitido ? "Acesso permitido" : (tmp_6_0 = r_r3.motivo) !== null && tmp_6_0 !== void 0 ? tmp_6_0 : "Acesso negado");
  }
}
function CatracaComponent_Conditional_48_For_27_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "tr")(1, "td", 54);
    \u0275\u0275text(2);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "td")(4, "span", 55);
    \u0275\u0275text(5);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(6, "td", 56);
    \u0275\u0275text(7);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(8, "td")(9, "span", 55);
    \u0275\u0275text(10);
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    let tmp_18_0;
    const entry_r4 = ctx.$implicit;
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(entry_r4.hora);
    \u0275\u0275advance(2);
    \u0275\u0275classProp("badge-neutral", entry_r4.tipo === "manual")("badge-info", entry_r4.tipo === "validacao");
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1(" ", entry_r4.tipo === "manual" ? "Manual" : "Busca", " ");
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(entry_r4.nome);
    \u0275\u0275advance(2);
    \u0275\u0275classProp("badge-success", entry_r4.sucesso)("badge-error", !entry_r4.sucesso);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1(" ", entry_r4.sucesso ? "Liberado" : (tmp_18_0 = entry_r4.motivo) !== null && tmp_18_0 !== void 0 ? tmp_18_0 : "Negado", " ");
  }
}
function CatracaComponent_Conditional_48_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 29)(1, "div", 22)(2, "div", 13);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(3, "svg", 6);
    \u0275\u0275element(4, "path", 45)(5, "polyline", 46)(6, "line", 47)(7, "line", 48);
    \u0275\u0275elementEnd()();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(8, "div")(9, "h2", 17);
    \u0275\u0275text(10, "Log da sess\xE3o");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(11, "p", 18);
    \u0275\u0275text(12, "\xDAltimas a\xE7\xF5es (reiniciado ao sair da p\xE1gina)");
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(13, "div", 49)(14, "table", 50)(15, "thead")(16, "tr")(17, "th", 51);
    \u0275\u0275text(18, "Hora");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(19, "th", 52);
    \u0275\u0275text(20, "Tipo");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(21, "th");
    \u0275\u0275text(22, "Identificado");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(23, "th", 53);
    \u0275\u0275text(24, "Resultado");
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(25, "tbody");
    \u0275\u0275repeaterCreate(26, CatracaComponent_Conditional_48_For_27_Template, 11, 12, "tr", null, \u0275\u0275repeaterTrackByIndex);
    \u0275\u0275elementEnd()()()();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance(26);
    \u0275\u0275repeater(ctx_r0.log());
  }
}
var CatracaComponent = class _CatracaComponent {
  constructor() {
    this.catracaService = inject(CatracaService);
    this.abrindo = signal(false);
    this.ultimaAbertura = signal(null);
    this.log = signal([]);
    this.buscando = signal(false);
    this.identificador = signal("");
    this.resultadoBusca = signal(null);
  }
  abrirManualmente() {
    this.abrindo.set(true);
    this.catracaService.abrirManualmente().subscribe({
      next: (res) => {
        const hora = (/* @__PURE__ */ new Date()).toLocaleTimeString("pt-BR");
        this.ultimaAbertura.set(hora);
        this.log.update((l) => [
          { hora, tipo: "manual", nome: res.dados?.operadorNome ?? "Operador", sucesso: true },
          ...l.slice(0, 19)
        ]);
        this.abrindo.set(false);
      },
      error: () => {
        this.abrindo.set(false);
      }
    });
  }
  buscarAluno() {
    if (!this.identificador().trim())
      return;
    this.buscando.set(true);
    this.resultadoBusca.set(null);
    this.catracaService.validar(this.identificador()).subscribe({
      next: (res) => {
        const resultado = res.dados ?? null;
        this.resultadoBusca.set(resultado);
        const hora = (/* @__PURE__ */ new Date()).toLocaleTimeString("pt-BR");
        this.log.update((l) => [
          {
            hora,
            tipo: "validacao",
            nome: resultado?.nomeAluno ?? this.identificador(),
            sucesso: resultado?.permitido ?? false,
            motivo: resultado?.motivo ?? void 0
          },
          ...l.slice(0, 19)
        ]);
        this.buscando.set(false);
      },
      error: () => {
        this.buscando.set(false);
      }
    });
  }
  limparBusca() {
    this.identificador.set("");
    this.resultadoBusca.set(null);
  }
  static {
    this.\u0275fac = function CatracaComponent_Factory(t) {
      return new (t || _CatracaComponent)();
    };
  }
  static {
    this.\u0275cmp = /* @__PURE__ */ \u0275\u0275defineComponent({ type: _CatracaComponent, selectors: [["app-catraca"]], standalone: true, features: [\u0275\u0275StandaloneFeature], decls: 49, vars: 7, consts: [[1, "page-container", 2, "max-width", "820px"], [1, "page-header"], [1, "page-title"], [1, "page-subtitle"], [1, "badge-pendente"], [1, "aviso-hardware"], ["width", "18", "height", "18", "fill", "none", "stroke", "currentColor", "stroke-width", "2", "viewBox", "0 0 24 24"], ["cx", "12", "cy", "12", "r", "10"], ["x1", "12", "y1", "8", "x2", "12", "y2", "12"], ["x1", "12", "y1", "16", "x2", "12.01", "y2", "16"], [1, "cards-row"], [1, "config-card", 2, "flex", "1", "text-align", "center"], [1, "config-card-header", 2, "justify-content", "center", "margin-bottom", "12px"], [1, "config-icon"], ["x", "3", "y", "11", "width", "18", "height", "11", "rx", "2"], ["d", "M7 11V7a5 5 0 0 1 10 0v4"], [2, "text-align", "left"], [1, "config-card-title"], [1, "config-card-sub"], [1, "btn-abrir", 3, "click", "disabled"], [2, "font-size", "12px", "color", "var(--app-text-2)", "margin-top", "10px"], [1, "config-card", 2, "flex", "1"], [1, "config-card-header", 2, "margin-bottom", "12px"], ["cx", "11", "cy", "11", "r", "8"], ["x1", "21", "y1", "21", "x2", "16.65", "y2", "16.65"], [2, "display", "flex", "gap", "8px", "margin-bottom", "12px"], ["placeholder", "E-mail do aluno...", 1, "form-input", 2, "flex", "1", 3, "input", "keydown.enter", "value"], [1, "btn-primary", 3, "click", "disabled"], [1, "resultado", 3, "resultado-ok", "resultado-nok"], [1, "config-card"], [1, "spinner"], ["width", "22", "height", "22", "fill", "none", "stroke", "currentColor", "stroke-width", "2", "viewBox", "0 0 24 24"], ["d", "M18 8h1a4 4 0 0 1 0 8h-1"], ["d", "M2 8h16v9a4 4 0 0 1-4 4H6a4 4 0 0 1-4-4V8z"], ["x1", "6", "y1", "1", "x2", "6", "y2", "4"], ["x1", "10", "y1", "1", "x2", "10", "y2", "4"], ["x1", "14", "y1", "1", "x2", "14", "y2", "4"], [1, "resultado"], [2, "font-weight", "600", "font-size", "14px"], [2, "font-size", "12px"], ["title", "Limpar", 1, "btn-dots", 2, "margin-left", "auto", 3, "click"], ["d", "M22 11.08V12a10 10 0 1 1-5.93-9.14"], ["points", "22 4 12 14.01 9 11.01"], ["x1", "15", "y1", "9", "x2", "9", "y2", "15"], ["x1", "9", "y1", "9", "x2", "15", "y2", "15"], ["d", "M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"], ["points", "14 2 14 8 20 8"], ["x1", "16", "y1", "13", "x2", "8", "y2", "13"], ["x1", "16", "y1", "17", "x2", "8", "y2", "17"], [1, "table-wrapper"], [1, "data-table"], [2, "width", "70px"], [2, "width", "90px"], [2, "width", "110px"], [2, "font-size", "12px", "color", "var(--app-text-2)"], [1, "badge"], [1, "font-medium"]], template: function CatracaComponent_Template(rf, ctx) {
      if (rf & 1) {
        \u0275\u0275elementStart(0, "div", 0)(1, "div", 1)(2, "div")(3, "h1", 2);
        \u0275\u0275text(4, "Catraca");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(5, "p", 3);
        \u0275\u0275text(6, "Controle de acesso da academia");
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(7, "span", 4);
        \u0275\u0275text(8, "Hardware n\xE3o conectado");
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(9, "div", 5);
        \u0275\u0275namespaceSVG();
        \u0275\u0275elementStart(10, "svg", 6);
        \u0275\u0275element(11, "circle", 7)(12, "line", 8)(13, "line", 9);
        \u0275\u0275elementEnd();
        \u0275\u0275namespaceHTML();
        \u0275\u0275elementStart(14, "span");
        \u0275\u0275text(15, " Integra\xE7\xE3o com hardware pendente. Quando a catraca for instalada, o bot\xE3o abaixo enviar\xE1 o comando f\xEDsico de abertura e o campo de busca ser\xE1 utilizado automaticamente pela leitora. ");
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(16, "div", 10)(17, "div", 11)(18, "div", 12)(19, "div", 13);
        \u0275\u0275namespaceSVG();
        \u0275\u0275elementStart(20, "svg", 6);
        \u0275\u0275element(21, "rect", 14)(22, "path", 15);
        \u0275\u0275elementEnd()();
        \u0275\u0275namespaceHTML();
        \u0275\u0275elementStart(23, "div", 16)(24, "h2", 17);
        \u0275\u0275text(25, "Abertura manual");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(26, "p", 18);
        \u0275\u0275text(27, "Secretaria libera o acesso");
        \u0275\u0275elementEnd()()();
        \u0275\u0275elementStart(28, "button", 19);
        \u0275\u0275listener("click", function CatracaComponent_Template_button_click_28_listener() {
          return ctx.abrirManualmente();
        });
        \u0275\u0275template(29, CatracaComponent_Conditional_29_Template, 2, 0)(30, CatracaComponent_Conditional_30_Template, 7, 0);
        \u0275\u0275elementEnd();
        \u0275\u0275template(31, CatracaComponent_Conditional_31_Template, 2, 1, "p", 20);
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(32, "div", 21)(33, "div", 22)(34, "div", 13);
        \u0275\u0275namespaceSVG();
        \u0275\u0275elementStart(35, "svg", 6);
        \u0275\u0275element(36, "circle", 23)(37, "line", 24);
        \u0275\u0275elementEnd()();
        \u0275\u0275namespaceHTML();
        \u0275\u0275elementStart(38, "div")(39, "h2", 17);
        \u0275\u0275text(40, "Verificar aluno");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(41, "p", 18);
        \u0275\u0275text(42, "Buscar por e-mail ou matr\xEDcula");
        \u0275\u0275elementEnd()()();
        \u0275\u0275elementStart(43, "div", 25)(44, "input", 26);
        \u0275\u0275listener("input", function CatracaComponent_Template_input_input_44_listener($event) {
          return ctx.identificador.set($event.target.value);
        })("keydown.enter", function CatracaComponent_Template_input_keydown_enter_44_listener() {
          return ctx.buscarAluno();
        });
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(45, "button", 27);
        \u0275\u0275listener("click", function CatracaComponent_Template_button_click_45_listener() {
          return ctx.buscarAluno();
        });
        \u0275\u0275text(46, " Verificar ");
        \u0275\u0275elementEnd()();
        \u0275\u0275template(47, CatracaComponent_Conditional_47_Template, 11, 7, "div", 28);
        \u0275\u0275elementEnd()();
        \u0275\u0275template(48, CatracaComponent_Conditional_48_Template, 28, 0, "div", 29);
        \u0275\u0275elementEnd();
      }
      if (rf & 2) {
        let tmp_5_0;
        \u0275\u0275advance(28);
        \u0275\u0275property("disabled", ctx.abrindo());
        \u0275\u0275advance();
        \u0275\u0275conditional(29, ctx.abrindo() ? 29 : 30);
        \u0275\u0275advance(2);
        \u0275\u0275conditional(31, ctx.ultimaAbertura() ? 31 : -1);
        \u0275\u0275advance(13);
        \u0275\u0275property("value", ctx.identificador());
        \u0275\u0275advance();
        \u0275\u0275property("disabled", ctx.buscando() || !ctx.identificador().trim());
        \u0275\u0275advance(2);
        \u0275\u0275conditional(47, (tmp_5_0 = ctx.resultadoBusca()) ? 47 : -1, tmp_5_0);
        \u0275\u0275advance();
        \u0275\u0275conditional(48, ctx.log().length > 0 ? 48 : -1);
      }
    }, dependencies: [CommonModule, FormsModule], styles: [".cards-row[_ngcontent-%COMP%] { display: flex; gap: 14px; margin-bottom: 14px; flex-wrap: wrap; }\n  .config-card[_ngcontent-%COMP%] { background: var(--app-surface); border: 1px solid var(--app-border); border-radius: 12px; padding: 20px 24px; margin-bottom: 14px; }\n  .config-card-header[_ngcontent-%COMP%] { display: flex; align-items: flex-start; gap: 14px; }\n  .config-icon[_ngcontent-%COMP%] { width: 36px; height: 36px; border-radius: 8px; background: rgba(99,102,241,0.1); color: #6366f1; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }\n  .config-card-title[_ngcontent-%COMP%] { font-size: 15px; font-weight: 700; margin: 0 0 2px; color: var(--app-text-1); }\n  .config-card-sub[_ngcontent-%COMP%] { font-size: 12px; color: var(--app-text-2); margin: 0; }\n\n  .badge-pendente[_ngcontent-%COMP%] { font-size: 11px; font-weight: 600; padding: 4px 10px; border-radius: 99px; background: rgba(234,179,8,0.15); color: #ca8a04; }\n\n  .aviso-hardware[_ngcontent-%COMP%] { display: flex; align-items: flex-start; gap: 10px; background: rgba(234,179,8,0.08); border: 1px solid rgba(234,179,8,0.25); border-radius: 10px; padding: 12px 16px; margin-bottom: 16px; font-size: 13px; color: var(--app-text-2); }\n\n  .btn-abrir[_ngcontent-%COMP%] { display: inline-flex; align-items: center; gap: 10px; padding: 14px 28px; background: #6366f1; color: white; border: none; border-radius: 10px; font-size: 16px; font-weight: 700; cursor: pointer; transition: background 0.15s; margin: 8px 0; }\n  .btn-abrir[_ngcontent-%COMP%]:hover:not(:disabled) { background: #4f46e5; }\n  .btn-abrir[_ngcontent-%COMP%]:disabled { opacity: 0.6; cursor: not-allowed; }\n\n  .spinner[_ngcontent-%COMP%] { width: 16px; height: 16px; border: 2px solid rgba(255,255,255,0.4); border-top-color: white; border-radius: 50%; animation: _ngcontent-%COMP%_spin 0.7s linear infinite; }\n  @keyframes _ngcontent-%COMP%_spin { to { transform: rotate(360deg); } }\n\n  .resultado[_ngcontent-%COMP%] { display: flex; align-items: center; gap: 12px; padding: 12px 14px; border-radius: 10px; border: 1px solid; }\n  .resultado-ok[_ngcontent-%COMP%] { background: rgba(34,197,94,0.08); border-color: rgba(34,197,94,0.3); color: #16a34a; }\n  .resultado-nok[_ngcontent-%COMP%] { background: rgba(239,68,68,0.08); border-color: rgba(239,68,68,0.25); color: #dc2626; }\n\n  .badge[_ngcontent-%COMP%] { font-size: 11px; font-weight: 600; padding: 2px 8px; border-radius: 99px; }\n  .badge-success[_ngcontent-%COMP%] { background: rgba(34,197,94,0.15); color: #22c55e; }\n  .badge-error[_ngcontent-%COMP%] { background: rgba(239,68,68,0.12); color: #ef4444; }\n  .badge-neutral[_ngcontent-%COMP%] { background: rgba(148,163,184,0.15); color: #94a3b8; }\n  .badge-info[_ngcontent-%COMP%] { background: rgba(99,102,241,0.12); color: #6366f1; }\n\n  .btn-dots[_ngcontent-%COMP%] { background: none; border: none; cursor: pointer; color: var(--app-text-3); font-size: 14px; padding: 4px; }"] });
  }
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && \u0275setClassDebugInfo(CatracaComponent, { className: "CatracaComponent" });
})();
export {
  CatracaComponent
};
//# sourceMappingURL=chunk-UEVQ3ENE.js.map
