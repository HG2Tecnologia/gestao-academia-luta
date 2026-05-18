import {
  ContratoService
} from "./chunk-AJ67XLLV.js";
import {
  FinanceiroService
} from "./chunk-KMLMG5SQ.js";
import {
  NivelBadgeComponent,
  RankingService
} from "./chunk-W5V7URI6.js";
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
  ActivatedRoute,
  Router,
  RouterLink
} from "./chunk-AXNOULNC.js";
import {
  CommonModule,
  NgClass,
  computed,
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
  ɵɵsanitizeUrl,
  ɵɵstyleProp,
  ɵɵtemplate,
  ɵɵtext,
  ɵɵtextInterpolate,
  ɵɵtextInterpolate1,
  ɵɵtextInterpolate2
} from "./chunk-WZ2AWGAJ.js";
import "./chunk-7G5TR5RR.js";

// src/app/features/alunos/pages/detalhe/aluno-detalhe.component.ts
var _forTrack0 = ($index, $item) => $item.id;
var _c0 = () => [1, 2, 3];
var _c1 = (a0) => ["/app/alunos", a0, "editar"];
var _c2 = () => [1, 2, 3, 4];
var _c3 = () => [1, 2];
var _c4 = (a0) => ["/app/contratos", a0];
function AlunoDetalheComponent_Conditional_0_For_4_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275element(0, "div", 3);
  }
}
function AlunoDetalheComponent_Conditional_0_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 0);
    \u0275\u0275element(1, "div", 1);
    \u0275\u0275elementStart(2, "div", 2);
    \u0275\u0275repeaterCreate(3, AlunoDetalheComponent_Conditional_0_For_4_Template, 1, 0, "div", 3, \u0275\u0275repeaterTrackByIdentity);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    \u0275\u0275advance(3);
    \u0275\u0275repeater(\u0275\u0275pureFunction0(0, _c0));
  }
}
function AlunoDetalheComponent_Conditional_1_Template(rf, ctx) {
  if (rf & 1) {
    const _r1 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 0)(1, "div", 4)(2, "p");
    \u0275\u0275text(3);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(4, "button", 5);
    \u0275\u0275listener("click", function AlunoDetalheComponent_Conditional_1_Template_button_click_4_listener() {
      \u0275\u0275restoreView(_r1);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.voltar());
    });
    \u0275\u0275text(5, "\u2190 Voltar");
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext();
    \u0275\u0275advance(3);
    \u0275\u0275textInterpolate(ctx_r1.erro() || "Aluno n\xE3o encontrado.");
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_7_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "a", 11);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(1, "svg", 27);
    \u0275\u0275element(2, "path", 28);
    \u0275\u0275elementEnd();
    \u0275\u0275text(3, " Entrar em contato ");
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(2);
    \u0275\u0275property("href", ctx_r1.wppLink(ctx_r1.aluno().telefone), \u0275\u0275sanitizeUrl);
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_20_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 20);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(2);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1("Matr\xEDcula: ", ctx_r1.aluno().matricula, "");
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_21_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 29);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(2);
    \u0275\u0275styleProp("background", ctx_r1.faixaCor(ctx_r1.aluno().faixaAtualCor) + "22")("color", ctx_r1.faixaCor(ctx_r1.aluno().faixaAtualCor))("border", "1px solid " + ctx_r1.faixaCor(ctx_r1.aluno().faixaAtualCor) + "55");
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1(" ", ctx_r1.aluno().faixaAtualNome, " ");
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_22_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275element(0, "app-nivel-badge", 22);
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(2);
    \u0275\u0275property("nivel", ctx_r1.perfil().nivel);
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_23_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "p", 23);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(2);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(ctx_r1.aluno().email);
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_35_Conditional_45_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 50)(1, "span", 51);
    \u0275\u0275text(2, "Telefone");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "span", 52);
    \u0275\u0275text(4);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(3);
    \u0275\u0275advance(4);
    \u0275\u0275textInterpolate(ctx_r1.aluno().telefone);
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_35_Conditional_46_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 50)(1, "span", 51);
    \u0275\u0275text(2, "Data de nascimento");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "span", 52);
    \u0275\u0275text(4);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(3);
    \u0275\u0275advance(4);
    \u0275\u0275textInterpolate(ctx_r1.formatarData(ctx_r1.aluno().dataNascimento));
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_35_Conditional_47_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 50)(1, "span", 51);
    \u0275\u0275text(2, "Tipo de plano");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "span", 52);
    \u0275\u0275text(4);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(3);
    \u0275\u0275advance(4);
    \u0275\u0275textInterpolate(ctx_r1.aluno().tipoPlano);
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_35_Conditional_48_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 50)(1, "span", 51);
    \u0275\u0275text(2, "Contato de emerg\xEAncia");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "span", 52);
    \u0275\u0275text(4);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(3);
    \u0275\u0275advance(4);
    \u0275\u0275textInterpolate2("", ctx_r1.aluno().contatoEmergenciaNome, "", ctx_r1.aluno().contatoEmergenciaTelefone ? " \xB7 " + ctx_r1.aluno().contatoEmergenciaTelefone : "", "");
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_35_Conditional_49_For_5_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 20);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const t_r4 = ctx.$implicit;
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(t_r4);
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_35_Conditional_49_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 47)(1, "h3", 48);
    \u0275\u0275text(2, "Turmas vinculadas");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "div", 53);
    \u0275\u0275repeaterCreate(4, AlunoDetalheComponent_Conditional_2_Conditional_35_Conditional_49_For_5_Template, 2, 1, "span", 20, \u0275\u0275repeaterTrackByIdentity);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(3);
    \u0275\u0275advance(4);
    \u0275\u0275repeater(ctx_r1.aluno().turmas);
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_35_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 26)(1, "div", 30)(2, "div", 31)(3, "div", 32);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(4, "svg", 33);
    \u0275\u0275element(5, "path", 34)(6, "circle", 35);
    \u0275\u0275elementEnd()();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(7, "div")(8, "div", 36);
    \u0275\u0275text(9, "Turmas");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(10, "div", 37);
    \u0275\u0275text(11);
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(12, "div", 31)(13, "div", 38);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(14, "svg", 33);
    \u0275\u0275element(15, "circle", 39)(16, "path", 40);
    \u0275\u0275elementEnd()();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(17, "div")(18, "div", 36);
    \u0275\u0275text(19, "Faixa atual");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(20, "div", 41);
    \u0275\u0275text(21);
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(22, "div", 31)(23, "div", 42);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(24, "svg", 33);
    \u0275\u0275element(25, "polygon", 43);
    \u0275\u0275elementEnd()();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(26, "div")(27, "div", 36);
    \u0275\u0275text(28, "XP Total");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(29, "div", 37);
    \u0275\u0275text(30);
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(31, "div", 31)(32, "div", 44);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(33, "svg", 33);
    \u0275\u0275element(34, "path", 45)(35, "polyline", 46);
    \u0275\u0275elementEnd()();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(36, "div")(37, "div", 36);
    \u0275\u0275text(38, "N\xEDvel");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(39, "div", 41);
    \u0275\u0275text(40);
    \u0275\u0275elementEnd()()()();
    \u0275\u0275elementStart(41, "div", 47)(42, "h3", 48);
    \u0275\u0275text(43, "Dados pessoais");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(44, "div", 49);
    \u0275\u0275template(45, AlunoDetalheComponent_Conditional_2_Conditional_35_Conditional_45_Template, 5, 1, "div", 50)(46, AlunoDetalheComponent_Conditional_2_Conditional_35_Conditional_46_Template, 5, 1, "div", 50)(47, AlunoDetalheComponent_Conditional_2_Conditional_35_Conditional_47_Template, 5, 1, "div", 50)(48, AlunoDetalheComponent_Conditional_2_Conditional_35_Conditional_48_Template, 5, 2, "div", 50);
    \u0275\u0275elementEnd()();
    \u0275\u0275template(49, AlunoDetalheComponent_Conditional_2_Conditional_35_Conditional_49_Template, 6, 0, "div", 47);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    let tmp_3_0;
    const ctx_r1 = \u0275\u0275nextContext(2);
    \u0275\u0275advance(11);
    \u0275\u0275textInterpolate(ctx_r1.aluno().turmas.length);
    \u0275\u0275advance(10);
    \u0275\u0275textInterpolate((tmp_3_0 = ctx_r1.aluno().faixaAtualNome) !== null && tmp_3_0 !== void 0 ? tmp_3_0 : "\u2014");
    \u0275\u0275advance(9);
    \u0275\u0275textInterpolate(ctx_r1.aluno().xpTotal);
    \u0275\u0275advance(10);
    \u0275\u0275textInterpolate(ctx_r1.aluno().nivel);
    \u0275\u0275advance(5);
    \u0275\u0275conditional(45, ctx_r1.aluno().telefone ? 45 : -1);
    \u0275\u0275advance();
    \u0275\u0275conditional(46, ctx_r1.aluno().dataNascimento ? 46 : -1);
    \u0275\u0275advance();
    \u0275\u0275conditional(47, ctx_r1.aluno().tipoPlano ? 47 : -1);
    \u0275\u0275advance();
    \u0275\u0275conditional(48, ctx_r1.aluno().contatoEmergenciaNome ? 48 : -1);
    \u0275\u0275advance();
    \u0275\u0275conditional(49, ctx_r1.aluno().turmas.length > 0 ? 49 : -1);
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_36_Conditional_12_For_2_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275element(0, "div", 3);
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_36_Conditional_12_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 2);
    \u0275\u0275repeaterCreate(1, AlunoDetalheComponent_Conditional_2_Conditional_36_Conditional_12_For_2_Template, 1, 0, "div", 3, \u0275\u0275repeaterTrackByIdentity);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    \u0275\u0275advance();
    \u0275\u0275repeater(\u0275\u0275pureFunction0(0, _c2));
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_36_Conditional_13_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 59)(1, "p");
    \u0275\u0275text(2, "Nenhuma presen\xE7a encontrada no per\xEDodo.");
    \u0275\u0275elementEnd()();
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_36_Conditional_14_For_6_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 64)(1, "div", 65);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(2, "svg", 66);
    \u0275\u0275element(3, "polyline", 67);
    \u0275\u0275elementEnd()();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(4, "div", 68)(5, "div", 62);
    \u0275\u0275text(6);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(7, "div", 69);
    \u0275\u0275text(8);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(9, "div", 70);
    \u0275\u0275text(10);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const p_r6 = ctx.$implicit;
    const ctx_r1 = \u0275\u0275nextContext(4);
    \u0275\u0275advance(6);
    \u0275\u0275textInterpolate(p_r6.nomeTurma);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(p_r6.horaCheckin ? p_r6.horaCheckin.substring(0, 5) : "");
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(ctx_r1.formatarData(p_r6.data));
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_36_Conditional_14_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 60)(1, "div", 61)(2, "span", 62);
    \u0275\u0275text(3);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(4, "div", 63);
    \u0275\u0275repeaterCreate(5, AlunoDetalheComponent_Conditional_2_Conditional_36_Conditional_14_For_6_Template, 11, 3, "div", 64, _forTrack0);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(3);
    \u0275\u0275advance(3);
    \u0275\u0275textInterpolate2("", ctx_r1.presencas().length, " presen\xE7a", ctx_r1.presencas().length !== 1 ? "s" : "", "");
    \u0275\u0275advance(2);
    \u0275\u0275repeater(ctx_r1.presencas());
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_36_Template(rf, ctx) {
  if (rf & 1) {
    const _r5 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 26)(1, "div", 54)(2, "div", 55)(3, "label", 56);
    \u0275\u0275text(4, "De");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(5, "input", 57);
    \u0275\u0275listener("ngModelChange", function AlunoDetalheComponent_Conditional_2_Conditional_36_Template_input_ngModelChange_5_listener($event) {
      \u0275\u0275restoreView(_r5);
      const ctx_r1 = \u0275\u0275nextContext(2);
      return \u0275\u0275resetView(ctx_r1.presencasDe.set($event));
    });
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(6, "div", 55)(7, "label", 56);
    \u0275\u0275text(8, "At\xE9");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(9, "input", 57);
    \u0275\u0275listener("ngModelChange", function AlunoDetalheComponent_Conditional_2_Conditional_36_Template_input_ngModelChange_9_listener($event) {
      \u0275\u0275restoreView(_r5);
      const ctx_r1 = \u0275\u0275nextContext(2);
      return \u0275\u0275resetView(ctx_r1.presencasAte.set($event));
    });
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(10, "button", 58);
    \u0275\u0275listener("click", function AlunoDetalheComponent_Conditional_2_Conditional_36_Template_button_click_10_listener() {
      \u0275\u0275restoreView(_r5);
      const ctx_r1 = \u0275\u0275nextContext(2);
      return \u0275\u0275resetView(ctx_r1.carregarPresencas(ctx_r1.aluno().id));
    });
    \u0275\u0275text(11, "Filtrar");
    \u0275\u0275elementEnd()();
    \u0275\u0275template(12, AlunoDetalheComponent_Conditional_2_Conditional_36_Conditional_12_Template, 3, 1, "div", 2)(13, AlunoDetalheComponent_Conditional_2_Conditional_36_Conditional_13_Template, 3, 0)(14, AlunoDetalheComponent_Conditional_2_Conditional_36_Conditional_14_Template, 7, 2);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(2);
    \u0275\u0275advance(5);
    \u0275\u0275property("ngModel", ctx_r1.presencasDe());
    \u0275\u0275advance(4);
    \u0275\u0275property("ngModel", ctx_r1.presencasAte());
    \u0275\u0275advance(3);
    \u0275\u0275conditional(12, ctx_r1.carregandoPresencas() ? 12 : ctx_r1.presencas().length === 0 ? 13 : 14);
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_37_Conditional_1_For_2_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275element(0, "div", 3);
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_37_Conditional_1_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 2);
    \u0275\u0275repeaterCreate(1, AlunoDetalheComponent_Conditional_2_Conditional_37_Conditional_1_For_2_Template, 1, 0, "div", 3, \u0275\u0275repeaterTrackByIdentity);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    \u0275\u0275advance();
    \u0275\u0275repeater(\u0275\u0275pureFunction0(0, _c2));
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_37_Conditional_2_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 59)(1, "p");
    \u0275\u0275text(2, "Nenhum pagamento registrado para este aluno.");
    \u0275\u0275elementEnd()();
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_37_Conditional_3_For_37_Conditional_6_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275text(0);
  }
  if (rf & 2) {
    const p_r7 = \u0275\u0275nextContext().$implicit;
    const ctx_r1 = \u0275\u0275nextContext(4);
    \u0275\u0275textInterpolate1(" \xB7 Pago: ", ctx_r1.formatarData(p_r7.dataPagamento), " ");
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_37_Conditional_3_For_37_Conditional_7_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275text(0);
  }
  if (rf & 2) {
    const p_r7 = \u0275\u0275nextContext().$implicit;
    \u0275\u0275textInterpolate1(" \xB7 ", p_r7.formaPagamento, " ");
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_37_Conditional_3_For_37_Conditional_13_Template(rf, ctx) {
  if (rf & 1) {
    const _r8 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "button", 87);
    \u0275\u0275listener("click", function AlunoDetalheComponent_Conditional_2_Conditional_37_Conditional_3_For_37_Conditional_13_Template_button_click_0_listener() {
      \u0275\u0275restoreView(_r8);
      const p_r7 = \u0275\u0275nextContext().$implicit;
      const ctx_r1 = \u0275\u0275nextContext(4);
      return \u0275\u0275resetView(ctx_r1.marcarPagamentoPago(p_r7));
    });
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(1, "svg", 88);
    \u0275\u0275element(2, "polyline", 67);
    \u0275\u0275elementEnd();
    \u0275\u0275text(3, " Pagar ");
    \u0275\u0275elementEnd();
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_37_Conditional_3_For_37_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 80)(1, "div", 81)(2, "div", 62);
    \u0275\u0275text(3);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(4, "div", 82);
    \u0275\u0275text(5);
    \u0275\u0275template(6, AlunoDetalheComponent_Conditional_2_Conditional_37_Conditional_3_For_37_Conditional_6_Template, 1, 1)(7, AlunoDetalheComponent_Conditional_2_Conditional_37_Conditional_3_For_37_Conditional_7_Template, 1, 1);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(8, "div", 83)(9, "span", 84);
    \u0275\u0275text(10);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(11, "span", 85);
    \u0275\u0275text(12);
    \u0275\u0275elementEnd();
    \u0275\u0275template(13, AlunoDetalheComponent_Conditional_2_Conditional_37_Conditional_3_For_37_Conditional_13_Template, 4, 0, "button", 86);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const p_r7 = ctx.$implicit;
    const ctx_r1 = \u0275\u0275nextContext(4);
    \u0275\u0275advance(3);
    \u0275\u0275textInterpolate(p_r7.descricao || p_r7.tipo);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate1(" Venc: ", ctx_r1.formatarData(p_r7.dataVencimento), " ");
    \u0275\u0275advance();
    \u0275\u0275conditional(6, p_r7.dataPagamento ? 6 : -1);
    \u0275\u0275advance();
    \u0275\u0275conditional(7, p_r7.formaPagamento ? 7 : -1);
    \u0275\u0275advance(2);
    \u0275\u0275classMap(ctx_r1.badgeStatusPag(p_r7.status));
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(p_r7.status);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(ctx_r1.formatarMoeda(p_r7.valor));
    \u0275\u0275advance();
    \u0275\u0275conditional(13, p_r7.status === "Pendente" || p_r7.status === "Atrasado" ? 13 : -1);
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_37_Conditional_3_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 71)(1, "div", 31)(2, "div", 44);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(3, "svg", 33);
    \u0275\u0275element(4, "polyline", 67);
    \u0275\u0275elementEnd()();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(5, "div")(6, "div", 36);
    \u0275\u0275text(7, "Total pago");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(8, "div", 72);
    \u0275\u0275text(9);
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(10, "div", 31)(11, "div", 42);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(12, "svg", 33);
    \u0275\u0275element(13, "circle", 73)(14, "polyline", 74);
    \u0275\u0275elementEnd()();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(15, "div")(16, "div", 36);
    \u0275\u0275text(17, "Pendente");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(18, "div", 72);
    \u0275\u0275text(19);
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(20, "div", 31)(21, "div", 75);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(22, "svg", 33);
    \u0275\u0275element(23, "circle", 73)(24, "line", 76)(25, "line", 77);
    \u0275\u0275elementEnd()();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(26, "div")(27, "div", 36);
    \u0275\u0275text(28, "Em atraso");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(29, "div", 72);
    \u0275\u0275text(30);
    \u0275\u0275elementEnd()()()();
    \u0275\u0275elementStart(31, "div", 60)(32, "div", 78)(33, "span", 62);
    \u0275\u0275text(34, "Hist\xF3rico de pagamentos");
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(35, "div", 79);
    \u0275\u0275repeaterCreate(36, AlunoDetalheComponent_Conditional_2_Conditional_37_Conditional_3_For_37_Template, 14, 9, "div", 80, _forTrack0);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(3);
    \u0275\u0275advance(9);
    \u0275\u0275textInterpolate(ctx_r1.formatarMoeda(ctx_r1.totalPago()));
    \u0275\u0275advance(10);
    \u0275\u0275textInterpolate(ctx_r1.formatarMoeda(ctx_r1.totalPendente()));
    \u0275\u0275advance(11);
    \u0275\u0275textInterpolate(ctx_r1.formatarMoeda(ctx_r1.totalAtrasado()));
    \u0275\u0275advance(6);
    \u0275\u0275repeater(ctx_r1.pagamentos());
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_37_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 26);
    \u0275\u0275template(1, AlunoDetalheComponent_Conditional_2_Conditional_37_Conditional_1_Template, 3, 1, "div", 2)(2, AlunoDetalheComponent_Conditional_2_Conditional_37_Conditional_2_Template, 3, 0)(3, AlunoDetalheComponent_Conditional_2_Conditional_37_Conditional_3_Template, 38, 3);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(2);
    \u0275\u0275advance();
    \u0275\u0275conditional(1, ctx_r1.carregandoPagamentos() ? 1 : ctx_r1.pagamentos().length === 0 ? 2 : 3);
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_38_Conditional_1_For_2_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275element(0, "div", 3);
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_38_Conditional_1_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 2);
    \u0275\u0275repeaterCreate(1, AlunoDetalheComponent_Conditional_2_Conditional_38_Conditional_1_For_2_Template, 1, 0, "div", 3, \u0275\u0275repeaterTrackByIdentity);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    \u0275\u0275advance();
    \u0275\u0275repeater(\u0275\u0275pureFunction0(0, _c0));
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_38_Conditional_2_Conditional_38_For_5_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 93)(1, "span");
    \u0275\u0275text(2);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "span", 94);
    \u0275\u0275text(4);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const c_r9 = ctx.$implicit;
    \u0275\u0275property("title", c_r9.descricao);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(c_r9.iconeUrl);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(c_r9.nome);
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_38_Conditional_2_Conditional_38_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 92)(1, "h3", 48);
    \u0275\u0275text(2);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "div", 53);
    \u0275\u0275repeaterCreate(4, AlunoDetalheComponent_Conditional_2_Conditional_38_Conditional_2_Conditional_38_For_5_Template, 5, 3, "div", 93, _forTrack0);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(4);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate1("Conquistas (", ctx_r1.perfil().conquistasDesbloqueadas.length, ")");
    \u0275\u0275advance(2);
    \u0275\u0275repeater(ctx_r1.perfil().conquistasDesbloqueadas);
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_38_Conditional_2_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 30)(1, "div", 31)(2, "div", 32);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(3, "svg", 33);
    \u0275\u0275element(4, "polyline", 89);
    \u0275\u0275elementEnd()();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(5, "div")(6, "div", 36);
    \u0275\u0275text(7, "Posi\xE7\xE3o global");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(8, "div", 37);
    \u0275\u0275text(9);
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(10, "div", 31)(11, "div", 90);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(12, "svg", 33);
    \u0275\u0275element(13, "path", 34)(14, "circle", 35);
    \u0275\u0275elementEnd()();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(15, "div")(16, "div", 36);
    \u0275\u0275text(17, "Posi\xE7\xE3o na turma");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(18, "div", 37);
    \u0275\u0275text(19);
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(20, "div", 31)(21, "div", 42);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(22, "svg", 33);
    \u0275\u0275element(23, "polygon", 43);
    \u0275\u0275elementEnd()();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(24, "div")(25, "div", 36);
    \u0275\u0275text(26, "XP este m\xEAs");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(27, "div", 37);
    \u0275\u0275text(28);
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(29, "div", 31)(30, "div", 75);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(31, "svg", 33);
    \u0275\u0275element(32, "path", 91);
    \u0275\u0275elementEnd()();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(33, "div")(34, "div", 36);
    \u0275\u0275text(35, "Sequ\xEAncia");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(36, "div", 37);
    \u0275\u0275text(37);
    \u0275\u0275elementEnd()()()();
    \u0275\u0275template(38, AlunoDetalheComponent_Conditional_2_Conditional_38_Conditional_2_Conditional_38_Template, 6, 1, "div", 92);
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(3);
    \u0275\u0275advance(9);
    \u0275\u0275textInterpolate1("#", ctx_r1.perfil().posicaoGlobal, "");
    \u0275\u0275advance(10);
    \u0275\u0275textInterpolate(ctx_r1.perfil().posicaoTurma > 0 ? "#" + ctx_r1.perfil().posicaoTurma : "\u2014");
    \u0275\u0275advance(9);
    \u0275\u0275textInterpolate(ctx_r1.perfil().xpMensal);
    \u0275\u0275advance(9);
    \u0275\u0275textInterpolate1("", ctx_r1.perfil().sequenciaAtual, " dias");
    \u0275\u0275advance();
    \u0275\u0275conditional(38, ctx_r1.perfil().conquistasDesbloqueadas.length > 0 ? 38 : -1);
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_38_Conditional_3_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 59)(1, "p");
    \u0275\u0275text(2, "Dados de ranking n\xE3o dispon\xEDveis.");
    \u0275\u0275elementEnd()();
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_38_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 26);
    \u0275\u0275template(1, AlunoDetalheComponent_Conditional_2_Conditional_38_Conditional_1_Template, 3, 1, "div", 2)(2, AlunoDetalheComponent_Conditional_2_Conditional_38_Conditional_2_Template, 39, 5)(3, AlunoDetalheComponent_Conditional_2_Conditional_38_Conditional_3_Template, 3, 0);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(2);
    \u0275\u0275advance();
    \u0275\u0275conditional(1, ctx_r1.carregandoPerfil() ? 1 : ctx_r1.perfil() ? 2 : 3);
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_39_Conditional_9_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 100);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(3);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(ctx_r1.erroContratos());
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_39_Conditional_10_For_2_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275element(0, "div", 101);
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_39_Conditional_10_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 2);
    \u0275\u0275repeaterCreate(1, AlunoDetalheComponent_Conditional_2_Conditional_39_Conditional_10_For_2_Template, 1, 0, "div", 101, \u0275\u0275repeaterTrackByIdentity);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    \u0275\u0275advance();
    \u0275\u0275repeater(\u0275\u0275pureFunction0(0, _c3));
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_39_Conditional_11_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 59)(1, "p", 102);
    \u0275\u0275text(2, "Nenhum contrato vinculado a este aluno.");
    \u0275\u0275elementEnd()();
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_39_Conditional_12_For_13_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "tr")(1, "td")(2, "span", 105);
    \u0275\u0275text(3);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(4, "td", 106);
    \u0275\u0275text(5);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(6, "td", 106);
    \u0275\u0275text(7);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(8, "td", 107)(9, "a", 108);
    \u0275\u0275text(10, "Ver contrato");
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    let tmp_16_0;
    const c_r11 = ctx.$implicit;
    const ctx_r1 = \u0275\u0275nextContext(4);
    \u0275\u0275advance(2);
    \u0275\u0275property("ngClass", ctx_r1.badgeClassContrato(c_r11.status));
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(c_r11.statusLabel);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(ctx_r1.formatarData(c_r11.criadoEm));
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate((tmp_16_0 = c_r11.nomeAssinou) !== null && tmp_16_0 !== void 0 ? tmp_16_0 : "\u2014");
    \u0275\u0275advance(2);
    \u0275\u0275property("routerLink", \u0275\u0275pureFunction1(5, _c4, c_r11.id));
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_39_Conditional_12_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 103)(1, "table", 104)(2, "thead")(3, "tr")(4, "th");
    \u0275\u0275text(5, "Status");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(6, "th");
    \u0275\u0275text(7, "Criado em");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(8, "th");
    \u0275\u0275text(9, "Assinado por");
    \u0275\u0275elementEnd();
    \u0275\u0275element(10, "th");
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(11, "tbody");
    \u0275\u0275repeaterCreate(12, AlunoDetalheComponent_Conditional_2_Conditional_39_Conditional_12_For_13_Template, 11, 7, "tr", null, _forTrack0);
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(3);
    \u0275\u0275advance(12);
    \u0275\u0275repeater(ctx_r1.contratos());
  }
}
function AlunoDetalheComponent_Conditional_2_Conditional_39_Template(rf, ctx) {
  if (rf & 1) {
    const _r10 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 26)(1, "div", 95)(2, "span", 70);
    \u0275\u0275text(3);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(4, "button", 96);
    \u0275\u0275listener("click", function AlunoDetalheComponent_Conditional_2_Conditional_39_Template_button_click_4_listener() {
      \u0275\u0275restoreView(_r10);
      const ctx_r1 = \u0275\u0275nextContext(2);
      return \u0275\u0275resetView(ctx_r1.criarContratoParaAluno());
    });
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(5, "svg", 97);
    \u0275\u0275element(6, "line", 98)(7, "line", 99);
    \u0275\u0275elementEnd();
    \u0275\u0275text(8);
    \u0275\u0275elementEnd()();
    \u0275\u0275template(9, AlunoDetalheComponent_Conditional_2_Conditional_39_Conditional_9_Template, 2, 1, "div", 100)(10, AlunoDetalheComponent_Conditional_2_Conditional_39_Conditional_10_Template, 3, 1, "div", 2)(11, AlunoDetalheComponent_Conditional_2_Conditional_39_Conditional_11_Template, 3, 0)(12, AlunoDetalheComponent_Conditional_2_Conditional_39_Conditional_12_Template, 14, 0);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(2);
    \u0275\u0275advance(3);
    \u0275\u0275textInterpolate1("", ctx_r1.contratos().length, " contrato(s) vinculado(s)");
    \u0275\u0275advance();
    \u0275\u0275property("disabled", ctx_r1.criandoContrato());
    \u0275\u0275advance(4);
    \u0275\u0275textInterpolate1(" ", ctx_r1.criandoContrato() ? "Gerando..." : "Gerar contrato", " ");
    \u0275\u0275advance();
    \u0275\u0275conditional(9, ctx_r1.erroContratos() ? 9 : -1);
    \u0275\u0275advance();
    \u0275\u0275conditional(10, ctx_r1.carregandoContratos() ? 10 : ctx_r1.contratos().length === 0 ? 11 : 12);
  }
}
function AlunoDetalheComponent_Conditional_2_Template(rf, ctx) {
  if (rf & 1) {
    const _r3 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 0)(1, "div", 6)(2, "button", 7);
    \u0275\u0275listener("click", function AlunoDetalheComponent_Conditional_2_Template_button_click_2_listener() {
      \u0275\u0275restoreView(_r3);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.voltar());
    });
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(3, "svg", 8);
    \u0275\u0275element(4, "polyline", 9);
    \u0275\u0275elementEnd();
    \u0275\u0275text(5, " Voltar para Alunos ");
    \u0275\u0275elementEnd();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(6, "div", 10);
    \u0275\u0275template(7, AlunoDetalheComponent_Conditional_2_Conditional_7_Template, 4, 1, "a", 11);
    \u0275\u0275elementStart(8, "a", 12);
    \u0275\u0275text(9, "Editar aluno");
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(10, "div", 13)(11, "div", 14);
    \u0275\u0275text(12);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(13, "div", 15)(14, "div", 16)(15, "h1", 17);
    \u0275\u0275text(16);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(17, "span", 18);
    \u0275\u0275text(18);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(19, "div", 19);
    \u0275\u0275template(20, AlunoDetalheComponent_Conditional_2_Conditional_20_Template, 2, 1, "span", 20)(21, AlunoDetalheComponent_Conditional_2_Conditional_21_Template, 2, 7, "span", 21)(22, AlunoDetalheComponent_Conditional_2_Conditional_22_Template, 1, 1, "app-nivel-badge", 22);
    \u0275\u0275elementEnd();
    \u0275\u0275template(23, AlunoDetalheComponent_Conditional_2_Conditional_23_Template, 2, 1, "p", 23);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(24, "div", 24)(25, "button", 25);
    \u0275\u0275listener("click", function AlunoDetalheComponent_Conditional_2_Template_button_click_25_listener() {
      \u0275\u0275restoreView(_r3);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.tabAtiva.set("info"));
    });
    \u0275\u0275text(26, "Informa\xE7\xF5es");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(27, "button", 25);
    \u0275\u0275listener("click", function AlunoDetalheComponent_Conditional_2_Template_button_click_27_listener() {
      \u0275\u0275restoreView(_r3);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.tabAtiva.set("presencas"));
    });
    \u0275\u0275text(28, "Presen\xE7as");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(29, "button", 25);
    \u0275\u0275listener("click", function AlunoDetalheComponent_Conditional_2_Template_button_click_29_listener() {
      \u0275\u0275restoreView(_r3);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.tabAtiva.set("financeiro"));
    });
    \u0275\u0275text(30, "Financeiro");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(31, "button", 25);
    \u0275\u0275listener("click", function AlunoDetalheComponent_Conditional_2_Template_button_click_31_listener() {
      \u0275\u0275restoreView(_r3);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.tabAtiva.set("ranking"));
    });
    \u0275\u0275text(32, "Ranking & XP");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(33, "button", 25);
    \u0275\u0275listener("click", function AlunoDetalheComponent_Conditional_2_Template_button_click_33_listener() {
      \u0275\u0275restoreView(_r3);
      const ctx_r1 = \u0275\u0275nextContext();
      ctx_r1.tabAtiva.set("contratos");
      return \u0275\u0275resetView(ctx_r1.carregarContratos(ctx_r1.aluno().id));
    });
    \u0275\u0275text(34, "Contratos");
    \u0275\u0275elementEnd()();
    \u0275\u0275template(35, AlunoDetalheComponent_Conditional_2_Conditional_35_Template, 50, 9, "div", 26)(36, AlunoDetalheComponent_Conditional_2_Conditional_36_Template, 15, 3, "div", 26)(37, AlunoDetalheComponent_Conditional_2_Conditional_37_Template, 4, 1, "div", 26)(38, AlunoDetalheComponent_Conditional_2_Conditional_38_Template, 4, 1, "div", 26)(39, AlunoDetalheComponent_Conditional_2_Conditional_39_Template, 13, 5, "div", 26);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext();
    \u0275\u0275advance(7);
    \u0275\u0275conditional(7, ctx_r1.aluno().telefone ? 7 : -1);
    \u0275\u0275advance();
    \u0275\u0275property("routerLink", \u0275\u0275pureFunction1(26, _c1, ctx_r1.aluno().id));
    \u0275\u0275advance(4);
    \u0275\u0275textInterpolate(ctx_r1.avatarInicial(ctx_r1.aluno().nome));
    \u0275\u0275advance(4);
    \u0275\u0275textInterpolate(ctx_r1.aluno().nome);
    \u0275\u0275advance();
    \u0275\u0275classProp("ativo", ctx_r1.aluno().ativo);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(ctx_r1.aluno().ativo ? "Ativo" : "Inativo");
    \u0275\u0275advance(2);
    \u0275\u0275conditional(20, ctx_r1.aluno().matricula ? 20 : -1);
    \u0275\u0275advance();
    \u0275\u0275conditional(21, ctx_r1.aluno().faixaAtualNome ? 21 : -1);
    \u0275\u0275advance();
    \u0275\u0275conditional(22, ctx_r1.perfil() ? 22 : -1);
    \u0275\u0275advance();
    \u0275\u0275conditional(23, ctx_r1.aluno().email ? 23 : -1);
    \u0275\u0275advance(2);
    \u0275\u0275classProp("active", ctx_r1.tabAtiva() === "info");
    \u0275\u0275advance(2);
    \u0275\u0275classProp("active", ctx_r1.tabAtiva() === "presencas");
    \u0275\u0275advance(2);
    \u0275\u0275classProp("active", ctx_r1.tabAtiva() === "financeiro");
    \u0275\u0275advance(2);
    \u0275\u0275classProp("active", ctx_r1.tabAtiva() === "ranking");
    \u0275\u0275advance(2);
    \u0275\u0275classProp("active", ctx_r1.tabAtiva() === "contratos");
    \u0275\u0275advance(2);
    \u0275\u0275conditional(35, ctx_r1.tabAtiva() === "info" ? 35 : -1);
    \u0275\u0275advance();
    \u0275\u0275conditional(36, ctx_r1.tabAtiva() === "presencas" ? 36 : -1);
    \u0275\u0275advance();
    \u0275\u0275conditional(37, ctx_r1.tabAtiva() === "financeiro" ? 37 : -1);
    \u0275\u0275advance();
    \u0275\u0275conditional(38, ctx_r1.tabAtiva() === "ranking" ? 38 : -1);
    \u0275\u0275advance();
    \u0275\u0275conditional(39, ctx_r1.tabAtiva() === "contratos" ? 39 : -1);
  }
}
var AlunoDetalheComponent = class _AlunoDetalheComponent {
  constructor() {
    this.alunoService = inject(AlunoService);
    this.presencaService = inject(PresencaService);
    this.rankingService = inject(RankingService);
    this.financeiroService = inject(FinanceiroService);
    this.contratoService = inject(ContratoService);
    this.route = inject(ActivatedRoute);
    this.router = inject(Router);
    this.aluno = signal(null);
    this.perfil = signal(null);
    this.presencas = signal([]);
    this.pagamentos = signal([]);
    this.carregando = signal(true);
    this.carregandoPerfil = signal(false);
    this.carregandoPresencas = signal(false);
    this.carregandoPagamentos = signal(false);
    this.contratos = signal([]);
    this.carregandoContratos = signal(false);
    this.erroContratos = signal("");
    this.modalNovoContratoAberto = signal(false);
    this.criandoContrato = signal(false);
    this.erro = signal("");
    this.tabAtiva = signal("info");
    this.presencasDe = signal(this.primeiroDiaMes());
    this.presencasAte = signal((/* @__PURE__ */ new Date()).toISOString().split("T")[0]);
    this.totalPago = computed(() => this.pagamentos().filter((p) => p.status === "Pago").reduce((s, p) => s + p.valor, 0));
    this.totalPendente = computed(() => this.pagamentos().filter((p) => p.status === "Pendente").reduce((s, p) => s + p.valor, 0));
    this.totalAtrasado = computed(() => this.pagamentos().filter((p) => p.status === "Atrasado").reduce((s, p) => s + p.valor, 0));
  }
  ngOnInit() {
    const id = this.route.snapshot.paramMap.get("id");
    this.alunoService.getById(id).subscribe({
      next: (res) => {
        this.aluno.set(res.dados ?? null);
        this.carregando.set(false);
        if (res.dados) {
          this.carregarPerfil(id);
          this.carregarPresencas(id);
          this.carregarPagamentos(id);
        }
      },
      error: () => {
        this.erro.set("Aluno n\xE3o encontrado.");
        this.carregando.set(false);
      }
    });
  }
  carregarPerfil(id) {
    this.carregandoPerfil.set(true);
    this.rankingService.getPerfilGamificado(id).subscribe({
      next: (p) => {
        this.perfil.set(p);
        this.carregandoPerfil.set(false);
      },
      error: () => this.carregandoPerfil.set(false)
    });
  }
  carregarPresencas(id) {
    this.carregandoPresencas.set(true);
    this.presencaService.getHistorico(id, this.presencasDe(), this.presencasAte()).subscribe({
      next: (res) => {
        this.presencas.set(res.dados ?? []);
        this.carregandoPresencas.set(false);
      },
      error: () => this.carregandoPresencas.set(false)
    });
  }
  carregarPagamentos(id) {
    this.carregandoPagamentos.set(true);
    this.financeiroService.listarPorAluno(id).subscribe({
      next: (res) => {
        this.pagamentos.set(res.dados ?? []);
        this.carregandoPagamentos.set(false);
      },
      error: () => this.carregandoPagamentos.set(false)
    });
  }
  marcarPagamentoPago(p) {
    const hoje = (/* @__PURE__ */ new Date()).toISOString().split("T")[0];
    this.financeiroService.atualizar(p.id, { status: 1, dataPagamento: hoje }).subscribe({
      next: () => this.carregarPagamentos(this.aluno().id)
    });
  }
  wppLink(telefone) {
    return `https://wa.me/55${telefone.replace(/\D/g, "")}`;
  }
  carregarContratos(alunoId) {
    this.carregandoContratos.set(true);
    this.contratoService.listar(alunoId).subscribe({
      next: (res) => {
        this.contratos.set(res.dados ?? []);
        this.carregandoContratos.set(false);
      },
      error: () => {
        this.erroContratos.set("Erro ao carregar contratos.");
        this.carregandoContratos.set(false);
      }
    });
  }
  criarContratoParaAluno() {
    const id = this.aluno()?.id;
    if (!id)
      return;
    this.criandoContrato.set(true);
    this.contratoService.criar({ alunoId: id }).subscribe({
      next: (res) => {
        this.criandoContrato.set(false);
        if (res.sucesso) {
          this.carregarContratos(id);
          this.modalNovoContratoAberto.set(false);
        }
      },
      error: () => this.criandoContrato.set(false)
    });
  }
  badgeClassContrato(status) {
    if (status === 2)
      return "badge-ct-assinado";
    if (status === 3)
      return "badge-ct-cancelado";
    return "badge-ct-pendente";
  }
  voltar() {
    this.router.navigate(["/app/alunos"]);
  }
  avatarInicial(nome) {
    return (nome ?? "A").charAt(0).toUpperCase();
  }
  faixaCor(cor) {
    const map = {
      branca: "#e2e8f0",
      cinza: "#94a3b8",
      azul: "#3b82f6",
      roxa: "#a855f7",
      marrom: "#92400e",
      preta: "#1e293b"
    };
    return map[cor?.toLowerCase() ?? ""] ?? "#6366f1";
  }
  formatarData(d) {
    if (!d)
      return "\u2014";
    const [y, m, day] = d.split("-");
    return `${day}/${m}/${y}`;
  }
  formatarMoeda(valor) {
    return valor.toLocaleString("pt-BR", { style: "currency", currency: "BRL" });
  }
  badgeStatusPag(status) {
    const map = {
      Pago: "badge-pag-pago",
      Pendente: "badge-pag-pendente",
      Atrasado: "badge-pag-atrasado",
      Cancelado: "badge-pag-cancelado"
    };
    return map[status] ?? "";
  }
  primeiroDiaMes() {
    const now = /* @__PURE__ */ new Date();
    return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-01`;
  }
  static {
    this.\u0275fac = function AlunoDetalheComponent_Factory(t) {
      return new (t || _AlunoDetalheComponent)();
    };
  }
  static {
    this.\u0275cmp = /* @__PURE__ */ \u0275\u0275defineComponent({ type: _AlunoDetalheComponent, selectors: [["app-aluno-detalhe"]], standalone: true, features: [\u0275\u0275StandaloneFeature], decls: 3, vars: 1, consts: [[1, "page-container"], [1, "skeleton-header"], [1, "skeleton-list"], [1, "skeleton-row"], [1, "error-card"], [1, "btn-secondary", 2, "margin-top", "12px", 3, "click"], [2, "display", "flex", "align-items", "center", "justify-content", "space-between", "margin-bottom", "20px", "flex-wrap", "wrap", "gap", "10px"], [1, "btn-ghost-back", 3, "click"], ["width", "16", "height", "16", "fill", "none", "stroke", "currentColor", "stroke-width", "2", "viewBox", "0 0 24 24"], ["points", "15 18 9 12 15 6"], [2, "display", "flex", "gap", "8px", "align-items", "center", "flex-wrap", "wrap"], ["target", "_blank", "rel", "noopener", 1, "btn-wpp-contato", 3, "href"], [1, "btn-secondary", 3, "routerLink"], [1, "perfil-header"], [1, "perfil-avatar"], [1, "perfil-header-info"], [2, "display", "flex", "align-items", "center", "gap", "10px", "flex-wrap", "wrap"], [2, "font-size", "1.5rem", "font-weight", "700", "margin", "0", "color", "var(--app-text-1)"], [1, "status-badge"], [2, "display", "flex", "align-items", "center", "gap", "8px", "margin-top", "6px", "flex-wrap", "wrap"], [1, "info-chip"], [1, "faixa-chip", 3, "background", "color", "border"], [3, "nivel"], [2, "font-size", "13px", "color", "var(--app-text-3)", "margin", "6px 0 0"], [1, "tabs", 2, "margin-top", "24px"], [1, "tab", 3, "click"], [1, "tab-content"], ["width", "15", "height", "15", "viewBox", "0 0 24 24", "fill", "currentColor"], ["d", "M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"], [1, "faixa-chip"], [1, "info-cards-row"], [1, "info-card"], [1, "info-card-icon", 2, "background", "rgba(99,102,241,0.1)", "color", "#6366f1"], ["width", "18", "height", "18", "fill", "none", "stroke", "currentColor", "stroke-width", "2", "viewBox", "0 0 24 24"], ["d", "M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"], ["cx", "9", "cy", "7", "r", "4"], [1, "info-card-label"], [1, "info-card-value"], [1, "info-card-icon", 2, "background", "rgba(168,85,247,0.1)", "color", "#a855f7"], ["cx", "12", "cy", "8", "r", "6"], ["d", "M15.477 12.89L17 22l-5-3-5 3 1.523-9.11"], [1, "info-card-value", 2, "font-size", "14px"], [1, "info-card-icon", 2, "background", "rgba(245,158,11,0.1)", "color", "#f59e0b"], ["points", "12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"], [1, "info-card-icon", 2, "background", "rgba(34,197,94,0.1)", "color", "#22c55e"], ["d", "M22 11.08V12a10 10 0 1 1-5.93-9.14"], ["points", "22 4 12 14.01 9 11.01"], [1, "secao-card"], [1, "secao-titulo"], [1, "dados-grid"], [1, "dado-item"], [1, "dado-label"], [1, "dado-valor"], [2, "display", "flex", "flex-wrap", "wrap", "gap", "8px"], [2, "display", "flex", "align-items", "flex-end", "gap", "12px", "flex-wrap", "wrap", "margin-bottom", "16px"], [1, "form-group", 2, "margin", "0"], [1, "form-label"], ["type", "date", 1, "form-input", 2, "max-width", "160px", 3, "ngModelChange", "ngModel"], [1, "btn-secondary", 3, "click"], [1, "empty-state"], [1, "secao-card", 2, "padding", "0", "overflow", "hidden"], [2, "padding", "14px 16px", "border-bottom", "1px solid var(--app-border)", "display", "flex", "justify-content", "space-between", "align-items", "center"], [2, "font-size", "13px", "font-weight", "600", "color", "var(--app-text-1)"], [1, "presencas-lista-detalhe"], [1, "presenca-row"], [1, "presenca-check-icon"], ["width", "14", "height", "14", "fill", "none", "stroke", "#22c55e", "stroke-width", "2.5", "viewBox", "0 0 24 24"], ["points", "20 6 9 17 4 12"], [2, "flex", "1"], [2, "font-size", "12px", "color", "var(--app-text-3)"], [2, "font-size", "13px", "color", "var(--app-text-2)"], [1, "info-cards-row", 2, "margin-bottom", "16px"], [1, "info-card-value", 2, "font-size", "16px"], ["cx", "12", "cy", "12", "r", "10"], ["points", "12 6 12 12 16 14"], [1, "info-card-icon", 2, "background", "rgba(239,68,68,0.1)", "color", "#ef4444"], ["x1", "12", "y1", "8", "x2", "12", "y2", "12"], ["x1", "12", "y1", "16", "x2", "12.01", "y2", "16"], [2, "padding", "14px 16px", "border-bottom", "1px solid var(--app-border)"], [1, "pagamentos-lista"], [1, "pagamento-row"], [2, "flex", "1", "min-width", "0"], [2, "font-size", "12px", "color", "var(--app-text-3)", "margin-top", "2px"], [2, "display", "flex", "align-items", "center", "gap", "10px", "flex-shrink", "0"], [1, "badge-pag"], [2, "font-size", "14px", "font-weight", "700", "color", "var(--app-text-1)"], ["title", "Marcar como pago", 1, "btn-pagar-mini"], ["title", "Marcar como pago", 1, "btn-pagar-mini", 3, "click"], ["width", "13", "height", "13", "fill", "none", "stroke", "currentColor", "stroke-width", "2.5", "viewBox", "0 0 24 24"], ["points", "22 12 18 12 15 21 9 3 6 12 2 12"], [1, "info-card-icon", 2, "background", "rgba(59,130,246,0.1)", "color", "#3b82f6"], ["d", "M13 2L3 14h9l-1 8 10-12h-9l1-8z"], [1, "secao-card", 2, "margin-top", "16px"], [1, "conquista-chip", 3, "title"], [2, "font-size", "11px"], [2, "display", "flex", "align-items", "center", "justify-content", "space-between", "margin-bottom", "16px", "flex-wrap", "wrap", "gap", "10px"], [1, "btn-primary", 2, "font-size", "13px", 3, "click", "disabled"], ["width", "13", "height", "13", "fill", "none", "stroke", "currentColor", "stroke-width", "2", "viewBox", "0 0 24 24"], ["x1", "12", "y1", "5", "x2", "12", "y2", "19"], ["x1", "5", "y1", "12", "x2", "19", "y2", "12"], [1, "alert-error"], [1, "skeleton-row", 2, "height", "56px"], [2, "color", "var(--app-text-3)", "font-size", "13px", "margin", "0"], [1, "table-wrapper"], [1, "data-table"], [1, "badge-ct", 3, "ngClass"], [2, "font-size", "13px"], [2, "text-align", "right"], [1, "btn-secondary", 2, "font-size", "12px", "padding", "5px 10px", 3, "routerLink"]], template: function AlunoDetalheComponent_Template(rf, ctx) {
      if (rf & 1) {
        \u0275\u0275template(0, AlunoDetalheComponent_Conditional_0_Template, 5, 1, "div", 0)(1, AlunoDetalheComponent_Conditional_1_Template, 6, 1)(2, AlunoDetalheComponent_Conditional_2_Template, 40, 28);
      }
      if (rf & 2) {
        \u0275\u0275conditional(0, ctx.carregando() ? 0 : ctx.erro() || !ctx.aluno() ? 1 : 2);
      }
    }, dependencies: [CommonModule, NgClass, FormsModule, DefaultValueAccessor, NgControlStatus, NgModel, RouterLink, NivelBadgeComponent], styles: ["\n\n  .btn-ghost-back[_ngcontent-%COMP%] { display:inline-flex; align-items:center; gap:6px; background:none; border:none; cursor:pointer; font-size:13px; font-weight:500; color:var(--app-text-2); padding:6px 10px; border-radius:6px; transition:all 0.15s; }\n  .btn-ghost-back[_ngcontent-%COMP%]:hover { background:var(--app-border-light); color:var(--app-text-1); }\n\n  \n\n  .btn-wpp-contato[_ngcontent-%COMP%] { display:inline-flex; align-items:center; gap:7px; padding:7px 14px; border-radius:8px; background:rgba(37,211,102,0.12); color:#25d366; font-size:13px; font-weight:600; text-decoration:none; border:1px solid rgba(37,211,102,0.3); transition:all 0.15s; }\n  .btn-wpp-contato[_ngcontent-%COMP%]:hover { background:rgba(37,211,102,0.2); border-color:rgba(37,211,102,0.5); }\n\n  \n\n  .perfil-header[_ngcontent-%COMP%] { display:flex; align-items:flex-start; gap:20px; background:var(--app-surface); border:1px solid var(--app-border); border-radius:12px; padding:24px; flex-wrap:wrap; }\n  .perfil-avatar[_ngcontent-%COMP%] { width:72px; height:72px; border-radius:50%; background:linear-gradient(135deg,#6366f1,#a855f7); color:#fff; display:flex; align-items:center; justify-content:center; font-size:28px; font-weight:700; flex-shrink:0; }\n  .perfil-header-info[_ngcontent-%COMP%] { flex:1; min-width:0; }\n\n  \n\n  .status-badge[_ngcontent-%COMP%] { font-size:11px; font-weight:600; padding:3px 10px; border-radius:99px; }\n  .status-badge.ativo[_ngcontent-%COMP%] { background:rgba(34,197,94,0.15); color:#22c55e; }\n  .status-badge[_ngcontent-%COMP%]:not(.ativo) { background:rgba(148,163,184,0.15); color:#94a3b8; }\n  .faixa-chip[_ngcontent-%COMP%] { font-size:11px; font-weight:600; padding:3px 10px; border-radius:99px; }\n  .info-chip[_ngcontent-%COMP%] { font-size:12px; font-weight:500; padding:3px 10px; border-radius:99px; background:var(--app-bg); border:1px solid var(--app-border); color:var(--app-text-2); }\n\n  \n\n  .info-cards-row[_ngcontent-%COMP%] { display:grid; grid-template-columns:repeat(auto-fill,minmax(180px,1fr)); gap:12px; }\n  .info-card[_ngcontent-%COMP%] { display:flex; align-items:center; gap:14px; background:var(--app-surface); border:1px solid var(--app-border); border-radius:10px; padding:16px; }\n  .info-card-icon[_ngcontent-%COMP%] { width:40px; height:40px; border-radius:10px; display:flex; align-items:center; justify-content:center; flex-shrink:0; }\n  .info-card-label[_ngcontent-%COMP%] { font-size:11px; color:var(--app-text-3); font-weight:500; text-transform:uppercase; letter-spacing:0.04em; }\n  .info-card-value[_ngcontent-%COMP%] { font-size:20px; font-weight:700; color:var(--app-text-1); margin-top:2px; }\n\n  \n\n  .secao-card[_ngcontent-%COMP%] { background:var(--app-surface); border:1px solid var(--app-border); border-radius:10px; padding:20px; margin-top:16px; }\n  .secao-titulo[_ngcontent-%COMP%] { font-size:13px; font-weight:600; color:var(--app-text-1); margin:0 0 14px; text-transform:uppercase; letter-spacing:0.04em; }\n  .dados-grid[_ngcontent-%COMP%] { display:grid; grid-template-columns:repeat(auto-fill,minmax(220px,1fr)); gap:12px; }\n  .dado-item[_ngcontent-%COMP%] { display:flex; flex-direction:column; gap:2px; }\n  .dado-label[_ngcontent-%COMP%] { font-size:11px; color:var(--app-text-3); font-weight:500; }\n  .dado-valor[_ngcontent-%COMP%] { font-size:14px; color:var(--app-text-1); font-weight:500; }\n\n  \n\n  .presencas-lista-detalhe[_ngcontent-%COMP%] { display:flex; flex-direction:column; }\n  .presenca-row[_ngcontent-%COMP%] { display:flex; align-items:center; gap:12px; padding:12px 16px; border-bottom:1px solid var(--app-border); }\n  .presenca-row[_ngcontent-%COMP%]:last-child { border-bottom:none; }\n  .presenca-check-icon[_ngcontent-%COMP%] { width:28px; height:28px; border-radius:50%; background:rgba(34,197,94,0.12); display:flex; align-items:center; justify-content:center; flex-shrink:0; }\n\n  \n\n  .conquista-chip[_ngcontent-%COMP%] { display:flex; align-items:center; gap:6px; padding:6px 10px; border-radius:99px; background:var(--app-bg); border:1px solid var(--app-border); font-size:13px; }\n\n  \n\n  .pagamentos-lista[_ngcontent-%COMP%] { display:flex; flex-direction:column; }\n  .pagamento-row[_ngcontent-%COMP%] { display:flex; align-items:center; gap:12px; padding:12px 16px; border-bottom:1px solid var(--app-border); flex-wrap:wrap; }\n  .pagamento-row[_ngcontent-%COMP%]:last-child { border-bottom:none; }\n  .badge-pag[_ngcontent-%COMP%] { font-size:11px; font-weight:600; padding:2px 8px; border-radius:99px; white-space:nowrap; }\n  .badge-pag-pago[_ngcontent-%COMP%] { background:rgba(34,197,94,0.12); color:#16a34a; }\n  .badge-pag-pendente[_ngcontent-%COMP%] { background:rgba(245,158,11,0.15); color:#d97706; }\n  .badge-pag-atrasado[_ngcontent-%COMP%] { background:rgba(239,68,68,0.15); color:#dc2626; }\n  .badge-pag-cancelado[_ngcontent-%COMP%] { background:rgba(148,163,184,0.12); color:#94a3b8; }\n  .btn-pagar-mini[_ngcontent-%COMP%] { display:inline-flex; align-items:center; gap:4px; padding:4px 10px; border-radius:6px; border:1px solid rgba(34,197,94,0.4); background:rgba(34,197,94,0.08); color:#16a34a; font-size:12px; font-weight:600; cursor:pointer; transition:all 0.15s; white-space:nowrap; }\n  .btn-pagar-mini[_ngcontent-%COMP%]:hover { background:rgba(34,197,94,0.18); border-color:rgba(34,197,94,0.6); }\n  .badge-ct[_ngcontent-%COMP%] { font-size:11px; font-weight:600; padding:2px 8px; border-radius:99px; white-space:nowrap; }\n  .badge-ct-pendente[_ngcontent-%COMP%]  { background:rgba(245,158,11,0.12); color:#b45309; }\n  .badge-ct-assinado[_ngcontent-%COMP%]  { background:rgba(34,197,94,0.12);  color:#15803d; }\n  .badge-ct-cancelado[_ngcontent-%COMP%] { background:rgba(107,114,128,0.12); color:#6b7280; }"] });
  }
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && \u0275setClassDebugInfo(AlunoDetalheComponent, { className: "AlunoDetalheComponent" });
})();
export {
  AlunoDetalheComponent
};
//# sourceMappingURL=chunk-KHFQBNTQ.js.map
