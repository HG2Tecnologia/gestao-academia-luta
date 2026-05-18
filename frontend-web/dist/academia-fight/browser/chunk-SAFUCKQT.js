import "./chunk-7G5TR5RR.js";

// src/app/features/funcionarios/funcionarios.routes.ts
var funcionariosRoutes = [
  {
    path: "",
    loadComponent: () => import("./chunk-ZGP5CUIL.js").then((m) => m.FuncionariosListaComponent),
    title: "Funcion\xE1rios \u2014 Academia Fight"
  },
  {
    path: "novo",
    loadComponent: () => import("./chunk-QO7DDKFO.js").then((m) => m.FuncionarioFormComponent),
    title: "Novo Funcion\xE1rio \u2014 Academia Fight"
  },
  {
    path: ":id/editar",
    loadComponent: () => import("./chunk-QO7DDKFO.js").then((m) => m.FuncionarioFormComponent),
    title: "Editar Funcion\xE1rio \u2014 Academia Fight"
  }
];
export {
  funcionariosRoutes
};
//# sourceMappingURL=chunk-SAFUCKQT.js.map
