import "./chunk-7G5TR5RR.js";

// src/app/features/contratos/contratos.routes.ts
var contratosRoutes = [
  {
    path: "",
    loadComponent: () => import("./chunk-TGF6KD6N.js").then((m) => m.ContratosListaComponent),
    title: "Contratos \u2014 Academia Fight"
  },
  {
    path: "modelos",
    loadComponent: () => import("./chunk-WJ2SI7XC.js").then((m) => m.ContratosModelosComponent),
    title: "Modelos de Contrato \u2014 Academia Fight"
  },
  {
    path: ":id",
    loadComponent: () => import("./chunk-DYM4S3GK.js").then((m) => m.ContratoDetalheComponent),
    title: "Contrato \u2014 Academia Fight"
  }
];
export {
  contratosRoutes
};
//# sourceMappingURL=chunk-NWDV7UR7.js.map
