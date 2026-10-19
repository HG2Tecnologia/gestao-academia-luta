import { CanActivateFn, Router } from '@angular/router';
import { inject } from '@angular/core';
import { FirebaseAuthService } from '../services/firebase-auth.service';

export const guestGuard: CanActivateFn = async () => {
  const authService = inject(FirebaseAuthService);
  const router = inject(Router);

  await authService.authReady;

  if (authService.isAuthenticated()) {
    return router.createUrlTree(['/app/dashboard']);
  }

  return true;
};
