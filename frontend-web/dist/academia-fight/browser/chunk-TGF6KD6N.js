import {
  ModeloContratoService
} from "./chunk-KEFB7QAL.js";
import {
  ContratoService
} from "./chunk-AJ67XLLV.js";
import {
  DefaultValueAccessor,
  FormsModule,
  NgControlStatus,
  NgModel,
  NgSelectOption,
  SelectControlValueAccessor,
  ɵNgSelectMultipleOption
} from "./chunk-JQJL26HT.js";
import {
  AlunoService
} from "./chunk-ZSIQJU4D.js";
import "./chunk-Z5CKO2JM.js";
import {
  RouterLink
} from "./chunk-AXNOULNC.js";
import {
  CommonModule,
  NgClass,
  computed,
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
  ɵɵpureFunction1,
  ɵɵrepeater,
  ɵɵrepeaterCreate,
  ɵɵrepeaterTrackByIdentity,
  ɵɵresetView,
  ɵɵrestoreView,
  ɵɵtemplate,
  ɵɵtext,
  ɵɵtextInterpolate,
  ɵɵtextInterpolate1
} from "./chunk-WZ2AWGAJ.js";
import "./chunk-7G5TR5RR.js";

// src/app/features/contratos/pages/lista/contratos-lista.component.ts
var _forTrack0 = ($index, $item) => $item.id;
var _c0 = () => [1, 2, 3, 4];
var _c1 = (a0) => ["/app/contratos", a0];
function ContratosListaComponent_Conditional_5_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "p", 3);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1("", ctx_r0.contratosFiltrados().length, " contrato(s)");
  }
}
function ContratosListaComponent_Conditional_17_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 12);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(ctx_r0.erro());
  }
}
function ContratosListaComponent_Conditional_29_For_2_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275element(0, "div", 21);
  }
}
function ContratosListaComponent_Conditional_29_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 20);
    \u0275\u0275repeaterCreate(1, ContratosListaComponent_Conditional_29_For_2_Template, 1, 0, "div", 21, \u0275\u0275repeaterTrackByIdentity);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    \u0275\u0275advance();
    \u0275\u0275repeater(\u0275\u0275pureFunction0(0, _c0));
  }
}
function ContratosListaComponent_Conditional_30_Conditional_16_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "tr")(1, "td", 25);
    \u0275\u0275text(2, "Nenhum contrato encontrado.");
    \u0275\u0275elementEnd()();
  }
}
function ContratosListaComponent_Conditional_30_For_18_Conditional_13_Template(rf, ctx) {
  if (rf & 1) {
    const _r2 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "button", 31);
    \u0275\u0275listener("click", function ContratosListaComponent_Conditional_30_For_18_Conditional_13_Template_button_click_0_listener($event) {
      \u0275\u0275restoreView(_r2);
      const c_r3 = \u0275\u0275nextContext().$implicit;
      const ctx_r0 = \u0275\u0275nextContext(2);
      return \u0275\u0275resetView(ctx_r0.cancelarContrato(c_r3.id, $event));
    });
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(1, "svg", 6);
    \u0275\u0275element(2, "line", 32)(3, "line", 33);
    \u0275\u0275elementEnd()();
  }
}
function ContratosListaComponent_Conditional_30_For_18_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "tr", 24)(1, "td", 26);
    \u0275\u0275text(2);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "td")(4, "span", 27);
    \u0275\u0275text(5);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(6, "td", 28);
    \u0275\u0275text(7);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(8, "td", 28);
    \u0275\u0275text(9);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(10, "td", 28);
    \u0275\u0275text(11);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(12, "td", 29);
    \u0275\u0275template(13, ContratosListaComponent_Conditional_30_For_18_Conditional_13_Template, 4, 0, "button", 30);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    let tmp_17_0;
    const c_r3 = ctx.$implicit;
    const ctx_r0 = \u0275\u0275nextContext(2);
    \u0275\u0275property("routerLink", \u0275\u0275pureFunction1(8, _c1, c_r3.id));
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(c_r3.nomeAluno);
    \u0275\u0275advance(2);
    \u0275\u0275property("ngClass", ctx_r0.badgeClass(c_r3.status));
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(c_r3.statusLabel);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(ctx_r0.formatarData(c_r3.criadoEm));
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(ctx_r0.formatarData(c_r3.dataAssinatura));
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate((tmp_17_0 = c_r3.nomeAssinou) !== null && tmp_17_0 !== void 0 ? tmp_17_0 : "\u2014");
    \u0275\u0275advance(2);
    \u0275\u0275conditional(13, c_r3.status === 1 ? 13 : -1);
  }
}
function ContratosListaComponent_Conditional_30_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 22)(1, "table", 23)(2, "thead")(3, "tr")(4, "th");
    \u0275\u0275text(5, "Aluno");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(6, "th");
    \u0275\u0275text(7, "Status");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(8, "th");
    \u0275\u0275text(9, "Criado em");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(10, "th");
    \u0275\u0275text(11, "Assinado em");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(12, "th");
    \u0275\u0275text(13, "Assinado por");
    \u0275\u0275elementEnd();
    \u0275\u0275element(14, "th");
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(15, "tbody");
    \u0275\u0275template(16, ContratosListaComponent_Conditional_30_Conditional_16_Template, 3, 0, "tr");
    \u0275\u0275repeaterCreate(17, ContratosListaComponent_Conditional_30_For_18_Template, 14, 10, "tr", 24, _forTrack0);
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance(16);
    \u0275\u0275conditional(16, ctx_r0.contratosFiltrados().length === 0 ? 16 : -1);
    \u0275\u0275advance();
    \u0275\u0275repeater(ctx_r0.contratosFiltrados());
  }
}
function ContratosListaComponent_Conditional_31_Conditional_7_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 38);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext(2);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(ctx_r0.erroCriacao());
  }
}
function ContratosListaComponent_Conditional_31_For_16_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "option", 43);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const a_r5 = ctx.$implicit;
    \u0275\u0275property("value", a_r5.id);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(a_r5.nome);
  }
}
function ContratosListaComponent_Conditional_31_For_24_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "option", 43);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const m_r6 = ctx.$implicit;
    \u0275\u0275property("value", m_r6.id);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(m_r6.nome);
  }
}
function ContratosListaComponent_Conditional_31_Conditional_25_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 45);
    \u0275\u0275text(1, " Nenhum modelo cadastrado. ");
    \u0275\u0275elementStart(2, "a", 49);
    \u0275\u0275text(3, "Criar modelos");
    \u0275\u0275elementEnd()();
  }
}
function ContratosListaComponent_Conditional_31_Template(rf, ctx) {
  if (rf & 1) {
    const _r4 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 34);
    \u0275\u0275listener("click", function ContratosListaComponent_Conditional_31_Template_div_click_0_listener() {
      \u0275\u0275restoreView(_r4);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.fecharModalNovo());
    });
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(1, "div", 35)(2, "div", 36)(3, "h3");
    \u0275\u0275text(4, "Novo contrato");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(5, "button", 37);
    \u0275\u0275listener("click", function ContratosListaComponent_Conditional_31_Template_button_click_5_listener() {
      \u0275\u0275restoreView(_r4);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.fecharModalNovo());
    });
    \u0275\u0275text(6, "\u2715");
    \u0275\u0275elementEnd()();
    \u0275\u0275template(7, ContratosListaComponent_Conditional_31_Conditional_7_Template, 2, 1, "div", 38);
    \u0275\u0275elementStart(8, "div", 39)(9, "div", 40)(10, "label", 41);
    \u0275\u0275text(11, "Aluno *");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(12, "select", 42);
    \u0275\u0275listener("ngModelChange", function ContratosListaComponent_Conditional_31_Template_select_ngModelChange_12_listener($event) {
      \u0275\u0275restoreView(_r4);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.novoAlunoId.set($event));
    });
    \u0275\u0275elementStart(13, "option", 16);
    \u0275\u0275text(14, "Selecione um aluno...");
    \u0275\u0275elementEnd();
    \u0275\u0275repeaterCreate(15, ContratosListaComponent_Conditional_31_For_16_Template, 2, 2, "option", 43, _forTrack0);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(17, "div", 44)(18, "label", 41);
    \u0275\u0275text(19, "Modelo de contrato");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(20, "select", 42);
    \u0275\u0275listener("ngModelChange", function ContratosListaComponent_Conditional_31_Template_select_ngModelChange_20_listener($event) {
      \u0275\u0275restoreView(_r4);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.novoModeloId.set($event));
    });
    \u0275\u0275elementStart(21, "option", 16);
    \u0275\u0275text(22, "Template padr\xE3o da academia");
    \u0275\u0275elementEnd();
    \u0275\u0275repeaterCreate(23, ContratosListaComponent_Conditional_31_For_24_Template, 2, 2, "option", 43, _forTrack0);
    \u0275\u0275elementEnd();
    \u0275\u0275template(25, ContratosListaComponent_Conditional_31_Conditional_25_Template, 4, 0, "span", 45);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(26, "div", 46)(27, "button", 47);
    \u0275\u0275listener("click", function ContratosListaComponent_Conditional_31_Template_button_click_27_listener() {
      \u0275\u0275restoreView(_r4);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.fecharModalNovo());
    });
    \u0275\u0275text(28, "Cancelar");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(29, "button", 48);
    \u0275\u0275listener("click", function ContratosListaComponent_Conditional_31_Template_button_click_29_listener() {
      \u0275\u0275restoreView(_r4);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.criarContrato());
    });
    \u0275\u0275text(30);
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance(7);
    \u0275\u0275conditional(7, ctx_r0.erroCriacao() ? 7 : -1);
    \u0275\u0275advance(5);
    \u0275\u0275property("ngModel", ctx_r0.novoAlunoId());
    \u0275\u0275advance(3);
    \u0275\u0275repeater(ctx_r0.alunos());
    \u0275\u0275advance(5);
    \u0275\u0275property("ngModel", ctx_r0.novoModeloId());
    \u0275\u0275advance(3);
    \u0275\u0275repeater(ctx_r0.modelos());
    \u0275\u0275advance(2);
    \u0275\u0275conditional(25, ctx_r0.modelos().length === 0 ? 25 : -1);
    \u0275\u0275advance(4);
    \u0275\u0275property("disabled", ctx_r0.criando());
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1(" ", ctx_r0.criando() ? "Criando..." : "Criar contrato", " ");
  }
}
var ContratosListaComponent = class _ContratosListaComponent {
  constructor() {
    this.contratoService = inject(ContratoService);
    this.modeloService = inject(ModeloContratoService);
    this.alunoService = inject(AlunoService);
    this.carregando = signal(true);
    this.erro = signal("");
    this.contratos = signal([]);
    this.alunos = signal([]);
    this.modelos = signal([]);
    this.filtroStatus = signal("");
    this.filtroBusca = signal("");
    this.modalNovoAberto = signal(false);
    this.criando = signal(false);
    this.erroCriacao = signal("");
    this.novoAlunoId = signal("");
    this.novoModeloId = signal("");
    this.contratosFiltrados = computed(() => {
      let lista = this.contratos();
      const status = this.filtroStatus();
      const busca = this.filtroBusca().toLowerCase();
      if (status)
        lista = lista.filter((c) => String(c.status) === status);
      if (busca)
        lista = lista.filter((c) => c.nomeAluno.toLowerCase().includes(busca));
      return lista;
    });
  }
  ngOnInit() {
    this.carregarContratos();
    this.carregarAlunos();
    this.carregarModelos();
  }
  carregarContratos() {
    this.carregando.set(true);
    this.contratoService.listar().subscribe({
      next: (res) => {
        this.contratos.set(res.dados ?? []);
        this.carregando.set(false);
      },
      error: () => {
        this.erro.set("Erro ao carregar contratos.");
        this.carregando.set(false);
      }
    });
  }
  carregarAlunos() {
    this.alunoService.getAll({ ativo: true, pageSize: 500 }).subscribe({
      next: (res) => this.alunos.set(res.dados?.itens ?? [])
    });
  }
  carregarModelos() {
    this.modeloService.listar().subscribe({
      next: (res) => this.modelos.set(res.dados ?? [])
    });
  }
  abrirModalNovo() {
    this.novoAlunoId.set("");
    this.novoModeloId.set("");
    this.erroCriacao.set("");
    this.modalNovoAberto.set(true);
  }
  fecharModalNovo() {
    this.modalNovoAberto.set(false);
  }
  criarContrato() {
    if (!this.novoAlunoId()) {
      this.erroCriacao.set("Selecione um aluno.");
      return;
    }
    this.criando.set(true);
    this.erroCriacao.set("");
    this.contratoService.criar({
      alunoId: this.novoAlunoId(),
      modeloContratoId: this.novoModeloId() || void 0
    }).subscribe({
      next: (res) => {
        this.criando.set(false);
        if (res.sucesso) {
          this.fecharModalNovo();
          this.carregarContratos();
        } else
          this.erroCriacao.set(res.mensagem ?? "Erro ao criar contrato.");
      },
      error: (err) => {
        this.criando.set(false);
        this.erroCriacao.set(err.error?.mensagem ?? "Erro ao criar contrato.");
      }
    });
  }
  cancelarContrato(id, event) {
    event.stopPropagation();
    if (!confirm("Cancelar este contrato?"))
      return;
    this.contratoService.cancelar(id).subscribe({
      next: () => this.carregarContratos()
    });
  }
  badgeClass(status) {
    if (status === 2)
      return "badge-assinado";
    if (status === 3)
      return "badge-cancelado";
    return "badge-pendente";
  }
  formatarData(d) {
    if (!d)
      return "\u2014";
    return new Date(d).toLocaleDateString("pt-BR");
  }
  static {
    this.\u0275fac = function ContratosListaComponent_Factory(t) {
      return new (t || _ContratosListaComponent)();
    };
  }
  static {
    this.\u0275cmp = /* @__PURE__ */ \u0275\u0275defineComponent({ type: _ContratosListaComponent, selectors: [["app-contratos-lista"]], standalone: true, features: [\u0275\u0275StandaloneFeature], decls: 32, vars: 6, consts: [[1, "page-container"], [1, "page-header"], [1, "page-title"], [1, "page-subtitle"], [2, "display", "flex", "gap", "8px"], ["routerLink", "/app/contratos/modelos", 1, "btn-secondary"], ["width", "14", "height", "14", "fill", "none", "stroke", "currentColor", "stroke-width", "2", "viewBox", "0 0 24 24"], ["d", "M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"], ["points", "14 2 14 8 20 8"], [1, "btn-primary", 3, "click"], ["x1", "12", "y1", "5", "x2", "12", "y2", "19"], ["x1", "5", "y1", "12", "x2", "19", "y2", "12"], [1, "alert-error"], [1, "filtros-row"], ["placeholder", "Buscar por aluno...", 1, "form-input", "search-input", 2, "max-width", "260px", 3, "ngModelChange", "ngModel"], [1, "form-input", 2, "max-width", "160px", 3, "ngModelChange", "ngModel"], ["value", ""], ["value", "1"], ["value", "2"], ["value", "3"], [1, "skeleton-list"], [1, "skeleton-row"], [1, "table-wrapper"], [1, "data-table"], [1, "row-link", 3, "routerLink"], ["colspan", "6", 2, "text-align", "center", "padding", "32px", "color", "var(--app-text-3)"], [1, "font-medium"], [1, "badge", 3, "ngClass"], [2, "font-size", "13px"], [2, "text-align", "right"], ["title", "Cancelar contrato", 1, "btn-icon", "btn-danger"], ["title", "Cancelar contrato", 1, "btn-icon", "btn-danger", 3, "click"], ["x1", "18", "y1", "6", "x2", "6", "y2", "18"], ["x1", "6", "y1", "6", "x2", "18", "y2", "18"], [1, "modal-backdrop", 3, "click"], [1, "modal"], [1, "modal-header"], [1, "modal-close", 3, "click"], [1, "alert-error", 2, "margin", "0 0 12px"], [1, "modal-body"], [1, "form-group"], [1, "form-label"], [1, "form-input", 3, "ngModelChange", "ngModel"], [3, "value"], [1, "form-group", 2, "margin-top", "12px"], [2, "font-size", "11px", "color", "var(--app-text-3)", "margin-top", "4px", "display", "block"], [1, "modal-actions"], [1, "btn-secondary", 3, "click"], [1, "btn-primary", 3, "click", "disabled"], ["routerLink", "/app/contratos/modelos", 2, "color", "#6366f1"]], template: function ContratosListaComponent_Template(rf, ctx) {
      if (rf & 1) {
        \u0275\u0275elementStart(0, "div", 0)(1, "div", 1)(2, "div")(3, "h1", 2);
        \u0275\u0275text(4, "Contratos");
        \u0275\u0275elementEnd();
        \u0275\u0275template(5, ContratosListaComponent_Conditional_5_Template, 2, 1, "p", 3);
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(6, "div", 4)(7, "a", 5);
        \u0275\u0275namespaceSVG();
        \u0275\u0275elementStart(8, "svg", 6);
        \u0275\u0275element(9, "path", 7)(10, "polyline", 8);
        \u0275\u0275elementEnd();
        \u0275\u0275text(11, " Modelos ");
        \u0275\u0275elementEnd();
        \u0275\u0275namespaceHTML();
        \u0275\u0275elementStart(12, "button", 9);
        \u0275\u0275listener("click", function ContratosListaComponent_Template_button_click_12_listener() {
          return ctx.abrirModalNovo();
        });
        \u0275\u0275namespaceSVG();
        \u0275\u0275elementStart(13, "svg", 6);
        \u0275\u0275element(14, "line", 10)(15, "line", 11);
        \u0275\u0275elementEnd();
        \u0275\u0275text(16, " Novo contrato ");
        \u0275\u0275elementEnd()()();
        \u0275\u0275template(17, ContratosListaComponent_Conditional_17_Template, 2, 1, "div", 12);
        \u0275\u0275namespaceHTML();
        \u0275\u0275elementStart(18, "div", 13)(19, "input", 14);
        \u0275\u0275listener("ngModelChange", function ContratosListaComponent_Template_input_ngModelChange_19_listener($event) {
          return ctx.filtroBusca.set($event);
        });
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(20, "select", 15);
        \u0275\u0275listener("ngModelChange", function ContratosListaComponent_Template_select_ngModelChange_20_listener($event) {
          return ctx.filtroStatus.set($event);
        });
        \u0275\u0275elementStart(21, "option", 16);
        \u0275\u0275text(22, "Todos os status");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(23, "option", 17);
        \u0275\u0275text(24, "Pendente");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(25, "option", 18);
        \u0275\u0275text(26, "Assinado");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(27, "option", 19);
        \u0275\u0275text(28, "Cancelado");
        \u0275\u0275elementEnd()()();
        \u0275\u0275template(29, ContratosListaComponent_Conditional_29_Template, 3, 1, "div", 20)(30, ContratosListaComponent_Conditional_30_Template, 19, 1);
        \u0275\u0275elementEnd();
        \u0275\u0275template(31, ContratosListaComponent_Conditional_31_Template, 31, 6);
      }
      if (rf & 2) {
        \u0275\u0275advance(5);
        \u0275\u0275conditional(5, !ctx.carregando() ? 5 : -1);
        \u0275\u0275advance(12);
        \u0275\u0275conditional(17, ctx.erro() ? 17 : -1);
        \u0275\u0275advance(2);
        \u0275\u0275property("ngModel", ctx.filtroBusca());
        \u0275\u0275advance();
        \u0275\u0275property("ngModel", ctx.filtroStatus());
        \u0275\u0275advance(9);
        \u0275\u0275conditional(29, ctx.carregando() ? 29 : 30);
        \u0275\u0275advance(2);
        \u0275\u0275conditional(31, ctx.modalNovoAberto() ? 31 : -1);
      }
    }, dependencies: [CommonModule, NgClass, RouterLink, FormsModule, NgSelectOption, \u0275NgSelectMultipleOption, DefaultValueAccessor, SelectControlValueAccessor, NgControlStatus, NgModel], styles: [".filtros-row[_ngcontent-%COMP%] { display: flex; gap: 10px; margin-bottom: 16px; flex-wrap: wrap; }\n  .badge[_ngcontent-%COMP%] { font-size: 11px; font-weight: 600; padding: 3px 10px; border-radius: 99px; }\n  .badge-pendente[_ngcontent-%COMP%]  { background: rgba(245,158,11,0.12); color: #b45309; }\n  .badge-assinado[_ngcontent-%COMP%]  { background: rgba(34,197,94,0.12);  color: #15803d; }\n  .badge-cancelado[_ngcontent-%COMP%] { background: rgba(107,114,128,0.12); color: #6b7280; }\n  .row-link[_ngcontent-%COMP%] { cursor: pointer; }\n  .row-link[_ngcontent-%COMP%]:hover   td[_ngcontent-%COMP%] { background: var(--app-surface-hover, rgba(0,0,0,0.03)); }\n  .btn-icon[_ngcontent-%COMP%] { background: none; border: none; cursor: pointer; padding: 4px; border-radius: 4px; color: var(--app-text-3); }\n  .btn-danger[_ngcontent-%COMP%]:hover { color: #dc2626; background: rgba(220,38,38,0.08); }"] });
  }
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && \u0275setClassDebugInfo(ContratosListaComponent, { className: "ContratosListaComponent" });
})();
export {
  ContratosListaComponent
};
//# sourceMappingURL=chunk-TGF6KD6N.js.map
