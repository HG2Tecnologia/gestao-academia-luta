import {
  RouterLink
} from "./chunk-AXNOULNC.js";
import {
  DecimalPipe,
  ElementRef,
  computed,
  inject,
  signal,
  ɵsetClassDebugInfo,
  ɵɵStandaloneFeature,
  ɵɵadvance,
  ɵɵclassProp,
  ɵɵdefineComponent,
  ɵɵelement,
  ɵɵelementEnd,
  ɵɵelementStart,
  ɵɵgetCurrentView,
  ɵɵlistener,
  ɵɵnamespaceHTML,
  ɵɵnamespaceSVG,
  ɵɵnextContext,
  ɵɵpipe,
  ɵɵpipeBind2,
  ɵɵproperty,
  ɵɵrepeater,
  ɵɵrepeaterCreate,
  ɵɵrepeaterTrackByIdentity,
  ɵɵrepeaterTrackByIndex,
  ɵɵresetView,
  ɵɵrestoreView,
  ɵɵstyleProp,
  ɵɵtext,
  ɵɵtextInterpolate,
  ɵɵtextInterpolate1
} from "./chunk-WZ2AWGAJ.js";
import {
  __spreadProps,
  __spreadValues
} from "./chunk-7G5TR5RR.js";

// src/app/features/landing/landing.component.ts
var _forTrack0 = ($index, $item) => $item.label;
var _forTrack1 = ($index, $item) => $item.num;
var _forTrack2 = ($index, $item) => $item.name;
function LandingComponent_For_113_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 56)(1, "div", 59);
    \u0275\u0275text(2);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "div", 120);
    \u0275\u0275text(4);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(5, "div", 177);
    \u0275\u0275text(6);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const stat_r1 = ctx.$implicit;
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(stat_r1.label);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(stat_r1.val);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate1("", stat_r1.delta, " vs. anterior");
  }
}
function LandingComponent_For_122_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275element(0, "div", 178);
  }
  if (rf & 2) {
    const bar_r2 = ctx.$implicit;
    \u0275\u0275styleProp("height", bar_r2, "%");
  }
}
function LandingComponent_For_150_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 70);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const item_r3 = ctx.$implicit;
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(item_r3);
  }
}
function LandingComponent_For_169_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 79)(1, "span", 179);
    \u0275\u0275text(2);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "div", 180);
    \u0275\u0275text(4);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(5, "div", 181);
    \u0275\u0275text(6);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(7, "div", 182);
    \u0275\u0275text(8);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const p_r4 = ctx.$implicit;
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(p_r4.num);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(p_r4.title);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(p_r4.body);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(p_r4.strike);
  }
}
function LandingComponent_For_187_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 84)(1, "div", 183);
    \u0275\u0275text(2);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "div", 184);
    \u0275\u0275text(4, "\u2192");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(5, "div", 185);
    \u0275\u0275text(6);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const row_r5 = ctx.$implicit;
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(row_r5[0]);
    \u0275\u0275advance(4);
    \u0275\u0275textInterpolate(row_r5[1]);
  }
}
function LandingComponent_For_233_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 186)(1, "span", 187);
    \u0275\u0275text(2);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "span")(4, "div", 188);
    \u0275\u0275text(5);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(6, "div", 189);
    \u0275\u0275text(7);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(8, "span", 190);
    \u0275\u0275text(9);
    \u0275\u0275pipe(10, "number");
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const row_r6 = ctx.$implicit;
    const i_r7 = ctx.$index;
    \u0275\u0275classProp("gold", i_r7 === 0)("silver", i_r7 === 1)("bronze", i_r7 === 2);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(i_r7 + 1);
    \u0275\u0275advance(3);
    \u0275\u0275textInterpolate(row_r6.name);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate1("Faixa ", row_r6.faixa, "");
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate1("", \u0275\u0275pipeBind2(10, 10, row_r6.pts, "1.0-0"), " pts");
  }
}
function LandingComponent_For_272_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 108)(1, "div", 191);
    \u0275\u0275text(2);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "div", 192);
    \u0275\u0275text(4);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(5, "div", 193);
    \u0275\u0275text(6);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const d_r8 = ctx.$implicit;
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate1("/ ", d_r8.num, "");
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(d_r8.title);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(d_r8.body);
  }
}
function LandingComponent_For_288_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 113)(1, "span", 194);
    \u0275\u0275text(2);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "div", 195);
    \u0275\u0275text(4);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(5, "div", 196);
    \u0275\u0275text(6);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const p_r9 = ctx.$implicit;
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(p_r9.num);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(p_r9.title);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(p_r9.body);
  }
}
function LandingComponent_For_302_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 115)(1, "div", 197);
    \u0275\u0275text(2);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "div", 198);
    \u0275\u0275text(4);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const b_r10 = ctx.$implicit;
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(b_r10.num);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(b_r10.label);
  }
}
function LandingComponent_For_375_Template(rf, ctx) {
  if (rf & 1) {
    const _r11 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "button", 199);
    \u0275\u0275listener("click", function LandingComponent_For_375_Template_button_click_0_listener() {
      const i_r12 = \u0275\u0275restoreView(_r11).$index;
      const ctx_r12 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r12.testimonialIdx.set(i_r12));
    });
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const i_r12 = ctx.$index;
    const ctx_r12 = \u0275\u0275nextContext();
    \u0275\u0275classProp("active", i_r12 === ctx_r12.testimonialIdx());
  }
}
function LandingComponent_For_421_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "li")(1, "span", 200);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(2, "svg", 145);
    \u0275\u0275element(3, "path", 201);
    \u0275\u0275elementEnd()();
    \u0275\u0275text(4);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const f_r14 = ctx.$implicit;
    \u0275\u0275advance(4);
    \u0275\u0275textInterpolate1(" ", f_r14, " ");
  }
}
var LandingComponent = class _LandingComponent {
  constructor() {
    this.el = inject(ElementRef);
    this.intervals = [];
    this.observer = null;
    this.tick = signal(0);
    this.testimonialIdx = signal(0);
    this.pricingAnual = signal(false);
    this.menuAberto = signal(false);
    this.roiStudents = signal(120);
    this.roiFee = signal(220);
    this.roiDefaultRate = signal(14);
    this.rankingRows = signal([
      { name: "Bruno Yamamoto", pts: 1284, faixa: "Roxa" },
      { name: "Let\xEDcia Andrade", pts: 1247, faixa: "Azul" },
      { name: "Diego Ferreira", pts: 1198, faixa: "Roxa" },
      { name: "Rafael Costa", pts: 1142, faixa: "Azul" },
      { name: "Mariana Silva", pts: 1098, faixa: "Branca" }
    ]);
    this.bars = computed(() => {
      const seed = this.tick();
      const base = [55, 62, 48, 70, 65, 78, 82, 75, 88, 92, 84, 95];
      return base.map((b, i) => Math.max(20, Math.min(100, b + Math.sin((seed + i) * 0.7) * 6)));
    });
    this.dashStats = computed(() => [
      { label: "Alunos ativos", val: String(247 + this.tick() % 4), delta: "+12%" },
      { label: "Receita do m\xEAs", val: "R$ 38.4k", delta: "+18%" },
      { label: "Inadimpl\xEAncia", val: "3.2%", delta: "\u221241%" }
    ]);
    this.pricingPreco = computed(() => this.pricingAnual() ? 119 : 149);
    this.pricingWas = computed(() => this.pricingAnual() ? 149 : 199);
    this.roiResult = computed(() => {
      const students = this.roiStudents();
      const fee = this.roiFee();
      const rate = this.roiDefaultRate();
      const monthlyRevenue = students * fee;
      const lostNow = monthlyRevenue * (rate / 100);
      const recovered = lostNow * 0.7;
      const newStudents = Math.round(students * 0.12);
      const growth = newStudents * fee;
      return { recovered, growth, total: recovered + growth, newStudents };
    });
    this.testimonialAtivo = computed(() => this.depoimentos[this.testimonialIdx()]);
    this.depoimentos = [
      {
        quote: "Cortei a inadimpl\xEAncia de 14% pra menos de 4% em dois meses. O sistema cobra sozinho, eu s\xF3 dou aula.",
        name: "Marcelo Tanaka",
        role: "Faixa Preta \xB7 Academia Tatame Norte, S\xE3o Paulo",
        avatar: "MT"
      },
      {
        quote: "O ranking gamificado virou febre. Os alunos competem pra n\xE3o faltar. Frequ\xEAncia subiu 38% no primeiro m\xEAs.",
        name: "Ana Beatriz Lopes",
        role: "Coach \xB7 Iron Fist Boxe, Belo Horizonte",
        avatar: "AB"
      },
      {
        quote: "Eu gerenciava 80 alunos numa planilha. Hoje tenho 240 e sobra tempo. Foi a melhor decis\xE3o que tomei pro neg\xF3cio.",
        name: "Rodrigo Vieira",
        role: "Dono \xB7 Vieira Muay Thai, Curitiba",
        avatar: "RV"
      },
      {
        quote: "Em 6 meses dobrei a base de alunos sem contratar ningu\xE9m. O Tatame faz o trabalho de uma secret\xE1ria por R$ 149.",
        name: "Camila Reis",
        role: "S\xF3cia \xB7 Reis Jiu-Jitsu, Recife",
        avatar: "CR"
      }
    ];
    this.problemas = [
      {
        num: "01",
        title: "Inadimpl\xEAncia fora de controle",
        body: "Voc\xEA n\xE3o sabe quem pagou, quem deve, e gasta a semana cobrando no WhatsApp.",
        strike: "14% de inadimpl\xEAncia m\xE9dia"
      },
      {
        num: "02",
        title: "Aluno some e ningu\xE9m percebe",
        body: "Frequ\xEAncia cai por 3 semanas, ningu\xE9m liga, ele cancela. Churn invis\xEDvel.",
        strike: "1 em cada 4 alunos some por ano"
      },
      {
        num: "03",
        title: "Planilha que ningu\xE9m entende",
        body: "Cada professor anota num caderno, num celular, num papel. Voc\xEA reza pra dar certo.",
        strike: "Horas perdidas toda segunda"
      },
      {
        num: "04",
        title: "Sem vis\xE3o financeira nenhuma",
        body: "Quanto entrou esse m\xEAs? Quanto vai entrar? Qual aluno d\xE1 lucro? Ningu\xE9m sabe.",
        strike: "Decis\xF5es no escuro"
      }
    ];
    this.transforms = [
      ["Planilha de Excel quebrando", "Dashboard ao vivo no celular"],
      ["Cobrar aluno por WhatsApp", "Pix autom\xE1tico + lembrete"],
      ["Aluno some sem voc\xEA ver", "Alerta de churn em 7 dias"],
      ["Decidir no ach\xF4metro", "Relat\xF3rios em tempo real"],
      ["Aluno desmotivado", "Ranking gamificado por faixa"]
    ];
    this.diferenciais = [
      {
        num: "01",
        title: "Automa\xE7\xE3o que cobra sozinha",
        body: "Pix, cart\xE3o, lembrete por WhatsApp, segunda via, comprovante. O fluxo financeiro inteiro roda sozinho. Voc\xEA revisa em 5 minutos por semana."
      },
      {
        num: "02",
        title: "Intelig\xEAncia que prev\xEA o churn",
        body: "Quando um aluno falta 3 semanas, o sistema te avisa antes dele cancelar. Voc\xEA liga, ele volta. Reten\xE7\xE3o sobe sem esfor\xE7o."
      },
      {
        num: "03",
        title: "Engajamento que vicia",
        body: "Ranking, badges, conquistas por faixa, desafios mensais. Os pr\xF3prios alunos puxam quem falta. A turma se autorregula."
      },
      {
        num: "04",
        title: "Feito por quem treina",
        body: "Time fundador \xE9 faixa preta. Cada feature foi pensada num tatame, n\xE3o numa reuni\xE3o. Voc\xEA sente isso em cada tela."
      }
    ];
    this.passos = [
      {
        num: "Passo 01",
        title: "Crie sua conta gr\xE1tis",
        body: "Em 60 segundos. N\xE3o pedimos cart\xE3o. S\xF3 email e o nome da academia."
      },
      {
        num: "Passo 02",
        title: "Importe seus alunos",
        body: "Mande sua planilha. Importamos pra voc\xEA sem custo. Em 4 horas t\xE1 tudo l\xE1."
      },
      {
        num: "Passo 03",
        title: "Configure cobran\xE7a",
        body: "Conecta sua conta Pix ou banco. Define dia de vencimento. Pronto, automatizou."
      },
      {
        num: "Passo 04",
        title: "Convide seus alunos",
        body: "Manda o link, eles baixam o app, veem o ranking e nunca mais te ligam pedindo recibo."
      }
    ];
    this.beneficios = [
      { num: "+38%", label: "Frequ\xEAncia m\xE9dia de alunos no tatame" },
      { num: "\u221272%", label: "Inadimpl\xEAncia depois do 2\xBA m\xEAs" },
      { num: "+27%", label: "Crescimento de base de alunos em 6 meses" },
      { num: "12h", label: "Economizadas por semana em tarefas operacionais" }
    ];
    this.disciplinas = [
      "JIU-JITSU",
      "MUAY THAI",
      "BOXE",
      "MMA",
      "KARAT\xCA",
      "TAEKWONDO",
      "WRESTLING",
      "KICKBOXING",
      "JUD\xD4",
      "CAPOEIRA"
    ];
    this.disciplinasMarquee = [...this.disciplinas, ...this.disciplinas];
    this.priceFeatures = [
      "Alunos ilimitados",
      "Cobran\xE7a autom\xE1tica (Pix + cart\xE3o)",
      "Ranking gamificado",
      "Controle de presen\xE7a por QR",
      "Dashboard financeiro completo",
      "App para alunos (iOS + Android)",
      "WhatsApp autom\xE1tico",
      "M\xFAltiplas unidades",
      "Relat\xF3rios personalizados",
      "Suporte humano em at\xE9 2h",
      "Importa\xE7\xE3o gr\xE1tis de planilhas",
      "30 dias gr\xE1tis. Cancele quando quiser"
    ];
  }
  ngOnInit() {
    document.body.style.setProperty("background", "#0a0a0a");
    document.body.style.setProperty("color", "#fafaf7");
  }
  ngAfterViewInit() {
    this.intervals.push(setInterval(() => this.tick.update((t) => t + 1), 1800), setInterval(() => {
      this.rankingRows.update((rows) => {
        const next = rows.map((r) => __spreadProps(__spreadValues({}, r), { pts: r.pts + Math.floor(Math.random() * 8) }));
        next.sort((a, b) => b.pts - a.pts);
        return [...next];
      });
    }, 1600), setInterval(() => {
      this.testimonialIdx.update((i) => (i + 1) % this.depoimentos.length);
    }, 7e3));
    this.observer = new IntersectionObserver((entries) => entries.forEach((e) => {
      if (e.isIntersecting) {
        e.target.classList.add("in");
        this.observer.unobserve(e.target);
      }
    }), { threshold: 0.1 });
    this.el.nativeElement.querySelectorAll("[data-reveal]").forEach((el) => {
      this.observer.observe(el);
    });
  }
  ngOnDestroy() {
    this.intervals.forEach(clearInterval);
    this.observer?.disconnect();
    document.body.style.removeProperty("background");
    document.body.style.removeProperty("color");
  }
  fmtBrl(n) {
    return "R$ " + Math.round(n).toLocaleString("pt-BR");
  }
  setRoiStudents(e) {
    this.roiStudents.set(+e.target.value);
  }
  setRoiFee(e) {
    this.roiFee.set(+e.target.value);
  }
  setRoiDefault(e) {
    this.roiDefaultRate.set(+e.target.value);
  }
  prevTestimonial() {
    this.testimonialIdx.update((i) => (i - 1 + this.depoimentos.length) % this.depoimentos.length);
  }
  nextTestimonial() {
    this.testimonialIdx.update((i) => (i + 1) % this.depoimentos.length);
  }
  static {
    this.\u0275fac = function LandingComponent_Factory(t) {
      return new (t || _LandingComponent)();
    };
  }
  static {
    this.\u0275cmp = /* @__PURE__ */ \u0275\u0275defineComponent({ type: _LandingComponent, selectors: [["app-landing"]], standalone: true, features: [\u0275\u0275StandaloneFeature], decls: 463, vars: 21, consts: [[1, "lp"], [1, "nav"], [1, "nav-inner"], ["routerLink", "/", 1, "brand"], [1, "brand-mark"], [1, "nav-links"], ["href", "#problema"], ["href", "#recursos"], ["href", "#como-funciona"], ["href", "#precos"], ["href", "#depoimentos"], [1, "nav-actions"], ["routerLink", "/login", 1, "btn", "btn-ghost", 2, "padding", "10px 16px", "font-size", "14px"], ["routerLink", "/cadastro", 1, "btn", "btn-primary", 2, "padding", "10px 18px", "font-size", "14px"], [1, "hero", "container"], [1, "hero-grid"], [1, "badge"], [1, "dot"], [1, "hero-headline", "h-display"], [1, "hero-sub", "lead"], [1, "hero-cta"], ["routerLink", "/cadastro", 1, "btn", "btn-primary", "btn-lg"], ["href", "#dash", 1, "btn", "btn-ghost", "btn-lg"], [1, "hero-trust"], [1, "avatar-stack"], [1, "avatar"], [1, "avatar", 2, "background", "var(--accent)", "color", "#0a0a0a"], [1, "stars"], [2, "color", "var(--fg-2)"], ["id", "dash", "data-reveal", ""], [1, "dash"], [1, "dash-chrome"], [1, "dash-dots"], [1, "dash-url"], [2, "width", "56px"], [1, "dash-body"], [1, "dash-sidebar"], [1, "dash-side-brand"], [1, "brand-mark", 2, "width", "18px", "height", "18px", "font-size", "11px"], [1, "dash-side-section"], [1, "dash-side-item", "active"], ["width", "13", "height", "13", "viewBox", "0 0 24 24", "fill", "none"], ["d", "M3 12l9-9 9 9M5 10v10h14V10", "stroke", "currentColor", "stroke-width", "1.5", "stroke-linecap", "round"], [1, "dash-side-item"], ["d", "M16 7a4 4 0 1 1-8 0 4 4 0 0 1 8 0zM3 21v-1a7 7 0 0 1 14 0v1", "stroke", "currentColor", "stroke-width", "1.5", "stroke-linecap", "round"], ["x", "3", "y", "5", "width", "18", "height", "16", "rx", "2", "stroke", "currentColor", "stroke-width", "1.5"], ["d", "M3 10h18M8 3v4M16 3v4", "stroke", "currentColor", "stroke-width", "1.5", "stroke-linecap", "round"], ["x", "2", "y", "6", "width", "20", "height", "12", "rx", "2", "stroke", "currentColor", "stroke-width", "1.5"], ["cx", "12", "cy", "12", "r", "3", "stroke", "currentColor", "stroke-width", "1.5"], ["d", "M8 21h8M12 17v4M7 4h10v6a5 5 0 0 1-10 0V4zM7 4H4v3a3 3 0 0 0 3 3M17 4h3v3a3 3 0 0 1-3 3", "stroke", "currentColor", "stroke-width", "1.5", "stroke-linecap", "round"], [1, "dash-main"], [1, "dash-h"], [2, "font-family", "var(--mono)", "font-size", "9px", "color", "var(--fg-3)", "letter-spacing", "0.08em", "text-transform", "uppercase"], [1, "dash-title"], [1, "badge", 2, "padding", "4px 10px", "font-size", "9px"], [1, "dash-stats"], [1, "dash-stat"], [1, "dash-chart"], [1, "chart-h"], [1, "label"], [1, "chart-bars"], [1, "chart-bar", 3, "height"], [1, "dash-list"], [1, "dash-list-h"], [1, "dash-list-row"], [2, "color", "var(--fg-3)", "font-family", "var(--mono)", "font-size", "11px"], [1, "pill", "paid"], [1, "pill", "due"], [1, "marquee"], [1, "marquee-track"], [1, "marquee-item"], ["id", "problema", 1, "section"], [1, "container"], [1, "section-num"], [1, "two-col-head"], ["data-reveal", "", 1, "h-1"], [2, "font-style", "normal", "color", "var(--accent)"], ["data-reveal", "", 1, "lead"], ["data-reveal", "", 1, "problem-grid"], [1, "problem-card"], [1, "section"], [1, "solution-split"], ["data-reveal", "", 1, "lead", 2, "margin-top", "28px"], ["data-reveal", "", 1, "transform-list"], [1, "transform-row"], ["data-reveal", ""], [1, "img-ph"], [2, "align-self", "flex-end"], ["id", "recursos", 1, "section"], ["data-reveal", "", 1, "features-grid"], [1, "feature-card", "span-3", "tall"], [1, "feat-icon"], ["width", "18", "height", "18", "viewBox", "0 0 24 24", "fill", "none"], ["d", "M16 7a4 4 0 1 1-8 0 4 4 0 0 1 8 0zM3 21v-1a7 7 0 0 1 14 0v1M21 21v-1a5 5 0 0 0-3-4.58", "stroke", "currentColor", "stroke-width", "1.5", "stroke-linecap", "round"], [1, "feat-title"], [1, "feat-body"], [2, "background", "var(--bg-3)", "border", "1px solid var(--line)", "border-radius", "8px", "padding", "20px", "flex", "1", "display", "flex", "align-items", "center", "justify-content", "center", "font-family", "var(--mono)", "font-size", "11px", "color", "var(--fg-3)", "letter-spacing", "0.08em", "text-transform", "uppercase"], [1, "ranking"], [1, "ranking-head"], [1, "eyebrow"], [1, "badge", 2, "padding", "3px 8px", "font-size", "9px"], [1, "ranking-row", 3, "gold", "silver", "bronze"], [1, "feature-card", "span-2"], ["d", "M9 12l2 2 4-4M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0z", "stroke", "currentColor", "stroke-width", "1.5", "stroke-linecap", "round"], ["d", "M3 3v18h18M7 14l4-4 4 4 5-7", "stroke", "currentColor", "stroke-width", "1.5", "stroke-linecap", "round"], [1, "section", 2, "background", "var(--bg-2)"], ["data-reveal", "", 1, "h-1", 2, "max-width", "16ch"], ["data-reveal", "", 1, "diff-grid"], [1, "diff-row"], ["id", "como-funciona", 1, "section"], ["data-reveal", "", 1, "h-1", 2, "max-width", "18ch"], ["data-reveal", "", 1, "lead", 2, "margin-top", "24px"], ["data-reveal", "", 1, "steps"], [1, "step"], ["data-reveal", "", 1, "benefit-stats"], [1, "benefit-stat"], ["data-reveal", "", 1, "roi-card"], [1, "eyebrow", 2, "margin-bottom", "12px"], [1, "h-2", 2, "margin-bottom", "28px", "font-size", "clamp(24px, 3vw, 40px)"], [1, "input-row"], [1, "val"], ["type", "range", "min", "20", "max", "500", "step", "5", 1, "slider", 3, "input", "value"], ["type", "range", "min", "80", "max", "500", "step", "10", 1, "slider", 3, "input", "value"], ["type", "range", "min", "2", "max", "35", "step", "1", 1, "slider", 3, "input", "value"], [1, "roi-result"], [1, "roi-label"], [1, "roi-big"], [2, "border-top", "1px solid var(--line)", "margin-top", "20px", "padding-top", "4px"], [1, "roi-line"], [1, "roi-line", 2, "border-top", "1px solid var(--line)", "color", "var(--accent)"], [2, "font-family", "var(--mono)"], ["id", "depoimentos", 1, "section", 2, "background", "var(--bg-2)"], ["data-reveal", "", 1, "h-1", 2, "max-width", "20ch"], [1, "test-wrap"], ["data-reveal", "", 1, "test-card"], [1, "test-quote"], [1, "test-meta"], [1, "test-avatar"], [1, "tname"], [1, "trole"], [1, "test-nav"], [1, "test-dots"], [1, "test-dot", 3, "active"], [1, "test-arrows"], [1, "test-arrow", 3, "click"], ["width", "14", "height", "14", "viewBox", "0 0 16 16", "fill", "none"], ["d", "M10 3L5 8l5 5", "stroke", "currentColor", "stroke-width", "1.5", "stroke-linecap", "round", "stroke-linejoin", "round"], ["d", "M6 3l5 5-5 5", "stroke", "currentColor", "stroke-width", "1.5", "stroke-linecap", "round", "stroke-linejoin", "round"], ["id", "precos", 1, "section"], [2, "text-align", "center", "max-width", "720px", "margin", "0 auto"], ["data-reveal", "", 1, "lead", 2, "margin", "24px auto 0", "text-align", "center"], ["data-reveal", "", 1, "pricing-card"], [1, "pricing-head"], [1, "h-2", 2, "margin-top", "8px"], [1, "toggle-period"], [3, "click"], [1, "save"], [1, "price-was"], [1, "price-row"], [1, "price-currency"], [1, "price-amount"], [1, "price-period"], [2, "color", "var(--fg-2)", "font-size", "16px", "line-height", "1.55", "max-width", "60ch"], [1, "feature-list"], [1, "pricing-cta"], ["routerLink", "/cadastro", 1, "btn", "btn-ghost", "btn-lg"], [1, "pricing-fine"], [1, "final-cta"], ["data-reveal", "", 1, "urgency"], ["data-reveal", "", 1, "h-display", 2, "margin-top", "24px"], ["data-reveal", "", 1, "final-cta-actions"], ["data-reveal", "", 1, "final-fine"], [1, "footer"], [1, "container", "footer-inner"], ["routerLink", "/", 1, "brand", 2, "justify-content", "center"], [1, "footer-links"], ["href", "#"], [1, "delta"], [1, "chart-bar"], [1, "num"], [1, "title"], [1, "body"], [1, "strike"], [1, "from"], [1, "arrow"], [1, "to"], [1, "ranking-row"], [1, "pos"], [1, "rname"], [1, "rfaixa"], [1, "pts"], [1, "diff-num"], [1, "diff-title"], [1, "diff-body"], [1, "step-num"], [1, "step-title"], [1, "step-body"], [1, "bnum"], [1, "blabel"], [1, "test-dot", 3, "click"], [1, "fcheck"], ["d", "M3 8.5L6.5 12L13 4.5", "stroke", "currentColor", "stroke-width", "2", "stroke-linecap", "round", "stroke-linejoin", "round"]], template: function LandingComponent_Template(rf, ctx) {
      if (rf & 1) {
        \u0275\u0275elementStart(0, "div", 0)(1, "nav", 1)(2, "div", 2)(3, "a", 3)(4, "span", 4);
        \u0275\u0275text(5, "T");
        \u0275\u0275elementEnd();
        \u0275\u0275text(6, " Tatame ");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(7, "div", 5)(8, "a", 6);
        \u0275\u0275text(9, "Problema");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(10, "a", 7);
        \u0275\u0275text(11, "Recursos");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(12, "a", 8);
        \u0275\u0275text(13, "Como funciona");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(14, "a", 9);
        \u0275\u0275text(15, "Pre\xE7os");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(16, "a", 10);
        \u0275\u0275text(17, "Clientes");
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(18, "div", 11)(19, "a", 12);
        \u0275\u0275text(20, "Entrar");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(21, "a", 13);
        \u0275\u0275text(22, "Come\xE7ar gr\xE1tis \u2192");
        \u0275\u0275elementEnd()()()();
        \u0275\u0275elementStart(23, "section", 14)(24, "div", 15)(25, "div")(26, "div", 16);
        \u0275\u0275element(27, "span", 17);
        \u0275\u0275text(28, "Novo \xB7 30 dias gr\xE1tis");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(29, "h1", 18);
        \u0275\u0275text(30, " A academia que para de");
        \u0275\u0275element(31, "br");
        \u0275\u0275elementStart(32, "em");
        \u0275\u0275text(33, "perder alunos.");
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(34, "p", 19);
        \u0275\u0275text(35, " O sistema completo pra academias de luta que querem crescer sem virar planilha. Cobran\xE7a autom\xE1tica, ranking gamificado e dashboard que mostra exatamente onde voc\xEA est\xE1 perdendo dinheiro. ");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(36, "div", 20)(37, "a", 21);
        \u0275\u0275text(38, "Come\xE7ar 30 dias gr\xE1tis \u2192");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(39, "a", 22);
        \u0275\u0275text(40, "Ver demonstra\xE7\xE3o");
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(41, "div", 23)(42, "div", 24)(43, "span", 25);
        \u0275\u0275text(44, "MT");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(45, "span", 25);
        \u0275\u0275text(46, "AB");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(47, "span", 25);
        \u0275\u0275text(48, "RV");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(49, "span", 25);
        \u0275\u0275text(50, "CR");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(51, "span", 26);
        \u0275\u0275text(52, "+");
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(53, "div")(54, "div", 27);
        \u0275\u0275text(55, "\u2605\u2605\u2605\u2605\u2605");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(56, "div", 28);
        \u0275\u0275text(57, "4.9/5 \xB7 ");
        \u0275\u0275elementStart(58, "strong");
        \u0275\u0275text(59, "+540 academias");
        \u0275\u0275elementEnd();
        \u0275\u0275text(60, " usando agora");
        \u0275\u0275elementEnd()()()();
        \u0275\u0275elementStart(61, "div", 29)(62, "div", 30)(63, "div", 31)(64, "div", 32);
        \u0275\u0275element(65, "span")(66, "span")(67, "span");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(68, "div", 33);
        \u0275\u0275text(69, "app.tatame.com.br/dashboard");
        \u0275\u0275elementEnd();
        \u0275\u0275element(70, "div", 34);
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(71, "div", 35)(72, "aside", 36)(73, "div", 37)(74, "span", 38);
        \u0275\u0275text(75, "T");
        \u0275\u0275elementEnd();
        \u0275\u0275text(76, " Tatame ");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(77, "div", 39);
        \u0275\u0275text(78, "Geral");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(79, "div", 40);
        \u0275\u0275namespaceSVG();
        \u0275\u0275elementStart(80, "svg", 41);
        \u0275\u0275element(81, "path", 42);
        \u0275\u0275elementEnd();
        \u0275\u0275text(82, " Dashboard ");
        \u0275\u0275elementEnd();
        \u0275\u0275namespaceHTML();
        \u0275\u0275elementStart(83, "div", 43);
        \u0275\u0275namespaceSVG();
        \u0275\u0275elementStart(84, "svg", 41);
        \u0275\u0275element(85, "path", 44);
        \u0275\u0275elementEnd();
        \u0275\u0275text(86, " Alunos ");
        \u0275\u0275elementEnd();
        \u0275\u0275namespaceHTML();
        \u0275\u0275elementStart(87, "div", 43);
        \u0275\u0275namespaceSVG();
        \u0275\u0275elementStart(88, "svg", 41);
        \u0275\u0275element(89, "rect", 45)(90, "path", 46);
        \u0275\u0275elementEnd();
        \u0275\u0275text(91, " Aulas ");
        \u0275\u0275elementEnd();
        \u0275\u0275namespaceHTML();
        \u0275\u0275elementStart(92, "div", 43);
        \u0275\u0275namespaceSVG();
        \u0275\u0275elementStart(93, "svg", 41);
        \u0275\u0275element(94, "rect", 47)(95, "circle", 48);
        \u0275\u0275elementEnd();
        \u0275\u0275text(96, " Financeiro ");
        \u0275\u0275elementEnd();
        \u0275\u0275namespaceHTML();
        \u0275\u0275elementStart(97, "div", 43);
        \u0275\u0275namespaceSVG();
        \u0275\u0275elementStart(98, "svg", 41);
        \u0275\u0275element(99, "path", 49);
        \u0275\u0275elementEnd();
        \u0275\u0275text(100, " Ranking ");
        \u0275\u0275elementEnd()();
        \u0275\u0275namespaceHTML();
        \u0275\u0275elementStart(101, "main", 50)(102, "div", 51)(103, "div")(104, "div", 52);
        \u0275\u0275text(105, "Ol\xE1, Mestre Carlos");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(106, "div", 53);
        \u0275\u0275text(107, "Vis\xE3o Geral \xB7 Maio 2026");
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(108, "div", 54);
        \u0275\u0275element(109, "span", 17);
        \u0275\u0275text(110, "Ao vivo");
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(111, "div", 55);
        \u0275\u0275repeaterCreate(112, LandingComponent_For_113_Template, 7, 3, "div", 56, _forTrack0);
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(114, "div", 57)(115, "div", 58)(116, "div", 59);
        \u0275\u0275text(117, "Frequ\xEAncia semanal");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(118, "div", 59);
        \u0275\u0275text(119, "\xDAltimos 12 dias");
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(120, "div", 60);
        \u0275\u0275repeaterCreate(121, LandingComponent_For_122_Template, 1, 2, "div", 61, \u0275\u0275repeaterTrackByIndex);
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(123, "div", 62)(124, "div", 63);
        \u0275\u0275text(125, "Pagamentos recentes");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(126, "div", 64)(127, "span");
        \u0275\u0275text(128, "Bruno Yamamoto \xB7 Faixa Roxa");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(129, "span", 65);
        \u0275\u0275text(130, "R$ 280");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(131, "span", 66);
        \u0275\u0275text(132, "Pago");
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(133, "div", 64)(134, "span");
        \u0275\u0275text(135, "Let\xEDcia Andrade \xB7 Faixa Azul");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(136, "span", 65);
        \u0275\u0275text(137, "R$ 280");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(138, "span", 66);
        \u0275\u0275text(139, "Pago");
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(140, "div", 64)(141, "span");
        \u0275\u0275text(142, "Rafael Costa \xB7 Faixa Branca");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(143, "span", 65);
        \u0275\u0275text(144, "R$ 220");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(145, "span", 67);
        \u0275\u0275text(146, "Em aberto");
        \u0275\u0275elementEnd()()()()()()()()();
        \u0275\u0275elementStart(147, "div", 68)(148, "div", 69);
        \u0275\u0275repeaterCreate(149, LandingComponent_For_150_Template, 2, 1, "span", 70, \u0275\u0275repeaterTrackByIndex);
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(151, "section", 71)(152, "div", 72)(153, "div", 73);
        \u0275\u0275text(154, "01 \u2014 O Problema");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(155, "div", 74)(156, "h2", 75);
        \u0275\u0275text(157, " Voc\xEA abriu uma academia");
        \u0275\u0275element(158, "br");
        \u0275\u0275text(159, " pra ");
        \u0275\u0275elementStart(160, "em", 76);
        \u0275\u0275text(161, "treinar");
        \u0275\u0275elementEnd();
        \u0275\u0275text(162, ".");
        \u0275\u0275element(163, "br");
        \u0275\u0275text(164, " N\xE3o pra cobrar boleto. ");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(165, "p", 77);
        \u0275\u0275text(166, " Toda semana \xE9 a mesma coisa: aluno some, mensalidade atrasa, planilha quebra, professor liga pedindo lista. O dinheiro escorre e voc\xEA nem percebe onde. ");
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(167, "div", 78);
        \u0275\u0275repeaterCreate(168, LandingComponent_For_169_Template, 9, 4, "div", 79, _forTrack1);
        \u0275\u0275elementEnd()()();
        \u0275\u0275elementStart(170, "section", 80)(171, "div", 72)(172, "div", 73);
        \u0275\u0275text(173, "02 \u2014 A Solu\xE7\xE3o");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(174, "div", 81)(175, "div")(176, "h2", 75);
        \u0275\u0275text(177, " Um sistema que ");
        \u0275\u0275elementStart(178, "em", 76);
        \u0275\u0275text(179, "cuida");
        \u0275\u0275elementEnd();
        \u0275\u0275text(180, " da academia");
        \u0275\u0275element(181, "br");
        \u0275\u0275text(182, " enquanto voc\xEA cuida do tatame. ");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(183, "p", 82);
        \u0275\u0275text(184, " Tatame \xE9 a \xFAnica plataforma feita exclusivamente pra academias de luta. Cobra sozinho, engaja seus alunos, e mostra todo dia onde voc\xEA pode crescer. ");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(185, "div", 83);
        \u0275\u0275repeaterCreate(186, LandingComponent_For_187_Template, 7, 2, "div", 84, \u0275\u0275repeaterTrackByIndex);
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(188, "div", 85)(189, "div", 86)(190, "span");
        \u0275\u0275text(191, "ATLETA \xB7 TREINO");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(192, "span", 87);
        \u0275\u0275text(193, "JIU-JITSU");
        \u0275\u0275elementEnd()()()()()();
        \u0275\u0275elementStart(194, "section", 88)(195, "div", 72)(196, "div", 73);
        \u0275\u0275text(197, "03 \u2014 Recursos");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(198, "div", 74)(199, "h2", 75);
        \u0275\u0275text(200, " Tudo que sua academia precisa.");
        \u0275\u0275element(201, "br");
        \u0275\u0275elementStart(202, "em", 76);
        \u0275\u0275text(203, "Nada que ela n\xE3o usa.");
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(204, "p", 77);
        \u0275\u0275text(205, " Cinco ferramentas que conversam entre si. Voc\xEA abre uma vez de manh\xE3 e pronto \u2014 sua opera\xE7\xE3o inteira est\xE1 sob controle. ");
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(206, "div", 89)(207, "div", 90)(208, "div", 91);
        \u0275\u0275namespaceSVG();
        \u0275\u0275elementStart(209, "svg", 92);
        \u0275\u0275element(210, "path", 93);
        \u0275\u0275elementEnd()();
        \u0275\u0275namespaceHTML();
        \u0275\u0275elementStart(211, "div", 94);
        \u0275\u0275text(212, "Gest\xE3o de alunos completa");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(213, "div", 95);
        \u0275\u0275text(214, "Cadastro com foto, contato, faixa, gradua\xE7\xE3o, hist\xF3rico m\xE9dico, contrato digital assinado. Tudo num s\xF3 lugar, acess\xEDvel em qualquer dispositivo.");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(215, "div", 96);
        \u0275\u0275text(216, " CARDS DE ALUNOS \xB7 UI ");
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(217, "div", 90)(218, "div", 91);
        \u0275\u0275namespaceSVG();
        \u0275\u0275elementStart(219, "svg", 92);
        \u0275\u0275element(220, "path", 49);
        \u0275\u0275elementEnd()();
        \u0275\u0275namespaceHTML();
        \u0275\u0275elementStart(221, "div", 94);
        \u0275\u0275text(222, "Ranking gamificado ao vivo");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(223, "div", 95);
        \u0275\u0275text(224, "Pontos por presen\xE7a, gradua\xE7\xE3o e competi\xE7\xE3o. O aluno v\xEA o ranking no app. Frequ\xEAncia sobe sem voc\xEA fazer nada.");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(225, "div", 97)(226, "div", 98)(227, "div", 99);
        \u0275\u0275text(228, "Ranking \xB7 Maio");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(229, "div", 100);
        \u0275\u0275element(230, "span", 17);
        \u0275\u0275text(231, "Ao vivo");
        \u0275\u0275elementEnd()();
        \u0275\u0275repeaterCreate(232, LandingComponent_For_233_Template, 11, 13, "div", 101, _forTrack2);
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(234, "div", 102)(235, "div", 91);
        \u0275\u0275namespaceSVG();
        \u0275\u0275elementStart(236, "svg", 92);
        \u0275\u0275element(237, "rect", 47)(238, "circle", 48);
        \u0275\u0275elementEnd()();
        \u0275\u0275namespaceHTML();
        \u0275\u0275elementStart(239, "div", 94);
        \u0275\u0275text(240, "Financeiro autom\xE1tico");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(241, "div", 95);
        \u0275\u0275text(242, "Pix, cart\xE3o e boleto na mesma tela. Cobra sozinho no dia 5, manda lembrete no dia 8, suspende acesso no dia 15. Voc\xEA s\xF3 conta o dinheiro.");
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(243, "div", 102)(244, "div", 91);
        \u0275\u0275namespaceSVG();
        \u0275\u0275elementStart(245, "svg", 92);
        \u0275\u0275element(246, "path", 103);
        \u0275\u0275elementEnd()();
        \u0275\u0275namespaceHTML();
        \u0275\u0275elementStart(247, "div", 94);
        \u0275\u0275text(248, "Presen\xE7a por QR");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(249, "div", 95);
        \u0275\u0275text(250, "Aluno bate o QR Code no celular ao entrar. Voc\xEA v\xEA quem treinou hoje, quem sumiu h\xE1 7 dias, quem est\xE1 virando lenda.");
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(251, "div", 102)(252, "div", 91);
        \u0275\u0275namespaceSVG();
        \u0275\u0275elementStart(253, "svg", 92);
        \u0275\u0275element(254, "path", 104);
        \u0275\u0275elementEnd()();
        \u0275\u0275namespaceHTML();
        \u0275\u0275elementStart(255, "div", 94);
        \u0275\u0275text(256, "Dashboard executivo");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(257, "div", 95);
        \u0275\u0275text(258, "Receita, churn, frequ\xEAncia, proje\xE7\xE3o de caixa. Os n\xFAmeros que importam, atualizados em tempo real, sem precisar de planilha nenhuma.");
        \u0275\u0275elementEnd()()()()();
        \u0275\u0275elementStart(259, "section", 105)(260, "div", 72)(261, "div", 73);
        \u0275\u0275text(262, "04 \u2014 Por que Tatame");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(263, "h2", 106);
        \u0275\u0275text(264, " N\xE3o \xE9 mais um sistema de gest\xE3o.");
        \u0275\u0275element(265, "br");
        \u0275\u0275text(266, " \xC9 uma ");
        \u0275\u0275elementStart(267, "em", 76);
        \u0275\u0275text(268, "arma de crescimento");
        \u0275\u0275elementEnd();
        \u0275\u0275text(269, ". ");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(270, "div", 107);
        \u0275\u0275repeaterCreate(271, LandingComponent_For_272_Template, 7, 3, "div", 108, _forTrack1);
        \u0275\u0275elementEnd()()();
        \u0275\u0275elementStart(273, "section", 109)(274, "div", 72)(275, "div", 73);
        \u0275\u0275text(276, "05 \u2014 Como funciona");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(277, "h2", 110);
        \u0275\u0275text(278, " Voc\xEA est\xE1 rodando");
        \u0275\u0275element(279, "br");
        \u0275\u0275text(280, "em ");
        \u0275\u0275elementStart(281, "em", 76);
        \u0275\u0275text(282, "menos de 24 horas");
        \u0275\u0275elementEnd();
        \u0275\u0275text(283, ". ");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(284, "p", 111);
        \u0275\u0275text(285, " Sem instala\xE7\xE3o, sem consultor, sem treinamento. A gente migra sua planilha pra voc\xEA. ");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(286, "div", 112);
        \u0275\u0275repeaterCreate(287, LandingComponent_For_288_Template, 7, 3, "div", 113, _forTrack1);
        \u0275\u0275elementEnd()()();
        \u0275\u0275elementStart(289, "section", 80)(290, "div", 72)(291, "div", 73);
        \u0275\u0275text(292, "06 \u2014 Resultado");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(293, "h2", 106);
        \u0275\u0275text(294, " Em ");
        \u0275\u0275elementStart(295, "em", 76);
        \u0275\u0275text(296, "90 dias");
        \u0275\u0275elementEnd();
        \u0275\u0275text(297, " sua academia");
        \u0275\u0275element(298, "br");
        \u0275\u0275text(299, "n\xE3o vai parecer a mesma. ");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(300, "div", 114);
        \u0275\u0275repeaterCreate(301, LandingComponent_For_302_Template, 5, 2, "div", 115, _forTrack1);
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(303, "div", 116)(304, "div")(305, "div", 117);
        \u0275\u0275text(306, "Calculadora \xB7 Quanto voc\xEA est\xE1 perdendo");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(307, "div", 118);
        \u0275\u0275text(308, "Descubra seu ganho mensal.");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(309, "div", 119)(310, "label");
        \u0275\u0275text(311, "Alunos hoje ");
        \u0275\u0275elementStart(312, "span", 120);
        \u0275\u0275text(313);
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(314, "input", 121);
        \u0275\u0275listener("input", function LandingComponent_Template_input_input_314_listener($event) {
          return ctx.setRoiStudents($event);
        });
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(315, "div", 119)(316, "label");
        \u0275\u0275text(317, "Mensalidade m\xE9dia ");
        \u0275\u0275elementStart(318, "span", 120);
        \u0275\u0275text(319);
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(320, "input", 122);
        \u0275\u0275listener("input", function LandingComponent_Template_input_input_320_listener($event) {
          return ctx.setRoiFee($event);
        });
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(321, "div", 119)(322, "label");
        \u0275\u0275text(323, "Inadimpl\xEAncia atual ");
        \u0275\u0275elementStart(324, "span", 120);
        \u0275\u0275text(325);
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(326, "input", 123);
        \u0275\u0275listener("input", function LandingComponent_Template_input_input_326_listener($event) {
          return ctx.setRoiDefault($event);
        });
        \u0275\u0275elementEnd()()();
        \u0275\u0275elementStart(327, "div", 124)(328, "div", 125);
        \u0275\u0275text(329, "Voc\xEA ganha por m\xEAs");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(330, "div", 126);
        \u0275\u0275text(331);
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(332, "div", 127)(333, "div", 128)(334, "span");
        \u0275\u0275text(335, "Inadimpl\xEAncia recuperada");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(336, "span");
        \u0275\u0275text(337);
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(338, "div", 128)(339, "span");
        \u0275\u0275text(340);
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(341, "span");
        \u0275\u0275text(342);
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(343, "div", 129)(344, "span");
        \u0275\u0275text(345, "Investimento Tatame");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(346, "span", 130);
        \u0275\u0275text(347, "R$ 149");
        \u0275\u0275elementEnd()()()()()()();
        \u0275\u0275elementStart(348, "section", 131)(349, "div", 72)(350, "div", 73);
        \u0275\u0275text(351, "07 \u2014 Quem j\xE1 treina com a gente");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(352, "h2", 132)(353, "em", 76);
        \u0275\u0275text(354, "540 academias");
        \u0275\u0275elementEnd();
        \u0275\u0275text(355, ".");
        \u0275\u0275element(356, "br");
        \u0275\u0275text(357, " +50 mil alunos gerenciados.");
        \u0275\u0275element(358, "br");
        \u0275\u0275text(359, " Zero arrependidos. ");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(360, "div", 133)(361, "div", 134)(362, "div", 135);
        \u0275\u0275text(363);
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(364, "div", 136)(365, "div", 137);
        \u0275\u0275text(366);
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(367, "div")(368, "div", 138);
        \u0275\u0275text(369);
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(370, "div", 139);
        \u0275\u0275text(371);
        \u0275\u0275elementEnd()()()();
        \u0275\u0275elementStart(372, "div", 140)(373, "div", 141);
        \u0275\u0275repeaterCreate(374, LandingComponent_For_375_Template, 1, 2, "button", 142, _forTrack2);
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(376, "div", 143)(377, "button", 144);
        \u0275\u0275listener("click", function LandingComponent_Template_button_click_377_listener() {
          return ctx.prevTestimonial();
        });
        \u0275\u0275namespaceSVG();
        \u0275\u0275elementStart(378, "svg", 145);
        \u0275\u0275element(379, "path", 146);
        \u0275\u0275elementEnd()();
        \u0275\u0275namespaceHTML();
        \u0275\u0275elementStart(380, "button", 144);
        \u0275\u0275listener("click", function LandingComponent_Template_button_click_380_listener() {
          return ctx.nextTestimonial();
        });
        \u0275\u0275namespaceSVG();
        \u0275\u0275elementStart(381, "svg", 145);
        \u0275\u0275element(382, "path", 147);
        \u0275\u0275elementEnd()()()()()()();
        \u0275\u0275namespaceHTML();
        \u0275\u0275elementStart(383, "section", 148)(384, "div", 72)(385, "div", 73);
        \u0275\u0275text(386, "08 \u2014 Pre\xE7os");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(387, "div", 149)(388, "h2", 75);
        \u0275\u0275text(389, " Um plano. ");
        \u0275\u0275elementStart(390, "em", 76);
        \u0275\u0275text(391, "Tudo dentro.");
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(392, "p", 150);
        \u0275\u0275text(393, " Sem trial limitado. Sem feature trancada. Sem upgrade for\xE7ado. Voc\xEA paga uma coisa s\xF3, simples e justa. ");
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(394, "div", 151)(395, "div", 152)(396, "div")(397, "div", 99);
        \u0275\u0275text(398, "Plano \xFAnico \xB7 Tudo incluso");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(399, "div", 153);
        \u0275\u0275text(400, "Tatame Pro");
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(401, "div", 154)(402, "button", 155);
        \u0275\u0275listener("click", function LandingComponent_Template_button_click_402_listener() {
          return ctx.pricingAnual.set(false);
        });
        \u0275\u0275text(403, "Mensal");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(404, "button", 155);
        \u0275\u0275listener("click", function LandingComponent_Template_button_click_404_listener() {
          return ctx.pricingAnual.set(true);
        });
        \u0275\u0275text(405, " Anual ");
        \u0275\u0275elementStart(406, "span", 156);
        \u0275\u0275text(407, "\u221220%");
        \u0275\u0275elementEnd()()()();
        \u0275\u0275elementStart(408, "div", 157);
        \u0275\u0275text(409);
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(410, "div", 158)(411, "span", 159);
        \u0275\u0275text(412, "R$");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(413, "span", 160);
        \u0275\u0275text(414);
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(415, "span", 161);
        \u0275\u0275text(416);
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(417, "p", 162);
        \u0275\u0275text(418, " Alunos ilimitados. Sem taxa por matr\xEDcula. Sem letra mi\xFAda. Cancele com um clique se n\xE3o amar. ");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(419, "ul", 163);
        \u0275\u0275repeaterCreate(420, LandingComponent_For_421_Template, 5, 1, "li", null, \u0275\u0275repeaterTrackByIdentity);
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(422, "div", 164)(423, "a", 21);
        \u0275\u0275text(424, "Come\xE7ar 30 dias gr\xE1tis \u2192");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(425, "a", 165);
        \u0275\u0275text(426, "Falar com vendas");
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(427, "div", 166);
        \u0275\u0275text(428, "SEM CART\xC3O DE CR\xC9DITO \xB7 MIGRA\xC7\xC3O GR\xC1TIS \xB7 SEU TIME EM MENOS DE 24H");
        \u0275\u0275elementEnd()()()();
        \u0275\u0275elementStart(429, "section", 167)(430, "div", 72)(431, "div", 168);
        \u0275\u0275element(432, "span", 17);
        \u0275\u0275text(433, "23 academias come\xE7aram esta semana");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(434, "h2", 169);
        \u0275\u0275text(435, " Sua academia");
        \u0275\u0275element(436, "br");
        \u0275\u0275text(437, "no ");
        \u0275\u0275elementStart(438, "em", 76);
        \u0275\u0275text(439, "pr\xF3ximo n\xEDvel");
        \u0275\u0275elementEnd();
        \u0275\u0275text(440, ". ");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(441, "div", 170)(442, "a", 21);
        \u0275\u0275text(443, "Come\xE7ar 30 dias gr\xE1tis \u2192");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(444, "a", 165);
        \u0275\u0275text(445, "Agendar demonstra\xE7\xE3o");
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(446, "div", 171);
        \u0275\u0275text(447, " Sem cart\xE3o de cr\xE9dito \xB7 Cancele com 1 clique \xB7 Suporte humano em at\xE9 2h ");
        \u0275\u0275elementEnd()()();
        \u0275\u0275elementStart(448, "footer", 172)(449, "div", 173)(450, "div");
        \u0275\u0275text(451, "\xA9 2026 Tatame. Feito por quem treina, pra quem treina.");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(452, "a", 174)(453, "span", 4);
        \u0275\u0275text(454, "T");
        \u0275\u0275elementEnd();
        \u0275\u0275text(455, " Tatame ");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(456, "div", 175)(457, "a", 176);
        \u0275\u0275text(458, "Termos");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(459, "a", 176);
        \u0275\u0275text(460, "Privacidade");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(461, "a", 176);
        \u0275\u0275text(462, "Suporte");
        \u0275\u0275elementEnd()()()()();
      }
      if (rf & 2) {
        \u0275\u0275advance(112);
        \u0275\u0275repeater(ctx.dashStats());
        \u0275\u0275advance(9);
        \u0275\u0275repeater(ctx.bars());
        \u0275\u0275advance(28);
        \u0275\u0275repeater(ctx.disciplinasMarquee);
        \u0275\u0275advance(19);
        \u0275\u0275repeater(ctx.problemas);
        \u0275\u0275advance(18);
        \u0275\u0275repeater(ctx.transforms);
        \u0275\u0275advance(46);
        \u0275\u0275repeater(ctx.rankingRows());
        \u0275\u0275advance(39);
        \u0275\u0275repeater(ctx.diferenciais);
        \u0275\u0275advance(16);
        \u0275\u0275repeater(ctx.passos);
        \u0275\u0275advance(14);
        \u0275\u0275repeater(ctx.beneficios);
        \u0275\u0275advance(12);
        \u0275\u0275textInterpolate(ctx.roiStudents());
        \u0275\u0275advance();
        \u0275\u0275property("value", ctx.roiStudents());
        \u0275\u0275advance(5);
        \u0275\u0275textInterpolate1("R$ ", ctx.roiFee(), "");
        \u0275\u0275advance();
        \u0275\u0275property("value", ctx.roiFee());
        \u0275\u0275advance(5);
        \u0275\u0275textInterpolate1("", ctx.roiDefaultRate(), "%");
        \u0275\u0275advance();
        \u0275\u0275property("value", ctx.roiDefaultRate());
        \u0275\u0275advance(5);
        \u0275\u0275textInterpolate(ctx.fmtBrl(ctx.roiResult().total));
        \u0275\u0275advance(6);
        \u0275\u0275textInterpolate(ctx.fmtBrl(ctx.roiResult().recovered));
        \u0275\u0275advance(3);
        \u0275\u0275textInterpolate1("Crescimento (", ctx.roiResult().newStudents, " novos alunos)");
        \u0275\u0275advance(2);
        \u0275\u0275textInterpolate(ctx.fmtBrl(ctx.roiResult().growth));
        \u0275\u0275advance(21);
        \u0275\u0275textInterpolate(ctx.testimonialAtivo().quote);
        \u0275\u0275advance(3);
        \u0275\u0275textInterpolate(ctx.testimonialAtivo().avatar);
        \u0275\u0275advance(3);
        \u0275\u0275textInterpolate(ctx.testimonialAtivo().name);
        \u0275\u0275advance(2);
        \u0275\u0275textInterpolate(ctx.testimonialAtivo().role);
        \u0275\u0275advance(3);
        \u0275\u0275repeater(ctx.depoimentos);
        \u0275\u0275advance(28);
        \u0275\u0275classProp("active", !ctx.pricingAnual());
        \u0275\u0275advance(2);
        \u0275\u0275classProp("active", ctx.pricingAnual());
        \u0275\u0275advance(5);
        \u0275\u0275textInterpolate1("de R$ ", ctx.pricingWas(), "/m\xEAs");
        \u0275\u0275advance(5);
        \u0275\u0275textInterpolate(ctx.pricingPreco());
        \u0275\u0275advance(2);
        \u0275\u0275textInterpolate1("/m\xEAs", ctx.pricingAnual() ? " \xB7 cobrado anualmente" : "", "");
        \u0275\u0275advance(4);
        \u0275\u0275repeater(ctx.priceFeatures);
      }
    }, dependencies: [RouterLink, DecimalPipe], styles: [`

[_nghost-%COMP%] {
  display: block;
  --bg: #0a0a0a;
  --bg-2: #111111;
  --bg-3: #161616;
  --fg: #fafaf7;
  --fg-2: #c9c8c2;
  --fg-3: #8a8985;
  --line: #232323;
  --line-2: #2e2e2e;
  --accent: #ff4d2e;
  --accent-2: #ff6a4d;
  --good: #a3e635;
  --display:
    "Geist",
    "Inter",
    system-ui,
    -apple-system,
    sans-serif;
  --mono:
    "Geist Mono",
    "JetBrains Mono",
    ui-monospace,
    monospace;
}
.lp[_ngcontent-%COMP%] {
  background: var(--bg);
  color: var(--fg);
  font-family: var(--display);
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  line-height: 1.4;
  overflow-x: clip;
  min-height: 100vh;
}
.lp[_ngcontent-%COMP%]   a[_ngcontent-%COMP%] {
  color: inherit;
  text-decoration: none;
}
.lp[_ngcontent-%COMP%]   button[_ngcontent-%COMP%] {
  font: inherit;
  color: inherit;
  background: none;
  border: none;
  cursor: pointer;
}
.container[_ngcontent-%COMP%] {
  width: 100%;
  max-width: 1440px;
  margin: 0 auto;
  padding: 0 32px;
}
@media (max-width: 720px) {
  .container[_ngcontent-%COMP%] {
    padding: 0 20px;
  }
}
.section[_ngcontent-%COMP%] {
  padding: 120px 0;
  border-top: 1px solid var(--line);
}
@media (max-width: 720px) {
  .section[_ngcontent-%COMP%] {
    padding: 72px 0;
  }
}
.section-num[_ngcontent-%COMP%] {
  font-family: var(--mono);
  font-size: 12px;
  letter-spacing: 0.08em;
  color: var(--fg-3);
  text-transform: uppercase;
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 48px;
}
.section-num[_ngcontent-%COMP%]::after {
  content: "";
  flex: 1;
  height: 1px;
  background: var(--line);
  max-width: 120px;
}
.eyebrow[_ngcontent-%COMP%] {
  font-family: var(--mono);
  font-size: 11px;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: var(--fg-3);
}
.h-display[_ngcontent-%COMP%] {
  font-family: var(--display);
  font-weight: 600;
  letter-spacing: -0.04em;
  line-height: 0.92;
  font-size: clamp(48px, 6vw, 100px);
}
.h-1[_ngcontent-%COMP%] {
  font-family: var(--display);
  font-weight: 600;
  letter-spacing: -0.035em;
  line-height: 0.95;
  font-size: clamp(30px, 3vw, 52px);
}
.h-2[_ngcontent-%COMP%] {
  font-family: var(--display);
  font-weight: 600;
  letter-spacing: -0.03em;
  line-height: 1;
  font-size: clamp(32px, 4vw, 56px);
}
.lead[_ngcontent-%COMP%] {
  font-size: clamp(17px, 1.4vw, 21px);
  color: var(--fg-2);
  line-height: 1.5;
  max-width: 56ch;
}
.btn[_ngcontent-%COMP%] {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  padding: 14px 22px;
  border-radius: 999px;
  font-weight: 500;
  font-size: 15px;
  letter-spacing: -0.005em;
  transition:
    transform 160ms ease,
    background 160ms ease,
    border-color 160ms ease;
  white-space: nowrap;
  cursor: pointer;
}
.btn[_ngcontent-%COMP%]:active {
  transform: translateY(1px);
}
.btn-primary[_ngcontent-%COMP%] {
  background: var(--accent);
  color: #0a0a0a;
}
.btn-primary[_ngcontent-%COMP%]:hover {
  background: var(--accent-2);
}
.btn-ghost[_ngcontent-%COMP%] {
  background: transparent;
  color: var(--fg);
  border: 1px solid var(--line-2);
}
.btn-ghost[_ngcontent-%COMP%]:hover {
  border-color: var(--fg-2);
}
.btn-lg[_ngcontent-%COMP%] {
  padding: 18px 28px;
  font-size: 16px;
}
.badge[_ngcontent-%COMP%] {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 6px 12px;
  border: 1px solid var(--line-2);
  border-radius: 999px;
  font-family: var(--mono);
  font-size: 11px;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--fg-2);
  background: var(--bg-2);
}
.badge[_ngcontent-%COMP%]   .dot[_ngcontent-%COMP%] {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--good);
  animation: _ngcontent-%COMP%_pulse 2s infinite;
}
@keyframes _ngcontent-%COMP%_pulse {
  0%, 100% {
    opacity: 1;
  }
  50% {
    opacity: 0.4;
  }
}
.nav[_ngcontent-%COMP%] {
  position: sticky;
  top: 0;
  z-index: 50;
  background: rgba(10, 10, 10, 0.85);
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  border-bottom: 1px solid var(--line);
}
.nav-inner[_ngcontent-%COMP%] {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 18px 32px;
  max-width: 1440px;
  margin: 0 auto;
}
@media (max-width: 720px) {
  .nav-inner[_ngcontent-%COMP%] {
    padding: 14px 20px;
  }
}
.brand[_ngcontent-%COMP%] {
  display: flex;
  align-items: center;
  gap: 10px;
  font-family: var(--display);
  font-weight: 700;
  font-size: 18px;
  letter-spacing: -0.02em;
}
.brand-mark[_ngcontent-%COMP%] {
  width: 22px;
  height: 22px;
  border-radius: 5px;
  background: var(--accent);
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: #0a0a0a;
  font-size: 13px;
  font-weight: 800;
}
.nav-links[_ngcontent-%COMP%] {
  display: flex;
  gap: 28px;
  font-size: 14px;
  color: var(--fg-2);
}
.nav-links[_ngcontent-%COMP%]   a[_ngcontent-%COMP%]:hover {
  color: var(--fg);
}
@media (max-width: 880px) {
  .nav-links[_ngcontent-%COMP%] {
    display: none;
  }
}
.nav-actions[_ngcontent-%COMP%] {
  display: flex;
  align-items: center;
  gap: 12px;
}
.hero[_ngcontent-%COMP%] {
  padding: 80px 0 60px;
}
.hero-grid[_ngcontent-%COMP%] {
  display: grid;
  grid-template-columns: 1.05fr 1fr;
  gap: 56px;
  align-items: center;
}
@media (max-width: 980px) {
  .hero-grid[_ngcontent-%COMP%] {
    grid-template-columns: 1fr;
    gap: 40px;
  }
}
.hero-headline[_ngcontent-%COMP%] {
  margin-top: 24px;
}
.hero-headline[_ngcontent-%COMP%]   em[_ngcontent-%COMP%] {
  font-style: normal;
  color: var(--accent);
}
.hero-sub[_ngcontent-%COMP%] {
  margin-top: 28px;
  max-width: 52ch;
}
.hero-cta[_ngcontent-%COMP%] {
  margin-top: 36px;
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
  align-items: center;
}
.hero-trust[_ngcontent-%COMP%] {
  margin-top: 32px;
  display: flex;
  align-items: center;
  gap: 16px;
  flex-wrap: wrap;
  font-size: 13px;
  color: var(--fg-3);
}
.avatar-stack[_ngcontent-%COMP%] {
  display: flex;
}
.avatar-stack[_ngcontent-%COMP%]   .avatar[_ngcontent-%COMP%] {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  border: 2px solid var(--bg);
  margin-left: -8px;
  background:
    linear-gradient(
      135deg,
      #444,
      #222);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 10px;
  font-weight: 600;
  color: var(--fg);
}
.avatar-stack[_ngcontent-%COMP%]   .avatar[_ngcontent-%COMP%]:first-child {
  margin-left: 0;
}
.stars[_ngcontent-%COMP%] {
  display: inline-flex;
  gap: 1px;
  color: var(--accent);
  font-size: 12px;
}
.dash[_ngcontent-%COMP%] {
  background: var(--bg-2);
  border: 1px solid var(--line);
  border-radius: 16px;
  overflow: hidden;
}
.dash-chrome[_ngcontent-%COMP%] {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
  border-bottom: 1px solid var(--line);
  background: var(--bg-3);
}
.dash-dots[_ngcontent-%COMP%] {
  display: flex;
  gap: 6px;
}
.dash-dots[_ngcontent-%COMP%]   span[_ngcontent-%COMP%] {
  width: 10px;
  height: 10px;
  border-radius: 50%;
}
.dash-dots[_ngcontent-%COMP%]   span[_ngcontent-%COMP%]:nth-child(1) {
  background: #ff6058;
}
.dash-dots[_ngcontent-%COMP%]   span[_ngcontent-%COMP%]:nth-child(2) {
  background: #ffbd2e;
}
.dash-dots[_ngcontent-%COMP%]   span[_ngcontent-%COMP%]:nth-child(3) {
  background: #28ca42;
}
.dash-url[_ngcontent-%COMP%] {
  flex: 1;
  text-align: center;
  font-family: var(--mono);
  font-size: 12px;
  color: var(--fg-3);
}
.dash-body[_ngcontent-%COMP%] {
  display: grid;
  grid-template-columns: 180px 1fr;
}
.dash-sidebar[_ngcontent-%COMP%] {
  background: var(--bg-3);
  border-right: 1px solid var(--line);
  padding: 16px 10px;
  display: flex;
  flex-direction: column;
  gap: 3px;
}
.dash-side-brand[_ngcontent-%COMP%] {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 10px;
  font-family: var(--display);
  font-weight: 700;
  font-size: 14px;
  margin-bottom: 12px;
}
.dash-side-section[_ngcontent-%COMP%] {
  font-family: var(--mono);
  font-size: 9px;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  color: var(--fg-3);
  padding: 10px 10px 4px;
}
.dash-side-item[_ngcontent-%COMP%] {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 7px 10px;
  border-radius: 6px;
  font-size: 12px;
  color: var(--fg-2);
}
.dash-side-item.active[_ngcontent-%COMP%] {
  background: rgba(255, 77, 46, 0.12);
  color: var(--fg);
}
.dash-main[_ngcontent-%COMP%] {
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}
.dash-h[_ngcontent-%COMP%] {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.dash-title[_ngcontent-%COMP%] {
  font-family: var(--display);
  font-weight: 600;
  font-size: 18px;
  letter-spacing: -0.02em;
}
.dash-stats[_ngcontent-%COMP%] {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 10px;
}
.dash-stat[_ngcontent-%COMP%] {
  background: var(--bg-3);
  border: 1px solid var(--line);
  border-radius: 8px;
  padding: 12px;
}
.dash-stat[_ngcontent-%COMP%]   .label[_ngcontent-%COMP%] {
  font-family: var(--mono);
  font-size: 9px;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  color: var(--fg-3);
}
.dash-stat[_ngcontent-%COMP%]   .val[_ngcontent-%COMP%] {
  font-family: var(--display);
  font-weight: 600;
  font-size: 20px;
  letter-spacing: -0.02em;
  margin-top: 4px;
}
.dash-stat[_ngcontent-%COMP%]   .delta[_ngcontent-%COMP%] {
  font-size: 10px;
  font-family: var(--mono);
  color: var(--good);
}
.dash-chart[_ngcontent-%COMP%] {
  background: var(--bg-3);
  border: 1px solid var(--line);
  border-radius: 8px;
  padding: 14px;
}
.chart-h[_ngcontent-%COMP%] {
  display: flex;
  justify-content: space-between;
  margin-bottom: 10px;
}
.chart-h[_ngcontent-%COMP%]   .label[_ngcontent-%COMP%] {
  font-family: var(--mono);
  font-size: 9px;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  color: var(--fg-3);
}
.chart-bars[_ngcontent-%COMP%] {
  display: flex;
  align-items: flex-end;
  gap: 5px;
  height: 80px;
}
.chart-bar[_ngcontent-%COMP%] {
  flex: 1;
  background:
    linear-gradient(
      to top,
      var(--accent),
      rgba(255, 77, 46, 0.4));
  border-radius: 3px;
  min-height: 4px;
  transition: height 800ms cubic-bezier(0.4, 0, 0.2, 1);
}
.dash-list[_ngcontent-%COMP%] {
  background: var(--bg-3);
  border: 1px solid var(--line);
  border-radius: 8px;
  padding: 12px;
}
.dash-list-h[_ngcontent-%COMP%] {
  font-family: var(--mono);
  font-size: 9px;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  color: var(--fg-3);
  padding-bottom: 8px;
  border-bottom: 1px solid var(--line);
  margin-bottom: 6px;
}
.dash-list-row[_ngcontent-%COMP%] {
  display: grid;
  grid-template-columns: 1fr auto auto;
  gap: 10px;
  padding: 7px 2px;
  border-bottom: 1px solid var(--line);
  align-items: center;
  font-size: 11px;
}
.dash-list-row[_ngcontent-%COMP%]:last-child {
  border-bottom: none;
}
.pill[_ngcontent-%COMP%] {
  font-family: var(--mono);
  font-size: 9px;
  padding: 3px 7px;
  border-radius: 999px;
}
.pill.paid[_ngcontent-%COMP%] {
  background: rgba(163, 230, 53, 0.15);
  color: var(--good);
}
.pill.due[_ngcontent-%COMP%] {
  background: rgba(250, 204, 21, 0.15);
  color: #facc15;
}
@media (max-width: 880px) {
  .dash-body[_ngcontent-%COMP%] {
    grid-template-columns: 1fr;
  }
  .dash-sidebar[_ngcontent-%COMP%] {
    display: none;
  }
  .dash-stats[_ngcontent-%COMP%] {
    grid-template-columns: 1fr 1fr;
  }
}
.marquee[_ngcontent-%COMP%] {
  border-top: 1px solid var(--line);
  border-bottom: 1px solid var(--line);
  padding: 28px 0;
  overflow: hidden;
}
.marquee-track[_ngcontent-%COMP%] {
  display: flex;
  gap: 56px;
  animation: _ngcontent-%COMP%_marquee 40s linear infinite;
  white-space: nowrap;
  width: max-content;
}
@keyframes _ngcontent-%COMP%_marquee {
  to {
    transform: translateX(-50%);
  }
}
.marquee-item[_ngcontent-%COMP%] {
  font-family: var(--display);
  font-weight: 600;
  font-size: 20px;
  letter-spacing: -0.02em;
  color: var(--fg-3);
  display: inline-flex;
  align-items: center;
  gap: 56px;
}
.marquee-item[_ngcontent-%COMP%]::after {
  content: "\\b7";
  color: var(--line-2);
  font-size: 14px;
}
.two-col-head[_ngcontent-%COMP%] {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 64px;
  align-items: start;
}
.two-col-head[_ngcontent-%COMP%]    > *[_ngcontent-%COMP%] {
  min-width: 0;
}
@media (max-width: 880px) {
  .two-col-head[_ngcontent-%COMP%] {
    grid-template-columns: 1fr;
    gap: 24px;
  }
}
.problem-grid[_ngcontent-%COMP%] {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 1px;
  background: var(--line);
  border: 1px solid var(--line);
  border-radius: 16px;
  overflow: hidden;
  margin-top: 64px;
}
.problem-card[_ngcontent-%COMP%] {
  background: var(--bg);
  padding: 32px;
  display: flex;
  flex-direction: column;
  gap: 12px;
  min-height: 200px;
}
.problem-card[_ngcontent-%COMP%]   .num[_ngcontent-%COMP%] {
  font-family: var(--mono);
  font-size: 11px;
  color: var(--fg-3);
  letter-spacing: 0.1em;
}
.problem-card[_ngcontent-%COMP%]   .title[_ngcontent-%COMP%] {
  font-family: var(--display);
  font-weight: 600;
  font-size: 22px;
  letter-spacing: -0.02em;
  line-height: 1.15;
  margin-top: 8px;
}
.problem-card[_ngcontent-%COMP%]   .body[_ngcontent-%COMP%] {
  font-size: 15px;
  color: var(--fg-3);
  line-height: 1.5;
}
.problem-card[_ngcontent-%COMP%]   .strike[_ngcontent-%COMP%] {
  text-decoration: line-through;
  text-decoration-color: var(--accent);
  text-decoration-thickness: 2px;
  color: var(--fg-3);
  font-family: var(--mono);
  font-size: 12px;
  margin-top: auto;
}
@media (max-width: 720px) {
  .problem-grid[_ngcontent-%COMP%] {
    grid-template-columns: 1fr;
  }
}
.solution-split[_ngcontent-%COMP%] {
  display: grid;
  grid-template-columns: 1.1fr 1fr;
  gap: 64px;
  align-items: start;
  margin-top: 32px;
}
.solution-split[_ngcontent-%COMP%]    > *[_ngcontent-%COMP%] {
  min-width: 0;
}
@media (max-width: 880px) {
  .solution-split[_ngcontent-%COMP%] {
    grid-template-columns: 1fr;
    gap: 40px;
  }
}
.transform-list[_ngcontent-%COMP%] {
  margin-top: 36px;
  border-top: 1px solid var(--line);
}
.transform-row[_ngcontent-%COMP%] {
  display: grid;
  grid-template-columns: 1fr auto 1fr;
  gap: 24px;
  padding: 20px 0;
  border-bottom: 1px solid var(--line);
  align-items: center;
}
.transform-row[_ngcontent-%COMP%]   .from[_ngcontent-%COMP%] {
  color: var(--fg-3);
  font-size: 15px;
  text-decoration: line-through;
  text-decoration-color: var(--fg-3);
}
.transform-row[_ngcontent-%COMP%]   .arrow[_ngcontent-%COMP%] {
  color: var(--accent);
  font-family: var(--mono);
  font-size: 12px;
}
.transform-row[_ngcontent-%COMP%]   .to[_ngcontent-%COMP%] {
  color: var(--fg);
  font-size: 16px;
  font-weight: 500;
}
.img-ph[_ngcontent-%COMP%] {
  background:
    repeating-linear-gradient(
      135deg,
      #1a1a1a 0px,
      #1a1a1a 1px,
      #0f0f0f 1px,
      #0f0f0f 8px);
  border: 1px solid var(--line);
  border-radius: 10px;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  padding: 20px;
  color: var(--fg-3);
  font-family: var(--mono);
  font-size: 11px;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  aspect-ratio: 3 / 4;
}
.features-grid[_ngcontent-%COMP%] {
  display: grid;
  grid-template-columns: repeat(6, 1fr);
  gap: 16px;
  margin-top: 64px;
}
.feature-card[_ngcontent-%COMP%] {
  background: var(--bg-2);
  border: 1px solid var(--line);
  border-radius: 16px;
  padding: 28px;
  display: flex;
  flex-direction: column;
  gap: 16px;
  transition: border-color 200ms ease;
}
.feature-card[_ngcontent-%COMP%]:hover {
  border-color: var(--line-2);
}
.feat-icon[_ngcontent-%COMP%] {
  width: 36px;
  height: 36px;
  border-radius: 8px;
  background: var(--bg-3);
  border: 1px solid var(--line);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--accent);
}
.feat-title[_ngcontent-%COMP%] {
  font-family: var(--display);
  font-weight: 600;
  font-size: 20px;
  letter-spacing: -0.02em;
}
.feat-body[_ngcontent-%COMP%] {
  color: var(--fg-3);
  font-size: 14px;
  line-height: 1.5;
  flex: 1;
}
.span-3[_ngcontent-%COMP%] {
  grid-column: span 3;
}
.span-2[_ngcontent-%COMP%] {
  grid-column: span 2;
}
.tall[_ngcontent-%COMP%] {
  min-height: 280px;
}
@media (max-width: 880px) {
  .features-grid[_ngcontent-%COMP%] {
    grid-template-columns: repeat(2, 1fr);
  }
  .span-3[_ngcontent-%COMP%], .span-2[_ngcontent-%COMP%] {
    grid-column: span 2;
  }
}
@media (max-width: 540px) {
  .features-grid[_ngcontent-%COMP%] {
    grid-template-columns: 1fr;
  }
  .span-3[_ngcontent-%COMP%], .span-2[_ngcontent-%COMP%] {
    grid-column: span 1;
  }
}
.ranking[_ngcontent-%COMP%] {
  background: var(--bg-3);
  border-radius: 10px;
  padding: 14px;
  border: 1px solid var(--line);
  font-family: var(--mono);
  font-size: 13px;
  margin-top: 12px;
}
.ranking-head[_ngcontent-%COMP%] {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
}
.ranking-row[_ngcontent-%COMP%] {
  display: grid;
  grid-template-columns: 30px 1fr auto;
  gap: 10px;
  align-items: center;
  padding: 7px 3px;
  border-bottom: 1px solid var(--line);
}
.ranking-row[_ngcontent-%COMP%]:last-child {
  border-bottom: none;
}
.ranking-row[_ngcontent-%COMP%]   .pos[_ngcontent-%COMP%] {
  width: 22px;
  height: 22px;
  border-radius: 50%;
  background: var(--bg-2);
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 10px;
  font-weight: 600;
  color: var(--fg);
}
.ranking-row.gold[_ngcontent-%COMP%]   .pos[_ngcontent-%COMP%] {
  background: var(--accent);
  color: #0a0a0a;
}
.ranking-row.silver[_ngcontent-%COMP%]   .pos[_ngcontent-%COMP%] {
  background: var(--fg-2);
  color: #0a0a0a;
}
.ranking-row.bronze[_ngcontent-%COMP%]   .pos[_ngcontent-%COMP%] {
  background: #b87333;
  color: #0a0a0a;
}
.ranking-row[_ngcontent-%COMP%]   .rname[_ngcontent-%COMP%] {
  font-family: var(--display);
  color: var(--fg);
  font-size: 13px;
}
.ranking-row[_ngcontent-%COMP%]   .rfaixa[_ngcontent-%COMP%] {
  font-size: 10px;
  color: var(--fg-3);
}
.ranking-row[_ngcontent-%COMP%]   .pts[_ngcontent-%COMP%] {
  color: var(--fg-3);
  font-size: 11px;
}
.diff-grid[_ngcontent-%COMP%] {
  border-top: 1px solid var(--line);
  margin-top: 48px;
}
.diff-row[_ngcontent-%COMP%] {
  display: grid;
  grid-template-columns: 80px 1fr 1.4fr;
  gap: 32px;
  padding: 28px 0;
  border-bottom: 1px solid var(--line);
  align-items: start;
}
.diff-row[_ngcontent-%COMP%]    > *[_ngcontent-%COMP%] {
  min-width: 0;
}
.diff-num[_ngcontent-%COMP%] {
  font-family: var(--mono);
  font-size: 12px;
  color: var(--accent);
  letter-spacing: 0.1em;
  padding-top: 6px;
}
.diff-title[_ngcontent-%COMP%] {
  font-family: var(--display);
  font-weight: 600;
  font-size: 28px;
  letter-spacing: -0.025em;
  line-height: 1.05;
}
.diff-body[_ngcontent-%COMP%] {
  color: var(--fg-3);
  font-size: 15px;
  line-height: 1.55;
  padding-top: 6px;
}
@media (max-width: 720px) {
  .diff-row[_ngcontent-%COMP%] {
    grid-template-columns: 1fr;
    gap: 8px;
  }
}
.steps[_ngcontent-%COMP%] {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 24px;
  margin-top: 64px;
}
.step[_ngcontent-%COMP%] {
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding: 28px 0 0;
  border-top: 1px solid var(--fg);
}
.step[_ngcontent-%COMP%]   .step-num[_ngcontent-%COMP%] {
  font-family: var(--mono);
  font-size: 11px;
  color: var(--fg-3);
  letter-spacing: 0.1em;
}
.step[_ngcontent-%COMP%]   .step-title[_ngcontent-%COMP%] {
  font-family: var(--display);
  font-weight: 600;
  font-size: 22px;
  letter-spacing: -0.02em;
  line-height: 1.15;
}
.step[_ngcontent-%COMP%]   .step-body[_ngcontent-%COMP%] {
  color: var(--fg-3);
  font-size: 14px;
  line-height: 1.55;
}
@media (max-width: 880px) {
  .steps[_ngcontent-%COMP%] {
    grid-template-columns: repeat(2, 1fr);
  }
}
@media (max-width: 540px) {
  .steps[_ngcontent-%COMP%] {
    grid-template-columns: 1fr;
  }
}
.benefit-stats[_ngcontent-%COMP%] {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 24px;
  margin-top: 48px;
  border-top: 1px solid var(--line);
  padding-top: 32px;
}
.benefit-stat[_ngcontent-%COMP%]   .bnum[_ngcontent-%COMP%] {
  font-family: var(--display);
  font-weight: 600;
  font-size: clamp(36px, 4.5vw, 64px);
  letter-spacing: -0.04em;
  line-height: 1;
  color: var(--accent);
}
.benefit-stat[_ngcontent-%COMP%]   .blabel[_ngcontent-%COMP%] {
  font-size: 13px;
  color: var(--fg-3);
  margin-top: 8px;
  line-height: 1.4;
}
@media (max-width: 720px) {
  .benefit-stats[_ngcontent-%COMP%] {
    grid-template-columns: repeat(2, 1fr);
  }
}
.roi-card[_ngcontent-%COMP%] {
  background: var(--bg-2);
  border: 1px solid var(--line);
  border-radius: 16px;
  padding: 40px;
  margin-top: 48px;
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 48px;
  align-items: center;
}
@media (max-width: 880px) {
  .roi-card[_ngcontent-%COMP%] {
    grid-template-columns: 1fr;
    padding: 28px;
    gap: 32px;
  }
}
.roi-result[_ngcontent-%COMP%] {
  background: var(--bg-3);
  border-radius: 10px;
  padding: 28px;
  border: 1px solid var(--line);
}
.roi-big[_ngcontent-%COMP%] {
  font-family: var(--display);
  font-weight: 600;
  font-size: clamp(48px, 6vw, 84px);
  letter-spacing: -0.04em;
  line-height: 1;
  color: var(--accent);
}
.roi-label[_ngcontent-%COMP%] {
  font-family: var(--mono);
  font-size: 11px;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: var(--fg-3);
  margin-bottom: 12px;
}
.roi-line[_ngcontent-%COMP%] {
  display: flex;
  justify-content: space-between;
  font-size: 14px;
  padding: 10px 0;
  border-bottom: 1px solid var(--line);
}
.roi-line[_ngcontent-%COMP%]:last-child {
  border-bottom: none;
  color: var(--accent);
  padding-top: 12px;
  border-top: 1px solid var(--line);
}
.roi-line[_ngcontent-%COMP%]   span[_ngcontent-%COMP%]:first-child {
  color: var(--fg-3);
}
.roi-line[_ngcontent-%COMP%]   span[_ngcontent-%COMP%]:last-child {
  font-family: var(--mono);
}
.input-row[_ngcontent-%COMP%] {
  display: flex;
  flex-direction: column;
  gap: 10px;
  margin-bottom: 20px;
}
.input-row[_ngcontent-%COMP%]   label[_ngcontent-%COMP%] {
  font-family: var(--mono);
  font-size: 11px;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: var(--fg-3);
  display: flex;
  justify-content: space-between;
}
.input-row[_ngcontent-%COMP%]   label[_ngcontent-%COMP%]   .val[_ngcontent-%COMP%] {
  color: var(--fg);
  font-weight: 600;
}
.slider[_ngcontent-%COMP%] {
  -webkit-appearance: none;
  appearance: none;
  width: 100%;
  height: 4px;
  background: var(--line-2);
  border-radius: 2px;
  outline: none;
}
.slider[_ngcontent-%COMP%]::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  width: 18px;
  height: 18px;
  border-radius: 50%;
  background: var(--accent);
  cursor: pointer;
  border: 3px solid var(--bg-2);
  box-shadow: 0 0 0 1px var(--accent);
}
.slider[_ngcontent-%COMP%]::-moz-range-thumb {
  width: 18px;
  height: 18px;
  border-radius: 50%;
  background: var(--accent);
  cursor: pointer;
  border: 3px solid var(--bg-2);
}
.test-wrap[_ngcontent-%COMP%] {
  margin-top: 48px;
}
.test-card[_ngcontent-%COMP%] {
  background: var(--bg-2);
  border: 1px solid var(--line);
  border-radius: 16px;
  padding: 48px;
  min-height: 260px;
}
.test-quote[_ngcontent-%COMP%] {
  font-family: var(--display);
  font-weight: 500;
  font-size: clamp(20px, 2.2vw, 28px);
  letter-spacing: -0.02em;
  line-height: 1.25;
}
.test-quote[_ngcontent-%COMP%]::before {
  content: '"';
  color: var(--accent);
}
.test-meta[_ngcontent-%COMP%] {
  margin-top: 28px;
  display: flex;
  align-items: center;
  gap: 14px;
}
.test-avatar[_ngcontent-%COMP%] {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  background:
    linear-gradient(
      135deg,
      #444,
      #222);
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
  color: var(--fg);
  font-family: var(--mono);
  font-size: 13px;
}
.test-meta[_ngcontent-%COMP%]   .tname[_ngcontent-%COMP%] {
  font-weight: 600;
}
.test-meta[_ngcontent-%COMP%]   .trole[_ngcontent-%COMP%] {
  color: var(--fg-3);
  font-size: 13px;
}
.test-nav[_ngcontent-%COMP%] {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 24px;
}
.test-dots[_ngcontent-%COMP%] {
  display: flex;
  gap: 8px;
}
.test-dot[_ngcontent-%COMP%] {
  width: 24px;
  height: 4px;
  background: var(--line-2);
  border-radius: 2px;
  cursor: pointer;
  transition: background 200ms ease;
  border: none;
  padding: 0;
}
.test-dot.active[_ngcontent-%COMP%] {
  background: var(--accent);
}
.test-arrows[_ngcontent-%COMP%] {
  display: flex;
  gap: 8px;
}
.test-arrow[_ngcontent-%COMP%] {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  border: 1px solid var(--line-2);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--fg);
  transition: border-color 200ms ease;
}
.test-arrow[_ngcontent-%COMP%]:hover {
  border-color: var(--fg);
}
.pricing-card[_ngcontent-%COMP%] {
  background: var(--bg-2);
  border: 1px solid var(--line);
  border-radius: 24px;
  padding: 48px;
  max-width: 720px;
  margin: 64px auto 0;
  position: relative;
  overflow: hidden;
}
.pricing-card[_ngcontent-%COMP%]::before {
  content: "";
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 4px;
  background: var(--accent);
}
.pricing-head[_ngcontent-%COMP%] {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  flex-wrap: wrap;
  gap: 16px;
}
.toggle-period[_ngcontent-%COMP%] {
  display: inline-flex;
  background: var(--bg-3);
  border: 1px solid var(--line);
  border-radius: 999px;
  padding: 4px;
  font-family: var(--mono);
  font-size: 12px;
}
.toggle-period[_ngcontent-%COMP%]   button[_ngcontent-%COMP%] {
  padding: 8px 18px;
  border-radius: 999px;
  letter-spacing: 0.05em;
  text-transform: uppercase;
  color: var(--fg-3);
  transition: background 200ms ease, color 200ms ease;
}
.toggle-period[_ngcontent-%COMP%]   button.active[_ngcontent-%COMP%] {
  background: var(--accent);
  color: #0a0a0a;
  font-weight: 600;
}
.save[_ngcontent-%COMP%] {
  color: var(--good);
  margin-left: 6px;
  font-size: 10px;
}
.toggle-period[_ngcontent-%COMP%]   button.active[_ngcontent-%COMP%]   .save[_ngcontent-%COMP%] {
  color: #0a0a0a;
}
.price-was[_ngcontent-%COMP%] {
  color: var(--fg-3);
  text-decoration: line-through;
  font-size: 14px;
  font-family: var(--mono);
  margin: 20px 0 4px;
}
.price-row[_ngcontent-%COMP%] {
  display: flex;
  align-items: baseline;
  gap: 8px;
  margin-bottom: 8px;
}
.price-amount[_ngcontent-%COMP%] {
  font-family: var(--display);
  font-weight: 600;
  font-size: clamp(56px, 7vw, 96px);
  letter-spacing: -0.04em;
  line-height: 1;
}
.price-currency[_ngcontent-%COMP%] {
  font-size: 24px;
  font-weight: 500;
  color: var(--fg-2);
}
.price-period[_ngcontent-%COMP%] {
  font-size: 16px;
  color: var(--fg-3);
}
.feature-list[_ngcontent-%COMP%] {
  margin-top: 32px;
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 14px 28px;
  list-style: none;
  padding: 0;
}
.feature-list[_ngcontent-%COMP%]   li[_ngcontent-%COMP%] {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 14px;
  color: var(--fg-2);
}
.fcheck[_ngcontent-%COMP%] {
  color: var(--accent);
  flex-shrink: 0;
}
@media (max-width: 720px) {
  .feature-list[_ngcontent-%COMP%] {
    grid-template-columns: 1fr;
  }
  .pricing-card[_ngcontent-%COMP%] {
    padding: 28px;
  }
}
.pricing-cta[_ngcontent-%COMP%] {
  margin-top: 36px;
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
  align-items: center;
}
.pricing-fine[_ngcontent-%COMP%] {
  margin-top: 16px;
  font-size: 12px;
  color: var(--fg-3);
  font-family: var(--mono);
  letter-spacing: 0.05em;
}
.final-cta[_ngcontent-%COMP%] {
  text-align: center;
  padding: 160px 0;
  border-top: 1px solid var(--line);
}
.urgency[_ngcontent-%COMP%] {
  margin-bottom: 24px;
  font-family: var(--mono);
  font-size: 12px;
  color: var(--fg-3);
  letter-spacing: 0.08em;
  text-transform: uppercase;
}
.urgency[_ngcontent-%COMP%]   .dot[_ngcontent-%COMP%] {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--good);
  display: inline-block;
  margin-right: 8px;
  animation: _ngcontent-%COMP%_pulse 2s infinite;
  vertical-align: middle;
}
.final-cta-actions[_ngcontent-%COMP%] {
  display: flex;
  gap: 12px;
  justify-content: center;
  flex-wrap: wrap;
  margin-top: 32px;
}
.final-fine[_ngcontent-%COMP%] {
  margin-top: 20px;
  font-size: 13px;
  color: var(--fg-3);
}
.footer[_ngcontent-%COMP%] {
  border-top: 1px solid var(--line);
  padding: 48px 0;
  font-size: 13px;
  color: var(--fg-3);
}
.footer-inner[_ngcontent-%COMP%] {
  display: grid;
  grid-template-columns: 1fr auto 1fr;
  gap: 24px;
  align-items: center;
}
.footer-links[_ngcontent-%COMP%] {
  display: flex;
  gap: 16px;
  justify-content: flex-end;
}
.footer-links[_ngcontent-%COMP%]   a[_ngcontent-%COMP%]:hover {
  color: var(--fg);
}
@media (max-width: 720px) {
  .footer-inner[_ngcontent-%COMP%] {
    grid-template-columns: 1fr;
    gap: 16px;
    text-align: center;
  }
  .footer-links[_ngcontent-%COMP%] {
    justify-content: center;
  }
}
[data-reveal][_ngcontent-%COMP%] {
  opacity: 0;
  transform: translateY(24px);
  transition: opacity 800ms cubic-bezier(0.16, 1, 0.3, 1), transform 800ms cubic-bezier(0.16, 1, 0.3, 1);
}
[data-reveal].in[_ngcontent-%COMP%] {
  opacity: 1;
  transform: translateY(0);
}
/*# sourceMappingURL=landing.component.css.map */`] });
  }
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && \u0275setClassDebugInfo(LandingComponent, { className: "LandingComponent" });
})();
export {
  LandingComponent
};
//# sourceMappingURL=chunk-GTTOD2U6.js.map
