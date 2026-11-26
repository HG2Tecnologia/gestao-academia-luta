import { inject } from '@angular/core';
import { Router, UrlTree } from '@angular/router';
import { AcessoWebService } from '../services/acesso-web.service';
import { FirebaseAuthService } from '../services/firebase-auth.service';

/**
 * Manda para `/assinatura` a academia sem direito ao web. Login e senha
 * obrigatória continuam por conta do `authGuard`.
 */
export async function acessoWebGuard(): Promise<boolean | UrlTree> {
  const authService = inject(FirebaseAuthService);
  const acessoService = inject(AcessoWebService);
  const router = inject(Router);

  await authService.authReady;
  if (!authService.isAuthenticated()) return true;

  const acesso = await acessoService.verificar();
  return acesso && !acesso.liberado ? router.createUrlTree(['/assinatura']) : true;
}
