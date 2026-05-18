import {
  DefaultValueAccessor,
  FormControl,
  FormControlDirective,
  NgControlStatus,
  ReactiveFormsModule,
  Validators
} from "./chunk-JQJL26HT.js";
import {
  AuthService
} from "./chunk-V3IOF26G.js";
import "./chunk-Z5CKO2JM.js";
import {
  RouterLink
} from "./chunk-AXNOULNC.js";
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
  ɵɵnamespaceSVG,
  ɵɵnextContext,
  ɵɵproperty,
  ɵɵresetView,
  ɵɵrestoreView,
  ɵɵtemplate,
  ɵɵtext,
  ɵɵtextInterpolate,
  ɵɵtextInterpolate1
} from "./chunk-WZ2AWGAJ.js";
import "./chunk-7G5TR5RR.js";

// src/app/features/auth/forgot-password/forgot-password.component.ts
function ForgotPasswordComponent_Conditional_7_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 5);
    \u0275\u0275text(1, " Se este e-mail estiver cadastrado, voc\xEA receber\xE1 as instru\xE7\xF5es em breve. Verifique sua caixa de entrada. ");
    \u0275\u0275elementEnd();
  }
}
function ForgotPasswordComponent_Conditional_8_Conditional_1_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 10);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(2);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(ctx_r1.erro());
  }
}
function ForgotPasswordComponent_Conditional_8_Template(rf, ctx) {
  if (rf & 1) {
    const _r1 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 9);
    \u0275\u0275template(1, ForgotPasswordComponent_Conditional_8_Conditional_1_Template, 2, 1, "div", 10);
    \u0275\u0275elementStart(2, "div")(3, "label", 11);
    \u0275\u0275text(4, "E-mail");
    \u0275\u0275elementEnd();
    \u0275\u0275element(5, "input", 12);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(6, "button", 13);
    \u0275\u0275listener("click", function ForgotPasswordComponent_Conditional_8_Template_button_click_6_listener() {
      \u0275\u0275restoreView(_r1);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.enviar());
    });
    \u0275\u0275text(7);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext();
    \u0275\u0275advance();
    \u0275\u0275conditional(1, ctx_r1.erro() ? 1 : -1);
    \u0275\u0275advance(4);
    \u0275\u0275property("formControl", ctx_r1.emailCtrl);
    \u0275\u0275advance();
    \u0275\u0275property("disabled", ctx_r1.emailCtrl.invalid || ctx_r1.enviando());
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1(" ", ctx_r1.enviando() ? "Enviando..." : "Enviar instru\xE7\xF5es", " ");
  }
}
var ForgotPasswordComponent = class _ForgotPasswordComponent {
  constructor() {
    this.authService = inject(AuthService);
    this.emailCtrl = new FormControl("", [Validators.required, Validators.email]);
    this.enviado = signal(false);
    this.enviando = signal(false);
    this.erro = signal("");
  }
  enviar() {
    if (this.emailCtrl.invalid)
      return;
    this.enviando.set(true);
    this.erro.set("");
    this.authService.forgotPassword(this.emailCtrl.value).subscribe({
      next: () => {
        this.enviando.set(false);
        this.enviado.set(true);
      },
      error: () => {
        this.enviando.set(false);
        this.erro.set("Ocorreu um erro. Tente novamente.");
      }
    });
  }
  static {
    this.\u0275fac = function ForgotPasswordComponent_Factory(t) {
      return new (t || _ForgotPasswordComponent)();
    };
  }
  static {
    this.\u0275cmp = /* @__PURE__ */ \u0275\u0275defineComponent({ type: _ForgotPasswordComponent, selectors: [["app-forgot-password"]], standalone: true, features: [\u0275\u0275StandaloneFeature], decls: 13, vars: 1, consts: [[1, "min-h-screen", "flex", "items-center", "justify-center", "bg-gradient-to-br", "from-primary-900", "via-primary-800", "to-primary-700", "px-4"], [1, "w-full", "max-w-md"], [1, "bg-white", "rounded-2xl", "shadow-2xl", "p-8"], [1, "text-xl", "font-semibold", "text-surface-800", "mb-2"], [1, "text-sm", "text-surface-500", "mb-6"], [1, "p-4", "rounded-lg", "bg-green-50", "border", "border-green-200", "text-sm", "text-green-700"], ["routerLink", "/login", 1, "mt-6", "flex", "items-center", "gap-1.5", "text-sm", "text-primary-600", "hover:text-primary-700"], ["fill", "none", "viewBox", "0 0 24 24", "stroke", "currentColor", 1, "w-4", "h-4"], ["stroke-linecap", "round", "stroke-linejoin", "round", "stroke-width", "2", "d", "M15 19l-7-7 7-7"], [1, "space-y-4"], [1, "p-3", "rounded-lg", "bg-red-50", "border", "border-red-200", "text-sm", "text-red-700"], [1, "block", "text-sm", "font-medium", "text-surface-700", "mb-1.5"], ["type", "email", "placeholder", "seu@email.com", "autocomplete", "email", 1, "input-field", 3, "formControl"], [1, "btn-primary", "w-full", 3, "click", "disabled"]], template: function ForgotPasswordComponent_Template(rf, ctx) {
      if (rf & 1) {
        \u0275\u0275elementStart(0, "div", 0)(1, "div", 1)(2, "div", 2)(3, "h2", 3);
        \u0275\u0275text(4, "Recuperar senha");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(5, "p", 4);
        \u0275\u0275text(6, " Informe seu e-mail e enviaremos um link para redefinir sua senha. ");
        \u0275\u0275elementEnd();
        \u0275\u0275template(7, ForgotPasswordComponent_Conditional_7_Template, 2, 0, "div", 5)(8, ForgotPasswordComponent_Conditional_8_Template, 8, 4);
        \u0275\u0275elementStart(9, "a", 6);
        \u0275\u0275namespaceSVG();
        \u0275\u0275elementStart(10, "svg", 7);
        \u0275\u0275element(11, "path", 8);
        \u0275\u0275elementEnd();
        \u0275\u0275text(12, " Voltar ao login ");
        \u0275\u0275elementEnd()()()();
      }
      if (rf & 2) {
        \u0275\u0275advance(7);
        \u0275\u0275conditional(7, ctx.enviado() ? 7 : 8);
      }
    }, dependencies: [CommonModule, ReactiveFormsModule, DefaultValueAccessor, NgControlStatus, FormControlDirective, RouterLink], encapsulation: 2 });
  }
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && \u0275setClassDebugInfo(ForgotPasswordComponent, { className: "ForgotPasswordComponent" });
})();
export {
  ForgotPasswordComponent
};
//# sourceMappingURL=chunk-D2I2CFUT.js.map
