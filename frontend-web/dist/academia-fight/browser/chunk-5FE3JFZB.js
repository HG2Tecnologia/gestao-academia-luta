import {
  PlanoService
} from "./chunk-DTM3EMXS.js";
import {
  GraduacaoService
} from "./chunk-GPQPM6NQ.js";
import {
  ModalidadeService
} from "./chunk-ZN4AZHLY.js";
import {
  TurmaService
} from "./chunk-S4MMSQ6J.js";
import {
  CheckboxControlValueAccessor,
  DefaultValueAccessor,
  FormBuilder,
  FormControlName,
  FormGroupDirective,
  FormsModule,
  MaxValidator,
  MinValidator,
  NgControlStatus,
  NgControlStatusGroup,
  NgModel,
  NgSelectOption,
  NumberValueAccessor,
  ReactiveFormsModule,
  SelectControlValueAccessor,
  Validators,
  ɵNgNoValidate,
  ɵNgSelectMultipleOption
} from "./chunk-JQJL26HT.js";
import {
  AlunoService
} from "./chunk-ZSIQJU4D.js";
import {
  AuthService
} from "./chunk-V3IOF26G.js";
import "./chunk-Z5CKO2JM.js";
import {
  ActivatedRoute,
  Router,
  RouterLink
} from "./chunk-AXNOULNC.js";
import {
  CommonModule,
  CurrencyPipe,
  Subject,
  computed,
  inject,
  signal,
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
  ɵɵnamespaceHTML,
  ɵɵnamespaceSVG,
  ɵɵnextContext,
  ɵɵpipe,
  ɵɵpipeBindV,
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
  ɵɵtextInterpolate1,
  ɵɵtextInterpolate2
} from "./chunk-WZ2AWGAJ.js";
import {
  __spreadProps,
  __spreadValues
} from "./chunk-7G5TR5RR.js";

// src/app/features/alunos/pages/form/aluno-form.component.ts
var _forTrack0 = ($index, $item) => $item.id;
var _c0 = () => [1, 2, 3, 4];
var _c1 = () => ({ standalone: true });
var _c2 = (a0) => [a0, "BRL", "symbol", "1.2-2", "pt-BR"];
function AlunoFormComponent_Conditional_6_For_2_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275element(0, "div", 5);
  }
}
function AlunoFormComponent_Conditional_6_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 4);
    \u0275\u0275repeaterCreate(1, AlunoFormComponent_Conditional_6_For_2_Template, 1, 0, "div", 5, \u0275\u0275repeaterTrackByIdentity);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    \u0275\u0275advance();
    \u0275\u0275repeater(\u0275\u0275pureFunction0(0, _c0));
  }
}
function AlunoFormComponent_Conditional_7_Conditional_0_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 6);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(2);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(ctx_r1.erro());
  }
}
function AlunoFormComponent_Conditional_7_Conditional_1_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 7)(1, "span");
    \u0275\u0275text(2, "Matr\xEDcula: ");
    \u0275\u0275elementStart(3, "strong");
    \u0275\u0275text(4);
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(2);
    \u0275\u0275advance(4);
    \u0275\u0275textInterpolate(ctx_r1.matricula());
  }
}
function AlunoFormComponent_Conditional_7_Conditional_8_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 13);
    \u0275\u0275text(1, "Nome \xE9 obrigat\xF3rio (m\xEDnimo 3 caracteres)");
    \u0275\u0275elementEnd();
  }
}
function AlunoFormComponent_Conditional_7_Conditional_13_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 13);
    \u0275\u0275text(1, "Telefone \xE9 obrigat\xF3rio");
    \u0275\u0275elementEnd();
  }
}
function AlunoFormComponent_Conditional_7_Conditional_19_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 13);
    \u0275\u0275text(1, "E-mail inv\xE1lido");
    \u0275\u0275elementEnd();
  }
}
function AlunoFormComponent_Conditional_7_Conditional_24_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 13);
    \u0275\u0275text(1, "Data de nascimento \xE9 obrigat\xF3ria");
    \u0275\u0275elementEnd();
  }
}
function AlunoFormComponent_Conditional_7_For_35_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "option", 21);
    \u0275\u0275text(1);
    \u0275\u0275pipe(2, "currency");
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const p_r3 = ctx.$implicit;
    \u0275\u0275property("value", p_r3.id);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate2("", p_r3.nome, " \u2014 ", \u0275\u0275pipeBindV(2, 3, \u0275\u0275pureFunction1(9, _c2, p_r3.valorMensal)), "/m\xEAs");
  }
}
function AlunoFormComponent_Conditional_7_Conditional_44_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 24);
    \u0275\u0275text(1, "Obrigat\xF3rio \u2014 aluno menor de 18 anos");
    \u0275\u0275elementEnd();
  }
}
function AlunoFormComponent_Conditional_7_Conditional_50_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 13);
    \u0275\u0275text(1, "Nome do respons\xE1vel \xE9 obrigat\xF3rio para menores de 18 anos");
    \u0275\u0275elementEnd();
  }
}
function AlunoFormComponent_Conditional_7_Conditional_55_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 13);
    \u0275\u0275text(1, "Telefone do respons\xE1vel \xE9 obrigat\xF3rio para menores de 18 anos");
    \u0275\u0275elementEnd();
  }
}
function AlunoFormComponent_Conditional_7_Conditional_56_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 14)(1, "label", 29)(2, "div", 30);
    \u0275\u0275element(3, "input", 31)(4, "span", 32);
    \u0275\u0275elementEnd();
    \u0275\u0275text(5, " Aluno ativo ");
    \u0275\u0275elementEnd()();
  }
}
function AlunoFormComponent_Conditional_7_Conditional_57_Conditional_6_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 38);
    \u0275\u0275text(1, "\u2713 Gradua\xE7\xE3o registrada com sucesso!");
    \u0275\u0275elementEnd();
  }
}
function AlunoFormComponent_Conditional_7_Conditional_57_Conditional_7_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 6);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(3);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(ctx_r1.erroGrad());
  }
}
function AlunoFormComponent_Conditional_7_Conditional_57_For_16_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "option", 21);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const m_r5 = ctx.$implicit;
    \u0275\u0275property("value", m_r5.id);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(m_r5.nome);
  }
}
function AlunoFormComponent_Conditional_7_Conditional_57_Conditional_17_For_7_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "option", 21);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const f_r7 = ctx.$implicit;
    \u0275\u0275property("value", f_r7.id);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(f_r7.nome);
  }
}
function AlunoFormComponent_Conditional_7_Conditional_57_Conditional_17_Template(rf, ctx) {
  if (rf & 1) {
    const _r6 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 14)(1, "label", 11);
    \u0275\u0275text(2, "Nova Faixa");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "select", 19);
    \u0275\u0275listener("ngModelChange", function AlunoFormComponent_Conditional_7_Conditional_57_Conditional_17_Template_select_ngModelChange_3_listener($event) {
      \u0275\u0275restoreView(_r6);
      const ctx_r1 = \u0275\u0275nextContext(3);
      return \u0275\u0275resetView(ctx_r1.faixaGradId.set($event));
    });
    \u0275\u0275elementStart(4, "option", 20);
    \u0275\u0275text(5, "\u2014 Selecione a faixa \u2014");
    \u0275\u0275elementEnd();
    \u0275\u0275repeaterCreate(6, AlunoFormComponent_Conditional_7_Conditional_57_Conditional_17_For_7_Template, 2, 2, "option", 21, _forTrack0);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(3);
    \u0275\u0275advance(3);
    \u0275\u0275property("ngModel", ctx_r1.faixaGradId())("ngModelOptions", \u0275\u0275pureFunction0(2, _c1));
    \u0275\u0275advance(3);
    \u0275\u0275repeater(ctx_r1.faixasGrad());
  }
}
function AlunoFormComponent_Conditional_7_Conditional_57_Template(rf, ctx) {
  if (rf & 1) {
    const _r4 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 33);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(1, "svg", 34);
    \u0275\u0275element(2, "circle", 35)(3, "path", 36);
    \u0275\u0275elementEnd();
    \u0275\u0275text(4, " Registrar Nova Gradua\xE7\xE3o ");
    \u0275\u0275elementEnd();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(5, "div", 37);
    \u0275\u0275template(6, AlunoFormComponent_Conditional_7_Conditional_57_Conditional_6_Template, 2, 0, "div", 38)(7, AlunoFormComponent_Conditional_7_Conditional_57_Conditional_7_Template, 2, 1, "div", 6);
    \u0275\u0275elementStart(8, "div", 9)(9, "div", 14)(10, "label", 11);
    \u0275\u0275text(11, "Modalidade");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(12, "select", 19);
    \u0275\u0275listener("ngModelChange", function AlunoFormComponent_Conditional_7_Conditional_57_Template_select_ngModelChange_12_listener($event) {
      \u0275\u0275restoreView(_r4);
      const ctx_r1 = \u0275\u0275nextContext(2);
      return \u0275\u0275resetView(ctx_r1.onModalidadeGradChange($event));
    });
    \u0275\u0275elementStart(13, "option", 20);
    \u0275\u0275text(14, "\u2014 Selecione a modalidade \u2014");
    \u0275\u0275elementEnd();
    \u0275\u0275repeaterCreate(15, AlunoFormComponent_Conditional_7_Conditional_57_For_16_Template, 2, 2, "option", 21, _forTrack0);
    \u0275\u0275elementEnd()();
    \u0275\u0275template(17, AlunoFormComponent_Conditional_7_Conditional_57_Conditional_17_Template, 8, 3, "div", 14);
    \u0275\u0275elementStart(18, "div", 39)(19, "label", 11);
    \u0275\u0275text(20, "Data do exame");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(21, "input", 40);
    \u0275\u0275listener("ngModelChange", function AlunoFormComponent_Conditional_7_Conditional_57_Template_input_ngModelChange_21_listener($event) {
      \u0275\u0275restoreView(_r4);
      const ctx_r1 = \u0275\u0275nextContext(2);
      return \u0275\u0275resetView(ctx_r1.dataGrad.set($event));
    });
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(22, "div", 41)(23, "button", 42);
    \u0275\u0275listener("click", function AlunoFormComponent_Conditional_7_Conditional_57_Template_button_click_23_listener() {
      \u0275\u0275restoreView(_r4);
      const ctx_r1 = \u0275\u0275nextContext(2);
      return \u0275\u0275resetView(ctx_r1.registrarGraduacao());
    });
    \u0275\u0275text(24);
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(2);
    \u0275\u0275advance(6);
    \u0275\u0275conditional(6, ctx_r1.gradSucesso() ? 6 : -1);
    \u0275\u0275advance();
    \u0275\u0275conditional(7, ctx_r1.erroGrad() ? 7 : -1);
    \u0275\u0275advance(5);
    \u0275\u0275property("ngModel", ctx_r1.modalidadeGradId())("ngModelOptions", \u0275\u0275pureFunction0(9, _c1));
    \u0275\u0275advance(3);
    \u0275\u0275repeater(ctx_r1.modalidades());
    \u0275\u0275advance(2);
    \u0275\u0275conditional(17, ctx_r1.faixasGrad().length > 0 ? 17 : -1);
    \u0275\u0275advance(4);
    \u0275\u0275property("ngModel", ctx_r1.dataGrad())("ngModelOptions", \u0275\u0275pureFunction0(10, _c1));
    \u0275\u0275advance(2);
    \u0275\u0275property("disabled", ctx_r1.registrandoGrad() || !ctx_r1.faixaGradId());
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1(" ", ctx_r1.registrandoGrad() ? "Registrando..." : "\u{1F94B} Registrar Gradua\xE7\xE3o", " ");
  }
}
function AlunoFormComponent_Conditional_7_Conditional_58_For_12_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "option", 21);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const t_r9 = ctx.$implicit;
    \u0275\u0275property("value", t_r9.id);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate2("", t_r9.nome, " \xB7 ", t_r9.modalidadeNome, "");
  }
}
function AlunoFormComponent_Conditional_7_Conditional_58_For_21_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "option", 21);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const m_r10 = ctx.$implicit;
    \u0275\u0275property("value", m_r10.id);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(m_r10.nome);
  }
}
function AlunoFormComponent_Conditional_7_Conditional_58_Conditional_22_For_7_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "option", 21);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const f_r12 = ctx.$implicit;
    \u0275\u0275property("value", f_r12.id);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(f_r12.nome);
  }
}
function AlunoFormComponent_Conditional_7_Conditional_58_Conditional_22_Template(rf, ctx) {
  if (rf & 1) {
    const _r11 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 14)(1, "label", 11);
    \u0275\u0275text(2, "Faixa inicial");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "select", 19);
    \u0275\u0275listener("ngModelChange", function AlunoFormComponent_Conditional_7_Conditional_58_Conditional_22_Template_select_ngModelChange_3_listener($event) {
      \u0275\u0275restoreView(_r11);
      const ctx_r1 = \u0275\u0275nextContext(3);
      return \u0275\u0275resetView(ctx_r1.faixaInicialId.set($event));
    });
    \u0275\u0275elementStart(4, "option", 20);
    \u0275\u0275text(5, "\u2014 Selecione \u2014");
    \u0275\u0275elementEnd();
    \u0275\u0275repeaterCreate(6, AlunoFormComponent_Conditional_7_Conditional_58_Conditional_22_For_7_Template, 2, 2, "option", 21, _forTrack0);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(3);
    \u0275\u0275advance(3);
    \u0275\u0275property("ngModel", ctx_r1.faixaInicialId())("ngModelOptions", \u0275\u0275pureFunction0(2, _c1));
    \u0275\u0275advance(3);
    \u0275\u0275repeater(ctx_r1.faixas());
  }
}
function AlunoFormComponent_Conditional_7_Conditional_58_Template(rf, ctx) {
  if (rf & 1) {
    const _r8 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 18);
    \u0275\u0275text(1, "Vincula\xE7\xF5es iniciais ");
    \u0275\u0275elementStart(2, "span", 43);
    \u0275\u0275text(3, "(opcional)");
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(4, "div", 9)(5, "div", 14)(6, "label", 11);
    \u0275\u0275text(7, "Turma inicial");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(8, "select", 19);
    \u0275\u0275listener("ngModelChange", function AlunoFormComponent_Conditional_7_Conditional_58_Template_select_ngModelChange_8_listener($event) {
      \u0275\u0275restoreView(_r8);
      const ctx_r1 = \u0275\u0275nextContext(2);
      return \u0275\u0275resetView(ctx_r1.turmaInicialId.set($event));
    });
    \u0275\u0275elementStart(9, "option", 20);
    \u0275\u0275text(10, "\u2014 Sem turma inicial \u2014");
    \u0275\u0275elementEnd();
    \u0275\u0275repeaterCreate(11, AlunoFormComponent_Conditional_7_Conditional_58_For_12_Template, 2, 3, "option", 21, _forTrack0);
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(13, "div", 9)(14, "div", 14)(15, "label", 11);
    \u0275\u0275text(16, "Modalidade (para faixa inicial)");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(17, "select", 19);
    \u0275\u0275listener("ngModelChange", function AlunoFormComponent_Conditional_7_Conditional_58_Template_select_ngModelChange_17_listener($event) {
      \u0275\u0275restoreView(_r8);
      const ctx_r1 = \u0275\u0275nextContext(2);
      return \u0275\u0275resetView(ctx_r1.onModalidadeChange($event));
    });
    \u0275\u0275elementStart(18, "option", 20);
    \u0275\u0275text(19, "\u2014 Sem faixa inicial \u2014");
    \u0275\u0275elementEnd();
    \u0275\u0275repeaterCreate(20, AlunoFormComponent_Conditional_7_Conditional_58_For_21_Template, 2, 2, "option", 21, _forTrack0);
    \u0275\u0275elementEnd()();
    \u0275\u0275template(22, AlunoFormComponent_Conditional_7_Conditional_58_Conditional_22_Template, 8, 3, "div", 14);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(2);
    \u0275\u0275advance(8);
    \u0275\u0275property("ngModel", ctx_r1.turmaInicialId())("ngModelOptions", \u0275\u0275pureFunction0(5, _c1));
    \u0275\u0275advance(3);
    \u0275\u0275repeater(ctx_r1.turmas());
    \u0275\u0275advance(6);
    \u0275\u0275property("ngModel", ctx_r1.modalidadeInicialId())("ngModelOptions", \u0275\u0275pureFunction0(6, _c1));
    \u0275\u0275advance(3);
    \u0275\u0275repeater(ctx_r1.modalidades());
    \u0275\u0275advance(2);
    \u0275\u0275conditional(22, ctx_r1.faixas().length > 0 ? 22 : -1);
  }
}
function AlunoFormComponent_Conditional_7_Template(rf, ctx) {
  if (rf & 1) {
    const _r1 = \u0275\u0275getCurrentView();
    \u0275\u0275template(0, AlunoFormComponent_Conditional_7_Conditional_0_Template, 2, 1, "div", 6)(1, AlunoFormComponent_Conditional_7_Conditional_1_Template, 5, 1, "div", 7);
    \u0275\u0275elementStart(2, "form", 8);
    \u0275\u0275listener("ngSubmit", function AlunoFormComponent_Conditional_7_Template_form_ngSubmit_2_listener() {
      \u0275\u0275restoreView(_r1);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.salvar());
    });
    \u0275\u0275elementStart(3, "div", 9)(4, "div", 10)(5, "label", 11);
    \u0275\u0275text(6, "Nome completo *");
    \u0275\u0275elementEnd();
    \u0275\u0275element(7, "input", 12);
    \u0275\u0275template(8, AlunoFormComponent_Conditional_7_Conditional_8_Template, 2, 0, "span", 13);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(9, "div", 14)(10, "label", 11);
    \u0275\u0275text(11, "Telefone *");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(12, "input", 15);
    \u0275\u0275listener("input", function AlunoFormComponent_Conditional_7_Template_input_input_12_listener($event) {
      \u0275\u0275restoreView(_r1);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.mascaraTelefone($event));
    });
    \u0275\u0275elementEnd();
    \u0275\u0275template(13, AlunoFormComponent_Conditional_7_Conditional_13_Template, 2, 0, "span", 13);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(14, "div", 9)(15, "div", 14)(16, "label", 11);
    \u0275\u0275text(17, "E-mail");
    \u0275\u0275elementEnd();
    \u0275\u0275element(18, "input", 16);
    \u0275\u0275template(19, AlunoFormComponent_Conditional_7_Conditional_19_Template, 2, 0, "span", 13);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(20, "div", 14)(21, "label", 11);
    \u0275\u0275text(22, "Data de Nascimento *");
    \u0275\u0275elementEnd();
    \u0275\u0275element(23, "input", 17);
    \u0275\u0275template(24, AlunoFormComponent_Conditional_7_Conditional_24_Template, 2, 0, "span", 13);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(25, "div", 18);
    \u0275\u0275text(26, "Plano e Financeiro");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(27, "div", 9)(28, "div", 10)(29, "label", 11);
    \u0275\u0275text(30, "Plano da Academia");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(31, "select", 19);
    \u0275\u0275listener("ngModelChange", function AlunoFormComponent_Conditional_7_Template_select_ngModelChange_31_listener($event) {
      \u0275\u0275restoreView(_r1);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.planoSelecionadoId.set($event));
    });
    \u0275\u0275elementStart(32, "option", 20);
    \u0275\u0275text(33, "\u2014 Sem plano vinculado \u2014");
    \u0275\u0275elementEnd();
    \u0275\u0275repeaterCreate(34, AlunoFormComponent_Conditional_7_For_35_Template, 3, 11, "option", 21, _forTrack0);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(36, "div", 14)(37, "label", 11);
    \u0275\u0275text(38, "Dia de Vencimento");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(39, "input", 22);
    \u0275\u0275listener("ngModelChange", function AlunoFormComponent_Conditional_7_Template_input_ngModelChange_39_listener($event) {
      \u0275\u0275restoreView(_r1);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.diaVencimento.set($event));
    });
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(40, "span", 23);
    \u0275\u0275text(41, "Dia do m\xEAs em que vence");
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(42, "div", 18);
    \u0275\u0275text(43, " Contato de Emerg\xEAncia / Respons\xE1vel ");
    \u0275\u0275template(44, AlunoFormComponent_Conditional_7_Conditional_44_Template, 2, 0, "span", 24);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(45, "div", 9)(46, "div", 14)(47, "label", 11);
    \u0275\u0275text(48);
    \u0275\u0275elementEnd();
    \u0275\u0275element(49, "input", 25);
    \u0275\u0275template(50, AlunoFormComponent_Conditional_7_Conditional_50_Template, 2, 0, "span", 13);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(51, "div", 14)(52, "label", 11);
    \u0275\u0275text(53);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(54, "input", 26);
    \u0275\u0275listener("input", function AlunoFormComponent_Conditional_7_Template_input_input_54_listener($event) {
      \u0275\u0275restoreView(_r1);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.mascaraEmergTel($event));
    });
    \u0275\u0275elementEnd();
    \u0275\u0275template(55, AlunoFormComponent_Conditional_7_Conditional_55_Template, 2, 0, "span", 13);
    \u0275\u0275elementEnd()();
    \u0275\u0275template(56, AlunoFormComponent_Conditional_7_Conditional_56_Template, 6, 0, "div", 14)(57, AlunoFormComponent_Conditional_7_Conditional_57_Template, 25, 11)(58, AlunoFormComponent_Conditional_7_Conditional_58_Template, 23, 7);
    \u0275\u0275elementStart(59, "div", 27)(60, "a", 3);
    \u0275\u0275text(61, "Cancelar");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(62, "button", 28);
    \u0275\u0275text(63);
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    let tmp_4_0;
    let tmp_5_0;
    let tmp_6_0;
    let tmp_7_0;
    let tmp_15_0;
    let tmp_17_0;
    const ctx_r1 = \u0275\u0275nextContext();
    \u0275\u0275conditional(0, ctx_r1.erro() ? 0 : -1);
    \u0275\u0275advance();
    \u0275\u0275conditional(1, ctx_r1.editandoId() && ctx_r1.matricula() ? 1 : -1);
    \u0275\u0275advance();
    \u0275\u0275property("formGroup", ctx_r1.form);
    \u0275\u0275advance(6);
    \u0275\u0275conditional(8, ((tmp_4_0 = ctx_r1.form.get("nome")) == null ? null : tmp_4_0.invalid) && ((tmp_4_0 = ctx_r1.form.get("nome")) == null ? null : tmp_4_0.touched) ? 8 : -1);
    \u0275\u0275advance(5);
    \u0275\u0275conditional(13, ((tmp_5_0 = ctx_r1.form.get("telefone")) == null ? null : tmp_5_0.invalid) && ((tmp_5_0 = ctx_r1.form.get("telefone")) == null ? null : tmp_5_0.touched) ? 13 : -1);
    \u0275\u0275advance(6);
    \u0275\u0275conditional(19, ((tmp_6_0 = ctx_r1.form.get("email")) == null ? null : tmp_6_0.invalid) && ((tmp_6_0 = ctx_r1.form.get("email")) == null ? null : tmp_6_0.touched) ? 19 : -1);
    \u0275\u0275advance(5);
    \u0275\u0275conditional(24, ((tmp_7_0 = ctx_r1.form.get("dataNascimento")) == null ? null : tmp_7_0.invalid) && ((tmp_7_0 = ctx_r1.form.get("dataNascimento")) == null ? null : tmp_7_0.touched) ? 24 : -1);
    \u0275\u0275advance(7);
    \u0275\u0275property("ngModel", ctx_r1.planoSelecionadoId())("ngModelOptions", \u0275\u0275pureFunction0(21, _c1));
    \u0275\u0275advance(3);
    \u0275\u0275repeater(ctx_r1.planosDisponiveis());
    \u0275\u0275advance(5);
    \u0275\u0275property("ngModel", ctx_r1.diaVencimento())("ngModelOptions", \u0275\u0275pureFunction0(22, _c1));
    \u0275\u0275advance(5);
    \u0275\u0275conditional(44, ctx_r1.menorDeIdade() ? 44 : -1);
    \u0275\u0275advance(4);
    \u0275\u0275textInterpolate1("Nome do respons\xE1vel", ctx_r1.menorDeIdade() ? " *" : "", "");
    \u0275\u0275advance(2);
    \u0275\u0275conditional(50, ((tmp_15_0 = ctx_r1.form.get("contatoEmergenciaNome")) == null ? null : tmp_15_0.invalid) && ((tmp_15_0 = ctx_r1.form.get("contatoEmergenciaNome")) == null ? null : tmp_15_0.touched) ? 50 : -1);
    \u0275\u0275advance(3);
    \u0275\u0275textInterpolate1("Telefone do respons\xE1vel", ctx_r1.menorDeIdade() ? " *" : "", "");
    \u0275\u0275advance(2);
    \u0275\u0275conditional(55, ((tmp_17_0 = ctx_r1.form.get("contatoEmergenciaTelefone")) == null ? null : tmp_17_0.invalid) && ((tmp_17_0 = ctx_r1.form.get("contatoEmergenciaTelefone")) == null ? null : tmp_17_0.touched) ? 55 : -1);
    \u0275\u0275advance();
    \u0275\u0275conditional(56, ctx_r1.editandoId() ? 56 : -1);
    \u0275\u0275advance();
    \u0275\u0275conditional(57, ctx_r1.editandoId() ? 57 : -1);
    \u0275\u0275advance();
    \u0275\u0275conditional(58, !ctx_r1.editandoId() ? 58 : -1);
    \u0275\u0275advance(4);
    \u0275\u0275property("disabled", ctx_r1.salvando());
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1(" ", ctx_r1.salvando() ? "Salvando..." : ctx_r1.editandoId() ? "Salvar altera\xE7\xF5es" : "Cadastrar aluno", " ");
  }
}
var AlunoFormComponent = class _AlunoFormComponent {
  constructor() {
    this.alunoService = inject(AlunoService);
    this.turmaService = inject(TurmaService);
    this.graduacaoService = inject(GraduacaoService);
    this.modalidadeService = inject(ModalidadeService);
    this.authService = inject(AuthService);
    this.planoService = inject(PlanoService);
    this.router = inject(Router);
    this.route = inject(ActivatedRoute);
    this.fb = inject(FormBuilder);
    this.destroy$ = new Subject();
    this.editandoId = signal(null);
    this.matricula = signal(null);
    this.salvando = signal(false);
    this.carregando = signal(false);
    this.erro = signal("");
    this.turmas = signal([]);
    this.modalidades = signal([]);
    this.faixas = signal([]);
    this.planosDisponiveis = signal([]);
    this.turmaInicialId = signal("");
    this.modalidadeInicialId = signal("");
    this.faixaInicialId = signal("");
    this.planoSelecionadoId = signal("");
    this.diaVencimento = signal(null);
    this.modalidadeGradId = signal("");
    this.faixaGradId = signal("");
    this.faixasGrad = signal([]);
    this.dataGrad = signal((/* @__PURE__ */ new Date()).toISOString().split("T")[0]);
    this.registrandoGrad = signal(false);
    this.gradSucesso = signal(false);
    this.erroGrad = signal("");
    this.form = this.fb.group({
      nome: ["", [Validators.required, Validators.minLength(3)]],
      email: ["", Validators.email],
      telefone: ["", Validators.required],
      dataNascimento: ["", Validators.required],
      contatoEmergenciaNome: [""],
      contatoEmergenciaTelefone: [""],
      tipoPlano: [""],
      ativo: [true]
    });
    this.menorDeIdade = computed(() => this.calcularMenorDeIdade(this.form.get("dataNascimento")?.value ?? ""));
  }
  ngOnInit() {
    this.form.get("dataNascimento").valueChanges.pipe(takeUntil(this.destroy$)).subscribe((val) => {
      this.atualizarValidadoresResponsavel(this.calcularMenorDeIdade(val ?? ""));
    });
    const id = this.route.snapshot.paramMap.get("id");
    if (id) {
      this.editandoId.set(id);
      this.carregando.set(true);
      this.alunoService.getById(id).subscribe({
        next: (res) => {
          if (res.dados) {
            const d = res.dados;
            this.matricula.set(d.matricula ?? null);
            this.form.patchValue({
              nome: d.nome,
              email: d.email ?? "",
              telefone: d.telefone ?? "",
              dataNascimento: d.dataNascimento ?? "",
              contatoEmergenciaNome: d.contatoEmergenciaNome ?? "",
              contatoEmergenciaTelefone: d.contatoEmergenciaTelefone ?? "",
              tipoPlano: d.tipoPlano ?? "",
              ativo: d.ativo
            });
            this.planoSelecionadoId.set(d.planoId ?? "");
            this.diaVencimento.set(d.diaVencimento ?? null);
          }
          this.carregando.set(false);
        },
        error: () => {
          this.erro.set("Erro ao carregar dados do aluno.");
          this.carregando.set(false);
        }
      });
    }
    this.planoService.listar().subscribe({ next: (r) => this.planosDisponiveis.set((r.dados ?? []).filter((p) => p.ativo)) });
    if (!this.editandoId()) {
      this.turmaService.getAll({ ativo: true }).subscribe({ next: (r) => this.turmas.set(r.dados ?? []) });
    }
    this.modalidadeService.getAll().subscribe({ next: (r) => this.modalidades.set(r.dados ?? []) });
  }
  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }
  onModalidadeChange(modalidadeId) {
    this.modalidadeInicialId.set(modalidadeId);
    this.faixaInicialId.set("");
    this.faixas.set([]);
    if (!modalidadeId)
      return;
    this.graduacaoService.getFaixasByModalidade(modalidadeId).subscribe({
      next: (r) => this.faixas.set(r.dados ?? [])
    });
  }
  onModalidadeGradChange(modalidadeId) {
    this.modalidadeGradId.set(modalidadeId);
    this.faixaGradId.set("");
    this.faixasGrad.set([]);
    if (!modalidadeId)
      return;
    this.graduacaoService.getFaixasByModalidade(modalidadeId).subscribe({
      next: (r) => this.faixasGrad.set(r.dados ?? [])
    });
  }
  registrarGraduacao() {
    const alunoId = this.editandoId();
    const faixaId = this.faixaGradId();
    const professorId = this.authService.currentUser()?.sub;
    if (!alunoId || !faixaId || !professorId) {
      this.erroGrad.set("Selecione modalidade e faixa.");
      return;
    }
    this.registrandoGrad.set(true);
    this.erroGrad.set("");
    this.gradSucesso.set(false);
    this.graduacaoService.registrar({ alunoId, faixaId, dataExame: this.dataGrad(), professorId, aprovado: true }).subscribe({
      next: () => {
        this.registrandoGrad.set(false);
        this.gradSucesso.set(true);
        this.modalidadeGradId.set("");
        this.faixaGradId.set("");
        this.faixasGrad.set([]);
      },
      error: (err) => {
        this.erroGrad.set(err.error?.mensagem ?? "Erro ao registrar gradua\xE7\xE3o.");
        this.registrandoGrad.set(false);
      }
    });
  }
  mascaraTelefone(event) {
    const input = event.target;
    const nums = input.value.replace(/\D/g, "").slice(0, 11);
    let v = "";
    if (nums.length > 6)
      v = `(${nums.slice(0, 2)}) ${nums.slice(2, 7)}-${nums.slice(7)}`;
    else if (nums.length > 2)
      v = `(${nums.slice(0, 2)}) ${nums.slice(2)}`;
    else if (nums.length > 0)
      v = `(${nums}`;
    input.value = v;
    this.form.get("telefone")?.setValue(v, { emitEvent: false });
  }
  mascaraEmergTel(event) {
    const input = event.target;
    const nums = input.value.replace(/\D/g, "").slice(0, 11);
    let v = "";
    if (nums.length > 6)
      v = `(${nums.slice(0, 2)}) ${nums.slice(2, 7)}-${nums.slice(7)}`;
    else if (nums.length > 2)
      v = `(${nums.slice(0, 2)}) ${nums.slice(2)}`;
    else if (nums.length > 0)
      v = `(${nums}`;
    input.value = v;
    this.form.get("contatoEmergenciaTelefone")?.setValue(v, { emitEvent: false });
  }
  salvar() {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    this.salvando.set(true);
    this.erro.set("");
    const v = this.form.value;
    const id = this.editandoId();
    const base = {
      nome: v.nome,
      email: v.email || void 0,
      telefone: v.telefone,
      dataNascimento: v.dataNascimento || void 0,
      contatoEmergenciaNome: v.contatoEmergenciaNome || void 0,
      contatoEmergenciaTelefone: v.contatoEmergenciaTelefone || void 0,
      tipoPlano: v.tipoPlano || void 0,
      planoId: this.planoSelecionadoId() || void 0,
      diaVencimento: this.diaVencimento() ?? void 0
    };
    const req$ = id ? this.alunoService.update(id, __spreadProps(__spreadValues({}, base), { ativo: v.ativo })) : this.alunoService.create(base);
    req$.subscribe({
      next: (res) => {
        if (!res.sucesso) {
          this.erro.set(res.mensagem ?? "Erro ao salvar.");
          this.salvando.set(false);
          return;
        }
        if (id) {
          this.router.navigate(["/app/alunos"]);
          return;
        }
        const alunoId = res.dados.id;
        this.vincularOpcionais(alunoId);
      },
      error: (err) => {
        this.erro.set(err.error?.mensagem ?? "Erro ao salvar.");
        this.salvando.set(false);
      }
    });
  }
  vincularOpcionais(alunoId) {
    const turmaId = this.turmaInicialId();
    const faixaId = this.faixaInicialId();
    const professorId = this.authService.currentUser()?.sub;
    const hoje = (/* @__PURE__ */ new Date()).toISOString().split("T")[0];
    const pendentes = [];
    if (turmaId) {
      pendentes.push(this.turmaService.matricular(turmaId, alunoId).toPromise());
    }
    if (faixaId && professorId) {
      pendentes.push(this.graduacaoService.registrar({
        alunoId,
        faixaId,
        dataExame: hoje,
        professorId,
        aprovado: true
      }).toPromise());
    }
    Promise.allSettled(pendentes).then(() => {
      this.router.navigate(["/app/alunos", alunoId]);
    });
  }
  calcularMenorDeIdade(dataNasc) {
    if (!dataNasc)
      return false;
    const nasc = new Date(dataNasc);
    const hoje = /* @__PURE__ */ new Date();
    const aniv = new Date(hoje.getFullYear(), nasc.getMonth(), nasc.getDate());
    const idade = hoje.getFullYear() - nasc.getFullYear() - (hoje < aniv ? 1 : 0);
    return idade < 18;
  }
  atualizarValidadoresResponsavel(menorDeIdade) {
    const nome = this.form.get("contatoEmergenciaNome");
    const tel = this.form.get("contatoEmergenciaTelefone");
    if (menorDeIdade) {
      nome.setValidators(Validators.required);
      tel.setValidators(Validators.required);
    } else {
      nome.clearValidators();
      tel.clearValidators();
    }
    nome.updateValueAndValidity({ emitEvent: false });
    tel.updateValueAndValidity({ emitEvent: false });
  }
  static {
    this.\u0275fac = function AlunoFormComponent_Factory(t) {
      return new (t || _AlunoFormComponent)();
    };
  }
  static {
    this.\u0275cmp = /* @__PURE__ */ \u0275\u0275defineComponent({ type: _AlunoFormComponent, selectors: [["app-aluno-form"]], standalone: true, features: [\u0275\u0275StandaloneFeature], decls: 8, vars: 2, consts: [[1, "page-container"], [1, "page-header"], [1, "page-title"], ["routerLink", "/app/alunos", 1, "btn-secondary"], [1, "skeleton-list"], [1, "skeleton-row"], [1, "alert-error"], [1, "summary-card", 2, "margin-bottom", "16px"], [1, "form-card", 3, "ngSubmit", "formGroup"], [1, "form-row"], [1, "form-group", 2, "flex", "2"], [1, "form-label"], ["formControlName", "nome", "placeholder", "Nome do aluno", 1, "form-input"], [1, "form-error"], [1, "form-group"], ["formControlName", "telefone", "placeholder", "(11) 99999-9999", "inputmode", "numeric", 1, "form-input", 3, "input"], ["formControlName", "email", "type", "email", "placeholder", "email@exemplo.com", 1, "form-input"], ["formControlName", "dataNascimento", "type", "date", 1, "form-input"], [1, "form-section-title"], [1, "form-input", 3, "ngModelChange", "ngModel", "ngModelOptions"], ["value", ""], [3, "value"], ["type", "number", "placeholder", "Ex: 10", "min", "1", "max", "31", 1, "form-input", 3, "ngModelChange", "ngModel", "ngModelOptions"], [2, "font-size", "11px", "color", "var(--app-text-3)", "margin-top", "4px"], [1, "badge-menor"], ["formControlName", "contatoEmergenciaNome", "placeholder", "Nome do respons\xE1vel", 1, "form-input"], ["formControlName", "contatoEmergenciaTelefone", "placeholder", "(11) 99999-9999", "inputmode", "numeric", 1, "form-input", 3, "input"], [1, "form-actions"], ["type", "submit", 1, "btn-primary", 3, "disabled"], [1, "toggle-label"], [1, "toggle-switch"], ["formControlName", "ativo", "type", "checkbox"], [1, "toggle-slider"], [1, "form-section-title", 2, "margin-top", "24px"], ["width", "14", "height", "14", "fill", "none", "stroke", "currentColor", "stroke-width", "2", "viewBox", "0 0 24 24"], ["cx", "12", "cy", "8", "r", "6"], ["d", "M15.477 12.89L17 22l-5-3-5 3 1.523-9.11"], [1, "grad-card"], [1, "alert-success"], [1, "form-group", 2, "max-width", "160px"], ["type", "date", 1, "form-input", 3, "ngModelChange", "ngModel", "ngModelOptions"], [2, "display", "flex", "justify-content", "flex-end", "margin-top", "4px"], ["type", "button", 1, "btn-primary", 2, "background", "#a855f7", "border-color", "#a855f7", 3, "click", "disabled"], [2, "font-weight", "400", "text-transform", "none", "letter-spacing", "0", "color", "var(--app-text-3)"]], template: function AlunoFormComponent_Template(rf, ctx) {
      if (rf & 1) {
        \u0275\u0275elementStart(0, "div", 0)(1, "div", 1)(2, "h1", 2);
        \u0275\u0275text(3);
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(4, "a", 3);
        \u0275\u0275text(5, "\u2190 Voltar");
        \u0275\u0275elementEnd()();
        \u0275\u0275template(6, AlunoFormComponent_Conditional_6_Template, 3, 1, "div", 4)(7, AlunoFormComponent_Conditional_7_Template, 64, 23);
        \u0275\u0275elementEnd();
      }
      if (rf & 2) {
        \u0275\u0275advance(3);
        \u0275\u0275textInterpolate(ctx.editandoId() ? "Editar Aluno" : "Novo Aluno");
        \u0275\u0275advance(3);
        \u0275\u0275conditional(6, ctx.carregando() ? 6 : 7);
      }
    }, dependencies: [CommonModule, CurrencyPipe, ReactiveFormsModule, \u0275NgNoValidate, NgSelectOption, \u0275NgSelectMultipleOption, DefaultValueAccessor, NumberValueAccessor, CheckboxControlValueAccessor, SelectControlValueAccessor, NgControlStatus, NgControlStatusGroup, MinValidator, MaxValidator, FormGroupDirective, FormControlName, FormsModule, NgModel, RouterLink], styles: [".form-section-title[_ngcontent-%COMP%] { font-size: 13px; font-weight: 600; color: var(--color-text-secondary); text-transform: uppercase; letter-spacing: 0.05em; margin: 16px 0 8px; display: flex; align-items: center; gap: 10px; }\n  .badge-menor[_ngcontent-%COMP%] { font-size: 11px; font-weight: 600; padding: 2px 8px; border-radius: 99px; background: rgba(251,146,60,0.15); color: #f97316; text-transform: none; letter-spacing: 0; }\n  .form-error[_ngcontent-%COMP%] { font-size: 12px; color: var(--color-danger, #ef4444); margin-top: 4px; display: block; }\n  .toggle-label[_ngcontent-%COMP%] { display: flex; align-items: center; gap: 12px; cursor: pointer; font-size: 14px; }\n  .toggle-switch[_ngcontent-%COMP%] { position: relative; width: 40px; height: 22px; }\n  .toggle-switch[_ngcontent-%COMP%]   input[_ngcontent-%COMP%] { opacity: 0; width: 0; height: 0; }\n  .toggle-slider[_ngcontent-%COMP%] { position: absolute; inset: 0; background: var(--color-border); border-radius: 99px; transition: background 0.2s; cursor: pointer; }\n  .toggle-slider[_ngcontent-%COMP%]::before { content: ''; position: absolute; height: 16px; width: 16px; left: 3px; top: 3px; background: white; border-radius: 50%; transition: transform 0.2s; }\n  .toggle-switch[_ngcontent-%COMP%]   input[_ngcontent-%COMP%]:checked    + .toggle-slider[_ngcontent-%COMP%] { background: var(--color-primary, #6366f1); }\n  .toggle-switch[_ngcontent-%COMP%]   input[_ngcontent-%COMP%]:checked    + .toggle-slider[_ngcontent-%COMP%]::before { transform: translateX(18px); }\n  .grad-card[_ngcontent-%COMP%] { background: rgba(168,85,247,0.05); border: 1px solid rgba(168,85,247,0.2); border-radius: 10px; padding: 16px; margin-top: 4px; }\n  .alert-success[_ngcontent-%COMP%] { background: rgba(34,197,94,0.12); border: 1px solid rgba(34,197,94,0.3); color: #16a34a; border-radius: 8px; padding: 10px 14px; font-size: 13px; font-weight: 600; margin-bottom: 12px; }"] });
  }
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && \u0275setClassDebugInfo(AlunoFormComponent, { className: "AlunoFormComponent" });
})();
export {
  AlunoFormComponent
};
//# sourceMappingURL=chunk-5FE3JFZB.js.map
