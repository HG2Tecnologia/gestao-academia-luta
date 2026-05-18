import "./chunk-7G5TR5RR.js";

// src/app/features/modalidades/modalidades.routes.ts
var modalidadesRoutes = [
  {
    path: "",
    loadComponent: () => import("./chunk-5TH6LAEF.js").then((m) => m.ModalidadesListaComponent),
    title: "Modalidades \u2014 Academia Fight"
  },
  {
    path: "novo",
    loadComponent: () => import("./chunk-IBD3FMXH.js").then((m) => m.ModalidadeFormComponent),
    title: "Nova Modalidade \u2014 Academia Fight"
  },
  {
    path: ":id/editar",
    loadComponent: () => import("./chunk-IBD3FMXH.js").then((m) => m.ModalidadeFormComponent),
    title: "Editar Modalidade \u2014 Academia Fight"
  }
];
export {
  modalidadesRoutes
};
//# sourceMappingURL=chunk-ROZKYM64.js.map
