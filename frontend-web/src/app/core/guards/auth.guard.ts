import { CanActivateFn, Router } from '@angular/router';
import { inject } from '@angular/core';
import { FirebaseAuthService } from '../services/firebase-auth.service';

export const authGuard: CanActivateFn = async (_route, _state) => {
  const authService = inject(FirebaseAuthService);
  const router = inject(Router);

  // Espera o Firebase Auth terminar de restaurar a sessão persistida antes
  // de decidir — sem isso, um F5 na página deslogava todo mundo (o SDK
  // ainda não tinha confirmado `auth.currentUser` no primeiro tick).
  await authService.authReady;

  if (authService.isAuthenticated()) {
    // Senha temporária: nada do sistema abre antes da troca (igual ao app).
    return authService.currentUser()?.mustChangePassword
      ? router.createUrlTree(['/troca-senha-obrigatoria'])
      : true;
  }

  return router.createUrlTree(['/login']);
};

export const trocaSenhaGuard: CanActivateFn = async () => {
  const authService = inject(FirebaseAuthService);
  const router = inject(Router);

  await authService.authReady;

  if (!authService.isAuthenticated()) return router.createUrlTree(['/login']);
  return authService.currentUser()?.mustChangePassword ? true : router.createUrlTree(['/app/dashboard']);
};
