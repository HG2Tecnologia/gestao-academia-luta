import {
  environment
} from "./chunk-Z5CKO2JM.js";
import {
  HttpClient,
  inject,
  ɵɵdefineInjectable
} from "./chunk-WZ2AWGAJ.js";

// src/app/core/services/contrato.service.ts
var ContratoService = class _ContratoService {
  constructor() {
    this.http = inject(HttpClient);
    this.api = `${environment.apiUrl}/api/contratos`;
    this.publicApi = `${environment.apiUrl}/api/public/contratos`;
  }
  listar(alunoId) {
    const params = {};
    if (alunoId)
      params["alunoId"] = alunoId;
    return this.http.get(this.api, { params });
  }
  obter(id) {
    return this.http.get(`${this.api}/${id}`);
  }
  criar(data) {
    return this.http.post(this.api, data);
  }
  assinar(id, data) {
    return this.http.post(`${this.api}/${id}/assinar`, data);
  }
  cancelar(id) {
    return this.http.post(`${this.api}/${id}/cancelar`, {});
  }
  obterPublico(token) {
    return this.http.get(`${this.publicApi}/${token}`);
  }
  assinarPublico(token, data) {
    return this.http.post(`${this.publicApi}/${token}/assinar`, data);
  }
  static {
    this.\u0275fac = function ContratoService_Factory(t) {
      return new (t || _ContratoService)();
    };
  }
  static {
    this.\u0275prov = /* @__PURE__ */ \u0275\u0275defineInjectable({ token: _ContratoService, factory: _ContratoService.\u0275fac, providedIn: "root" });
  }
};

export {
  ContratoService
};
//# sourceMappingURL=chunk-AJ67XLLV.js.map
