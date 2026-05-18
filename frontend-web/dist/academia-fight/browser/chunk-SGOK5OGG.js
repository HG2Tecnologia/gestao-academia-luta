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
  ActivatedRoute,
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
  ɵɵconditional,
  ɵɵdefineComponent,
  ɵɵelement,
  ɵɵelementEnd,
  ɵɵelementStart,
  ɵɵgetCurrentView,
  ɵɵlistener,
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

// src/app/features/auth/reset-password/reset-password.component.ts
function ResetPasswordComponent_Conditional_5_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 4);
    \u0275\u0275text(1, " Link inv\xE1lido. Solicite um novo link de recupera\xE7\xE3o. ");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(2, "a", 5);
    \u0275\u0275text(3, " Solicitar novo link ");
    \u0275\u0275elementEnd();
  }
}
function ResetPasswordComponent_Conditional_6_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 6);
    \u0275\u0275text(1, " Senha redefinida com sucesso! ");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(2, "a", 7);
    \u0275\u0275text(3, "Ir para o login");
    \u0275\u0275elementEnd();
  }
}
function ResetPasswordComponent_Conditional_7_Conditional_2_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 9);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(2);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(ctx_r1.erro());
  }
}
function ResetPasswordComponent_Conditional_7_Conditional_12_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "p", 14);
    \u0275\u0275text(1, "As senhas n\xE3o coincidem.");
    \u0275\u0275elementEnd();
  }
}
function ResetPasswordComponent_Conditional_7_Template(rf, ctx) {
  if (rf & 1) {
    const _r1 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "p", 8);
    \u0275\u0275text(1, "Digite sua nova senha abaixo.");
    \u0275\u0275elementEnd();
    \u0275\u0275template(2, ResetPasswordComponent_Conditional_7_Conditional_2_Template, 2, 1, "div", 9);
    \u0275\u0275elementStart(3, "div", 10)(4, "div")(5, "label", 11);
    \u0275\u0275text(6, "Nova senha");
    \u0275\u0275elementEnd();
    \u0275\u0275element(7, "input", 12);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(8, "div")(9, "label", 11);
    \u0275\u0275text(10, "Confirmar senha");
    \u0275\u0275elementEnd();
    \u0275\u0275element(11, "input", 13);
    \u0275\u0275template(12, ResetPasswordComponent_Conditional_7_Conditional_12_Template, 2, 0, "p", 14);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(13, "button", 15);
    \u0275\u0275listener("click", function ResetPasswordComponent_Conditional_7_Template_button_click_13_listener() {
      \u0275\u0275restoreView(_r1);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.salvar());
    });
    \u0275\u0275text(14);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext();
    \u0275\u0275advance(2);
    \u0275\u0275conditional(2, ctx_r1.erro() ? 2 : -1);
    \u0275\u0275advance(5);
    \u0275\u0275property("formControl", ctx_r1.senhaCtrl);
    \u0275\u0275advance(4);
    \u0275\u0275property("formControl", ctx_r1.confirmCtrl);
    \u0275\u0275advance();
    \u0275\u0275conditional(12, ctx_r1.confirmCtrl.touched && (ctx_r1.confirmCtrl.errors == null ? null : ctx_r1.confirmCtrl.errors["senhasDiferentes"]) ? 12 : -1);
    \u0275\u0275advance();
    \u0275\u0275property("disabled", ctx_r1.senhaCtrl.invalid || ctx_r1.confirmCtrl.invalid || ctx_r1.salvando());
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1(" ", ctx_r1.salvando() ? "Salvando..." : "Redefinir senha", " ");
  }
}
function senhasIguaisValidator(confirmCtrl) {
  return (ctrl) => {
    return ctrl.value === confirmCtrl.value ? null : { senhasDiferentes: true };
  };
}
var ResetPasswordComponent = class _ResetPasswordComponent {
  constructor() {
    this.authService = inject(AuthService);
    this.route = inject(ActivatedRoute);
    this.router = inject(Router);
    this.token = signal("");
    this.concluido = signal(false);
    this.salvando = signal(false);
    this.erro = signal("");
    this.senhaCtrl = new FormControl("", [Validators.required, Validators.minLength(6)]);
    this.confirmCtrl = new FormControl("", [Validators.required, senhasIguaisValidator(this.senhaCtrl)]);
    this.senhaCtrl.valueChanges.subscribe(() => this.confirmCtrl.updateValueAndValidity());
  }
  ngOnInit() {
    const t = this.route.snapshot.queryParamMap.get("token") ?? "";
    this.token.set(t);
  }
  salvar() {
    if (this.senhaCtrl.invalid || this.confirmCtrl.invalid)
      return;
    this.salvando.set(true);
    this.erro.set("");
    this.authService.resetPassword(this.token(), this.senhaCtrl.value).subscribe({
      next: (res) => {
        this.salvando.set(false);
        if (res.sucesso) {
          this.concluido.set(true);
        } else {
          this.erro.set(res.mensagem ?? "Erro ao redefinir senha.");
        }
      },
      error: (err) => {
        this.salvando.set(false);
        this.erro.set(err.error?.mensagem ?? "Link inv\xE1lido ou expirado. Solicite um novo link.");
      }
    });
  }
  static {
    this.\u0275fac = function ResetPasswordComponent_Factory(t) {
      return new (t || _ResetPasswordComponent)();
    };
  }
  static {
    this.\u0275cmp = /* @__PURE__ */ \u0275\u0275defineComponent({ type: _ResetPasswordComponent, selectors: [["app-reset-password"]], standalone: true, features: [\u0275\u0275StandaloneFeature], decls: 8, vars: 1, consts: [[1, "min-h-screen", "flex", "items-center", "justify-center", "bg-gradient-to-br", "from-primary-900", "via-primary-800", "to-primary-700", "px-4"], [1, "w-full", "max-w-md"], [1, "bg-white", "rounded-2xl", "shadow-2xl", "p-8"], [1, "text-xl", "font-semibold", "text-surface-800", "mb-2"], [1, "p-4", "rounded-lg", "bg-red-50", "border", "border-red-200", "text-sm", "text-red-700"], ["routerLink", "/forgot-password", 1, "mt-4", "inline-block", "text-sm", "text-primary-600", "hover:text-primary-700"], [1, "p-4", "rounded-lg", "bg-green-50", "border", "border-green-200", "text-sm", "text-green-700", "mb-4"], ["routerLink", "/login", 1, "btn-primary", "w-full", "text-center", "block"], [1, "text-sm", "text-surface-500", "mb-6"], [1, "p-3", "rounded-lg", "bg-red-50", "border", "border-red-200", "text-sm", "text-red-700", "mb-4"], [1, "space-y-4"], [1, "block", "text-sm", "font-medium", "text-surface-700", "mb-1.5"], ["type", "password", "placeholder", "M\xEDnimo 6 caracteres", "autocomplete", "new-password", 1, "input-field", 3, "formControl"], ["type", "password", "placeholder", "Repita a senha", "autocomplete", "new-password", 1, "input-field", 3, "formControl"], [1, "text-xs", "text-red-600", "mt-1"], [1, "btn-primary", "w-full", 3, "click", "disabled"]], template: function ResetPasswordComponent_Template(rf, ctx) {
      if (rf & 1) {
        \u0275\u0275elementStart(0, "div", 0)(1, "div", 1)(2, "div", 2)(3, "h2", 3);
        \u0275\u0275text(4, "Criar nova senha");
        \u0275\u0275elementEnd();
        \u0275\u0275template(5, ResetPasswordComponent_Conditional_5_Template, 4, 0)(6, ResetPasswordComponent_Conditional_6_Template, 4, 0)(7, ResetPasswordComponent_Conditional_7_Template, 15, 6);
        \u0275\u0275elementEnd()()();
      }
      if (rf & 2) {
        \u0275\u0275advance(5);
        \u0275\u0275conditional(5, !ctx.token() ? 5 : ctx.concluido() ? 6 : 7);
      }
    }, dependencies: [CommonModule, ReactiveFormsModule, DefaultValueAccessor, NgControlStatus, FormControlDirective, RouterLink], encapsulation: 2 });
  }
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && \u0275setClassDebugInfo(ResetPasswordComponent, { className: "ResetPasswordComponent" });
})();
export {
  ResetPasswordComponent
};
//# sourceMappingURL=chunk-SGOK5OGG.js.map
