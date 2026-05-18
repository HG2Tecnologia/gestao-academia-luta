import {
  NIVEL_CONFIG,
  NivelBadgeComponent,
  RankingService
} from "./chunk-W5V7URI6.js";
import "./chunk-Z5CKO2JM.js";
import {
  ActivatedRoute,
  RouterLink
} from "./chunk-AXNOULNC.js";
import {
  CommonModule,
  DatePipe,
  NgIf,
  signal,
  ɵsetClassDebugInfo,
  ɵɵNgOnChangesFeature,
  ɵɵStandaloneFeature,
  ɵɵadvance,
  ɵɵconditional,
  ɵɵdefineComponent,
  ɵɵdirectiveInject,
  ɵɵelement,
  ɵɵelementEnd,
  ɵɵelementStart,
  ɵɵgetCurrentView,
  ɵɵlistener,
  ɵɵnextContext,
  ɵɵpipe,
  ɵɵpipeBind2,
  ɵɵproperty,
  ɵɵpropertyInterpolate,
  ɵɵpureFunction0,
  ɵɵrepeater,
  ɵɵrepeaterCreate,
  ɵɵrepeaterTrackByIdentity,
  ɵɵresetView,
  ɵɵrestoreView,
  ɵɵstyleProp,
  ɵɵtemplate,
  ɵɵtext,
  ɵɵtextInterpolate,
  ɵɵtextInterpolate1,
  ɵɵtextInterpolate2
} from "./chunk-WZ2AWGAJ.js";
import "./chunk-7G5TR5RR.js";

// src/app/shared/components/xp-progress/xp-progress.component.ts
function XpProgressComponent_span_4_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 6);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance();
    \u0275\u0275textInterpolate2("+", ctx_r0.xpParaProximoNivel, " para ", ctx_r0.proximoNivel, "");
  }
}
function XpProgressComponent_span_5_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 6);
    \u0275\u0275text(1, "N\xEDvel m\xE1ximo!");
    \u0275\u0275elementEnd();
  }
}
var XpProgressComponent = class _XpProgressComponent {
  constructor() {
    this.xpAtual = 0;
    this.xpParaProximoNivel = 0;
    this.nivel = "Iniciante";
    this.pct = 0;
    this.cor = "#6366f1";
    this.LIMITES = {
      Iniciante: [0, 200],
      Guerreiro: [200, 500],
      Veterano: [500, 1e3],
      Elite: [1e3, 2e3],
      Mestre: [2e3, 2e3]
    };
    this.PROXIMO = {
      Iniciante: "Guerreiro",
      Guerreiro: "Veterano",
      Veterano: "Elite",
      Elite: "Mestre",
      Mestre: ""
    };
  }
  get proximoNivel() {
    return this.PROXIMO[this.nivel] ?? "";
  }
  ngOnChanges() {
    const [min, max] = this.LIMITES[this.nivel] ?? [0, 200];
    this.pct = max > min ? Math.min(100, (this.xpAtual - min) / (max - min) * 100) : 100;
    this.cor = NIVEL_CONFIG[this.nivel]?.cor ?? "#6366f1";
  }
  static {
    this.\u0275fac = function XpProgressComponent_Factory(t) {
      return new (t || _XpProgressComponent)();
    };
  }
  static {
    this.\u0275cmp = /* @__PURE__ */ \u0275\u0275defineComponent({ type: _XpProgressComponent, selectors: [["app-xp-progress"]], inputs: { xpAtual: "xpAtual", xpParaProximoNivel: "xpParaProximoNivel", nivel: "nivel" }, standalone: true, features: [\u0275\u0275NgOnChangesFeature, \u0275\u0275StandaloneFeature], decls: 8, vars: 7, consts: [[1, "xp-wrap"], [1, "xp-labels"], [1, "xp-atual"], ["class", "xp-meta", 4, "ngIf"], [1, "xp-bar-bg"], [1, "xp-bar-fill"], [1, "xp-meta"]], template: function XpProgressComponent_Template(rf, ctx) {
      if (rf & 1) {
        \u0275\u0275elementStart(0, "div", 0)(1, "div", 1)(2, "span", 2);
        \u0275\u0275text(3);
        \u0275\u0275elementEnd();
        \u0275\u0275template(4, XpProgressComponent_span_4_Template, 2, 2, "span", 3)(5, XpProgressComponent_span_5_Template, 2, 0, "span", 3);
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(6, "div", 4);
        \u0275\u0275element(7, "div", 5);
        \u0275\u0275elementEnd()();
      }
      if (rf & 2) {
        \u0275\u0275advance(3);
        \u0275\u0275textInterpolate1("", ctx.xpAtual, " XP");
        \u0275\u0275advance();
        \u0275\u0275property("ngIf", ctx.xpParaProximoNivel > 0);
        \u0275\u0275advance();
        \u0275\u0275property("ngIf", ctx.xpParaProximoNivel === 0);
        \u0275\u0275advance(2);
        \u0275\u0275styleProp("width", ctx.pct, "%")("background", ctx.cor);
      }
    }, dependencies: [CommonModule, NgIf], styles: ["\n\n.xp-wrap[_ngcontent-%COMP%] {\n  display: flex;\n  flex-direction: column;\n  gap: 6px;\n}\n.xp-labels[_ngcontent-%COMP%] {\n  display: flex;\n  justify-content: space-between;\n  font-size: 0.75rem;\n}\n.xp-atual[_ngcontent-%COMP%] {\n  font-weight: 700;\n  color: var(--app-text-1);\n}\n.xp-meta[_ngcontent-%COMP%] {\n  color: var(--app-text-3);\n}\n.xp-bar-bg[_ngcontent-%COMP%] {\n  height: 8px;\n  background: var(--app-border);\n  border-radius: 99px;\n  overflow: hidden;\n}\n.xp-bar-fill[_ngcontent-%COMP%] {\n  height: 100%;\n  border-radius: 99px;\n  transition: width 1s ease;\n}\n/*# sourceMappingURL=xp-progress.component.css.map */"] });
  }
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && \u0275setClassDebugInfo(XpProgressComponent, { className: "XpProgressComponent" });
})();

// src/app/features/ranking/pages/perfil-gamificado/perfil-gamificado.component.ts
var _forTrack0 = ($index, $item) => $item.id;
var _c0 = () => [1, 2, 3];
function PerfilGamificadoComponent_Conditional_5_For_2_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275element(0, "div", 5);
  }
}
function PerfilGamificadoComponent_Conditional_5_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 3);
    \u0275\u0275repeaterCreate(1, PerfilGamificadoComponent_Conditional_5_For_2_Template, 1, 0, "div", 5, \u0275\u0275repeaterTrackByIdentity);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    \u0275\u0275advance();
    \u0275\u0275repeater(\u0275\u0275pureFunction0(0, _c0));
  }
}
function PerfilGamificadoComponent_Conditional_6_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 6);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(ctx_r0.erro());
  }
}
function PerfilGamificadoComponent_Conditional_7_For_42_Template(rf, ctx) {
  if (rf & 1) {
    const _r2 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 23);
    \u0275\u0275listener("click", function PerfilGamificadoComponent_Conditional_7_For_42_Template_div_click_0_listener() {
      const c_r3 = \u0275\u0275restoreView(_r2).$implicit;
      const ctx_r0 = \u0275\u0275nextContext(2);
      return \u0275\u0275resetView(ctx_r0.conquistaSelecionada.set(c_r3));
    });
    \u0275\u0275elementStart(1, "div", 24);
    \u0275\u0275text(2);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "div", 25);
    \u0275\u0275text(4);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const c_r3 = ctx.$implicit;
    \u0275\u0275propertyInterpolate("title", c_r3.nome);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(c_r3.iconeUrl);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(c_r3.nome);
  }
}
function PerfilGamificadoComponent_Conditional_7_Conditional_46_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 22);
    \u0275\u0275text(1, "Nenhum evento registrado.");
    \u0275\u0275elementEnd();
  }
}
function PerfilGamificadoComponent_Conditional_7_Conditional_47_For_2_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 27)(1, "span", 28);
    \u0275\u0275text(2);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "div", 29);
    \u0275\u0275text(4);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(5, "strong", 30);
    \u0275\u0275text(6);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(7, "span", 31);
    \u0275\u0275text(8);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const h_r4 = ctx.$implicit;
    const ctx_r0 = \u0275\u0275nextContext(3);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(ctx_r0.tipoIcone(h_r4.tipoEvento));
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(h_r4.tipoEvento);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate1("+", h_r4.pontos, " XP");
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(h_r4.data);
  }
}
function PerfilGamificadoComponent_Conditional_7_Conditional_47_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 26);
    \u0275\u0275repeaterCreate(1, PerfilGamificadoComponent_Conditional_7_Conditional_47_For_2_Template, 9, 4, "div", 27, _forTrack0);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext(2);
    \u0275\u0275advance();
    \u0275\u0275repeater(ctx_r0.perfil().historicoXp);
  }
}
function PerfilGamificadoComponent_Conditional_7_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 7)(1, "div", 8);
    \u0275\u0275text(2);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "div", 9)(4, "div", 10);
    \u0275\u0275text(5);
    \u0275\u0275elementEnd();
    \u0275\u0275element(6, "app-nivel-badge", 11);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(7, "div", 12)(8, "div", 13);
    \u0275\u0275text(9, "Progresso de XP");
    \u0275\u0275elementEnd();
    \u0275\u0275element(10, "app-xp-progress", 14);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(11, "div", 15)(12, "div", 16)(13, "div", 17);
    \u0275\u0275text(14);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(15, "div", 18);
    \u0275\u0275text(16, "XP Total");
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(17, "div", 16)(18, "div", 17);
    \u0275\u0275text(19);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(20, "div", 18);
    \u0275\u0275text(21, "XP este m\xEAs");
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(22, "div", 16)(23, "div", 17);
    \u0275\u0275text(24);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(25, "div", 18);
    \u0275\u0275text(26, "Posi\xE7\xE3o Global");
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(27, "div", 16)(28, "div", 17);
    \u0275\u0275text(29);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(30, "div", 18);
    \u0275\u0275text(31, "Posi\xE7\xE3o na Turma");
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(32, "div", 16)(33, "div", 17);
    \u0275\u0275text(34);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(35, "div", 18);
    \u0275\u0275text(36, "Sequ\xEAncia atual");
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(37, "div", 12)(38, "div", 13);
    \u0275\u0275text(39);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(40, "div", 19);
    \u0275\u0275repeaterCreate(41, PerfilGamificadoComponent_Conditional_7_For_42_Template, 5, 3, "div", 20, _forTrack0);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(43, "div", 21)(44, "div", 13);
    \u0275\u0275text(45, "\xDAltimos eventos de XP");
    \u0275\u0275elementEnd();
    \u0275\u0275template(46, PerfilGamificadoComponent_Conditional_7_Conditional_46_Template, 2, 0, "div", 22)(47, PerfilGamificadoComponent_Conditional_7_Conditional_47_Template, 3, 0);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance();
    \u0275\u0275styleProp("border-color", ctx_r0.nivelCor(ctx_r0.perfil().nivel));
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(ctx_r0.avatarInicial(ctx_r0.perfil().nome));
    \u0275\u0275advance(3);
    \u0275\u0275textInterpolate(ctx_r0.perfil().nome);
    \u0275\u0275advance();
    \u0275\u0275property("nivel", ctx_r0.perfil().nivel);
    \u0275\u0275advance(4);
    \u0275\u0275property("xpAtual", ctx_r0.perfil().xpTotal)("xpParaProximoNivel", ctx_r0.perfil().xpParaProximoNivel)("nivel", ctx_r0.perfil().nivel);
    \u0275\u0275advance(4);
    \u0275\u0275textInterpolate(ctx_r0.perfil().xpTotal);
    \u0275\u0275advance(5);
    \u0275\u0275textInterpolate(ctx_r0.perfil().xpMensal);
    \u0275\u0275advance(5);
    \u0275\u0275textInterpolate1("#", ctx_r0.perfil().posicaoGlobal, "");
    \u0275\u0275advance(5);
    \u0275\u0275textInterpolate1("#", ctx_r0.perfil().posicaoTurma || "\u2013", "");
    \u0275\u0275advance(5);
    \u0275\u0275textInterpolate1("\u{1F525} ", ctx_r0.perfil().sequenciaAtual, "");
    \u0275\u0275advance(5);
    \u0275\u0275textInterpolate1(" Conquistas (", ctx_r0.perfil().conquistasDesbloqueadas.length, ") ");
    \u0275\u0275advance(2);
    \u0275\u0275repeater(ctx_r0.perfil().conquistasDesbloqueadas);
    \u0275\u0275advance(5);
    \u0275\u0275conditional(46, !ctx_r0.perfil().historicoXp.length ? 46 : 47);
  }
}
function PerfilGamificadoComponent_Conditional_8_Conditional_8_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 37);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const c_r6 = \u0275\u0275nextContext();
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1("+", c_r6.pontosXpBonus, " XP b\xF4nus");
  }
}
function PerfilGamificadoComponent_Conditional_8_Conditional_9_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 31);
    \u0275\u0275text(1);
    \u0275\u0275pipe(2, "date");
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const c_r6 = \u0275\u0275nextContext();
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1("Desbloqueada em ", \u0275\u0275pipeBind2(2, 1, c_r6.desbloqueadaEm, "dd/MM/yyyy"), "");
  }
}
function PerfilGamificadoComponent_Conditional_8_Template(rf, ctx) {
  if (rf & 1) {
    const _r5 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 32);
    \u0275\u0275listener("click", function PerfilGamificadoComponent_Conditional_8_Template_div_click_0_listener() {
      \u0275\u0275restoreView(_r5);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.fecharModal());
    });
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(1, "div", 33)(2, "div", 34);
    \u0275\u0275text(3);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(4, "h3", 35);
    \u0275\u0275text(5);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(6, "p", 36);
    \u0275\u0275text(7);
    \u0275\u0275elementEnd();
    \u0275\u0275template(8, PerfilGamificadoComponent_Conditional_8_Conditional_8_Template, 2, 1, "div", 37)(9, PerfilGamificadoComponent_Conditional_8_Conditional_9_Template, 3, 4, "div", 31);
    \u0275\u0275elementStart(10, "div", 38)(11, "button", 39);
    \u0275\u0275listener("click", function PerfilGamificadoComponent_Conditional_8_Template_button_click_11_listener() {
      \u0275\u0275restoreView(_r5);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.fecharModal());
    });
    \u0275\u0275text(12, "Fechar");
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    const c_r6 = ctx;
    \u0275\u0275advance(3);
    \u0275\u0275textInterpolate(c_r6.iconeUrl);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(c_r6.nome);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(c_r6.descricao);
    \u0275\u0275advance();
    \u0275\u0275conditional(8, c_r6.pontosXpBonus > 0 ? 8 : -1);
    \u0275\u0275advance();
    \u0275\u0275conditional(9, c_r6.desbloqueadaEm ? 9 : -1);
  }
}
function PerfilGamificadoComponent_Conditional_9_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 4)(1, "span", 40);
    \u0275\u0275text(2);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "div")(4, "div", 41);
    \u0275\u0275text(5, "Nova conquista desbloqueada!");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(6, "div", 42);
    \u0275\u0275text(7);
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    const nova_r7 = ctx;
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(nova_r7.iconeUrl);
    \u0275\u0275advance(5);
    \u0275\u0275textInterpolate(nova_r7.nome);
  }
}
var PerfilGamificadoComponent = class _PerfilGamificadoComponent {
  constructor(route, rankingService) {
    this.route = route;
    this.rankingService = rankingService;
    this.perfil = signal(null);
    this.carregando = signal(true);
    this.erro = signal("");
    this.conquistaSelecionada = signal(null);
    this.animacaoNovaConquista = signal(null);
  }
  ngOnInit() {
    const alunoId = this.route.snapshot.paramMap.get("alunoId") ?? "";
    this.rankingService.getPerfilGamificado(alunoId).subscribe({
      next: (p) => {
        this.perfil.set(p);
        this.carregando.set(false);
        this.verificarNovasConquistas(p.conquistasDesbloqueadas);
      },
      error: () => {
        this.erro.set("Erro ao carregar perfil.");
        this.carregando.set(false);
      }
    });
  }
  verificarNovasConquistas(conquistas) {
    const hoje = (/* @__PURE__ */ new Date()).toISOString().slice(0, 10);
    const nova = conquistas.filter((c) => c.desbloqueadaEm?.startsWith(hoje)).sort((a, b) => (b.desbloqueadaEm ?? "").localeCompare(a.desbloqueadaEm ?? ""))[0];
    if (!nova)
      return;
    this.animacaoNovaConquista.set(nova);
    setTimeout(() => this.animacaoNovaConquista.set(null), 3500);
  }
  nivelCor(nivel) {
    return NIVEL_CONFIG[nivel]?.cor ?? "#6366f1";
  }
  avatarInicial(nome) {
    return (nome ?? "U").charAt(0).toUpperCase();
  }
  tipoIcone(tipo) {
    const map = {
      Presenca: "\u2705",
      SequenciaPresenca: "\u{1F525}",
      Graduacao: "\u{1F396}\uFE0F",
      PrimeiroCheckinMes: "\u2B50",
      ConquistaDesbloqueada: "\u{1F3C5}"
    };
    return map[tipo] ?? "\u26A1";
  }
  fecharModal() {
    this.conquistaSelecionada.set(null);
  }
  static {
    this.\u0275fac = function PerfilGamificadoComponent_Factory(t) {
      return new (t || _PerfilGamificadoComponent)(\u0275\u0275directiveInject(ActivatedRoute), \u0275\u0275directiveInject(RankingService));
    };
  }
  static {
    this.\u0275cmp = /* @__PURE__ */ \u0275\u0275defineComponent({ type: _PerfilGamificadoComponent, selectors: [["app-perfil-gamificado"]], standalone: true, features: [\u0275\u0275StandaloneFeature], decls: 10, vars: 3, consts: [[1, "page-container"], [1, "breadcrumb"], ["routerLink", "/app/ranking", 1, "breadcrumb-link"], [1, "skeleton-list"], [1, "conquista-toast"], [1, "skeleton-row", 2, "height", "80px"], [1, "alert-error"], [1, "card", 2, "display", "flex", "align-items", "center", "gap", "20px", "margin-bottom", "16px"], [1, "presenca-avatar", 2, "width", "64px", "height", "64px", "font-size", "1.5rem", "font-weight", "700", "border", "3px solid"], [2, "flex", "1"], [2, "font-size", "1.25rem", "font-weight", "700", "color", "var(--app-text-1)"], [3, "nivel"], [1, "card", 2, "margin-bottom", "16px"], [2, "font-size", "0.875rem", "font-weight", "600", "color", "var(--app-text-2)", "margin-bottom", "12px"], [3, "xpAtual", "xpParaProximoNivel", "nivel"], [1, "stats-row", 2, "margin-bottom", "16px"], [1, "stat-card"], [1, "stat-value"], [1, "stat-label"], [1, "conquistas-grid"], [1, "conquista-item", 3, "title"], [1, "card"], [1, "empty-state", 2, "padding", "24px"], [1, "conquista-item", 3, "click", "title"], [1, "conquista-icone"], [1, "conquista-nome"], [2, "display", "flex", "flex-direction", "column", "gap", "8px"], [2, "display", "flex", "align-items", "center", "gap", "12px", "padding", "10px", "border-radius", "8px", "background", "var(--app-border-light)"], [2, "font-size", "1.2rem"], [2, "flex", "1", "font-size", "0.875rem", "color", "var(--app-text-2)"], [2, "color", "#22c55e"], [2, "font-size", "0.75rem", "color", "var(--app-text-3)"], [1, "modal-backdrop", 3, "click"], [1, "modal", 2, "max-width", "360px", "text-align", "center"], [2, "font-size", "2.5rem", "margin-bottom", "8px"], [2, "font-size", "1.125rem", "font-weight", "700", "margin", "0 0 8px"], [2, "font-size", "0.875rem", "color", "var(--app-text-2)", "margin", "0 0 12px"], [1, "badge-tag", 2, "margin", "0 auto 16px", "width", "fit-content"], [1, "modal-actions", 2, "justify-content", "center", "margin-top", "16px"], [1, "btn-primary", 3, "click"], [1, "conquista-toast-icone"], [1, "conquista-toast-titulo"], [1, "conquista-toast-nome"]], template: function PerfilGamificadoComponent_Template(rf, ctx) {
      if (rf & 1) {
        \u0275\u0275elementStart(0, "div", 0)(1, "div", 1)(2, "a", 2);
        \u0275\u0275text(3, "Ranking");
        \u0275\u0275elementEnd();
        \u0275\u0275text(4, " / Perfil Gamificado ");
        \u0275\u0275elementEnd();
        \u0275\u0275template(5, PerfilGamificadoComponent_Conditional_5_Template, 3, 1, "div", 3)(6, PerfilGamificadoComponent_Conditional_6_Template, 2, 1)(7, PerfilGamificadoComponent_Conditional_7_Template, 48, 15);
        \u0275\u0275elementEnd();
        \u0275\u0275template(8, PerfilGamificadoComponent_Conditional_8_Template, 13, 5)(9, PerfilGamificadoComponent_Conditional_9_Template, 8, 2, "div", 4);
      }
      if (rf & 2) {
        let tmp_1_0;
        let tmp_2_0;
        \u0275\u0275advance(5);
        \u0275\u0275conditional(5, ctx.carregando() ? 5 : ctx.erro() ? 6 : ctx.perfil() ? 7 : -1);
        \u0275\u0275advance(3);
        \u0275\u0275conditional(8, (tmp_1_0 = ctx.conquistaSelecionada()) ? 8 : -1, tmp_1_0);
        \u0275\u0275advance();
        \u0275\u0275conditional(9, (tmp_2_0 = ctx.animacaoNovaConquista()) ? 9 : -1, tmp_2_0);
      }
    }, dependencies: [CommonModule, DatePipe, RouterLink, NivelBadgeComponent, XpProgressComponent], styles: [".conquistas-grid[_ngcontent-%COMP%] { display: grid; grid-template-columns: repeat(auto-fill, minmax(80px,1fr)); gap: 12px; }\n  .conquista-item[_ngcontent-%COMP%] { display: flex; flex-direction: column; align-items: center; gap: 6px; padding: 12px 8px; border-radius: 8px; background: var(--app-border-light); cursor: pointer; transition: background 0.15s; }\n  .conquista-item[_ngcontent-%COMP%]:hover { background: var(--app-border); }\n  .conquista-icone[_ngcontent-%COMP%] { font-size: 1.5rem; }\n  .conquista-nome[_ngcontent-%COMP%] { font-size: 0.65rem; color: var(--app-text-2); text-align: center; line-height: 1.2; }\n\n  .conquista-toast[_ngcontent-%COMP%] {\n    position: fixed; bottom: 24px; left: 50%; transform: translateX(-50%);\n    display: flex; align-items: center; gap: 12px;\n    background: #1e293b; border: 1px solid #f59e0b66;\n    border-radius: 12px; padding: 14px 20px;\n    box-shadow: 0 8px 24px rgba(0,0,0,0.4);\n    z-index: 1000;\n    animation: _ngcontent-%COMP%_toastIn 0.35s cubic-bezier(.21,1.02,.73,1) forwards,\n               _ngcontent-%COMP%_toastOut 0.4s ease 3.1s forwards;\n  }\n  .conquista-toast-icone[_ngcontent-%COMP%] { font-size: 2rem; }\n  .conquista-toast-titulo[_ngcontent-%COMP%] { font-size: 0.7rem; text-transform: uppercase; letter-spacing: .05em; color: #f59e0b; font-weight: 700; }\n  .conquista-toast-nome[_ngcontent-%COMP%] { font-size: 0.95rem; font-weight: 600; color: #f1f5f9; margin-top: 2px; }\n\n  @keyframes _ngcontent-%COMP%_toastIn {\n    from { opacity: 0; transform: translateX(-50%) translateY(20px); }\n    to   { opacity: 1; transform: translateX(-50%) translateY(0); }\n  }\n  @keyframes _ngcontent-%COMP%_toastOut {\n    from { opacity: 1; }\n    to   { opacity: 0; transform: translateX(-50%) translateY(16px); }\n  }"] });
  }
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && \u0275setClassDebugInfo(PerfilGamificadoComponent, { className: "PerfilGamificadoComponent" });
})();
export {
  PerfilGamificadoComponent
};
//# sourceMappingURL=chunk-2ONFKNNO.js.map
