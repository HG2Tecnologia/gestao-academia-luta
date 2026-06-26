import { Routes } from '@angular/router';

export const gruposFamiliaresRoutes: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('./grupos-familiares.component').then((m) => m.GruposFamiliaresComponent),
    title: 'Grupos Familiares — Sensei Manager',
  },
];
