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
    return true;
  }

  return router.createUrlTree(['/login']);
};
