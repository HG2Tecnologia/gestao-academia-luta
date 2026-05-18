import { Routes } from '@angular/router';

export const turmasRoutes: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('./pages/lista/turmas-lista.component').then((m) => m.TurmasListaComponent),
    title: 'Turmas — Academia Fight',
  },
  {
    path: 'novo',
    loadComponent: () =>
      import('./pages/form/turma-form.component').then((m) => m.TurmaFormComponent),
    title: 'Nova Turma — Academia Fight',
  },
  {
    path: ':id/editar',
    loadComponent: () =>
      import('./pages/form/turma-form.component').then((m) => m.TurmaFormComponent),
    title: 'Editar Turma — Academia Fight',
  },
  {
    path: ':id',
    loadComponent: () =>
      import('./pages/detalhe/turma-detalhe.component').then((m) => m.TurmaDetalheComponent),
    title: 'Detalhe da Turma — Academia Fight',
  },
];
