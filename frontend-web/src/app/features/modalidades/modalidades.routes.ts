import { Routes } from '@angular/router';

export const modalidadesRoutes: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('./pages/lista/modalidades-lista.component').then(m => m.ModalidadesListaComponent),
    title: 'Modalidades — Academia Fight',
  },
  {
    path: 'novo',
    loadComponent: () =>
      import('./pages/form/modalidade-form.component').then(m => m.ModalidadeFormComponent),
    title: 'Nova Modalidade — Academia Fight',
  },
  {
    path: ':id/editar',
    loadComponent: () =>
      import('./pages/form/modalidade-form.component').then(m => m.ModalidadeFormComponent),
    title: 'Editar Modalidade — Academia Fight',
  },
  {
    path: ':id',
    loadComponent: () =>
      import('./pages/detalhe/modalidade-detalhe.component').then(m => m.ModalidadeDetalheComponent),
    title: 'Modalidade — Academia Fight',
  },
];
