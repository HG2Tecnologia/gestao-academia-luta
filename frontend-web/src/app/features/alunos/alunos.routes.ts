import { Routes } from '@angular/router';

export const alunosRoutes: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('./pages/lista/alunos-lista.component').then(m => m.AlunosListaComponent),
    title: 'Alunos — Sensei Manager',
  },
  {
    path: 'novo',
    loadComponent: () =>
      import('./pages/form/aluno-form.component').then(m => m.AlunoFormComponent),
    title: 'Novo Aluno — Sensei Manager',
  },
  {
    path: ':id/editar',
    loadComponent: () =>
      import('./pages/form/aluno-form.component').then(m => m.AlunoFormComponent),
    title: 'Editar Aluno — Sensei Manager',
  },
  {
    path: ':id',
    loadComponent: () =>
      import('./pages/detalhe/aluno-detalhe.component').then(m => m.AlunoDetalheComponent),
    title: 'Detalhe do Aluno — Sensei Manager',
  },
];
