// Chaves de permissão usadas para professor e secretaria.
// Admin ignora todas — sempre tem acesso total.

const kPermissoesDefault = {
  'Professor': {
    'tela_turmas': true,
    'tela_alunos': false,
    'tela_horarios': true,
    'tela_rankings': true,
    'acao_dar_presenca': true,
    'acao_graduar': true,
    'acao_editar_aluno_basico': false,
    'acesso_turmas_todas': false,
    'tela_relatorio_presencas': false,
    'acesso_redefinir_senha': false,
    'acesso_saude_aluno': false,
    'acesso_grupo_familiar': false,
    'acesso_gerenciar_acesso_app': false,
  },
  'Secretaria': {
    'tela_turmas': true,
    'tela_alunos': false,
    'tela_horarios': true,
    'tela_rankings': true,
    'acao_dar_presenca': true,
    'acao_graduar': true,
    'acao_editar_aluno_basico': false,
    'acesso_turmas_todas': false,
    'acesso_redefinir_senha': false,
    'tela_relatorio_presencas': false,
    // Secretaria já via/editava isso incondicionalmente antes de virar
    // permissão — default true preserva o comportamento atual sem exigir
    // reconfiguração de ninguém.
    'acesso_saude_aluno': true,
    'acesso_grupo_familiar': true,
    'acesso_gerenciar_acesso_app': true,
  },
};

// label, descrição
const kPermissoesInfo = <String, (String, String)>{
  'tela_turmas': ('Ver Turmas', 'Visualizar a lista de turmas'),
  'tela_alunos': ('Ver Alunos', 'Acessar a lista de alunos das turmas dele'),
  'tela_horarios': ('Ver Horários', 'Acessar a grade de horários'),
  'tela_rankings': ('Ver Rankings', 'Visualizar o ranking da academia'),
  'acao_dar_presenca': ('Registrar Presença', 'Marcar alunos como presentes'),
  'acao_graduar': ('Graduar Alunos', 'Promover alunos para nova faixa'),
  'acao_editar_aluno_basico': (
    'Editar dados do aluno',
    'Alterar nome e telefone do aluno',
  ),
  'acesso_turmas_todas': (
    'Ver todas as turmas',
    'Além das próprias, ver e acompanhar todas as turmas da academia (como um admin)',
  ),
  'acesso_redefinir_senha': (
    'Redefinir senha de outros',
    'Gerar uma senha temporária para alunos ou equipe que perderam o acesso',
  ),
  'tela_relatorio_presencas': (
    'Relatório de Presenças',
    'Ver e exportar o relatório oficial de presenças e faltas dos alunos',
  ),
  'acesso_saude_aluno': (
    'Dados de saúde do aluno',
    'Ver atestado médico e PAR-Q na ficha do aluno',
  ),
  'acesso_grupo_familiar': (
    'Grupo familiar',
    'Ver e gerenciar o grupo familiar do aluno',
  ),
  'acesso_gerenciar_acesso_app': (
    'Gerenciar acesso ao app',
    'Liberar ou bloquear o acesso do aluno ao app',
  ),
};

Map<String, bool> permissoesParaPerfil(String perfil) {
  final defaults = kPermissoesDefault[perfil];
  if (defaults == null) return {};
  return Map<String, bool>.from(defaults);
}
