import { Routes } from '@angular/router';

export const planosRoutes: Routes = [
  {
    path: '',
    loadComponent: () => import('./pages/lista/planos-lista.component').then(m => m.PlanosListaComponent),
    title: 'Planos — Academia Fight',
  },
];
