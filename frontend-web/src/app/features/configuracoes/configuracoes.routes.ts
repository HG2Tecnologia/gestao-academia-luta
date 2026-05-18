import { Routes } from '@angular/router';

export const configuracoesRoutes: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('./pages/geral/configuracoes-geral.component').then(m => m.ConfiguracoesGeralComponent),
    title: 'Configurações — Academia Fight',
  },
];
