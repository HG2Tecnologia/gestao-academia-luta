import {
  FinanceiroService
} from "./chunk-KMLMG5SQ.js";
import {
  FormsModule,
  NgControlStatus,
  NgModel,
  NgSelectOption,
  SelectControlValueAccessor,
  ɵNgSelectMultipleOption
} from "./chunk-JQJL26HT.js";
import "./chunk-Z5CKO2JM.js";
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

// src/app/features/relatorios/pages/geral/relatorios.component.ts
var _forTrack0 = ($index, $item) => $item.mes;
var _forTrack1 = ($index, $item) => $item.alunoId;
var _c0 = () => [1, 2, 3];
function RelatoriosComponent_Conditional_5_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "p", 3);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance();
    \u0275\u0275textInterpolate2("Ano ", ctx_r0.anoSelecionado(), " \xB7 ", ctx_r0.relatorio().totalAlunosAtivos, " alunos ativos");
  }
}
function RelatoriosComponent_For_9_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "option", 6);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const a_r2 = ctx.$implicit;
    \u0275\u0275property("value", a_r2);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(a_r2);
  }
}
function RelatoriosComponent_Conditional_10_Template(rf, ctx) {
  if (rf & 1) {
    const _r3 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "button", 9);
    \u0275\u0275listener("click", function RelatoriosComponent_Conditional_10_Template_button_click_0_listener() {
      \u0275\u0275restoreView(_r3);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.exportarCSV());
    });
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(1, "svg", 10);
    \u0275\u0275element(2, "path", 11)(3, "polyline", 12)(4, "line", 13);
    \u0275\u0275elementEnd();
    \u0275\u0275text(5, " CSV ");
    \u0275\u0275elementEnd();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(6, "button", 9);
    \u0275\u0275listener("click", function RelatoriosComponent_Conditional_10_Template_button_click_6_listener() {
      \u0275\u0275restoreView(_r3);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.imprimirPDF());
    });
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(7, "svg", 10);
    \u0275\u0275element(8, "polyline", 14)(9, "path", 15)(10, "rect", 16);
    \u0275\u0275elementEnd();
    \u0275\u0275text(11, " Imprimir ");
    \u0275\u0275elementEnd();
  }
}
function RelatoriosComponent_Conditional_11_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 7);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(ctx_r0.erro());
  }
}
function RelatoriosComponent_Conditional_12_For_2_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275element(0, "div", 17);
  }
}
function RelatoriosComponent_Conditional_12_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 8);
    \u0275\u0275repeaterCreate(1, RelatoriosComponent_Conditional_12_For_2_Template, 1, 0, "div", 17, \u0275\u0275repeaterTrackByIdentity);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    \u0275\u0275advance();
    \u0275\u0275repeater(\u0275\u0275pureFunction0(0, _c0));
  }
}
function RelatoriosComponent_Conditional_13_Conditional_0_For_26_Conditional_2_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275element(0, "div", 38);
  }
  if (rf & 2) {
    const m_r4 = \u0275\u0275nextContext().$implicit;
    const ctx_r0 = \u0275\u0275nextContext(3);
    \u0275\u0275styleProp("height", ctx_r0.barH(m_r4.recebido, ctx_r0.maxRecebido()), "%");
    \u0275\u0275property("title", ctx_r0.formatarMoeda(m_r4.recebido));
  }
}
function RelatoriosComponent_Conditional_13_Conditional_0_For_26_Conditional_3_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275element(0, "div", 39);
  }
  if (rf & 2) {
    const m_r4 = \u0275\u0275nextContext().$implicit;
    const ctx_r0 = \u0275\u0275nextContext(3);
    \u0275\u0275styleProp("height", ctx_r0.barH(m_r4.pendente, ctx_r0.maxRecebido()), "%");
    \u0275\u0275property("title", "Pendente: " + ctx_r0.formatarMoeda(m_r4.pendente));
  }
}
function RelatoriosComponent_Conditional_13_Conditional_0_For_26_Conditional_4_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275element(0, "div", 40);
  }
  if (rf & 2) {
    const m_r4 = \u0275\u0275nextContext().$implicit;
    const ctx_r0 = \u0275\u0275nextContext(3);
    \u0275\u0275styleProp("height", ctx_r0.barH(m_r4.atrasado, ctx_r0.maxRecebido()), "%");
    \u0275\u0275property("title", "Atrasado: " + ctx_r0.formatarMoeda(m_r4.atrasado));
  }
}
function RelatoriosComponent_Conditional_13_Conditional_0_For_26_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 26)(1, "div", 32);
    \u0275\u0275template(2, RelatoriosComponent_Conditional_13_Conditional_0_For_26_Conditional_2_Template, 1, 3, "div", 33)(3, RelatoriosComponent_Conditional_13_Conditional_0_For_26_Conditional_3_Template, 1, 3, "div", 34)(4, RelatoriosComponent_Conditional_13_Conditional_0_For_26_Conditional_4_Template, 1, 3, "div", 35);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(5, "div", 36);
    \u0275\u0275text(6);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(7, "div", 37);
    \u0275\u0275text(8);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const m_r4 = ctx.$implicit;
    const ctx_r0 = \u0275\u0275nextContext(3);
    \u0275\u0275advance(2);
    \u0275\u0275conditional(2, m_r4.recebido > 0 ? 2 : -1);
    \u0275\u0275advance();
    \u0275\u0275conditional(3, m_r4.pendente > 0 ? 3 : -1);
    \u0275\u0275advance();
    \u0275\u0275conditional(4, m_r4.atrasado > 0 && m_r4.atrasado !== m_r4.pendente ? 4 : -1);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(ctx_r0.meses[m_r4.mes - 1]);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(m_r4.recebido > 0 ? ctx_r0.formatarMoeda(m_r4.recebido) : "\u2014");
  }
}
function RelatoriosComponent_Conditional_13_Conditional_0_For_39_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 26)(1, "div", 32);
    \u0275\u0275element(2, "div", 41);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "div", 36);
    \u0275\u0275text(4);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(5, "div", 37);
    \u0275\u0275text(6);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const m_r5 = ctx.$implicit;
    const ctx_r0 = \u0275\u0275nextContext(3);
    \u0275\u0275advance(2);
    \u0275\u0275styleProp("height", ctx_r0.barH(m_r5.totalPresencas, ctx_r0.maxPresencas()), "%");
    \u0275\u0275property("title", m_r5.totalPresencas + " presen\xE7as");
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(ctx_r0.meses[m_r5.mes - 1]);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(m_r5.totalPresencas > 0 ? m_r5.totalPresencas : "\u2014");
  }
}
function RelatoriosComponent_Conditional_13_Conditional_0_Conditional_43_For_17_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "tr")(1, "td", 46);
    \u0275\u0275text(2);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "td", 47);
    \u0275\u0275text(4);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(5, "td", 45)(6, "span", 48);
    \u0275\u0275text(7);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(8, "td", 49);
    \u0275\u0275text(9);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const ind_r6 = ctx.$implicit;
    const ctx_r0 = \u0275\u0275nextContext(4);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(ind_r6.nomeAluno);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(ctx_r0.formatarMoeda(ind_r6.totalDevido));
    \u0275\u0275advance(2);
    \u0275\u0275classProp("badge-dias-critico", ind_r6.diasAtraso > 30);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1("", ind_r6.diasAtraso, "d");
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(ctx_r0.formatarData(ind_r6.ultimoVencimento));
  }
}
function RelatoriosComponent_Conditional_13_Conditional_0_Conditional_43_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 23)(1, "div", 24);
    \u0275\u0275text(2);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "div", 42)(4, "table", 43)(5, "thead")(6, "tr")(7, "th");
    \u0275\u0275text(8, "Aluno");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(9, "th", 44);
    \u0275\u0275text(10, "Total devido");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(11, "th", 45);
    \u0275\u0275text(12, "Dias em atraso");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(13, "th");
    \u0275\u0275text(14, "\xDAltimo vencimento");
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(15, "tbody");
    \u0275\u0275repeaterCreate(16, RelatoriosComponent_Conditional_13_Conditional_0_Conditional_43_For_17_Template, 10, 6, "tr", null, _forTrack1);
    \u0275\u0275elementEnd()()()();
  }
  if (rf & 2) {
    const r_r7 = \u0275\u0275nextContext();
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate1("Inadimplentes atuais (", r_r7.inadimplentes.length, ")");
    \u0275\u0275advance(14);
    \u0275\u0275repeater(r_r7.inadimplentes);
  }
}
function RelatoriosComponent_Conditional_13_Conditional_0_Conditional_44_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 50)(1, "div", 51);
    \u0275\u0275text(2, "Nenhum inadimplente no momento");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "div", 52);
    \u0275\u0275text(4, "Todos os alunos est\xE3o em dia.");
    \u0275\u0275elementEnd()();
  }
}
function RelatoriosComponent_Conditional_13_Conditional_0_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 18)(1, "div", 19)(2, "div", 20);
    \u0275\u0275text(3);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(4, "div", 21);
    \u0275\u0275text(5);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(6, "div", 19)(7, "div", 20);
    \u0275\u0275text(8, "Alunos ativos");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(9, "div", 22);
    \u0275\u0275text(10);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(11, "div", 19)(12, "div", 20);
    \u0275\u0275text(13, "Inadimplentes agora");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(14, "div", 22);
    \u0275\u0275text(15);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(16, "div", 19)(17, "div", 20);
    \u0275\u0275text(18, "Total em atraso");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(19, "div", 22);
    \u0275\u0275text(20);
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(21, "div", 23)(22, "div", 24);
    \u0275\u0275text(23);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(24, "div", 25);
    \u0275\u0275repeaterCreate(25, RelatoriosComponent_Conditional_13_Conditional_0_For_26_Template, 9, 5, "div", 26, _forTrack0);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(27, "div", 27);
    \u0275\u0275element(28, "span", 28);
    \u0275\u0275text(29, "Recebido ");
    \u0275\u0275element(30, "span", 29);
    \u0275\u0275text(31, "Pendente ");
    \u0275\u0275element(32, "span", 30);
    \u0275\u0275text(33, "Atrasado ");
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(34, "div", 23)(35, "div", 24);
    \u0275\u0275text(36);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(37, "div", 25);
    \u0275\u0275repeaterCreate(38, RelatoriosComponent_Conditional_13_Conditional_0_For_39_Template, 7, 5, "div", 26, _forTrack0);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(40, "div", 27);
    \u0275\u0275element(41, "span", 31);
    \u0275\u0275text(42, "Total de check-ins ");
    \u0275\u0275elementEnd()();
    \u0275\u0275template(43, RelatoriosComponent_Conditional_13_Conditional_0_Conditional_43_Template, 18, 1, "div", 23)(44, RelatoriosComponent_Conditional_13_Conditional_0_Conditional_44_Template, 5, 0);
  }
  if (rf & 2) {
    const r_r7 = ctx;
    const ctx_r0 = \u0275\u0275nextContext(2);
    \u0275\u0275advance(3);
    \u0275\u0275textInterpolate1("Receita recebida ", ctx_r0.anoSelecionado(), "");
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(ctx_r0.formatarMoeda(r_r7.totalRecebidoAno));
    \u0275\u0275advance(5);
    \u0275\u0275textInterpolate(r_r7.totalAlunosAtivos);
    \u0275\u0275advance(4);
    \u0275\u0275classProp("kpi-red", r_r7.totalInadimplentes > 0);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(r_r7.totalInadimplentes);
    \u0275\u0275advance(4);
    \u0275\u0275classProp("kpi-red", r_r7.inadimplentes.length > 0);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1(" ", ctx_r0.formatarMoeda(ctx_r0.totalDevido()), " ");
    \u0275\u0275advance(3);
    \u0275\u0275textInterpolate1("Receita mensal \u2014 ", ctx_r0.anoSelecionado(), "");
    \u0275\u0275advance(2);
    \u0275\u0275repeater(r_r7.receitaMensal);
    \u0275\u0275advance(11);
    \u0275\u0275textInterpolate1("Presen\xE7as mensais \u2014 ", ctx_r0.anoSelecionado(), "");
    \u0275\u0275advance(2);
    \u0275\u0275repeater(r_r7.frequenciaMensal);
    \u0275\u0275advance(5);
    \u0275\u0275conditional(43, r_r7.inadimplentes.length > 0 ? 43 : 44);
  }
}
function RelatoriosComponent_Conditional_13_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275template(0, RelatoriosComponent_Conditional_13_Conditional_0_Template, 45, 12);
  }
  if (rf & 2) {
    let tmp_1_0;
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275conditional(0, (tmp_1_0 = ctx_r0.relatorio()) ? 0 : -1, tmp_1_0);
  }
}
var MESES = ["Jan", "Fev", "Mar", "Abr", "Mai", "Jun", "Jul", "Ago", "Set", "Out", "Nov", "Dez"];
var RelatoriosComponent = class _RelatoriosComponent {
  constructor() {
    this.financeiroService = inject(FinanceiroService);
    this.anoAtual = (/* @__PURE__ */ new Date()).getFullYear();
    this.anos = Array.from({ length: 5 }, (_, i) => this.anoAtual - i);
    this.meses = MESES;
    this.anoSelecionado = signal(this.anoAtual);
    this.carregando = signal(true);
    this.erro = signal("");
    this.relatorio = signal(null);
    this.maxRecebido = computed(() => {
      const r = this.relatorio();
      if (!r)
        return 1;
      return Math.max(...r.receitaMensal.flatMap((m) => [m.recebido, m.pendente, m.atrasado]), 1);
    });
    this.maxPresencas = computed(() => {
      const r = this.relatorio();
      if (!r)
        return 1;
      return Math.max(...r.frequenciaMensal.map((m) => m.totalPresencas), 1);
    });
    this.totalDevido = computed(() => this.relatorio()?.inadimplentes.reduce((s, i) => s + i.totalDevido, 0) ?? 0);
  }
  ngOnInit() {
    this.carregar();
  }
  carregar() {
    this.carregando.set(true);
    this.erro.set("");
    this.financeiroService.getRelatorioAnual(this.anoSelecionado()).subscribe({
      next: (res) => {
        this.relatorio.set(res.dados ?? null);
        this.carregando.set(false);
      },
      error: () => {
        this.erro.set("Erro ao carregar relat\xF3rio.");
        this.carregando.set(false);
      }
    });
  }
  onAnoChange(ano) {
    this.anoSelecionado.set(Number(ano));
    this.carregar();
  }
  barH(valor, max) {
    return max > 0 ? Math.round(valor / max * 100) : 0;
  }
  formatarMoeda(valor) {
    return valor.toLocaleString("pt-BR", { style: "currency", currency: "BRL" });
  }
  formatarData(d) {
    if (!d)
      return "\u2014";
    const [y, m, day] = d.split("-");
    return `${day}/${m}/${y}`;
  }
  exportarCSV() {
    const r = this.relatorio();
    if (!r)
      return;
    const linhas = [
      ["M\xEAs", "Recebido (R$)", "Pendente (R$)", "Atrasado (R$)", "Presen\xE7as", "Alunos \xFAnicos"]
    ];
    for (let i = 0; i < 12; i++) {
      const rec = r.receitaMensal[i];
      const freq = r.frequenciaMensal[i];
      linhas.push([
        MESES[i],
        rec.recebido.toFixed(2),
        rec.pendente.toFixed(2),
        rec.atrasado.toFixed(2),
        String(freq.totalPresencas),
        String(freq.alunosUnicos)
      ]);
    }
    linhas.push([]);
    linhas.push(["Inadimplentes", "Total devido (R$)", "Dias atraso", "\xDAltimo vencimento"]);
    for (const ind of r.inadimplentes) {
      linhas.push([ind.nomeAluno, ind.totalDevido.toFixed(2), String(ind.diasAtraso), ind.ultimoVencimento ?? ""]);
    }
    const csv = linhas.map((l) => l.map((c) => `"${c}"`).join(",")).join("\n");
    const blob = new Blob(["\uFEFF" + csv], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `relatorio-${r.ano}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  }
  imprimirPDF() {
    window.print();
  }
  static {
    this.\u0275fac = function RelatoriosComponent_Factory(t) {
      return new (t || _RelatoriosComponent)();
    };
  }
  static {
    this.\u0275cmp = /* @__PURE__ */ \u0275\u0275defineComponent({ type: _RelatoriosComponent, selectors: [["app-relatorios"]], standalone: true, features: [\u0275\u0275StandaloneFeature], decls: 14, vars: 5, consts: [[1, "page-container", "rel-page"], [1, "page-header"], [1, "page-title"], [1, "page-subtitle"], [2, "display", "flex", "gap", "8px", "align-items", "center"], [1, "form-input", 2, "max-width", "110px", 3, "ngModelChange", "ngModel"], [3, "value"], [1, "alert-error"], [1, "skeleton-list"], [1, "btn-secondary", "no-print", 3, "click"], ["width", "14", "height", "14", "fill", "none", "stroke", "currentColor", "stroke-width", "2", "viewBox", "0 0 24 24"], ["d", "M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"], ["points", "7 10 12 15 17 10"], ["x1", "12", "y1", "15", "x2", "12", "y2", "3"], ["points", "6 9 6 2 18 2 18 9"], ["d", "M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"], ["x", "6", "y", "14", "width", "12", "height", "8"], [1, "skeleton-row", 2, "height", "80px"], [1, "kpi-row"], [1, "kpi-card"], [1, "kpi-label"], [1, "kpi-value", "kpi-green"], [1, "kpi-value"], [1, "chart-card"], [1, "chart-title"], [1, "bar-chart"], [1, "bar-col"], [1, "chart-legend"], [1, "legend-dot", "legend-green"], [1, "legend-dot", "legend-amber", 2, "margin-left", "16px"], [1, "legend-dot", "legend-red", 2, "margin-left", "16px"], [1, "legend-dot", "legend-indigo"], [1, "bar-wrap"], [1, "bar", "bar-green", 3, "height", "title"], [1, "bar", "bar-amber", 3, "height", "title"], [1, "bar", "bar-red", 3, "height", "title"], [1, "bar-label"], [1, "bar-value"], [1, "bar", "bar-green", 3, "title"], [1, "bar", "bar-amber", 3, "title"], [1, "bar", "bar-red", 3, "title"], [1, "bar", "bar-indigo", 3, "title"], [1, "table-wrapper", 2, "margin-top", "12px"], [1, "data-table"], [2, "text-align", "right"], [2, "text-align", "center"], [1, "font-medium"], [2, "text-align", "right", "color", "#dc2626", "font-weight", "600"], [1, "badge-dias"], [2, "font-size", "13px"], [1, "chart-card", 2, "text-align", "center", "padding", "32px"], [2, "color", "#16a34a", "font-weight", "600", "font-size", "15px"], [2, "color", "var(--app-text-3)", "font-size", "13px", "margin-top", "4px"]], template: function RelatoriosComponent_Template(rf, ctx) {
      if (rf & 1) {
        \u0275\u0275elementStart(0, "div", 0)(1, "div", 1)(2, "div")(3, "h1", 2);
        \u0275\u0275text(4, "Relat\xF3rios");
        \u0275\u0275elementEnd();
        \u0275\u0275template(5, RelatoriosComponent_Conditional_5_Template, 2, 2, "p", 3);
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(6, "div", 4)(7, "select", 5);
        \u0275\u0275listener("ngModelChange", function RelatoriosComponent_Template_select_ngModelChange_7_listener($event) {
          return ctx.onAnoChange($event);
        });
        \u0275\u0275repeaterCreate(8, RelatoriosComponent_For_9_Template, 2, 2, "option", 6, \u0275\u0275repeaterTrackByIdentity);
        \u0275\u0275elementEnd();
        \u0275\u0275template(10, RelatoriosComponent_Conditional_10_Template, 12, 0);
        \u0275\u0275elementEnd()();
        \u0275\u0275template(11, RelatoriosComponent_Conditional_11_Template, 2, 1, "div", 7)(12, RelatoriosComponent_Conditional_12_Template, 3, 1, "div", 8)(13, RelatoriosComponent_Conditional_13_Template, 1, 1);
        \u0275\u0275elementEnd();
      }
      if (rf & 2) {
        \u0275\u0275advance(5);
        \u0275\u0275conditional(5, ctx.relatorio() ? 5 : -1);
        \u0275\u0275advance(2);
        \u0275\u0275property("ngModel", ctx.anoSelecionado());
        \u0275\u0275advance();
        \u0275\u0275repeater(ctx.anos);
        \u0275\u0275advance(2);
        \u0275\u0275conditional(10, ctx.relatorio() ? 10 : -1);
        \u0275\u0275advance();
        \u0275\u0275conditional(11, ctx.erro() ? 11 : -1);
        \u0275\u0275advance();
        \u0275\u0275conditional(12, ctx.carregando() ? 12 : 13);
      }
    }, dependencies: [CommonModule, FormsModule, NgSelectOption, \u0275NgSelectMultipleOption, SelectControlValueAccessor, NgControlStatus, NgModel], styles: [".rel-page[_ngcontent-%COMP%] { }\n\n  \n\n  .kpi-row[_ngcontent-%COMP%] { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; margin-bottom: 20px; }\n  .kpi-card[_ngcontent-%COMP%] { background: var(--app-surface); border: 1px solid var(--app-border); border-radius: 12px; padding: 16px 20px; }\n  .kpi-label[_ngcontent-%COMP%] { font-size: 12px; color: var(--app-text-3); text-transform: uppercase; letter-spacing: 0.04em; font-weight: 600; margin-bottom: 6px; }\n  .kpi-value[_ngcontent-%COMP%] { font-size: 22px; font-weight: 700; color: var(--app-text-1); }\n  .kpi-green[_ngcontent-%COMP%] { color: #16a34a; }\n  .kpi-red[_ngcontent-%COMP%] { color: #dc2626; }\n\n  \n\n  .chart-card[_ngcontent-%COMP%] { background: var(--app-surface); border: 1px solid var(--app-border); border-radius: 12px; padding: 20px; margin-bottom: 16px; }\n  .chart-title[_ngcontent-%COMP%] { font-size: 13px; font-weight: 600; color: var(--app-text-2); text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 16px; }\n\n  \n\n  .bar-chart[_ngcontent-%COMP%] { display: flex; align-items: flex-end; gap: 6px; height: 160px; padding-bottom: 28px; position: relative; overflow: hidden; }\n  .bar-col[_ngcontent-%COMP%] { flex: 1; display: flex; flex-direction: column; align-items: center; gap: 4px; height: 100%; justify-content: flex-end; min-width: 0; }\n  .bar-wrap[_ngcontent-%COMP%] { width: 100%; display: flex; align-items: flex-end; justify-content: center; gap: 2px; flex: 1; min-height: 0; overflow: hidden; }\n  .bar[_ngcontent-%COMP%] { width: 100%; max-width: 28px; border-radius: 4px 4px 0 0; transition: height 0.3s ease; min-height: 2px; }\n  .bar-green[_ngcontent-%COMP%] { background: #22c55e; }\n  .bar-amber[_ngcontent-%COMP%] { background: #f59e0b; }\n  .bar-red[_ngcontent-%COMP%] { background: #ef4444; }\n  .bar-indigo[_ngcontent-%COMP%] { background: #6366f1; }\n  .bar-label[_ngcontent-%COMP%] { font-size: 11px; color: var(--app-text-3); white-space: nowrap; }\n  .bar-value[_ngcontent-%COMP%] { font-size: 10px; color: var(--app-text-3); white-space: nowrap; text-align: center; }\n\n  \n\n  .chart-legend[_ngcontent-%COMP%] { display: flex; align-items: center; gap: 6px; font-size: 12px; color: var(--app-text-2); margin-top: 8px; }\n  .legend-dot[_ngcontent-%COMP%] { width: 10px; height: 10px; border-radius: 2px; display: inline-block; flex-shrink: 0; }\n  .legend-green[_ngcontent-%COMP%] { background: #22c55e; }\n  .legend-amber[_ngcontent-%COMP%] { background: #f59e0b; }\n  .legend-red[_ngcontent-%COMP%] { background: #ef4444; }\n  .legend-indigo[_ngcontent-%COMP%] { background: #6366f1; }\n\n  \n\n  .badge-dias[_ngcontent-%COMP%] { font-size: 11px; font-weight: 600; padding: 2px 8px; border-radius: 99px; background: rgba(239,68,68,0.1); color: #dc2626; }\n  .badge-dias-critico[_ngcontent-%COMP%] { background: rgba(239,68,68,0.2); color: #b91c1c; }\n\n  \n\n  @media print {\n    .no-print[_ngcontent-%COMP%] { display: none !important; }\n    .page-container[_ngcontent-%COMP%] { padding: 0 !important; }\n    .chart-card[_ngcontent-%COMP%], .kpi-card[_ngcontent-%COMP%] { break-inside: avoid; }\n    .kpi-row[_ngcontent-%COMP%] { grid-template-columns: repeat(4, 1fr); }\n  }\n\n  @media (max-width: 768px) {\n    .kpi-row[_ngcontent-%COMP%] { grid-template-columns: repeat(2, 1fr); }\n    .bar-value[_ngcontent-%COMP%] { display: none; }\n  }"] });
  }
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && \u0275setClassDebugInfo(RelatoriosComponent, { className: "RelatoriosComponent" });
})();
export {
  RelatoriosComponent
};
//# sourceMappingURL=chunk-C5ZKLE4N.js.map
