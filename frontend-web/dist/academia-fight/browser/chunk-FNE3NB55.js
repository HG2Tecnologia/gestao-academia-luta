import {
  PlanoService
} from "./chunk-DTM3EMXS.js";
import {
  DefaultValueAccessor,
  FormBuilder,
  FormControlName,
  FormGroupDirective,
  FormsModule,
  MinValidator,
  NgControlStatus,
  NgControlStatusGroup,
  NumberValueAccessor,
  ReactiveFormsModule,
  Validators,
  ɵNgNoValidate
} from "./chunk-JQJL26HT.js";
import "./chunk-Z5CKO2JM.js";
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
  ɵɵtemplate,
  ɵɵtext,
  ɵɵtextInterpolate,
  ɵɵtextInterpolate1,
  ɵɵtextInterpolate2
} from "./chunk-WZ2AWGAJ.js";
import "./chunk-7G5TR5RR.js";

// src/app/features/planos/pages/lista/planos-lista.component.ts
var _forTrack0 = ($index, $item) => $item.id;
var _c0 = () => [1, 2, 3];
function PlanosListaComponent_Conditional_9_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 5);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(ctx_r0.erro());
  }
}
function PlanosListaComponent_Conditional_10_For_2_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275element(0, "div", 7);
  }
}
function PlanosListaComponent_Conditional_10_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 6);
    \u0275\u0275repeaterCreate(1, PlanosListaComponent_Conditional_10_For_2_Template, 1, 0, "div", 7, \u0275\u0275repeaterTrackByIdentity);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    \u0275\u0275advance();
    \u0275\u0275repeater(\u0275\u0275pureFunction0(0, _c0));
  }
}
function PlanosListaComponent_Conditional_11_Template(rf, ctx) {
  if (rf & 1) {
    const _r2 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 8);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(1, "svg", 9);
    \u0275\u0275element(2, "path", 10);
    \u0275\u0275elementEnd();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(3, "h3");
    \u0275\u0275text(4, "Nenhum plano criado");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(5, "p");
    \u0275\u0275text(6, "Crie o primeiro plano da academia para come\xE7ar a vincular alunos");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(7, "button", 4);
    \u0275\u0275listener("click", function PlanosListaComponent_Conditional_11_Template_button_click_7_listener() {
      \u0275\u0275restoreView(_r2);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.abrirNovo());
    });
    \u0275\u0275text(8, "Criar primeiro plano");
    \u0275\u0275elementEnd()();
  }
}
function PlanosListaComponent_Conditional_12_For_2_Conditional_5_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "p", 16);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const p_r4 = \u0275\u0275nextContext().$implicit;
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(p_r4.descricao);
  }
}
function PlanosListaComponent_Conditional_12_For_2_Conditional_19_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 24)(1, "span", 25);
    \u0275\u0275text(2, "Taxa de matr\xEDcula");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(3, "span", 26);
    \u0275\u0275text(4);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const p_r4 = \u0275\u0275nextContext().$implicit;
    const ctx_r0 = \u0275\u0275nextContext(2);
    \u0275\u0275advance(4);
    \u0275\u0275textInterpolate(ctx_r0.formatarMoeda(p_r4.taxaMatricula));
  }
}
function PlanosListaComponent_Conditional_12_For_2_Template(rf, ctx) {
  if (rf & 1) {
    const _r3 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 13)(1, "div", 14)(2, "div")(3, "div", 15);
    \u0275\u0275text(4);
    \u0275\u0275elementEnd();
    \u0275\u0275template(5, PlanosListaComponent_Conditional_12_For_2_Conditional_5_Template, 2, 1, "p", 16);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(6, "div", 17)(7, "button", 18);
    \u0275\u0275listener("click", function PlanosListaComponent_Conditional_12_For_2_Template_button_click_7_listener() {
      const p_r4 = \u0275\u0275restoreView(_r3).$implicit;
      const ctx_r0 = \u0275\u0275nextContext(2);
      return \u0275\u0275resetView(ctx_r0.abrirEditar(p_r4));
    });
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(8, "svg", 19);
    \u0275\u0275element(9, "path", 20);
    \u0275\u0275elementEnd()();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(10, "button", 21);
    \u0275\u0275listener("click", function PlanosListaComponent_Conditional_12_For_2_Template_button_click_10_listener() {
      const p_r4 = \u0275\u0275restoreView(_r3).$implicit;
      const ctx_r0 = \u0275\u0275nextContext(2);
      return \u0275\u0275resetView(ctx_r0.confirmarExcluir(p_r4));
    });
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(11, "svg", 19);
    \u0275\u0275element(12, "path", 22);
    \u0275\u0275elementEnd()()()();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(13, "div", 23)(14, "div", 24)(15, "span", 25);
    \u0275\u0275text(16, "Mensalidade");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(17, "span", 26);
    \u0275\u0275text(18);
    \u0275\u0275elementEnd()();
    \u0275\u0275template(19, PlanosListaComponent_Conditional_12_For_2_Conditional_19_Template, 5, 1, "div", 24);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(20, "div", 27)(21, "span", 28);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(22, "svg", 29);
    \u0275\u0275element(23, "path", 30);
    \u0275\u0275elementEnd();
    \u0275\u0275text(24);
    \u0275\u0275elementEnd();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(25, "button", 31);
    \u0275\u0275listener("click", function PlanosListaComponent_Conditional_12_For_2_Template_button_click_25_listener() {
      const p_r4 = \u0275\u0275restoreView(_r3).$implicit;
      const ctx_r0 = \u0275\u0275nextContext(2);
      return \u0275\u0275resetView(ctx_r0.toggleAtivo(p_r4));
    });
    \u0275\u0275text(26);
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    const p_r4 = ctx.$implicit;
    const ctx_r0 = \u0275\u0275nextContext(2);
    \u0275\u0275classProp("inativo", !p_r4.ativo);
    \u0275\u0275advance(4);
    \u0275\u0275textInterpolate(p_r4.nome);
    \u0275\u0275advance();
    \u0275\u0275conditional(5, p_r4.descricao ? 5 : -1);
    \u0275\u0275advance(13);
    \u0275\u0275textInterpolate(ctx_r0.formatarMoeda(p_r4.valorMensal));
    \u0275\u0275advance();
    \u0275\u0275conditional(19, p_r4.taxaMatricula ? 19 : -1);
    \u0275\u0275advance(5);
    \u0275\u0275textInterpolate2(" ", p_r4.totalAlunos, " ", p_r4.totalAlunos === 1 ? "aluno" : "alunos", " ");
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate1(" ", p_r4.ativo ? "Inativar" : "Reativar", " ");
  }
}
function PlanosListaComponent_Conditional_12_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 11);
    \u0275\u0275repeaterCreate(1, PlanosListaComponent_Conditional_12_For_2_Template, 27, 9, "div", 12, _forTrack0);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance();
    \u0275\u0275repeater(ctx_r0.planos());
  }
}
function PlanosListaComponent_Conditional_13_Conditional_13_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 43);
    \u0275\u0275text(1, "Nome \xE9 obrigat\xF3rio (m\xEDnimo 2 caracteres)");
    \u0275\u0275elementEnd();
  }
}
function PlanosListaComponent_Conditional_13_Conditional_23_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 43);
    \u0275\u0275text(1, "Informe o valor mensal");
    \u0275\u0275elementEnd();
  }
}
function PlanosListaComponent_Conditional_13_Conditional_28_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "p", 43);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext(2);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(ctx_r0.erroModal());
  }
}
function PlanosListaComponent_Conditional_13_Template(rf, ctx) {
  if (rf & 1) {
    const _r5 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 32);
    \u0275\u0275listener("click", function PlanosListaComponent_Conditional_13_Template_div_click_0_listener() {
      \u0275\u0275restoreView(_r5);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.fecharModal());
    });
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(1, "div", 33)(2, "div", 34)(3, "h2", 35);
    \u0275\u0275text(4);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(5, "button", 36);
    \u0275\u0275listener("click", function PlanosListaComponent_Conditional_13_Template_button_click_5_listener() {
      \u0275\u0275restoreView(_r5);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.fecharModal());
    });
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(6, "svg", 37);
    \u0275\u0275element(7, "path", 38);
    \u0275\u0275elementEnd()()();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(8, "form", 39);
    \u0275\u0275listener("ngSubmit", function PlanosListaComponent_Conditional_13_Template_form_ngSubmit_8_listener() {
      \u0275\u0275restoreView(_r5);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.salvar());
    });
    \u0275\u0275elementStart(9, "div", 40)(10, "label", 41);
    \u0275\u0275text(11, "Nome do plano *");
    \u0275\u0275elementEnd();
    \u0275\u0275element(12, "input", 42);
    \u0275\u0275template(13, PlanosListaComponent_Conditional_13_Conditional_13_Template, 2, 0, "span", 43);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(14, "div", 40)(15, "label", 41);
    \u0275\u0275text(16, "Descri\xE7\xE3o");
    \u0275\u0275elementEnd();
    \u0275\u0275element(17, "textarea", 44);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(18, "div", 45)(19, "div", 40)(20, "label", 41);
    \u0275\u0275text(21, "Valor mensal *");
    \u0275\u0275elementEnd();
    \u0275\u0275element(22, "input", 46);
    \u0275\u0275template(23, PlanosListaComponent_Conditional_13_Conditional_23_Template, 2, 0, "span", 43);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(24, "div", 40)(25, "label", 41);
    \u0275\u0275text(26, "Taxa de matr\xEDcula");
    \u0275\u0275elementEnd();
    \u0275\u0275element(27, "input", 47);
    \u0275\u0275elementEnd()();
    \u0275\u0275template(28, PlanosListaComponent_Conditional_13_Conditional_28_Template, 2, 1, "p", 43);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(29, "div", 48)(30, "button", 49);
    \u0275\u0275listener("click", function PlanosListaComponent_Conditional_13_Template_button_click_30_listener() {
      \u0275\u0275restoreView(_r5);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.fecharModal());
    });
    \u0275\u0275text(31, "Cancelar");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(32, "button", 50);
    \u0275\u0275listener("click", function PlanosListaComponent_Conditional_13_Template_button_click_32_listener() {
      \u0275\u0275restoreView(_r5);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.salvar());
    });
    \u0275\u0275text(33);
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    let tmp_3_0;
    let tmp_4_0;
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance(4);
    \u0275\u0275textInterpolate(ctx_r0.editandoId() ? "Editar plano" : "Novo plano");
    \u0275\u0275advance(4);
    \u0275\u0275property("formGroup", ctx_r0.form);
    \u0275\u0275advance(5);
    \u0275\u0275conditional(13, ((tmp_3_0 = ctx_r0.form.get("nome")) == null ? null : tmp_3_0.invalid) && ((tmp_3_0 = ctx_r0.form.get("nome")) == null ? null : tmp_3_0.touched) ? 13 : -1);
    \u0275\u0275advance(10);
    \u0275\u0275conditional(23, ((tmp_4_0 = ctx_r0.form.get("valorMensal")) == null ? null : tmp_4_0.invalid) && ((tmp_4_0 = ctx_r0.form.get("valorMensal")) == null ? null : tmp_4_0.touched) ? 23 : -1);
    \u0275\u0275advance(5);
    \u0275\u0275conditional(28, ctx_r0.erroModal() ? 28 : -1);
    \u0275\u0275advance(2);
    \u0275\u0275property("disabled", ctx_r0.salvando());
    \u0275\u0275advance(2);
    \u0275\u0275property("disabled", ctx_r0.salvando());
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1(" ", ctx_r0.salvando() ? "Salvando..." : ctx_r0.editandoId() ? "Salvar altera\xE7\xF5es" : "Criar plano", " ");
  }
}
function PlanosListaComponent_Conditional_14_Conditional_12_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "p", 43);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext(2);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(ctx_r0.erroExcluir());
  }
}
function PlanosListaComponent_Conditional_14_Template(rf, ctx) {
  if (rf & 1) {
    const _r6 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 32);
    \u0275\u0275listener("click", function PlanosListaComponent_Conditional_14_Template_div_click_0_listener() {
      \u0275\u0275restoreView(_r6);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.fecharExcluir());
    });
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(1, "div", 51)(2, "div", 52);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(3, "svg", 53);
    \u0275\u0275element(4, "path", 54);
    \u0275\u0275elementEnd()();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(5, "h3", 55);
    \u0275\u0275text(6, "Excluir plano?");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(7, "p", 56);
    \u0275\u0275text(8, " O plano ");
    \u0275\u0275elementStart(9, "strong");
    \u0275\u0275text(10);
    \u0275\u0275elementEnd();
    \u0275\u0275text(11, " ser\xE1 removido permanentemente. Isso falhar\xE1 se houver alunos vinculados a ele. ");
    \u0275\u0275elementEnd();
    \u0275\u0275template(12, PlanosListaComponent_Conditional_14_Conditional_12_Template, 2, 1, "p", 43);
    \u0275\u0275elementStart(13, "div", 57)(14, "button", 58);
    \u0275\u0275listener("click", function PlanosListaComponent_Conditional_14_Template_button_click_14_listener() {
      \u0275\u0275restoreView(_r6);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.fecharExcluir());
    });
    \u0275\u0275text(15, "Cancelar");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(16, "button", 59);
    \u0275\u0275listener("click", function PlanosListaComponent_Conditional_14_Template_button_click_16_listener() {
      \u0275\u0275restoreView(_r6);
      const ctx_r0 = \u0275\u0275nextContext();
      return \u0275\u0275resetView(ctx_r0.executarExcluir());
    });
    \u0275\u0275text(17);
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance(10);
    \u0275\u0275textInterpolate(ctx_r0.confirmandoExcluir().nome);
    \u0275\u0275advance(2);
    \u0275\u0275conditional(12, ctx_r0.erroExcluir() ? 12 : -1);
    \u0275\u0275advance(2);
    \u0275\u0275property("disabled", ctx_r0.excluindo());
    \u0275\u0275advance(2);
    \u0275\u0275property("disabled", ctx_r0.excluindo());
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1(" ", ctx_r0.excluindo() ? "Excluindo..." : "Excluir", " ");
  }
}
var PlanosListaComponent = class _PlanosListaComponent {
  constructor() {
    this.planoService = inject(PlanoService);
    this.fb = inject(FormBuilder);
    this.planos = signal([]);
    this.carregando = signal(true);
    this.erro = signal("");
    this.modalAberto = signal(false);
    this.editandoId = signal(null);
    this.salvando = signal(false);
    this.erroModal = signal("");
    this.confirmandoExcluir = signal(null);
    this.excluindo = signal(false);
    this.erroExcluir = signal("");
    this.form = this.fb.group({
      nome: ["", [Validators.required, Validators.minLength(2)]],
      descricao: [""],
      valorMensal: [null, [Validators.required, Validators.min(0.01)]],
      taxaMatricula: [null]
    });
  }
  ngOnInit() {
    this.carregar();
  }
  carregar() {
    this.carregando.set(true);
    this.planoService.listar().subscribe({
      next: (r) => {
        this.planos.set(r.dados ?? []);
        this.carregando.set(false);
      },
      error: () => {
        this.erro.set("Erro ao carregar planos.");
        this.carregando.set(false);
      }
    });
  }
  abrirNovo() {
    this.editandoId.set(null);
    this.erroModal.set("");
    this.form.reset({ nome: "", descricao: "", valorMensal: null, taxaMatricula: null });
    this.modalAberto.set(true);
  }
  abrirEditar(p) {
    this.editandoId.set(p.id);
    this.erroModal.set("");
    this.form.patchValue({ nome: p.nome, descricao: p.descricao ?? "", valorMensal: p.valorMensal, taxaMatricula: p.taxaMatricula ?? null });
    this.modalAberto.set(true);
  }
  fecharModal() {
    if (this.salvando())
      return;
    this.modalAberto.set(false);
  }
  salvar() {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    this.salvando.set(true);
    this.erroModal.set("");
    const v = this.form.value;
    const id = this.editandoId();
    const req$ = id ? this.planoService.atualizar(id, { nome: v.nome, descricao: v.descricao || void 0, valorMensal: v.valorMensal, taxaMatricula: v.taxaMatricula ?? void 0, ativo: true }) : this.planoService.criar({ nome: v.nome, descricao: v.descricao || void 0, valorMensal: v.valorMensal, taxaMatricula: v.taxaMatricula ?? void 0 });
    req$.subscribe({
      next: (r) => {
        if (!r.sucesso) {
          this.erroModal.set(r.mensagem ?? "Erro ao salvar.");
          this.salvando.set(false);
          return;
        }
        this.modalAberto.set(false);
        this.salvando.set(false);
        this.carregar();
      },
      error: (err) => {
        this.erroModal.set(err.error?.mensagem ?? "Erro ao salvar.");
        this.salvando.set(false);
      }
    });
  }
  toggleAtivo(p) {
    this.planoService.atualizar(p.id, { nome: p.nome, descricao: p.descricao, valorMensal: p.valorMensal, taxaMatricula: p.taxaMatricula ?? void 0, ativo: !p.ativo }).subscribe({
      next: () => this.carregar()
    });
  }
  confirmarExcluir(p) {
    this.erroExcluir.set("");
    this.confirmandoExcluir.set(p);
  }
  fecharExcluir() {
    if (this.excluindo())
      return;
    this.confirmandoExcluir.set(null);
  }
  formatarMoeda(valor) {
    return valor.toLocaleString("pt-BR", { style: "currency", currency: "BRL" });
  }
  executarExcluir() {
    const p = this.confirmandoExcluir();
    if (!p)
      return;
    this.excluindo.set(true);
    this.erroExcluir.set("");
    this.planoService.deletar(p.id).subscribe({
      next: (r) => {
        if (!r.sucesso) {
          this.erroExcluir.set(r.mensagem ?? "Erro ao excluir.");
          this.excluindo.set(false);
          return;
        }
        this.confirmandoExcluir.set(null);
        this.excluindo.set(false);
        this.carregar();
      },
      error: (err) => {
        this.erroExcluir.set(err.error?.mensagem ?? "N\xE3o \xE9 poss\xEDvel excluir: verifique se h\xE1 alunos vinculados.");
        this.excluindo.set(false);
      }
    });
  }
  static {
    this.\u0275fac = function PlanosListaComponent_Factory(t) {
      return new (t || _PlanosListaComponent)();
    };
  }
  static {
    this.\u0275cmp = /* @__PURE__ */ \u0275\u0275defineComponent({ type: _PlanosListaComponent, selectors: [["app-planos-lista"]], standalone: true, features: [\u0275\u0275StandaloneFeature], decls: 15, vars: 4, consts: [[1, "planos-page"], [1, "page-header"], [1, "page-title"], [1, "page-subtitle"], [1, "btn-primary", 3, "click"], [1, "alert-error"], [1, "skeleton-list"], [1, "skeleton-row", 2, "height", "120px", "border-radius", "12px"], [1, "empty-state"], ["width", "52", "height", "52", "fill", "none", "stroke", "currentColor", "stroke-width", "1.5", "viewBox", "0 0 24 24"], ["d", "M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"], [1, "planos-grid"], [1, "plano-card", 3, "inativo"], [1, "plano-card"], [1, "plano-top"], [1, "plano-nome"], [1, "plano-desc"], [1, "plano-acoes"], ["title", "Editar", 1, "btn-icon", 3, "click"], ["width", "14", "height", "14", "fill", "none", "stroke", "currentColor", "stroke-width", "2", "viewBox", "0 0 24 24"], ["d", "M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"], ["title", "Excluir", 1, "btn-icon", "btn-icon-danger", 3, "click"], ["d", "M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"], [1, "plano-valores"], [1, "valor-item"], [1, "valor-label"], [1, "valor-num"], [1, "plano-footer"], [1, "plano-alunos"], ["width", "13", "height", "13", "fill", "none", "stroke", "currentColor", "stroke-width", "2", "viewBox", "0 0 24 24", 2, "vertical-align", "-2px"], ["d", "M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z"], [1, "btn-toggle", 3, "click"], [1, "modal-backdrop", 3, "click"], ["role", "dialog", 1, "modal"], [1, "modal-header"], [1, "modal-titulo"], [1, "modal-fechar", 3, "click"], ["width", "18", "height", "18", "fill", "none", "stroke", "currentColor", "stroke-width", "2", "viewBox", "0 0 24 24"], ["d", "M6 18L18 6M6 6l12 12"], [1, "modal-body", 3, "ngSubmit", "formGroup"], [1, "form-field"], [1, "form-label"], ["formControlName", "nome", "placeholder", "Ex: Plano Mensal, Trimestral...", 1, "form-input"], [1, "form-erro"], ["formControlName", "descricao", "placeholder", "Descreva o que inclui este plano...", 1, "form-input", "form-textarea"], [1, "form-row"], ["formControlName", "valorMensal", "type", "number", "placeholder", "0,00", "min", "0", "step", "0.01", 1, "form-input"], ["formControlName", "taxaMatricula", "type", "number", "placeholder", "0,00 (opcional)", "min", "0", "step", "0.01", 1, "form-input"], [1, "modal-footer"], ["type", "button", 1, "btn-ghost", 3, "click", "disabled"], ["type", "button", 1, "btn-primary", 3, "click", "disabled"], ["role", "dialog", 1, "modal", "modal-sm", "confirm-box"], [1, "modal-icon-danger"], ["width", "22", "height", "22", "fill", "none", "stroke", "currentColor", "stroke-width", "2", "viewBox", "0 0 24 24"], ["d", "M12 9v2m0 4h.01M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z"], [1, "modal-titulo", 2, "font-size", "1rem", "margin", "0"], [2, "font-size", "0.875rem", "color", "var(--app-text-2)", "margin", "0", "text-align", "center", "line-height", "1.6"], [1, "modal-footer", 2, "justify-content", "center"], [1, "btn-ghost", 3, "click", "disabled"], [1, "btn-danger", 3, "click", "disabled"]], template: function PlanosListaComponent_Template(rf, ctx) {
      if (rf & 1) {
        \u0275\u0275elementStart(0, "div", 0)(1, "div", 1)(2, "div")(3, "h1", 2);
        \u0275\u0275text(4, "Planos");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(5, "p", 3);
        \u0275\u0275text(6, "Planos e mensalidades oferecidos pela academia");
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(7, "button", 4);
        \u0275\u0275listener("click", function PlanosListaComponent_Template_button_click_7_listener() {
          return ctx.abrirNovo();
        });
        \u0275\u0275text(8, "+ Novo Plano");
        \u0275\u0275elementEnd()();
        \u0275\u0275template(9, PlanosListaComponent_Conditional_9_Template, 2, 1, "div", 5)(10, PlanosListaComponent_Conditional_10_Template, 3, 1, "div", 6)(11, PlanosListaComponent_Conditional_11_Template, 9, 0)(12, PlanosListaComponent_Conditional_12_Template, 3, 0);
        \u0275\u0275elementEnd();
        \u0275\u0275template(13, PlanosListaComponent_Conditional_13_Template, 34, 8)(14, PlanosListaComponent_Conditional_14_Template, 18, 5);
      }
      if (rf & 2) {
        \u0275\u0275advance(9);
        \u0275\u0275conditional(9, ctx.erro() ? 9 : -1);
        \u0275\u0275advance();
        \u0275\u0275conditional(10, ctx.carregando() ? 10 : ctx.planos().length === 0 ? 11 : 12);
        \u0275\u0275advance(3);
        \u0275\u0275conditional(13, ctx.modalAberto() ? 13 : -1);
        \u0275\u0275advance();
        \u0275\u0275conditional(14, ctx.confirmandoExcluir() ? 14 : -1);
      }
    }, dependencies: [CommonModule, ReactiveFormsModule, \u0275NgNoValidate, DefaultValueAccessor, NumberValueAccessor, NgControlStatus, NgControlStatusGroup, MinValidator, FormGroupDirective, FormControlName, FormsModule], styles: [".planos-page[_ngcontent-%COMP%] { padding: 28px 32px; max-width: 1100px; margin: 0 auto; }\n  .page-header[_ngcontent-%COMP%] { display: flex; align-items: flex-start; justify-content: space-between; margin-bottom: 28px; }\n  .page-title[_ngcontent-%COMP%] { font-size: 1.5rem; font-weight: 700; color: var(--app-text-1); margin: 0 0 4px; }\n  .page-subtitle[_ngcontent-%COMP%] { font-size: 0.875rem; color: var(--app-text-3); margin: 0; }\n\n  .planos-grid[_ngcontent-%COMP%] { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 16px; }\n\n  .plano-card[_ngcontent-%COMP%] { background: var(--app-surface); border: 1px solid var(--app-border); border-radius: 12px; padding: 20px; display: flex; flex-direction: column; gap: 14px; transition: border-color 0.15s; }\n  .plano-card[_ngcontent-%COMP%]:hover { border-color: rgba(99,102,241,0.4); }\n  .plano-card.inativo[_ngcontent-%COMP%] { opacity: 0.6; }\n\n  .plano-top[_ngcontent-%COMP%] { display: flex; align-items: flex-start; justify-content: space-between; gap: 8px; }\n  .plano-nome[_ngcontent-%COMP%] { font-size: 1rem; font-weight: 700; color: var(--app-text-1); margin-bottom: 4px; }\n  .plano-desc[_ngcontent-%COMP%] { font-size: 0.8rem; color: var(--app-text-3); margin: 0; line-height: 1.5; }\n  .plano-acoes[_ngcontent-%COMP%] { display: flex; gap: 4px; flex-shrink: 0; }\n\n  .btn-icon[_ngcontent-%COMP%] { width: 28px; height: 28px; border-radius: 6px; border: 1px solid var(--app-border); background: var(--app-surface); cursor: pointer; color: var(--app-text-2); display: flex; align-items: center; justify-content: center; transition: background 0.15s, color 0.15s; }\n  .btn-icon[_ngcontent-%COMP%]:hover { background: var(--app-border); color: var(--app-text-1); }\n  .btn-icon-danger[_ngcontent-%COMP%]:hover { background: rgba(239,68,68,0.1); color: #ef4444; border-color: #ef4444; }\n\n  .plano-valores[_ngcontent-%COMP%] { display: flex; flex-direction: column; gap: 8px; padding: 12px; background: rgba(99,102,241,0.05); border-radius: 8px; }\n  .valor-item[_ngcontent-%COMP%] { display: flex; justify-content: space-between; align-items: center; }\n  .valor-label[_ngcontent-%COMP%] { font-size: 0.75rem; color: var(--app-text-3); }\n  .valor-num[_ngcontent-%COMP%] { font-size: 0.95rem; font-weight: 700; color: var(--app-text-1); }\n\n  .plano-valores[_ngcontent-%COMP%] { flex: 1; }\n  .plano-footer[_ngcontent-%COMP%] { display: flex; align-items: center; justify-content: space-between; padding-top: 10px; border-top: 1px solid var(--app-border); }\n  .plano-alunos[_ngcontent-%COMP%] { font-size: 0.75rem; color: var(--app-text-3); display: flex; align-items: center; gap: 4px; }\n  .btn-toggle[_ngcontent-%COMP%] { font-size: 0.75rem; font-weight: 600; padding: 4px 10px; background: transparent; border: 1px solid var(--app-border); border-radius: 6px; color: var(--app-text-2); cursor: pointer; }\n  .btn-toggle[_ngcontent-%COMP%]:hover { background: var(--app-border); }\n\n  \n\n  .modal-backdrop[_ngcontent-%COMP%] { position: fixed; inset: 0; background: rgba(0,0,0,0.5); z-index: 100; }\n  .modal[_ngcontent-%COMP%] { position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%); z-index: 101; background: var(--app-surface); border: 1px solid var(--app-border); border-radius: 16px; width: 520px; max-width: calc(100vw - 32px); max-height: calc(100vh - 64px); display: flex; flex-direction: column; overflow: hidden; box-shadow: 0 20px 60px rgba(0,0,0,0.4); }\n  .modal-sm[_ngcontent-%COMP%] { width: 400px; }\n  .confirm-box[_ngcontent-%COMP%] { padding: 28px; align-items: center; gap: 12px; }\n  .modal-header[_ngcontent-%COMP%] { display: flex; align-items: center; justify-content: space-between; padding: 20px 24px 16px; border-bottom: 1px solid var(--app-border); }\n  .modal-titulo[_ngcontent-%COMP%] { font-size: 1.1rem; font-weight: 700; color: var(--app-text-1); margin: 0; }\n  .modal-fechar[_ngcontent-%COMP%] { background: none; border: none; color: var(--app-text-3); cursor: pointer; display: flex; align-items: center; padding: 4px; border-radius: 6px; }\n  .modal-fechar[_ngcontent-%COMP%]:hover { background: var(--app-border); }\n  .modal-body[_ngcontent-%COMP%] { padding: 20px 24px; overflow-y: auto; display: flex; flex-direction: column; gap: 14px; }\n  .modal-footer[_ngcontent-%COMP%] { display: flex; justify-content: flex-end; gap: 10px; padding: 16px 24px 20px; border-top: 1px solid var(--app-border); }\n  .modal-icon-danger[_ngcontent-%COMP%] { width: 52px; height: 52px; border-radius: 50%; background: rgba(239,68,68,0.1); color: #ef4444; display: flex; align-items: center; justify-content: center; }\n\n  .form-field[_ngcontent-%COMP%] { display: flex; flex-direction: column; gap: 5px; }\n  .form-label[_ngcontent-%COMP%] { font-size: 0.8rem; font-weight: 600; color: var(--app-text-2); }\n  .form-input[_ngcontent-%COMP%] { background: var(--app-bg, #0f1117); border: 1px solid var(--app-border); border-radius: 8px; padding: 9px 12px; font-size: 0.875rem; color: var(--app-text-1); width: 100%; box-sizing: border-box; }\n  .form-input[_ngcontent-%COMP%]:focus { outline: none; border-color: var(--color-primary, #6366f1); }\n  .form-textarea[_ngcontent-%COMP%] { resize: vertical; min-height: 72px; }\n  .form-row[_ngcontent-%COMP%] { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }\n  .form-erro[_ngcontent-%COMP%] { font-size: 0.8rem; color: #ef4444; font-weight: 500; }\n\n  .btn-primary[_ngcontent-%COMP%] { display: inline-flex; align-items: center; gap: 6px; padding: 9px 18px; background: var(--color-primary, #6366f1); color: #fff; border: none; border-radius: 8px; font-size: 0.875rem; font-weight: 600; cursor: pointer; }\n  .btn-primary[_ngcontent-%COMP%]:disabled { opacity: 0.6; cursor: not-allowed; }\n  .btn-primary[_ngcontent-%COMP%]:hover:not(:disabled) { opacity: 0.9; }\n  .btn-ghost[_ngcontent-%COMP%] { padding: 9px 18px; background: transparent; border: 1px solid var(--app-border); border-radius: 8px; font-size: 0.875rem; font-weight: 500; color: var(--app-text-2); cursor: pointer; }\n  .btn-ghost[_ngcontent-%COMP%]:disabled { opacity: 0.6; cursor: not-allowed; }\n  .btn-ghost[_ngcontent-%COMP%]:hover:not(:disabled) { background: var(--app-border); }\n  .btn-danger[_ngcontent-%COMP%] { padding: 9px 18px; background: #ef4444; color: #fff; border: none; border-radius: 8px; font-size: 0.875rem; font-weight: 600; cursor: pointer; }\n  .btn-danger[_ngcontent-%COMP%]:disabled { opacity: 0.6; cursor: not-allowed; }\n  .btn-danger[_ngcontent-%COMP%]:hover:not(:disabled) { opacity: 0.88; }\n\n  @media (max-width: 768px) {\n    .planos-page[_ngcontent-%COMP%] { padding: 16px; }\n    .form-row[_ngcontent-%COMP%] { grid-template-columns: 1fr; }\n  }"] });
  }
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && \u0275setClassDebugInfo(PlanosListaComponent, { className: "PlanosListaComponent" });
})();
export {
  PlanosListaComponent
};
//# sourceMappingURL=chunk-FNE3NB55.js.map
