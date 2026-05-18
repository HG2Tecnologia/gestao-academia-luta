import {
  FinanceiroService
} from "./chunk-KMLMG5SQ.js";
import {
  FormsModule,
  NgSelectOption,
  ɵNgSelectMultipleOption
} from "./chunk-JQJL26HT.js";
import {
  AlunoService
} from "./chunk-ZSIQJU4D.js";
import "./chunk-Z5CKO2JM.js";
import {
  CommonModule,
  NgClass,
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
  ɵɵrepeater,
  ɵɵrepeaterCreate,
  ɵɵresetView,
  ɵɵrestoreView,
  ɵɵstyleProp,
  ɵɵtemplate,
  ɵɵtext,
  ɵɵtextInterpolate,
  ɵɵtextInterpolate1
} from "./chunk-WZ2AWGAJ.js";
import {
  __spreadProps,
  __spreadValues
} from "./chunk-7G5TR5RR.js";

// src/app/core/models/financeiro.model.ts
var TipoPagamento = {
  1: "Mensalidade",
  2: "Taxa de Matr\xEDcula",
  3: "Di\xE1ria",
  4: "Produto",
  5: "Gradua\xE7\xE3o",
  6: "Outros"
};
var StatusPagamento = {
  1: "Pago",
  2: "Pendente",
  3: "Atrasado",
  4: "Cancelado"
};

// src/app/features/financeiro/pages/overview/financeiro-overview.component.ts
var _forTrack0 = ($index, $item) => $item.valor;
var _forTrack1 = ($index, $item) => $item.id;
var _forTrack2 = ($index, $item) => $item.alunoId;
function FinanceiroOverviewComponent_Conditional_26_Template(rf, ctx) {
  if (rf & 1) {
    const _r1 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "button", 23);
    \u0275\u0275listener("click", function FinanceiroOverviewComponent_Conditional_26_Template_button_click_0_listener() {
      \u0275\u0275restoreView(_r1);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.irMesAtual());
    });
    \u0275\u0275text(1, "M\xEAs atual");
    \u0275\u0275elementEnd();
  }
}
function FinanceiroOverviewComponent_Conditional_27_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 19)(1, "div", 24)(2, "span", 25);
    \u0275\u0275text(3, "Recebido no m\xEAs");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(4, "span", 26);
    \u0275\u0275text(5);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(6, "div", 27)(7, "span", 25);
    \u0275\u0275text(8, "Pendente no m\xEAs");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(9, "span", 26);
    \u0275\u0275text(10);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(11, "div", 28)(12, "span", 25);
    \u0275\u0275text(13, "Em atraso");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(14, "span", 26);
    \u0275\u0275text(15);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(16, "div", 29)(17, "span", 25);
    \u0275\u0275text(18, "Inadimplentes");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(19, "span", 26);
    \u0275\u0275text(20);
    \u0275\u0275elementStart(21, "small");
    \u0275\u0275text(22);
    \u0275\u0275elementEnd()()()();
  }
  if (rf & 2) {
    const r_r3 = ctx;
    const ctx_r1 = \u0275\u0275nextContext();
    \u0275\u0275advance(5);
    \u0275\u0275textInterpolate(ctx_r1.formatarMoeda(r_r3.totalRecebidoMes));
    \u0275\u0275advance(5);
    \u0275\u0275textInterpolate(ctx_r1.formatarMoeda(r_r3.totalPendenteMes));
    \u0275\u0275advance(5);
    \u0275\u0275textInterpolate(ctx_r1.formatarMoeda(r_r3.totalAtrasado));
    \u0275\u0275advance(5);
    \u0275\u0275textInterpolate1("", r_r3.alunosInadimplentes, " ");
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate1("de ", r_r3.totalAlunos, "");
  }
}
function FinanceiroOverviewComponent_Conditional_33_For_5_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "option", 33);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const s_r5 = ctx.$implicit;
    \u0275\u0275property("value", s_r5.label);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(s_r5.label);
  }
}
function FinanceiroOverviewComponent_Conditional_33_Conditional_7_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 34);
    \u0275\u0275text(1, "Carregando...");
    \u0275\u0275elementEnd();
  }
}
function FinanceiroOverviewComponent_Conditional_33_Conditional_8_For_23_Conditional_17_Template(rf, ctx) {
  if (rf & 1) {
    const _r7 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "button", 44);
    \u0275\u0275listener("click", function FinanceiroOverviewComponent_Conditional_33_Conditional_8_For_23_Conditional_17_Template_button_click_0_listener($event) {
      \u0275\u0275restoreView(_r7);
      const p_r8 = \u0275\u0275nextContext().$implicit;
      const ctx_r1 = \u0275\u0275nextContext(3);
      ctx_r1.abrirWhatsApp(p_r8);
      return \u0275\u0275resetView($event.stopPropagation());
    });
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(1, "svg", 45);
    \u0275\u0275element(2, "path", 7);
    \u0275\u0275elementEnd()();
  }
}
function FinanceiroOverviewComponent_Conditional_33_Conditional_8_For_23_Conditional_18_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 46);
    \u0275\u0275text(1, "\u2014");
    \u0275\u0275elementEnd();
  }
}
function FinanceiroOverviewComponent_Conditional_33_Conditional_8_For_23_Conditional_22_Conditional_2_Template(rf, ctx) {
  if (rf & 1) {
    const _r10 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "button", 55);
    \u0275\u0275listener("click", function FinanceiroOverviewComponent_Conditional_33_Conditional_8_For_23_Conditional_22_Conditional_2_Template_button_click_0_listener($event) {
      \u0275\u0275restoreView(_r10);
      const p_r8 = \u0275\u0275nextContext(2).$implicit;
      const ctx_r1 = \u0275\u0275nextContext(3);
      ctx_r1.marcarComoPago(p_r8);
      return \u0275\u0275resetView($event.stopPropagation());
    });
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(1, "svg", 50);
    \u0275\u0275element(2, "polyline", 56);
    \u0275\u0275elementEnd();
    \u0275\u0275text(3, " Marcar como pago ");
    \u0275\u0275elementEnd();
    \u0275\u0275namespaceHTML();
    \u0275\u0275element(4, "div", 57);
  }
}
function FinanceiroOverviewComponent_Conditional_33_Conditional_8_For_23_Conditional_22_Conditional_3_Template(rf, ctx) {
  if (rf & 1) {
    const _r11 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "button", 58);
    \u0275\u0275listener("click", function FinanceiroOverviewComponent_Conditional_33_Conditional_8_For_23_Conditional_22_Conditional_3_Template_button_click_0_listener($event) {
      \u0275\u0275restoreView(_r11);
      const p_r8 = \u0275\u0275nextContext(2).$implicit;
      const ctx_r1 = \u0275\u0275nextContext(3);
      ctx_r1.abrirWhatsApp(p_r8);
      return \u0275\u0275resetView($event.stopPropagation());
    });
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(1, "svg", 59);
    \u0275\u0275element(2, "path", 7);
    \u0275\u0275elementEnd();
    \u0275\u0275text(3, " Enviar cobran\xE7a (WhatsApp) ");
    \u0275\u0275elementEnd();
    \u0275\u0275namespaceHTML();
    \u0275\u0275element(4, "div", 57);
  }
}
function FinanceiroOverviewComponent_Conditional_33_Conditional_8_For_23_Conditional_22_Template(rf, ctx) {
  if (rf & 1) {
    const _r9 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 47);
    \u0275\u0275listener("click", function FinanceiroOverviewComponent_Conditional_33_Conditional_8_For_23_Conditional_22_Template_div_click_0_listener() {
      \u0275\u0275restoreView(_r9);
      const ctx_r1 = \u0275\u0275nextContext(4);
      return \u0275\u0275resetView(ctx_r1.fecharDropdownAcao());
    });
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(1, "div", 48);
    \u0275\u0275template(2, FinanceiroOverviewComponent_Conditional_33_Conditional_8_For_23_Conditional_22_Conditional_2_Template, 5, 0)(3, FinanceiroOverviewComponent_Conditional_33_Conditional_8_For_23_Conditional_22_Conditional_3_Template, 5, 0);
    \u0275\u0275elementStart(4, "button", 49);
    \u0275\u0275listener("click", function FinanceiroOverviewComponent_Conditional_33_Conditional_8_For_23_Conditional_22_Template_button_click_4_listener($event) {
      \u0275\u0275restoreView(_r9);
      const p_r8 = \u0275\u0275nextContext().$implicit;
      const ctx_r1 = \u0275\u0275nextContext(3);
      ctx_r1.confirmarExcluir(p_r8);
      return \u0275\u0275resetView($event.stopPropagation());
    });
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(5, "svg", 50);
    \u0275\u0275element(6, "polyline", 51)(7, "path", 52)(8, "path", 53)(9, "path", 54);
    \u0275\u0275elementEnd();
    \u0275\u0275text(10, " Excluir ");
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const p_r8 = \u0275\u0275nextContext().$implicit;
    const ctx_r1 = \u0275\u0275nextContext(3);
    \u0275\u0275advance();
    \u0275\u0275styleProp("top", ctx_r1.dropdownPos().top, "px")("right", ctx_r1.dropdownPos().right, "px");
    \u0275\u0275advance();
    \u0275\u0275conditional(2, p_r8.status === "Pendente" || p_r8.status === "Atrasado" ? 2 : -1);
    \u0275\u0275advance();
    \u0275\u0275conditional(3, p_r8.telefoneAluno && p_r8.status !== "Pago" ? 3 : -1);
  }
}
function FinanceiroOverviewComponent_Conditional_33_Conditional_8_For_23_Template(rf, ctx) {
  if (rf & 1) {
    const _r6 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "tr")(1, "td", 37);
    \u0275\u0275text(2);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "td");
    \u0275\u0275text(4);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(5, "td", 38);
    \u0275\u0275text(6);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(7, "td", 39);
    \u0275\u0275text(8);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(9, "td");
    \u0275\u0275text(10);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(11, "td");
    \u0275\u0275text(12);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(13, "td")(14, "span", 40);
    \u0275\u0275text(15);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(16, "td", 41);
    \u0275\u0275template(17, FinanceiroOverviewComponent_Conditional_33_Conditional_8_For_23_Conditional_17_Template, 3, 0, "button", 42)(18, FinanceiroOverviewComponent_Conditional_33_Conditional_8_For_23_Conditional_18_Template, 2, 0);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(19, "td", 41)(20, "button", 43);
    \u0275\u0275listener("click", function FinanceiroOverviewComponent_Conditional_33_Conditional_8_For_23_Template_button_click_20_listener($event) {
      const p_r8 = \u0275\u0275restoreView(_r6).$implicit;
      const ctx_r1 = \u0275\u0275nextContext(3);
      return \u0275\u0275resetView(ctx_r1.toggleDropdownAcao(p_r8.id, $event));
    });
    \u0275\u0275text(21, "\u22EF");
    \u0275\u0275elementEnd();
    \u0275\u0275template(22, FinanceiroOverviewComponent_Conditional_33_Conditional_8_For_23_Conditional_22_Template, 11, 6);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const p_r8 = ctx.$implicit;
    const ctx_r1 = \u0275\u0275nextContext(3);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(p_r8.nomeAluno);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(p_r8.tipo);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(p_r8.descricao || "\u2014");
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(ctx_r1.formatarMoeda(p_r8.valor));
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(ctx_r1.formatarData(p_r8.dataVencimento));
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(ctx_r1.formatarData(p_r8.dataPagamento));
    \u0275\u0275advance(2);
    \u0275\u0275property("ngClass", ctx_r1.badgeStatus(p_r8.status));
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(p_r8.status);
    \u0275\u0275advance(2);
    \u0275\u0275conditional(17, p_r8.telefoneAluno && p_r8.status !== "Pago" ? 17 : 18);
    \u0275\u0275advance(5);
    \u0275\u0275conditional(22, ctx_r1.dropdownAcaoId() === p_r8.id ? 22 : -1);
  }
}
function FinanceiroOverviewComponent_Conditional_33_Conditional_8_ForEmpty_24_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "tr")(1, "td", 60);
    \u0275\u0275text(2);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(3);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate1("Nenhum pagamento para ", ctx_r1.nomeMes(), ".");
  }
}
function FinanceiroOverviewComponent_Conditional_33_Conditional_8_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "table", 35)(1, "thead")(2, "tr")(3, "th");
    \u0275\u0275text(4, "Aluno");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(5, "th");
    \u0275\u0275text(6, "Tipo");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(7, "th");
    \u0275\u0275text(8, "Descri\xE7\xE3o");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(9, "th");
    \u0275\u0275text(10, "Valor");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(11, "th");
    \u0275\u0275text(12, "Vencimento");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(13, "th");
    \u0275\u0275text(14, "Pagamento");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(15, "th");
    \u0275\u0275text(16, "Status");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(17, "th", 36);
    \u0275\u0275text(18, "WhatsApp");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(19, "th", 36);
    \u0275\u0275text(20, "A\xE7\xF5es");
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(21, "tbody");
    \u0275\u0275repeaterCreate(22, FinanceiroOverviewComponent_Conditional_33_Conditional_8_For_23_Template, 23, 10, "tr", null, _forTrack1, false, FinanceiroOverviewComponent_Conditional_33_Conditional_8_ForEmpty_24_Template, 3, 1, "tr");
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(2);
    \u0275\u0275advance(22);
    \u0275\u0275repeater(ctx_r1.pagamentosFiltrados);
  }
}
function FinanceiroOverviewComponent_Conditional_33_Template(rf, ctx) {
  if (rf & 1) {
    const _r4 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 30)(1, "select", 31);
    \u0275\u0275listener("change", function FinanceiroOverviewComponent_Conditional_33_Template_select_change_1_listener($event) {
      \u0275\u0275restoreView(_r4);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.filtroStatus.set($event.target.value));
    });
    \u0275\u0275elementStart(2, "option", 32);
    \u0275\u0275text(3, "Todos os status");
    \u0275\u0275elementEnd();
    \u0275\u0275repeaterCreate(4, FinanceiroOverviewComponent_Conditional_33_For_5_Template, 2, 2, "option", 33, _forTrack0);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(6, "div", 22);
    \u0275\u0275template(7, FinanceiroOverviewComponent_Conditional_33_Conditional_7_Template, 2, 0, "div", 34)(8, FinanceiroOverviewComponent_Conditional_33_Conditional_8_Template, 25, 1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext();
    \u0275\u0275advance();
    \u0275\u0275property("value", ctx_r1.filtroStatus());
    \u0275\u0275advance(3);
    \u0275\u0275repeater(ctx_r1.statusPagamento);
    \u0275\u0275advance(3);
    \u0275\u0275conditional(7, ctx_r1.carregando() ? 7 : 8);
  }
}
function FinanceiroOverviewComponent_Conditional_34_For_14_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "tr")(1, "td");
    \u0275\u0275text(2);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "td", 61);
    \u0275\u0275text(4);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(5, "td")(6, "span", 62);
    \u0275\u0275text(7);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(8, "td");
    \u0275\u0275text(9);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const i_r12 = ctx.$implicit;
    const ctx_r1 = \u0275\u0275nextContext(2);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(i_r12.nomeAluno);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(ctx_r1.formatarMoeda(i_r12.totalDevido));
    \u0275\u0275advance(3);
    \u0275\u0275textInterpolate1("", i_r12.diasAtraso, "d");
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(ctx_r1.formatarData(i_r12.ultimoVencimento));
  }
}
function FinanceiroOverviewComponent_Conditional_34_ForEmpty_15_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "tr")(1, "td", 63);
    \u0275\u0275text(2, "Nenhum inadimplente. Parab\xE9ns!");
    \u0275\u0275elementEnd()();
  }
}
function FinanceiroOverviewComponent_Conditional_34_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 22)(1, "table", 35)(2, "thead")(3, "tr")(4, "th");
    \u0275\u0275text(5, "Aluno");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(6, "th");
    \u0275\u0275text(7, "Total Devido");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(8, "th");
    \u0275\u0275text(9, "Dias em Atraso");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(10, "th");
    \u0275\u0275text(11, "\xDAltimo Vencimento");
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(12, "tbody");
    \u0275\u0275repeaterCreate(13, FinanceiroOverviewComponent_Conditional_34_For_14_Template, 10, 4, "tr", null, _forTrack2, false, FinanceiroOverviewComponent_Conditional_34_ForEmpty_15_Template, 3, 0, "tr");
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext();
    \u0275\u0275advance(13);
    \u0275\u0275repeater(ctx_r1.inadimplentes);
  }
}
function FinanceiroOverviewComponent_Conditional_35_Conditional_15_For_2_Template(rf, ctx) {
  if (rf & 1) {
    const _r14 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 91);
    \u0275\u0275listener("click", function FinanceiroOverviewComponent_Conditional_35_Conditional_15_For_2_Template_div_click_0_listener() {
      const a_r15 = \u0275\u0275restoreView(_r14).$implicit;
      const ctx_r1 = \u0275\u0275nextContext(3);
      return \u0275\u0275resetView(ctx_r1.selecionarAluno(a_r15));
    });
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const a_r15 = ctx.$implicit;
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(a_r15.nome);
  }
}
function FinanceiroOverviewComponent_Conditional_35_Conditional_15_ForEmpty_3_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 90);
    \u0275\u0275text(1, "Nenhum aluno encontrado");
    \u0275\u0275elementEnd();
  }
}
function FinanceiroOverviewComponent_Conditional_35_Conditional_15_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 77);
    \u0275\u0275repeaterCreate(1, FinanceiroOverviewComponent_Conditional_35_Conditional_15_For_2_Template, 2, 1, "div", 89, _forTrack1, false, FinanceiroOverviewComponent_Conditional_35_Conditional_15_ForEmpty_3_Template, 2, 0, "div", 90);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(2);
    \u0275\u0275advance();
    \u0275\u0275repeater(ctx_r1.alunosFiltradosDropdown());
  }
}
function FinanceiroOverviewComponent_Conditional_35_For_22_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "option", 33);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const t_r16 = ctx.$implicit;
    \u0275\u0275property("value", t_r16.valor);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(t_r16.label);
  }
}
function FinanceiroOverviewComponent_Conditional_35_For_28_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "option", 33);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const s_r17 = ctx.$implicit;
    \u0275\u0275property("value", s_r17.valor);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(s_r17.label);
  }
}
function FinanceiroOverviewComponent_Conditional_35_Conditional_55_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "p", 85);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(2);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(ctx_r1.erroSalvar());
  }
}
function FinanceiroOverviewComponent_Conditional_35_Template(rf, ctx) {
  if (rf & 1) {
    const _r13 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 64);
    \u0275\u0275listener("click", function FinanceiroOverviewComponent_Conditional_35_Template_div_click_0_listener() {
      \u0275\u0275restoreView(_r13);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.modalNovoPagamento.set(false));
    });
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(1, "div", 65)(2, "div", 66)(3, "h2", 67);
    \u0275\u0275text(4, "Novo Pagamento");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(5, "button", 68);
    \u0275\u0275listener("click", function FinanceiroOverviewComponent_Conditional_35_Template_button_click_5_listener() {
      \u0275\u0275restoreView(_r13);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.modalNovoPagamento.set(false));
    });
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(6, "svg", 69);
    \u0275\u0275element(7, "line", 70)(8, "line", 71);
    \u0275\u0275elementEnd()()();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(9, "div", 72)(10, "div", 73)(11, "label", 74);
    \u0275\u0275text(12, "Aluno *");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(13, "div", 75)(14, "input", 76);
    \u0275\u0275listener("focus", function FinanceiroOverviewComponent_Conditional_35_Template_input_focus_14_listener() {
      \u0275\u0275restoreView(_r13);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.dropdownAluno.set(true));
    })("input", function FinanceiroOverviewComponent_Conditional_35_Template_input_input_14_listener($event) {
      \u0275\u0275restoreView(_r13);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.filtroDropdownAluno.set($event.target.value));
    });
    \u0275\u0275elementEnd();
    \u0275\u0275template(15, FinanceiroOverviewComponent_Conditional_35_Conditional_15_Template, 4, 1, "div", 77);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(16, "div", 78)(17, "div", 73)(18, "label", 74);
    \u0275\u0275text(19, "Tipo *");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(20, "select", 79);
    \u0275\u0275listener("change", function FinanceiroOverviewComponent_Conditional_35_Template_select_change_20_listener($event) {
      \u0275\u0275restoreView(_r13);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.updateForm("tipo", +$event.target.value));
    });
    \u0275\u0275repeaterCreate(21, FinanceiroOverviewComponent_Conditional_35_For_22_Template, 2, 2, "option", 33, _forTrack0);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(23, "div", 73)(24, "label", 74);
    \u0275\u0275text(25, "Status *");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(26, "select", 79);
    \u0275\u0275listener("change", function FinanceiroOverviewComponent_Conditional_35_Template_select_change_26_listener($event) {
      \u0275\u0275restoreView(_r13);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.updateForm("status", +$event.target.value));
    });
    \u0275\u0275repeaterCreate(27, FinanceiroOverviewComponent_Conditional_35_For_28_Template, 2, 2, "option", 33, _forTrack0);
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(29, "div", 78)(30, "div", 73)(31, "label", 74);
    \u0275\u0275text(32, "Valor (R$) *");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(33, "input", 80);
    \u0275\u0275listener("input", function FinanceiroOverviewComponent_Conditional_35_Template_input_input_33_listener($event) {
      \u0275\u0275restoreView(_r13);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.updateForm("valor", +$event.target.value));
    });
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(34, "div", 73)(35, "label", 74);
    \u0275\u0275text(36, "Forma de Pagamento");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(37, "input", 81);
    \u0275\u0275listener("input", function FinanceiroOverviewComponent_Conditional_35_Template_input_input_37_listener($event) {
      \u0275\u0275restoreView(_r13);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.updateForm("formaPagamento", $event.target.value));
    });
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(38, "div", 78)(39, "div", 73)(40, "label", 74);
    \u0275\u0275text(41, "Vencimento");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(42, "input", 82);
    \u0275\u0275listener("input", function FinanceiroOverviewComponent_Conditional_35_Template_input_input_42_listener($event) {
      \u0275\u0275restoreView(_r13);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.updateForm("dataVencimento", $event.target.value));
    });
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(43, "div", 73)(44, "label", 74);
    \u0275\u0275text(45, "Data de Pagamento");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(46, "input", 82);
    \u0275\u0275listener("input", function FinanceiroOverviewComponent_Conditional_35_Template_input_input_46_listener($event) {
      \u0275\u0275restoreView(_r13);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.updateForm("dataPagamento", $event.target.value));
    });
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(47, "div", 73)(48, "label", 74);
    \u0275\u0275text(49, "Descri\xE7\xE3o");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(50, "input", 83);
    \u0275\u0275listener("input", function FinanceiroOverviewComponent_Conditional_35_Template_input_input_50_listener($event) {
      \u0275\u0275restoreView(_r13);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.updateForm("descricao", $event.target.value));
    });
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(51, "div", 73)(52, "label", 74);
    \u0275\u0275text(53, "Observa\xE7\xF5es");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(54, "textarea", 84);
    \u0275\u0275listener("input", function FinanceiroOverviewComponent_Conditional_35_Template_textarea_input_54_listener($event) {
      \u0275\u0275restoreView(_r13);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.updateForm("observacoes", $event.target.value));
    });
    \u0275\u0275elementEnd()();
    \u0275\u0275template(55, FinanceiroOverviewComponent_Conditional_35_Conditional_55_Template, 2, 1, "p", 85);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(56, "div", 86)(57, "button", 87);
    \u0275\u0275listener("click", function FinanceiroOverviewComponent_Conditional_35_Template_button_click_57_listener() {
      \u0275\u0275restoreView(_r13);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.modalNovoPagamento.set(false));
    });
    \u0275\u0275text(58, "Cancelar");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(59, "button", 88);
    \u0275\u0275listener("click", function FinanceiroOverviewComponent_Conditional_35_Template_button_click_59_listener() {
      \u0275\u0275restoreView(_r13);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.salvarPagamento());
    });
    \u0275\u0275text(60);
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    let tmp_9_0;
    let tmp_10_0;
    let tmp_11_0;
    let tmp_12_0;
    let tmp_13_0;
    const ctx_r1 = \u0275\u0275nextContext();
    \u0275\u0275advance(14);
    \u0275\u0275property("placeholder", ctx_r1.alunoSelecionadoNome() || "Pesquisar aluno...")("value", ctx_r1.filtroDropdownAluno());
    \u0275\u0275advance();
    \u0275\u0275conditional(15, ctx_r1.dropdownAluno() ? 15 : -1);
    \u0275\u0275advance(5);
    \u0275\u0275property("value", ctx_r1.novoForm().tipo);
    \u0275\u0275advance();
    \u0275\u0275repeater(ctx_r1.tiposPagamento);
    \u0275\u0275advance(5);
    \u0275\u0275property("value", ctx_r1.novoForm().status);
    \u0275\u0275advance();
    \u0275\u0275repeater(ctx_r1.statusPagamento);
    \u0275\u0275advance(6);
    \u0275\u0275property("value", ctx_r1.novoForm().valor);
    \u0275\u0275advance(4);
    \u0275\u0275property("value", (tmp_9_0 = ctx_r1.novoForm().formaPagamento) !== null && tmp_9_0 !== void 0 ? tmp_9_0 : "");
    \u0275\u0275advance(5);
    \u0275\u0275property("value", (tmp_10_0 = ctx_r1.novoForm().dataVencimento) !== null && tmp_10_0 !== void 0 ? tmp_10_0 : "");
    \u0275\u0275advance(4);
    \u0275\u0275property("value", (tmp_11_0 = ctx_r1.novoForm().dataPagamento) !== null && tmp_11_0 !== void 0 ? tmp_11_0 : "");
    \u0275\u0275advance(4);
    \u0275\u0275property("value", (tmp_12_0 = ctx_r1.novoForm().descricao) !== null && tmp_12_0 !== void 0 ? tmp_12_0 : "");
    \u0275\u0275advance(4);
    \u0275\u0275property("value", (tmp_13_0 = ctx_r1.novoForm().observacoes) !== null && tmp_13_0 !== void 0 ? tmp_13_0 : "");
    \u0275\u0275advance();
    \u0275\u0275conditional(55, ctx_r1.erroSalvar() ? 55 : -1);
    \u0275\u0275advance(4);
    \u0275\u0275property("disabled", ctx_r1.salvando());
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1(" ", ctx_r1.salvando() ? "Salvando..." : "Salvar", " ");
  }
}
function FinanceiroOverviewComponent_Conditional_36_Template(rf, ctx) {
  if (rf & 1) {
    const _r18 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 64);
    \u0275\u0275listener("click", function FinanceiroOverviewComponent_Conditional_36_Template_div_click_0_listener() {
      \u0275\u0275restoreView(_r18);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.modalExcluir.set(false));
    });
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(1, "div", 92)(2, "div", 66)(3, "h2", 67);
    \u0275\u0275text(4, "Confirmar exclus\xE3o");
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(5, "div", 72)(6, "p");
    \u0275\u0275text(7, "Deseja excluir o pagamento de ");
    \u0275\u0275elementStart(8, "strong");
    \u0275\u0275text(9);
    \u0275\u0275elementEnd();
    \u0275\u0275text(10, " no valor de ");
    \u0275\u0275elementStart(11, "strong");
    \u0275\u0275text(12);
    \u0275\u0275elementEnd();
    \u0275\u0275text(13, "?");
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(14, "div", 86)(15, "button", 87);
    \u0275\u0275listener("click", function FinanceiroOverviewComponent_Conditional_36_Template_button_click_15_listener() {
      \u0275\u0275restoreView(_r18);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.modalExcluir.set(false));
    });
    \u0275\u0275text(16, "Cancelar");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(17, "button", 93);
    \u0275\u0275listener("click", function FinanceiroOverviewComponent_Conditional_36_Template_button_click_17_listener() {
      \u0275\u0275restoreView(_r18);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.executarExcluir());
    });
    \u0275\u0275text(18);
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    let tmp_1_0;
    let tmp_2_0;
    const ctx_r1 = \u0275\u0275nextContext();
    \u0275\u0275advance(9);
    \u0275\u0275textInterpolate((tmp_1_0 = ctx_r1.pagamentoParaExcluir()) == null ? null : tmp_1_0.nomeAluno);
    \u0275\u0275advance(3);
    \u0275\u0275textInterpolate(ctx_r1.formatarMoeda((tmp_2_0 = (tmp_2_0 = ctx_r1.pagamentoParaExcluir()) == null ? null : tmp_2_0.valor) !== null && tmp_2_0 !== void 0 ? tmp_2_0 : 0));
    \u0275\u0275advance(5);
    \u0275\u0275property("disabled", ctx_r1.excluindo());
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1(" ", ctx_r1.excluindo() ? "Excluindo..." : "Excluir", " ");
  }
}
function FinanceiroOverviewComponent_Conditional_37_Template(rf, ctx) {
  if (rf & 1) {
    const _r19 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 64);
    \u0275\u0275listener("click", function FinanceiroOverviewComponent_Conditional_37_Template_div_click_0_listener() {
      \u0275\u0275restoreView(_r19);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.modalMsgTemplate.set(false));
    });
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(1, "div", 65)(2, "div", 66)(3, "h2", 67);
    \u0275\u0275text(4, "Mensagem de cobran\xE7a (WhatsApp)");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(5, "button", 68);
    \u0275\u0275listener("click", function FinanceiroOverviewComponent_Conditional_37_Template_button_click_5_listener() {
      \u0275\u0275restoreView(_r19);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.modalMsgTemplate.set(false));
    });
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(6, "svg", 69);
    \u0275\u0275element(7, "line", 70)(8, "line", 71);
    \u0275\u0275elementEnd()()();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(9, "div", 72)(10, "p", 94);
    \u0275\u0275text(11, "Use as vari\xE1veis abaixo para personalizar a mensagem:");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(12, "div", 95)(13, "span", 96)(14, "code");
    \u0275\u0275text(15, "{nome}");
    \u0275\u0275elementEnd();
    \u0275\u0275text(16, " Primeiro nome do aluno");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(17, "span", 96)(18, "code");
    \u0275\u0275text(19, "{valor}");
    \u0275\u0275elementEnd();
    \u0275\u0275text(20, " Valor do pagamento");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(21, "span", 96)(22, "code");
    \u0275\u0275text(23, "{vencimento}");
    \u0275\u0275elementEnd();
    \u0275\u0275text(24, " Data de vencimento");
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(25, "div", 97)(26, "label", 74);
    \u0275\u0275text(27, "Mensagem");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(28, "textarea", 98);
    \u0275\u0275listener("input", function FinanceiroOverviewComponent_Conditional_37_Template_textarea_input_28_listener($event) {
      \u0275\u0275restoreView(_r19);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.msgTemplateEditando.set($event.target.value));
    });
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(29, "div", 99)(30, "p", 100);
    \u0275\u0275text(31, "Pr\xE9-visualiza\xE7\xE3o");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(32, "p", 101);
    \u0275\u0275text(33);
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(34, "div", 86)(35, "button", 87);
    \u0275\u0275listener("click", function FinanceiroOverviewComponent_Conditional_37_Template_button_click_35_listener() {
      \u0275\u0275restoreView(_r19);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.modalMsgTemplate.set(false));
    });
    \u0275\u0275text(36, "Cancelar");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(37, "button", 8);
    \u0275\u0275listener("click", function FinanceiroOverviewComponent_Conditional_37_Template_button_click_37_listener() {
      \u0275\u0275restoreView(_r19);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.salvarMsgTemplate());
    });
    \u0275\u0275text(38, "Salvar mensagem");
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext();
    \u0275\u0275advance(28);
    \u0275\u0275property("value", ctx_r1.msgTemplateEditando());
    \u0275\u0275advance(5);
    \u0275\u0275textInterpolate(ctx_r1.previewMsg());
  }
}
var MESES = ["Janeiro", "Fevereiro", "Mar\xE7o", "Abril", "Maio", "Junho", "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"];
var FinanceiroOverviewComponent = class _FinanceiroOverviewComponent {
  constructor() {
    this.financeiroService = inject(FinanceiroService);
    this.alunoService = inject(AlunoService);
    this.hoje = /* @__PURE__ */ new Date();
    this.mesAtual = signal(this.hoje.getMonth() + 1);
    this.anoAtual = signal(this.hoje.getFullYear());
    this.nomeMes = computed(() => `${MESES[this.mesAtual() - 1]} ${this.anoAtual()}`);
    this.ehMesAtual = computed(() => this.mesAtual() === this.hoje.getMonth() + 1 && this.anoAtual() === this.hoje.getFullYear());
    this.carregando = signal(true);
    this.resumo = signal(null);
    this.pagamentos = signal([]);
    this.alunos = signal([]);
    this.abaAtiva = signal("pagamentos");
    this.filtroStatus = signal("");
    this.msgTemplate = signal("Ol\xE1 {nome}! Temos um pagamento de {valor} {vencimento} em aberto. Poderia regularizar? Qualquer d\xFAvida estamos \xE0 disposi\xE7\xE3o! \u{1F60A}");
    this.modalMsgTemplate = signal(false);
    this.msgTemplateEditando = signal("");
    this.dropdownAcaoId = signal(null);
    this.dropdownPos = signal({ top: 0, right: 0 });
    this.modalNovoPagamento = signal(false);
    this.salvando = signal(false);
    this.erroSalvar = signal("");
    this.modalExcluir = signal(false);
    this.pagamentoParaExcluir = signal(null);
    this.excluindo = signal(false);
    this.novoForm = signal({
      alunoId: "",
      tipo: 1,
      status: 2,
      valor: 0,
      descricao: "",
      dataVencimento: "",
      dataPagamento: "",
      formaPagamento: "",
      observacoes: ""
    });
    this.tiposPagamento = Object.entries(TipoPagamento).map(([k, v]) => ({ valor: Number(k), label: v }));
    this.statusPagamento = Object.entries(StatusPagamento).map(([k, v]) => ({ valor: Number(k), label: v }));
    this.dropdownAluno = signal(false);
    this.filtroDropdownAluno = signal("");
    this.alunoSelecionadoNome = signal("");
    this.alunosFiltradosDropdown = computed(() => {
      const filtro = this.filtroDropdownAluno().toLowerCase().trim();
      return filtro ? this.alunos().filter((a) => a.nome.toLowerCase().includes(filtro)) : this.alunos();
    });
  }
  ngOnInit() {
    this.carregarTudo();
    this.alunoService.getAll({ pageSize: 500 }).subscribe({
      next: (res) => this.alunos.set(res.dados?.itens ?? [])
    });
  }
  // ── Navegação de mês ──────────────────────────────────────────
  irMesAnterior() {
    if (this.mesAtual() === 1) {
      this.mesAtual.set(12);
      this.anoAtual.update((a) => a - 1);
    } else {
      this.mesAtual.update((m) => m - 1);
    }
    this.carregarTudo();
  }
  irProximoMes() {
    if (this.mesAtual() === 12) {
      this.mesAtual.set(1);
      this.anoAtual.update((a) => a + 1);
    } else {
      this.mesAtual.update((m) => m + 1);
    }
    this.carregarTudo();
  }
  irMesAtual() {
    this.mesAtual.set(this.hoje.getMonth() + 1);
    this.anoAtual.set(this.hoje.getFullYear());
    this.carregarTudo();
  }
  // ── Carregamento ──────────────────────────────────────────────
  carregarTudo() {
    this.carregando.set(true);
    const ano = this.anoAtual();
    const mes = this.mesAtual();
    if (this.ehMesAtual()) {
      this.financeiroService.gerarCobrancasMensais().subscribe({ error: () => {
      } });
    }
    this.financeiroService.getResumo(ano, mes).subscribe({
      next: (res) => {
        this.resumo.set(res.dados ?? null);
        this.carregando.set(false);
      },
      error: () => this.carregando.set(false)
    });
    this.financeiroService.listar({ ano, mes, pageSize: 200 }).subscribe({
      next: (res) => this.pagamentos.set(res.dados ?? [])
    });
  }
  selecionarAba(aba) {
    this.abaAtiva.set(aba);
  }
  // ── Dropdown ações ────────────────────────────────────────────
  toggleDropdownAcao(id, event) {
    event.stopPropagation();
    if (this.dropdownAcaoId() === id) {
      this.dropdownAcaoId.set(null);
      return;
    }
    const rect = event.currentTarget.getBoundingClientRect();
    this.dropdownPos.set({ top: rect.bottom + 4, right: window.innerWidth - rect.right });
    this.dropdownAcaoId.set(id);
  }
  fecharDropdownAcao() {
    this.dropdownAcaoId.set(null);
  }
  // ── WhatsApp ──────────────────────────────────────────────────
  abrirWhatsApp(p) {
    if (!p.telefoneAluno)
      return;
    const tel = p.telefoneAluno.replace(/\D/g, "");
    const nome = p.nomeAluno.split(" ")[0];
    const valor = this.formatarMoeda(p.valor);
    const venc = p.dataVencimento ? `com vencimento em ${this.formatarData(p.dataVencimento)}` : "";
    const msg = this.msgTemplate().replace("{nome}", nome).replace("{valor}", valor).replace("{vencimento}", venc);
    window.open(`https://wa.me/55${tel}?text=${encodeURIComponent(msg)}`, "_blank");
    this.fecharDropdownAcao();
  }
  previewMsg() {
    return this.msgTemplateEditando().replace("{nome}", "Jo\xE3o").replace("{valor}", "R$ 150,00").replace("{vencimento}", "com vencimento em 20/06/2025");
  }
  abrirModalMsgTemplate() {
    this.msgTemplateEditando.set(this.msgTemplate());
    this.modalMsgTemplate.set(true);
  }
  salvarMsgTemplate() {
    this.msgTemplate.set(this.msgTemplateEditando());
    this.modalMsgTemplate.set(false);
  }
  // ── Pagamentos ────────────────────────────────────────────────
  get pagamentosFiltrados() {
    const s = this.filtroStatus();
    return s ? this.pagamentos().filter((p) => p.status === s) : this.pagamentos();
  }
  abrirModalNovoPagamento() {
    this.novoForm.set({ alunoId: "", tipo: 1, status: 2, valor: 0, descricao: "", dataVencimento: "", dataPagamento: "", formaPagamento: "", observacoes: "" });
    this.alunoSelecionadoNome.set("");
    this.filtroDropdownAluno.set("");
    this.erroSalvar.set("");
    this.modalNovoPagamento.set(true);
  }
  selecionarAluno(aluno) {
    this.novoForm.update((f) => __spreadProps(__spreadValues({}, f), { alunoId: aluno.id }));
    this.alunoSelecionadoNome.set(aluno.nome);
    this.dropdownAluno.set(false);
    this.filtroDropdownAluno.set("");
  }
  updateForm(campo, valor) {
    this.novoForm.update((f) => __spreadProps(__spreadValues({}, f), { [campo]: valor }));
  }
  salvarPagamento() {
    const form = this.novoForm();
    if (!form.alunoId) {
      this.erroSalvar.set("Selecione um aluno.");
      return;
    }
    if (!form.valor || form.valor <= 0) {
      this.erroSalvar.set("Informe um valor v\xE1lido.");
      return;
    }
    this.salvando.set(true);
    this.erroSalvar.set("");
    this.financeiroService.criar(form).subscribe({
      next: () => {
        this.modalNovoPagamento.set(false);
        this.salvando.set(false);
        this.carregarTudo();
      },
      error: () => {
        this.erroSalvar.set("Erro ao salvar pagamento.");
        this.salvando.set(false);
      }
    });
  }
  confirmarExcluir(p) {
    this.pagamentoParaExcluir.set(p);
    this.modalExcluir.set(true);
    this.fecharDropdownAcao();
  }
  executarExcluir() {
    const p = this.pagamentoParaExcluir();
    if (!p)
      return;
    this.excluindo.set(true);
    this.financeiroService.deletar(p.id).subscribe({
      next: () => {
        this.modalExcluir.set(false);
        this.excluindo.set(false);
        this.pagamentoParaExcluir.set(null);
        this.carregarTudo();
      },
      error: () => this.excluindo.set(false)
    });
  }
  marcarComoPago(p) {
    const hoje = (/* @__PURE__ */ new Date()).toISOString().split("T")[0];
    this.financeiroService.atualizar(p.id, { status: 1, dataPagamento: hoje }).subscribe({
      next: () => {
        this.fecharDropdownAcao();
        this.carregarTudo();
      }
    });
  }
  // ── Helpers ────────────────────────────────────────────────────
  formatarMoeda(valor) {
    return valor.toLocaleString("pt-BR", { style: "currency", currency: "BRL" });
  }
  formatarData(data) {
    if (!data)
      return "\u2014";
    const [y, m, d] = data.split("-");
    return `${d}/${m}/${y}`;
  }
  badgeStatus(status) {
    const map = {
      Pago: "badge-pago",
      Pendente: "badge-pendente",
      Atrasado: "badge-atrasado",
      Cancelado: "badge-cancelado"
    };
    return map[status] ?? "";
  }
  get inadimplentes() {
    return this.resumo()?.inadimplentes ?? [];
  }
  static {
    this.\u0275fac = function FinanceiroOverviewComponent_Factory(t) {
      return new (t || _FinanceiroOverviewComponent)();
    };
  }
  static {
    this.\u0275cmp = /* @__PURE__ */ \u0275\u0275defineComponent({ type: _FinanceiroOverviewComponent, selectors: [["app-financeiro-overview"]], standalone: true, features: [\u0275\u0275StandaloneFeature], decls: 38, vars: 12, consts: [[1, "financeiro-page", 3, "click"], [1, "page-header"], [1, "page-title"], [1, "page-subtitle"], [2, "display", "flex", "gap", "10px", "align-items", "center"], ["title", "Personalizar mensagem de cobran\xE7a WhatsApp", 1, "btn-ghost-msg", 3, "click"], ["width", "15", "height", "15", "viewBox", "0 0 24 24", "fill", "currentColor"], ["d", "M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"], [1, "btn-primary", 3, "click"], ["width", "16", "height", "16", "viewBox", "0 0 24 24", "fill", "none", "stroke", "currentColor", "stroke-width", "2", "stroke-linecap", "round", "stroke-linejoin", "round"], ["x1", "12", "y1", "5", "x2", "12", "y2", "19"], ["x1", "5", "y1", "12", "x2", "19", "y2", "12"], [1, "mes-nav"], [1, "mes-btn", 3, "click"], ["width", "16", "height", "16", "viewBox", "0 0 24 24", "fill", "none", "stroke", "currentColor", "stroke-width", "2"], ["points", "15 18 9 12 15 6"], [1, "mes-label"], ["points", "9 18 15 12 9 6"], [1, "mes-hoje-btn"], [1, "resumo-grid"], [1, "abas-bar"], [1, "aba-btn", 3, "click"], [1, "tabela-wrap"], [1, "mes-hoje-btn", 3, "click"], [1, "resumo-card", "card-verde"], [1, "resumo-label"], [1, "resumo-valor"], [1, "resumo-card", "card-amarelo"], [1, "resumo-card", "card-vermelho"], [1, "resumo-card", "card-neutro"], [1, "filtros-bar"], [1, "select-filtro", 3, "change", "value"], ["value", ""], [3, "value"], [1, "loading-state"], [1, "tabela"], [2, "width", "44px", "text-align", "center"], [1, "font-medium"], [1, "desc-col"], [1, "valor-col"], [1, "badge", 3, "ngClass"], [2, "text-align", "center"], ["title", "Enviar cobran\xE7a via WhatsApp", 1, "wpp-btn"], ["title", "A\xE7\xF5es", 1, "btn-dots", 3, "click"], ["title", "Enviar cobran\xE7a via WhatsApp", 1, "wpp-btn", 3, "click"], ["width", "17", "height", "17", "viewBox", "0 0 24 24", "fill", "currentColor"], [2, "color", "var(--app-text-3)", "font-size", "12px"], [1, "acao-overlay", 3, "click"], [1, "acao-dropdown", 2, "position", "fixed"], [1, "acao-item", "acao-excluir", 3, "click"], ["width", "14", "height", "14", "viewBox", "0 0 24 24", "fill", "none", "stroke", "currentColor", "stroke-width", "2"], ["points", "3 6 5 6 21 6"], ["d", "M19 6l-1 14H6L5 6"], ["d", "M10 11v6M14 11v6"], ["d", "M9 6V4h6v2"], [1, "acao-item", "acao-pagar", 3, "click"], ["points", "20 6 9 17 4 12"], [1, "acao-separator"], [1, "acao-item", 3, "click"], ["width", "14", "height", "14", "viewBox", "0 0 24 24", "fill", "currentColor"], ["colspan", "9", 1, "empty-row"], [1, "valor-col", "valor-vermelho"], [1, "badge", "badge-atrasado"], ["colspan", "4", 1, "empty-row"], [1, "modal-backdrop", 3, "click"], ["role", "dialog", "aria-modal", "true", 1, "modal"], [1, "modal-header"], [1, "modal-titulo"], [1, "modal-fechar", 3, "click"], ["width", "18", "height", "18", "viewBox", "0 0 24 24", "fill", "none", "stroke", "currentColor", "stroke-width", "2"], ["x1", "18", "y1", "6", "x2", "6", "y2", "18"], ["x1", "6", "y1", "6", "x2", "18", "y2", "18"], [1, "modal-body"], [1, "form-field"], [1, "form-label"], [1, "aluno-picker"], ["type", "text", 1, "form-input", 3, "focus", "input", "placeholder", "value"], [1, "aluno-dropdown"], [1, "form-row"], [1, "form-input", 3, "change", "value"], ["type", "number", "min", "0", "step", "0.01", 1, "form-input", 3, "input", "value"], ["type", "text", "placeholder", "Pix, Cart\xE3o...", 1, "form-input", 3, "input", "value"], ["type", "date", 1, "form-input", 3, "input", "value"], ["type", "text", "placeholder", "Mensalidade maio...", 1, "form-input", 3, "input", "value"], ["rows", "2", 1, "form-input", "form-textarea", 3, "input", "value"], [1, "erro-msg"], [1, "modal-footer"], [1, "btn-ghost", 3, "click"], [1, "btn-primary", 3, "click", "disabled"], [1, "aluno-item"], [1, "aluno-item", "aluno-vazio"], [1, "aluno-item", 3, "click"], ["role", "dialog", 1, "modal", "modal-sm"], [1, "btn-danger", 3, "click", "disabled"], [1, "form-hint", 2, "margin-bottom", "12px"], [1, "vars-chips"], [1, "var-chip"], [1, "form-field", 2, "margin-top", "16px"], ["rows", "5", 1, "form-input", "form-textarea", 3, "input", "value"], [1, "msg-preview"], [1, "msg-preview-label"], [1, "msg-preview-text"]], template: function FinanceiroOverviewComponent_Template(rf, ctx) {
      if (rf & 1) {
        \u0275\u0275elementStart(0, "div", 0);
        \u0275\u0275listener("click", function FinanceiroOverviewComponent_Template_div_click_0_listener() {
          return ctx.fecharDropdownAcao();
        });
        \u0275\u0275elementStart(1, "div", 1)(2, "div")(3, "h1", 2);
        \u0275\u0275text(4, "Financeiro");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(5, "p", 3);
        \u0275\u0275text(6, "Controle de pagamentos e inadimpl\xEAncia");
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(7, "div", 4)(8, "button", 5);
        \u0275\u0275listener("click", function FinanceiroOverviewComponent_Template_button_click_8_listener() {
          return ctx.abrirModalMsgTemplate();
        });
        \u0275\u0275namespaceSVG();
        \u0275\u0275elementStart(9, "svg", 6);
        \u0275\u0275element(10, "path", 7);
        \u0275\u0275elementEnd();
        \u0275\u0275text(11, " Personalizar mensagem de cobran\xE7a ");
        \u0275\u0275elementEnd();
        \u0275\u0275namespaceHTML();
        \u0275\u0275elementStart(12, "button", 8);
        \u0275\u0275listener("click", function FinanceiroOverviewComponent_Template_button_click_12_listener() {
          return ctx.abrirModalNovoPagamento();
        });
        \u0275\u0275namespaceSVG();
        \u0275\u0275elementStart(13, "svg", 9);
        \u0275\u0275element(14, "line", 10)(15, "line", 11);
        \u0275\u0275elementEnd();
        \u0275\u0275text(16, " Novo Pagamento ");
        \u0275\u0275elementEnd()()();
        \u0275\u0275namespaceHTML();
        \u0275\u0275elementStart(17, "div", 12)(18, "button", 13);
        \u0275\u0275listener("click", function FinanceiroOverviewComponent_Template_button_click_18_listener() {
          return ctx.irMesAnterior();
        });
        \u0275\u0275namespaceSVG();
        \u0275\u0275elementStart(19, "svg", 14);
        \u0275\u0275element(20, "polyline", 15);
        \u0275\u0275elementEnd()();
        \u0275\u0275namespaceHTML();
        \u0275\u0275elementStart(21, "span", 16);
        \u0275\u0275text(22);
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(23, "button", 13);
        \u0275\u0275listener("click", function FinanceiroOverviewComponent_Template_button_click_23_listener() {
          return ctx.irProximoMes();
        });
        \u0275\u0275namespaceSVG();
        \u0275\u0275elementStart(24, "svg", 14);
        \u0275\u0275element(25, "polyline", 17);
        \u0275\u0275elementEnd()();
        \u0275\u0275template(26, FinanceiroOverviewComponent_Conditional_26_Template, 2, 0, "button", 18);
        \u0275\u0275elementEnd();
        \u0275\u0275template(27, FinanceiroOverviewComponent_Conditional_27_Template, 23, 5, "div", 19);
        \u0275\u0275namespaceHTML();
        \u0275\u0275elementStart(28, "div", 20)(29, "button", 21);
        \u0275\u0275listener("click", function FinanceiroOverviewComponent_Template_button_click_29_listener() {
          return ctx.selecionarAba("pagamentos");
        });
        \u0275\u0275text(30, "Pagamentos");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(31, "button", 21);
        \u0275\u0275listener("click", function FinanceiroOverviewComponent_Template_button_click_31_listener() {
          return ctx.selecionarAba("inadimplentes");
        });
        \u0275\u0275text(32, "Inadimplentes");
        \u0275\u0275elementEnd()();
        \u0275\u0275template(33, FinanceiroOverviewComponent_Conditional_33_Template, 9, 2)(34, FinanceiroOverviewComponent_Conditional_34_Template, 16, 1, "div", 22);
        \u0275\u0275elementEnd();
        \u0275\u0275template(35, FinanceiroOverviewComponent_Conditional_35_Template, 61, 14)(36, FinanceiroOverviewComponent_Conditional_36_Template, 19, 4)(37, FinanceiroOverviewComponent_Conditional_37_Template, 39, 2);
      }
      if (rf & 2) {
        let tmp_2_0;
        \u0275\u0275advance(22);
        \u0275\u0275textInterpolate(ctx.nomeMes());
        \u0275\u0275advance(4);
        \u0275\u0275conditional(26, !ctx.ehMesAtual() ? 26 : -1);
        \u0275\u0275advance();
        \u0275\u0275conditional(27, (tmp_2_0 = ctx.resumo()) ? 27 : -1, tmp_2_0);
        \u0275\u0275advance(2);
        \u0275\u0275classProp("ativa", ctx.abaAtiva() === "pagamentos");
        \u0275\u0275advance(2);
        \u0275\u0275classProp("ativa", ctx.abaAtiva() === "inadimplentes");
        \u0275\u0275advance(2);
        \u0275\u0275conditional(33, ctx.abaAtiva() === "pagamentos" ? 33 : -1);
        \u0275\u0275advance();
        \u0275\u0275conditional(34, ctx.abaAtiva() === "inadimplentes" ? 34 : -1);
        \u0275\u0275advance();
        \u0275\u0275conditional(35, ctx.modalNovoPagamento() ? 35 : -1);
        \u0275\u0275advance();
        \u0275\u0275conditional(36, ctx.modalExcluir() ? 36 : -1);
        \u0275\u0275advance();
        \u0275\u0275conditional(37, ctx.modalMsgTemplate() ? 37 : -1);
      }
    }, dependencies: [CommonModule, NgClass, FormsModule, NgSelectOption, \u0275NgSelectMultipleOption], styles: ['\n\n.financeiro-page[_ngcontent-%COMP%] {\n  padding: 28px 32px;\n  max-width: 1200px;\n  margin: 0 auto;\n}\n.page-header[_ngcontent-%COMP%] {\n  display: flex;\n  align-items: flex-start;\n  justify-content: space-between;\n  margin-bottom: 28px;\n}\n.page-title[_ngcontent-%COMP%] {\n  font-size: 1.5rem;\n  font-weight: 700;\n  color: var(--app-text-1);\n  margin: 0 0 4px;\n}\n.page-subtitle[_ngcontent-%COMP%] {\n  font-size: 0.875rem;\n  color: var(--app-text-3);\n  margin: 0;\n}\n.mes-nav[_ngcontent-%COMP%] {\n  display: flex;\n  align-items: center;\n  gap: 8px;\n  margin-bottom: 24px;\n}\n.mes-btn[_ngcontent-%COMP%] {\n  display: flex;\n  align-items: center;\n  justify-content: center;\n  width: 32px;\n  height: 32px;\n  border-radius: 8px;\n  border: 1px solid var(--app-border);\n  background: var(--app-surface);\n  color: var(--app-text-2);\n  cursor: pointer;\n  transition: background 0.15s, color 0.15s;\n}\n.mes-btn[_ngcontent-%COMP%]:hover {\n  background: var(--app-border);\n  color: var(--app-text-1);\n}\n.mes-label[_ngcontent-%COMP%] {\n  font-size: 1rem;\n  font-weight: 700;\n  color: var(--app-text-1);\n  min-width: 180px;\n  text-align: center;\n}\n.mes-hoje-btn[_ngcontent-%COMP%] {\n  font-size: 0.75rem;\n  font-weight: 600;\n  padding: 4px 10px;\n  background: transparent;\n  border: 1px solid var(--color-primary, #6366f1);\n  border-radius: 6px;\n  color: var(--color-primary, #6366f1);\n  cursor: pointer;\n  transition: background 0.15s;\n  margin-left: 4px;\n}\n.mes-hoje-btn[_ngcontent-%COMP%]:hover {\n  background: rgba(99, 102, 241, 0.1);\n}\n.resumo-grid[_ngcontent-%COMP%] {\n  display: grid;\n  grid-template-columns: repeat(4, 1fr);\n  gap: 16px;\n  margin-bottom: 28px;\n}\n.resumo-card[_ngcontent-%COMP%] {\n  background: var(--app-surface);\n  border: 1px solid var(--app-border);\n  border-radius: 12px;\n  padding: 20px 24px;\n  display: flex;\n  flex-direction: column;\n  gap: 8px;\n  border-left: 4px solid transparent;\n}\n.card-verde[_ngcontent-%COMP%] {\n  border-left-color: #22c55e;\n}\n.card-amarelo[_ngcontent-%COMP%] {\n  border-left-color: #f59e0b;\n}\n.card-vermelho[_ngcontent-%COMP%] {\n  border-left-color: #ef4444;\n}\n.card-neutro[_ngcontent-%COMP%] {\n  border-left-color: #6366f1;\n}\n.resumo-label[_ngcontent-%COMP%] {\n  font-size: 0.75rem;\n  font-weight: 600;\n  text-transform: uppercase;\n  letter-spacing: 0.05em;\n  color: var(--app-text-3);\n}\n.resumo-valor[_ngcontent-%COMP%] {\n  font-size: 1.5rem;\n  font-weight: 700;\n  color: var(--app-text-1);\n  line-height: 1.2;\n}\n.resumo-valor[_ngcontent-%COMP%]   small[_ngcontent-%COMP%] {\n  font-size: 0.875rem;\n  font-weight: 400;\n  color: var(--app-text-3);\n}\n.abas-bar[_ngcontent-%COMP%] {\n  display: flex;\n  gap: 4px;\n  border-bottom: 1px solid var(--app-border);\n  margin-bottom: 20px;\n}\n.aba-btn[_ngcontent-%COMP%] {\n  background: none;\n  border: none;\n  padding: 10px 18px;\n  font-size: 0.875rem;\n  font-weight: 500;\n  color: var(--app-text-3);\n  cursor: pointer;\n  border-bottom: 2px solid transparent;\n  transition: color 0.15s, border-color 0.15s;\n  margin-bottom: -1px;\n}\n.aba-btn[_ngcontent-%COMP%]:hover {\n  color: var(--app-text-1);\n}\n.aba-btn.ativa[_ngcontent-%COMP%] {\n  color: var(--color-primary, #6366f1);\n  border-bottom-color: var(--color-primary, #6366f1);\n}\n.filtros-bar[_ngcontent-%COMP%] {\n  display: flex;\n  gap: 12px;\n  margin-bottom: 16px;\n}\n.select-filtro[_ngcontent-%COMP%] {\n  background: var(--app-surface);\n  border: 1px solid var(--app-border);\n  border-radius: 8px;\n  padding: 8px 12px;\n  font-size: 0.875rem;\n  color: var(--app-text-1);\n  min-width: 180px;\n}\n.tabela-wrap[_ngcontent-%COMP%] {\n  background: var(--app-surface);\n  border: 1px solid var(--app-border);\n  border-radius: 12px;\n  overflow: hidden;\n}\n.tabela[_ngcontent-%COMP%] {\n  width: 100%;\n  border-collapse: collapse;\n  font-size: 0.875rem;\n}\n.tabela[_ngcontent-%COMP%]   th[_ngcontent-%COMP%] {\n  padding: 12px 16px;\n  text-align: left;\n  font-size: 0.75rem;\n  font-weight: 600;\n  text-transform: uppercase;\n  letter-spacing: 0.05em;\n  color: var(--app-text-3);\n  border-bottom: 1px solid var(--app-border);\n  background: var(--app-surface);\n}\n.tabela[_ngcontent-%COMP%]   td[_ngcontent-%COMP%] {\n  padding: 12px 16px;\n  color: var(--app-text-1);\n  border-bottom: 1px solid var(--app-border);\n  vertical-align: middle;\n}\n.tabela[_ngcontent-%COMP%]   tr[_ngcontent-%COMP%]:last-child   td[_ngcontent-%COMP%] {\n  border-bottom: none;\n}\n.tabela[_ngcontent-%COMP%]   tbody[_ngcontent-%COMP%]   tr[_ngcontent-%COMP%]:hover {\n  background: rgba(99, 102, 241, 0.04);\n}\n.valor-col[_ngcontent-%COMP%] {\n  font-weight: 600;\n  font-variant-numeric: tabular-nums;\n}\n.valor-vermelho[_ngcontent-%COMP%] {\n  color: #ef4444;\n}\n.desc-col[_ngcontent-%COMP%] {\n  color: var(--app-text-2);\n  max-width: 200px;\n  white-space: nowrap;\n  overflow: hidden;\n  text-overflow: ellipsis;\n}\n.empty-row[_ngcontent-%COMP%] {\n  text-align: center;\n  color: var(--app-text-3);\n  padding: 32px 16px !important;\n}\n.loading-state[_ngcontent-%COMP%] {\n  text-align: center;\n  color: var(--app-text-3);\n  padding: 48px;\n  font-size: 0.9rem;\n}\n.badge[_ngcontent-%COMP%] {\n  display: inline-block;\n  padding: 3px 10px;\n  border-radius: 999px;\n  font-size: 0.75rem;\n  font-weight: 600;\n  letter-spacing: 0.02em;\n}\n.badge-pago[_ngcontent-%COMP%] {\n  background: rgba(34, 197, 94, 0.12);\n  color: #16a34a;\n}\n.badge-pendente[_ngcontent-%COMP%] {\n  background: rgba(245, 158, 11, 0.12);\n  color: #d97706;\n}\n.badge-atrasado[_ngcontent-%COMP%] {\n  background: rgba(239, 68, 68, 0.12);\n  color: #dc2626;\n}\n.badge-cancelado[_ngcontent-%COMP%] {\n  background: rgba(107, 114, 128, 0.12);\n  color: #6b7280;\n}\n.acoes-col[_ngcontent-%COMP%] {\n  display: flex;\n  gap: 6px;\n  align-items: center;\n}\n.btn-acao[_ngcontent-%COMP%] {\n  display: flex;\n  align-items: center;\n  justify-content: center;\n  width: 30px;\n  height: 30px;\n  border-radius: 6px;\n  border: 1px solid var(--app-border);\n  background: var(--app-surface);\n  cursor: pointer;\n  color: var(--app-text-2);\n  font-size: 0.875rem;\n  font-weight: 700;\n  transition: background 0.15s, color 0.15s;\n}\n.btn-pagar[_ngcontent-%COMP%]:hover {\n  background: rgba(34, 197, 94, 0.15);\n  color: #16a34a;\n  border-color: #22c55e;\n}\n.btn-excluir[_ngcontent-%COMP%]:hover {\n  background: rgba(239, 68, 68, 0.1);\n  color: #dc2626;\n  border-color: #ef4444;\n}\n.btn-primary[_ngcontent-%COMP%] {\n  display: inline-flex;\n  align-items: center;\n  gap: 6px;\n  padding: 9px 18px;\n  background: var(--color-primary, #6366f1);\n  color: #fff;\n  border: none;\n  border-radius: 8px;\n  font-size: 0.875rem;\n  font-weight: 600;\n  cursor: pointer;\n  transition: opacity 0.15s;\n}\n.btn-primary[_ngcontent-%COMP%]:disabled {\n  opacity: 0.6;\n  cursor: not-allowed;\n}\n.btn-primary[_ngcontent-%COMP%]:hover:not(:disabled) {\n  opacity: 0.9;\n}\n.btn-ghost[_ngcontent-%COMP%] {\n  padding: 9px 18px;\n  background: transparent;\n  border: 1px solid var(--app-border);\n  border-radius: 8px;\n  font-size: 0.875rem;\n  font-weight: 500;\n  color: var(--app-text-2);\n  cursor: pointer;\n  transition: background 0.15s;\n}\n.btn-ghost[_ngcontent-%COMP%]:hover {\n  background: var(--app-border);\n}\n.btn-danger[_ngcontent-%COMP%] {\n  padding: 9px 18px;\n  background: #ef4444;\n  color: #fff;\n  border: none;\n  border-radius: 8px;\n  font-size: 0.875rem;\n  font-weight: 600;\n  cursor: pointer;\n  transition: opacity 0.15s;\n}\n.btn-danger[_ngcontent-%COMP%]:disabled {\n  opacity: 0.6;\n  cursor: not-allowed;\n}\n.btn-danger[_ngcontent-%COMP%]:hover:not(:disabled) {\n  opacity: 0.88;\n}\n.modal-backdrop[_ngcontent-%COMP%] {\n  position: fixed;\n  inset: 0;\n  background: rgba(0, 0, 0, 0.5);\n  z-index: 100;\n}\n.modal[_ngcontent-%COMP%] {\n  position: fixed;\n  top: 50%;\n  left: 50%;\n  transform: translate(-50%, -50%);\n  z-index: 101;\n  background: var(--app-surface);\n  border: 1px solid var(--app-border);\n  border-radius: 16px;\n  width: 560px;\n  max-width: calc(100vw - 32px);\n  max-height: calc(100vh - 64px);\n  display: flex;\n  flex-direction: column;\n  overflow: hidden;\n  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.4);\n}\n.modal-sm[_ngcontent-%COMP%] {\n  width: 400px;\n}\n.modal-header[_ngcontent-%COMP%] {\n  display: flex;\n  align-items: center;\n  justify-content: space-between;\n  padding: 20px 24px 16px;\n  border-bottom: 1px solid var(--app-border);\n}\n.modal-titulo[_ngcontent-%COMP%] {\n  font-size: 1.1rem;\n  font-weight: 700;\n  color: var(--app-text-1);\n  margin: 0;\n}\n.modal-fechar[_ngcontent-%COMP%] {\n  background: none;\n  border: none;\n  color: var(--app-text-3);\n  cursor: pointer;\n  display: flex;\n  align-items: center;\n  padding: 4px;\n  border-radius: 6px;\n  transition: background 0.15s;\n}\n.modal-fechar[_ngcontent-%COMP%]:hover {\n  background: var(--app-border);\n}\n.modal-body[_ngcontent-%COMP%] {\n  padding: 20px 24px;\n  overflow-y: auto;\n  display: flex;\n  flex-direction: column;\n  gap: 16px;\n}\n.modal-footer[_ngcontent-%COMP%] {\n  display: flex;\n  justify-content: flex-end;\n  gap: 10px;\n  padding: 16px 24px 20px;\n  border-top: 1px solid var(--app-border);\n}\n.form-field[_ngcontent-%COMP%] {\n  display: flex;\n  flex-direction: column;\n  gap: 6px;\n}\n.form-label[_ngcontent-%COMP%] {\n  font-size: 0.8rem;\n  font-weight: 600;\n  color: var(--app-text-2);\n}\n.form-input[_ngcontent-%COMP%] {\n  background: var(--app-bg, #0f1117);\n  border: 1px solid var(--app-border);\n  border-radius: 8px;\n  padding: 9px 12px;\n  font-size: 0.875rem;\n  color: var(--app-text-1);\n  width: 100%;\n  box-sizing: border-box;\n  transition: border-color 0.15s;\n}\n.form-input[_ngcontent-%COMP%]:focus {\n  outline: none;\n  border-color: var(--color-primary, #6366f1);\n}\n.form-textarea[_ngcontent-%COMP%] {\n  resize: vertical;\n  min-height: 64px;\n}\n.form-row[_ngcontent-%COMP%] {\n  display: grid;\n  grid-template-columns: 1fr 1fr;\n  gap: 16px;\n}\n.erro-msg[_ngcontent-%COMP%] {\n  color: #ef4444;\n  font-size: 0.8rem;\n  font-weight: 500;\n  margin: 0;\n}\n.aluno-picker[_ngcontent-%COMP%] {\n  position: relative;\n}\n.aluno-dropdown[_ngcontent-%COMP%] {\n  position: absolute;\n  top: calc(100% + 4px);\n  left: 0;\n  right: 0;\n  background: var(--app-surface);\n  border: 1px solid var(--app-border);\n  border-radius: 8px;\n  max-height: 200px;\n  overflow-y: auto;\n  z-index: 200;\n  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3);\n}\n.aluno-item[_ngcontent-%COMP%] {\n  padding: 10px 14px;\n  font-size: 0.875rem;\n  color: var(--app-text-1);\n  cursor: pointer;\n  transition: background 0.1s;\n}\n.aluno-item[_ngcontent-%COMP%]:hover {\n  background: rgba(99, 102, 241, 0.1);\n}\n.aluno-vazio[_ngcontent-%COMP%] {\n  color: var(--app-text-3);\n  cursor: default;\n}\n.planos-header[_ngcontent-%COMP%] {\n  display: flex;\n  align-items: center;\n  justify-content: space-between;\n  margin-bottom: 20px;\n  gap: 16px;\n}\n.planos-desc[_ngcontent-%COMP%] {\n  font-size: 0.875rem;\n  color: var(--app-text-3);\n  margin: 0;\n}\n.planos-grid[_ngcontent-%COMP%] {\n  display: grid;\n  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));\n  gap: 16px;\n}\n.plano-card[_ngcontent-%COMP%] {\n  background: var(--app-surface);\n  border: 1px solid var(--app-border);\n  border-radius: 12px;\n  padding: 20px;\n  display: flex;\n  flex-direction: column;\n  gap: 12px;\n  transition: border-color 0.15s;\n}\n.plano-card[_ngcontent-%COMP%]:hover {\n  border-color: var(--color-primary, #6366f1);\n}\n.plano-card.inativo[_ngcontent-%COMP%] {\n  opacity: 0.6;\n}\n.plano-card-top[_ngcontent-%COMP%] {\n  display: flex;\n  align-items: flex-start;\n  justify-content: space-between;\n  gap: 8px;\n}\n.plano-nome[_ngcontent-%COMP%] {\n  font-size: 1rem;\n  font-weight: 700;\n  color: var(--app-text-1);\n  margin-right: 8px;\n}\n.plano-acoes[_ngcontent-%COMP%] {\n  display: flex;\n  gap: 6px;\n  flex-shrink: 0;\n}\n.plano-desc[_ngcontent-%COMP%] {\n  font-size: 0.8rem;\n  color: var(--app-text-3);\n  margin: 0;\n  line-height: 1.5;\n}\n.plano-valores[_ngcontent-%COMP%] {\n  display: flex;\n  flex-direction: column;\n  gap: 8px;\n  padding: 12px;\n  background: rgba(99, 102, 241, 0.05);\n  border-radius: 8px;\n}\n.plano-valor-item[_ngcontent-%COMP%] {\n  display: flex;\n  justify-content: space-between;\n  align-items: center;\n}\n.plano-valor-label[_ngcontent-%COMP%] {\n  font-size: 0.75rem;\n  color: var(--app-text-3);\n}\n.plano-valor-num[_ngcontent-%COMP%] {\n  font-size: 0.95rem;\n  font-weight: 700;\n  color: var(--app-text-1);\n}\n.plano-footer[_ngcontent-%COMP%] {\n  display: flex;\n  align-items: center;\n  justify-content: space-between;\n  margin-top: auto;\n  padding-top: 8px;\n  border-top: 1px solid var(--app-border);\n}\n.plano-alunos[_ngcontent-%COMP%] {\n  font-size: 0.75rem;\n  color: var(--app-text-3);\n}\n.btn-toggle[_ngcontent-%COMP%] {\n  font-size: 0.75rem;\n  font-weight: 600;\n  padding: 4px 10px;\n  background: transparent;\n  border: 1px solid var(--app-border);\n  border-radius: 6px;\n  color: var(--app-text-2);\n  cursor: pointer;\n  transition: background 0.15s;\n}\n.btn-toggle[_ngcontent-%COMP%]:hover {\n  background: var(--app-border);\n}\n.planos-empty[_ngcontent-%COMP%] {\n  grid-column: 1 / -1;\n  text-align: center;\n  padding: 48px;\n  color: var(--app-text-3);\n  font-size: 0.9rem;\n}\n.aviso-msg[_ngcontent-%COMP%] {\n  font-size: 0.8rem;\n  color: var(--app-text-3);\n  margin: 4px 0 0;\n}\n.btn-ghost-msg[_ngcontent-%COMP%] {\n  display: inline-flex;\n  align-items: center;\n  gap: 7px;\n  padding: 8px 16px;\n  background: rgba(37, 211, 102, 0.08);\n  border: 1px solid rgba(37, 211, 102, 0.3);\n  border-radius: 8px;\n  font-size: 0.875rem;\n  font-weight: 600;\n  color: #25d366;\n  cursor: pointer;\n  transition: background 0.15s, border-color 0.15s;\n  white-space: nowrap;\n}\n.btn-ghost-msg[_ngcontent-%COMP%]:hover {\n  background: rgba(37, 211, 102, 0.15);\n  border-color: rgba(37, 211, 102, 0.5);\n}\n.vars-chips[_ngcontent-%COMP%] {\n  display: flex;\n  flex-direction: column;\n  gap: 6px;\n  background: var(--app-bg, rgba(0,0,0,0.2));\n  border: 1px solid var(--app-border);\n  border-radius: 10px;\n  padding: 12px 14px;\n}\n.var-chip[_ngcontent-%COMP%] {\n  display: flex;\n  align-items: center;\n  gap: 10px;\n  font-size: 0.8rem;\n  color: var(--app-text-2);\n}\n.var-chip[_ngcontent-%COMP%]   code[_ngcontent-%COMP%] {\n  display: inline-block;\n  background: rgba(99, 102, 241, 0.12);\n  color: var(--color-primary, #6366f1);\n  border: 1px solid rgba(99, 102, 241, 0.25);\n  border-radius: 5px;\n  padding: 2px 7px;\n  font-size: 0.78rem;\n  font-family:\n    "Menlo",\n    "Consolas",\n    monospace;\n  font-weight: 600;\n  min-width: 120px;\n}\n.msg-preview[_ngcontent-%COMP%] {\n  background: #fdf6e3;\n  border: 1px solid #e8d9a0;\n  border-radius: 10px;\n  padding: 14px 16px;\n  margin-top: 4px;\n}\n.msg-preview-label[_ngcontent-%COMP%] {\n  font-size: 0.7rem;\n  font-weight: 700;\n  text-transform: uppercase;\n  letter-spacing: 0.06em;\n  color: #a08020;\n  margin: 0 0 8px;\n}\n.msg-preview-text[_ngcontent-%COMP%] {\n  font-size: 0.875rem;\n  color: #5a4a10;\n  margin: 0;\n  line-height: 1.6;\n  white-space: pre-wrap;\n}\n.btn-dots[_ngcontent-%COMP%] {\n  background: none;\n  border: 1px solid transparent;\n  border-radius: 6px;\n  cursor: pointer;\n  padding: 4px 8px;\n  font-size: 18px;\n  color: var(--app-text-3);\n  line-height: 1;\n  transition: all 0.15s;\n}\n.btn-dots[_ngcontent-%COMP%]:hover {\n  background: var(--app-border-light, rgba(255,255,255,0.06));\n  border-color: var(--app-border);\n  color: var(--app-text-1);\n}\n.acao-overlay[_ngcontent-%COMP%] {\n  position: fixed;\n  inset: 0;\n  z-index: 10;\n}\n.acao-dropdown[_ngcontent-%COMP%] {\n  background: var(--app-surface);\n  border: 1px solid var(--app-border);\n  border-radius: 8px;\n  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.25);\n  z-index: 200;\n  min-width: 200px;\n  padding: 4px;\n}\n.acao-item[_ngcontent-%COMP%] {\n  display: flex;\n  align-items: center;\n  gap: 8px;\n  width: 100%;\n  padding: 8px 10px;\n  border: none;\n  background: none;\n  cursor: pointer;\n  font-size: 13px;\n  color: var(--app-text-1);\n  text-decoration: none;\n  border-radius: 6px;\n  transition: background 0.1s;\n  text-align: left;\n  white-space: nowrap;\n}\n.acao-item[_ngcontent-%COMP%]:hover {\n  background: rgba(99, 102, 241, 0.08);\n}\n.acao-pagar[_ngcontent-%COMP%] {\n  color: #16a34a;\n}\n.acao-pagar[_ngcontent-%COMP%]:hover {\n  background: rgba(34, 197, 94, 0.1);\n}\n.acao-excluir[_ngcontent-%COMP%] {\n  color: #dc2626;\n}\n.acao-excluir[_ngcontent-%COMP%]:hover {\n  background: rgba(239, 68, 68, 0.1);\n}\n.acao-separator[_ngcontent-%COMP%] {\n  height: 1px;\n  background: var(--app-border);\n  margin: 4px 0;\n}\n.wpp-btn[_ngcontent-%COMP%] {\n  display: inline-flex;\n  align-items: center;\n  justify-content: center;\n  background: none;\n  border: none;\n  cursor: pointer;\n  color: #25d366;\n  opacity: 0.8;\n  padding: 4px;\n  border-radius: 6px;\n  transition: opacity 0.15s, transform 0.15s;\n}\n.wpp-btn[_ngcontent-%COMP%]:hover {\n  opacity: 1;\n  transform: scale(1.15);\n}\n.font-medium[_ngcontent-%COMP%] {\n  font-weight: 600;\n}\n@media (max-width: 768px) {\n  .financeiro-page[_ngcontent-%COMP%] {\n    padding: 16px;\n  }\n  .resumo-grid[_ngcontent-%COMP%] {\n    grid-template-columns: 1fr 1fr;\n  }\n  .form-row[_ngcontent-%COMP%] {\n    grid-template-columns: 1fr;\n  }\n}\n@media (max-width: 480px) {\n  .resumo-grid[_ngcontent-%COMP%] {\n    grid-template-columns: 1fr;\n  }\n}\n/*# sourceMappingURL=financeiro-overview.component.css.map */'] });
  }
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && \u0275setClassDebugInfo(FinanceiroOverviewComponent, { className: "FinanceiroOverviewComponent" });
})();
export {
  FinanceiroOverviewComponent
};
//# sourceMappingURL=chunk-MTZMSRNP.js.map
