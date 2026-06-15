import { Routes } from '@angular/router';

export const financeiroRoutes: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('./pages/overview/financeiro-overview.component').then(
        (m) => m.FinanceiroOverviewComponent
      ),
    title: 'Financeiro — Sensei Manager',
  },
];
