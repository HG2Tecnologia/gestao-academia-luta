import {
  environment
} from "./chunk-Z5CKO2JM.js";
import {
  HttpClient,
  inject,
  ɵɵdefineInjectable
} from "./chunk-WZ2AWGAJ.js";

// src/app/core/services/aluno.service.ts
var AlunoService = class _AlunoService {
  constructor() {
    this.http = inject(HttpClient);
    this.api = `${environment.apiUrl}/api/alunos`;
  }
  getAll(filtros) {
    const params = {};
    if (filtros?.nome)
      params["nome"] = filtros.nome;
    if (filtros?.ativo !== void 0)
      params["ativo"] = String(filtros.ativo);
    if (filtros?.page)
      params["page"] = String(filtros.page);
    if (filtros?.pageSize)
      params["pageSize"] = String(filtros.pageSize);
    return this.http.get(this.api, { params });
  }
  buscarPorNome(nome) {
    return this.http.get(this.api, { params: { nome, pageSize: "10" } });
  }
  getById(id) {
    return this.http.get(`${this.api}/${id}`);
  }
  create(data) {
    return this.http.post(this.api, data);
  }
  update(id, data) {
    return this.http.put(`${this.api}/${id}`, data);
  }
  toggleAtivo(id, ativo) {
    return this.http.patch(`${this.api}/${id}/status`, { ativo });
  }
  delete(id) {
    return this.http.delete(`${this.api}/${id}`);
  }
  getAniversariantes(mes) {
    const params = {};
    if (mes !== void 0)
      params["mes"] = String(mes);
    return this.http.get(`${this.api}/aniversariantes`, { params });
  }
  static {
    this.\u0275fac = function AlunoService_Factory(t) {
      return new (t || _AlunoService)();
    };
  }
  static {
    this.\u0275prov = /* @__PURE__ */ \u0275\u0275defineInjectable({ token: _AlunoService, factory: _AlunoService.\u0275fac, providedIn: "root" });
  }
};

export {
  AlunoService
};
//# sourceMappingURL=chunk-ZSIQJU4D.js.map
