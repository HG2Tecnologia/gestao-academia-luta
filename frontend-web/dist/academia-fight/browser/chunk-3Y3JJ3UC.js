import {
  HorarioService
} from "./chunk-CWZ2LAZG.js";
import {
  TurmaService
} from "./chunk-S4MMSQ6J.js";
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
  RouterLink
} from "./chunk-AXNOULNC.js";
import {
  CommonModule,
  DatePipe,
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
  ɵɵnamespaceSVG,
  ɵɵnextContext,
  ɵɵpipe,
  ɵɵpipeBind2,
  ɵɵproperty,
  ɵɵpureFunction0,
  ɵɵpureFunction1,
  ɵɵrepeater,
  ɵɵrepeaterCreate,
  ɵɵresetView,
  ɵɵrestoreView,
  ɵɵtemplate,
  ɵɵtext,
  ɵɵtextInterpolate,
  ɵɵtextInterpolate1,
  ɵɵtextInterpolate2
} from "./chunk-WZ2AWGAJ.js";
import "./chunk-7G5TR5RR.js";

// src/app/features/turmas/pages/detalhe/turma-detalhe.component.ts
var _forTrack0 = ($index, $item) => $item.id;
var _c0 = (a0) => ["/app/turmas", a0, "editar"];
var _c1 = () => ["/app/presencas"];
var _c2 = (a0) => ({ turmaId: a0 });
function TurmaDetalheComponent_Conditional_0_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 0);
    \u0275\u0275element(1, "div", 1);
    \u0275\u0275elementEnd();
  }
}
function TurmaDetalheComponent_Conditional_1_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 0)(1, "div", 2)(2, "p");
    \u0275\u0275text(3);
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance(3);
    \u0275\u0275textInterpolate(ctx_r0.erro() || "Turma n\xE3o encontrada.");
  }
}
function TurmaDetalheComponent_Conditional_2_Conditional_12_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 9);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext(2);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(ctx_r0.turma().nivel);
  }
}
function TurmaDetalheComponent_Conditional_2_Conditional_40_Conditional_4_Conditional_1_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "li", 25);
    \u0275\u0275text(1, "Nenhum aluno dispon\xEDvel");
    \u0275\u0275elementEnd();
  }
}
function TurmaDetalheComponent_Conditional_2_Conditional_40_Conditional_4_For_3_Template(rf, ctx) {
  if (rf & 1) {
    const _r4 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "li", 27);
    \u0275\u0275listener("mousedown", function TurmaDetalheComponent_Conditional_2_Conditional_40_Conditional_4_For_3_Template_li_mousedown_0_listener() {
      const a_r5 = \u0275\u0275restoreView(_r4).$implicit;
      const ctx_r0 = \u0275\u0275nextContext(4);
      return \u0275\u0275resetView(ctx_r0.selecionarAluno(a_r5));
    });
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const a_r5 = ctx.$implicit;
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1(" ", a_r5.nome, " ");
  }
}
function TurmaDetalheComponent_Conditional_2_Conditional_40_Conditional_4_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "ul", 21);
    \u0275\u0275template(1, TurmaDetalheComponent_Conditional_2_Conditional_40_Conditional_4_Conditional_1_Template, 2, 0, "li", 25);
    \u0275\u0275repeaterCreate(2, TurmaDetalheComponent_Conditional_2_Conditional_40_Conditional_4_For_3_Template, 2, 1, "li", 26, _forTrack0);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext(3);
    \u0275\u0275advance();
    \u0275\u0275conditional(1, ctx_r0.alunosFiltrados().length === 0 ? 1 : -1);
    \u0275\u0275advance();
    \u0275\u0275repeater(ctx_r0.alunosFiltrados());
  }
}
function TurmaDetalheComponent_Conditional_2_Conditional_40_Conditional_7_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 23);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext(3);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(ctx_r0.erroMatricula());
  }
}
function TurmaDetalheComponent_Conditional_2_Conditional_40_Conditional_8_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 24)(1, "p");
    \u0275\u0275text(2, "Nenhum aluno matriculado");
    \u0275\u0275elementEnd()();
  }
}
function TurmaDetalheComponent_Conditional_2_Conditional_40_Conditional_9_For_13_Template(rf, ctx) {
  if (rf & 1) {
    const _r6 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "tr")(1, "td", 30);
    \u0275\u0275text(2);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "td");
    \u0275\u0275text(4);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(5, "td");
    \u0275\u0275text(6);
    \u0275\u0275pipe(7, "date");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(8, "td")(9, "button", 31);
    \u0275\u0275listener("click", function TurmaDetalheComponent_Conditional_2_Conditional_40_Conditional_9_For_13_Template_button_click_9_listener() {
      const aluno_r7 = \u0275\u0275restoreView(_r6).$implicit;
      const ctx_r0 = \u0275\u0275nextContext(4);
      return \u0275\u0275resetView(ctx_r0.abrirModalRemover(aluno_r7));
    });
    \u0275\u0275text(10, "Remover");
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    const aluno_r7 = ctx.$implicit;
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(aluno_r7.nomeAluno);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(aluno_r7.emailAluno);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(\u0275\u0275pipeBind2(7, 3, aluno_r7.dataInicio, "dd/MM/yyyy"));
  }
}
function TurmaDetalheComponent_Conditional_2_Conditional_40_Conditional_9_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 28)(1, "table", 29)(2, "thead")(3, "tr")(4, "th");
    \u0275\u0275text(5, "Nome");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(6, "th");
    \u0275\u0275text(7, "Email");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(8, "th");
    \u0275\u0275text(9, "Desde");
    \u0275\u0275elementEnd();
    \u0275\u0275element(10, "th");
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(11, "tbody");
    \u0275\u0275repeaterCreate(12, TurmaDetalheComponent_Conditional_2_Conditional_40_Conditional_9_For_13_Template, 11, 6, "tr", null, _forTrack0);
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext(3);
    \u0275\u0275advance(12);
    \u0275\u0275repeater(ctx_r0.turma().alunos);
  }
}
function TurmaDetalheComponent_Conditional_2_Conditional_40_Template(rf, ctx) {
  if (rf & 1) {
    const _r3 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 17)(1, "div", 18)(2, "div", 19)(3, "input", 20);
    \u0275\u0275listener("ngModelChange", function TurmaDetalheComponent_Conditional_2_Conditional_40_Template_input_ngModelChange_3_listener($event) {
      \u0275\u0275restoreView(_r3);
      const ctx_r0 = \u0275\u0275nextContext(2);
      return \u0275\u0275resetView(ctx_r0.onFiltroChange($event));
    })("focus", function TurmaDetalheComponent_Conditional_2_Conditional_40_Template_input_focus_3_listener() {
      \u0275\u0275restoreView(_r3);
      const ctx_r0 = \u0275\u0275nextContext(2);
      return \u0275\u0275resetView(ctx_r0.abrirDropdown());
    })("blur", function TurmaDetalheComponent_Conditional_2_Conditional_40_Template_input_blur_3_listener() {
      \u0275\u0275restoreView(_r3);
      const ctx_r0 = \u0275\u0275nextContext(2);
      return \u0275\u0275resetView(ctx_r0.fecharDropdown());
    });
    \u0275\u0275elementEnd();
    \u0275\u0275template(4, TurmaDetalheComponent_Conditional_2_Conditional_40_Conditional_4_Template, 4, 1, "ul", 21);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(5, "button", 22);
    \u0275\u0275listener("click", function TurmaDetalheComponent_Conditional_2_Conditional_40_Template_button_click_5_listener() {
      \u0275\u0275restoreView(_r3);
      const ctx_r0 = \u0275\u0275nextContext(2);
      return \u0275\u0275resetView(ctx_r0.matricular());
    });
    \u0275\u0275text(6);
    \u0275\u0275elementEnd()();
    \u0275\u0275template(7, TurmaDetalheComponent_Conditional_2_Conditional_40_Conditional_7_Template, 2, 1, "div", 23)(8, TurmaDetalheComponent_Conditional_2_Conditional_40_Conditional_8_Template, 3, 0, "div", 24)(9, TurmaDetalheComponent_Conditional_2_Conditional_40_Conditional_9_Template, 14, 0);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext(2);
    \u0275\u0275advance(3);
    \u0275\u0275property("ngModel", ctx_r0.filtroAluno());
    \u0275\u0275advance();
    \u0275\u0275conditional(4, ctx_r0.dropdownAberto() ? 4 : -1);
    \u0275\u0275advance();
    \u0275\u0275property("disabled", ctx_r0.operando() || !ctx_r0.alunoSelecionado());
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1(" ", ctx_r0.operando() ? "Matriculando..." : "+ Matricular", " ");
    \u0275\u0275advance();
    \u0275\u0275conditional(7, ctx_r0.erroMatricula() ? 7 : -1);
    \u0275\u0275advance();
    \u0275\u0275conditional(8, ctx_r0.turma().alunos.length === 0 ? 8 : 9);
  }
}
function TurmaDetalheComponent_Conditional_2_Conditional_41_Conditional_1_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 24)(1, "p");
    \u0275\u0275text(2, "Nenhum hor\xE1rio cadastrado");
    \u0275\u0275elementEnd()();
  }
}
function TurmaDetalheComponent_Conditional_2_Conditional_41_Conditional_2_For_2_Conditional_11_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 39);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(1, "svg", 46);
    \u0275\u0275element(2, "path", 47)(3, "polyline", 48);
    \u0275\u0275elementEnd();
    \u0275\u0275text(4);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const h_r9 = \u0275\u0275nextContext().$implicit;
    \u0275\u0275advance(4);
    \u0275\u0275textInterpolate1(" ", h_r9.sala, " ");
  }
}
function TurmaDetalheComponent_Conditional_2_Conditional_41_Conditional_2_For_2_Template(rf, ctx) {
  if (rf & 1) {
    const _r8 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 33)(1, "div", 34)(2, "span", 35);
    \u0275\u0275text(3);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(4, "div", 36)(5, "span", 37);
    \u0275\u0275text(6);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(7, "span", 38);
    \u0275\u0275text(8, "\u2013");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(9, "span", 37);
    \u0275\u0275text(10);
    \u0275\u0275elementEnd()();
    \u0275\u0275template(11, TurmaDetalheComponent_Conditional_2_Conditional_41_Conditional_2_For_2_Conditional_11_Template, 5, 1, "span", 39);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(12, "button", 40);
    \u0275\u0275listener("click", function TurmaDetalheComponent_Conditional_2_Conditional_41_Conditional_2_For_2_Template_button_click_12_listener() {
      const h_r9 = \u0275\u0275restoreView(_r8).$implicit;
      const ctx_r0 = \u0275\u0275nextContext(4);
      return \u0275\u0275resetView(ctx_r0.abrirModalRemoverHorario(h_r9));
    });
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(13, "svg", 41);
    \u0275\u0275element(14, "polyline", 42)(15, "path", 43)(16, "path", 44)(17, "path", 45);
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    const h_r9 = ctx.$implicit;
    const ctx_r0 = \u0275\u0275nextContext(4);
    \u0275\u0275advance(3);
    \u0275\u0275textInterpolate(h_r9.diaSemanaLabel);
    \u0275\u0275advance(3);
    \u0275\u0275textInterpolate(ctx_r0.formatarHora(h_r9.horaInicio));
    \u0275\u0275advance(4);
    \u0275\u0275textInterpolate(ctx_r0.formatarHora(h_r9.horaFim));
    \u0275\u0275advance();
    \u0275\u0275conditional(11, h_r9.sala ? 11 : -1);
  }
}
function TurmaDetalheComponent_Conditional_2_Conditional_41_Conditional_2_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 32);
    \u0275\u0275repeaterCreate(1, TurmaDetalheComponent_Conditional_2_Conditional_41_Conditional_2_For_2_Template, 18, 4, "div", 33, _forTrack0);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext(3);
    \u0275\u0275advance();
    \u0275\u0275repeater(ctx_r0.turma().horarios);
  }
}
function TurmaDetalheComponent_Conditional_2_Conditional_41_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 17);
    \u0275\u0275template(1, TurmaDetalheComponent_Conditional_2_Conditional_41_Conditional_1_Template, 3, 0, "div", 24)(2, TurmaDetalheComponent_Conditional_2_Conditional_41_Conditional_2_Template, 3, 0);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext(2);
    \u0275\u0275advance();
    \u0275\u0275conditional(1, ctx_r0.turma().horarios.length === 0 ? 1 : 2);
  }
}
function TurmaDetalheComponent_Conditional_2_Conditional_42_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 17)(1, "a", 49);
    \u0275\u0275text(2, " Ver presen\xE7as desta turma ");
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext(2);
    \u0275\u0275advance();
    \u0275\u0275property("routerLink", \u0275\u0275pureFunction0(2, _c1))("queryParams", \u0275\u0275pureFunction1(3, _c2, ctx_r0.turma().id));
  }
}
function TurmaDetalheComponent_Conditional_2_Template(rf, ctx) {
  if (rf & 1) {
    const _r2 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 0)(1, "div", 3)(2, "div")(3, "div", 4)(4, "a", 5);
    \u0275\u0275text(5, "Turmas");
    \u0275\u0275elementEnd();
    \u0275\u0275text(6);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(7, "h1", 6);
    \u0275\u0275text(8);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(9, "div", 7)(10, "span", 8);
    \u0275\u0275text(11);
    \u0275\u0275elementEnd();
    \u0275\u0275template(12, TurmaDetalheComponent_Conditional_2_Conditional_12_Template, 2, 1, "span", 9);
    \u0275\u0275elementStart(13, "span");
    \u0275\u0275text(14);
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(15, "a", 10);
    \u0275\u0275text(16, "Editar");
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(17, "div", 11)(18, "div", 12)(19, "span", 13);
    \u0275\u0275text(20);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(21, "span", 14);
    \u0275\u0275text(22, "Alunos");
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(23, "div", 12)(24, "span", 13);
    \u0275\u0275text(25);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(26, "span", 14);
    \u0275\u0275text(27, "Hor\xE1rios");
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(28, "div", 12)(29, "span", 13);
    \u0275\u0275text(30);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(31, "span", 14);
    \u0275\u0275text(32, "Professor");
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(33, "div", 15)(34, "button", 16);
    \u0275\u0275listener("click", function TurmaDetalheComponent_Conditional_2_Template_button_click_34_listener() {
      \u0275\u0275restoreView(_r2);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.abaAtiva.set("alunos"));
    });
    \u0275\u0275text(35, "Alunos");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(36, "button", 16);
    \u0275\u0275listener("click", function TurmaDetalheComponent_Conditional_2_Template_button_click_36_listener() {
      \u0275\u0275restoreView(_r2);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.abaAtiva.set("horarios"));
    });
    \u0275\u0275text(37, "Hor\xE1rios");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(38, "button", 16);
    \u0275\u0275listener("click", function TurmaDetalheComponent_Conditional_2_Template_button_click_38_listener() {
      \u0275\u0275restoreView(_r2);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.abaAtiva.set("presencas"));
    });
    \u0275\u0275text(39, "Presen\xE7as");
    \u0275\u0275elementEnd()();
    \u0275\u0275template(40, TurmaDetalheComponent_Conditional_2_Conditional_40_Template, 10, 6, "div", 17)(41, TurmaDetalheComponent_Conditional_2_Conditional_41_Template, 3, 1, "div", 17)(42, TurmaDetalheComponent_Conditional_2_Conditional_42_Template, 3, 5, "div", 17);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance(6);
    \u0275\u0275textInterpolate1(" / ", ctx_r0.turma().nome, "");
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(ctx_r0.turma().nome);
    \u0275\u0275advance(3);
    \u0275\u0275textInterpolate(ctx_r0.turma().modalidadeNome);
    \u0275\u0275advance();
    \u0275\u0275conditional(12, ctx_r0.turma().nivel ? 12 : -1);
    \u0275\u0275advance();
    \u0275\u0275classMap(ctx_r0.turma().ativo ? "badge-ativo" : "badge-inativo");
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(ctx_r0.turma().ativo ? "Ativa" : "Inativa");
    \u0275\u0275advance();
    \u0275\u0275property("routerLink", \u0275\u0275pureFunction1(21, _c0, ctx_r0.turma().id));
    \u0275\u0275advance(5);
    \u0275\u0275textInterpolate2("", ctx_r0.turma().totalAlunos, "/", ctx_r0.turma().capacidadeMaxima, "");
    \u0275\u0275advance(5);
    \u0275\u0275textInterpolate(ctx_r0.turma().horarios.length);
    \u0275\u0275advance(5);
    \u0275\u0275textInterpolate(ctx_r0.turma().professorNome);
    \u0275\u0275advance(4);
    \u0275\u0275classProp("active", ctx_r0.abaAtiva() === "alunos");
    \u0275\u0275advance(2);
    \u0275\u0275classProp("active", ctx_r0.abaAtiva() === "horarios");
    \u0275\u0275advance(2);
    \u0275\u0275classProp("active", ctx_r0.abaAtiva() === "presencas");
    \u0275\u0275advance(2);
    \u0275\u0275conditional(40, ctx_r0.abaAtiva() === "alunos" ? 40 : -1);
    \u0275\u0275advance();
    \u0275\u0275conditional(41, ctx_r0.abaAtiva() === "horarios" ? 41 : -1);
    \u0275\u0275advance();
    \u0275\u0275conditional(42, ctx_r0.abaAtiva() === "presencas" ? 42 : -1);
  }
}
function TurmaDetalheComponent_Conditional_3_Template(rf, ctx) {
  if (rf & 1) {
    const _r10 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 50);
    \u0275\u0275listener("click", function TurmaDetalheComponent_Conditional_3_Template_div_click_0_listener() {
      \u0275\u0275restoreView(_r10);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.fecharModalRemover());
    });
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(1, "div", 51)(2, "div", 52)(3, "h3");
    \u0275\u0275text(4, "Remover aluno da turma");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(5, "button", 53);
    \u0275\u0275listener("click", function TurmaDetalheComponent_Conditional_3_Template_button_click_5_listener() {
      \u0275\u0275restoreView(_r10);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.fecharModalRemover());
    });
    \u0275\u0275text(6, "\u2715");
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(7, "div", 54)(8, "p", 55);
    \u0275\u0275text(9, " Tem certeza que deseja remover ");
    \u0275\u0275elementStart(10, "strong");
    \u0275\u0275text(11);
    \u0275\u0275elementEnd();
    \u0275\u0275text(12, " desta turma? O hist\xF3rico de presen\xE7as ser\xE1 mantido. ");
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(13, "div", 56)(14, "button", 57);
    \u0275\u0275listener("click", function TurmaDetalheComponent_Conditional_3_Template_button_click_14_listener() {
      \u0275\u0275restoreView(_r10);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.fecharModalRemover());
    });
    \u0275\u0275text(15, "Cancelar");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(16, "button", 58);
    \u0275\u0275listener("click", function TurmaDetalheComponent_Conditional_3_Template_button_click_16_listener() {
      \u0275\u0275restoreView(_r10);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.confirmarRemover());
    });
    \u0275\u0275text(17);
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance(11);
    \u0275\u0275textInterpolate(ctx_r0.alunoParaRemover().nomeAluno);
    \u0275\u0275advance(3);
    \u0275\u0275property("disabled", ctx_r0.removendo());
    \u0275\u0275advance(2);
    \u0275\u0275property("disabled", ctx_r0.removendo());
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1(" ", ctx_r0.removendo() ? "Removendo..." : "Remover", " ");
  }
}
function TurmaDetalheComponent_Conditional_4_Template(rf, ctx) {
  if (rf & 1) {
    const _r11 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 50);
    \u0275\u0275listener("click", function TurmaDetalheComponent_Conditional_4_Template_div_click_0_listener() {
      \u0275\u0275restoreView(_r11);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.fecharModalRemoverHorario());
    });
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(1, "div", 51)(2, "div", 52)(3, "h3");
    \u0275\u0275text(4, "Remover hor\xE1rio");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(5, "button", 53);
    \u0275\u0275listener("click", function TurmaDetalheComponent_Conditional_4_Template_button_click_5_listener() {
      \u0275\u0275restoreView(_r11);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.fecharModalRemoverHorario());
    });
    \u0275\u0275text(6, "\u2715");
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(7, "div", 54)(8, "p", 55);
    \u0275\u0275text(9, " Deseja remover o hor\xE1rio de ");
    \u0275\u0275elementStart(10, "strong");
    \u0275\u0275text(11);
    \u0275\u0275elementEnd();
    \u0275\u0275text(12, ", das ");
    \u0275\u0275elementStart(13, "strong");
    \u0275\u0275text(14);
    \u0275\u0275elementEnd();
    \u0275\u0275text(15, " \xE0s ");
    \u0275\u0275elementStart(16, "strong");
    \u0275\u0275text(17);
    \u0275\u0275elementEnd();
    \u0275\u0275text(18, "? ");
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(19, "div", 56)(20, "button", 57);
    \u0275\u0275listener("click", function TurmaDetalheComponent_Conditional_4_Template_button_click_20_listener() {
      \u0275\u0275restoreView(_r11);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.fecharModalRemoverHorario());
    });
    \u0275\u0275text(21, "Cancelar");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(22, "button", 58);
    \u0275\u0275listener("click", function TurmaDetalheComponent_Conditional_4_Template_button_click_22_listener() {
      \u0275\u0275restoreView(_r11);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.confirmarRemoverHorario());
    });
    \u0275\u0275text(23);
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance(11);
    \u0275\u0275textInterpolate(ctx_r0.horarioParaRemover().diaSemanaLabel);
    \u0275\u0275advance(3);
    \u0275\u0275textInterpolate(ctx_r0.formatarHora(ctx_r0.horarioParaRemover().horaInicio));
    \u0275\u0275advance(3);
    \u0275\u0275textInterpolate(ctx_r0.formatarHora(ctx_r0.horarioParaRemover().horaFim));
    \u0275\u0275advance(3);
    \u0275\u0275property("disabled", ctx_r0.removendoHorario());
    \u0275\u0275advance(2);
    \u0275\u0275property("disabled", ctx_r0.removendoHorario());
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1(" ", ctx_r0.removendoHorario() ? "Removendo..." : "Remover", " ");
  }
}
var TurmaDetalheComponent = class _TurmaDetalheComponent {
  constructor() {
    this.turmaService = inject(TurmaService);
    this.alunoService = inject(AlunoService);
    this.horarioService = inject(HorarioService);
    this.route = inject(ActivatedRoute);
    this.turma = signal(null);
    this.carregando = signal(true);
    this.erro = signal("");
    this.abaAtiva = signal("alunos");
    this.operando = signal(false);
    this.erroMatricula = signal("");
    this.todosAlunos = signal([]);
    this.filtroAluno = signal("");
    this.dropdownAberto = signal(false);
    this.alunoSelecionado = signal(null);
    this.alunoParaRemover = signal(null);
    this.removendo = signal(false);
    this.horarioParaRemover = signal(null);
    this.removendoHorario = signal(false);
    this.alunosFiltrados = computed(() => {
      const filtro = this.filtroAluno().toLowerCase().trim();
      const matriculadosIds = new Set((this.turma()?.alunos ?? []).map((a) => a.alunoId));
      const disponiveis = this.todosAlunos().filter((a) => !matriculadosIds.has(a.id));
      return filtro.length === 0 ? disponiveis : disponiveis.filter((a) => a.nome.toLowerCase().includes(filtro));
    });
  }
  ngOnInit() {
    const id = this.route.snapshot.paramMap.get("id");
    this.carregar(id);
    this.alunoService.getAll({ ativo: true, pageSize: 500 }).subscribe({
      next: (res) => this.todosAlunos.set(res.dados?.itens ?? [])
    });
  }
  carregar(id) {
    this.carregando.set(true);
    this.turmaService.getById(id).subscribe({
      next: (res) => {
        this.turma.set(res.dados ?? null);
        this.carregando.set(false);
      },
      error: () => {
        this.erro.set("Erro ao carregar turma.");
        this.carregando.set(false);
      }
    });
  }
  abrirDropdown() {
    this.dropdownAberto.set(true);
  }
  fecharDropdown() {
    setTimeout(() => this.dropdownAberto.set(false), 200);
  }
  onFiltroChange(v) {
    this.filtroAluno.set(v);
    this.alunoSelecionado.set(null);
    this.dropdownAberto.set(true);
  }
  selecionarAluno(aluno) {
    this.alunoSelecionado.set(aluno);
    this.filtroAluno.set(aluno.nome);
    this.dropdownAberto.set(false);
  }
  matricular() {
    const aluno = this.alunoSelecionado();
    const turma = this.turma();
    if (!aluno || !turma)
      return;
    this.erroMatricula.set("");
    this.operando.set(true);
    this.turmaService.matricular(turma.id, aluno.id).subscribe({
      next: () => {
        this.alunoSelecionado.set(null);
        this.filtroAluno.set("");
        this.operando.set(false);
        this.carregar(turma.id);
      },
      error: (err) => {
        this.erroMatricula.set(err.error?.mensagem ?? "Erro ao matricular aluno.");
        this.operando.set(false);
      }
    });
  }
  abrirModalRemover(aluno) {
    this.alunoParaRemover.set(aluno);
  }
  fecharModalRemover() {
    this.alunoParaRemover.set(null);
  }
  confirmarRemover() {
    const aluno = this.alunoParaRemover();
    const turma = this.turma();
    if (!aluno || !turma)
      return;
    this.removendo.set(true);
    this.turmaService.desmatricular(turma.id, aluno.alunoId).subscribe({
      next: () => {
        this.removendo.set(false);
        this.fecharModalRemover();
        this.carregar(turma.id);
      },
      error: () => {
        this.removendo.set(false);
        this.fecharModalRemover();
        this.erro.set("Erro ao remover aluno.");
      }
    });
  }
  abrirModalRemoverHorario(h) {
    this.horarioParaRemover.set(h);
  }
  fecharModalRemoverHorario() {
    this.horarioParaRemover.set(null);
  }
  confirmarRemoverHorario() {
    const h = this.horarioParaRemover();
    const turma = this.turma();
    if (!h || !turma)
      return;
    this.removendoHorario.set(true);
    this.horarioService.delete(h.id).subscribe({
      next: () => {
        this.removendoHorario.set(false);
        this.fecharModalRemoverHorario();
        this.carregar(turma.id);
      },
      error: () => {
        this.removendoHorario.set(false);
        this.fecharModalRemoverHorario();
        this.erro.set("Erro ao remover hor\xE1rio.");
      }
    });
  }
  formatarHora(h) {
    return h ? h.substring(0, 5) : "";
  }
  static {
    this.\u0275fac = function TurmaDetalheComponent_Factory(t) {
      return new (t || _TurmaDetalheComponent)();
    };
  }
  static {
    this.\u0275cmp = /* @__PURE__ */ \u0275\u0275defineComponent({ type: _TurmaDetalheComponent, selectors: [["app-turma-detalhe"]], standalone: true, features: [\u0275\u0275StandaloneFeature], decls: 5, vars: 3, consts: [[1, "page-container"], [1, "skeleton-header"], [1, "error-card"], [1, "page-header"], [1, "breadcrumb"], ["routerLink", "/app/turmas", 1, "breadcrumb-link"], [1, "page-title"], [1, "badges-row"], [1, "badge-tag"], [1, "badge-tag", "secondary"], [1, "btn-secondary", 3, "routerLink"], [1, "stats-row"], [1, "stat-card"], [1, "stat-value"], [1, "stat-label"], [1, "tabs"], [1, "tab", 3, "click"], [1, "tab-content"], [1, "matricular-row"], [2, "position", "relative", "max-width", "340px", "flex", "1"], ["placeholder", "Selecionar aluno...", "autocomplete", "off", 1, "form-input", 3, "ngModelChange", "focus", "blur", "ngModel"], [1, "aluno-dropdown"], [1, "btn-primary", 3, "click", "disabled"], [1, "alert-error", 2, "margin-bottom", "12px"], [1, "empty-state"], [1, "aluno-dropdown-vazio"], [1, "aluno-dropdown-item"], [1, "aluno-dropdown-item", 3, "mousedown"], [1, "table-wrapper"], [1, "data-table"], [1, "font-medium"], [1, "action-link", "danger", 3, "click"], [1, "horarios-grid"], [1, "horario-item"], [1, "horario-item-left"], [1, "horario-dia-badge"], [1, "horario-tempo"], [1, "horario-hora-texto"], [1, "horario-separador"], [1, "horario-sala-tag"], ["title", "Remover hor\xE1rio", 1, "horario-remover-btn", 3, "click"], ["width", "15", "height", "15", "fill", "none", "stroke", "currentColor", "stroke-width", "2", "viewBox", "0 0 24 24"], ["points", "3 6 5 6 21 6"], ["d", "M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"], ["d", "M10 11v6M14 11v6"], ["d", "M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"], ["width", "12", "height", "12", "fill", "none", "stroke", "currentColor", "stroke-width", "2", "viewBox", "0 0 24 24"], ["d", "M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"], ["points", "9 22 9 12 15 12 15 22"], [1, "btn-secondary", 3, "routerLink", "queryParams"], [1, "modal-backdrop", 3, "click"], [1, "modal"], [1, "modal-header"], [1, "modal-close", 3, "click"], [1, "modal-body"], [2, "color", "var(--app-text-2)", "font-size", "0.9rem"], [1, "modal-actions"], [1, "btn-secondary", 3, "click", "disabled"], [1, "btn-danger", 3, "click", "disabled"]], template: function TurmaDetalheComponent_Template(rf, ctx) {
      if (rf & 1) {
        \u0275\u0275template(0, TurmaDetalheComponent_Conditional_0_Template, 2, 0, "div", 0)(1, TurmaDetalheComponent_Conditional_1_Template, 4, 1)(2, TurmaDetalheComponent_Conditional_2_Template, 43, 23)(3, TurmaDetalheComponent_Conditional_3_Template, 18, 4)(4, TurmaDetalheComponent_Conditional_4_Template, 24, 6);
      }
      if (rf & 2) {
        \u0275\u0275conditional(0, ctx.carregando() ? 0 : ctx.erro() || !ctx.turma() ? 1 : 2);
        \u0275\u0275advance(3);
        \u0275\u0275conditional(3, ctx.alunoParaRemover() ? 3 : -1);
        \u0275\u0275advance();
        \u0275\u0275conditional(4, ctx.horarioParaRemover() ? 4 : -1);
      }
    }, dependencies: [CommonModule, DatePipe, FormsModule, DefaultValueAccessor, NgControlStatus, NgModel, RouterLink], styles: ["\n\n  .aluno-dropdown[_ngcontent-%COMP%] { position: absolute; top: calc(100% + 4px); left: 0; right: 0; background: var(--app-surface); border: 1px solid var(--app-border); border-radius: 8px; box-shadow: 0 4px 20px rgba(0,0,0,0.12); z-index: 200; max-height: 260px; overflow-y: auto; padding: 4px; margin: 0; list-style: none; }\n  .aluno-dropdown-item[_ngcontent-%COMP%] { padding: 8px 10px; border-radius: 6px; cursor: pointer; font-size: 14px; color: var(--app-text-1); transition: background 0.1s; }\n  .aluno-dropdown-item[_ngcontent-%COMP%]:hover { background: var(--app-border-light); }\n  .aluno-dropdown-vazio[_ngcontent-%COMP%] { padding: 12px 10px; font-size: 13px; color: var(--app-text-3); text-align: center; }\n\n  \n\n  .horarios-grid[_ngcontent-%COMP%] { display: flex; flex-direction: column; gap: 8px; }\n  .horario-item[_ngcontent-%COMP%] {\n    display: flex; align-items: center; justify-content: space-between;\n    background: var(--app-surface); border: 1px solid var(--app-border);\n    border-radius: 10px; padding: 14px 16px;\n    transition: box-shadow 0.15s;\n  }\n  .horario-item[_ngcontent-%COMP%]:hover { box-shadow: 0 2px 10px rgba(0,0,0,0.07); }\n  .horario-item-left[_ngcontent-%COMP%] { display: flex; align-items: center; gap: 16px; flex-wrap: wrap; }\n  .horario-dia-badge[_ngcontent-%COMP%] {\n    font-size: 12px; font-weight: 700; padding: 4px 12px; border-radius: 99px;\n    background: rgba(99,102,241,0.12); color: #6366f1; min-width: 70px; text-align: center;\n  }\n  .horario-tempo[_ngcontent-%COMP%] { display: flex; align-items: center; gap: 6px; }\n  .horario-hora-texto[_ngcontent-%COMP%] { font-size: 18px; font-weight: 700; color: var(--app-text-1); font-variant-numeric: tabular-nums; }\n  .horario-separador[_ngcontent-%COMP%] { font-size: 16px; color: var(--app-text-3); font-weight: 300; }\n  .horario-sala-tag[_ngcontent-%COMP%] {\n    display: flex; align-items: center; gap: 4px;\n    font-size: 12px; color: var(--app-text-3);\n    background: var(--app-bg); border: 1px solid var(--app-border);\n    padding: 3px 10px; border-radius: 99px;\n  }\n  .horario-remover-btn[_ngcontent-%COMP%] {\n    background: none; border: none; cursor: pointer; padding: 6px;\n    color: var(--app-text-3); border-radius: 6px; transition: all 0.15s;\n    display: flex; align-items: center;\n  }\n  .horario-remover-btn[_ngcontent-%COMP%]:hover { background: rgba(239,68,68,0.1); color: #ef4444; }\n\n  \n\n  .modal-backdrop[_ngcontent-%COMP%] { position: fixed; inset: 0; background: rgba(0,0,0,0.4); z-index: 100; }\n  .modal[_ngcontent-%COMP%] { position: fixed; top: 50%; left: 50%; transform: translate(-50%,-50%); background: var(--app-surface); border-radius: 12px; padding: 24px; width: 100%; max-width: 420px; z-index: 101; box-shadow: 0 8px 32px rgba(0,0,0,0.15); }\n  .modal-header[_ngcontent-%COMP%] { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }\n  .modal-header[_ngcontent-%COMP%]   h3[_ngcontent-%COMP%] { font-size: 1rem; font-weight: 600; margin: 0; }\n  .modal-close[_ngcontent-%COMP%] { background: none; border: none; font-size: 1.1rem; cursor: pointer; color: var(--app-text-3); }\n  .modal-body[_ngcontent-%COMP%] { margin-bottom: 20px; }\n  .modal-actions[_ngcontent-%COMP%] { display: flex; gap: 8px; justify-content: flex-end; }\n  .btn-danger[_ngcontent-%COMP%] { padding: 8px 18px; background: #ef4444; color: #fff; border: none; border-radius: 6px; cursor: pointer; font-size: 0.875rem; font-weight: 500; transition: background 0.15s; }\n  .btn-danger[_ngcontent-%COMP%]:hover { background: #dc2626; }\n  .btn-danger[_ngcontent-%COMP%]:disabled { opacity: 0.6; cursor: not-allowed; }"] });
  }
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && \u0275setClassDebugInfo(TurmaDetalheComponent, { className: "TurmaDetalheComponent" });
})();
export {
  TurmaDetalheComponent
};
//# sourceMappingURL=chunk-3Y3JJ3UC.js.map
