import {
  DefaultValueAccessor,
  FormControl,
  FormControlName,
  FormGroup,
  FormGroupDirective,
  NgControlStatus,
  NgControlStatusGroup,
  ReactiveFormsModule,
  Validators,
  ɵNgNoValidate
} from "./chunk-JQJL26HT.js";
import {
  AuthService
} from "./chunk-V3IOF26G.js";
import "./chunk-Z5CKO2JM.js";
import {
  Router,
  RouterLink
} from "./chunk-AXNOULNC.js";
import {
  CommonModule,
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
  ɵɵlistener,
  ɵɵnamespaceHTML,
  ɵɵnamespaceSVG,
  ɵɵnextContext,
  ɵɵproperty,
  ɵɵtemplate,
  ɵɵtext,
  ɵɵtextInterpolate,
  ɵɵtextInterpolate1
} from "./chunk-WZ2AWGAJ.js";
import "./chunk-7G5TR5RR.js";

// src/app/features/auth/login/login.component.ts
function LoginComponent_Conditional_60_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 20);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(1, "svg", 33);
    \u0275\u0275element(2, "path", 34);
    \u0275\u0275elementEnd();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(3, "p");
    \u0275\u0275text(4);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance(4);
    \u0275\u0275textInterpolate(ctx_r0.erro());
  }
}
function LoginComponent_Conditional_66_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "p", 25);
    \u0275\u0275text(1, "Informe um e-mail v\xE1lido.");
    \u0275\u0275elementEnd();
  }
}
function LoginComponent_Conditional_75_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(0, "svg", 30);
    \u0275\u0275element(1, "path", 35)(2, "line", 36);
    \u0275\u0275elementEnd();
  }
}
function LoginComponent_Conditional_76_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(0, "svg", 30);
    \u0275\u0275element(1, "path", 37)(2, "circle", 38);
    \u0275\u0275elementEnd();
  }
}
function LoginComponent_Conditional_77_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "p", 25);
    \u0275\u0275text(1, "A senha deve ter pelo menos 6 caracteres.");
    \u0275\u0275elementEnd();
  }
}
function LoginComponent_Conditional_79_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(0, "svg", 39);
    \u0275\u0275element(1, "circle", 40);
    \u0275\u0275elementEnd();
    \u0275\u0275text(2, " Entrando... ");
  }
}
function LoginComponent_Conditional_80_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275text(0, " Entrar na plataforma \u2192 ");
  }
}
var LoginComponent = class _LoginComponent {
  constructor() {
    this.authService = inject(AuthService);
    this.router = inject(Router);
    this.carregando = signal(false);
    this.erro = signal(null);
    this.mostrarSenha = signal(false);
    this.form = new FormGroup({
      email: new FormControl("", {
        nonNullable: true,
        validators: [Validators.required, Validators.email]
      }),
      senha: new FormControl("", {
        nonNullable: true,
        validators: [Validators.required, Validators.minLength(6)]
      })
    });
    this.year = (/* @__PURE__ */ new Date()).getFullYear();
  }
  entrar() {
    if (this.form.invalid || this.carregando())
      return;
    this.carregando.set(true);
    this.erro.set(null);
    const { email, senha } = this.form.getRawValue();
    this.authService.login({ email, senha }).subscribe({
      next: (res) => {
        if (res.sucesso) {
          this.router.navigate(["/app/dashboard"]);
        } else {
          this.erro.set(res.mensagem ?? "Credenciais inv\xE1lidas.");
          this.carregando.set(false);
        }
      },
      error: (err) => {
        const msg = err?.error?.mensagem;
        this.erro.set(msg ?? "N\xE3o foi poss\xEDvel conectar ao servidor. Tente novamente.");
        this.carregando.set(false);
      }
    });
  }
  get emailInvalido() {
    const ctrl = this.form.get("email");
    return !!(ctrl?.invalid && ctrl.touched);
  }
  get senhaInvalida() {
    const ctrl = this.form.get("senha");
    return !!(ctrl?.invalid && ctrl.touched);
  }
  static {
    this.\u0275fac = function LoginComponent_Factory(t) {
      return new (t || _LoginComponent)();
    };
  }
  static {
    this.\u0275cmp = /* @__PURE__ */ \u0275\u0275defineComponent({ type: _LoginComponent, selectors: [["app-login"]], standalone: true, features: [\u0275\u0275StandaloneFeature], decls: 83, vars: 13, consts: [[1, "auth-wrap"], [1, "auth-left"], ["routerLink", "/", 1, "auth-brand"], [1, "brand-mark"], [1, "auth-center"], [1, "eyebrow", 2, "margin-bottom", "16px"], [1, "auth-headline"], [1, "auth-benefits"], [1, "benefit-check"], ["width", "10", "height", "10", "viewBox", "0 0 16 16", "fill", "none"], ["d", "M3 8.5L6.5 12L13 4.5", "stroke", "currentColor", "stroke-width", "2", "stroke-linecap", "round", "stroke-linejoin", "round"], [1, "auth-trust"], [1, "auth-trust-label"], [1, "auth-trust-stars"], [1, "auth-right"], [1, "auth-form-wrap"], ["routerLink", "/", 1, "auth-mobile-brand"], [1, "auth-title"], [1, "auth-sub"], ["routerLink", "/cadastro"], [1, "error-alert"], ["novalidate", "", 3, "ngSubmit", "formGroup"], [1, "form-group"], [1, "form-label"], ["type", "email", "formControlName", "email", "placeholder", "seu@email.com", "autocomplete", "email", 1, "form-input"], [1, "form-error"], ["routerLink", "/forgot-password"], [1, "input-wrap"], ["formControlName", "senha", "placeholder", "\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022", "autocomplete", "current-password", 1, "form-input", 3, "type"], ["type", "button", "tabindex", "-1", 1, "eye-btn", 3, "click"], ["width", "18", "height", "18", "viewBox", "0 0 24 24", "fill", "none"], ["type", "submit", 1, "btn-submit", 3, "disabled"], [1, "auth-footer"], ["width", "16", "height", "16", "viewBox", "0 0 20 20", "fill", "currentColor"], ["fill-rule", "evenodd", "d", "M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z", "clip-rule", "evenodd"], ["d", "M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24", "stroke", "currentColor", "stroke-width", "1.5", "stroke-linecap", "round", "stroke-linejoin", "round"], ["x1", "1", "y1", "1", "x2", "23", "y2", "23", "stroke", "currentColor", "stroke-width", "1.5", "stroke-linecap", "round"], ["d", "M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z", "stroke", "currentColor", "stroke-width", "1.5"], ["cx", "12", "cy", "12", "r", "3", "stroke", "currentColor", "stroke-width", "1.5"], ["width", "16", "height", "16", "viewBox", "0 0 24 24", "fill", "none", 1, "spin"], ["cx", "12", "cy", "12", "r", "10", "stroke", "currentColor", "stroke-width", "3", "stroke-dasharray", "50", "stroke-dashoffset", "12"]], template: function LoginComponent_Template(rf, ctx) {
      if (rf & 1) {
        \u0275\u0275elementStart(0, "div", 0)(1, "div", 1)(2, "a", 2)(3, "span", 3);
        \u0275\u0275text(4, "T");
        \u0275\u0275elementEnd();
        \u0275\u0275text(5, " Tatame ");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(6, "div", 4)(7, "div")(8, "div", 5);
        \u0275\u0275text(9, "Gest\xE3o inteligente");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(10, "h2", 6);
        \u0275\u0275text(11, " Sua academia");
        \u0275\u0275element(12, "br");
        \u0275\u0275text(13, "no ");
        \u0275\u0275elementStart(14, "em");
        \u0275\u0275text(15, "pr\xF3ximo n\xEDvel");
        \u0275\u0275elementEnd();
        \u0275\u0275text(16, ". ");
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(17, "ul", 7)(18, "li")(19, "span", 8);
        \u0275\u0275namespaceSVG();
        \u0275\u0275elementStart(20, "svg", 9);
        \u0275\u0275element(21, "path", 10);
        \u0275\u0275elementEnd()();
        \u0275\u0275text(22, " Cobran\xE7a autom\xE1tica, zero inadimpl\xEAncia ");
        \u0275\u0275elementEnd();
        \u0275\u0275namespaceHTML();
        \u0275\u0275elementStart(23, "li")(24, "span", 8);
        \u0275\u0275namespaceSVG();
        \u0275\u0275elementStart(25, "svg", 9);
        \u0275\u0275element(26, "path", 10);
        \u0275\u0275elementEnd()();
        \u0275\u0275text(27, " Ranking gamificado que ret\xE9m alunos ");
        \u0275\u0275elementEnd();
        \u0275\u0275namespaceHTML();
        \u0275\u0275elementStart(28, "li")(29, "span", 8);
        \u0275\u0275namespaceSVG();
        \u0275\u0275elementStart(30, "svg", 9);
        \u0275\u0275element(31, "path", 10);
        \u0275\u0275elementEnd()();
        \u0275\u0275text(32, " Dashboard ao vivo no celular ");
        \u0275\u0275elementEnd();
        \u0275\u0275namespaceHTML();
        \u0275\u0275elementStart(33, "li")(34, "span", 8);
        \u0275\u0275namespaceSVG();
        \u0275\u0275elementStart(35, "svg", 9);
        \u0275\u0275element(36, "path", 10);
        \u0275\u0275elementEnd()();
        \u0275\u0275text(37, " Presen\xE7a por QR Code sem papelada ");
        \u0275\u0275elementEnd();
        \u0275\u0275namespaceHTML();
        \u0275\u0275elementStart(38, "li")(39, "span", 8);
        \u0275\u0275namespaceSVG();
        \u0275\u0275elementStart(40, "svg", 9);
        \u0275\u0275element(41, "path", 10);
        \u0275\u0275elementEnd()();
        \u0275\u0275text(42, " Suporte humano em portugu\xEAs, 7 dias ");
        \u0275\u0275elementEnd()();
        \u0275\u0275namespaceHTML();
        \u0275\u0275elementStart(43, "div", 11)(44, "div", 12);
        \u0275\u0275text(45, "+540 academias confiam");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(46, "div", 13);
        \u0275\u0275text(47, "\u2605\u2605\u2605\u2605\u2605 \xA04.9/5 \xB7 +50 mil alunos gerenciados");
        \u0275\u0275elementEnd()()()();
        \u0275\u0275elementStart(48, "div", 14)(49, "div", 15)(50, "a", 16)(51, "span", 3);
        \u0275\u0275text(52, "T");
        \u0275\u0275elementEnd();
        \u0275\u0275text(53, " Tatame ");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(54, "h1", 17);
        \u0275\u0275text(55, "Bem-vindo de volta");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(56, "p", 18);
        \u0275\u0275text(57, " Ainda n\xE3o tem conta? ");
        \u0275\u0275elementStart(58, "a", 19);
        \u0275\u0275text(59, "Criar conta gr\xE1tis");
        \u0275\u0275elementEnd()();
        \u0275\u0275template(60, LoginComponent_Conditional_60_Template, 5, 1, "div", 20);
        \u0275\u0275elementStart(61, "form", 21);
        \u0275\u0275listener("ngSubmit", function LoginComponent_Template_form_ngSubmit_61_listener() {
          return ctx.entrar();
        });
        \u0275\u0275elementStart(62, "div", 22)(63, "div", 23);
        \u0275\u0275text(64, "E-mail");
        \u0275\u0275elementEnd();
        \u0275\u0275element(65, "input", 24);
        \u0275\u0275template(66, LoginComponent_Conditional_66_Template, 2, 0, "p", 25);
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(67, "div", 22)(68, "div", 23);
        \u0275\u0275text(69, " Senha ");
        \u0275\u0275elementStart(70, "a", 26);
        \u0275\u0275text(71, "Esqueci minha senha");
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(72, "div", 27);
        \u0275\u0275element(73, "input", 28);
        \u0275\u0275elementStart(74, "button", 29);
        \u0275\u0275listener("click", function LoginComponent_Template_button_click_74_listener() {
          return ctx.mostrarSenha.set(!ctx.mostrarSenha());
        });
        \u0275\u0275template(75, LoginComponent_Conditional_75_Template, 3, 0, ":svg:svg", 30)(76, LoginComponent_Conditional_76_Template, 3, 0);
        \u0275\u0275elementEnd()();
        \u0275\u0275template(77, LoginComponent_Conditional_77_Template, 2, 0, "p", 25);
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(78, "button", 31);
        \u0275\u0275template(79, LoginComponent_Conditional_79_Template, 3, 0)(80, LoginComponent_Conditional_80_Template, 1, 0);
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(81, "div", 32);
        \u0275\u0275text(82);
        \u0275\u0275elementEnd()()()();
      }
      if (rf & 2) {
        \u0275\u0275advance(60);
        \u0275\u0275conditional(60, ctx.erro() ? 60 : -1);
        \u0275\u0275advance();
        \u0275\u0275property("formGroup", ctx.form);
        \u0275\u0275advance(4);
        \u0275\u0275classProp("has-error", ctx.emailInvalido);
        \u0275\u0275advance();
        \u0275\u0275conditional(66, ctx.emailInvalido ? 66 : -1);
        \u0275\u0275advance(7);
        \u0275\u0275classProp("has-error", ctx.senhaInvalida);
        \u0275\u0275property("type", ctx.mostrarSenha() ? "text" : "password");
        \u0275\u0275advance(2);
        \u0275\u0275conditional(75, ctx.mostrarSenha() ? 75 : 76);
        \u0275\u0275advance(2);
        \u0275\u0275conditional(77, ctx.senhaInvalida ? 77 : -1);
        \u0275\u0275advance();
        \u0275\u0275property("disabled", ctx.carregando());
        \u0275\u0275advance();
        \u0275\u0275conditional(79, ctx.carregando() ? 79 : 80);
        \u0275\u0275advance(3);
        \u0275\u0275textInterpolate1("\xA9 ", ctx.year, " Tatame. Todos os direitos reservados.");
      }
    }, dependencies: [CommonModule, ReactiveFormsModule, \u0275NgNoValidate, DefaultValueAccessor, NgControlStatus, NgControlStatusGroup, FormGroupDirective, FormControlName, RouterLink], styles: ['\n\n[_nghost-%COMP%] {\n  display: block;\n  --bg: #0a0a0a;\n  --bg-2: #111111;\n  --bg-3: #161616;\n  --fg: #fafaf7;\n  --fg-2: #c9c8c2;\n  --fg-3: #8a8985;\n  --line: #232323;\n  --line-2: #2e2e2e;\n  --accent: #ff4d2e;\n  --accent-2: #ff6a4d;\n  --display:\n    "Geist",\n    "Inter",\n    system-ui,\n    -apple-system,\n    sans-serif;\n  --mono:\n    "Geist Mono",\n    "JetBrains Mono",\n    ui-monospace,\n    monospace;\n  font-family: var(--display);\n  -webkit-font-smoothing: antialiased;\n}\n.auth-wrap[_ngcontent-%COMP%] {\n  min-height: 100vh;\n  display: flex;\n  background: var(--bg);\n  color: var(--fg);\n}\n.auth-left[_ngcontent-%COMP%] {\n  display: none;\n  width: 44%;\n  flex-shrink: 0;\n  background: var(--bg-2);\n  border-right: 1px solid var(--line);\n  flex-direction: column;\n  padding: 52px 48px;\n  gap: 0;\n}\n@media (min-width: 1024px) {\n  .auth-left[_ngcontent-%COMP%] {\n    display: flex;\n  }\n}\n.auth-brand[_ngcontent-%COMP%] {\n  display: flex;\n  align-items: center;\n  gap: 10px;\n  font-family: var(--display);\n  font-weight: 700;\n  font-size: 18px;\n  letter-spacing: -0.02em;\n  color: var(--fg);\n  text-decoration: none;\n}\n.brand-mark[_ngcontent-%COMP%] {\n  width: 22px;\n  height: 22px;\n  border-radius: 5px;\n  background: var(--accent);\n  display: inline-flex;\n  align-items: center;\n  justify-content: center;\n  color: #0a0a0a;\n  font-size: 13px;\n  font-weight: 800;\n}\n.auth-center[_ngcontent-%COMP%] {\n  flex: 1;\n  display: flex;\n  flex-direction: column;\n  justify-content: center;\n  gap: 40px;\n}\n.eyebrow[_ngcontent-%COMP%] {\n  font-family: var(--mono);\n  font-size: 11px;\n  letter-spacing: 0.12em;\n  text-transform: uppercase;\n  color: var(--fg-3);\n}\n.auth-headline[_ngcontent-%COMP%] {\n  font-family: var(--display);\n  font-weight: 600;\n  font-size: clamp(36px, 3.2vw, 52px);\n  letter-spacing: -0.035em;\n  line-height: 0.95;\n  margin-top: 16px;\n}\n.auth-headline[_ngcontent-%COMP%]   em[_ngcontent-%COMP%] {\n  font-style: normal;\n  color: var(--accent);\n}\n.auth-benefits[_ngcontent-%COMP%] {\n  list-style: none;\n  padding: 0;\n  margin: 0;\n  display: flex;\n  flex-direction: column;\n  gap: 14px;\n}\n.auth-benefits[_ngcontent-%COMP%]   li[_ngcontent-%COMP%] {\n  display: flex;\n  align-items: center;\n  gap: 12px;\n  font-size: 15px;\n  color: var(--fg-2);\n}\n.benefit-check[_ngcontent-%COMP%] {\n  width: 20px;\n  height: 20px;\n  border-radius: 50%;\n  background: rgba(255, 77, 46, 0.12);\n  border: 1px solid rgba(255, 77, 46, 0.25);\n  display: inline-flex;\n  align-items: center;\n  justify-content: center;\n  color: var(--accent);\n  flex-shrink: 0;\n}\n.auth-trust[_ngcontent-%COMP%] {\n  margin-top: auto;\n  padding-top: 40px;\n  border-top: 1px solid var(--line);\n}\n.auth-trust-label[_ngcontent-%COMP%] {\n  font-family: var(--mono);\n  font-size: 11px;\n  color: var(--fg-3);\n  letter-spacing: 0.08em;\n  text-transform: uppercase;\n  margin-bottom: 10px;\n}\n.auth-trust-stars[_ngcontent-%COMP%] {\n  font-size: 14px;\n  color: var(--fg-2);\n}\n.auth-right[_ngcontent-%COMP%] {\n  flex: 1;\n  display: flex;\n  align-items: center;\n  justify-content: center;\n  padding: 48px 32px;\n}\n.auth-form-wrap[_ngcontent-%COMP%] {\n  width: 100%;\n  max-width: 400px;\n}\n.auth-mobile-brand[_ngcontent-%COMP%] {\n  display: flex;\n  align-items: center;\n  gap: 10px;\n  font-family: var(--display);\n  font-weight: 700;\n  font-size: 18px;\n  letter-spacing: -0.02em;\n  color: var(--fg);\n  text-decoration: none;\n  margin-bottom: 40px;\n}\n@media (min-width: 1024px) {\n  .auth-mobile-brand[_ngcontent-%COMP%] {\n    display: none;\n  }\n}\n.auth-title[_ngcontent-%COMP%] {\n  font-family: var(--display);\n  font-weight: 600;\n  font-size: 30px;\n  letter-spacing: -0.025em;\n  margin-bottom: 8px;\n}\n.auth-sub[_ngcontent-%COMP%] {\n  font-size: 14px;\n  color: var(--fg-3);\n  margin-bottom: 32px;\n}\n.auth-sub[_ngcontent-%COMP%]   a[_ngcontent-%COMP%] {\n  color: var(--accent);\n  text-decoration: none;\n}\n.auth-sub[_ngcontent-%COMP%]   a[_ngcontent-%COMP%]:hover {\n  text-decoration: underline;\n}\n.form-group[_ngcontent-%COMP%] {\n  margin-bottom: 18px;\n}\n.form-label[_ngcontent-%COMP%] {\n  display: flex;\n  justify-content: space-between;\n  align-items: center;\n  font-family: var(--mono);\n  font-size: 11px;\n  letter-spacing: 0.08em;\n  text-transform: uppercase;\n  color: var(--fg-3);\n  margin-bottom: 8px;\n}\n.form-label[_ngcontent-%COMP%]   a[_ngcontent-%COMP%] {\n  color: var(--accent);\n  text-transform: none;\n  letter-spacing: 0;\n  font-size: 12px;\n  text-decoration: none;\n}\n.form-label[_ngcontent-%COMP%]   a[_ngcontent-%COMP%]:hover {\n  text-decoration: underline;\n}\n.input-wrap[_ngcontent-%COMP%] {\n  position: relative;\n}\n.input-wrap[_ngcontent-%COMP%]   .form-input[_ngcontent-%COMP%] {\n  padding-right: 44px;\n}\n.eye-btn[_ngcontent-%COMP%] {\n  position: absolute;\n  right: 12px;\n  top: 50%;\n  transform: translateY(-50%);\n  background: none;\n  border: none;\n  cursor: pointer;\n  color: var(--fg-3);\n  padding: 4px;\n  display: flex;\n  align-items: center;\n  line-height: 0;\n}\n.eye-btn[_ngcontent-%COMP%]:hover {\n  color: var(--fg);\n}\n.form-input[_ngcontent-%COMP%] {\n  width: 100%;\n  background: var(--bg-2);\n  border: 1px solid var(--line);\n  border-radius: 8px;\n  padding: 13px 16px;\n  font-size: 15px;\n  color: var(--fg);\n  outline: none;\n  transition: border-color 150ms ease;\n  font-family: var(--display);\n  appearance: none;\n  -webkit-appearance: none;\n}\n.form-input[_ngcontent-%COMP%]::placeholder {\n  color: var(--fg-3);\n}\n.form-input[_ngcontent-%COMP%]:focus {\n  border-color: var(--accent);\n}\n.form-input.has-error[_ngcontent-%COMP%] {\n  border-color: #ef4444;\n}\n.form-error[_ngcontent-%COMP%] {\n  font-size: 12px;\n  color: #ef4444;\n  margin-top: 6px;\n  font-family: var(--mono);\n}\n.btn-submit[_ngcontent-%COMP%] {\n  width: 100%;\n  display: flex;\n  align-items: center;\n  justify-content: center;\n  gap: 8px;\n  background: var(--accent);\n  color: #0a0a0a;\n  border: none;\n  border-radius: 999px;\n  padding: 15px 24px;\n  font-size: 15px;\n  font-weight: 600;\n  cursor: pointer;\n  transition: background 150ms ease, opacity 150ms ease;\n  font-family: var(--display);\n  margin-top: 8px;\n  letter-spacing: -0.01em;\n}\n.btn-submit[_ngcontent-%COMP%]:hover {\n  background: var(--accent-2);\n}\n.btn-submit[_ngcontent-%COMP%]:disabled {\n  opacity: 0.5;\n  cursor: not-allowed;\n}\n@keyframes _ngcontent-%COMP%_spin {\n  to {\n    transform: rotate(360deg);\n  }\n}\n.spin[_ngcontent-%COMP%] {\n  animation: _ngcontent-%COMP%_spin 0.8s linear infinite;\n}\n.error-alert[_ngcontent-%COMP%] {\n  display: flex;\n  align-items: flex-start;\n  gap: 10px;\n  background: rgba(239, 68, 68, 0.08);\n  border: 1px solid rgba(239, 68, 68, 0.2);\n  border-radius: 8px;\n  padding: 12px 14px;\n  margin-bottom: 20px;\n}\n.error-alert[_ngcontent-%COMP%]   svg[_ngcontent-%COMP%] {\n  color: #ef4444;\n  flex-shrink: 0;\n  margin-top: 1px;\n}\n.error-alert[_ngcontent-%COMP%]   p[_ngcontent-%COMP%] {\n  font-size: 14px;\n  color: #fca5a5;\n  margin: 0;\n}\n.auth-footer[_ngcontent-%COMP%] {\n  text-align: center;\n  margin-top: 36px;\n  font-size: 12px;\n  color: var(--fg-3);\n  font-family: var(--mono);\n  letter-spacing: 0.04em;\n}\n/*# sourceMappingURL=login.component.css.map */'] });
  }
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && \u0275setClassDebugInfo(LoginComponent, { className: "LoginComponent" });
})();
export {
  LoginComponent
};
//# sourceMappingURL=chunk-FPTZ2VIT.js.map
