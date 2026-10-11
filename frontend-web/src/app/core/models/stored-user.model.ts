/**
 * Espelho de `StoredUser` em `mobile/lib/core/auth_storage.dart`. Mesmos
 * campos, mesma regra de `temPermissao` (Admin sempre tem tudo).
 */
export interface StoredUser {
  id: string;
  nome: string;
  email: string;
  perfil: string;
  academiaId: string | null;
  permissoes: Record<string, boolean>;
  perfis: Record<string, any>[];
  mustChangePassword: boolean;
}

export function temPermissao(user: StoredUser | null, chave: string): boolean {
  if (!user) return false;
  if (user.perfil === 'Admin') return true;
  return user.permissoes?.[chave] === true;
}
