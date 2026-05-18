import {
  environment
} from "./chunk-Z5CKO2JM.js";
import {
  HttpClient,
  inject,
  ɵɵdefineInjectable
} from "./chunk-WZ2AWGAJ.js";

// src/app/core/services/modelo-contrato.service.ts
var ModeloContratoService = class _ModeloContratoService {
  constructor() {
    this.http = inject(HttpClient);
    this.api = `${environment.apiUrl}/api/contratos/modelos`;
  }
  listar() {
    return this.http.get(this.api);
  }
  obter(id) {
    return this.http.get(`${this.api}/${id}`);
  }
  criar(data) {
    return this.http.post(this.api, data);
  }
  atualizar(id, data) {
    return this.http.put(`${this.api}/${id}`, data);
  }
  excluir(id) {
    return this.http.delete(`${this.api}/${id}`);
  }
  static {
    this.\u0275fac = function ModeloContratoService_Factory(t) {
      return new (t || _ModeloContratoService)();
    };
  }
  static {
    this.\u0275prov = /* @__PURE__ */ \u0275\u0275defineInjectable({ token: _ModeloContratoService, factory: _ModeloContratoService.\u0275fac, providedIn: "root" });
  }
};

export {
  ModeloContratoService
};
//# sourceMappingURL=chunk-KEFB7QAL.js.map
