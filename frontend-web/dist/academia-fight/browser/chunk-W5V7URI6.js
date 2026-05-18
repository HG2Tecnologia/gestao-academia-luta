import {
  environment
} from "./chunk-Z5CKO2JM.js";
import {
  CommonModule,
  HttpClient,
  ɵsetClassDebugInfo,
  ɵɵStandaloneFeature,
  ɵɵadvance,
  ɵɵdefineComponent,
  ɵɵdefineInjectable,
  ɵɵelement,
  ɵɵelementEnd,
  ɵɵelementStart,
  ɵɵinject,
  ɵɵnamespaceSVG,
  ɵɵstyleProp,
  ɵɵtext,
  ɵɵtextInterpolate1
} from "./chunk-WZ2AWGAJ.js";

// src/app/core/services/ranking.service.ts
var RankingService = class _RankingService {
  constructor(http) {
    this.http = http;
    this.base = `${environment.apiUrl}/api/ranking`;
  }
  getLeaderboardAcademia(periodo, pagina = 1) {
    return this.http.get(`${this.base}/leaderboard/academia`, {
      params: { periodo, pagina: pagina.toString() }
    });
  }
  getLeaderboardTurma(turmaId, periodo, pagina = 1) {
    return this.http.get(`${this.base}/leaderboard/turma/${turmaId}`, {
      params: { periodo, pagina: pagina.toString() }
    });
  }
  getPerfilGamificado(alunoId) {
    return this.http.get(`${this.base}/perfil/${alunoId}`);
  }
  getConquistas(alunoId) {
    return this.http.get(`${this.base}/conquistas/${alunoId}`);
  }
  marcarConquistasVistas(alunoId) {
    return this.http.post(`${this.base}/conquistas/marcar-vistas`, { alunoId });
  }
  static {
    this.\u0275fac = function RankingService_Factory(t) {
      return new (t || _RankingService)(\u0275\u0275inject(HttpClient));
    };
  }
  static {
    this.\u0275prov = /* @__PURE__ */ \u0275\u0275defineInjectable({ token: _RankingService, factory: _RankingService.\u0275fac, providedIn: "root" });
  }
};

// src/app/core/models/ranking.model.ts
var NIVEL_CONFIG = {
  Iniciante: { cor: "#94a3b8", label: "Iniciante" },
  Guerreiro: { cor: "#22c55e", label: "Guerreiro" },
  Veterano: { cor: "#3b82f6", label: "Veterano" },
  Elite: { cor: "#a855f7", label: "Elite" },
  Mestre: { cor: "#f59e0b", label: "Mestre" }
};

// src/app/shared/components/nivel-badge/nivel-badge.component.ts
var NivelBadgeComponent = class _NivelBadgeComponent {
  constructor() {
    this.nivel = "Iniciante";
  }
  get bg() {
    return NIVEL_CONFIG[this.nivel]?.cor ?? "#94a3b8";
  }
  get label() {
    return NIVEL_CONFIG[this.nivel]?.label ?? this.nivel;
  }
  static {
    this.\u0275fac = function NivelBadgeComponent_Factory(t) {
      return new (t || _NivelBadgeComponent)();
    };
  }
  static {
    this.\u0275cmp = /* @__PURE__ */ \u0275\u0275defineComponent({ type: _NivelBadgeComponent, selectors: [["app-nivel-badge"]], inputs: { nivel: "nivel" }, standalone: true, features: [\u0275\u0275StandaloneFeature], decls: 4, vars: 7, consts: [[1, "nivel-badge"], ["width", "10", "height", "10", "viewBox", "0 0 24 24", "fill", "currentColor"], ["d", "M12 2l2.4 7.4H22l-6.2 4.5 2.4 7.4L12 17l-6.2 4.3 2.4-7.4L2 9.4h7.6z"]], template: function NivelBadgeComponent_Template(rf, ctx) {
      if (rf & 1) {
        \u0275\u0275elementStart(0, "span", 0);
        \u0275\u0275namespaceSVG();
        \u0275\u0275elementStart(1, "svg", 1);
        \u0275\u0275element(2, "path", 2);
        \u0275\u0275elementEnd();
        \u0275\u0275text(3);
        \u0275\u0275elementEnd();
      }
      if (rf & 2) {
        \u0275\u0275styleProp("background", ctx.bg + "22")("color", ctx.bg)("border", "1px solid " + ctx.bg + "55");
        \u0275\u0275advance(3);
        \u0275\u0275textInterpolate1(" ", ctx.label, " ");
      }
    }, dependencies: [CommonModule], styles: ["\n\n.nivel-badge[_ngcontent-%COMP%] {\n  display: inline-flex;\n  align-items: center;\n  gap: 4px;\n  padding: 2px 8px;\n  border-radius: 99px;\n  font-size: 0.7rem;\n  font-weight: 600;\n}\n/*# sourceMappingURL=nivel-badge.component.css.map */"] });
  }
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && \u0275setClassDebugInfo(NivelBadgeComponent, { className: "NivelBadgeComponent" });
})();

export {
  RankingService,
  NIVEL_CONFIG,
  NivelBadgeComponent
};
//# sourceMappingURL=chunk-W5V7URI6.js.map
