import { Routes } from '@angular/router';

export const graduacaoRoutes: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('./pages/faixas/faixas.component').then((m) => m.FaixasComponent),
    title: 'Faixas — Academia Fight',
  },
  {
    path: 'registrar',
    loadComponent: () =>
      import('./pages/registrar/registrar-graduacao.component').then((m) => m.RegistrarGraduacaoComponent),
    title: 'Registrar Graduação — Academia Fight',
  },
];
