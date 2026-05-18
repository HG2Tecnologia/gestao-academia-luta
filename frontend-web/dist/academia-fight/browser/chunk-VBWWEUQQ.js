import {
  DefaultValueAccessor,
  FormBuilder,
  FormControlName,
  FormGroupDirective,
  FormsModule,
  NgControlStatus,
  NgControlStatusGroup,
  NgModel,
  ReactiveFormsModule,
  Validators,
  ɵNgNoValidate
} from "./chunk-JQJL26HT.js";
import {
  AcademiaService
} from "./chunk-EIUHPY3K.js";
import {
  AuthService
} from "./chunk-V3IOF26G.js";
import "./chunk-Z5CKO2JM.js";
import "./chunk-AXNOULNC.js";
import {
  CommonModule,
  inject,
  signal,
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
  ɵɵproperty,
  ɵɵpureFunction0,
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

// src/app/features/configuracoes/pages/geral/configuracoes-geral.component.ts
var _c0 = () => [1, 2, 3];
function ConfiguracoesGeralComponent_Conditional_7_For_2_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275element(0, "div", 5);
  }
}
function ConfiguracoesGeralComponent_Conditional_7_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 4);
    \u0275\u0275repeaterCreate(1, ConfiguracoesGeralComponent_Conditional_7_For_2_Template, 1, 0, "div", 5, \u0275\u0275repeaterTrackByIdentity);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    \u0275\u0275advance();
    \u0275\u0275repeater(\u0275\u0275pureFunction0(0, _c0));
  }
}
function ConfiguracoesGeralComponent_Conditional_8_Conditional_0_Template(rf, ctx) {
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
function ConfiguracoesGeralComponent_Conditional_8_Conditional_1_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 7);
    \u0275\u0275text(1, "\u2713 Dados salvos com sucesso!");
    \u0275\u0275elementEnd();
  }
}
function ConfiguracoesGeralComponent_Conditional_8_Conditional_19_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 21);
    \u0275\u0275text(1, "Nome \xE9 obrigat\xF3rio");
    \u0275\u0275elementEnd();
  }
}
function ConfiguracoesGeralComponent_Conditional_8_Conditional_29_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 21);
    \u0275\u0275text(1, "E-mail inv\xE1lido");
    \u0275\u0275elementEnd();
  }
}
function ConfiguracoesGeralComponent_Conditional_8_For_98_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "code", 48);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const v_r3 = ctx.$implicit;
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(v_r3);
  }
}
function ConfiguracoesGeralComponent_Conditional_8_Conditional_99_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 49);
    \u0275\u0275text(1, "\u2713 Template salvo com sucesso!");
    \u0275\u0275elementEnd();
  }
}
function ConfiguracoesGeralComponent_Conditional_8_Conditional_100_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 50);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(2);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(ctx_r1.erroTemplate());
  }
}
function ConfiguracoesGeralComponent_Conditional_8_Template(rf, ctx) {
  if (rf & 1) {
    const _r1 = \u0275\u0275getCurrentView();
    \u0275\u0275template(0, ConfiguracoesGeralComponent_Conditional_8_Conditional_0_Template, 2, 1, "div", 6)(1, ConfiguracoesGeralComponent_Conditional_8_Conditional_1_Template, 2, 0, "div", 7);
    \u0275\u0275elementStart(2, "div", 8)(3, "div", 9)(4, "div", 10);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(5, "svg", 11);
    \u0275\u0275element(6, "path", 12)(7, "polyline", 13);
    \u0275\u0275elementEnd()();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(8, "div")(9, "h2", 14);
    \u0275\u0275text(10, "Informa\xE7\xF5es da Academia");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(11, "p", 15);
    \u0275\u0275text(12, "Nome, contato e dados gerais");
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(13, "form", 16);
    \u0275\u0275listener("ngSubmit", function ConfiguracoesGeralComponent_Conditional_8_Template_form_ngSubmit_13_listener() {
      \u0275\u0275restoreView(_r1);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.salvarInfo());
    });
    \u0275\u0275elementStart(14, "div", 17)(15, "div", 18)(16, "label", 19);
    \u0275\u0275text(17, "Nome da academia *");
    \u0275\u0275elementEnd();
    \u0275\u0275element(18, "input", 20);
    \u0275\u0275template(19, ConfiguracoesGeralComponent_Conditional_8_Conditional_19_Template, 2, 0, "span", 21);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(20, "div", 22)(21, "label", 19);
    \u0275\u0275text(22, "Telefone");
    \u0275\u0275elementEnd();
    \u0275\u0275element(23, "input", 23);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(24, "div", 17)(25, "div", 18)(26, "label", 19);
    \u0275\u0275text(27, "E-mail de contato *");
    \u0275\u0275elementEnd();
    \u0275\u0275element(28, "input", 24);
    \u0275\u0275template(29, ConfiguracoesGeralComponent_Conditional_8_Conditional_29_Template, 2, 0, "span", 21);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(30, "div", 22)(31, "label", 19);
    \u0275\u0275text(32, "Subdom\xEDnio");
    \u0275\u0275elementEnd();
    \u0275\u0275element(33, "input", 25);
    \u0275\u0275elementStart(34, "span", 26);
    \u0275\u0275text(35, "N\xE3o pode ser alterado");
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(36, "div", 27)(37, "button", 28);
    \u0275\u0275text(38);
    \u0275\u0275elementEnd()()()();
    \u0275\u0275elementStart(39, "div", 8)(40, "div", 9)(41, "div", 10);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(42, "svg", 11);
    \u0275\u0275element(43, "rect", 29)(44, "path", 30);
    \u0275\u0275elementEnd()();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(45, "div")(46, "h2", 14);
    \u0275\u0275text(47, "Acesso & Seguran\xE7a");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(48, "p", 15);
    \u0275\u0275text(49, "Credenciais e autentica\xE7\xE3o do administrador");
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(50, "div", 31)(51, "div", 32)(52, "span", 33);
    \u0275\u0275text(53, "URL de acesso");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(54, "span", 34);
    \u0275\u0275text(55);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(56, "div", 32)(57, "span", 33);
    \u0275\u0275text(58, "E-mail do administrador");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(59, "span", 34);
    \u0275\u0275text(60);
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(61, "div", 35)(62, "button", 36);
    \u0275\u0275listener("click", function ConfiguracoesGeralComponent_Conditional_8_Template_button_click_62_listener() {
      \u0275\u0275restoreView(_r1);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.abrirModalSenha());
    });
    \u0275\u0275text(63, " Alterar senha ");
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(64, "div", 8)(65, "div", 9)(66, "div", 10);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(67, "svg", 11);
    \u0275\u0275element(68, "circle", 37)(69, "path", 38);
    \u0275\u0275elementEnd()();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(70, "div")(71, "h2", 14);
    \u0275\u0275text(72, "Identidade Visual");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(73, "p", 15);
    \u0275\u0275text(74, "Logo e cores da academia");
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(75, "div", 39)(76, "div", 40);
    \u0275\u0275text(77);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(78, "div")(79, "p", 41);
    \u0275\u0275text(80, "Logo da academia");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(81, "p", 42);
    \u0275\u0275text(82, " Upload de imagem dispon\xEDvel em breve. O logo aparecer\xE1 no app e nos relat\xF3rios. ");
    \u0275\u0275elementEnd()()()();
    \u0275\u0275elementStart(83, "div", 8)(84, "div", 9)(85, "div", 10);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(86, "svg", 11);
    \u0275\u0275element(87, "path", 43)(88, "polyline", 44)(89, "line", 45)(90, "line", 46);
    \u0275\u0275elementEnd()();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(91, "div")(92, "h2", 14);
    \u0275\u0275text(93, "Template de Contrato");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(94, "p", 15);
    \u0275\u0275text(95, "HTML exibido nos contratos gerados. Use as vari\xE1veis abaixo para personalizar.");
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(96, "div", 47);
    \u0275\u0275repeaterCreate(97, ConfiguracoesGeralComponent_Conditional_8_For_98_Template, 2, 1, "code", 48, \u0275\u0275repeaterTrackByIdentity);
    \u0275\u0275elementEnd();
    \u0275\u0275template(99, ConfiguracoesGeralComponent_Conditional_8_Conditional_99_Template, 2, 0, "div", 49)(100, ConfiguracoesGeralComponent_Conditional_8_Conditional_100_Template, 2, 1, "div", 50);
    \u0275\u0275elementStart(101, "textarea", 51);
    \u0275\u0275listener("ngModelChange", function ConfiguracoesGeralComponent_Conditional_8_Template_textarea_ngModelChange_101_listener($event) {
      \u0275\u0275restoreView(_r1);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.templateContrato.set($event));
    });
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(102, "div", 52)(103, "button", 53);
    \u0275\u0275listener("click", function ConfiguracoesGeralComponent_Conditional_8_Template_button_click_103_listener() {
      \u0275\u0275restoreView(_r1);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.restaurarTemplatepadrao());
    });
    \u0275\u0275text(104, "Restaurar padr\xE3o");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(105, "button", 54);
    \u0275\u0275listener("click", function ConfiguracoesGeralComponent_Conditional_8_Template_button_click_105_listener() {
      \u0275\u0275restoreView(_r1);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.salvarTemplate());
    });
    \u0275\u0275text(106);
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(107, "div", 55)(108, "div", 9)(109, "div", 56);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(110, "svg", 11);
    \u0275\u0275element(111, "path", 57)(112, "line", 58)(113, "line", 59);
    \u0275\u0275elementEnd()();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(114, "div")(115, "h2", 60);
    \u0275\u0275text(116, "Zona de Perigo");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(117, "p", 15);
    \u0275\u0275text(118, "A\xE7\xF5es irrevers\xEDveis");
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(119, "div", 61)(120, "div")(121, "p", 62);
    \u0275\u0275text(122, "Exportar dados da academia");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(123, "p", 42);
    \u0275\u0275text(124, "Baixar todos os dados em formato JSON/CSV. (Em breve)");
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(125, "button", 63);
    \u0275\u0275text(126, "Exportar dados");
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    let tmp_4_0;
    let tmp_5_0;
    let tmp_6_0;
    let tmp_9_0;
    let tmp_10_0;
    let tmp_11_0;
    const ctx_r1 = \u0275\u0275nextContext();
    \u0275\u0275conditional(0, ctx_r1.erro() ? 0 : -1);
    \u0275\u0275advance();
    \u0275\u0275conditional(1, ctx_r1.salvoOk() ? 1 : -1);
    \u0275\u0275advance(12);
    \u0275\u0275property("formGroup", ctx_r1.formInfo);
    \u0275\u0275advance(6);
    \u0275\u0275conditional(19, ((tmp_4_0 = ctx_r1.formInfo.get("nome")) == null ? null : tmp_4_0.invalid) && ((tmp_4_0 = ctx_r1.formInfo.get("nome")) == null ? null : tmp_4_0.touched) ? 19 : -1);
    \u0275\u0275advance(10);
    \u0275\u0275conditional(29, ((tmp_5_0 = ctx_r1.formInfo.get("email")) == null ? null : tmp_5_0.invalid) && ((tmp_5_0 = ctx_r1.formInfo.get("email")) == null ? null : tmp_5_0.touched) ? 29 : -1);
    \u0275\u0275advance(4);
    \u0275\u0275property("value", (tmp_6_0 = (tmp_6_0 = ctx_r1.academia()) == null ? null : tmp_6_0.subdominio) !== null && tmp_6_0 !== void 0 ? tmp_6_0 : "");
    \u0275\u0275advance(4);
    \u0275\u0275property("disabled", ctx_r1.salvando());
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1(" ", ctx_r1.salvando() ? "Salvando..." : "Salvar informa\xE7\xF5es", " ");
    \u0275\u0275advance(17);
    \u0275\u0275textInterpolate1("", (tmp_9_0 = ctx_r1.academia()) == null ? null : tmp_9_0.subdominio, ".tatame.app");
    \u0275\u0275advance(5);
    \u0275\u0275textInterpolate((tmp_10_0 = ctx_r1.academia()) == null ? null : tmp_10_0.email);
    \u0275\u0275advance(17);
    \u0275\u0275textInterpolate(ctx_r1.iniciais((tmp_11_0 = (tmp_11_0 = ctx_r1.academia()) == null ? null : tmp_11_0.nome) !== null && tmp_11_0 !== void 0 ? tmp_11_0 : "A"));
    \u0275\u0275advance(20);
    \u0275\u0275repeater(ctx_r1.variaveisContrato);
    \u0275\u0275advance(2);
    \u0275\u0275conditional(99, ctx_r1.salvoTemplateOk() ? 99 : -1);
    \u0275\u0275advance();
    \u0275\u0275conditional(100, ctx_r1.erroTemplate() ? 100 : -1);
    \u0275\u0275advance();
    \u0275\u0275property("ngModel", ctx_r1.templateContrato());
    \u0275\u0275advance(4);
    \u0275\u0275property("disabled", ctx_r1.salvandoTemplate());
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1(" ", ctx_r1.salvandoTemplate() ? "Salvando..." : "Salvar template", " ");
  }
}
function ConfiguracoesGeralComponent_Conditional_9_Conditional_7_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 68);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(2);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(ctx_r1.erroSenha());
  }
}
function ConfiguracoesGeralComponent_Conditional_9_Conditional_8_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 69);
    \u0275\u0275text(1, "\u2713 Senha alterada com sucesso!");
    \u0275\u0275elementEnd();
  }
}
function ConfiguracoesGeralComponent_Conditional_9_Template(rf, ctx) {
  if (rf & 1) {
    const _r4 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 64);
    \u0275\u0275listener("click", function ConfiguracoesGeralComponent_Conditional_9_Template_div_click_0_listener() {
      \u0275\u0275restoreView(_r4);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.fecharModalSenha());
    });
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(1, "div", 65)(2, "div", 66)(3, "h3");
    \u0275\u0275text(4, "Alterar Senha");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(5, "button", 67);
    \u0275\u0275listener("click", function ConfiguracoesGeralComponent_Conditional_9_Template_button_click_5_listener() {
      \u0275\u0275restoreView(_r4);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.fecharModalSenha());
    });
    \u0275\u0275text(6, "\u2715");
    \u0275\u0275elementEnd()();
    \u0275\u0275template(7, ConfiguracoesGeralComponent_Conditional_9_Conditional_7_Template, 2, 1, "div", 68)(8, ConfiguracoesGeralComponent_Conditional_9_Conditional_8_Template, 2, 0, "div", 69);
    \u0275\u0275elementStart(9, "form", 70);
    \u0275\u0275listener("ngSubmit", function ConfiguracoesGeralComponent_Conditional_9_Template_form_ngSubmit_9_listener() {
      \u0275\u0275restoreView(_r4);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.salvarSenha());
    });
    \u0275\u0275elementStart(10, "div", 22)(11, "label", 19);
    \u0275\u0275text(12, "Senha atual");
    \u0275\u0275elementEnd();
    \u0275\u0275element(13, "input", 71);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(14, "div", 22)(15, "label", 19);
    \u0275\u0275text(16, "Nova senha");
    \u0275\u0275elementEnd();
    \u0275\u0275element(17, "input", 72);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(18, "div", 22)(19, "label", 19);
    \u0275\u0275text(20, "Confirmar nova senha");
    \u0275\u0275elementEnd();
    \u0275\u0275element(21, "input", 73);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(22, "div", 74)(23, "button", 36);
    \u0275\u0275listener("click", function ConfiguracoesGeralComponent_Conditional_9_Template_button_click_23_listener() {
      \u0275\u0275restoreView(_r4);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.fecharModalSenha());
    });
    \u0275\u0275text(24, "Cancelar");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(25, "button", 28);
    \u0275\u0275text(26, "Alterar senha");
    \u0275\u0275elementEnd()()()();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext();
    \u0275\u0275advance(7);
    \u0275\u0275conditional(7, ctx_r1.erroSenha() ? 7 : -1);
    \u0275\u0275advance();
    \u0275\u0275conditional(8, ctx_r1.senhaOk() ? 8 : -1);
    \u0275\u0275advance();
    \u0275\u0275property("formGroup", ctx_r1.formSenha);
    \u0275\u0275advance(16);
    \u0275\u0275property("disabled", ctx_r1.salvandoSenha());
  }
}
var ConfiguracoesGeralComponent = class _ConfiguracoesGeralComponent {
  constructor() {
    this.academiaService = inject(AcademiaService);
    this.authService = inject(AuthService);
    this.fb = inject(FormBuilder);
    this.academia = signal(null);
    this.carregando = signal(true);
    this.salvando = signal(false);
    this.salvoOk = signal(false);
    this.erro = signal("");
    this.modalSenhaAberto = signal(false);
    this.salvandoSenha = signal(false);
    this.erroSenha = signal("");
    this.senhaOk = signal(false);
    this.templateContrato = signal("");
    this.salvandoTemplate = signal(false);
    this.salvoTemplateOk = signal(false);
    this.erroTemplate = signal("");
    this.variaveisContrato = [
      "{{nomeAluno}}",
      "{{email}}",
      "{{telefone}}",
      "{{dataNascimento}}",
      "{{plano}}",
      "{{valor}}",
      "{{modalidade}}",
      "{{dataInicio}}",
      "{{dataFim}}",
      "{{academia}}",
      "{{dataContrato}}"
    ];
    this.formInfo = this.fb.group({
      nome: ["", Validators.required],
      email: ["", [Validators.required, Validators.email]],
      telefone: [""]
    });
    this.formSenha = this.fb.group({
      senhaAtual: ["", Validators.required],
      novaSenha: ["", [Validators.required, Validators.minLength(6)]],
      confirmarSenha: ["", Validators.required]
    });
  }
  ngOnInit() {
    this.academiaService.getCurrent().subscribe({
      next: (res) => {
        if (res.dados) {
          this.academia.set(res.dados);
          this.formInfo.patchValue({
            nome: res.dados.nome,
            email: res.dados.email,
            telefone: res.dados.telefone ?? ""
          });
          this.templateContrato.set(res.dados.templateContrato ?? "");
        }
        this.carregando.set(false);
      },
      error: () => {
        this.erro.set("Erro ao carregar dados da academia.");
        this.carregando.set(false);
      }
    });
  }
  salvarInfo() {
    if (this.formInfo.invalid) {
      this.formInfo.markAllAsTouched();
      return;
    }
    this.salvando.set(true);
    this.salvoOk.set(false);
    this.erro.set("");
    const v = this.formInfo.value;
    this.academiaService.update({
      nome: v.nome,
      email: v.email,
      telefone: v.telefone || void 0
    }).subscribe({
      next: (res) => {
        if (res.sucesso) {
          this.academia.set(res.dados ?? null);
          this.salvoOk.set(true);
        } else {
          this.erro.set(res.mensagem ?? "Erro ao salvar.");
        }
        this.salvando.set(false);
      },
      error: (err) => {
        this.erro.set(err.error?.mensagem ?? "Erro ao salvar.");
        this.salvando.set(false);
      }
    });
  }
  abrirModalSenha() {
    this.formSenha.reset();
    this.erroSenha.set("");
    this.senhaOk.set(false);
    this.modalSenhaAberto.set(true);
  }
  fecharModalSenha() {
    this.modalSenhaAberto.set(false);
  }
  salvarSenha() {
    if (this.formSenha.invalid) {
      this.formSenha.markAllAsTouched();
      return;
    }
    const v = this.formSenha.value;
    if (v.novaSenha !== v.confirmarSenha) {
      this.erroSenha.set("As senhas n\xE3o coincidem.");
      return;
    }
    this.salvandoSenha.set(true);
    this.erroSenha.set("");
    this.authService.alterarSenha(v.senhaAtual, v.novaSenha).subscribe({
      next: (res) => {
        this.salvandoSenha.set(false);
        if (res.sucesso) {
          this.senhaOk.set(true);
          setTimeout(() => this.fecharModalSenha(), 1800);
        } else {
          this.erroSenha.set(res.mensagem ?? "Erro ao alterar senha.");
        }
      },
      error: (err) => {
        this.salvandoSenha.set(false);
        this.erroSenha.set(err.error?.mensagem ?? "Erro ao alterar senha.");
      }
    });
  }
  iniciais(nome) {
    return nome.split(" ").slice(0, 2).map((p) => p[0]).join("").toUpperCase();
  }
  salvarTemplate() {
    this.salvandoTemplate.set(true);
    this.salvoTemplateOk.set(false);
    this.erroTemplate.set("");
    this.academiaService.updateTemplateContrato(this.templateContrato() || null).subscribe({
      next: (res) => {
        this.salvandoTemplate.set(false);
        if (res.sucesso)
          this.salvoTemplateOk.set(true);
        else
          this.erroTemplate.set(res.mensagem ?? "Erro ao salvar template.");
      },
      error: (err) => {
        this.salvandoTemplate.set(false);
        this.erroTemplate.set(err.error?.mensagem ?? "Erro ao salvar template.");
      }
    });
  }
  restaurarTemplatepadrao() {
    this.templateContrato.set("");
    this.salvoTemplateOk.set(false);
    this.erroTemplate.set("");
  }
  static {
    this.\u0275fac = function ConfiguracoesGeralComponent_Factory(t) {
      return new (t || _ConfiguracoesGeralComponent)();
    };
  }
  static {
    this.\u0275cmp = /* @__PURE__ */ \u0275\u0275defineComponent({ type: _ConfiguracoesGeralComponent, selectors: [["app-configuracoes-geral"]], standalone: true, features: [\u0275\u0275StandaloneFeature], decls: 10, vars: 2, consts: [[1, "page-container", 2, "max-width", "760px"], [1, "page-header"], [1, "page-title"], [1, "page-subtitle"], [1, "skeleton-list"], [1, "skeleton-row", 2, "height", "80px"], [1, "alert-error", 2, "margin-bottom", "16px"], [1, "alert-success", 2, "margin-bottom", "16px"], [1, "config-card"], [1, "config-card-header"], [1, "config-icon"], ["width", "18", "height", "18", "fill", "none", "stroke", "currentColor", "stroke-width", "2", "viewBox", "0 0 24 24"], ["d", "M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"], ["points", "9 22 9 12 15 12 15 22"], [1, "config-card-title"], [1, "config-card-sub"], [2, "display", "flex", "flex-direction", "column", "gap", "16px", 3, "ngSubmit", "formGroup"], [1, "form-row"], [1, "form-group", 2, "flex", "2"], [1, "form-label"], ["formControlName", "nome", "placeholder", "Nome da academia", 1, "form-input"], [1, "form-error"], [1, "form-group"], ["formControlName", "telefone", "placeholder", "(11) 99999-9999", 1, "form-input"], ["formControlName", "email", "type", "email", "placeholder", "contato@academia.com", 1, "form-input"], ["readonly", "", 1, "form-input", 2, "opacity", "0.5", "cursor", "not-allowed", "background", "var(--app-bg)", 3, "value"], [2, "font-size", "11px", "color", "var(--app-text-2)", "margin-top", "3px", "display", "block"], [2, "display", "flex", "justify-content", "flex-end"], ["type", "submit", 1, "btn-primary", 3, "disabled"], ["x", "3", "y", "11", "width", "18", "height", "11", "rx", "2", "ry", "2"], ["d", "M7 11V7a5 5 0 0 1 10 0v4"], [1, "info-grid"], [1, "info-item"], [1, "info-label"], [1, "info-value"], [2, "margin-top", "16px"], ["type", "button", 1, "btn-secondary", 3, "click"], ["cx", "12", "cy", "12", "r", "10"], ["d", "M12 8v4l3 3"], [2, "display", "flex", "align-items", "center", "gap", "20px"], [1, "logo-placeholder"], [2, "font-size", "13px", "color", "var(--app-text-2)", "margin", "0 0 4px"], [2, "font-size", "12px", "color", "var(--app-text-2)", "margin", "0"], ["d", "M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"], ["points", "14 2 14 8 20 8"], ["x1", "16", "y1", "13", "x2", "8", "y2", "13"], ["x1", "16", "y1", "17", "x2", "8", "y2", "17"], [1, "variaveis-grid"], [1, "variavel-chip"], [1, "alert-success", 2, "margin", "12px 0"], [1, "alert-error", 2, "margin", "12px 0"], ["rows", "16", "placeholder", "Cole aqui o HTML do seu contrato...", 1, "form-input", "template-textarea", 3, "ngModelChange", "ngModel"], [2, "display", "flex", "justify-content", "flex-end", "margin-top", "12px", "gap", "8px"], [1, "btn-secondary", 3, "click"], [1, "btn-primary", 3, "click", "disabled"], [1, "config-card", "danger-zone"], [1, "config-icon", "danger-icon"], ["d", "M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"], ["x1", "12", "y1", "9", "x2", "12", "y2", "13"], ["x1", "12", "y1", "17", "x2", "12.01", "y2", "17"], [1, "config-card-title", 2, "color", "#ef4444"], [2, "display", "flex", "align-items", "center", "justify-content", "space-between", "gap", "16px", "flex-wrap", "wrap"], [2, "font-size", "13px", "font-weight", "500", "margin", "0 0 3px"], ["disabled", "", 1, "btn-secondary", 2, "opacity", "0.5"], [1, "modal-backdrop", 3, "click"], [1, "modal"], [1, "modal-header"], [1, "modal-close", 3, "click"], [1, "alert-error", 2, "margin", "0 0 12px"], [1, "alert-success", 2, "margin", "0 0 12px"], [1, "modal-body", 3, "ngSubmit", "formGroup"], ["formControlName", "senhaAtual", "type", "password", 1, "form-input"], ["formControlName", "novaSenha", "type", "password", 1, "form-input"], ["formControlName", "confirmarSenha", "type", "password", 1, "form-input"], [1, "modal-actions"]], template: function ConfiguracoesGeralComponent_Template(rf, ctx) {
      if (rf & 1) {
        \u0275\u0275elementStart(0, "div", 0)(1, "div", 1)(2, "div")(3, "h1", 2);
        \u0275\u0275text(4, "Configura\xE7\xF5es");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(5, "p", 3);
        \u0275\u0275text(6, "Gerencie as informa\xE7\xF5es da sua academia");
        \u0275\u0275elementEnd()()();
        \u0275\u0275template(7, ConfiguracoesGeralComponent_Conditional_7_Template, 3, 1, "div", 4)(8, ConfiguracoesGeralComponent_Conditional_8_Template, 127, 16);
        \u0275\u0275elementEnd();
        \u0275\u0275template(9, ConfiguracoesGeralComponent_Conditional_9_Template, 27, 4);
      }
      if (rf & 2) {
        \u0275\u0275advance(7);
        \u0275\u0275conditional(7, ctx.carregando() ? 7 : 8);
        \u0275\u0275advance(2);
        \u0275\u0275conditional(9, ctx.modalSenhaAberto() ? 9 : -1);
      }
    }, dependencies: [CommonModule, ReactiveFormsModule, \u0275NgNoValidate, DefaultValueAccessor, NgControlStatus, NgControlStatusGroup, FormGroupDirective, FormControlName, FormsModule, NgModel], styles: [".config-card[_ngcontent-%COMP%] { background: var(--app-surface); border: 1px solid var(--app-border); border-radius: 12px; padding: 20px 24px; margin-bottom: 14px; }\n  .config-card-header[_ngcontent-%COMP%] { display: flex; align-items: flex-start; gap: 14px; margin-bottom: 20px; }\n  .config-icon[_ngcontent-%COMP%] { width: 36px; height: 36px; border-radius: 8px; background: rgba(99,102,241,0.1); color: #6366f1; display: flex; align-items: center; justify-content: center; flex-shrink: 0; margin-top: 1px; }\n  .config-card-title[_ngcontent-%COMP%] { font-size: 15px; font-weight: 700; margin: 0 0 2px; color: var(--app-text-1); }\n  .config-card-sub[_ngcontent-%COMP%] { font-size: 12px; color: var(--app-text-2); margin: 0; }\n  .danger-zone[_ngcontent-%COMP%] { border-color: rgba(239,68,68,0.25); }\n  .danger-icon[_ngcontent-%COMP%] { background: rgba(239,68,68,0.1); color: #ef4444; }\n  .info-grid[_ngcontent-%COMP%] { display: flex; flex-direction: column; gap: 10px; }\n  .info-item[_ngcontent-%COMP%] { display: flex; align-items: center; gap: 0; font-size: 13px; }\n  .info-label[_ngcontent-%COMP%] { min-width: 200px; color: var(--app-text-2); font-weight: 500; }\n  .info-value[_ngcontent-%COMP%] { font-weight: 600; color: var(--app-text-1); }\n  .logo-placeholder[_ngcontent-%COMP%] { width: 68px; height: 68px; background: #6366f1; border-radius: 12px; display: flex; align-items: center; justify-content: center; font-size: 22px; font-weight: 700; color: white; flex-shrink: 0; }\n  .form-error[_ngcontent-%COMP%] { font-size: 12px; color: #ef4444; margin-top: 4px; display: block; }\n  .alert-success[_ngcontent-%COMP%] { background: rgba(34,197,94,0.12); border: 1px solid rgba(34,197,94,0.3); color: #22c55e; padding: 10px 14px; border-radius: 8px; font-size: 13px; }\n  .variaveis-grid[_ngcontent-%COMP%] { display: flex; flex-wrap: wrap; gap: 6px; margin-bottom: 12px; }\n  .variavel-chip[_ngcontent-%COMP%] { background: rgba(99,102,241,0.08); border: 1px solid rgba(99,102,241,0.2); color: #6366f1; font-size: 11px; font-family: monospace; padding: 3px 8px; border-radius: 4px; }\n  .template-textarea[_ngcontent-%COMP%] { width: 100%; font-family: monospace; font-size: 12px; line-height: 1.6; resize: vertical; }"] });
  }
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && \u0275setClassDebugInfo(ConfiguracoesGeralComponent, { className: "ConfiguracoesGeralComponent" });
})();
export {
  ConfiguracoesGeralComponent
};
//# sourceMappingURL=chunk-VBWWEUQQ.js.map
