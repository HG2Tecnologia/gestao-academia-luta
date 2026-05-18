import { Routes } from '@angular/router';

export const alunosRoutes: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('./pages/lista/alunos-lista.component').then(m => m.AlunosListaComponent),
    title: 'Alunos — Academia Fight',
  },
  {
    path: 'novo',
    loadComponent: () =>
      import('./pages/form/aluno-form.component').then(m => m.AlunoFormComponent),
    title: 'Novo Aluno — Academia Fight',
  },
  {
    path: ':id/editar',
    loadComponent: () =>
      import('./pages/form/aluno-form.component').then(m => m.AlunoFormComponent),
    title: 'Editar Aluno — Academia Fight',
  },
  {
    path: ':id',
    loadComponent: () =>
      import('./pages/detalhe/aluno-detalhe.component').then(m => m.AlunoDetalheComponent),
    title: 'Detalhe do Aluno — Academia Fight',
  },
];
