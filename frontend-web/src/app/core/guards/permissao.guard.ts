import { CanActivateFn, Router } from '@angular/router';
import { inject } from '@angular/core';
import { FirebaseAuthService } from '../services/firebase-auth.service';
import { temPermissao } from '../models/stored-user.model';

/**
 * Espelho de `temPermissao` em `mobile/lib/core/auth_storage.dart` — Admin
 * sempre passa, os outros perfis dependem da chave de permissão granular
 * (ver `core/models/permissoes.model.ts`).
 *
 * Nem toda tela do mobile é gateada por uma permissão granular — telas
 * como Configurações, Catraca, Planos e Contratos só existem pro perfil
 * Admin lá (sem chave em `kPermissoesDefault`), e Financeiro é liberado
 * tanto pra Admin quanto Secretaria incondicionalmente (mesma regra do
 * `FINANCE_ROLES` em `functions/finance-functions.js`). Pra esses casos,
 * passe `{ perfis: [...] }` em vez de uma chave de permissão.
 */
export function permissaoGuard(chave: string | { perfis: string[] }): CanActivateFn {
  return async (_route, _state) => {
    const authService = inject(FirebaseAuthService);
    const router = inject(Router);

    await authService.authReady;
    const user = authService.currentUser();
    if (!user) return router.createUrlTree(['/login']);

    if (typeof chave === 'string') {
      if (temPermissao(user, chave)) return true;
    } else if (chave.perfis.includes(user.perfil)) {
      return true;
    }

    return router.createUrlTree(['/app/dashboard']);
  };
}
