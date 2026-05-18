import {
  environment
} from "./chunk-Z5CKO2JM.js";
import {
  HttpClient,
  inject,
  ɵɵdefineInjectable
} from "./chunk-WZ2AWGAJ.js";

// src/app/core/services/modalidade.service.ts
var ModalidadeService = class _ModalidadeService {
  constructor() {
    this.http = inject(HttpClient);
    this.api = `${environment.apiUrl}/api/modalidades`;
  }
  getAll() {
    return this.http.get(this.api);
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
  static {
    this.\u0275fac = function ModalidadeService_Factory(t) {
      return new (t || _ModalidadeService)();
    };
  }
  static {
    this.\u0275prov = /* @__PURE__ */ \u0275\u0275defineInjectable({ token: _ModalidadeService, factory: _ModalidadeService.\u0275fac, providedIn: "root" });
  }
};

export {
  ModalidadeService
};
//# sourceMappingURL=chunk-ZN4AZHLY.js.map
