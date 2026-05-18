import {
  ModeloContratoService
} from "./chunk-KEFB7QAL.js";
import {
  DefaultValueAccessor,
  FormsModule,
  NgControlStatus,
  NgModel
} from "./chunk-JQJL26HT.js";
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
  ɵɵtemplate,
  ɵɵtext,
  ɵɵtextInterpolate,
  ɵɵtextInterpolate1
} from "./chunk-WZ2AWGAJ.js";
import "./chunk-7G5TR5RR.js";

// src/app/features/contratos/pages/modelos/contratos-modelos.component.ts
var _forTrack0 = ($index, $item) => $item.id;
var _c0 = () => [1, 2];
function ContratosModelosComponent_Conditional_14_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 9);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(ctx_r0.erro());
  }
}
function ContratosModelosComponent_For_20_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "code", 13);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const v_r2 = ctx.$implicit;
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(v_r2);
  }
}
function ContratosModelosComponent_Conditional_21_For_2_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275element(0, "div", 15);
  }
}
function ContratosModelosComponent_Conditional_21_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 14);
    \u0275\u0275repeaterCreate(1, ContratosModelosComponent_Conditional_21_For_2_Template, 1, 0, "div", 15, \u0275\u0275repeaterTrackByIdentity);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    \u0275\u0275advance();
    \u0275\u0275repeater(\u0275\u0275pureFunction0(0, _c0));
  }
}
function ContratosModelosComponent_Conditional_22_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 16);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(1, "svg", 17);
    \u0275\u0275element(2, "path", 18)(3, "polyline", 19);
    \u0275\u0275elementEnd();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(4, "p", 20);
    \u0275\u0275text(5, "Nenhum modelo cadastrado");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(6, "p", 21);
    \u0275\u0275text(7, "Ao criar um contrato sem modelo selecionado, o template padr\xE3o \xE9 usado.");
    \u0275\u0275elementEnd()();
  }
}
function ContratosModelosComponent_Conditional_23_For_2_Template(rf, ctx) {
  if (rf & 1) {
    const _r3 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 23)(1, "div", 24)(2, "div", 25);
    \u0275\u0275text(3);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(4, "div", 26);
    \u0275\u0275text(5);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(6, "div", 27)(7, "button", 28);
    \u0275\u0275listener("click", function ContratosModelosComponent_Conditional_23_For_2_Template_button_click_7_listener() {
      const m_r4 = \u0275\u0275restoreView(_r3).$implicit;
      const ctx_r0 = \u0275\u0275nextContext(2);
      return \u0275\u0275resetView(ctx_r0.abrirEditar(m_r4));
    });
    \u0275\u0275text(8, "Editar");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(9, "button", 29);
    \u0275\u0275listener("click", function ContratosModelosComponent_Conditional_23_For_2_Template_button_click_9_listener() {
      const m_r4 = \u0275\u0275restoreView(_r3).$implicit;
      const ctx_r0 = \u0275\u0275nextContext(2);
      return \u0275\u0275resetView(ctx_r0.excluir(m_r4));
    });
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(10, "svg", 6);
    \u0275\u0275element(11, "polyline", 30)(12, "path", 31)(13, "path", 32)(14, "path", 33)(15, "path", 34);
    \u0275\u0275elementEnd()()()();
  }
  if (rf & 2) {
    const m_r4 = ctx.$implicit;
    const ctx_r0 = \u0275\u0275nextContext(2);
    \u0275\u0275advance(3);
    \u0275\u0275textInterpolate(m_r4.nome);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate1("Criado em ", ctx_r0.formatarData(m_r4.criadoEm), "");
  }
}
function ContratosModelosComponent_Conditional_23_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 22);
    \u0275\u0275repeaterCreate(1, ContratosModelosComponent_Conditional_23_For_2_Template, 16, 2, "div", 23, _forTrack0);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance();
    \u0275\u0275repeater(ctx_r0.modelos());
  }
}
function ContratosModelosComponent_Conditional_24_Conditional_7_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 39);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext(2);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(ctx_r0.erroSalvar());
  }
}
function ContratosModelosComponent_Conditional_24_Conditional_8_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 40);
    \u0275\u0275text(1, "\u2713 Salvo com sucesso!");
    \u0275\u0275elementEnd();
  }
}
function ContratosModelosComponent_Conditional_24_Template(rf, ctx) {
  if (rf & 1) {
    const _r5 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 35);
    \u0275\u0275listener("click", function ContratosModelosComponent_Conditional_24_Template_div_click_0_listener() {
      \u0275\u0275restoreView(_r5);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.fecharModal());
    });
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(1, "div", 36)(2, "div", 37)(3, "h3");
    \u0275\u0275text(4);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(5, "button", 38);
    \u0275\u0275listener("click", function ContratosModelosComponent_Conditional_24_Template_button_click_5_listener() {
      \u0275\u0275restoreView(_r5);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.fecharModal());
    });
    \u0275\u0275text(6, "\u2715");
    \u0275\u0275elementEnd()();
    \u0275\u0275template(7, ContratosModelosComponent_Conditional_24_Conditional_7_Template, 2, 1, "div", 39)(8, ContratosModelosComponent_Conditional_24_Conditional_8_Template, 2, 0, "div", 40);
    \u0275\u0275elementStart(9, "div", 41)(10, "div", 42)(11, "label", 43);
    \u0275\u0275text(12, "Nome do modelo *");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(13, "input", 44);
    \u0275\u0275listener("ngModelChange", function ContratosModelosComponent_Conditional_24_Template_input_ngModelChange_13_listener($event) {
      \u0275\u0275restoreView(_r5);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.formNome.set($event));
    });
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(14, "div", 45)(15, "label", 43);
    \u0275\u0275text(16, "Conte\xFAdo HTML *");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(17, "textarea", 46);
    \u0275\u0275listener("ngModelChange", function ContratosModelosComponent_Conditional_24_Template_textarea_ngModelChange_17_listener($event) {
      \u0275\u0275restoreView(_r5);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.formConteudo.set($event));
    });
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(18, "div", 47)(19, "button", 48);
    \u0275\u0275listener("click", function ContratosModelosComponent_Conditional_24_Template_button_click_19_listener() {
      \u0275\u0275restoreView(_r5);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.fecharModal());
    });
    \u0275\u0275text(20, "Cancelar");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(21, "button", 49);
    \u0275\u0275listener("click", function ContratosModelosComponent_Conditional_24_Template_button_click_21_listener() {
      \u0275\u0275restoreView(_r5);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.salvar());
    });
    \u0275\u0275text(22);
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance(4);
    \u0275\u0275textInterpolate(ctx_r0.editando() ? "Editar modelo" : "Novo modelo");
    \u0275\u0275advance(3);
    \u0275\u0275conditional(7, ctx_r0.erroSalvar() ? 7 : -1);
    \u0275\u0275advance();
    \u0275\u0275conditional(8, ctx_r0.salvoOk() ? 8 : -1);
    \u0275\u0275advance(5);
    \u0275\u0275property("ngModel", ctx_r0.formNome());
    \u0275\u0275advance(4);
    \u0275\u0275property("ngModel", ctx_r0.formConteudo());
    \u0275\u0275advance(4);
    \u0275\u0275property("disabled", ctx_r0.salvando());
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1(" ", ctx_r0.salvando() ? "Salvando..." : "Salvar modelo", " ");
  }
}
var VARIAVEIS = [
  "{{nomeAluno}}",
  "{{email}}",
  "{{telefone}}",
  "{{dataNascimento}}",
  "{{plano}}",
  "{{valor}}",
  "{{modalidade}}",
  "{{dataInicio}}",
  "{{dataFim}}",
  "{{academia}}",
  "{{cnpj}}",
  "{{dataContrato}}"
];
var TEMPLATE_PADRAO = `<h2>Contrato de Presta\xE7\xE3o de Servi\xE7os</h2>
<p><strong>Academia:</strong> {{academia}} &nbsp;|&nbsp; <strong>CNPJ:</strong> {{cnpj}}</p>
<p><strong>Data:</strong> {{dataContrato}}</p>
<hr/>
<h3>Dados do Aluno</h3>
<p><strong>Nome:</strong> {{nomeAluno}}</p>
<p><strong>E-mail:</strong> {{email}}</p>
<p><strong>Telefone:</strong> {{telefone}}</p>
<p><strong>Data de Nascimento:</strong> {{dataNascimento}}</p>
<hr/>
<h3>Plano Contratado</h3>
<p><strong>Plano:</strong> {{plano}}</p>
<p><strong>Modalidade:</strong> {{modalidade}}</p>
<p><strong>Valor Mensal:</strong> {{valor}}</p>
<p><strong>In\xEDcio:</strong> {{dataInicio}}</p>
<hr/>
<h3>Cl\xE1usulas</h3>
<p>1. O aluno se compromete a cumprir as normas internas da academia.</p>
<p>2. O pagamento da mensalidade dever\xE1 ser efetuado at\xE9 o vencimento acordado.</p>
<p>3. A academia se reserva o direito de suspender o acesso em caso de inadimpl\xEAncia.</p>
<p>4. O cancelamento dever\xE1 ser solicitado com 30 dias de anteced\xEAncia.</p>
<p>Ao assinar este contrato digitalmente, o aluno declara ter lido e concordado com todos os termos acima.</p>
<hr/>
<div style="margin-top:32px;">
  <p><strong>{{academia}}</strong></p>
  <p>CNPJ: {{cnpj}}</p>
</div>`;
var ContratosModelosComponent = class _ContratosModelosComponent {
  constructor() {
    this.modeloService = inject(ModeloContratoService);
    this.variaveis = VARIAVEIS;
    this.carregando = signal(true);
    this.modelos = signal([]);
    this.erro = signal("");
    this.modalAberto = signal(false);
    this.editando = signal(null);
    this.salvando = signal(false);
    this.erroSalvar = signal("");
    this.salvoOk = signal(false);
    this.formNome = signal("");
    this.formConteudo = signal("");
  }
  ngOnInit() {
    this.carregar();
  }
  carregar() {
    this.carregando.set(true);
    this.modeloService.listar().subscribe({
      next: (res) => {
        this.modelos.set(res.dados ?? []);
        this.carregando.set(false);
      },
      error: () => {
        this.erro.set("Erro ao carregar modelos.");
        this.carregando.set(false);
      }
    });
  }
  abrirNovo() {
    this.editando.set(null);
    this.formNome.set("");
    this.formConteudo.set(TEMPLATE_PADRAO);
    this.erroSalvar.set("");
    this.salvoOk.set(false);
    this.modalAberto.set(true);
  }
  abrirEditar(m) {
    this.editando.set(m);
    this.formNome.set(m.nome);
    this.formConteudo.set(m.conteudoHtml);
    this.erroSalvar.set("");
    this.salvoOk.set(false);
    this.modalAberto.set(true);
  }
  fecharModal() {
    this.modalAberto.set(false);
  }
  salvar() {
    if (!this.formNome().trim()) {
      this.erroSalvar.set("Informe o nome do modelo.");
      return;
    }
    if (!this.formConteudo().trim()) {
      this.erroSalvar.set("O conte\xFAdo n\xE3o pode estar vazio.");
      return;
    }
    this.salvando.set(true);
    this.erroSalvar.set("");
    const dados = { nome: this.formNome(), conteudoHtml: this.formConteudo() };
    const req = this.editando() ? this.modeloService.atualizar(this.editando().id, dados) : this.modeloService.criar(dados);
    req.subscribe({
      next: (res) => {
        this.salvando.set(false);
        if (res.sucesso) {
          this.salvoOk.set(true);
          this.carregar();
          setTimeout(() => this.fecharModal(), 900);
        } else
          this.erroSalvar.set(res.mensagem ?? "Erro ao salvar.");
      },
      error: (err) => {
        this.salvando.set(false);
        this.erroSalvar.set(err.error?.mensagem ?? "Erro ao salvar.");
      }
    });
  }
  excluir(m) {
    if (!confirm(`Excluir o modelo "${m.nome}"?`))
      return;
    this.modeloService.excluir(m.id).subscribe({ next: () => this.carregar() });
  }
  formatarData(d) {
    return new Date(d).toLocaleDateString("pt-BR");
  }
  static {
    this.\u0275fac = function ContratosModelosComponent_Factory(t) {
      return new (t || _ContratosModelosComponent)();
    };
  }
  static {
    this.\u0275cmp = /* @__PURE__ */ \u0275\u0275defineComponent({ type: _ContratosModelosComponent, selectors: [["app-contratos-modelos"]], standalone: true, features: [\u0275\u0275StandaloneFeature], decls: 25, vars: 3, consts: [[1, "page-container", 2, "max-width", "900px"], [1, "page-header"], ["routerLink", "/app/contratos", 1, "back-link"], [1, "page-title"], [1, "page-subtitle"], [1, "btn-primary", 3, "click"], ["width", "14", "height", "14", "fill", "none", "stroke", "currentColor", "stroke-width", "2", "viewBox", "0 0 24 24"], ["x1", "12", "y1", "5", "x2", "12", "y2", "19"], ["x1", "5", "y1", "12", "x2", "19", "y2", "12"], [1, "alert-error"], [1, "variaveis-card"], [2, "font-size", "12px", "font-weight", "600", "color", "var(--app-text-2)", "margin", "0 0 8px"], [1, "variaveis-grid"], [1, "variavel-chip"], [1, "skeleton-list"], [1, "skeleton-row", 2, "height", "70px"], [1, "empty-state"], ["width", "40", "height", "40", "fill", "none", "stroke", "currentColor", "stroke-width", "1.5", "viewBox", "0 0 24 24", 2, "color", "var(--app-text-3)", "margin-bottom", "12px"], ["d", "M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"], ["points", "14 2 14 8 20 8"], [2, "font-weight", "600", "color", "var(--app-text-2)", "margin", "0 0 4px"], [2, "font-size", "13px", "color", "var(--app-text-3)", "margin", "0"], [1, "modelos-lista"], [1, "modelo-card"], [1, "modelo-info"], [1, "modelo-nome"], [1, "modelo-meta"], [1, "modelo-acoes"], [1, "btn-secondary", 2, "font-size", "12px", "padding", "6px 12px", 3, "click"], ["title", "Excluir modelo", 1, "btn-icon", "btn-danger", 3, "click"], ["points", "3 6 5 6 21 6"], ["d", "M19 6l-1 14H6L5 6"], ["d", "M10 11v6"], ["d", "M14 11v6"], ["d", "M9 6V4h6v2"], [1, "modal-backdrop", 3, "click"], [1, "modal", "modal-wide"], [1, "modal-header"], [1, "modal-close", 3, "click"], [1, "alert-error", 2, "margin", "0 0 12px"], [1, "alert-success", 2, "margin", "0 0 12px"], [1, "modal-body"], [1, "form-group"], [1, "form-label"], ["placeholder", "Ex: Contrato BJJ, Contrato Muay Thai...", 1, "form-input", 3, "ngModelChange", "ngModel"], [1, "form-group", 2, "margin-top", "12px"], ["rows", "20", "placeholder", "Cole ou escreva o HTML do contrato...", 1, "form-input", "template-textarea", 3, "ngModelChange", "ngModel"], [1, "modal-actions"], [1, "btn-secondary", 3, "click"], [1, "btn-primary", 3, "click", "disabled"]], template: function ContratosModelosComponent_Template(rf, ctx) {
      if (rf & 1) {
        \u0275\u0275elementStart(0, "div", 0)(1, "div", 1)(2, "div")(3, "a", 2);
        \u0275\u0275text(4, "\u2190 Contratos");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(5, "h1", 3);
        \u0275\u0275text(6, "Modelos de Contrato");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(7, "p", 4);
        \u0275\u0275text(8, "Crie N modelos para diferentes modalidades e planos");
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(9, "button", 5);
        \u0275\u0275listener("click", function ContratosModelosComponent_Template_button_click_9_listener() {
          return ctx.abrirNovo();
        });
        \u0275\u0275namespaceSVG();
        \u0275\u0275elementStart(10, "svg", 6);
        \u0275\u0275element(11, "line", 7)(12, "line", 8);
        \u0275\u0275elementEnd();
        \u0275\u0275text(13, " Novo modelo ");
        \u0275\u0275elementEnd()();
        \u0275\u0275template(14, ContratosModelosComponent_Conditional_14_Template, 2, 1, "div", 9);
        \u0275\u0275namespaceHTML();
        \u0275\u0275elementStart(15, "div", 10)(16, "p", 11);
        \u0275\u0275text(17, "Vari\xE1veis dispon\xEDveis para usar nos templates:");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(18, "div", 12);
        \u0275\u0275repeaterCreate(19, ContratosModelosComponent_For_20_Template, 2, 1, "code", 13, \u0275\u0275repeaterTrackByIdentity);
        \u0275\u0275elementEnd()();
        \u0275\u0275template(21, ContratosModelosComponent_Conditional_21_Template, 3, 1, "div", 14)(22, ContratosModelosComponent_Conditional_22_Template, 8, 0)(23, ContratosModelosComponent_Conditional_23_Template, 3, 0);
        \u0275\u0275elementEnd();
        \u0275\u0275template(24, ContratosModelosComponent_Conditional_24_Template, 23, 7);
      }
      if (rf & 2) {
        \u0275\u0275advance(14);
        \u0275\u0275conditional(14, ctx.erro() ? 14 : -1);
        \u0275\u0275advance(5);
        \u0275\u0275repeater(ctx.variaveis);
        \u0275\u0275advance(2);
        \u0275\u0275conditional(21, ctx.carregando() ? 21 : ctx.modelos().length === 0 ? 22 : 23);
        \u0275\u0275advance(3);
        \u0275\u0275conditional(24, ctx.modalAberto() ? 24 : -1);
      }
    }, dependencies: [CommonModule, FormsModule, DefaultValueAccessor, NgControlStatus, NgModel, RouterLink], styles: [".back-link[_ngcontent-%COMP%] { font-size: 13px; color: var(--app-text-3); text-decoration: none; display: inline-block; margin-bottom: 4px; }\n  .back-link[_ngcontent-%COMP%]:hover { color: var(--app-text-1); }\n\n  .variaveis-card[_ngcontent-%COMP%] { background: var(--app-surface); border: 1px solid var(--app-border); border-radius: 10px; padding: 14px 16px; margin-bottom: 20px; }\n  .variaveis-grid[_ngcontent-%COMP%] { display: flex; flex-wrap: wrap; gap: 6px; }\n  .variavel-chip[_ngcontent-%COMP%] { background: rgba(99,102,241,0.08); border: 1px solid rgba(99,102,241,0.2); color: #6366f1; font-size: 11px; font-family: monospace; padding: 3px 8px; border-radius: 4px; }\n\n  .empty-state[_ngcontent-%COMP%] { text-align: center; padding: 48px; background: var(--app-surface); border: 1px solid var(--app-border); border-radius: 12px; display: flex; flex-direction: column; align-items: center; }\n\n  .modelos-lista[_ngcontent-%COMP%] { display: flex; flex-direction: column; gap: 10px; }\n  .modelo-card[_ngcontent-%COMP%] { background: var(--app-surface); border: 1px solid var(--app-border); border-radius: 10px; padding: 14px 18px; display: flex; align-items: center; justify-content: space-between; gap: 12px; }\n  .modelo-nome[_ngcontent-%COMP%] { font-weight: 600; font-size: 14px; color: var(--app-text-1); }\n  .modelo-meta[_ngcontent-%COMP%] { font-size: 12px; color: var(--app-text-3); margin-top: 2px; }\n  .modelo-acoes[_ngcontent-%COMP%] { display: flex; gap: 8px; align-items: center; flex-shrink: 0; }\n\n  .btn-icon[_ngcontent-%COMP%] { background: none; border: none; cursor: pointer; padding: 6px; border-radius: 6px; color: var(--app-text-3); }\n  .btn-danger[_ngcontent-%COMP%]:hover { color: #dc2626; background: rgba(220,38,38,0.08); }\n\n  .modal-wide[_ngcontent-%COMP%] { width: min(860px, 95vw); max-height: 90vh; display: flex; flex-direction: column; }\n  .modal-wide[_ngcontent-%COMP%]   .modal-body[_ngcontent-%COMP%] { overflow-y: auto; flex: 1; }\n  .template-textarea[_ngcontent-%COMP%] { width: 100%; font-family: monospace; font-size: 12px; line-height: 1.6; resize: vertical; }\n\n  .alert-success[_ngcontent-%COMP%] { background: rgba(34,197,94,0.12); border: 1px solid rgba(34,197,94,0.3); color: #22c55e; padding: 10px 14px; border-radius: 8px; font-size: 13px; }"] });
  }
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && \u0275setClassDebugInfo(ContratosModelosComponent, { className: "ContratosModelosComponent" });
})();
export {
  ContratosModelosComponent
};
//# sourceMappingURL=chunk-WJ2SI7XC.js.map
