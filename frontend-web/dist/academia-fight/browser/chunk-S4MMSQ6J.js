import {
  environment
} from "./chunk-Z5CKO2JM.js";
import {
  HttpClient,
  inject,
  ɵɵdefineInjectable
} from "./chunk-WZ2AWGAJ.js";

// src/app/core/services/turma.service.ts
var TurmaService = class _TurmaService {
  constructor() {
    this.http = inject(HttpClient);
    this.api = `${environment.apiUrl}/api/turmas`;
  }
  getAll(filtros) {
    let params = {};
    if (filtros?.modalidadeId)
      params["modalidadeId"] = filtros.modalidadeId;
    if (filtros?.ativo !== void 0)
      params["ativo"] = String(filtros.ativo);
    return this.http.get(this.api, { params });
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
  delete(id) {
    return this.http.delete(`${this.api}/${id}`);
  }
  getAlunos(turmaId) {
    return this.http.get(`${this.api}/${turmaId}/alunos`);
  }
  matricular(turmaId, alunoId) {
    return this.http.post(`${this.api}/${turmaId}/matricular`, { alunoId });
  }
  desmatricular(turmaId, alunoId) {
    return this.http.delete(`${this.api}/${turmaId}/matricular/${alunoId}`);
  }
  static {
    this.\u0275fac = function TurmaService_Factory(t) {
      return new (t || _TurmaService)();
    };
  }
  static {
    this.\u0275prov = /* @__PURE__ */ \u0275\u0275defineInjectable({ token: _TurmaService, factory: _TurmaService.\u0275fac, providedIn: "root" });
  }
};

export {
  TurmaService
};
//# sourceMappingURL=chunk-S4MMSQ6J.js.map
