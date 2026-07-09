// Chaves de permissão usadas para professor e secretaria.
// Admin ignora todas — sempre tem acesso total.

const kPermissoesDefault = {
  'Professor': {
    'tela_turmas': true,
    'tela_horarios': true,
    'tela_presenca': true,
    'tela_graduacao': true,
    'tela_rankings': true,
    'acao_dar_presenca': true,
    'acao_graduar': true,
  },
  'Secretaria': {
    'tela_turmas': true,
    'tela_horarios': true,
    'tela_presenca': true,
    'tela_graduacao': true,
    'tela_rankings': true,
    'acao_dar_presenca': true,
    'acao_graduar': true,
  },
};

// label, descrição
const kPermissoesInfo = <String, (String, String)>{
  'tela_turmas':     ('Ver Turmas',             'Visualizar a lista de turmas'),
  'tela_horarios':   ('Ver Horários',            'Acessar a grade de horários'),
  'tela_presenca':   ('Acessar Presença',        'Ver a tela de chamada'),
  'tela_graduacao':  ('Acessar Graduação',       'Ver a tela de promoção de faixas'),
  'tela_rankings':   ('Ver Rankings',            'Visualizar o ranking da academia'),
  'acao_dar_presenca':('Registrar Presença',     'Marcar alunos como presentes'),
  'acao_graduar':    ('Graduar Alunos',          'Promover alunos para nova faixa'),
};

Map<String, bool> permissoesParaPerfil(String perfil) {
  final defaults = kPermissoesDefault[perfil];
  if (defaults == null) return {};
  return Map<String, bool>.from(defaults);
}
