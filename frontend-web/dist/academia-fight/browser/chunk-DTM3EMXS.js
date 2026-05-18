import {
  environment
} from "./chunk-Z5CKO2JM.js";
import {
  HttpClient,
  inject,
  ɵɵdefineInjectable
} from "./chunk-WZ2AWGAJ.js";

// src/app/core/services/plano.service.ts
var PlanoService = class _PlanoService {
  constructor() {
    this.http = inject(HttpClient);
    this.api = `${environment.apiUrl}/api/planos`;
  }
  listar() {
    return this.http.get(this.api);
  }
  criar(dto) {
    return this.http.post(this.api, dto);
  }
  atualizar(id, dto) {
    return this.http.put(`${this.api}/${id}`, dto);
  }
  deletar(id) {
    return this.http.delete(`${this.api}/${id}`);
  }
  static {
    this.\u0275fac = function PlanoService_Factory(t) {
      return new (t || _PlanoService)();
    };
  }
  static {
    this.\u0275prov = /* @__PURE__ */ \u0275\u0275defineInjectable({ token: _PlanoService, factory: _PlanoService.\u0275fac, providedIn: "root" });
  }
};

export {
  PlanoService
};
//# sourceMappingURL=chunk-DTM3EMXS.js.map
