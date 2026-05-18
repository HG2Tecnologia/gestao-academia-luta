import {
  environment
} from "./chunk-Z5CKO2JM.js";
import {
  HttpClient,
  inject,
  ɵɵdefineInjectable
} from "./chunk-WZ2AWGAJ.js";

// src/app/core/services/financeiro.service.ts
var FinanceiroService = class _FinanceiroService {
  constructor() {
    this.http = inject(HttpClient);
    this.api = `${environment.apiUrl}/api/financeiro`;
  }
  getResumo(ano, mes) {
    const params = {};
    if (ano)
      params["ano"] = String(ano);
    if (mes)
      params["mes"] = String(mes);
    return this.http.get(`${this.api}/resumo`, { params });
  }
  listar(filtros) {
    const params = {};
    if (filtros?.alunoId)
      params["alunoId"] = filtros.alunoId;
    if (filtros?.status)
      params["status"] = filtros.status;
    if (filtros?.ano)
      params["ano"] = String(filtros.ano);
    if (filtros?.mes)
      params["mes"] = String(filtros.mes);
    if (filtros?.page)
      params["page"] = String(filtros.page);
    if (filtros?.pageSize)
      params["pageSize"] = String(filtros.pageSize);
    return this.http.get(this.api, { params });
  }
  listarPorAluno(alunoId) {
    return this.http.get(`${this.api}/aluno/${alunoId}`);
  }
  criar(dto) {
    return this.http.post(this.api, dto);
  }
  atualizar(id, dto) {
    return this.http.patch(`${this.api}/${id}`, dto);
  }
  deletar(id) {
    return this.http.delete(`${this.api}/${id}`);
  }
  gerarCobrancasMensais() {
    return this.http.post(`${this.api}/gerar-cobrancas`, {});
  }
  getRelatorioAnual(ano) {
    const params = {};
    if (ano)
      params["ano"] = String(ano);
    return this.http.get(`${this.api}/relatorio-anual`, { params });
  }
  static {
    this.\u0275fac = function FinanceiroService_Factory(t) {
      return new (t || _FinanceiroService)();
    };
  }
  static {
    this.\u0275prov = /* @__PURE__ */ \u0275\u0275defineInjectable({ token: _FinanceiroService, factory: _FinanceiroService.\u0275fac, providedIn: "root" });
  }
};

export {
  FinanceiroService
};
//# sourceMappingURL=chunk-KMLMG5SQ.js.map
