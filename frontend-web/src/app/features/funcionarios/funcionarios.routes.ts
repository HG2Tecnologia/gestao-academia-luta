import { Routes } from '@angular/router';

export const funcionariosRoutes: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('./pages/lista/funcionarios-lista.component').then(m => m.FuncionariosListaComponent),
    title: 'Funcionários — Academia Fight',
  },
  {
    path: 'novo',
    loadComponent: () =>
      import('./pages/form/funcionario-form.component').then(m => m.FuncionarioFormComponent),
    title: 'Novo Funcionário — Academia Fight',
  },
  {
    path: ':id/editar',
    loadComponent: () =>
      import('./pages/form/funcionario-form.component').then(m => m.FuncionarioFormComponent),
    title: 'Editar Funcionário — Academia Fight',
  },
  {
    path: ':id',
    loadComponent: () =>
      import('./pages/detalhe/funcionario-detalhe.component').then(m => m.FuncionarioDetalheComponent),
    title: 'Funcionário — Academia Fight',
  },
];
