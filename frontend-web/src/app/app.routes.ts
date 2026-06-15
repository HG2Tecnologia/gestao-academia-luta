import { Routes } from '@angular/router';
import { authGuard } from './core/guards/auth.guard';
import { guestGuard } from './core/guards/guest.guard';
import { permissaoGuard } from './core/guards/permissao.guard';

export const routes: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('./features/landing/landing.component').then((m) => m.LandingComponent),
    title: 'Sensei Manager — Gestão inteligente para artes marciais',
  },
  {
    path: 'login',
    loadComponent: () =>
      import('./features/auth/login/login.component').then((m) => m.LoginComponent),
    canActivate: [guestGuard],
    title: 'Entrar — Sensei Manager',
  },
  {
    path: 'cadastro',
    loadComponent: () =>
      import('./features/auth/cadastro/cadastro.component').then((m) => m.CadastroComponent),
    canActivate: [guestGuard],
    title: 'Criar conta — Sensei Manager',
  },
  {
    path: 'forgot-password',
    loadComponent: () =>
      import('./features/auth/forgot-password/forgot-password.component').then(
        (m) => m.ForgotPasswordComponent
      ),
    title: 'Recuperar senha — Sensei Manager',
  },
  {
    path: 'reset-password',
    loadComponent: () =>
      import('./features/auth/reset-password/reset-password.component').then(
        (m) => m.ResetPasswordComponent
      ),
    title: 'Nova senha — Sensei Manager',
  },
  {
    path: 'app',
    loadComponent: () =>
      import('./shared/layout/shell/shell.component').then((m) => m.ShellComponent),
    canActivate: [authGuard],
    children: [
      { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
      {
        path: 'dashboard',
        title: 'Dashboard — Sensei Manager',
        loadComponent: () =>
          import('./features/dashboard/dashboard.component').then((m) => m.DashboardComponent),
      },
      {
        path: 'alunos',
        canActivate: [permissaoGuard('Alunos')],
        loadChildren: () =>
          import('./features/alunos/alunos.routes').then((m) => m.alunosRoutes),
      },
      {
        path: 'turmas',
        canActivate: [permissaoGuard('Turmas')],
        loadChildren: () =>
          import('./features/turmas/turmas.routes').then((m) => m.turmasRoutes),
      },
      {
        path: 'horarios',
        canActivate: [permissaoGuard('Horários')],
        loadChildren: () =>
          import('./features/horarios/horarios.routes').then((m) => m.horariosRoutes),
      },
      {
        path: 'presencas',
        canActivate: [permissaoGuard('Presenças')],
        loadChildren: () =>
          import('./features/presencas/presencas.routes').then((m) => m.presencasRoutes),
      },
      {
        path: 'graduacao',
        canActivate: [permissaoGuard('Graduação')],
        loadChildren: () =>
          import('./features/graduacao/graduacao.routes').then((m) => m.graduacaoRoutes),
      },
      {
        path: 'ranking',
        canActivate: [permissaoGuard('Ranking')],
        loadChildren: () =>
          import('./features/ranking/ranking.routes').then((m) => m.RANKING_ROUTES),
      },
      {
        path: 'modalidades',
        canActivate: [permissaoGuard('Admin')],
        loadChildren: () =>
          import('./features/modalidades/modalidades.routes').then((m) => m.modalidadesRoutes),
      },
      {
        path: 'funcionarios',
        canActivate: [permissaoGuard('Admin')],
        loadChildren: () =>
          import('./features/funcionarios/funcionarios.routes').then((m) => m.funcionariosRoutes),
      },
      {
        path: 'configuracoes',
        canActivate: [permissaoGuard('Configurações')],
        loadChildren: () =>
          import('./features/configuracoes/configuracoes.routes').then((m) => m.configuracoesRoutes),
      },
      {
        path: 'catraca',
        canActivate: [permissaoGuard('Catraca')],
        loadChildren: () =>
          import('./features/catraca/catraca.routes').then((m) => m.catracaRoutes),
      },
      {
        path: 'planos',
        canActivate: [permissaoGuard('Planos')],
        loadChildren: () =>
          import('./features/planos/planos.routes').then((m) => m.planosRoutes),
      },
      {
        path: 'financeiro',
        canActivate: [permissaoGuard('Financeiro')],
        loadChildren: () =>
          import('./features/financeiro/financeiro.routes').then((m) => m.financeiroRoutes),
      },
      {
        path: 'relatorios',
        canActivate: [permissaoGuard('Relatórios')],
        loadChildren: () =>
          import('./features/relatorios/relatorios.routes').then((m) => m.relatoriosRoutes),
      },
      {
        path: 'contratos',
        canActivate: [permissaoGuard('Contratos')],
        loadChildren: () =>
          import('./features/contratos/contratos.routes').then((m) => m.contratosRoutes),
      },
    ],
  },
  {
    path: 'assinar/:token',
    loadComponent: () =>
      import('./features/contratos/pages/assinar/assinar-contrato.component').then((m) => m.AssinarContratoComponent),
    title: 'Assinar Contrato',
  },
  {
    path: '**',
    redirectTo: '',
  },
];
