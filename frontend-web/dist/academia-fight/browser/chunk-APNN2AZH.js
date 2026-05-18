import {
  DefaultValueAccessor,
  FormsModule,
  NgControlStatus,
  NgModel,
  NgSelectOption,
  ɵNgSelectMultipleOption
} from "./chunk-JQJL26HT.js";
import {
  AlunoService
} from "./chunk-ZSIQJU4D.js";
import "./chunk-Z5CKO2JM.js";
import {
  RouterLink
} from "./chunk-AXNOULNC.js";
import {
  CommonModule,
  Subject,
  debounceTime,
  distinctUntilChanged,
  inject,
  signal,
  takeUntil,
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
  ɵɵsanitizeUrl,
  ɵɵstyleProp,
  ɵɵtemplate,
  ɵɵtext,
  ɵɵtextInterpolate,
  ɵɵtextInterpolate1,
  ɵɵtextInterpolate2
} from "./chunk-WZ2AWGAJ.js";
import "./chunk-7G5TR5RR.js";

// src/app/features/alunos/pages/lista/alunos-lista.component.ts
var _forTrack0 = ($index, $item) => $item.id;
var _c0 = () => [1, 2, 3, 4, 5];
var _c1 = (a0) => [a0];
var _c2 = (a0) => [a0, "editar"];
function AlunosListaComponent_Conditional_5_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "p", 3);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1("", ctx_r0.total(), " alunos cadastrados");
  }
}
function AlunosListaComponent_Conditional_17_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 11);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(ctx_r0.erro());
  }
}
function AlunosListaComponent_Conditional_18_For_2_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275element(0, "div", 13);
  }
}
function AlunosListaComponent_Conditional_18_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 12);
    \u0275\u0275repeaterCreate(1, AlunosListaComponent_Conditional_18_For_2_Template, 1, 0, "div", 13, \u0275\u0275repeaterTrackByIdentity);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    \u0275\u0275advance();
    \u0275\u0275repeater(\u0275\u0275pureFunction0(0, _c0));
  }
}
function AlunosListaComponent_Conditional_19_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 14);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(1, "svg", 15);
    \u0275\u0275element(2, "path", 16)(3, "circle", 17)(4, "path", 18);
    \u0275\u0275elementEnd();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(5, "p");
    \u0275\u0275text(6, "Nenhum aluno encontrado.");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(7, "a", 4);
    \u0275\u0275text(8, "+ Novo Aluno");
    \u0275\u0275elementEnd()();
  }
}
function AlunosListaComponent_Conditional_20_For_26_Conditional_8_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 27);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const a_r3 = \u0275\u0275nextContext().$implicit;
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(a_r3.email);
  }
}
function AlunosListaComponent_Conditional_20_For_26_Conditional_10_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 28);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const a_r3 = \u0275\u0275nextContext().$implicit;
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(a_r3.matricula);
  }
}
function AlunosListaComponent_Conditional_20_For_26_Conditional_11_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 37);
    \u0275\u0275text(1, "\u2014");
    \u0275\u0275elementEnd();
  }
}
function AlunosListaComponent_Conditional_20_For_26_Conditional_13_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 29);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const a_r3 = \u0275\u0275nextContext().$implicit;
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(a_r3.planoNome);
  }
}
function AlunosListaComponent_Conditional_20_For_26_Conditional_14_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 37);
    \u0275\u0275text(1, "\u2014");
    \u0275\u0275elementEnd();
  }
}
function AlunosListaComponent_Conditional_20_For_26_Conditional_16_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 30);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const a_r3 = \u0275\u0275nextContext().$implicit;
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(a_r3.turmas.join(", "));
  }
}
function AlunosListaComponent_Conditional_20_For_26_Conditional_17_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 37);
    \u0275\u0275text(1, "Sem turma");
    \u0275\u0275elementEnd();
  }
}
function AlunosListaComponent_Conditional_20_For_26_Conditional_19_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 38);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const a_r3 = \u0275\u0275nextContext().$implicit;
    const ctx_r0 = \u0275\u0275nextContext(2);
    \u0275\u0275styleProp("background", ctx_r0.faixaCor(a_r3.faixaAtualCor) + "33")("color", ctx_r0.faixaCor(a_r3.faixaAtualCor))("border", "1px solid " + ctx_r0.faixaCor(a_r3.faixaAtualCor) + "66");
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1(" ", a_r3.faixaAtualNome, " ");
  }
}
function AlunosListaComponent_Conditional_20_For_26_Conditional_20_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 37);
    \u0275\u0275text(1, "\u2014");
    \u0275\u0275elementEnd();
  }
}
function AlunosListaComponent_Conditional_20_For_26_Conditional_22_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 30);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const a_r3 = \u0275\u0275nextContext().$implicit;
    const ctx_r0 = \u0275\u0275nextContext(2);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(ctx_r0.aniversario(a_r3.dataNascimento));
  }
}
function AlunosListaComponent_Conditional_20_For_26_Conditional_23_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 37);
    \u0275\u0275text(1, "\u2014");
    \u0275\u0275elementEnd();
  }
}
function AlunosListaComponent_Conditional_20_For_26_Conditional_28_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 33);
    \u0275\u0275text(1, "Inadimplente");
    \u0275\u0275elementEnd();
  }
}
function AlunosListaComponent_Conditional_20_For_26_Conditional_29_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 39);
    \u0275\u0275text(1, "Pendente");
    \u0275\u0275elementEnd();
  }
}
function AlunosListaComponent_Conditional_20_For_26_Conditional_30_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 40);
    \u0275\u0275text(1, "Em dia");
    \u0275\u0275elementEnd();
  }
}
function AlunosListaComponent_Conditional_20_For_26_Conditional_31_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 41);
    \u0275\u0275text(1, "\u2014");
    \u0275\u0275elementEnd();
  }
}
function AlunosListaComponent_Conditional_20_For_26_Conditional_33_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "a", 35);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(1, "svg", 42);
    \u0275\u0275element(2, "path", 43);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const a_r3 = \u0275\u0275nextContext().$implicit;
    const ctx_r0 = \u0275\u0275nextContext(2);
    \u0275\u0275property("href", ctx_r0.wppLink(a_r3.telefone), \u0275\u0275sanitizeUrl)("title", "WhatsApp: " + a_r3.telefone);
  }
}
function AlunosListaComponent_Conditional_20_For_26_Conditional_34_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 41);
    \u0275\u0275text(1, "\u2014");
    \u0275\u0275elementEnd();
  }
}
function AlunosListaComponent_Conditional_20_For_26_Conditional_40_Template(rf, ctx) {
  if (rf & 1) {
    const _r4 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 44);
    \u0275\u0275listener("click", function AlunosListaComponent_Conditional_20_For_26_Conditional_40_Template_div_click_0_listener() {
      \u0275\u0275restoreView(_r4);
      const ctx_r0 = \u0275\u0275nextContext(3);
      return \u0275\u0275resetView(ctx_r0.fecharDropdown());
    });
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(1, "div", 45)(2, "a", 46);
    \u0275\u0275listener("click", function AlunosListaComponent_Conditional_20_For_26_Conditional_40_Template_a_click_2_listener() {
      \u0275\u0275restoreView(_r4);
      const ctx_r0 = \u0275\u0275nextContext(3);
      return \u0275\u0275resetView(ctx_r0.fecharDropdown());
    });
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(3, "svg", 47);
    \u0275\u0275element(4, "path", 48)(5, "circle", 49);
    \u0275\u0275elementEnd();
    \u0275\u0275text(6, " Ver detalhes ");
    \u0275\u0275elementEnd();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(7, "a", 46);
    \u0275\u0275listener("click", function AlunosListaComponent_Conditional_20_For_26_Conditional_40_Template_a_click_7_listener() {
      \u0275\u0275restoreView(_r4);
      const ctx_r0 = \u0275\u0275nextContext(3);
      return \u0275\u0275resetView(ctx_r0.fecharDropdown());
    });
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(8, "svg", 47);
    \u0275\u0275element(9, "path", 50)(10, "path", 51);
    \u0275\u0275elementEnd();
    \u0275\u0275text(11, " Editar ");
    \u0275\u0275elementEnd();
    \u0275\u0275namespaceHTML();
    \u0275\u0275element(12, "div", 52);
    \u0275\u0275elementStart(13, "button", 53);
    \u0275\u0275listener("click", function AlunosListaComponent_Conditional_20_For_26_Conditional_40_Template_button_click_13_listener() {
      \u0275\u0275restoreView(_r4);
      const a_r3 = \u0275\u0275nextContext().$implicit;
      const ctx_r0 = \u0275\u0275nextContext(2);
      return \u0275\u0275resetView(ctx_r0.abrirToggle(a_r3));
    });
    \u0275\u0275elementStart(14, "div", 54);
    \u0275\u0275element(15, "div", 55);
    \u0275\u0275elementEnd();
    \u0275\u0275text(16);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const a_r3 = \u0275\u0275nextContext().$implicit;
    const ctx_r0 = \u0275\u0275nextContext(2);
    \u0275\u0275advance();
    \u0275\u0275styleProp("top", ctx_r0.dropdownPos().top, "px")("right", ctx_r0.dropdownPos().right, "px");
    \u0275\u0275advance();
    \u0275\u0275property("routerLink", \u0275\u0275pureFunction1(9, _c1, a_r3.id));
    \u0275\u0275advance(5);
    \u0275\u0275property("routerLink", \u0275\u0275pureFunction1(11, _c2, a_r3.id));
    \u0275\u0275advance(7);
    \u0275\u0275classProp("on", a_r3.ativo);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate1(" ", a_r3.ativo ? "Desativar" : "Ativar", " ");
  }
}
function AlunosListaComponent_Conditional_20_For_26_Template(rf, ctx) {
  if (rf & 1) {
    const _r2 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "tr")(1, "td")(2, "div", 24)(3, "div", 25);
    \u0275\u0275text(4);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(5, "div")(6, "div", 26);
    \u0275\u0275text(7);
    \u0275\u0275elementEnd();
    \u0275\u0275template(8, AlunosListaComponent_Conditional_20_For_26_Conditional_8_Template, 2, 1, "div", 27);
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(9, "td");
    \u0275\u0275template(10, AlunosListaComponent_Conditional_20_For_26_Conditional_10_Template, 2, 1, "span", 28)(11, AlunosListaComponent_Conditional_20_For_26_Conditional_11_Template, 2, 0);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(12, "td");
    \u0275\u0275template(13, AlunosListaComponent_Conditional_20_For_26_Conditional_13_Template, 2, 1, "span", 29)(14, AlunosListaComponent_Conditional_20_For_26_Conditional_14_Template, 2, 0);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(15, "td");
    \u0275\u0275template(16, AlunosListaComponent_Conditional_20_For_26_Conditional_16_Template, 2, 1, "span", 30)(17, AlunosListaComponent_Conditional_20_For_26_Conditional_17_Template, 2, 0);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(18, "td");
    \u0275\u0275template(19, AlunosListaComponent_Conditional_20_For_26_Conditional_19_Template, 2, 7, "span", 31)(20, AlunosListaComponent_Conditional_20_For_26_Conditional_20_Template, 2, 0);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(21, "td");
    \u0275\u0275template(22, AlunosListaComponent_Conditional_20_For_26_Conditional_22_Template, 2, 1, "span", 30)(23, AlunosListaComponent_Conditional_20_For_26_Conditional_23_Template, 2, 0);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(24, "td")(25, "span", 32);
    \u0275\u0275text(26);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(27, "td");
    \u0275\u0275template(28, AlunosListaComponent_Conditional_20_For_26_Conditional_28_Template, 2, 0, "span", 33)(29, AlunosListaComponent_Conditional_20_For_26_Conditional_29_Template, 2, 0)(30, AlunosListaComponent_Conditional_20_For_26_Conditional_30_Template, 2, 0)(31, AlunosListaComponent_Conditional_20_For_26_Conditional_31_Template, 2, 0);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(32, "td", 34);
    \u0275\u0275template(33, AlunosListaComponent_Conditional_20_For_26_Conditional_33_Template, 3, 2, "a", 35)(34, AlunosListaComponent_Conditional_20_For_26_Conditional_34_Template, 2, 0);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(35, "td")(36, "div")(37, "button", 36);
    \u0275\u0275listener("click", function AlunosListaComponent_Conditional_20_For_26_Template_button_click_37_listener($event) {
      const a_r3 = \u0275\u0275restoreView(_r2).$implicit;
      const ctx_r0 = \u0275\u0275nextContext(2);
      ctx_r0.toggleDropdown(a_r3.id, $event);
      return \u0275\u0275resetView($event.stopPropagation());
    });
    \u0275\u0275elementStart(38, "span");
    \u0275\u0275text(39, "\u22EF");
    \u0275\u0275elementEnd()();
    \u0275\u0275template(40, AlunosListaComponent_Conditional_20_For_26_Conditional_40_Template, 17, 13);
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    const a_r3 = ctx.$implicit;
    const ctx_r0 = \u0275\u0275nextContext(2);
    \u0275\u0275advance(4);
    \u0275\u0275textInterpolate(ctx_r0.avatarInicial(a_r3.nome));
    \u0275\u0275advance(3);
    \u0275\u0275textInterpolate(a_r3.nome);
    \u0275\u0275advance();
    \u0275\u0275conditional(8, a_r3.email ? 8 : -1);
    \u0275\u0275advance(2);
    \u0275\u0275conditional(10, a_r3.matricula ? 10 : 11);
    \u0275\u0275advance(3);
    \u0275\u0275conditional(13, a_r3.planoNome ? 13 : 14);
    \u0275\u0275advance(3);
    \u0275\u0275conditional(16, a_r3.turmas.length ? 16 : 17);
    \u0275\u0275advance(3);
    \u0275\u0275conditional(19, a_r3.faixaAtualNome ? 19 : 20);
    \u0275\u0275advance(3);
    \u0275\u0275conditional(22, a_r3.dataNascimento ? 22 : 23);
    \u0275\u0275advance(3);
    \u0275\u0275classProp("badge-success", a_r3.ativo)("badge-neutral", !a_r3.ativo);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1(" ", a_r3.ativo ? "Ativo" : "Inativo", " ");
    \u0275\u0275advance(2);
    \u0275\u0275conditional(28, a_r3.situacaoFinanceira === "Inadimplente" ? 28 : a_r3.situacaoFinanceira === "Pendente" ? 29 : a_r3.situacaoFinanceira === "EmDia" ? 30 : 31);
    \u0275\u0275advance(5);
    \u0275\u0275conditional(33, a_r3.telefone ? 33 : 34);
    \u0275\u0275advance(7);
    \u0275\u0275conditional(40, ctx_r0.dropdownAbertoId() === a_r3.id ? 40 : -1);
  }
}
function AlunosListaComponent_Conditional_20_Conditional_27_Template(rf, ctx) {
  if (rf & 1) {
    const _r5 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 23)(1, "button", 56);
    \u0275\u0275listener("click", function AlunosListaComponent_Conditional_20_Conditional_27_Template_button_click_1_listener() {
      \u0275\u0275restoreView(_r5);
      const ctx_r0 = \u0275\u0275nextContext(2);
      return \u0275\u0275resetView(ctx_r0.irPagina(ctx_r0.pagina() - 1));
    });
    \u0275\u0275text(2, "\u2190 Anterior");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "span", 57);
    \u0275\u0275text(4);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(5, "button", 56);
    \u0275\u0275listener("click", function AlunosListaComponent_Conditional_20_Conditional_27_Template_button_click_5_listener() {
      \u0275\u0275restoreView(_r5);
      const ctx_r0 = \u0275\u0275nextContext(2);
      return \u0275\u0275resetView(ctx_r0.irPagina(ctx_r0.pagina() + 1));
    });
    \u0275\u0275text(6, "Pr\xF3xima \u2192");
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext(2);
    \u0275\u0275advance();
    \u0275\u0275property("disabled", ctx_r0.pagina() === 1);
    \u0275\u0275advance(3);
    \u0275\u0275textInterpolate2("P\xE1gina ", ctx_r0.pagina(), " de ", ctx_r0.totalPaginas(), "");
    \u0275\u0275advance();
    \u0275\u0275property("disabled", ctx_r0.pagina() === ctx_r0.totalPaginas());
  }
}
function AlunosListaComponent_Conditional_20_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 19)(1, "table", 20)(2, "thead")(3, "tr")(4, "th");
    \u0275\u0275text(5, "Aluno");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(6, "th");
    \u0275\u0275text(7, "Matr\xEDcula");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(8, "th");
    \u0275\u0275text(9, "Plano");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(10, "th");
    \u0275\u0275text(11, "Turmas");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(12, "th");
    \u0275\u0275text(13, "Faixa");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(14, "th");
    \u0275\u0275text(15, "Anivers\xE1rio");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(16, "th");
    \u0275\u0275text(17, "Status");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(18, "th");
    \u0275\u0275text(19, "Situa\xE7\xE3o");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(20, "th", 21);
    \u0275\u0275text(21, "Contato");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(22, "th", 22);
    \u0275\u0275text(23, "A\xE7\xF5es");
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(24, "tbody");
    \u0275\u0275repeaterCreate(25, AlunosListaComponent_Conditional_20_For_26_Template, 41, 16, "tr", null, _forTrack0);
    \u0275\u0275elementEnd()()();
    \u0275\u0275template(27, AlunosListaComponent_Conditional_20_Conditional_27_Template, 7, 4, "div", 23);
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance(25);
    \u0275\u0275repeater(ctx_r0.alunos());
    \u0275\u0275advance(2);
    \u0275\u0275conditional(27, ctx_r0.totalPaginas() > 1 ? 27 : -1);
  }
}
function AlunosListaComponent_Conditional_21_Conditional_9_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275text(0, " Tem certeza que deseja ");
    \u0275\u0275elementStart(1, "strong");
    \u0275\u0275text(2, "desativar");
    \u0275\u0275elementEnd();
    \u0275\u0275text(3, " o aluno ");
    \u0275\u0275elementStart(4, "strong");
    \u0275\u0275text(5);
    \u0275\u0275elementEnd();
    \u0275\u0275text(6, "? O aluno n\xE3o poder\xE1 fazer check-in enquanto estiver inativo. ");
  }
  if (rf & 2) {
    let tmp_2_0;
    const ctx_r0 = \u0275\u0275nextContext(2);
    \u0275\u0275advance(5);
    \u0275\u0275textInterpolate((tmp_2_0 = ctx_r0.alunoParaToggle()) == null ? null : tmp_2_0.nome);
  }
}
function AlunosListaComponent_Conditional_21_Conditional_10_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275text(0, " Tem certeza que deseja ");
    \u0275\u0275elementStart(1, "strong");
    \u0275\u0275text(2, "ativar");
    \u0275\u0275elementEnd();
    \u0275\u0275text(3, " o aluno ");
    \u0275\u0275elementStart(4, "strong");
    \u0275\u0275text(5);
    \u0275\u0275elementEnd();
    \u0275\u0275text(6, "? ");
  }
  if (rf & 2) {
    let tmp_2_0;
    const ctx_r0 = \u0275\u0275nextContext(2);
    \u0275\u0275advance(5);
    \u0275\u0275textInterpolate((tmp_2_0 = ctx_r0.alunoParaToggle()) == null ? null : tmp_2_0.nome);
  }
}
function AlunosListaComponent_Conditional_21_Template(rf, ctx) {
  if (rf & 1) {
    const _r6 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 58);
    \u0275\u0275listener("click", function AlunosListaComponent_Conditional_21_Template_div_click_0_listener() {
      \u0275\u0275restoreView(_r6);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.fecharModal());
    });
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(1, "div", 59)(2, "div", 60)(3, "h3");
    \u0275\u0275text(4);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(5, "button", 61);
    \u0275\u0275listener("click", function AlunosListaComponent_Conditional_21_Template_button_click_5_listener() {
      \u0275\u0275restoreView(_r6);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.fecharModal());
    });
    \u0275\u0275text(6, "\u2715");
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(7, "div", 62)(8, "p", 63);
    \u0275\u0275template(9, AlunosListaComponent_Conditional_21_Conditional_9_Template, 7, 1)(10, AlunosListaComponent_Conditional_21_Conditional_10_Template, 7, 1);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(11, "div", 64)(12, "button", 56);
    \u0275\u0275listener("click", function AlunosListaComponent_Conditional_21_Template_button_click_12_listener() {
      \u0275\u0275restoreView(_r6);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.fecharModal());
    });
    \u0275\u0275text(13, "Cancelar");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(14, "button", 65);
    \u0275\u0275listener("click", function AlunosListaComponent_Conditional_21_Template_button_click_14_listener() {
      \u0275\u0275restoreView(_r6);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.confirmarToggle());
    });
    \u0275\u0275text(15);
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    let tmp_1_0;
    let tmp_2_0;
    let tmp_4_0;
    let tmp_6_0;
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance(4);
    \u0275\u0275textInterpolate(((tmp_1_0 = ctx_r0.alunoParaToggle()) == null ? null : tmp_1_0.ativo) ? "Desativar aluno" : "Ativar aluno");
    \u0275\u0275advance(5);
    \u0275\u0275conditional(9, ((tmp_2_0 = ctx_r0.alunoParaToggle()) == null ? null : tmp_2_0.ativo) ? 9 : 10);
    \u0275\u0275advance(3);
    \u0275\u0275property("disabled", ctx_r0.toggleAtivando());
    \u0275\u0275advance(2);
    \u0275\u0275classMap(((tmp_4_0 = ctx_r0.alunoParaToggle()) == null ? null : tmp_4_0.ativo) ? "btn-danger" : "btn-primary");
    \u0275\u0275property("disabled", ctx_r0.toggleAtivando());
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1(" ", ctx_r0.toggleAtivando() ? "Aguarde..." : ((tmp_6_0 = ctx_r0.alunoParaToggle()) == null ? null : tmp_6_0.ativo) ? "Desativar" : "Ativar", " ");
  }
}
var AlunosListaComponent = class _AlunosListaComponent {
  constructor() {
    this.alunoService = inject(AlunoService);
    this.alunos = signal([]);
    this.total = signal(0);
    this.pagina = signal(1);
    this.totalPaginas = signal(1);
    this.carregando = signal(true);
    this.erro = signal("");
    this.filtroNome = signal("");
    this.filtroAtivo = signal(void 0);
    this.modalConfirmacao = signal(false);
    this.alunoParaToggle = signal(null);
    this.toggleAtivando = signal(false);
    this.dropdownAbertoId = signal(null);
    this.dropdownPos = signal({ top: 0, right: 0 });
    this.search$ = new Subject();
    this.destroy$ = new Subject();
  }
  ngOnInit() {
    this.search$.pipe(debounceTime(400), distinctUntilChanged(), takeUntil(this.destroy$)).subscribe(() => {
      this.pagina.set(1);
      this.carregar();
    });
    this.carregar();
  }
  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }
  onNomeChange(nome) {
    this.filtroNome.set(nome);
    this.search$.next(nome);
  }
  onAtivoChange(val) {
    this.filtroAtivo.set(val === "" ? void 0 : val === "true");
    this.pagina.set(1);
    this.carregar();
  }
  carregar() {
    this.carregando.set(true);
    this.alunoService.getAll({
      nome: this.filtroNome() || void 0,
      ativo: this.filtroAtivo(),
      page: this.pagina(),
      pageSize: 20
    }).subscribe({
      next: (res) => {
        const dados = res.dados;
        this.alunos.set(dados?.itens ?? []);
        this.total.set(dados?.totalItens ?? 0);
        this.totalPaginas.set(dados?.totalPaginas ?? 1);
        this.carregando.set(false);
      },
      error: () => {
        this.erro.set("Erro ao carregar alunos.");
        this.carregando.set(false);
      }
    });
  }
  abrirToggle(aluno) {
    this.alunoParaToggle.set(aluno);
    this.modalConfirmacao.set(true);
    this.dropdownAbertoId.set(null);
  }
  fecharModal() {
    this.modalConfirmacao.set(false);
    this.alunoParaToggle.set(null);
  }
  confirmarToggle() {
    const aluno = this.alunoParaToggle();
    if (!aluno)
      return;
    this.toggleAtivando.set(true);
    this.alunoService.toggleAtivo(aluno.id, !aluno.ativo).subscribe({
      next: () => {
        this.toggleAtivando.set(false);
        this.fecharModal();
        this.carregar();
      },
      error: () => {
        this.toggleAtivando.set(false);
        this.fecharModal();
        this.erro.set("Erro ao alterar status do aluno.");
      }
    });
  }
  toggleDropdown(id, event) {
    const rect = event.currentTarget.getBoundingClientRect();
    this.dropdownPos.set({ top: rect.bottom + 4, right: window.innerWidth - rect.right });
    this.dropdownAbertoId.update((atual) => atual === id ? null : id);
  }
  fecharDropdown() {
    this.dropdownAbertoId.set(null);
  }
  irPagina(p) {
    if (p < 1 || p > this.totalPaginas())
      return;
    this.pagina.set(p);
    this.carregar();
  }
  wppLink(telefone) {
    return `https://wa.me/55${telefone.replace(/\D/g, "")}`;
  }
  avatarInicial(nome) {
    return (nome ?? "A").charAt(0).toUpperCase();
  }
  faixaCor(cor) {
    return cor ?? "#94a3b8";
  }
  aniversario(dataNascimento) {
    const [, m, d] = dataNascimento.split("-");
    return `${d}/${m}`;
  }
  static {
    this.\u0275fac = function AlunosListaComponent_Factory(t) {
      return new (t || _AlunosListaComponent)();
    };
  }
  static {
    this.\u0275cmp = /* @__PURE__ */ \u0275\u0275defineComponent({ type: _AlunosListaComponent, selectors: [["app-alunos-lista"]], standalone: true, features: [\u0275\u0275StandaloneFeature], decls: 22, vars: 5, consts: [[1, "page-container"], [1, "page-header"], [1, "page-title"], [1, "page-subtitle"], ["routerLink", "novo", 1, "btn-primary"], [1, "filters-row"], ["placeholder", "Buscar por nome...", 1, "form-input", 2, "max-width", "320px", 3, "ngModelChange", "ngModel"], [1, "form-input", 2, "max-width", "160px", 3, "change"], ["value", ""], ["value", "true"], ["value", "false"], [1, "alert-error"], [1, "skeleton-list"], [1, "skeleton-row"], [1, "empty-state"], ["width", "48", "height", "48", "fill", "none", "stroke", "currentColor", "stroke-width", "1.5", "viewBox", "0 0 24 24"], ["d", "M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"], ["cx", "9", "cy", "7", "r", "4"], ["d", "M23 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"], [1, "table-wrapper"], [1, "data-table"], [2, "width", "44px", "text-align", "center"], [2, "width", "60px"], [1, "pagination"], [2, "display", "flex", "align-items", "center", "gap", "10px"], [1, "presenca-avatar", 2, "flex-shrink", "0"], [1, "font-medium"], [2, "font-size", "12px", "color", "var(--app-text-3)"], [1, "badge", "badge-neutral"], [1, "badge-plano"], [2, "font-size", "13px"], [1, "faixa-badge", 3, "background", "color", "border"], [1, "badge"], [1, "badge", "badge-inadimplente"], [2, "text-align", "center"], ["target", "_blank", "rel", "noopener", 1, "wpp-btn", 3, "href", "title"], ["title", "A\xE7\xF5es", 1, "btn-dots", 3, "click"], [2, "color", "var(--app-text-3)"], [1, "faixa-badge"], [1, "badge", "badge-pendente-fin"], [1, "badge", "badge-emdia"], [2, "color", "var(--app-text-3)", "font-size", "12px"], ["width", "17", "height", "17", "viewBox", "0 0 24 24", "fill", "currentColor"], ["d", "M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"], [1, "acao-overlay", 3, "click"], [1, "acao-dropdown"], [1, "acao-item", 3, "click", "routerLink"], ["width", "14", "height", "14", "fill", "none", "stroke", "currentColor", "stroke-width", "2", "viewBox", "0 0 24 24"], ["d", "M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"], ["cx", "12", "cy", "12", "r", "3"], ["d", "M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"], ["d", "M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"], [1, "acao-separator"], [1, "acao-item", "toggle-item", 3, "click"], [1, "mini-toggle"], [1, "mini-toggle-knob"], [1, "btn-secondary", 3, "click", "disabled"], [2, "font-size", "13px", "color", "var(--app-text-2)"], [1, "modal-backdrop", 3, "click"], [1, "modal"], [1, "modal-header"], [1, "modal-close", 3, "click"], [1, "modal-body"], [2, "color", "var(--app-text-2)", "font-size", "0.9rem"], [1, "modal-actions"], [3, "click", "disabled"]], template: function AlunosListaComponent_Template(rf, ctx) {
      if (rf & 1) {
        \u0275\u0275elementStart(0, "div", 0)(1, "div", 1)(2, "div")(3, "h1", 2);
        \u0275\u0275text(4, "Alunos");
        \u0275\u0275elementEnd();
        \u0275\u0275template(5, AlunosListaComponent_Conditional_5_Template, 2, 1, "p", 3);
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(6, "a", 4);
        \u0275\u0275text(7, "+ Novo Aluno");
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(8, "div", 5)(9, "input", 6);
        \u0275\u0275listener("ngModelChange", function AlunosListaComponent_Template_input_ngModelChange_9_listener($event) {
          return ctx.onNomeChange($event);
        });
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(10, "select", 7);
        \u0275\u0275listener("change", function AlunosListaComponent_Template_select_change_10_listener($event) {
          return ctx.onAtivoChange($event.target.value);
        });
        \u0275\u0275elementStart(11, "option", 8);
        \u0275\u0275text(12, "Todos");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(13, "option", 9);
        \u0275\u0275text(14, "Ativos");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(15, "option", 10);
        \u0275\u0275text(16, "Inativos");
        \u0275\u0275elementEnd()()();
        \u0275\u0275template(17, AlunosListaComponent_Conditional_17_Template, 2, 1, "div", 11)(18, AlunosListaComponent_Conditional_18_Template, 3, 1, "div", 12)(19, AlunosListaComponent_Conditional_19_Template, 9, 0)(20, AlunosListaComponent_Conditional_20_Template, 28, 1);
        \u0275\u0275elementEnd();
        \u0275\u0275template(21, AlunosListaComponent_Conditional_21_Template, 16, 7);
      }
      if (rf & 2) {
        \u0275\u0275advance(5);
        \u0275\u0275conditional(5, !ctx.carregando() ? 5 : -1);
        \u0275\u0275advance(4);
        \u0275\u0275property("ngModel", ctx.filtroNome());
        \u0275\u0275advance(8);
        \u0275\u0275conditional(17, ctx.erro() ? 17 : -1);
        \u0275\u0275advance();
        \u0275\u0275conditional(18, ctx.carregando() ? 18 : ctx.alunos().length === 0 ? 19 : 20);
        \u0275\u0275advance(3);
        \u0275\u0275conditional(21, ctx.modalConfirmacao() ? 21 : -1);
      }
    }, dependencies: [CommonModule, FormsModule, NgSelectOption, \u0275NgSelectMultipleOption, DefaultValueAccessor, NgControlStatus, NgModel, RouterLink], styles: [".badge-plano[_ngcontent-%COMP%] { font-size: 11px; font-weight: 600; padding: 2px 8px; border-radius: 99px; white-space: nowrap; background: rgba(99,102,241,0.12); color: #6366f1; }\n  .wpp-btn[_ngcontent-%COMP%] { display: inline-flex; align-items: center; justify-content: center; color: #25d366; opacity: 0.8; transition: opacity 0.15s, transform 0.15s; }\n  .wpp-btn[_ngcontent-%COMP%]:hover { opacity: 1; transform: scale(1.15); }\n  .faixa-badge[_ngcontent-%COMP%] { font-size: 11px; font-weight: 600; padding: 2px 8px; border-radius: 99px; white-space: nowrap; }\n  .badge[_ngcontent-%COMP%] { font-size: 11px; font-weight: 600; padding: 2px 8px; border-radius: 99px; }\n  .badge-success[_ngcontent-%COMP%] { background: rgba(34,197,94,0.15); color: #22c55e; }\n  .badge-neutral[_ngcontent-%COMP%] { background: rgba(148,163,184,0.15); color: #94a3b8; }\n  .badge-emdia[_ngcontent-%COMP%] { background: rgba(34,197,94,0.12); color: #16a34a; }\n  .badge-pendente-fin[_ngcontent-%COMP%] { background: rgba(245,158,11,0.15); color: #d97706; }\n  .badge-inadimplente[_ngcontent-%COMP%] { background: rgba(239,68,68,0.15); color: #dc2626; }\n  .pagination[_ngcontent-%COMP%] { display: flex; align-items: center; justify-content: center; gap: 16px; margin-top: 16px; }\n\n  \n\n  .btn-dots[_ngcontent-%COMP%] { background: none; border: 1px solid transparent; border-radius: 6px; cursor: pointer; padding: 4px 8px; font-size: 18px; color: var(--app-text-3); line-height: 1; transition: all 0.15s; }\n  .btn-dots[_ngcontent-%COMP%]:hover { background: var(--app-border-light); border-color: var(--app-border); color: var(--app-text-1); }\n\n  \n\n  .acao-overlay[_ngcontent-%COMP%] { position: fixed; inset: 0; z-index: 10; }\n  .acao-dropdown[_ngcontent-%COMP%] { position: fixed; background: var(--app-surface); border: 1px solid var(--app-border); border-radius: 8px; box-shadow: 0 4px 20px rgba(0,0,0,0.12); z-index: 200; min-width: 160px; padding: 4px; }\n  .acao-item[_ngcontent-%COMP%] { display: flex; align-items: center; gap: 8px; width: 100%; padding: 7px 10px; border: none; background: none; cursor: pointer; font-size: 13px; color: var(--app-text-1); text-decoration: none; border-radius: 6px; transition: background 0.1s; text-align: left; }\n  .acao-item[_ngcontent-%COMP%]:hover { background: var(--app-border-light); }\n  .acao-separator[_ngcontent-%COMP%] { height: 1px; background: var(--app-border); margin: 4px 0; }\n  .toggle-item[_ngcontent-%COMP%] { color: var(--app-text-2); }\n\n  \n\n  .mini-toggle[_ngcontent-%COMP%] { width: 28px; height: 16px; border-radius: 99px; background: var(--app-border); position: relative; flex-shrink: 0; transition: background 0.2s; }\n  .mini-toggle.on[_ngcontent-%COMP%] { background: #22c55e; }\n  .mini-toggle-knob[_ngcontent-%COMP%] { position: absolute; top: 2px; left: 2px; width: 12px; height: 12px; border-radius: 50%; background: white; transition: transform 0.2s; }\n  .mini-toggle.on[_ngcontent-%COMP%]   .mini-toggle-knob[_ngcontent-%COMP%] { transform: translateX(12px); }"] });
  }
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && \u0275setClassDebugInfo(AlunosListaComponent, { className: "AlunosListaComponent" });
})();
export {
  AlunosListaComponent
};
//# sourceMappingURL=chunk-APNN2AZH.js.map
