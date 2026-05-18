import {
  FuncionarioService
} from "./chunk-UQMVK7T6.js";
import {
  DefaultValueAccessor,
  FormsModule,
  NgControlStatus,
  NgModel,
  NgSelectOption,
  ɵNgSelectMultipleOption
} from "./chunk-JQJL26HT.js";
import "./chunk-Z5CKO2JM.js";
import {
  RouterLink
} from "./chunk-AXNOULNC.js";
import {
  CommonModule,
  Subject,
  debounceTime,
  distinctUntilChanged,
  inject,
  signal,
  takeUntil,
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
  ɵɵpureFunction1,
  ɵɵrepeater,
  ɵɵrepeaterCreate,
  ɵɵrepeaterTrackByIdentity,
  ɵɵresetView,
  ɵɵrestoreView,
  ɵɵsanitizeUrl,
  ɵɵstyleProp,
  ɵɵtemplate,
  ɵɵtext,
  ɵɵtextInterpolate,
  ɵɵtextInterpolate1
} from "./chunk-WZ2AWGAJ.js";
import "./chunk-7G5TR5RR.js";

// src/app/features/funcionarios/pages/lista/funcionarios-lista.component.ts
var _forTrack0 = ($index, $item) => $item.id;
var _c0 = () => [1, 2, 3, 4];
var _c1 = (a0) => [a0, "editar"];
function FuncionariosListaComponent_Conditional_20_Template(rf, ctx) {
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
function FuncionariosListaComponent_Conditional_21_For_2_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275element(0, "div", 14);
  }
}
function FuncionariosListaComponent_Conditional_21_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 13);
    \u0275\u0275repeaterCreate(1, FuncionariosListaComponent_Conditional_21_For_2_Template, 1, 0, "div", 14, \u0275\u0275repeaterTrackByIdentity);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    \u0275\u0275advance();
    \u0275\u0275repeater(\u0275\u0275pureFunction0(0, _c0));
  }
}
function FuncionariosListaComponent_Conditional_22_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 15);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(1, "svg", 16);
    \u0275\u0275element(2, "rect", 17)(3, "path", 18);
    \u0275\u0275elementEnd();
    \u0275\u0275namespaceHTML();
    \u0275\u0275elementStart(4, "p");
    \u0275\u0275text(5, "Nenhum funcion\xE1rio encontrado.");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(6, "a", 4);
    \u0275\u0275text(7, "+ Novo Funcion\xE1rio");
    \u0275\u0275elementEnd()();
  }
}
function FuncionariosListaComponent_Conditional_23_For_18_Conditional_8_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 25);
    \u0275\u0275text(1);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const f_r3 = \u0275\u0275nextContext().$implicit;
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(f_r3.email);
  }
}
function FuncionariosListaComponent_Conditional_23_For_18_Conditional_15_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "a", 29);
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(1, "svg", 32);
    \u0275\u0275element(2, "path", 33);
    \u0275\u0275elementEnd();
    \u0275\u0275text(3);
    \u0275\u0275elementEnd();
  }
  if (rf & 2) {
    const f_r3 = \u0275\u0275nextContext().$implicit;
    const ctx_r0 = \u0275\u0275nextContext(2);
    \u0275\u0275property("href", ctx_r0.wppLink(f_r3.telefone), \u0275\u0275sanitizeUrl)("title", "WhatsApp: " + f_r3.telefone);
    \u0275\u0275advance(3);
    \u0275\u0275textInterpolate1(" ", f_r3.telefone, " ");
  }
}
function FuncionariosListaComponent_Conditional_23_For_18_Conditional_16_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "span", 34);
    \u0275\u0275text(1, "\u2014");
    \u0275\u0275elementEnd();
  }
}
function FuncionariosListaComponent_Conditional_23_For_18_Conditional_25_Template(rf, ctx) {
  if (rf & 1) {
    const _r4 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "div", 35);
    \u0275\u0275listener("click", function FuncionariosListaComponent_Conditional_23_For_18_Conditional_25_Template_div_click_0_listener() {
      \u0275\u0275restoreView(_r4);
      const ctx_r0 = \u0275\u0275nextContext(3);
      return \u0275\u0275resetView(ctx_r0.fecharDropdown());
    });
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(1, "div", 36)(2, "a", 37);
    \u0275\u0275listener("click", function FuncionariosListaComponent_Conditional_23_For_18_Conditional_25_Template_a_click_2_listener() {
      \u0275\u0275restoreView(_r4);
      const ctx_r0 = \u0275\u0275nextContext(3);
      return \u0275\u0275resetView(ctx_r0.fecharDropdown());
    });
    \u0275\u0275namespaceSVG();
    \u0275\u0275elementStart(3, "svg", 38);
    \u0275\u0275element(4, "path", 39)(5, "path", 40);
    \u0275\u0275elementEnd();
    \u0275\u0275text(6, " Editar ");
    \u0275\u0275elementEnd();
    \u0275\u0275namespaceHTML();
    \u0275\u0275element(7, "div", 41);
    \u0275\u0275elementStart(8, "button", 42);
    \u0275\u0275listener("click", function FuncionariosListaComponent_Conditional_23_For_18_Conditional_25_Template_button_click_8_listener() {
      \u0275\u0275restoreView(_r4);
      const f_r3 = \u0275\u0275nextContext().$implicit;
      const ctx_r0 = \u0275\u0275nextContext(2);
      return \u0275\u0275resetView(ctx_r0.toggleAtivo(f_r3));
    });
    \u0275\u0275elementStart(9, "div", 43);
    \u0275\u0275element(10, "div", 44);
    \u0275\u0275elementEnd();
    \u0275\u0275text(11);
    \u0275\u0275elementEnd()();
  }
  if (rf & 2) {
    const f_r3 = \u0275\u0275nextContext().$implicit;
    const ctx_r0 = \u0275\u0275nextContext(2);
    \u0275\u0275advance();
    \u0275\u0275styleProp("top", ctx_r0.dropdownPos().top, "px")("right", ctx_r0.dropdownPos().right, "px");
    \u0275\u0275advance();
    \u0275\u0275property("routerLink", \u0275\u0275pureFunction1(8, _c1, f_r3.id));
    \u0275\u0275advance(7);
    \u0275\u0275classProp("on", f_r3.ativo);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate1(" ", f_r3.ativo ? "Desativar" : "Ativar", " ");
  }
}
function FuncionariosListaComponent_Conditional_23_For_18_Template(rf, ctx) {
  if (rf & 1) {
    const _r2 = \u0275\u0275getCurrentView();
    \u0275\u0275elementStart(0, "tr")(1, "td")(2, "div", 22)(3, "div", 23);
    \u0275\u0275text(4);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(5, "div")(6, "div", 24);
    \u0275\u0275text(7);
    \u0275\u0275elementEnd();
    \u0275\u0275template(8, FuncionariosListaComponent_Conditional_23_For_18_Conditional_8_Template, 2, 1, "div", 25);
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(9, "td", 26);
    \u0275\u0275text(10);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(11, "td")(12, "span", 27);
    \u0275\u0275text(13);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(14, "td", 28);
    \u0275\u0275template(15, FuncionariosListaComponent_Conditional_23_For_18_Conditional_15_Template, 4, 3, "a", 29)(16, FuncionariosListaComponent_Conditional_23_For_18_Conditional_16_Template, 2, 0);
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(17, "td")(18, "span", 30);
    \u0275\u0275text(19);
    \u0275\u0275elementEnd()();
    \u0275\u0275elementStart(20, "td")(21, "div")(22, "button", 31);
    \u0275\u0275listener("click", function FuncionariosListaComponent_Conditional_23_For_18_Template_button_click_22_listener($event) {
      const f_r3 = \u0275\u0275restoreView(_r2).$implicit;
      const ctx_r0 = \u0275\u0275nextContext(2);
      ctx_r0.toggleDropdown(f_r3.id, $event);
      return \u0275\u0275resetView($event.stopPropagation());
    });
    \u0275\u0275elementStart(23, "span");
    \u0275\u0275text(24, "\u22EF");
    \u0275\u0275elementEnd()();
    \u0275\u0275template(25, FuncionariosListaComponent_Conditional_23_For_18_Conditional_25_Template, 12, 10);
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    const f_r3 = ctx.$implicit;
    const ctx_r0 = \u0275\u0275nextContext(2);
    \u0275\u0275advance(3);
    \u0275\u0275styleProp("background", ctx_r0.perfilCor(f_r3.perfil));
    \u0275\u0275advance();
    \u0275\u0275textInterpolate(ctx_r0.avatarInicial(f_r3.nome));
    \u0275\u0275advance(3);
    \u0275\u0275textInterpolate(f_r3.nome);
    \u0275\u0275advance();
    \u0275\u0275conditional(8, f_r3.email ? 8 : -1);
    \u0275\u0275advance(2);
    \u0275\u0275textInterpolate(f_r3.cargo);
    \u0275\u0275advance(2);
    \u0275\u0275styleProp("background", ctx_r0.perfilCor(f_r3.perfil) + "22")("color", ctx_r0.perfilCor(f_r3.perfil));
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1(" ", f_r3.perfil, " ");
    \u0275\u0275advance(2);
    \u0275\u0275conditional(15, f_r3.telefone ? 15 : 16);
    \u0275\u0275advance(3);
    \u0275\u0275classProp("badge-success", f_r3.ativo)("badge-neutral", !f_r3.ativo);
    \u0275\u0275advance();
    \u0275\u0275textInterpolate1(" ", f_r3.ativo ? "Ativo" : "Inativo", " ");
    \u0275\u0275advance(6);
    \u0275\u0275conditional(25, ctx_r0.dropdownAbertoId() === f_r3.id ? 25 : -1);
  }
}
function FuncionariosListaComponent_Conditional_23_Template(rf, ctx) {
  if (rf & 1) {
    \u0275\u0275elementStart(0, "div", 19)(1, "table", 20)(2, "thead")(3, "tr")(4, "th");
    \u0275\u0275text(5, "Funcion\xE1rio");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(6, "th");
    \u0275\u0275text(7, "Cargo");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(8, "th");
    \u0275\u0275text(9, "Perfil");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(10, "th");
    \u0275\u0275text(11, "Telefone");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(12, "th");
    \u0275\u0275text(13, "Status");
    \u0275\u0275elementEnd();
    \u0275\u0275elementStart(14, "th", 21);
    \u0275\u0275text(15, "Config.");
    \u0275\u0275elementEnd()()();
    \u0275\u0275elementStart(16, "tbody");
    \u0275\u0275repeaterCreate(17, FuncionariosListaComponent_Conditional_23_For_18_Template, 26, 18, "tr", null, _forTrack0);
    \u0275\u0275elementEnd()()();
  }
  if (rf & 2) {
    const ctx_r0 = \u0275\u0275nextContext();
    \u0275\u0275advance(17);
    \u0275\u0275repeater(ctx_r0.funcionarios());
  }
}
var FuncionariosListaComponent = class _FuncionariosListaComponent {
  constructor() {
    this.funcionarioService = inject(FuncionarioService);
    this.funcionarios = signal([]);
    this.carregando = signal(true);
    this.erro = signal("");
    this.filtroNome = signal("");
    this.filtroPerfil = signal("");
    this.dropdownAbertoId = signal(null);
    this.dropdownPos = signal({ top: 0, right: 0 });
    this.search$ = new Subject();
    this.destroy$ = new Subject();
  }
  ngOnInit() {
    this.search$.pipe(debounceTime(400), distinctUntilChanged(), takeUntil(this.destroy$)).subscribe(() => this.carregar());
    this.carregar();
  }
  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }
  onNomeChange(nome) {
    this.filtroNome.set(nome);
    this.search$.next(nome);
  }
  onPerfilChange(perfil) {
    this.filtroPerfil.set(perfil);
    this.carregar();
  }
  carregar() {
    this.carregando.set(true);
    this.funcionarioService.getAll({
      nome: this.filtroNome() || void 0,
      perfil: this.filtroPerfil() || void 0
    }).subscribe({
      next: (res) => {
        this.funcionarios.set(res.dados ?? []);
        this.carregando.set(false);
      },
      error: () => {
        this.erro.set("Erro ao carregar funcion\xE1rios.");
        this.carregando.set(false);
      }
    });
  }
  toggleDropdown(id, event) {
    const rect = event.currentTarget.getBoundingClientRect();
    this.dropdownPos.set({ top: rect.bottom + 4, right: window.innerWidth - rect.right });
    this.dropdownAbertoId.update((atual) => atual === id ? null : id);
  }
  fecharDropdown() {
    this.dropdownAbertoId.set(null);
  }
  toggleAtivo(f) {
    this.fecharDropdown();
    this.funcionarioService.update(f.id, {
      nome: f.nome,
      email: f.email || void 0,
      telefone: "",
      cargo: f.cargo,
      perfil: f.perfil,
      ativo: !f.ativo
    }).subscribe({ next: () => this.carregar(), error: () => this.erro.set("Erro ao alterar status.") });
  }
  wppLink(telefone) {
    return `https://wa.me/55${telefone.replace(/\D/g, "")}`;
  }
  avatarInicial(nome) {
    return (nome ?? "F").charAt(0).toUpperCase();
  }
  perfilCor(perfil) {
    const map = { Admin: "#a855f7", Professor: "#3b82f6", Recepcionista: "#22c55e" };
    return map[perfil] ?? "#94a3b8";
  }
  static {
    this.\u0275fac = function FuncionariosListaComponent_Factory(t) {
      return new (t || _FuncionariosListaComponent)();
    };
  }
  static {
    this.\u0275cmp = /* @__PURE__ */ \u0275\u0275defineComponent({ type: _FuncionariosListaComponent, selectors: [["app-funcionarios-lista"]], standalone: true, features: [\u0275\u0275StandaloneFeature], decls: 24, vars: 3, consts: [[1, "page-container"], [1, "page-header"], [1, "page-title"], [1, "page-subtitle"], ["routerLink", "novo", 1, "btn-primary"], [1, "filters-row"], ["placeholder", "Buscar por nome...", 1, "form-input", 2, "max-width", "300px", 3, "ngModelChange", "ngModel"], [1, "form-input", 2, "max-width", "180px", 3, "change"], ["value", ""], ["value", "Admin"], ["value", "Professor"], ["value", "Recepcionista"], [1, "alert-error"], [1, "skeleton-list"], [1, "skeleton-row"], [1, "empty-state"], ["width", "48", "height", "48", "fill", "none", "stroke", "currentColor", "stroke-width", "1.5", "viewBox", "0 0 24 24"], ["x", "2", "y", "7", "width", "20", "height", "14", "rx", "2"], ["d", "M16 3H8a2 2 0 0 0-2 2v2h12V5a2 2 0 0 0-2-2z"], [1, "table-wrapper"], [1, "data-table"], [2, "width", "60px"], [2, "display", "flex", "align-items", "center", "gap", "10px"], [1, "presenca-avatar", 2, "flex-shrink", "0"], [1, "font-medium"], [2, "font-size", "12px", "color", "var(--app-text-3)"], [2, "color", "var(--app-text-2)", "font-size", "13px"], [1, "perfil-badge"], [2, "font-size", "13px", "color", "var(--app-text-2)"], ["target", "_blank", "rel", "noopener", 1, "wpp-tel-link", 3, "href", "title"], [1, "badge"], ["title", "Configura\xE7\xF5es", 1, "btn-dots", 3, "click"], ["width", "14", "height", "14", "viewBox", "0 0 24 24", "fill", "currentColor", 2, "flex-shrink", "0"], ["d", "M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"], [2, "color", "var(--app-text-3)"], [1, "acao-overlay", 3, "click"], [1, "acao-dropdown"], [1, "acao-item", 3, "click", "routerLink"], ["width", "14", "height", "14", "fill", "none", "stroke", "currentColor", "stroke-width", "2", "viewBox", "0 0 24 24"], ["d", "M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"], ["d", "M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"], [1, "acao-separator"], [1, "acao-item", "toggle-item", 3, "click"], [1, "mini-toggle"], [1, "mini-toggle-knob"]], template: function FuncionariosListaComponent_Template(rf, ctx) {
      if (rf & 1) {
        \u0275\u0275elementStart(0, "div", 0)(1, "div", 1)(2, "div")(3, "h1", 2);
        \u0275\u0275text(4, "Professores & Funcion\xE1rios");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(5, "p", 3);
        \u0275\u0275text(6, "Gerencie a equipe da academia");
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(7, "a", 4);
        \u0275\u0275text(8, "+ Novo Funcion\xE1rio");
        \u0275\u0275elementEnd()();
        \u0275\u0275elementStart(9, "div", 5)(10, "input", 6);
        \u0275\u0275listener("ngModelChange", function FuncionariosListaComponent_Template_input_ngModelChange_10_listener($event) {
          return ctx.onNomeChange($event);
        });
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(11, "select", 7);
        \u0275\u0275listener("change", function FuncionariosListaComponent_Template_select_change_11_listener($event) {
          return ctx.onPerfilChange($event.target.value);
        });
        \u0275\u0275elementStart(12, "option", 8);
        \u0275\u0275text(13, "Todos os perfis");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(14, "option", 9);
        \u0275\u0275text(15, "Admin");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(16, "option", 10);
        \u0275\u0275text(17, "Professor");
        \u0275\u0275elementEnd();
        \u0275\u0275elementStart(18, "option", 11);
        \u0275\u0275text(19, "Recepcionista");
        \u0275\u0275elementEnd()()();
        \u0275\u0275template(20, FuncionariosListaComponent_Conditional_20_Template, 2, 1, "div", 12)(21, FuncionariosListaComponent_Conditional_21_Template, 3, 1, "div", 13)(22, FuncionariosListaComponent_Conditional_22_Template, 8, 0)(23, FuncionariosListaComponent_Conditional_23_Template, 19, 0);
        \u0275\u0275elementEnd();
      }
      if (rf & 2) {
        \u0275\u0275advance(10);
        \u0275\u0275property("ngModel", ctx.filtroNome());
        \u0275\u0275advance(10);
        \u0275\u0275conditional(20, ctx.erro() ? 20 : -1);
        \u0275\u0275advance();
        \u0275\u0275conditional(21, ctx.carregando() ? 21 : ctx.funcionarios().length === 0 ? 22 : 23);
      }
    }, dependencies: [CommonModule, FormsModule, NgSelectOption, \u0275NgSelectMultipleOption, DefaultValueAccessor, NgControlStatus, NgModel, RouterLink], styles: [".perfil-badge[_ngcontent-%COMP%] { font-size: 11px; font-weight: 600; padding: 2px 8px; border-radius: 99px; }\n  .badge[_ngcontent-%COMP%] { font-size: 11px; font-weight: 600; padding: 2px 8px; border-radius: 99px; }\n  .badge-success[_ngcontent-%COMP%] { background: rgba(34,197,94,0.15); color: #22c55e; }\n  .badge-neutral[_ngcontent-%COMP%] { background: rgba(148,163,184,0.15); color: #94a3b8; }\n\n  .btn-dots[_ngcontent-%COMP%] { background: none; border: 1px solid transparent; border-radius: 6px; cursor: pointer; padding: 4px 8px; font-size: 18px; color: var(--app-text-3); line-height: 1; transition: all 0.15s; }\n  .btn-dots[_ngcontent-%COMP%]:hover { background: var(--app-border-light); border-color: var(--app-border); color: var(--app-text-1); }\n\n  .acao-overlay[_ngcontent-%COMP%] { position: fixed; inset: 0; z-index: 10; }\n  .acao-dropdown[_ngcontent-%COMP%] { position: fixed; background: var(--app-surface); border: 1px solid var(--app-border); border-radius: 8px; box-shadow: 0 4px 20px rgba(0,0,0,0.12); z-index: 200; min-width: 155px; padding: 4px; }\n  .acao-item[_ngcontent-%COMP%] { display: flex; align-items: center; gap: 8px; width: 100%; padding: 7px 10px; border: none; background: none; cursor: pointer; font-size: 13px; color: var(--app-text-1); text-decoration: none; border-radius: 6px; transition: background 0.1s; text-align: left; }\n  .acao-item[_ngcontent-%COMP%]:hover { background: var(--app-border-light); }\n  .acao-separator[_ngcontent-%COMP%] { height: 1px; background: var(--app-border); margin: 4px 0; }\n  .toggle-item[_ngcontent-%COMP%] { color: var(--app-text-2); }\n\n  .mini-toggle[_ngcontent-%COMP%] { width: 28px; height: 16px; border-radius: 99px; background: var(--app-border); position: relative; flex-shrink: 0; transition: background 0.2s; }\n  .mini-toggle.on[_ngcontent-%COMP%] { background: #22c55e; }\n  .mini-toggle-knob[_ngcontent-%COMP%] { position: absolute; top: 2px; left: 2px; width: 12px; height: 12px; border-radius: 50%; background: white; transition: transform 0.2s; }\n  .mini-toggle.on[_ngcontent-%COMP%]   .mini-toggle-knob[_ngcontent-%COMP%] { transform: translateX(12px); }\n\n  .wpp-tel-link[_ngcontent-%COMP%] { display: inline-flex; align-items: center; gap: 5px; color: #25d366; text-decoration: none; font-size: 13px; opacity: 0.85; transition: opacity 0.15s; }\n  .wpp-tel-link[_ngcontent-%COMP%]:hover { opacity: 1; }"] });
  }
};
(() => {
  (typeof ngDevMode === "undefined" || ngDevMode) && \u0275setClassDebugInfo(FuncionariosListaComponent, { className: "FuncionariosListaComponent" });
})();
export {
  FuncionariosListaComponent
};
//# sourceMappingURL=chunk-ZGP5CUIL.js.map
