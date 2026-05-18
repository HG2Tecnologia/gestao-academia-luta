import {
  CommonModule,
  ɵsetClassDebugInfo,
  ɵɵStandaloneFeature,
  ɵɵdefineComponent,
  ɵɵelement,
  ɵɵproperty,
  ɵɵstyleProp
} from "./chunk-WZ2AWGAJ.js";

// src/app/shared/components/badge-faixa/badge-faixa.component.ts
var BadgeFaixaComponent = class _BadgeFaixaComponent {
  constructor() {
    this.cor = "#FFFFFF";
    this.nome = "";
    this.tamanho = "md";
    this.tamanhos = { sm: 14, md: 20, lg: 28 };
  }
  static {
    this.\u0275fac = function BadgeFaixaComponent_Factory(t) {
      return new (t || _BadgeFaixaComponent)();
    };
  }
  static {
    this.\u0275cmp = /* @__PURE__ */ \u0275\u0275defineComponent({ type: _BadgeFaixaComponent, selectors: [["app-badge-faixa"]], inputs: { cor: "cor", nome: "nome", tamanho: "tamanho" }, standalone: true, features: [\u0275\u0275StandaloneFeature], decls: 1, vars: 7, consts: [[1, "badge-faixa", 3, "title"]], template: function BadgeFaixaComponent_Template(rf, ctx) {
      if (rf & 1) {
        \u0275\u0275element(0, "span", 0);
      }
      if (rf & 2) {
        \u0275\u0275styleProp("background-color", ctx.cor)("width", ctx.tamanhos[ctx.tamanho], "px")("height", ctx.tamanhos[ctx.tamanho], "px");
        \u0275\u0275property("title", ctx.nome);
      }
    }, dependencies: [CommonModule], styles: ["\n\n.badge-faixa[_ngcontent-%COMP%] {\n  display: inline-block;\n  border-radius: 2px;\n  border: 2px solid rgba(255, 255, 255, 0.6);\n  flex-shrink: 0;\n}\n/*# sourceMappingURL=badge-faixa.component.css.map */"] });
  }
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && \u0275setClassDebugInfo(BadgeFaixaComponent, { className: "BadgeFaixaComponent" });
})();

export {
  BadgeFaixaComponent
};
//# sourceMappingURL=chunk-ZVPVJ4B3.js.map
