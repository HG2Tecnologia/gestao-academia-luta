import { Routes } from '@angular/router';

export const turmasRoutes: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('./pages/lista/turmas-lista.component').then((m) => m.TurmasListaComponent),
    title: 'Turmas — Sensei Manager',
  },
  {
    path: 'novo',
    loadComponent: () =>
      import('./pages/form/turma-form.component').then((m) => m.TurmaFormComponent),
    title: 'Nova Turma — Sensei Manager',
  },
  {
    path: ':id/editar',
    loadComponent: () =>
      import('./pages/form/turma-form.component').then((m) => m.TurmaFormComponent),
    title: 'Editar Turma — Sensei Manager',
  },
  {
    path: ':id',
    loadComponent: () =>
      import('./pages/detalhe/turma-detalhe.component').then((m) => m.TurmaDetalheComponent),
    title: 'Detalhe da Turma — Sensei Manager',
  },
];
