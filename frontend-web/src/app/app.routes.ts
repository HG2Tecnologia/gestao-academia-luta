import { inject, Injector, runInInjectionContext } from '@angular/core';
import { CanActivateFn, Routes, UrlTree } from '@angular/router';

/**
 * Guards importados via `import()` dinâmico, não estático — os guards
 * injetam `FirebaseAuthService`, que carrega o SDK inteiro do Firebase
 * (Auth+Firestore+Functions). Um import estático no topo deste arquivo
 * (que é ele mesmo carregado eager pelo `app.config.ts`) colocava todo
 * esse peso no bundle inicial, pago até por quem só visita a landing
 * pública sem nunca clicar em Entrar/Cadastrar. Isso é só code-splitting;
 * a lógica dos guards em si (`core/guards/*.guard.ts`) não muda em nada.
 *
 * `Injector` é capturado de forma síncrona (barato, não traz o Firebase)
 * ANTES do `await import(...)` — depois do await o contexto de injeção
 * do Angular já não existe mais, e o `inject()` de dentro do guard
 * carregado dinamicamente lançaria `NG0203`. `runInInjectionContext`
 * reabre esse contexto pra chamada do guard real.
 */
const authGuard: CanActivateFn = async (route, state): Promise<boolean | UrlTree> => {
  const injector = inject(Injector);
  const m = await import('./core/guards/auth.guard');
  return (await runInInjectionContext(injector, () => m.authGuard(route, state))) as boolean | UrlTree;
};

const guestGuard: CanActivateFn = async (route, state): Promise<boolean | UrlTree> => {
  const injector = inject(Injector);
  const m = await import('./core/guards/guest.guard');
  return (await runInInjectionContext(injector, () => m.guestGuard(route, state))) as boolean | UrlTree;
};

function permissaoGuard(chave: string | { perfis: string[] }): CanActivateFn {
  return async (route, state): Promise<boolean | UrlTree> => {
    const injector = inject(Injector);
    const m = await import('./core/guards/permissao.guard');
    return (await runInInjectionContext(injector, () => m.permissaoGuard(chave)(route, state))) as boolean | UrlTree;
  };
}

export const routes: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('./features/landing/landing.component').then((m) => m.LandingComponent),
    title: 'Sensei Manager | Acesse sua conta ou cadastre sua academia',
    data: {
      description:
        'Acesse o Sensei Manager CRM ou cadastre sua academia. Gerencie sua operação pelo computador com integração ao aplicativo mobile.',
      robots: 'index, follow',
    },
  },
  {
    path: 'login',
    loadComponent: () =>
      import('./features/auth/login/login.component').then((m) => m.LoginComponent),
    canActivate: [guestGuard],
    title: 'Entrar — Sensei Manager',
    data: { robots: 'noindex, nofollow' },
  },
  {
    path: 'cadastro',
    loadComponent: () =>
      import('./features/auth/cadastro/cadastro.component').then((m) => m.CadastroComponent),
    canActivate: [guestGuard],
    title: 'Criar conta — Sensei Manager',
    data: { robots: 'noindex, nofollow' },
  },
  {
    path: 'forgot-password',
    loadComponent: () =>
      import('./features/auth/forgot-password/forgot-password.component').then(
        (m) => m.ForgotPasswordComponent
      ),
    title: 'Recuperar senha — Sensei Manager',
    data: { robots: 'noindex, nofollow' },
  },
  {
    path: 'app',
    loadComponent: () =>
      import('./shared/layout/shell/shell.component').then((m) => m.ShellComponent),
    canActivate: [authGuard],
    data: { robots: 'noindex, nofollow' },
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
        canActivate: [permissaoGuard('tela_alunos')],
        loadChildren: () =>
          import('./features/alunos/alunos.routes').then((m) => m.alunosRoutes),
      },
      {
        path: 'turmas',
        canActivate: [permissaoGuard('tela_turmas')],
        loadChildren: () =>
          import('./features/turmas/turmas.routes').then((m) => m.turmasRoutes),
      },
      {
        path: 'horarios',
        canActivate: [permissaoGuard('tela_horarios')],
        loadChildren: () =>
          import('./features/horarios/horarios.routes').then((m) => m.horariosRoutes),
      },
      {
        path: 'presencas',
        canActivate: [permissaoGuard('acao_dar_presenca')],
        loadChildren: () =>
          import('./features/presencas/presencas.routes').then((m) => m.presencasRoutes),
      },
      {
        path: 'graduacao',
        canActivate: [permissaoGuard('acao_graduar')],
        loadChildren: () =>
          import('./features/graduacao/graduacao.routes').then((m) => m.graduacaoRoutes),
      },
      {
        path: 'ranking',
        canActivate: [permissaoGuard('tela_rankings')],
        loadChildren: () =>
          import('./features/ranking/ranking.routes').then((m) => m.RANKING_ROUTES),
      },
      {
        path: 'modalidades',
        canActivate: [permissaoGuard({ perfis: ['Admin'] })],
        loadChildren: () =>
          import('./features/modalidades/modalidades.routes').then((m) => m.modalidadesRoutes),
      },
      {
        path: 'funcionarios',
        canActivate: [permissaoGuard({ perfis: ['Admin'] })],
        loadChildren: () =>
          import('./features/funcionarios/funcionarios.routes').then((m) => m.funcionariosRoutes),
      },
      {
        path: 'configuracoes',
        canActivate: [permissaoGuard({ perfis: ['Admin'] })],
        loadChildren: () =>
          import('./features/configuracoes/configuracoes.routes').then((m) => m.configuracoesRoutes),
      },
      {
        path: 'catraca',
        canActivate: [permissaoGuard({ perfis: ['Admin'] })],
        loadChildren: () =>
          import('./features/catraca/catraca.routes').then((m) => m.catracaRoutes),
      },
      {
        path: 'planos',
        canActivate: [permissaoGuard({ perfis: ['Admin'] })],
        loadChildren: () =>
          import('./features/planos/planos.routes').then((m) => m.planosRoutes),
      },
      {
        path: 'financeiro',
        canActivate: [permissaoGuard({ perfis: ['Admin', 'Secretaria'] })],
        loadChildren: () =>
          import('./features/financeiro/financeiro.routes').then((m) => m.financeiroRoutes),
      },
      {
        path: 'relatorios',
        canActivate: [permissaoGuard('tela_relatorio_presencas')],
        loadChildren: () =>
          import('./features/relatorios/relatorios.routes').then((m) => m.relatoriosRoutes),
      },
      {
        path: 'contratos',
        canActivate: [permissaoGuard({ perfis: ['Admin'] })],
        loadChildren: () =>
          import('./features/contratos/contratos.routes').then((m) => m.contratosRoutes),
      },
      {
        path: 'grupos-familiares',
        canActivate: [permissaoGuard('acesso_grupo_familiar')],
        loadChildren: () =>
          import('./features/grupos-familiares/grupos-familiares.routes').then((m) => m.gruposFamiliaresRoutes),
      },
    ],
  },
  {
    path: 'assinar/:token',
    loadComponent: () =>
      import('./features/contratos/pages/assinar/assinar-contrato.component').then((m) => m.AssinarContratoComponent),
    title: 'Assinar Contrato',
    // Página de assinatura de contrato com token na própria URL — nunca pode ser indexada/cacheada publicamente.
    data: { robots: 'noindex, nofollow' },
  },
  {
    path: 'privacidade',
    loadComponent: () =>
      import('./features/legal/privacidade.component').then((m) => m.PrivacidadeComponent),
    title: 'Política de Privacidade — Sensei Manager',
    data: { description: 'Política de privacidade do Sensei Manager.', robots: 'index, follow' },
  },
  {
    path: 'termos',
    loadComponent: () =>
      import('./features/legal/termos.component').then((m) => m.TermosComponent),
    title: 'Termos de Uso — Sensei Manager',
    data: { description: 'Termos de uso do Sensei Manager.', robots: 'index, follow' },
  },
  {
    path: '**',
    redirectTo: '',
  },
];
