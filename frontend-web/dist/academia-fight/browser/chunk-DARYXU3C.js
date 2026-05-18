import {
  environment
} from "./chunk-Z5CKO2JM.js";
import {
  HttpClient,
  inject,
  ɵɵdefineInjectable
} from "./chunk-WZ2AWGAJ.js";

// src/app/core/services/presenca.service.ts
var PresencaService = class _PresencaService {
  constructor() {
    this.http = inject(HttpClient);
    this.api = `${environment.apiUrl}/api/presencas`;
  }
  registrar(data) {
    return this.http.post(this.api, data);
  }
  registrarQrCode(token) {
    return this.http.post(`${this.api}/qrcode`, { token });
  }
  getHistorico(alunoId, de, ate) {
    return this.http.get(this.api, { params: { alunoId, de, ate } });
  }
  getPresencasAula(horarioId, data) {
    return this.http.get(`${this.api}/aula`, { params: { horarioId, data } });
  }
  getRelatorio(turmaId, de, ate) {
    return this.http.get(`${this.api}/relatorio`, {
      params: { turmaId, de, ate }
    });
  }
  gerarQrToken(alunoId) {
    return this.http.get(`${this.api}/qr/${alunoId}`);
  }
  static {
    this.\u0275fac = function PresencaService_Factory(t) {
      return new (t || _PresencaService)();
    };
  }
  static {
    this.\u0275prov = /* @__PURE__ */ \u0275\u0275defineInjectable({ token: _PresencaService, factory: _PresencaService.\u0275fac, providedIn: "root" });
  }
};

export {
  PresencaService
};
//# sourceMappingURL=chunk-DARYXU3C.js.map
