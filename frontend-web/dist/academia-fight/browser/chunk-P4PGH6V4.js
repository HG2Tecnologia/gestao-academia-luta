import {
  environment
} from "./chunk-Z5CKO2JM.js";
import {
  HttpClient,
  inject,
  ɵɵdefineInjectable
} from "./chunk-WZ2AWGAJ.js";

// src/app/core/services/usuario.service.ts
var UsuarioService = class _UsuarioService {
  constructor() {
    this.http = inject(HttpClient);
    this.base = `${environment.apiUrl}/api/usuarios`;
  }
  getProfessores() {
    return this.http.get(`${this.base}/professores`);
  }
  static {
    this.\u0275fac = function UsuarioService_Factory(t) {
      return new (t || _UsuarioService)();
    };
  }
  static {
    this.\u0275prov = /* @__PURE__ */ \u0275\u0275defineInjectable({ token: _UsuarioService, factory: _UsuarioService.\u0275fac, providedIn: "root" });
  }
};

export {
  UsuarioService
};
//# sourceMappingURL=chunk-P4PGH6V4.js.map
