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

export function ehProfessor(user: StoredUser | null): boolean {
  return user?.perfil === 'Professor';
}

/**
 * Mesma regra do app mobile: o Professor só enxerga as turmas em que é o
 * professor titular, salvo com a permissão `acesso_turmas_todas`.
 */
export function veSomenteTurmasProprias(user: StoredUser | null): boolean {
  return ehProfessor(user) && !temPermissao(user, 'acesso_turmas_todas');
}

/** No app, mesmo a Secretaria só tem estas se a permissão estiver ligada. */
const EXIGEM_PERMISSAO_DA_SECRETARIA = new Set(['acesso_redefinir_senha', 'tela_relatorio_presencas']);

export function temPermissao(user: StoredUser | null, chave: string): boolean {
  if (!user) return false;
  if (user.perfil === 'Admin') return true;
  // A Secretaria usa a mesma área do Admin no app.
  if (user.perfil === 'Secretaria' && !EXIGEM_PERMISSAO_DA_SECRETARIA.has(chave)) return true;
  return user.permissoes?.[chave] === true;
}
