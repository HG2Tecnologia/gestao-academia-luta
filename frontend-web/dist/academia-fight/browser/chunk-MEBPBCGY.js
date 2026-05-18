import {
  ContratoService
} from "./chunk-AJ67XLLV.js";
import {
  DefaultValueAccessor,
  FormsModule,
  NgControlStatus,
  NgModel
} from "./chunk-JQJL26HT.js";
import "./chunk-Z5CKO2JM.js";
import {
  ActivatedRoute,
  DomSanitizer
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
  ɵɵsanitizeHtml,
  ɵɵtemplate,
  ɵɵtext,
  ɵɵtextInterpolate,
  ɵɵtextInterpolate1
} from "./chunk-WZ2AWGAJ.js";
import "./chunk-7G5TR5RR.js";

// src/app/features/contratos/pages/assinar/assinar-contrato.component.ts
var _c0 = () => [1, 2, 3];
function AssinarContratoComponent_Conditional_2_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 2);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(ctx_r0.contrato().nomeAcademia);
  }
}
function AssinarContratoComponent_Conditional_5_For_3_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275element(0, "div", 6);
  }
}
function AssinarContratoComponent_Conditional_5_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 4)(1, "div", 5);
    \u0275\u0275repeaterCreate(2, AssinarContratoComponent_Conditional_5_For_3_Template, 1, 0, "div", 6, \u0275\u0275repeaterTrackByIdentity);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    \u0275\u0275advance(2);
    \u0275\u0275repeater(\u0275\u0275pureFunction0(0, _c0));
  }
}
function AssinarContratoComponent_Conditional_6_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 7);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(1, "svg", 8);
    \u0275\u0275element(2, "circle", 9)(3, "line", 10)(4, "line", 11);
    \u0275\u0275elementEnd();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(5, "p", 12);
    \u0275\u0275text(6, "Link inv\xE1lido");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(7, "p", 13);
    \u0275\u0275text(8);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance(8);
    \u0275\u0275textInterpolate(ctx_r0.erro());
  }
}
function AssinarContratoComponent_Conditional_7_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 14);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(1, "svg", 15);
    \u0275\u0275element(2, "circle", 9)(3, "polyline", 16);
    \u0275\u0275elementEnd();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(4, "p", 17);
    \u0275\u0275text(5, "Contrato assinado!");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(6, "p", 18);
    \u0275\u0275text(7);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance(7);
    \u0275\u0275textInterpolate1("Sua assinatura foi registrada com sucesso. Obrigado, ", ctx_r0.nomeCompleto(), "!");
  }
}
function AssinarContratoComponent_Conditional_8_Conditional_0_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 14);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(1, "svg", 19);
    \u0275\u0275element(2, "polyline", 16);
    \u0275\u0275elementEnd();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(3, "p", 20);
    \u0275\u0275text(4, "Contrato j\xE1 assinado");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(5, "p", 13);
    \u0275\u0275text(6, "Assinado por ");
    \u0275\u0275elementStart(7, "strong");
    \u0275\u0275text(8);
    \u0275\u0275elementEnd();
    \u0275\u0275text(9);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext(2);
    \u0275\u0275advance(8);
    \u0275\u0275textInterpolate(ctx_r0.contrato().nomeAssinou);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1(" em ", ctx_r0.formatarData(ctx_r0.contrato().dataAssinatura), "");
  }
}
function AssinarContratoComponent_Conditional_8_Conditional_1_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 21)(1, "p", 22);
    \u0275\u0275text(2, "Este contrato foi cancelado.");
    \u0275\u0275elementEnd()();
  }
}
function AssinarContratoComponent_Conditional_8_Conditional_2_Conditional_6_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 27);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext(3);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(ctx_r0.erroAssinatura());
  }
}
function AssinarContratoComponent_Conditional_8_Conditional_2_Conditional_15_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275text(0, " Assinando... ");
  }
}
function AssinarContratoComponent_Conditional_8_Conditional_2_Conditional_16_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(0, "svg", 34);
    \u0275\u0275element(1, "polyline", 16);
    \u0275\u0275elementEnd();
    \u0275\u0275text(2, " Confirmar assinatura ");
  }
}
function AssinarContratoComponent_Conditional_8_Conditional_2_Template(rf, ctx) {
  if (rf & 1) {
    const _r2 = \u0275\u0275getCurrentView();
    \u0275\u0275element(0, "div", 23);
    \u0275\u0275elementStart(1, "div", 24)(2, "h3", 25);
    \u0275\u0275text(3, "Assinar digitalmente");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(4, "p", 26);
    \u0275\u0275text(5, " Ao assinar, voc\xEA confirma que leu e concordou com todos os termos acima. Sua assinatura registrar\xE1 seu nome, data/hora e IP. ");
    \u0275\u0275elementEnd();
    \u0275\u0275template(6, AssinarContratoComponent_Conditional_8_Conditional_2_Conditional_6_Template, 2, 1, "div", 27);
    \u0275\u0275elementStart(7, "div", 28)(8, "label", 29);
    \u0275\u0275text(9, "Seu nome completo *");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(10, "input", 30);
    \u0275\u0275listener("ngModelChange", function AssinarContratoComponent_Conditional_8_Conditional_2_Template_input_ngModelChange_10_listener($event) {
      \u0275\u0275restoreView(_r2);
      const ctx_r0 = \u0275\u0275nextContext(2);
      return \u0275\u0275resetView(ctx_r0.nomeCompleto.set($event));
    });
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(11, "label", 31)(12, "input", 32);
    \u0275\u0275listener("change", function AssinarContratoComponent_Conditional_8_Conditional_2_Template_input_change_12_listener() {
      \u0275\u0275restoreView(_r2);
      const ctx_r0 = \u0275\u0275nextContext(2);
      return \u0275\u0275resetView(ctx_r0.aceito.set(!ctx_r0.aceito()));
    });
    \u0275\u0275elementEnd();
    \u0275\u0275text(13, " Li e concordo com todos os termos e condi\xE7\xF5es deste contrato. ");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(14, "button", 33);
    \u0275\u0275listener("click", function AssinarContratoComponent_Conditional_8_Conditional_2_Template_button_click_14_listener() {
      \u0275\u0275restoreView(_r2);
      const ctx_r0 = \u0275\u0275nextContext(2);
      return \u0275\u0275resetView(ctx_r0.confirmarAssinatura());
    });
    \u0275\u0275template(15, AssinarContratoComponent_Conditional_8_Conditional_2_Conditional_15_Template, 1, 0)(16, AssinarContratoComponent_Conditional_8_Conditional_2_Conditional_16_Template, 3, 0);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext(2);
    \u0275\u0275property("innerHTML", ctx_r0.conteudoSafe(), \u0275\u0275sanitizeHtml);
    \u0275\u0275advance(6);
    \u0275\u0275conditional(6, ctx_r0.erroAssinatura() ? 6 : -1);
    \u0275\u0275advance(4);
    \u0275\u0275property("ngModel", ctx_r0.nomeCompleto());
    \u0275\u0275advance(2);
    \u0275\u0275property("checked", ctx_r0.aceito());
    \u0275\u0275advance(2);
    \u0275\u0275property("disabled", ctx_r0.assinando());
    \u0275\u0275advance();
    \u0275\u0275conditional(15, ctx_r0.assinando() ? 15 : 16);
  }
}
function AssinarContratoComponent_Conditional_8_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275template(0, AssinarContratoComponent_Conditional_8_Conditional_0_Template, 10, 2, "div", 14)(1, AssinarContratoComponent_Conditional_8_Conditional_1_Template, 3, 0)(2, AssinarContratoComponent_Conditional_8_Conditional_2_Template, 17, 6);
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275conditional(0, ctx_r0.contrato().status === 2 ? 0 : ctx_r0.contrato().status === 3 ? 1 : 2);
  }
}
var AssinarContratoComponent = class _AssinarContratoComponent {
  constructor() {
    this.route = inject(ActivatedRoute);
    this.contratoService = inject(ContratoService);
    this.sanitizer = inject(DomSanitizer);
    this.carregando = signal(true);
    this.erro = signal("");
    this.contrato = signal(null);
    this.conteudoSafe = signal("");
    this.nomeCompleto = signal("");
    this.aceito = signal(false);
    this.assinando = signal(false);
    this.erroAssinatura = signal("");
    this.assinado = signal(false);
  }
  ngOnInit() {
    const token = this.route.snapshot.paramMap.get("token");
    this.contratoService.obterPublico(token).subscribe({
      next: (res) => {
        if (res.dados) {
          this.contrato.set(res.dados);
          this.conteudoSafe.set(this.sanitizer.bypassSecurityTrustHtml(res.dados.conteudoHtml));
          if (res.dados.status !== 1)
            this.erro.set("");
        } else {
          this.erro.set(res.mensagem ?? "Contrato n\xE3o encontrado.");
        }
        this.carregando.set(false);
      },
      error: () => {
        this.erro.set("Contrato n\xE3o encontrado ou link inv\xE1lido.");
        this.carregando.set(false);
      }
    });
  }
  confirmarAssinatura() {
    if (!this.aceito()) {
      this.erroAssinatura.set("Voc\xEA precisa marcar que leu e concorda.");
      return;
    }
    if (!this.nomeCompleto().trim()) {
      this.erroAssinatura.set("Informe seu nome completo.");
      return;
    }
    const token = this.route.snapshot.paramMap.get("token");
    this.assinando.set(true);
    this.erroAssinatura.set("");
    this.contratoService.assinarPublico(token, { nomeCompleto: this.nomeCompleto() }).subscribe({
      next: (res) => {
        this.assinando.set(false);
        if (res.sucesso) {
          this.assinado.set(true);
        } else {
          this.erroAssinatura.set(res.mensagem ?? "Erro ao assinar.");
        }
      },
      error: (err) => {
        this.assinando.set(false);
        this.erroAssinatura.set(err.error?.mensagem ?? "Erro ao assinar.");
      }
    });
  }
  formatarData(d) {
    if (!d)
      return "\u2014";
    return new Date(d).toLocaleString("pt-BR");
  }
  static {
    this.\u0275fac = function AssinarContratoComponent_Factory(t) {
      return new (t || _AssinarContratoComponent)();
    };
  }
  static {
    this.\u0275cmp = /* @__PURE__ */ \u0275\u0275defineComponent({ type: _AssinarContratoComponent, selectors: [["app-assinar-contrato"]], standalone: true, features: [\u0275\u0275StandaloneFeature], decls: 9, vars: 2, consts: [[1, "assinar-page"], [1, "assinar-header"], [1, "academia-nome"], [1, "page-title-pub"], [1, "assinar-card"], [1, "skeleton-list"], [1, "skeleton-row", 2, "height", "60px"], [1, "assinar-card", "error-card-pub"], ["width", "40", "height", "40", "fill", "none", "stroke", "currentColor", "stroke-width", "1.5", "viewBox", "0 0 24 24", 2, "color", "#ef4444", "margin-bottom", "12px"], ["cx", "12", "cy", "12", "r", "10"], ["x1", "12", "y1", "8", "x2", "12", "y2", "12"], ["x1", "12", "y1", "16", "x2", "12.01", "y2", "16"], [2, "font-weight", "600", "color", "#ef4444", "margin", "0 0 4px"], [2, "font-size", "13px", "color", "#6b7280", "margin", "0"], [1, "assinar-card", "success-card"], ["width", "48", "height", "48", "fill", "none", "stroke", "currentColor", "stroke-width", "1.5", "viewBox", "0 0 24 24", 2, "color", "#22c55e", "margin-bottom", "16px"], ["points", "20 6 9 17 4 12"], [2, "font-size", "18px", "font-weight", "700", "color", "#15803d", "margin", "0 0 6px"], [2, "font-size", "14px", "color", "#6b7280", "margin", "0"], ["width", "40", "height", "40", "fill", "none", "stroke", "currentColor", "stroke-width", "1.5", "viewBox", "0 0 24 24", 2, "color", "#22c55e", "margin-bottom", "12px"], [2, "font-weight", "700", "color", "#15803d", "margin", "0 0 4px"], [1, "assinar-card", 2, "text-align", "center", "padding", "40px"], [2, "font-weight", "600", "color", "#6b7280", "margin", "0"], [1, "contrato-box", 3, "innerHTML"], [1, "assinar-card", "form-card"], [2, "font-size", "15px", "font-weight", "700", "margin", "0 0 16px"], [2, "font-size", "13px", "color", "#6b7280", "margin", "0 0 16px"], [1, "alert-error-pub", 2, "margin-bottom", "12px"], [1, "form-group-pub"], [1, "form-label-pub"], ["type", "text", "placeholder", "Digite seu nome completo", 1, "form-input-pub", 3, "ngModelChange", "ngModel"], [1, "aceite-label"], ["type", "checkbox", 3, "change", "checked"], [1, "btn-assinar", 3, "click", "disabled"], ["width", "16", "height", "16", "fill", "none", "stroke", "currentColor", "stroke-width", "2", "viewBox", "0 0 24 24"]], template: function AssinarContratoComponent_Template(rf, ctx) {
      if (rf & 1) {
        \u0275\u0275elementStart(0, "div", 0)(1, "div", 1);
        \u0275\u0275template(2, AssinarContratoComponent_Conditional_2_Template, 2, 1, "div", 2);
        \u0275\u0275elementStart(3, "div", 3);
        \u0275\u0275text(4, "Assinatura de Contrato");
        \u0275\u0275elementEnd()();
        \u0275\u0275template(5, AssinarContratoComponent_Conditional_5_Template, 4, 1, "div", 4)(6, AssinarContratoComponent_Conditional_6_Template, 9, 1)(7, AssinarContratoComponent_Conditional_7_Template, 8, 1)(8, AssinarContratoComponent_Conditional_8_Template, 3, 1);
        \u0275\u0275elementEnd();
      }
      if (rf & 2) {
        \u0275\u0275advance(2);
        \u0275\u0275conditional(2, ctx.contrato() ? 2 : -1);
        \u0275\u0275advance(3);
        \u0275\u0275conditional(5, ctx.carregando() ? 5 : ctx.erro() ? 6 : ctx.assinado() ? 7 : ctx.contrato() ? 8 : -1);
      }
    }, dependencies: [CommonModule, FormsModule, DefaultValueAccessor, NgControlStatus, NgModel], styles: ["*[_ngcontent-%COMP%] { box-sizing: border-box; }\n  body[_ngcontent-%COMP%] { margin: 0; background: #f8fafc; }\n\n  .assinar-page[_ngcontent-%COMP%] { min-height: 100vh; background: #f8fafc; padding: 0 0 60px; }\n\n  .assinar-header[_ngcontent-%COMP%] { background: white; border-bottom: 1px solid #e2e8f0; padding: 20px 24px; text-align: center; }\n  .academia-nome[_ngcontent-%COMP%] { font-size: 12px; font-weight: 600; color: #6366f1; text-transform: uppercase; letter-spacing: 0.06em; margin-bottom: 4px; }\n  .page-title-pub[_ngcontent-%COMP%] { font-size: 18px; font-weight: 700; color: #1e293b; }\n\n  .assinar-card[_ngcontent-%COMP%] { background: white; border: 1px solid #e2e8f0; border-radius: 12px; padding: 28px; max-width: 760px; margin: 24px auto; }\n  .error-card-pub[_ngcontent-%COMP%] { text-align: center; padding: 48px; }\n  .success-card[_ngcontent-%COMP%] { text-align: center; padding: 48px; }\n  .form-card[_ngcontent-%COMP%] { }\n\n  .contrato-box[_ngcontent-%COMP%] { background: white; border: 1px solid #e2e8f0; border-radius: 12px; padding: 40px 48px; max-width: 760px; margin: 24px auto; font-size: 14px; line-height: 1.75; color: #1e293b; }\n  .contrato-box[_ngcontent-%COMP%]   h2[_ngcontent-%COMP%] { font-size: 20px; font-weight: 700; margin-bottom: 16px; }\n  .contrato-box[_ngcontent-%COMP%]   h3[_ngcontent-%COMP%] { font-size: 15px; font-weight: 600; margin: 20px 0 8px; }\n  .contrato-box[_ngcontent-%COMP%]   p[_ngcontent-%COMP%] { margin-bottom: 8px; }\n  .contrato-box[_ngcontent-%COMP%]   hr[_ngcontent-%COMP%] { border: none; border-top: 1px solid #e2e8f0; margin: 20px 0; }\n\n  .form-group-pub[_ngcontent-%COMP%] { margin-bottom: 14px; }\n  .form-label-pub[_ngcontent-%COMP%] { display: block; font-size: 13px; font-weight: 600; color: #374151; margin-bottom: 6px; }\n  .form-input-pub[_ngcontent-%COMP%] { width: 100%; padding: 10px 12px; border: 1px solid #d1d5db; border-radius: 8px; font-size: 14px; color: #1e293b; outline: none; }\n  .form-input-pub[_ngcontent-%COMP%]:focus { border-color: #6366f1; box-shadow: 0 0 0 3px rgba(99,102,241,0.1); }\n\n  .aceite-label[_ngcontent-%COMP%] { display: flex; align-items: flex-start; gap: 10px; font-size: 13px; color: #374151; margin: 16px 0; cursor: pointer; line-height: 1.5; }\n  .aceite-label[_ngcontent-%COMP%]   input[_ngcontent-%COMP%] { margin-top: 2px; flex-shrink: 0; cursor: pointer; }\n\n  .btn-assinar[_ngcontent-%COMP%] { width: 100%; display: flex; align-items: center; justify-content: center; gap: 8px; background: #6366f1; color: white; border: none; border-radius: 10px; padding: 14px; font-size: 15px; font-weight: 700; cursor: pointer; margin-top: 8px; }\n  .btn-assinar[_ngcontent-%COMP%]:hover:not(:disabled) { background: #4f46e5; }\n  .btn-assinar[_ngcontent-%COMP%]:disabled { opacity: 0.6; cursor: not-allowed; }\n\n  .alert-error-pub[_ngcontent-%COMP%] { background: rgba(239,68,68,0.08); border: 1px solid rgba(239,68,68,0.25); color: #dc2626; padding: 10px 14px; border-radius: 8px; font-size: 13px; }\n\n  .skeleton-list[_ngcontent-%COMP%] { display: flex; flex-direction: column; gap: 10px; }\n  .skeleton-row[_ngcontent-%COMP%] { background: linear-gradient(90deg, #f1f5f9 25%, #e2e8f0 50%, #f1f5f9 75%); background-size: 200% 100%; animation: _ngcontent-%COMP%_shimmer 1.4s infinite; border-radius: 8px; }\n  @keyframes _ngcontent-%COMP%_shimmer { 0% { background-position: 200% 0; } 100% { background-position: -200% 0; } }\n\n  @media (max-width: 600px) {\n    .contrato-box[_ngcontent-%COMP%] { padding: 24px 20px; }\n    .assinar-card[_ngcontent-%COMP%] { margin: 16px; }\n    .contrato-box[_ngcontent-%COMP%] { margin: 16px; }\n  }"] });
  }
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && \u0275setClassDebugInfo(AssinarContratoComponent, { className: "AssinarContratoComponent" });
})();
export {
  AssinarContratoComponent
};
//# sourceMappingURL=chunk-MEBPBCGY.js.map
