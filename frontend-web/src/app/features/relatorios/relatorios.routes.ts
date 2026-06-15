import { Routes } from '@angular/router';

export const relatoriosRoutes: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('./pages/geral/relatorios.component').then((m) => m.RelatoriosComponent),
    title: 'Relatórios — Sensei Manager',
  },
];
