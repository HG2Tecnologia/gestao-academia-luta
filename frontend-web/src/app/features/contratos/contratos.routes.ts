import { Routes } from '@angular/router';

export const contratosRoutes: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('./pages/lista/contratos-lista.component').then((m) => m.ContratosListaComponent),
    title: 'Contratos — Academia Fight',
  },
  {
    path: 'modelos',
    loadComponent: () =>
      import('./pages/modelos/contratos-modelos.component').then((m) => m.ContratosModelosComponent),
    title: 'Modelos de Contrato — Academia Fight',
  },
  {
    path: ':id',
    loadComponent: () =>
      import('./pages/detalhe/contrato-detalhe.component').then((m) => m.ContratoDetalheComponent),
    title: 'Contrato — Academia Fight',
  },
];
