import {
  environment
} from "./chunk-Z5CKO2JM.js";
import {
  HttpClient,
  inject,
  ɵɵdefineInjectable
} from "./chunk-WZ2AWGAJ.js";

// src/app/core/services/academia.service.ts
var AcademiaService = class _AcademiaService {
  constructor() {
    this.http = inject(HttpClient);
    this.api = `${environment.apiUrl}/api/academia`;
  }
  getCurrent() {
    return this.http.get(this.api);
  }
  update(data) {
    return this.http.put(this.api, data);
  }
  updateTemplateContrato(template) {
    return this.http.put(`${this.api}/template-contrato`, { template });
  }
  static {
    this.\u0275fac = function AcademiaService_Factory(t) {
      return new (t || _AcademiaService)();
    };
  }
  static {
    this.\u0275prov = /* @__PURE__ */ \u0275\u0275defineInjectable({ token: _AcademiaService, factory: _AcademiaService.\u0275fac, providedIn: "root" });
  }
};

export {
  AcademiaService
};
//# sourceMappingURL=chunk-EIUHPY3K.js.map
