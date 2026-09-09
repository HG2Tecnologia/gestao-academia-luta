import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/ad_service.dart';
import 'core/constants.dart';
import 'core/push_service.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/entrada_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/primeiro_acesso_screen.dart';
import 'screens/auth/esqueci_senha_screen.dart';
import 'screens/auth/cadastro_screen.dart';
import 'screens/auth/troca_senha_obrigatoria_screen.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/admin/dashboard_screen.dart';
import 'screens/admin/alunos_screen.dart';
import 'screens/admin/aluno_detalhe_screen.dart';
import 'screens/admin/aluno_criar_screen.dart';
import 'screens/admin/turmas_screen.dart';
import 'screens/admin/turma_detalhe_screen.dart';
import 'screens/admin/equipe_screen.dart';
import 'screens/admin/equipe_criar_screen.dart';
import 'screens/admin/financeiro_screen.dart';
import 'screens/admin/contas_academia_screen.dart';
import 'screens/admin/configuracoes_screen.dart';
import 'screens/admin/faixas_screen.dart';
import 'screens/admin/relatorio_anual_screen.dart';
import 'screens/admin/relatorio_presencas_screen.dart';
import 'screens/admin/aniversariantes_screen.dart';
import 'screens/professor/prof_presenca_historico_screen.dart';
import 'screens/admin/modelos_contrato_screen.dart';
import 'screens/admin/rankings_screen.dart';
import 'screens/admin/ranking_detalhe_screen.dart';
import 'screens/professor/professor_shell.dart';
import 'screens/professor/prof_dashboard_screen.dart';
import 'screens/professor/prof_turmas_screen.dart';
import 'screens/professor/prof_horarios_screen.dart';
import 'screens/professor/prof_perfil_screen.dart';
import 'screens/professor/prof_ranking_screen.dart';
import 'screens/aluno/aluno_shell.dart';
import 'screens/aluno/aluno_home_screen.dart';
import 'screens/aluno/aluno_perfil_screen.dart';
import 'screens/aluno/aluno_horarios_screen.dart';
import 'screens/aluno/aluno_presencas_screen.dart';
import 'screens/aluno/aluno_financeiro_screen.dart';
import 'screens/aluno/aluno_ranking_screen.dart';
import 'screens/aluno/aluno_graduacoes_screen.dart';
import 'screens/aluno/aluno_conquistas_screen.dart';
import 'screens/alterar_senha_screen.dart';
import 'screens/shared/qr_scan_screen.dart';
import 'screens/noticias_screen.dart';
import 'screens/admin/admin_noticias_screen.dart';
import 'screens/admin/grupos_familiares_screen.dart';
import 'screens/admin/admin_pesquisa_screen.dart';
import 'screens/admin/admin_pesquisa_templates_screen.dart';
import 'screens/admin/admin_evasao_screen.dart';
import 'screens/aluno/aluno_parq_screen.dart';

final routerKey = GlobalKey<NavigatorState>();

/// Extrai o `contexto` ('aluno'/'academia') de um `state.extra` do
/// GoRouter, usado para manter a tela de login contextualizada ao ir e
/// voltar entre Primeiro acesso / Esqueci minha senha.
String? _contextoFrom(Object? extra) =>
    extra is Map ? extra['contexto'] as String? : null;

/// Aponta o app para os emuladores locais do Firebase quando rodado com
/// `--dart-define=USE_FIREBASE_EMULATOR=true`. Inerte em release (default
/// false), então não afeta produção nem as lojas.
const _kUseFirebaseEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');

Future<void> _conectarEmuladores() async {
  // Android emulador enxerga a máquina host em 10.0.2.2; iOS/desktop em
  // localhost. Pode sobrescrever com --dart-define=EMULATOR_HOST=<ip>.
  const override = String.fromEnvironment('EMULATOR_HOST');
  final host = override.isNotEmpty
      ? override
      : (defaultTargetPlatform == TargetPlatform.android
            ? '10.0.2.2'
            : 'localhost');
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
  debugPrint('🔧 Firebase apontado para emuladores em $host');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (_kUseFirebaseEmulator) await _conectarEmuladores();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await AdService.instance.init();
  runApp(const TatameApp());
}

final _router = GoRouter(
  navigatorKey: routerKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(
      path: '/alterar-senha',
      builder: (_, __) => const AlterarSenhaScreen(),
    ),
    GoRoute(path: '/boas-vindas', builder: (_, __) => const EntradaScreen()),
    GoRoute(
      path: '/login',
      builder: (_, state) => LoginScreen(contexto: _contextoFrom(state.extra)),
    ),
    GoRoute(
      path: '/primeiro-acesso',
      builder: (_, state) =>
          PrimeiroAcessoScreen(contexto: _contextoFrom(state.extra)),
    ),
    GoRoute(path: '/cadastrar', builder: (_, __) => const CadastroScreen()),
    GoRoute(
      path: '/troca-senha-obrigatoria',
      builder: (_, __) => const TrocaSenhaObrigatoriaScreen(),
    ),
    GoRoute(
      path: '/esqueci-senha',
      builder: (_, state) =>
          EsqueciSenhaScreen(contexto: _contextoFrom(state.extra)),
    ),
    GoRoute(path: '/scan-qr', builder: (_, __) => const QrScanScreen()),
    GoRoute(path: '/noticias', builder: (_, __) => const NoticiasScreen()),
    GoRoute(
      path: '/admin/noticias',
      builder: (_, __) => const AdminNoticiasScreen(),
    ),
    GoRoute(
      path: '/admin/grupos-familiares',
      builder: (_, __) => const AdminGruposFamiliaresScreen(),
    ),
    GoRoute(
      path: '/admin/evasao',
      builder: (_, __) => const AdminEvasaoScreen(),
    ),
    GoRoute(path: '/aluno/parq', builder: (_, __) => const AlunoParQScreen()),
    GoRoute(
      path: '/admin/pesquisa',
      builder: (_, state) =>
          AdminPesquisaScreen(template: state.extra as Map<String, dynamic>?),
    ),
    GoRoute(
      path: '/admin/pesquisa/templates',
      builder: (_, __) => const AdminPesquisaTemplatesScreen(),
    ),
    GoRoute(
      path: '/admin/rankings',
      builder: (_, __) => const AdminRankingsScreen(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (_, state) => AdminRankingDetalheScreen(
            rankingId: state.pathParameters['id']!,
            rankingExtra: state.extra as Map<String, dynamic>?,
          ),
        ),
      ],
    ),

    // Admin
    StatefulShellRoute.indexedStack(
      builder: (_, __, shell) => AdminShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/admin/dashboard',
              builder: (_, __) => const AdminDashboardScreen(),
              routes: [
                GoRoute(
                  path: 'configuracoes',
                  builder: (_, __) => const AdminConfiguracoesScreen(),
                ),
                GoRoute(
                  path: 'faixas',
                  builder: (_, __) => const AdminFaixasScreen(),
                ),
                GoRoute(
                  path: 'contratos',
                  builder: (_, __) => const AdminModelosContratoScreen(),
                ),
                GoRoute(
                  path: 'aniversariantes',
                  builder: (_, __) => const AdminAniversariantesScreen(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/admin/alunos',
              builder: (_, __) => const AdminAlunosScreen(),
              routes: [
                GoRoute(
                  path: 'novo',
                  builder: (_, __) => const AdminAlunoCriarScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (_, state) => AdminAlunoDetalheScreen(
                    alunoId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/admin/turmas',
              builder: (_, __) => const AdminTurmasScreen(),
              routes: [
                GoRoute(
                  path: 'relatorio',
                  builder: (_, __) => const AdminRelatorioPresencasScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (_, state) => AdminTurmaDetalheScreen(
                    turmaId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/admin/equipe',
              builder: (_, __) => const AdminEquipeScreen(),
              routes: [
                GoRoute(
                  path: 'novo',
                  builder: (_, __) => const AdminEquipeCriarScreen(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/admin/financeiro',
              builder: (_, __) => const AdminFinanceiroScreen(),
              routes: [
                GoRoute(
                  path: 'relatorio',
                  builder: (_, __) => const AdminRelatorioAnualScreen(),
                ),
                GoRoute(
                  path: 'contas',
                  builder: (_, __) => const AdminContasAcademiaScreen(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/admin/ranking',
              builder: (_, __) => const ProfRankingScreen(),
            ),
          ],
        ),
      ],
    ),

    // Professor — reaproveita as telas do admin (com professorMode) para Turmas
    // e Alunos. Branches: 0 Início · 1 Turmas · 2 Alunos · 3 Horários ·
    // 4 Rankings · 5 Perfil.
    StatefulShellRoute.indexedStack(
      builder: (_, __, shell) => ProfessorShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/professor/dashboard',
              builder: (_, __) => const ProfDashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/professor/turmas',
              builder: (_, __) => const ProfTurmasScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, state) => AdminTurmaDetalheScreen(
                    turmaId: state.pathParameters['id']!,
                    professorMode: true,
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/professor/alunos',
              builder: (_, __) => const AdminAlunosScreen(professorMode: true),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, state) => AdminAlunoDetalheScreen(
                    alunoId: state.pathParameters['id']!,
                    professorMode: true,
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/professor/horarios',
              builder: (_, __) => const ProfHorariosScreen(),
              routes: [
                GoRoute(
                  path: ':id/presencas',
                  builder: (_, state) => ProfPresencaHistoricoScreen(
                    horarioId: state.pathParameters['id']!,
                    nomeTurma: state.uri.queryParameters['turma'] ?? '',
                    horario: state.uri.queryParameters['horario'] ?? '',
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/professor/rankings',
              builder: (_, __) => const ProfRankingScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/professor/perfil',
              builder: (_, __) => const ProfPerfilScreen(),
            ),
          ],
        ),
      ],
    ),

    // Aluno — telas fora da casca (sem NavigationBar inferior)
    GoRoute(
      path: '/aluno/presencas',
      builder: (_, s) =>
          AlunoPresencasScreen(filtroInicial: s.uri.queryParameters['filtro']),
    ),
    GoRoute(
      path: '/aluno/ranking',
      builder: (_, __) => const AlunoRankingScreen(),
      routes: [
        GoRoute(
          path: 'conquistas',
          builder: (_, __) => const AlunoConquistasScreen(),
        ),
      ],
    ),

    // Aluno — casca com NavigationBar (Início, Aulas, Graduações,
    // Financeiro, Perfil). A ordem das branches define o índice das abas.
    StatefulShellRoute.indexedStack(
      builder: (_, __, shell) => AlunoShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/aluno/inicio',
              builder: (_, __) => const AlunoHomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/aluno/horarios',
              builder: (_, __) => const AlunoHorariosScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/aluno/graduacoes',
              builder: (_, __) => const AlunoGraduacoesScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/aluno/financeiro',
              builder: (_, __) => const AlunoFinanceiroScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/aluno/perfil',
              builder: (_, __) => const AlunoPerfilScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

class TatameApp extends StatelessWidget {
  const TatameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Tatame',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('pt', 'BR'), Locale('en')],
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: kPrimary,
          surface: kSurface,
          onSurface: kText1,
          outline: kBorder,
        ),
        scaffoldBackgroundColor: kBg,
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: kSurface,
          indicatorColor: kPrimary.withOpacity(0.2),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TextStyle(
                color: kPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              );
            }
            return TextStyle(color: kText2, fontSize: 11);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(color: kPrimary);
            }
            return IconThemeData(color: kText2);
          }),
        ),
      ),
      routerConfig: _router,
    );
  }
}
