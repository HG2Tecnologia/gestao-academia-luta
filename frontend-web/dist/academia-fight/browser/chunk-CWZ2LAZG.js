import {
  environment
} from "./chunk-Z5CKO2JM.js";
import {
  HttpClient,
  inject,
  ɵɵdefineInjectable
} from "./chunk-WZ2AWGAJ.js";

// src/app/core/services/horario.service.ts
var HorarioService = class _HorarioService {
  constructor() {
    this.http = inject(HttpClient);
    this.api = `${environment.apiUrl}/api/horarios`;
  }
  getGrade() {
    return this.http.get(`${this.api}/grade`);
  }
  getByTurma(turmaId) {
    return this.http.get(this.api, { params: { turmaId } });
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
    this.\u0275fac = function HorarioService_Factory(t) {
      return new (t || _HorarioService)();
    };
  }
  static {
    this.\u0275prov = /* @__PURE__ */ \u0275\u0275defineInjectable({ token: _HorarioService, factory: _HorarioService.\u0275fac, providedIn: "root" });
  }
};

export {
  HorarioService
};
//# sourceMappingURL=chunk-CWZ2LAZG.js.map
