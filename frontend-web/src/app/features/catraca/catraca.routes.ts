import { Routes } from '@angular/router';

export const catracaRoutes: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('./catraca.component').then((m) => m.CatracaComponent),
    title: 'Catraca — Academia Fight',
  },
];
