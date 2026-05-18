import { CanActivateFn, Router } from '@angular/router';
import { inject } from '@angular/core';
import { AuthService } from '../services/auth.service';

export const authGuard: CanActivateFn = (_route, _state) => {
  const authService = inject(AuthService);
  const router = inject(Router);

  if (authService.isAuthenticated()) {
    return true;
  }

  // Access token expired but refresh token still exists → allow entry.
  // The HTTP interceptor will refresh on the first 401 automatically.
  if (authService.getRefreshToken()) {
    return true;
  }

  return router.createUrlTree(['/login']);
};
