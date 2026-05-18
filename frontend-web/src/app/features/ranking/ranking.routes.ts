import { Routes } from '@angular/router';

export const RANKING_ROUTES: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('./pages/leaderboard/leaderboard.component').then(m => m.LeaderboardComponent),
  },
  {
    path: 'perfil/:alunoId',
    loadComponent: () =>
      import('./pages/perfil-gamificado/perfil-gamificado.component').then(m => m.PerfilGamificadoComponent),
  },
];
