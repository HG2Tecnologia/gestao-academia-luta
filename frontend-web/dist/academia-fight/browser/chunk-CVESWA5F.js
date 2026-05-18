import "./chunk-7G5TR5RR.js";

// src/app/features/turmas/turmas.routes.ts
var turmasRoutes = [
  {
    path: "",
    loadComponent: () => import("./chunk-6IHFLHLS.js").then((m) => m.TurmasListaComponent),
    title: "Turmas \u2014 Academia Fight"
  },
  {
    path: "novo",
    loadComponent: () => import("./chunk-EFKAJ3N7.js").then((m) => m.TurmaFormComponent),
    title: "Nova Turma \u2014 Academia Fight"
  },
  {
    path: ":id/editar",
    loadComponent: () => import("./chunk-EFKAJ3N7.js").then((m) => m.TurmaFormComponent),
    title: "Editar Turma \u2014 Academia Fight"
  },
  {
    path: ":id",
    loadComponent: () => import("./chunk-3Y3JJ3UC.js").then((m) => m.TurmaDetalheComponent),
    title: "Detalhe da Turma \u2014 Academia Fight"
  }
];
export {
  turmasRoutes
};
//# sourceMappingURL=chunk-CVESWA5F.js.map
