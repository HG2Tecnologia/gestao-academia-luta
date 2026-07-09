/// Modalidades e faixas padrão que toda academia recebe ao ser criada.
/// Estrutura: { nome, cor, faixas: [{ nome, cor, ordem, tem_graus, max_graus }] }

const List<Map<String, dynamic>> kModalidadesDefault = [
  {
    'nome': 'Jiu-Jitsu Adulto',
    'cor': '#1565C0',
    'faixas': [
      {'nome': 'Branca',  'cor': '#F5F5F5', 'ordem': 1, 'tem_graus': true,  'max_graus': 4},
      {'nome': 'Azul',    'cor': '#1565C0', 'ordem': 2, 'tem_graus': true,  'max_graus': 4},
      {'nome': 'Roxa',    'cor': '#7B1FA2', 'ordem': 3, 'tem_graus': true,  'max_graus': 4},
      {'nome': 'Marrom',  'cor': '#5D4037', 'ordem': 4, 'tem_graus': true,  'max_graus': 4},
      {'nome': 'Preta',   'cor': '#212121', 'ordem': 5, 'tem_graus': true,  'max_graus': 6},
    ],
  },
  {
    'nome': 'Jiu-Jitsu Infantil',
    'cor': '#2E7D32',
    'faixas': [
      {'nome': 'Branca',         'cor': '#F5F5F5', 'ordem': 1,  'tem_graus': true, 'max_graus': 4},
      {'nome': 'Cinza/Branca',   'cor': '#90A4AE', 'ordem': 2,  'tem_graus': true, 'max_graus': 4},
      {'nome': 'Cinza',          'cor': '#607D8B', 'ordem': 3,  'tem_graus': true, 'max_graus': 4},
      {'nome': 'Cinza/Preta',    'cor': '#455A64', 'ordem': 4,  'tem_graus': true, 'max_graus': 4},
      {'nome': 'Amarela/Branca', 'cor': '#FDD835', 'ordem': 5,  'tem_graus': true, 'max_graus': 4},
      {'nome': 'Amarela',        'cor': '#F9A825', 'ordem': 6,  'tem_graus': true, 'max_graus': 4},
      {'nome': 'Amarela/Preta',  'cor': '#F57F17', 'ordem': 7,  'tem_graus': true, 'max_graus': 4},
      {'nome': 'Laranja/Branca', 'cor': '#FF8A65', 'ordem': 8,  'tem_graus': true, 'max_graus': 4},
      {'nome': 'Laranja',        'cor': '#F4511E', 'ordem': 9,  'tem_graus': true, 'max_graus': 4},
      {'nome': 'Laranja/Preta',  'cor': '#E64A19', 'ordem': 10, 'tem_graus': true, 'max_graus': 4},
      {'nome': 'Verde/Branca',   'cor': '#66BB6A', 'ordem': 11, 'tem_graus': true, 'max_graus': 4},
      {'nome': 'Verde',          'cor': '#388E3C', 'ordem': 12, 'tem_graus': true, 'max_graus': 4},
      {'nome': 'Verde/Preta',    'cor': '#1B5E20', 'ordem': 13, 'tem_graus': true, 'max_graus': 4},
    ],
  },
  {
    'nome': 'Muay Thai',
    'cor': '#C62828',
    'faixas': [
      {'nome': 'Branca',   'cor': '#F5F5F5', 'ordem': 1, 'tem_graus': false, 'max_graus': 0},
      {'nome': 'Amarela',  'cor': '#F9A825', 'ordem': 2, 'tem_graus': false, 'max_graus': 0},
      {'nome': 'Laranja',  'cor': '#F4511E', 'ordem': 3, 'tem_graus': false, 'max_graus': 0},
      {'nome': 'Verde',    'cor': '#388E3C', 'ordem': 4, 'tem_graus': false, 'max_graus': 0},
      {'nome': 'Azul',     'cor': '#1565C0', 'ordem': 5, 'tem_graus': false, 'max_graus': 0},
      {'nome': 'Vermelha', 'cor': '#C62828', 'ordem': 6, 'tem_graus': false, 'max_graus': 0},
      {'nome': 'Marrom',   'cor': '#5D4037', 'ordem': 7, 'tem_graus': false, 'max_graus': 0},
      {'nome': 'Preta',    'cor': '#212121', 'ordem': 8, 'tem_graus': false, 'max_graus': 0},
    ],
  },
  {
    'nome': 'Karatê',
    'cor': '#E65100',
    'faixas': [
      {'nome': 'Branca',   'cor': '#F5F5F5', 'ordem': 1, 'tem_graus': false, 'max_graus': 0},
      {'nome': 'Amarela',  'cor': '#F9A825', 'ordem': 2, 'tem_graus': false, 'max_graus': 0},
      {'nome': 'Laranja',  'cor': '#F4511E', 'ordem': 3, 'tem_graus': false, 'max_graus': 0},
      {'nome': 'Verde',    'cor': '#388E3C', 'ordem': 4, 'tem_graus': false, 'max_graus': 0},
      {'nome': 'Azul',     'cor': '#1565C0', 'ordem': 5, 'tem_graus': false, 'max_graus': 0},
      {'nome': 'Vermelha', 'cor': '#C62828', 'ordem': 6, 'tem_graus': false, 'max_graus': 0},
      {'nome': 'Marrom',   'cor': '#5D4037', 'ordem': 7, 'tem_graus': false, 'max_graus': 0},
      {'nome': 'Preta',    'cor': '#212121', 'ordem': 8, 'tem_graus': false, 'max_graus': 0},
    ],
  },
  {
    'nome': 'Judô',
    'cor': '#4A148C',
    'faixas': [
      {'nome': 'Branca',   'cor': '#F5F5F5', 'ordem': 1, 'tem_graus': false, 'max_graus': 0},
      {'nome': 'Amarela',  'cor': '#F9A825', 'ordem': 2, 'tem_graus': false, 'max_graus': 0},
      {'nome': 'Laranja',  'cor': '#F4511E', 'ordem': 3, 'tem_graus': false, 'max_graus': 0},
      {'nome': 'Verde',    'cor': '#388E3C', 'ordem': 4, 'tem_graus': false, 'max_graus': 0},
      {'nome': 'Azul',     'cor': '#1565C0', 'ordem': 5, 'tem_graus': false, 'max_graus': 0},
      {'nome': 'Marrom',   'cor': '#5D4037', 'ordem': 6, 'tem_graus': false, 'max_graus': 0},
      {'nome': 'Preta',    'cor': '#212121', 'ordem': 7, 'tem_graus': false, 'max_graus': 0},
    ],
  },
  {
    'nome': 'Boxe',
    'cor': '#B71C1C',
    'faixas': [
      {'nome': 'Iniciante',     'cor': '#90CAF9', 'ordem': 1, 'tem_graus': false, 'max_graus': 0},
      {'nome': 'Intermediário', 'cor': '#42A5F5', 'ordem': 2, 'tem_graus': false, 'max_graus': 0},
      {'nome': 'Avançado',      'cor': '#1565C0', 'ordem': 3, 'tem_graus': false, 'max_graus': 0},
    ],
  },
  {
    'nome': 'Kickboxing',
    'cor': '#880E4F',
    'faixas': [
      {'nome': 'Branca',   'cor': '#F5F5F5', 'ordem': 1, 'tem_graus': false, 'max_graus': 0},
      {'nome': 'Amarela',  'cor': '#F9A825', 'ordem': 2, 'tem_graus': false, 'max_graus': 0},
      {'nome': 'Laranja',  'cor': '#F4511E', 'ordem': 3, 'tem_graus': false, 'max_graus': 0},
      {'nome': 'Verde',    'cor': '#388E3C', 'ordem': 4, 'tem_graus': false, 'max_graus': 0},
      {'nome': 'Azul',     'cor': '#1565C0', 'ordem': 5, 'tem_graus': false, 'max_graus': 0},
      {'nome': 'Vermelha', 'cor': '#C62828', 'ordem': 6, 'tem_graus': false, 'max_graus': 0},
      {'nome': 'Preta',    'cor': '#212121', 'ordem': 7, 'tem_graus': false, 'max_graus': 0},
    ],
  },
  {
    'nome': 'MMA',
    'cor': '#37474F',
    'faixas': [
      {'nome': 'Iniciante',     'cor': '#90CAF9', 'ordem': 1, 'tem_graus': false, 'max_graus': 0},
      {'nome': 'Intermediário', 'cor': '#42A5F5', 'ordem': 2, 'tem_graus': false, 'max_graus': 0},
      {'nome': 'Avançado',      'cor': '#1565C0', 'ordem': 3, 'tem_graus': false, 'max_graus': 0},
    ],
  },
];
