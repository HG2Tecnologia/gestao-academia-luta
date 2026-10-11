/**
 * Espelho exato de `mobile/lib/core/permissoes.dart` — mesmas chaves, mesmos
 * defaults por perfil. Admin ignora tudo isso e sempre tem acesso total (ver
 * `temPermissao` em `auth.service.ts`), igual no app.
 *
 * Ao adicionar uma permissão nova aqui, adicione a mesma chave no Dart (e
 * vice-versa) — os dois têm que ficar sempre em sincronia.
 */
export type PerfilComPermissoes = 'Professor' | 'Secretaria';

export const PERMISSOES_DEFAULT: Record<PerfilComPermissoes, Record<string, boolean>> = {
  Professor: {
    tela_turmas: true,
    tela_alunos: false,
    tela_horarios: true,
    tela_rankings: true,
    acao_dar_presenca: true,
    acao_graduar: true,
    acao_editar_aluno_basico: false,
    acesso_turmas_todas: false,
    tela_relatorio_presencas: false,
    acesso_redefinir_senha: false,
    acesso_saude_aluno: false,
    acesso_grupo_familiar: false,
    acesso_gerenciar_acesso_app: false,
  },
  Secretaria: {
    tela_turmas: true,
    tela_alunos: false,
    tela_horarios: true,
    tela_rankings: true,
    acao_dar_presenca: true,
    acao_graduar: true,
    acao_editar_aluno_basico: false,
    acesso_turmas_todas: false,
    acesso_redefinir_senha: false,
    tela_relatorio_presencas: false,
    // Secretaria já via/editava isso incondicionalmente antes de virar
    // permissão — default true preserva o comportamento atual sem exigir
    // reconfiguração de ninguém.
    acesso_saude_aluno: true,
    acesso_grupo_familiar: true,
    acesso_gerenciar_acesso_app: true,
  },
};

export interface PermissaoInfo {
  label: string;
  descricao: string;
}

export const PERMISSOES_INFO: Record<string, PermissaoInfo> = {
  tela_turmas: { label: 'Ver Turmas', descricao: 'Visualizar a lista de turmas' },
  tela_alunos: { label: 'Ver Alunos', descricao: 'Acessar a lista de alunos das turmas dele' },
  tela_horarios: { label: 'Ver Horários', descricao: 'Acessar a grade de horários' },
  tela_rankings: { label: 'Ver Rankings', descricao: 'Visualizar o ranking da academia' },
  acao_dar_presenca: { label: 'Registrar Presença', descricao: 'Marcar alunos como presentes' },
  acao_graduar: { label: 'Graduar Alunos', descricao: 'Promover alunos para nova faixa' },
  acao_editar_aluno_basico: {
    label: 'Editar dados do aluno',
    descricao: 'Alterar nome e telefone do aluno',
  },
  acesso_turmas_todas: {
    label: 'Ver todas as turmas',
    descricao: 'Além das próprias, ver e acompanhar todas as turmas da academia (como um admin)',
  },
  acesso_redefinir_senha: {
    label: 'Redefinir senha de outros',
    descricao: 'Gerar uma senha temporária para alunos ou equipe que perderam o acesso',
  },
  tela_relatorio_presencas: {
    label: 'Relatório de Presenças',
    descricao: 'Ver e exportar o relatório oficial de presenças e faltas dos alunos',
  },
  acesso_saude_aluno: {
    label: 'Dados de saúde do aluno',
    descricao: 'Ver atestado médico e PAR-Q na ficha do aluno',
  },
  acesso_grupo_familiar: {
    label: 'Grupo familiar',
    descricao: 'Ver e gerenciar o grupo familiar do aluno',
  },
  acesso_gerenciar_acesso_app: {
    label: 'Gerenciar acesso ao app',
    descricao: 'Liberar ou bloquear o acesso do aluno ao app',
  },
};

export function permissoesParaPerfil(perfil: string): Record<string, boolean> {
  const defaults = PERMISSOES_DEFAULT[perfil as PerfilComPermissoes];
  return defaults ? { ...defaults } : {};
}
