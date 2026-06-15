import { Routes } from '@angular/router';

export const horariosRoutes: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('./pages/grade/grade-horarios.component').then((m) => m.GradeHorariosComponent),
    title: 'Grade de Horários — Sensei Manager',
  },
];
