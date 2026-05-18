import { CanActivateFn, Router } from '@angular/router';
import { inject } from '@angular/core';
import { AuthService } from '../services/auth.service';

export function permissaoGuard(modulo: string): CanActivateFn {
  return (_route, _state) => {
    const authService = inject(AuthService);
    const router = inject(Router);

    const user = authService.currentUser();
    if (!user) return router.createUrlTree(['/login']);

    if (user.perfil === 'Admin') return true;

    if (user.permissoes?.[modulo] === true) return true;

    return router.createUrlTree(['/app/dashboard']);
  };
}
