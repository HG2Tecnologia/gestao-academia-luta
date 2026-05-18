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
  ɵɵgetCurrentView,
  ɵɵlistener,
  ɵɵnamespaceHTML,
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

// src/app/features/auth/cadastro/cadastro.component.ts
function CadastroComponent_Conditional_57_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(0, "svg", 9);
    \u0275\u0275element(1, "path", 10);
    \u0275\u0275elementEnd();
  }
}
function CadastroComponent_Conditional_58_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275text(0, " 1 ");
  }
}
function CadastroComponent_Conditional_65_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 21);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(1, "svg", 24);
    \u0275\u0275element(2, "path", 25);
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
function CadastroComponent_Conditional_67_Conditional_10_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "p", 32);
    \u0275\u0275text(1, "Informe seu nome (m\xEDnimo 3 caracteres).");
    \u0275\u0275elementEnd();
  }
}
function CadastroComponent_Conditional_67_Conditional_15_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "p", 32);
    \u0275\u0275text(1, "Informe um e-mail v\xE1lido.");
    \u0275\u0275elementEnd();
  }
}
function CadastroComponent_Conditional_67_Conditional_22_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(0, "svg", 37);
    \u0275\u0275element(1, "path", 41)(2, "line", 42);
    \u0275\u0275elementEnd();
  }
}
function CadastroComponent_Conditional_67_Conditional_23_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(0, "svg", 37);
    \u0275\u0275element(1, "path", 43)(2, "circle", 44);
    \u0275\u0275elementEnd();
  }
}
function CadastroComponent_Conditional_67_Conditional_24_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "p", 32);
    \u0275\u0275text(1, "A senha deve ter pelo menos 8 caracteres.");
    \u0275\u0275elementEnd();
  }
}
function CadastroComponent_Conditional_67_Conditional_31_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(0, "svg", 37);
    \u0275\u0275element(1, "path", 41)(2, "line", 42);
    \u0275\u0275elementEnd();
  }
}
function CadastroComponent_Conditional_67_Conditional_32_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(0, "svg", 37);
    \u0275\u0275element(1, "path", 43)(2, "circle", 44);
    \u0275\u0275elementEnd();
  }
}
function CadastroComponent_Conditional_67_Conditional_33_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "p", 32);
    \u0275\u0275text(1, "As senhas n\xE3o coincidem.");
    \u0275\u0275elementEnd();
  }
}
function CadastroComponent_Conditional_67_Template(rf, ctx) {
  if (rf & 1) {
    const _r2 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "h1", 26);
    \u0275\u0275text(1, "Criar sua conta");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(2, "p", 27);
    \u0275\u0275text(3, " J\xE1 tem conta? ");
    \u0275\u0275elementStart(4, "a", 28);
    \u0275\u0275text(5, "Entrar");
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(6, "div", 29)(7, "div", 30);
    \u0275\u0275text(8, "Nome completo");
    \u0275\u0275elementEnd();
    \u0275\u0275element(9, "input", 31);
    \u0275\u0275template(10, CadastroComponent_Conditional_67_Conditional_10_Template, 2, 0, "p", 32);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(11, "div", 29)(12, "div", 30);
    \u0275\u0275text(13, "E-mail");
    \u0275\u0275elementEnd();
    \u0275\u0275element(14, "input", 33);
    \u0275\u0275template(15, CadastroComponent_Conditional_67_Conditional_15_Template, 2, 0, "p", 32);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(16, "div", 29)(17, "div", 30);
    \u0275\u0275text(18, "Senha");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(19, "div", 34);
    \u0275\u0275element(20, "input", 35);
    \u0275\u0275elementStart(21, "button", 36);
    \u0275\u0275listener("click", function CadastroComponent_Conditional_67_Template_button_click_21_listener() {
      \u0275\u0275restoreView(_r2);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.mostrarSenha.set(!ctx_r0.mostrarSenha()));
    });
    \u0275\u0275template(22, CadastroComponent_Conditional_67_Conditional_22_Template, 3, 0, ":svg:svg", 37)(23, CadastroComponent_Conditional_67_Conditional_23_Template, 3, 0);
    \u0275\u0275elementEnd()();
    \u0275\u0275template(24, CadastroComponent_Conditional_67_Conditional_24_Template, 2, 0, "p", 32);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(25, "div", 29)(26, "div", 30);
    \u0275\u0275text(27, "Confirmar senha");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(28, "div", 34);
    \u0275\u0275element(29, "input", 38);
    \u0275\u0275elementStart(30, "button", 36);
    \u0275\u0275listener("click", function CadastroComponent_Conditional_67_Template_button_click_30_listener() {
      \u0275\u0275restoreView(_r2);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.mostrarConfirmarSenha.set(!ctx_r0.mostrarConfirmarSenha()));
    });
    \u0275\u0275template(31, CadastroComponent_Conditional_67_Conditional_31_Template, 3, 0, ":svg:svg", 37)(32, CadastroComponent_Conditional_67_Conditional_32_Template, 3, 0);
    \u0275\u0275elementEnd()();
    \u0275\u0275template(33, CadastroComponent_Conditional_67_Conditional_33_Template, 2, 0, "p", 32);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(34, "div", 39)(35, "button", 40);
    \u0275\u0275listener("click", function CadastroComponent_Conditional_67_Template_button_click_35_listener() {
      \u0275\u0275restoreView(_r2);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.avancar());
    });
    \u0275\u0275text(36, " Pr\xF3ximo \u2192 ");
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance(9);
    \u0275\u0275classProp("has-error", ctx_r0.campo("nome"));
    \u0275\u0275advance();
    \u0275\u0275conditional(10, ctx_r0.campo("nome") ? 10 : -1);
    \u0275\u0275advance(4);
    \u0275\u0275classProp("has-error", ctx_r0.campo("email"));
    \u0275\u0275advance();
    \u0275\u0275conditional(15, ctx_r0.campo("email") ? 15 : -1);
    \u0275\u0275advance(5);
    \u0275\u0275classProp("has-error", ctx_r0.campo("senha"));
    \u0275\u0275property("type", ctx_r0.mostrarSenha() ? "text" : "password");
    \u0275\u0275advance(2);
    \u0275\u0275conditional(22, ctx_r0.mostrarSenha() ? 22 : 23);
    \u0275\u0275advance(2);
    \u0275\u0275conditional(24, ctx_r0.campo("senha") ? 24 : -1);
    \u0275\u0275advance(5);
    \u0275\u0275classProp("has-error", ctx_r0.campo("confirmarSenha") || ctx_r0.senhasDiferentes);
    \u0275\u0275property("type", ctx_r0.mostrarConfirmarSenha() ? "text" : "password");
    \u0275\u0275advance(2);
    \u0275\u0275conditional(31, ctx_r0.mostrarConfirmarSenha() ? 31 : 32);
    \u0275\u0275advance(2);
    \u0275\u0275conditional(33, ctx_r0.senhasDiferentes ? 33 : -1);
  }
}
function CadastroComponent_Conditional_68_Conditional_8_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "p", 32);
    \u0275\u0275text(1, "Informe o nome da academia (m\xEDnimo 3 caracteres).");
    \u0275\u0275elementEnd();
  }
}
function CadastroComponent_Conditional_68_Conditional_16_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "p", 32);
    \u0275\u0275text(1, "Use apenas letras min\xFAsculas, n\xFAmeros e h\xEDfens.");
    \u0275\u0275elementEnd();
  }
}
function CadastroComponent_Conditional_68_Conditional_25_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(0, "svg", 53);
    \u0275\u0275element(1, "circle", 54);
    \u0275\u0275elementEnd();
    \u0275\u0275text(2, " Criando sua conta... ");
  }
}
function CadastroComponent_Conditional_68_Conditional_26_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275text(0, " Criar minha conta gr\xE1tis \u2192 ");
  }
}
function CadastroComponent_Conditional_68_Template(rf, ctx) {
  if (rf & 1) {
    const _r3 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "h1", 26);
    \u0275\u0275text(1, "Sua academia");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(2, "p", 27);
    \u0275\u0275text(3, "Onde o tatame encontra a tecnologia.");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(4, "div", 29)(5, "div", 30);
    \u0275\u0275text(6, "Nome da academia");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(7, "input", 45);
    \u0275\u0275listener("blur", function CadastroComponent_Conditional_68_Template_input_blur_7_listener() {
      \u0275\u0275restoreView(_r3);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.gerarSubdominio());
    });
    \u0275\u0275elementEnd();
    \u0275\u0275template(8, CadastroComponent_Conditional_68_Conditional_8_Template, 2, 0, "p", 32);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(9, "div", 29)(10, "div", 30);
    \u0275\u0275text(11, "Subdom\xEDnio");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(12, "div", 46);
    \u0275\u0275element(13, "input", 47);
    \u0275\u0275elementStart(14, "span", 48);
    \u0275\u0275text(15, ".tatame.com.br");
    \u0275\u0275elementEnd()();
    \u0275\u0275template(16, CadastroComponent_Conditional_68_Conditional_16_Template, 2, 0, "p", 32);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(17, "div", 29)(18, "div", 30);
    \u0275\u0275text(19, "Telefone ");
    \u0275\u0275elementStart(20, "span", 49);
    \u0275\u0275text(21, "(opcional)");
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(22, "input", 50);
    \u0275\u0275listener("input", function CadastroComponent_Conditional_68_Template_input_input_22_listener($event) {
      \u0275\u0275restoreView(_r3);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.onTelefoneInput($event));
    });
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(23, "div", 39)(24, "button", 51);
    \u0275\u0275listener("click", function CadastroComponent_Conditional_68_Template_button_click_24_listener() {
      \u0275\u0275restoreView(_r3);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.cadastrar());
    });
    \u0275\u0275template(25, CadastroComponent_Conditional_68_Conditional_25_Template, 3, 0)(26, CadastroComponent_Conditional_68_Conditional_26_Template, 1, 0);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(27, "button", 52);
    \u0275\u0275listener("click", function CadastroComponent_Conditional_68_Template_button_click_27_listener() {
      \u0275\u0275restoreView(_r3);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.etapa.set(1));
    });
    \u0275\u0275text(28, "\u2190 Voltar");
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance(7);
    \u0275\u0275classProp("has-error", ctx_r0.campo("nomeAcademia"));
    \u0275\u0275advance();
    \u0275\u0275conditional(8, ctx_r0.campo("nomeAcademia") ? 8 : -1);
    \u0275\u0275advance(5);
    \u0275\u0275classProp("has-error", ctx_r0.campo("subdominio"));
    \u0275\u0275advance(3);
    \u0275\u0275conditional(16, ctx_r0.campo("subdominio") ? 16 : -1);
    \u0275\u0275advance(8);
    \u0275\u0275property("disabled", ctx_r0.carregando());
    \u0275\u0275advance();
    \u0275\u0275conditional(25, ctx_r0.carregando() ? 25 : 26);
  }
}
function senhasIguaisValidator(group) {
  const senha = group.get("senha")?.value;
  const confirmar = group.get("confirmarSenha")?.value;
  return senha === confirmar ? null : { senhasDiferentes: true };
}
var CadastroComponent = class _CadastroComponent {
  constructor() {
    this.authService = inject(AuthService);
    this.router = inject(Router);
    this.carregando = signal(false);
    this.erro = signal(null);
    this.etapa = signal(1);
    this.mostrarSenha = signal(false);
    this.mostrarConfirmarSenha = signal(false);
    this.year = (/* @__PURE__ */ new Date()).getFullYear();
    this.beneficios = [
      "14 dias gr\xE1tis, sem cart\xE3o de cr\xE9dito",
      "Gest\xE3o completa de alunos e turmas",
      "Controle de mensalidades e cobran\xE7as",
      "Ranking e progress\xE3o de belts",
      "Suporte em portugu\xEAs 7 dias por semana"
    ];
    this.form = new FormGroup({
      nome: new FormControl("", {
        nonNullable: true,
        validators: [Validators.required, Validators.minLength(3)]
      }),
      email: new FormControl("", {
        nonNullable: true,
        validators: [Validators.required, Validators.email]
      }),
      senha: new FormControl("", {
        nonNullable: true,
        validators: [Validators.required, Validators.minLength(8)]
      }),
      confirmarSenha: new FormControl("", {
        nonNullable: true,
        validators: [Validators.required]
      }),
      nomeAcademia: new FormControl("", {
        nonNullable: true,
        validators: [Validators.required, Validators.minLength(3)]
      }),
      subdominio: new FormControl("", {
        nonNullable: true,
        validators: [
          Validators.required,
          Validators.minLength(3),
          Validators.pattern(/^[a-z0-9-]+$/)
        ]
      }),
      telefone: new FormControl("", { nonNullable: true })
    }, { validators: senhasIguaisValidator });
  }
  avancar() {
    const campos = ["nome", "email", "senha", "confirmarSenha"];
    campos.forEach((c) => this.form.get(c)?.markAsTouched());
    const etapa1Valida = !this.form.get("nome")?.invalid && !this.form.get("email")?.invalid && !this.form.get("senha")?.invalid && !this.form.get("confirmarSenha")?.invalid && !this.form.hasError("senhasDiferentes");
    if (etapa1Valida)
      this.etapa.set(2);
  }
  cadastrar() {
    if (this.form.invalid || this.carregando())
      return;
    this.carregando.set(true);
    this.erro.set(null);
    const { nome, email, senha, nomeAcademia, subdominio, telefone } = this.form.getRawValue();
    this.authService.register({ nome, email, senha, nomeAcademia, subdominio, telefone: telefone || void 0 }).subscribe({
      next: (res) => {
        if (res.sucesso) {
          this.router.navigate(["/app/dashboard"]);
        } else {
          this.erro.set(res.mensagem ?? "Erro ao criar conta. Tente novamente.");
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
  onTelefoneInput(event) {
    const input = event.target;
    let digits = input.value.replace(/\D/g, "").slice(0, 11);
    let formatted = "";
    if (digits.length > 0)
      formatted = "(" + digits.slice(0, 2);
    if (digits.length > 2)
      formatted += ") " + digits.slice(2, digits.length > 10 ? 7 : 6);
    if (digits.length > 6 && digits.length <= 10)
      formatted += "-" + digits.slice(6, 10);
    if (digits.length > 10)
      formatted += "-" + digits.slice(7, 11);
    input.value = formatted;
    this.form.get("telefone")?.setValue(formatted, { emitEvent: false });
  }
  gerarSubdominio() {
    const nome = this.form.get("nomeAcademia")?.value ?? "";
    const slug = nome.toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "").replace(/[^a-z0-9\s-]/g, "").trim().replace(/\s+/g, "-");
    this.form.get("subdominio")?.setValue(slug);
  }
  campo(name) {
    const ctrl = this.form.get(name);
    return !!(ctrl?.invalid && ctrl.touched);
  }
  get senhasDiferentes() {
    return this.form.hasError("senhasDiferentes") && !!this.form.get("confirmarSenha")?.touched;
  }
  static {
    this.\u0275fac = function CadastroComponent_Factory(t) {
      return new (t || _CadastroComponent)();
    };
  }
  static {
    this.\u0275cmp = /* @__PURE__ */ \u0275\u0275defineComponent({ type: _CadastroComponent, selectors: [["app-cadastro"]], standalone: true, features: [\u0275\u0275StandaloneFeature], decls: 71, vars: 12, consts: [[1, "auth-wrap"], [1, "auth-left"], ["routerLink", "/", 1, "auth-brand"], [1, "brand-mark"], [1, "auth-center"], [1, "eyebrow", 2, "margin-bottom", "16px"], [1, "auth-headline"], [1, "auth-benefits"], [1, "benefit-check"], ["width", "10", "height", "10", "viewBox", "0 0 16 16", "fill", "none"], ["d", "M3 8.5L6.5 12L13 4.5", "stroke", "currentColor", "stroke-width", "2", "stroke-linecap", "round", "stroke-linejoin", "round"], [1, "auth-trust"], [1, "auth-trust-label"], [1, "auth-trust-stars"], [1, "auth-right"], [1, "auth-form-wrap"], ["routerLink", "/", 1, "auth-mobile-brand"], [1, "steps-indicator"], [1, "step-item"], [1, "step-circle"], [1, "step-sep"], [1, "error-alert"], ["novalidate", "", 3, "formGroup"], [1, "auth-footer"], ["width", "16", "height", "16", "viewBox", "0 0 20 20", "fill", "currentColor"], ["fill-rule", "evenodd", "d", "M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z", "clip-rule", "evenodd"], [1, "auth-title"], [1, "auth-sub"], ["routerLink", "/login"], [1, "form-group"], [1, "form-label"], ["type", "text", "formControlName", "nome", "placeholder", "Seu nome", "autocomplete", "name", 1, "form-input"], [1, "form-error"], ["type", "email", "formControlName", "email", "placeholder", "seu@email.com", "autocomplete", "email", 1, "form-input"], [1, "input-wrap"], ["formControlName", "senha", "placeholder", "M\xEDnimo 8 caracteres", "autocomplete", "new-password", 1, "form-input", 3, "type"], ["type", "button", "tabindex", "-1", 1, "eye-btn", 3, "click"], ["width", "18", "height", "18", "viewBox", "0 0 24 24", "fill", "none"], ["formControlName", "confirmarSenha", "placeholder", "Repita a senha", "autocomplete", "new-password", 1, "form-input", 3, "type"], [1, "form-actions"], ["type", "button", 1, "btn-submit", 3, "click"], ["d", "M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24", "stroke", "currentColor", "stroke-width", "1.5", "stroke-linecap", "round", "stroke-linejoin", "round"], ["x1", "1", "y1", "1", "x2", "23", "y2", "23", "stroke", "currentColor", "stroke-width", "1.5", "stroke-linecap", "round"], ["d", "M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z", "stroke", "currentColor", "stroke-width", "1.5"], ["cx", "12", "cy", "12", "r", "3", "stroke", "currentColor", "stroke-width", "1.5"], ["type", "text", "formControlName", "nomeAcademia", "placeholder", "Ex: Academia Tatame Norte", 1, "form-input", 3, "blur"], [1, "subdomain-group"], ["type", "text", "formControlName", "subdominio", "placeholder", "minha-academia", 1, "form-input"], [1, "subdomain-suffix"], [2, "color", "var(--fg-3)", "font-size", "10px", "text-transform", "none", "letter-spacing", "0"], ["type", "tel", "formControlName", "telefone", "placeholder", "(11) 99999-9999", "autocomplete", "tel", "inputmode", "numeric", 1, "form-input", 3, "input"], ["type", "button", 1, "btn-submit", 3, "click", "disabled"], ["type", "button", 1, "btn-ghost", 3, "click"], ["width", "16", "height", "16", "viewBox", "0 0 24 24", "fill", "none", 1, "spin"], ["cx", "12", "cy", "12", "r", "10", "stroke", "currentColor", "stroke-width", "3", "stroke-dasharray", "50", "stroke-dashoffset", "12"]], template: function CadastroComponent_Template(rf, ctx) {
      if (rf & 1) {
        \u0275\u0275elementStart(0, "div", 0)(1, "div", 1)(2, "a", 2)(3, "span", 3);
        \u0275\u0275text(4, "T");
        \u0275\u0275elementEnd();
        \u0275\u0275text(5, " Tatame ");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(6, "div", 4)(7, "div")(8, "div", 5);
        \u0275\u0275text(9, "Comece agora \xB7 30 dias gr\xE1tis");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(10, "h2", 6);
        \u0275\u0275text(11, " Sua academia");
        \u0275\u0275element(12, "br");
        \u0275\u0275text(13, "na ");
        \u0275\u0275elementStart(14, "em");
        \u0275\u0275text(15, "palma da m\xE3o");
        \u0275\u0275elementEnd();
        \u0275\u0275text(16, ". ");
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(17, "ul", 7)(18, "li")(19, "span", 8);
        \u0275\u0275namespaceSVG();
        \u0275\u0275elementStart(20, "svg", 9);
        \u0275\u0275element(21, "path", 10);
        \u0275\u0275elementEnd()();
        \u0275\u0275text(22, " 30 dias gr\xE1tis, sem cart\xE3o de cr\xE9dito ");
        \u0275\u0275elementEnd();
        \u0275\u0275namespaceHTML();
        \u0275\u0275elementStart(23, "li")(24, "span", 8);
        \u0275\u0275namespaceSVG();
        \u0275\u0275elementStart(25, "svg", 9);
        \u0275\u0275element(26, "path", 10);
        \u0275\u0275elementEnd()();
        \u0275\u0275text(27, " Importa\xE7\xE3o de planilha sem custo ");
        \u0275\u0275elementEnd();
        \u0275\u0275namespaceHTML();
        \u0275\u0275elementStart(28, "li")(29, "span", 8);
        \u0275\u0275namespaceSVG();
        \u0275\u0275elementStart(30, "svg", 9);
        \u0275\u0275element(31, "path", 10);
        \u0275\u0275elementEnd()();
        \u0275\u0275text(32, " Cobran\xE7a autom\xE1tica por Pix e cart\xE3o ");
        \u0275\u0275elementEnd();
        \u0275\u0275namespaceHTML();
        \u0275\u0275elementStart(33, "li")(34, "span", 8);
        \u0275\u0275namespaceSVG();
        \u0275\u0275elementStart(35, "svg", 9);
        \u0275\u0275element(36, "path", 10);
        \u0275\u0275elementEnd()();
        \u0275\u0275text(37, " Ranking gamificado que ret\xE9m alunos ");
        \u0275\u0275elementEnd();
        \u0275\u0275namespaceHTML();
        \u0275\u0275elementStart(38, "li")(39, "span", 8);
        \u0275\u0275namespaceSVG();
        \u0275\u0275elementStart(40, "svg", 9);
        \u0275\u0275element(41, "path", 10);
        \u0275\u0275elementEnd()();
        \u0275\u0275text(42, " Suporte em portugu\xEAs 7 dias por semana ");
        \u0275\u0275elementEnd()();
        \u0275\u0275namespaceHTML();
        \u0275\u0275elementStart(43, "div", 11)(44, "div", 12);
        \u0275\u0275text(45, "+540 academias j\xE1 usam");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(46, "div", 13);
        \u0275\u0275text(47, "\u2605\u2605\u2605\u2605\u2605 \xA04.9/5 \xB7 Setup em menos de 24h");
        \u0275\u0275elementEnd()()()();
        \u0275\u0275elementStart(48, "div", 14)(49, "div", 15)(50, "a", 16)(51, "span", 3);
        \u0275\u0275text(52, "T");
        \u0275\u0275elementEnd();
        \u0275\u0275text(53, " Tatame ");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(54, "div", 17)(55, "div", 18)(56, "span", 19);
        \u0275\u0275template(57, CadastroComponent_Conditional_57_Template, 2, 0, ":svg:svg", 9)(58, CadastroComponent_Conditional_58_Template, 1, 0);
        \u0275\u0275elementEnd();
        \u0275\u0275text(59, " Sua conta ");
        \u0275\u0275elementEnd();
        \u0275\u0275element(60, "div", 20);
        \u0275\u0275elementStart(61, "div", 18)(62, "span", 19);
        \u0275\u0275text(63, "2");
        \u0275\u0275elementEnd();
        \u0275\u0275text(64, " Sua academia ");
        \u0275\u0275elementEnd()();
        \u0275\u0275template(65, CadastroComponent_Conditional_65_Template, 5, 1, "div", 21);
        \u0275\u0275elementStart(66, "form", 22);
        \u0275\u0275template(67, CadastroComponent_Conditional_67_Template, 37, 16)(68, CadastroComponent_Conditional_68_Template, 29, 8);
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(69, "div", 23);
        \u0275\u0275text(70);
        \u0275\u0275elementEnd()()()();
      }
      if (rf & 2) {
        \u0275\u0275advance(55);
        \u0275\u0275classProp("active", ctx.etapa() === 1)("done", ctx.etapa() > 1);
        \u0275\u0275advance(2);
        \u0275\u0275conditional(57, ctx.etapa() > 1 ? 57 : 58);
        \u0275\u0275advance(4);
        \u0275\u0275classProp("active", ctx.etapa() === 2);
        \u0275\u0275advance(4);
        \u0275\u0275conditional(65, ctx.erro() ? 65 : -1);
        \u0275\u0275advance();
        \u0275\u0275property("formGroup", ctx.form);
        \u0275\u0275advance();
        \u0275\u0275conditional(67, ctx.etapa() === 1 ? 67 : -1);
        \u0275\u0275advance();
        \u0275\u0275conditional(68, ctx.etapa() === 2 ? 68 : -1);
        \u0275\u0275advance(2);
        \u0275\u0275textInterpolate1("\xA9 ", ctx.year, " Tatame. Todos os direitos reservados.");
      }
    }, dependencies: [CommonModule, ReactiveFormsModule, \u0275NgNoValidate, DefaultValueAccessor, NgControlStatus, NgControlStatusGroup, FormGroupDirective, FormControlName, RouterLink], styles: ['\n\n[_nghost-%COMP%] {\n  display: block;\n  --bg: #0a0a0a;\n  --bg-2: #111111;\n  --bg-3: #161616;\n  --fg: #fafaf7;\n  --fg-2: #c9c8c2;\n  --fg-3: #8a8985;\n  --line: #232323;\n  --line-2: #2e2e2e;\n  --accent: #ff4d2e;\n  --accent-2: #ff6a4d;\n  --display:\n    "Geist",\n    "Inter",\n    system-ui,\n    -apple-system,\n    sans-serif;\n  --mono:\n    "Geist Mono",\n    "JetBrains Mono",\n    ui-monospace,\n    monospace;\n  font-family: var(--display);\n  -webkit-font-smoothing: antialiased;\n}\n.auth-wrap[_ngcontent-%COMP%] {\n  min-height: 100vh;\n  display: flex;\n  background: var(--bg);\n  color: var(--fg);\n}\n.auth-left[_ngcontent-%COMP%] {\n  display: none;\n  width: 44%;\n  flex-shrink: 0;\n  background: var(--bg-2);\n  border-right: 1px solid var(--line);\n  flex-direction: column;\n  padding: 52px 48px;\n}\n@media (min-width: 1024px) {\n  .auth-left[_ngcontent-%COMP%] {\n    display: flex;\n  }\n}\n.auth-brand[_ngcontent-%COMP%] {\n  display: flex;\n  align-items: center;\n  gap: 10px;\n  font-family: var(--display);\n  font-weight: 700;\n  font-size: 18px;\n  letter-spacing: -0.02em;\n  color: var(--fg);\n  text-decoration: none;\n}\n.brand-mark[_ngcontent-%COMP%] {\n  width: 22px;\n  height: 22px;\n  border-radius: 5px;\n  background: var(--accent);\n  display: inline-flex;\n  align-items: center;\n  justify-content: center;\n  color: #0a0a0a;\n  font-size: 13px;\n  font-weight: 800;\n}\n.auth-center[_ngcontent-%COMP%] {\n  flex: 1;\n  display: flex;\n  flex-direction: column;\n  justify-content: center;\n  gap: 40px;\n}\n.eyebrow[_ngcontent-%COMP%] {\n  font-family: var(--mono);\n  font-size: 11px;\n  letter-spacing: 0.12em;\n  text-transform: uppercase;\n  color: var(--fg-3);\n}\n.auth-headline[_ngcontent-%COMP%] {\n  font-family: var(--display);\n  font-weight: 600;\n  font-size: clamp(36px, 3.2vw, 52px);\n  letter-spacing: -0.035em;\n  line-height: 0.95;\n  margin-top: 16px;\n}\n.auth-headline[_ngcontent-%COMP%]   em[_ngcontent-%COMP%] {\n  font-style: normal;\n  color: var(--accent);\n}\n.auth-benefits[_ngcontent-%COMP%] {\n  list-style: none;\n  padding: 0;\n  margin: 0;\n  display: flex;\n  flex-direction: column;\n  gap: 14px;\n}\n.auth-benefits[_ngcontent-%COMP%]   li[_ngcontent-%COMP%] {\n  display: flex;\n  align-items: center;\n  gap: 12px;\n  font-size: 15px;\n  color: var(--fg-2);\n}\n.benefit-check[_ngcontent-%COMP%] {\n  width: 20px;\n  height: 20px;\n  border-radius: 50%;\n  background: rgba(255, 77, 46, 0.12);\n  border: 1px solid rgba(255, 77, 46, 0.25);\n  display: inline-flex;\n  align-items: center;\n  justify-content: center;\n  color: var(--accent);\n  flex-shrink: 0;\n}\n.auth-trust[_ngcontent-%COMP%] {\n  margin-top: auto;\n  padding-top: 40px;\n  border-top: 1px solid var(--line);\n}\n.auth-trust-label[_ngcontent-%COMP%] {\n  font-family: var(--mono);\n  font-size: 11px;\n  color: var(--fg-3);\n  letter-spacing: 0.08em;\n  text-transform: uppercase;\n  margin-bottom: 10px;\n}\n.auth-trust-stars[_ngcontent-%COMP%] {\n  font-size: 14px;\n  color: var(--fg-2);\n}\n.auth-right[_ngcontent-%COMP%] {\n  flex: 1;\n  display: flex;\n  align-items: flex-start;\n  justify-content: center;\n  padding: 48px 32px;\n  overflow-y: auto;\n}\n.auth-form-wrap[_ngcontent-%COMP%] {\n  width: 100%;\n  max-width: 420px;\n  padding: 12px 0;\n}\n.auth-mobile-brand[_ngcontent-%COMP%] {\n  display: flex;\n  align-items: center;\n  gap: 10px;\n  font-family: var(--display);\n  font-weight: 700;\n  font-size: 18px;\n  letter-spacing: -0.02em;\n  color: var(--fg);\n  text-decoration: none;\n  margin-bottom: 40px;\n}\n@media (min-width: 1024px) {\n  .auth-mobile-brand[_ngcontent-%COMP%] {\n    display: none;\n  }\n}\n.steps-indicator[_ngcontent-%COMP%] {\n  display: flex;\n  align-items: center;\n  gap: 8px;\n  margin-bottom: 32px;\n}\n.step-item[_ngcontent-%COMP%] {\n  display: flex;\n  align-items: center;\n  gap: 8px;\n  font-family: var(--mono);\n  font-size: 11px;\n  letter-spacing: 0.06em;\n  text-transform: uppercase;\n  color: var(--fg-3);\n}\n.step-item.active[_ngcontent-%COMP%] {\n  color: var(--fg);\n}\n.step-circle[_ngcontent-%COMP%] {\n  width: 24px;\n  height: 24px;\n  border-radius: 50%;\n  border: 1px solid var(--line);\n  display: inline-flex;\n  align-items: center;\n  justify-content: center;\n  font-size: 11px;\n  font-weight: 600;\n  flex-shrink: 0;\n}\n.step-item.active[_ngcontent-%COMP%]   .step-circle[_ngcontent-%COMP%] {\n  background: var(--accent);\n  color: #0a0a0a;\n  border-color: var(--accent);\n}\n.step-item.done[_ngcontent-%COMP%]   .step-circle[_ngcontent-%COMP%] {\n  background: rgba(255, 77, 46, 0.15);\n  border-color: rgba(255, 77, 46, 0.3);\n  color: var(--accent);\n}\n.step-sep[_ngcontent-%COMP%] {\n  height: 1px;\n  width: 32px;\n  background: var(--line);\n}\n.auth-title[_ngcontent-%COMP%] {\n  font-family: var(--display);\n  font-weight: 600;\n  font-size: 30px;\n  letter-spacing: -0.025em;\n  margin-bottom: 8px;\n}\n.auth-sub[_ngcontent-%COMP%] {\n  font-size: 14px;\n  color: var(--fg-3);\n  margin-bottom: 32px;\n}\n.auth-sub[_ngcontent-%COMP%]   a[_ngcontent-%COMP%] {\n  color: var(--accent);\n  text-decoration: none;\n}\n.auth-sub[_ngcontent-%COMP%]   a[_ngcontent-%COMP%]:hover {\n  text-decoration: underline;\n}\n.form-group[_ngcontent-%COMP%] {\n  margin-bottom: 18px;\n}\n.form-label[_ngcontent-%COMP%] {\n  display: flex;\n  justify-content: space-between;\n  align-items: center;\n  font-family: var(--mono);\n  font-size: 11px;\n  letter-spacing: 0.08em;\n  text-transform: uppercase;\n  color: var(--fg-3);\n  margin-bottom: 8px;\n}\n.form-input[_ngcontent-%COMP%] {\n  width: 100%;\n  background: var(--bg-2);\n  border: 1px solid var(--line);\n  border-radius: 8px;\n  padding: 13px 16px;\n  font-size: 15px;\n  color: var(--fg);\n  outline: none;\n  transition: border-color 150ms ease;\n  font-family: var(--display);\n  appearance: none;\n  -webkit-appearance: none;\n}\n.form-input[_ngcontent-%COMP%]::placeholder {\n  color: var(--fg-3);\n}\n.form-input[_ngcontent-%COMP%]:focus {\n  border-color: var(--accent);\n}\n.form-input.has-error[_ngcontent-%COMP%] {\n  border-color: #ef4444;\n}\n.input-wrap[_ngcontent-%COMP%] {\n  position: relative;\n}\n.input-wrap[_ngcontent-%COMP%]   .form-input[_ngcontent-%COMP%] {\n  padding-right: 44px;\n}\n.eye-btn[_ngcontent-%COMP%] {\n  position: absolute;\n  right: 12px;\n  top: 50%;\n  transform: translateY(-50%);\n  background: none;\n  border: none;\n  cursor: pointer;\n  color: var(--fg-3);\n  padding: 4px;\n  display: flex;\n  align-items: center;\n  line-height: 0;\n}\n.eye-btn[_ngcontent-%COMP%]:hover {\n  color: var(--fg);\n}\n.subdomain-group[_ngcontent-%COMP%] {\n  display: flex;\n}\n.subdomain-prefix[_ngcontent-%COMP%] {\n  display: none;\n}\n.subdomain-suffix[_ngcontent-%COMP%] {\n  display: inline-flex;\n  align-items: center;\n  padding: 0 14px;\n  background: var(--bg-3);\n  border: 1px solid var(--line);\n  border-left: none;\n  border-radius: 0 8px 8px 0;\n  font-family: var(--mono);\n  font-size: 12px;\n  color: var(--fg-3);\n  white-space: nowrap;\n}\n.subdomain-group[_ngcontent-%COMP%]   .form-input[_ngcontent-%COMP%] {\n  border-radius: 8px 0 0 8px;\n}\n.form-error[_ngcontent-%COMP%] {\n  font-size: 12px;\n  color: #ef4444;\n  margin-top: 6px;\n  font-family: var(--mono);\n}\n.btn-submit[_ngcontent-%COMP%] {\n  width: 100%;\n  display: flex;\n  align-items: center;\n  justify-content: center;\n  gap: 8px;\n  background: var(--accent);\n  color: #0a0a0a;\n  border: none;\n  border-radius: 999px;\n  padding: 15px 24px;\n  font-size: 15px;\n  font-weight: 600;\n  cursor: pointer;\n  transition: background 150ms ease, opacity 150ms ease;\n  font-family: var(--display);\n  letter-spacing: -0.01em;\n}\n.btn-submit[_ngcontent-%COMP%]:hover {\n  background: var(--accent-2);\n}\n.btn-submit[_ngcontent-%COMP%]:disabled {\n  opacity: 0.5;\n  cursor: not-allowed;\n}\n.btn-ghost[_ngcontent-%COMP%] {\n  width: 100%;\n  display: flex;\n  align-items: center;\n  justify-content: center;\n  background: transparent;\n  color: var(--fg-2);\n  border: 1px solid var(--line-2);\n  border-radius: 999px;\n  padding: 14px 24px;\n  font-size: 15px;\n  font-weight: 500;\n  cursor: pointer;\n  transition: border-color 150ms ease, color 150ms ease;\n  font-family: var(--display);\n  margin-top: 10px;\n}\n.btn-ghost[_ngcontent-%COMP%]:hover {\n  border-color: var(--fg-2);\n  color: var(--fg);\n}\n.form-actions[_ngcontent-%COMP%] {\n  display: flex;\n  flex-direction: column;\n  gap: 0;\n  margin-top: 8px;\n}\n@keyframes _ngcontent-%COMP%_spin {\n  to {\n    transform: rotate(360deg);\n  }\n}\n.spin[_ngcontent-%COMP%] {\n  animation: _ngcontent-%COMP%_spin 0.8s linear infinite;\n}\n.error-alert[_ngcontent-%COMP%] {\n  display: flex;\n  align-items: flex-start;\n  gap: 10px;\n  background: rgba(239, 68, 68, 0.08);\n  border: 1px solid rgba(239, 68, 68, 0.2);\n  border-radius: 8px;\n  padding: 12px 14px;\n  margin-bottom: 20px;\n}\n.error-alert[_ngcontent-%COMP%]   svg[_ngcontent-%COMP%] {\n  color: #ef4444;\n  flex-shrink: 0;\n  margin-top: 1px;\n}\n.error-alert[_ngcontent-%COMP%]   p[_ngcontent-%COMP%] {\n  font-size: 14px;\n  color: #fca5a5;\n  margin: 0;\n}\n.auth-footer[_ngcontent-%COMP%] {\n  text-align: center;\n  margin-top: 32px;\n  font-size: 12px;\n  color: var(--fg-3);\n  font-family: var(--mono);\n  letter-spacing: 0.04em;\n}\n/*# sourceMappingURL=cadastro.component.css.map */'] });
  }
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && \u0275setClassDebugInfo(CadastroComponent, { className: "CadastroComponent" });
})();
export {
  CadastroComponent
};
//# sourceMappingURL=chunk-2JLX7JCJ.js.map
