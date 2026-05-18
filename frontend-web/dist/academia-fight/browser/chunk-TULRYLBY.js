import {
  AlunoService
} from "./chunk-ZSIQJU4D.js";
import {
  AuthService
} from "./chunk-V3IOF26G.js";
import {
  environment
} from "./chunk-Z5CKO2JM.js";
import "./chunk-AXNOULNC.js";
import {
  CommonModule,
  HttpClient,
  inject,
  signal,
  ɵsetClassDebugInfo,
  ɵɵStandaloneFeature,
  ɵɵadvance,
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
  ɵɵpureFunction0,
  ɵɵrepeater,
  ɵɵrepeaterCreate,
  ɵɵrepeaterTrackByIdentity,
  ɵɵresetView,
  ɵɵrestoreView,
  ɵɵtemplate,
  ɵɵtext,
  ɵɵtextInterpolate,
  ɵɵtextInterpolate1,
  ɵɵtextInterpolate2
} from "./chunk-WZ2AWGAJ.js";
import "./chunk-7G5TR5RR.js";

// src/app/core/services/dashboard.service.ts
var DashboardService = class _DashboardService {
  constructor() {
    this.http = inject(HttpClient);
  }
  getResumo() {
    return this.http.get(`${environment.apiUrl}/api/dashboard/resumo`);
  }
  static {
    this.\u0275fac = function DashboardService_Factory(t) {
      return new (t || _DashboardService)();
    };
  }
  static {
    this.\u0275prov = /* @__PURE__ */ \u0275\u0275defineInjectable({ token: _DashboardService, factory: _DashboardService.\u0275fac, providedIn: "root" });
  }
};

// src/app/features/dashboard/dashboard.component.ts
var _forTrack0 = ($index, $item) => $item.id;
var _forTrack1 = ($index, $item) => $item.horarioId;
var _c0 = () => [1, 2, 3, 4];
function DashboardComponent_Conditional_6_For_2_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275element(0, "div", 3);
  }
}
function DashboardComponent_Conditional_6_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 2);
    \u0275\u0275repeaterCreate(1, DashboardComponent_Conditional_6_For_2_Template, 1, 0, "div", 3, \u0275\u0275repeaterTrackByIdentity);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    \u0275\u0275advance();
    \u0275\u0275repeater(\u0275\u0275pureFunction0(0, _c0));
  }
}
function DashboardComponent_Conditional_7_Template(rf, ctx) {
  if (rf & 1) {
    const _r1 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 4)(1, "p");
    \u0275\u0275text(2);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "button", 5);
    \u0275\u0275listener("click", function DashboardComponent_Conditional_7_Template_button_click_3_listener() {
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
function DashboardComponent_Conditional_8_Conditional_40_For_10_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 29)(1, "div", 30);
    \u0275\u0275text(2);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "span", 31);
    \u0275\u0275text(4);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(5, "span", 32);
    \u0275\u0275text(6);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const a_r3 = ctx.$implicit;
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(a_r3.nome.charAt(0).toUpperCase());
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(a_r3.nome);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate1("dia ", a_r3.diaNascimento, "");
  }
}
function DashboardComponent_Conditional_8_Conditional_40_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 19)(1, "div", 23);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(2, "svg", 24);
    \u0275\u0275element(3, "path", 25)(4, "circle", 26);
    \u0275\u0275elementEnd();
    \u0275\u0275text(5);
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(6, "span", 27);
    \u0275\u0275text(7);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(8, "div", 28);
    \u0275\u0275repeaterCreate(9, DashboardComponent_Conditional_8_Conditional_40_For_10_Template, 7, 3, "div", 29, _forTrack0);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(2);
    \u0275\u0275advance(5);
    \u0275\u0275textInterpolate1(" Aniversariantes de ", ctx_r1.mesNomes[ctx_r1.mesAtual], " ");
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(ctx_r1.aniversariantes().length);
    \u0275\u0275advance(2);
    \u0275\u0275repeater(ctx_r1.aniversariantes());
  }
}
function DashboardComponent_Conditional_8_Conditional_44_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 22);
    \u0275\u0275text(1, "Nenhuma aula agendada para hoje.");
    \u0275\u0275elementEnd();
  }
}
function DashboardComponent_Conditional_8_Conditional_45_For_16_Template(rf, ctx) {
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
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(9, "td");
    \u0275\u0275text(10);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    let tmp_15_0;
    const aula_r4 = ctx.$implicit;
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate2("", aula_r4.horaInicio, " \u2013 ", aula_r4.horaFim, "");
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(aula_r4.turma);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(aula_r4.modalidade);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate((tmp_15_0 = aula_r4.sala) !== null && tmp_15_0 !== void 0 ? tmp_15_0 : "\u2014");
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate2("", aula_r4.totalAlunos, "/", aula_r4.capacidadeMaxima, "");
  }
}
function DashboardComponent_Conditional_8_Conditional_45_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 33)(1, "table")(2, "thead")(3, "tr")(4, "th");
    \u0275\u0275text(5, "Hor\xE1rio");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(6, "th");
    \u0275\u0275text(7, "Turma");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(8, "th");
    \u0275\u0275text(9, "Modalidade");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(10, "th");
    \u0275\u0275text(11, "Sala");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(12, "th");
    \u0275\u0275text(13, "Alunos");
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(14, "tbody");
    \u0275\u0275repeaterCreate(15, DashboardComponent_Conditional_8_Conditional_45_For_16_Template, 11, 7, "tr", null, _forTrack1);
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(2);
    \u0275\u0275advance(15);
    \u0275\u0275repeater(ctx_r1.resumo().proximasAulas);
  }
}
function DashboardComponent_Conditional_8_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 2)(1, "div", 6)(2, "div", 7)(3, "span", 8);
    \u0275\u0275text(4, "Total de Alunos");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(5, "div", 9);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(6, "svg", 10);
    \u0275\u0275element(7, "path", 11);
    \u0275\u0275elementEnd()()();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(8, "div", 12);
    \u0275\u0275text(9);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(10, "div", 6)(11, "div", 7)(12, "span", 8);
    \u0275\u0275text(13, "Turmas Ativas");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(14, "div", 9);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(15, "svg", 10);
    \u0275\u0275element(16, "rect", 13)(17, "path", 14);
    \u0275\u0275elementEnd()()();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(18, "div", 12);
    \u0275\u0275text(19);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(20, "div", 6)(21, "div", 7)(22, "span", 8);
    \u0275\u0275text(23, "Presen\xE7as Hoje");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(24, "div", 9);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(25, "svg", 10);
    \u0275\u0275element(26, "path", 15);
    \u0275\u0275elementEnd()()();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(27, "div", 12);
    \u0275\u0275text(28);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(29, "div", 6)(30, "div", 7)(31, "span", 8);
    \u0275\u0275text(32, "Sem turma");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(33, "div", 9);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(34, "svg", 10);
    \u0275\u0275element(35, "path", 16)(36, "circle", 17)(37, "line", 18);
    \u0275\u0275elementEnd()()();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(38, "div", 12);
    \u0275\u0275text(39);
    \u0275\u0275elementEnd()()();
    \u0275\u0275template(40, DashboardComponent_Conditional_8_Conditional_40_Template, 11, 2, "div", 19);
    \u0275\u0275elementStart(41, "div", 20)(42, "div", 21);
    \u0275\u0275text(43, "Pr\xF3ximas aulas hoje");
    \u0275\u0275elementEnd();
    \u0275\u0275template(44, DashboardComponent_Conditional_8_Conditional_44_Template, 2, 0, "div", 22)(45, DashboardComponent_Conditional_8_Conditional_45_Template, 17, 0);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext();
    \u0275\u0275advance(9);
    \u0275\u0275textInterpolate(ctx_r1.resumo().totalAlunos);
    \u0275\u0275advance(10);
    \u0275\u0275textInterpolate(ctx_r1.resumo().turmasAtivas);
    \u0275\u0275advance(9);
    \u0275\u0275textInterpolate(ctx_r1.resumo().presencasHoje);
    \u0275\u0275advance(11);
    \u0275\u0275textInterpolate(ctx_r1.resumo().alunosInadimplentes);
    \u0275\u0275advance();
    \u0275\u0275conditional(40, ctx_r1.aniversariantes().length > 0 ? 40 : -1);
    \u0275\u0275advance(4);
    \u0275\u0275conditional(44, ctx_r1.resumo().proximasAulas.length === 0 ? 44 : 45);
  }
}
var DashboardComponent = class _DashboardComponent {
  constructor() {
    this.authService = inject(AuthService);
    this.dashboardService = inject(DashboardService);
    this.alunoService = inject(AlunoService);
    this.resumo = signal(null);
    this.aniversariantes = signal([]);
    this.carregando = signal(true);
    this.erro = signal("");
    this.mesNomes = ["Janeiro", "Fevereiro", "Mar\xE7o", "Abril", "Maio", "Junho", "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"];
    this.mesAtual = (/* @__PURE__ */ new Date()).getMonth();
  }
  ngOnInit() {
    this.carregar();
    this.alunoService.getAniversariantes().subscribe({
      next: (res) => this.aniversariantes.set(res.dados ?? [])
    });
  }
  carregar() {
    this.carregando.set(true);
    this.erro.set("");
    this.dashboardService.getResumo().subscribe({
      next: (res) => {
        this.resumo.set(res.dados ?? null);
        this.carregando.set(false);
      },
      error: () => {
        this.erro.set("Erro ao carregar dados.");
        this.carregando.set(false);
      }
    });
  }
  static {
    this.\u0275fac = function DashboardComponent_Factory(t) {
      return new (t || _DashboardComponent)();
    };
  }
  static {
    this.\u0275cmp = /* @__PURE__ */ \u0275\u0275defineComponent({ type: _DashboardComponent, selectors: [["app-dashboard"]], standalone: true, features: [\u0275\u0275StandaloneFeature], decls: 9, vars: 2, consts: [[1, "dash-page"], [1, "dash-header"], [1, "metrics-grid"], [1, "metric-card", "skeleton-pulse", 2, "height", "100px"], [1, "error-card"], [1, "btn-secondary", 3, "click"], [1, "metric-card"], [1, "metric-top"], [1, "metric-label"], [1, "metric-icon"], ["width", "16", "height", "16", "viewBox", "0 0 24 24", "fill", "none", "stroke", "currentColor", "stroke-width", "1.75", "stroke-linecap", "round", "stroke-linejoin", "round"], ["d", "M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z"], [1, "metric-value"], ["x", "2", "y", "7", "width", "20", "height", "14", "rx", "2"], ["d", "M16 3H8a2 2 0 0 0-2 2v2h12V5a2 2 0 0 0-2-2z"], ["d", "M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"], ["d", "M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"], ["cx", "9", "cy", "7", "r", "4"], ["x1", "23", "y1", "11", "x2", "17", "y2", "11"], [1, "table-card", 2, "margin-bottom", "16px"], [1, "table-card"], [1, "table-card-header"], [1, "table-empty"], [1, "table-card-header", 2, "display", "flex", "align-items", "center", "gap", "8px"], ["width", "16", "height", "16", "fill", "none", "stroke", "currentColor", "stroke-width", "1.75", "viewBox", "0 0 24 24"], ["d", "M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"], ["cx", "12", "cy", "7", "r", "4"], [2, "margin-left", "auto", "font-size", "12px", "background", "rgba(99,102,241,0.12)", "color", "#6366f1", "padding", "2px 8px", "border-radius", "99px", "font-weight", "600"], [1, "aniversariantes-lista"], [1, "aniversariante-row"], [1, "aniversariante-avatar"], [1, "aniversariante-nome"], [1, "aniversariante-data"], [1, "table-wrap"]], template: function DashboardComponent_Template(rf, ctx) {
      if (rf & 1) {
        \u0275\u0275elementStart(0, "div", 0)(1, "div", 1)(2, "h1");
        \u0275\u0275text(3, "Dashboard");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(4, "p");
        \u0275\u0275text(5);
        \u0275\u0275elementEnd()();
        \u0275\u0275template(6, DashboardComponent_Conditional_6_Template, 3, 1, "div", 2)(7, DashboardComponent_Conditional_7_Template, 5, 1)(8, DashboardComponent_Conditional_8_Template, 46, 6);
        \u0275\u0275elementEnd();
      }
      if (rf & 2) {
        let tmp_0_0;
        \u0275\u0275advance(5);
        \u0275\u0275textInterpolate1("Bem-vindo, ", (tmp_0_0 = (tmp_0_0 = ctx.authService.currentUser()) == null ? null : tmp_0_0.nome) !== null && tmp_0_0 !== void 0 ? tmp_0_0 : "usu\xE1rio", "!");
        \u0275\u0275advance();
        \u0275\u0275conditional(6, ctx.carregando() ? 6 : ctx.erro() ? 7 : ctx.resumo() ? 8 : -1);
      }
    }, dependencies: [CommonModule], styles: ['\n\n[_nghost-%COMP%] {\n  display: block;\n  --bg-2: var(--app-surface);\n  --bg-3: var(--app-table-head-bg);\n  --fg: var(--app-text-1);\n  --fg-2: var(--app-text-2);\n  --fg-3: var(--app-text-3);\n  --line: var(--app-border);\n  --accent: #ff4d2e;\n  --good: #16a34a;\n  font-family:\n    "Inter",\n    system-ui,\n    -apple-system,\n    sans-serif;\n  -webkit-font-smoothing: antialiased;\n  color: var(--fg);\n}\n.dash-page[_ngcontent-%COMP%] {\n  max-width: 1100px;\n  margin: 0 auto;\n}\n.dash-header[_ngcontent-%COMP%] {\n  margin-bottom: 28px;\n}\n.dash-header[_ngcontent-%COMP%]   h1[_ngcontent-%COMP%] {\n  font-size: 24px;\n  font-weight: 600;\n  letter-spacing: -0.02em;\n  color: var(--fg);\n}\n.dash-header[_ngcontent-%COMP%]   p[_ngcontent-%COMP%] {\n  font-size: 14px;\n  color: var(--fg-3);\n  margin-top: 4px;\n}\n.metrics-grid[_ngcontent-%COMP%] {\n  display: grid;\n  grid-template-columns: repeat(4, 1fr);\n  gap: 16px;\n  margin-bottom: 24px;\n}\n@media (max-width: 1024px) {\n  .metrics-grid[_ngcontent-%COMP%] {\n    grid-template-columns: repeat(2, 1fr);\n  }\n}\n@media (max-width: 600px) {\n  .metrics-grid[_ngcontent-%COMP%] {\n    grid-template-columns: 1fr;\n  }\n}\n.metric-card[_ngcontent-%COMP%] {\n  background: var(--bg-2);\n  border: 1px solid var(--line);\n  border-radius: 12px;\n  padding: 20px;\n}\n.metric-top[_ngcontent-%COMP%] {\n  display: flex;\n  align-items: center;\n  justify-content: space-between;\n  margin-bottom: 14px;\n}\n.metric-label[_ngcontent-%COMP%] {\n  font-size: 11px;\n  letter-spacing: 0.08em;\n  text-transform: uppercase;\n  color: var(--fg-3);\n  font-family:\n    "JetBrains Mono",\n    "Courier New",\n    monospace;\n}\n.metric-icon[_ngcontent-%COMP%] {\n  width: 32px;\n  height: 32px;\n  border-radius: 7px;\n  background: rgba(255, 77, 46, 0.1);\n  border: 1px solid rgba(255, 77, 46, 0.18);\n  display: flex;\n  align-items: center;\n  justify-content: center;\n  color: var(--accent);\n  flex-shrink: 0;\n}\n.metric-value[_ngcontent-%COMP%] {\n  font-size: 30px;\n  font-weight: 600;\n  letter-spacing: -0.03em;\n  color: var(--fg);\n  line-height: 1;\n}\n.metric-delta[_ngcontent-%COMP%] {\n  font-size: 12px;\n  color: var(--fg-3);\n  margin-top: 6px;\n  font-family:\n    "JetBrains Mono",\n    "Courier New",\n    monospace;\n}\n.metric-delta.positive[_ngcontent-%COMP%] {\n  color: var(--good);\n}\n.table-card[_ngcontent-%COMP%] {\n  background: var(--bg-2);\n  border: 1px solid var(--line);\n  border-radius: 12px;\n  overflow: hidden;\n}\n.table-card-header[_ngcontent-%COMP%] {\n  padding: 14px 20px;\n  border-bottom: 1px solid var(--line);\n  font-size: 14px;\n  font-weight: 500;\n  color: var(--fg);\n}\n.table-wrap[_ngcontent-%COMP%] {\n  overflow-x: auto;\n}\ntable[_ngcontent-%COMP%] {\n  width: 100%;\n  border-collapse: collapse;\n  font-size: 13px;\n}\nthead[_ngcontent-%COMP%]   th[_ngcontent-%COMP%] {\n  padding: 10px 20px;\n  text-align: left;\n  font-size: 10px;\n  letter-spacing: 0.1em;\n  text-transform: uppercase;\n  color: var(--fg-3);\n  border-bottom: 1px solid var(--line);\n  font-weight: 500;\n  font-family:\n    "JetBrains Mono",\n    "Courier New",\n    monospace;\n}\ntbody[_ngcontent-%COMP%]   td[_ngcontent-%COMP%] {\n  padding: 12px 20px;\n  color: var(--fg-2);\n  border-bottom: 1px solid var(--line);\n}\ntbody[_ngcontent-%COMP%]   tr[_ngcontent-%COMP%]:last-child   td[_ngcontent-%COMP%] {\n  border-bottom: none;\n}\ntbody[_ngcontent-%COMP%]   tr[_ngcontent-%COMP%]:hover   td[_ngcontent-%COMP%] {\n  background: rgba(255, 255, 255, 0.02);\n}\n.table-empty[_ngcontent-%COMP%] {\n  padding: 20px;\n  text-align: center;\n  font-size: 12px;\n  color: var(--fg-3);\n  font-family:\n    "JetBrains Mono",\n    "Courier New",\n    monospace;\n  border-top: 1px solid var(--line);\n}\n.aniversariantes-lista[_ngcontent-%COMP%] {\n  display: flex;\n  flex-direction: column;\n  padding: 4px 0;\n}\n.aniversariante-row[_ngcontent-%COMP%] {\n  display: flex;\n  align-items: center;\n  gap: 12px;\n  padding: 10px 16px;\n  border-bottom: 1px solid var(--line);\n}\n.aniversariante-row[_ngcontent-%COMP%]:last-child {\n  border-bottom: none;\n}\n.aniversariante-avatar[_ngcontent-%COMP%] {\n  width: 32px;\n  height: 32px;\n  border-radius: 50%;\n  background: rgba(99, 102, 241, 0.15);\n  color: #6366f1;\n  display: flex;\n  align-items: center;\n  justify-content: center;\n  font-size: 13px;\n  font-weight: 700;\n  flex-shrink: 0;\n}\n.aniversariante-nome[_ngcontent-%COMP%] {\n  flex: 1;\n  font-size: 13px;\n  font-weight: 500;\n  color: var(--fg);\n}\n.aniversariante-data[_ngcontent-%COMP%] {\n  font-size: 12px;\n  font-weight: 600;\n  color: #6366f1;\n  background: rgba(99, 102, 241, 0.1);\n  padding: 2px 8px;\n  border-radius: 99px;\n}\n/*# sourceMappingURL=dashboard.component.css.map */'] });
  }
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && \u0275setClassDebugInfo(DashboardComponent, { className: "DashboardComponent" });
})();
export {
  DashboardComponent
};
//# sourceMappingURL=chunk-TULRYLBY.js.map
