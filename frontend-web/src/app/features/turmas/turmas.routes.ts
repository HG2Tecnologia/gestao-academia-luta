import { Routes } from '@angular/router';
import { permissaoGuard } from '../../core/guards/permissao.guard';

/** Cadastro e edição não existem pro Professor, como no app. */
const somenteGestao = permissaoGuard({ perfis: ['Admin', 'Secretaria'] });

export const turmasRoutes: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('./pages/lista/turmas-lista.component').then((m) => m.TurmasListaComponent),
    title: 'Turmas — Sensei Manager',
  },
  {
    path: 'novo',
    canActivate: [somenteGestao],
    loadComponent: () =>
      import('./pages/form/turma-form.component').then((m) => m.TurmaFormComponent),
    title: 'Nova Turma — Sensei Manager',
  },
  {
    path: ':id/editar',
    canActivate: [somenteGestao],
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
