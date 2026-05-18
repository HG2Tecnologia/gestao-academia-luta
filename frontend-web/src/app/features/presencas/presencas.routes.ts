import { Routes } from '@angular/router';

export const presencasRoutes: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('./pages/checkin/checkin.component').then((m) => m.CheckinComponent),
    title: 'Check-in — Academia Fight',
  },
  {
    path: 'historico',
    loadComponent: () =>
      import('./pages/historico/historico-presencas.component').then((m) => m.HistoricoPresencasComponent),
    title: 'Histórico de Presenças — Academia Fight',
  },
];
