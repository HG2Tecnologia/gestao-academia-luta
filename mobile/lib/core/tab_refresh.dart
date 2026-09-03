import 'package:flutter/foundation.dart';

// Notifica telas dentro de StatefulShellRoute.indexedStack quando uma aba
// é selecionada, permitindo que recarreguem dados ao ganhar foco.
final alunoTabNotifier = ValueNotifier<int>(0);
final adminTabNotifier = ValueNotifier<int>(0);

// Ações disparadas pelo drawer do aluno para a tela de perfil
final alunoDrawerActionNotifier = ValueNotifier<String>('');

// Incrementado sempre que o usuário troca de perfil (mostrarTrocarPerfil).
// Telas "raiz" de cada área (dashboard, minhas turmas, perfil do aluno)
// escutam isso para recarregar mesmo quando a rota de destino é a mesma em
// que já estavam (ex: trocar entre dois perfis de Aluno).
final perfilTrocadoNotifier = ValueNotifier<int>(0);
