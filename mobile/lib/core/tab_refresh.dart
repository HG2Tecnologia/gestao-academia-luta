import 'package:flutter/foundation.dart';

// Notifica telas dentro de StatefulShellRoute.indexedStack quando uma aba
// é selecionada, permitindo que recarreguem dados ao ganhar foco.
final alunoTabNotifier = ValueNotifier<int>(0);
final adminTabNotifier = ValueNotifier<int>(0);

// Ações disparadas pelo drawer do aluno para a tela de perfil
final alunoDrawerActionNotifier = ValueNotifier<String>('');
