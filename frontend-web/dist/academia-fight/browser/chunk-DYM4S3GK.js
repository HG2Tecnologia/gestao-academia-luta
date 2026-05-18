import {
  ContratoService
} from "./chunk-AJ67XLLV.js";
import {
  AlunoService
} from "./chunk-ZSIQJU4D.js";
import "./chunk-Z5CKO2JM.js";
import {
  ActivatedRoute,
  DomSanitizer,
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

// src/app/features/contratos/pages/detalhe/contrato-detalhe.component.ts
var _c0 = () => [1, 2, 3];
function ContratoDetalheComponent_Conditional_5_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "h1", 6);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(2, "p", 7);
    \u0275\u0275text(3);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const c_r1 = ctx;
    const ctx_r1 = \u0275\u0275nextContext();
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1("Contrato \u2014 ", c_r1.nomeAluno, "");
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate1("Criado em ", ctx_r1.formatarData(c_r1.criadoEm), "");
  }
}
function ContratoDetalheComponent_Conditional_6_Conditional_1_Conditional_0_Template(rf, ctx) {
  if (rf & 1) {
    const _r5 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "button", 17);
    \u0275\u0275listener("click", function ContratoDetalheComponent_Conditional_6_Conditional_1_Conditional_0_Template_button_click_0_listener() {
      \u0275\u0275restoreView(_r5);
      const ctx_r1 = \u0275\u0275nextContext(3);
      return \u0275\u0275resetView(ctx_r1.enviarWhatsApp());
    });
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(1, "svg", 18);
    \u0275\u0275element(2, "path", 19);
    \u0275\u0275elementEnd();
    \u0275\u0275text(3, " Enviar via WhatsApp ");
    \u0275\u0275elementEnd();
  }
}
function ContratoDetalheComponent_Conditional_6_Conditional_1_Template(rf, ctx) {
  if (rf & 1) {
    const _r4 = \u0275\u0275getCurrentView();
    \u0275\u0275template(0, ContratoDetalheComponent_Conditional_6_Conditional_1_Conditional_0_Template, 4, 0, "button", 14);
    \u0275\u0275elementStart(1, "button", 9);
    \u0275\u0275listener("click", function ContratoDetalheComponent_Conditional_6_Conditional_1_Template_button_click_1_listener() {
      \u0275\u0275restoreView(_r4);
      const ctx_r1 = \u0275\u0275nextContext(2);
      return \u0275\u0275resetView(ctx_r1.copiarLink());
    });
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(2, "svg", 10);
    \u0275\u0275element(3, "rect", 15)(4, "path", 16);
    \u0275\u0275elementEnd();
    \u0275\u0275text(5, " Copiar link ");
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(2);
    \u0275\u0275conditional(0, ctx_r1.telefoneAluno() ? 0 : -1);
  }
}
function ContratoDetalheComponent_Conditional_6_Template(rf, ctx) {
  if (rf & 1) {
    const _r3 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 3);
    \u0275\u0275template(1, ContratoDetalheComponent_Conditional_6_Conditional_1_Template, 6, 1, "button", 8);
    \u0275\u0275elementStart(2, "button", 9);
    \u0275\u0275listener("click", function ContratoDetalheComponent_Conditional_6_Template_button_click_2_listener() {
      \u0275\u0275restoreView(_r3);
      const ctx_r1 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r1.imprimirContrato());
    });
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(3, "svg", 10);
    \u0275\u0275element(4, "polyline", 11)(5, "path", 12)(6, "rect", 13);
    \u0275\u0275elementEnd();
    \u0275\u0275text(7, " Imprimir PDF ");
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    \u0275\u0275advance();
    \u0275\u0275conditional(1, ctx.status === 1 ? 1 : -1);
  }
}
function ContratoDetalheComponent_Conditional_7_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 4);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext();
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(ctx_r1.erro());
  }
}
function ContratoDetalheComponent_Conditional_8_For_2_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275element(0, "div", 20);
  }
}
function ContratoDetalheComponent_Conditional_8_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 5);
    \u0275\u0275repeaterCreate(1, ContratoDetalheComponent_Conditional_8_For_2_Template, 1, 0, "div", 20, \u0275\u0275repeaterTrackByIdentity);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    \u0275\u0275advance();
    \u0275\u0275repeater(\u0275\u0275pureFunction0(0, _c0));
  }
}
function ContratoDetalheComponent_Conditional_9_Conditional_0_Conditional_1_Conditional_4_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 27);
    \u0275\u0275text(1, '(aluno sem telefone cadastrado \u2014 use "Copiar link")');
    \u0275\u0275elementEnd();
  }
}
function ContratoDetalheComponent_Conditional_9_Conditional_0_Conditional_1_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(0, "svg", 24);
    \u0275\u0275element(1, "circle", 25)(2, "polyline", 26);
    \u0275\u0275elementEnd();
    \u0275\u0275text(3, " Aguardando assinatura do aluno ");
    \u0275\u0275template(4, ContratoDetalheComponent_Conditional_9_Conditional_0_Conditional_1_Conditional_4_Template, 2, 0, "span", 27);
  }
  if (rf & 2) {
    const ctx_r1 = \u0275\u0275nextContext(3);
    \u0275\u0275advance(4);
    \u0275\u0275conditional(4, !ctx_r1.telefoneAluno() ? 4 : -1);
  }
}
function ContratoDetalheComponent_Conditional_9_Conditional_0_Conditional_2_Conditional_6_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275text(0);
  }
  if (rf & 2) {
    const c_r6 = \u0275\u0275nextContext(2);
    \u0275\u0275textInterpolate1(" \xA0\xB7 IP: ", c_r6.ipAssinatura, " ");
  }
}
function ContratoDetalheComponent_Conditional_9_Conditional_0_Conditional_2_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(0, "svg", 24);
    \u0275\u0275element(1, "polyline", 28);
    \u0275\u0275elementEnd();
    \u0275\u0275text(2, " Assinado por ");
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(3, "strong");
    \u0275\u0275text(4);
    \u0275\u0275elementEnd();
    \u0275\u0275text(5);
    \u0275\u0275template(6, ContratoDetalheComponent_Conditional_9_Conditional_0_Conditional_2_Conditional_6_Template, 1, 1);
  }
  if (rf & 2) {
    const c_r6 = \u0275\u0275nextContext();
    const ctx_r1 = \u0275\u0275nextContext(2);
    \u0275\u0275advance(4);
    \u0275\u0275textInterpolate(c_r6.nomeAssinou);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1(" em ", ctx_r1.formatarData(c_r6.dataAssinatura), " ");
    \u0275\u0275advance();
    \u0275\u0275conditional(6, c_r6.ipAssinatura ? 6 : -1);
  }
}
function ContratoDetalheComponent_Conditional_9_Conditional_0_Conditional_3_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(0, "svg", 24);
    \u0275\u0275element(1, "line", 29)(2, "line", 30);
    \u0275\u0275elementEnd();
    \u0275\u0275text(3, " Contrato cancelado ");
  }
}
function ContratoDetalheComponent_Conditional_9_Conditional_0_Conditional_5_Conditional_7_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "p");
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const c_r6 = \u0275\u0275nextContext(2);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1("Endere\xE7o IP: ", c_r6.ipAssinatura, "");
  }
}
function ContratoDetalheComponent_Conditional_9_Conditional_0_Conditional_5_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 23)(1, "p");
    \u0275\u0275text(2, "Assinado digitalmente por: ");
    \u0275\u0275elementStart(3, "strong");
    \u0275\u0275text(4);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(5, "p");
    \u0275\u0275text(6);
    \u0275\u0275elementEnd();
    \u0275\u0275template(7, ContratoDetalheComponent_Conditional_9_Conditional_0_Conditional_5_Conditional_7_Template, 2, 1, "p");
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const c_r6 = \u0275\u0275nextContext();
    const ctx_r1 = \u0275\u0275nextContext(2);
    \u0275\u0275advance(4);
    \u0275\u0275textInterpolate(c_r6.nomeAssinou);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate1("Data e hora: ", ctx_r1.formatarData(c_r6.dataAssinatura), "");
    \u0275\u0275advance();
    \u0275\u0275conditional(7, c_r6.ipAssinatura ? 7 : -1);
  }
}
function ContratoDetalheComponent_Conditional_9_Conditional_0_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 21);
    \u0275\u0275template(1, ContratoDetalheComponent_Conditional_9_Conditional_0_Conditional_1_Template, 5, 1)(2, ContratoDetalheComponent_Conditional_9_Conditional_0_Conditional_2_Template, 7, 3)(3, ContratoDetalheComponent_Conditional_9_Conditional_0_Conditional_3_Template, 4, 0);
    \u0275\u0275elementEnd();
    \u0275\u0275element(4, "div", 22);
    \u0275\u0275template(5, ContratoDetalheComponent_Conditional_9_Conditional_0_Conditional_5_Template, 8, 3, "div", 23);
  }
  if (rf & 2) {
    const c_r6 = ctx;
    const ctx_r1 = \u0275\u0275nextContext(2);
    \u0275\u0275classProp("status-assinado", c_r6.status === 2)("status-cancelado", c_r6.status === 3);
    \u0275\u0275advance();
    \u0275\u0275conditional(1, c_r6.status === 1 ? 1 : -1);
    \u0275\u0275advance();
    \u0275\u0275conditional(2, c_r6.status === 2 ? 2 : -1);
    \u0275\u0275advance();
    \u0275\u0275conditional(3, c_r6.status === 3 ? 3 : -1);
    \u0275\u0275advance();
    \u0275\u0275property("innerHTML", ctx_r1.conteudoSafe(), \u0275\u0275sanitizeHtml);
    \u0275\u0275advance();
    \u0275\u0275conditional(5, c_r6.status === 2 ? 5 : -1);
  }
}
function ContratoDetalheComponent_Conditional_9_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275template(0, ContratoDetalheComponent_Conditional_9_Conditional_0_Template, 6, 9);
  }
  if (rf & 2) {
    let tmp_1_0;
    const ctx_r1 = \u0275\u0275nextContext();
    \u0275\u0275conditional(0, (tmp_1_0 = ctx_r1.contrato()) ? 0 : -1, tmp_1_0);
  }
}
var ContratoDetalheComponent = class _ContratoDetalheComponent {
  constructor() {
    this.route = inject(ActivatedRoute);
    this.contratoService = inject(ContratoService);
    this.alunoService = inject(AlunoService);
    this.sanitizer = inject(DomSanitizer);
    this.carregando = signal(true);
    this.erro = signal("");
    this.contrato = signal(null);
    this.conteudoSafe = signal("");
    this.telefoneAluno = signal("");
  }
  ngOnInit() {
    const id = this.route.snapshot.paramMap.get("id");
    this.contratoService.obter(id).subscribe({
      next: (res) => {
        if (res.dados) {
          this.contrato.set(res.dados);
          this.conteudoSafe.set(this.sanitizer.bypassSecurityTrustHtml(res.dados.conteudoHtml));
          this.carregarTelefone(res.dados.alunoId);
        } else {
          this.erro.set(res.mensagem ?? "Contrato n\xE3o encontrado.");
        }
        this.carregando.set(false);
      },
      error: () => {
        this.erro.set("Erro ao carregar contrato.");
        this.carregando.set(false);
      }
    });
  }
  carregarTelefone(alunoId) {
    this.alunoService.getById(alunoId).subscribe({
      next: (res) => {
        if (res.dados?.telefone)
          this.telefoneAluno.set(res.dados.telefone);
      }
    });
  }
  linkPublico() {
    const token = this.contrato()?.tokenPublico;
    return token ? `${window.location.origin}/assinar/${token}` : "";
  }
  enviarWhatsApp() {
    const telefone = this.telefoneAluno().replace(/\D/g, "");
    const link = this.linkPublico();
    const texto = encodeURIComponent(`Ol\xE1 ${this.contrato()?.nomeAluno}, segue o link para assinar seu contrato:
${link}`);
    window.open(`https://wa.me/55${telefone}?text=${texto}`, "_blank");
  }
  copiarLink() {
    navigator.clipboard.writeText(this.linkPublico());
  }
  imprimirContrato() {
    const html = this.contrato()?.conteudoHtml ?? "";
    const nomeAcademia = document.title;
    const janela = window.open("", "_blank", "width=800,height=900");
    if (!janela)
      return;
    janela.document.write(`<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <title>Contrato</title>
  <style>
    body { font-family: Arial, sans-serif; padding: 40px 60px; font-size: 14px; line-height: 1.7; color: #111; }
    h2 { font-size: 20px; margin-bottom: 12px; }
    h3 { font-size: 15px; margin: 20px 0 8px; }
    p { margin-bottom: 6px; }
    hr { border: none; border-top: 1px solid #ccc; margin: 16px 0; }
  </style>
</head>
<body>${html}</body>
</html>`);
    janela.document.close();
    janela.onload = () => {
      janela.print();
    };
  }
  formatarData(d) {
    if (!d)
      return "\u2014";
    return new Date(d).toLocaleString("pt-BR");
  }
  static {
    this.\u0275fac = function ContratoDetalheComponent_Factory(t) {
      return new (t || _ContratoDetalheComponent)();
    };
  }
  static {
    this.\u0275cmp = /* @__PURE__ */ \u0275\u0275defineComponent({ type: _ContratoDetalheComponent, selectors: [["app-contrato-detalhe"]], standalone: true, features: [\u0275\u0275StandaloneFeature], decls: 10, vars: 4, consts: [[1, "page-container"], [1, "page-header", "no-print"], ["routerLink", "/app/contratos", 1, "back-link"], [2, "display", "flex", "gap", "8px", "flex-wrap", "wrap"], [1, "alert-error"], [1, "skeleton-list"], [1, "page-title"], [1, "page-subtitle"], [1, "btn-secondary"], [1, "btn-secondary", 3, "click"], ["width", "14", "height", "14", "fill", "none", "stroke", "currentColor", "stroke-width", "2", "viewBox", "0 0 24 24"], ["points", "6 9 6 2 18 2 18 9"], ["d", "M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"], ["x", "6", "y", "14", "width", "12", "height", "8"], [1, "btn-wpp"], ["x", "9", "y", "9", "width", "13", "height", "13", "rx", "2", "ry", "2"], ["d", "M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"], [1, "btn-wpp", 3, "click"], ["width", "15", "height", "15", "viewBox", "0 0 24 24", "fill", "currentColor"], ["d", "M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"], [1, "skeleton-row", 2, "height", "60px"], [1, "status-bar", "no-print"], [1, "contrato-body", 3, "innerHTML"], [1, "assinatura-rodape"], ["width", "16", "height", "16", "fill", "none", "stroke", "currentColor", "stroke-width", "2", "viewBox", "0 0 24 24"], ["cx", "12", "cy", "12", "r", "10"], ["points", "12 6 12 12 16 14"], [2, "font-size", "11px", "opacity", "0.7", "margin-left", "8px"], ["points", "20 6 9 17 4 12"], ["x1", "18", "y1", "6", "x2", "6", "y2", "18"], ["x1", "6", "y1", "6", "x2", "18", "y2", "18"]], template: function ContratoDetalheComponent_Template(rf, ctx) {
      if (rf & 1) {
        \u0275\u0275elementStart(0, "div", 0)(1, "div", 1)(2, "div")(3, "a", 2);
        \u0275\u0275text(4, "\u2190 Contratos");
        \u0275\u0275elementEnd();
        \u0275\u0275template(5, ContratoDetalheComponent_Conditional_5_Template, 4, 2);
        \u0275\u0275elementEnd();
        \u0275\u0275template(6, ContratoDetalheComponent_Conditional_6_Template, 8, 1, "div", 3);
        \u0275\u0275elementEnd();
        \u0275\u0275template(7, ContratoDetalheComponent_Conditional_7_Template, 2, 1, "div", 4)(8, ContratoDetalheComponent_Conditional_8_Template, 3, 1, "div", 5)(9, ContratoDetalheComponent_Conditional_9_Template, 1, 1);
        \u0275\u0275elementEnd();
      }
      if (rf & 2) {
        let tmp_0_0;
        let tmp_1_0;
        \u0275\u0275advance(5);
        \u0275\u0275conditional(5, (tmp_0_0 = ctx.contrato()) ? 5 : -1, tmp_0_0);
        \u0275\u0275advance();
        \u0275\u0275conditional(6, (tmp_1_0 = ctx.contrato()) ? 6 : -1, tmp_1_0);
        \u0275\u0275advance();
        \u0275\u0275conditional(7, ctx.erro() ? 7 : -1);
        \u0275\u0275advance();
        \u0275\u0275conditional(8, ctx.carregando() ? 8 : 9);
      }
    }, dependencies: [CommonModule, RouterLink], styles: [".back-link[_ngcontent-%COMP%] { font-size: 13px; color: var(--app-text-3); text-decoration: none; display: inline-block; margin-bottom: 4px; }\n  .back-link[_ngcontent-%COMP%]:hover { color: var(--app-text-1); }\n\n  .btn-wpp[_ngcontent-%COMP%] { display: inline-flex; align-items: center; gap: 6px; background: #25d366; color: white; border: none; border-radius: 8px; padding: 8px 14px; font-size: 13px; font-weight: 600; cursor: pointer; }\n  .btn-wpp[_ngcontent-%COMP%]:hover { background: #20bd5c; }\n\n  .status-bar[_ngcontent-%COMP%] { display: flex; align-items: center; gap: 8px; font-size: 13px; font-weight: 500; padding: 10px 16px; border-radius: 8px; margin-bottom: 20px; background: rgba(245,158,11,0.1); color: #b45309; border: 1px solid rgba(245,158,11,0.2); flex-wrap: wrap; }\n  .status-assinado[_ngcontent-%COMP%]  { background: rgba(34,197,94,0.1);  color: #15803d; border-color: rgba(34,197,94,0.2); }\n  .status-cancelado[_ngcontent-%COMP%] { background: rgba(107,114,128,0.1); color: #6b7280; border-color: rgba(107,114,128,0.2); }\n\n  .contrato-body[_ngcontent-%COMP%] { background: var(--app-surface); border: 1px solid var(--app-border); border-radius: 12px; padding: 40px 48px; max-width: 760px; margin: 0 auto; line-height: 1.7; font-size: 14px; color: var(--app-text-1); }\n  .contrato-body[_ngcontent-%COMP%]   h2[_ngcontent-%COMP%] { font-size: 20px; font-weight: 700; margin-bottom: 16px; }\n  .contrato-body[_ngcontent-%COMP%]   h3[_ngcontent-%COMP%] { font-size: 15px; font-weight: 600; margin: 20px 0 8px; }\n  .contrato-body[_ngcontent-%COMP%]   p[_ngcontent-%COMP%]  { margin-bottom: 8px; }\n  .contrato-body[_ngcontent-%COMP%]   hr[_ngcontent-%COMP%] { border: none; border-top: 1px solid var(--app-border); margin: 20px 0; }\n\n  .assinatura-rodape[_ngcontent-%COMP%] { max-width: 760px; margin: 20px auto 0; padding: 16px 48px; border: 1px solid var(--app-border); border-radius: 8px; font-size: 12px; color: var(--app-text-2); background: var(--app-surface); }\n  .assinatura-rodape[_ngcontent-%COMP%]   p[_ngcontent-%COMP%] { margin-bottom: 4px; }\n\n  @media print {\n    .no-print[_ngcontent-%COMP%] { display: none !important; }\n  }"] });
  }
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && \u0275setClassDebugInfo(ContratoDetalheComponent, { className: "ContratoDetalheComponent" });
})();
export {
  ContratoDetalheComponent
};
//# sourceMappingURL=chunk-DYM4S3GK.js.map
