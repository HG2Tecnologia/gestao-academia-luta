import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// No description provided for @appTagline.
  ///
  /// In pt, this message translates to:
  /// **'Gestão inteligente para academia de lutas'**
  String get appTagline;

  /// No description provided for @commonSave.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get commonDelete;

  /// No description provided for @commonRemove.
  ///
  /// In pt, this message translates to:
  /// **'Remover'**
  String get commonRemove;

  /// No description provided for @commonEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get commonEdit;

  /// No description provided for @commonBack.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get commonBack;

  /// No description provided for @commonNext.
  ///
  /// In pt, this message translates to:
  /// **'Avançar'**
  String get commonNext;

  /// No description provided for @commonContinue.
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get commonContinue;

  /// No description provided for @commonConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar'**
  String get commonConfirm;

  /// No description provided for @commonClose.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get commonClose;

  /// No description provided for @commonRetry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get commonRetry;

  /// No description provided for @commonUnderstood.
  ///
  /// In pt, this message translates to:
  /// **'Entendi'**
  String get commonUnderstood;

  /// No description provided for @commonRequiredField.
  ///
  /// In pt, this message translates to:
  /// **'Obrigatório'**
  String get commonRequiredField;

  /// No description provided for @commonLoading.
  ///
  /// In pt, this message translates to:
  /// **'Carregando...'**
  String get commonLoading;

  /// No description provided for @commonGenericError.
  ///
  /// In pt, this message translates to:
  /// **'Algo deu errado. Tente novamente.'**
  String get commonGenericError;

  /// No description provided for @commonNoConnection.
  ///
  /// In pt, this message translates to:
  /// **'Sem conexão com a internet.'**
  String get commonNoConnection;

  /// No description provided for @commonMinChars.
  ///
  /// In pt, this message translates to:
  /// **'Mínimo {count} caracteres'**
  String commonMinChars(int count);

  /// No description provided for @commonPasswordsDontMatch.
  ///
  /// In pt, this message translates to:
  /// **'As senhas não coincidem'**
  String get commonPasswordsDontMatch;

  /// No description provided for @commonInvalidEmail.
  ///
  /// In pt, this message translates to:
  /// **'E-mail inválido'**
  String get commonInvalidEmail;

  /// No description provided for @commonYes.
  ///
  /// In pt, this message translates to:
  /// **'Sim'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In pt, this message translates to:
  /// **'Não'**
  String get commonNo;

  /// No description provided for @commonSeeAll.
  ///
  /// In pt, this message translates to:
  /// **'Ver todos'**
  String get commonSeeAll;

  /// No description provided for @commonSeeAllFem.
  ///
  /// In pt, this message translates to:
  /// **'Ver todas'**
  String get commonSeeAllFem;

  /// No description provided for @commonDescriptionOptional.
  ///
  /// In pt, this message translates to:
  /// **'Descrição (opcional)'**
  String get commonDescriptionOptional;

  /// No description provided for @commonSaveError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar. Tente novamente.'**
  String get commonSaveError;

  /// No description provided for @commonEnterValidValue.
  ///
  /// In pt, this message translates to:
  /// **'Informe um valor válido'**
  String get commonEnterValidValue;

  /// No description provided for @dashHello.
  ///
  /// In pt, this message translates to:
  /// **'Olá!'**
  String get dashHello;

  /// No description provided for @dashHelloName.
  ///
  /// In pt, this message translates to:
  /// **'Olá, {name}!'**
  String dashHelloName(String name);

  /// No description provided for @dashYourAcademyToday.
  ///
  /// In pt, this message translates to:
  /// **'Sua academia hoje'**
  String get dashYourAcademyToday;

  /// No description provided for @dashActiveStudents.
  ///
  /// In pt, this message translates to:
  /// **'Alunos ativos'**
  String get dashActiveStudents;

  /// No description provided for @dashActiveClasses.
  ///
  /// In pt, this message translates to:
  /// **'Turmas ativas'**
  String get dashActiveClasses;

  /// No description provided for @dashAttendanceToday.
  ///
  /// In pt, this message translates to:
  /// **'Presenças hoje'**
  String get dashAttendanceToday;

  /// No description provided for @dashOverdueAccounts.
  ///
  /// In pt, this message translates to:
  /// **'Inadimplentes'**
  String get dashOverdueAccounts;

  /// No description provided for @dashQuickActions.
  ///
  /// In pt, this message translates to:
  /// **'Ações rápidas'**
  String get dashQuickActions;

  /// No description provided for @dashNewStudent.
  ///
  /// In pt, this message translates to:
  /// **'Novo aluno'**
  String get dashNewStudent;

  /// No description provided for @dashNewClass.
  ///
  /// In pt, this message translates to:
  /// **'Nova turma'**
  String get dashNewClass;

  /// No description provided for @dashMarkAttendance.
  ///
  /// In pt, this message translates to:
  /// **'Registrar presença'**
  String get dashMarkAttendance;

  /// No description provided for @dashTrialActive.
  ///
  /// In pt, this message translates to:
  /// **'Trial gratuito ativo'**
  String get dashTrialActive;

  /// No description provided for @dashTrialLastDay.
  ///
  /// In pt, this message translates to:
  /// **'Último dia do trial!'**
  String get dashTrialLastDay;

  /// No description provided for @dashTrialDaysLeft.
  ///
  /// In pt, this message translates to:
  /// **'{days, plural, one{1 dia restante} other{{days} dias restantes}}'**
  String dashTrialDaysLeft(int days);

  /// No description provided for @dashSeePlans.
  ///
  /// In pt, this message translates to:
  /// **'Ver planos'**
  String get dashSeePlans;

  /// No description provided for @dashFreePlan.
  ///
  /// In pt, this message translates to:
  /// **'Plano Gratuito'**
  String get dashFreePlan;

  /// No description provided for @dashFreePlanLimits.
  ///
  /// In pt, this message translates to:
  /// **'Limite: 3 turmas · 10 alunos/turma · anúncios'**
  String get dashFreePlanLimits;

  /// No description provided for @dashSubscribePro.
  ///
  /// In pt, this message translates to:
  /// **'Assinar PRO'**
  String get dashSubscribePro;

  /// No description provided for @dashGettingStarted.
  ///
  /// In pt, this message translates to:
  /// **'Primeiros passos'**
  String get dashGettingStarted;

  /// No description provided for @dashGettingStartedSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Configure sua academia em ordem'**
  String get dashGettingStartedSubtitle;

  /// No description provided for @dashStepModality.
  ///
  /// In pt, this message translates to:
  /// **'Crie uma modalidade'**
  String get dashStepModality;

  /// No description provided for @dashStepModalityDesc.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Jiu-Jitsu, Muay Thai, Boxe.'**
  String get dashStepModalityDesc;

  /// No description provided for @dashStepPlan.
  ///
  /// In pt, this message translates to:
  /// **'Crie um plano de mensalidade'**
  String get dashStepPlan;

  /// No description provided for @dashStepPlanDesc.
  ///
  /// In pt, this message translates to:
  /// **'Defina valores e periodicidade.'**
  String get dashStepPlanDesc;

  /// No description provided for @dashStepInstructor.
  ///
  /// In pt, this message translates to:
  /// **'Cadastre um professor'**
  String get dashStepInstructor;

  /// No description provided for @dashStepInstructorDesc.
  ///
  /// In pt, this message translates to:
  /// **'Turmas precisam de um professor responsável.'**
  String get dashStepInstructorDesc;

  /// No description provided for @dashStepClass.
  ///
  /// In pt, this message translates to:
  /// **'Monte uma turma'**
  String get dashStepClass;

  /// No description provided for @dashStepClassDesc.
  ///
  /// In pt, this message translates to:
  /// **'Agrupe alunos por modalidade e horário.'**
  String get dashStepClassDesc;

  /// No description provided for @dashStepFirstStudent.
  ///
  /// In pt, this message translates to:
  /// **'Cadastre seu primeiro aluno'**
  String get dashStepFirstStudent;

  /// No description provided for @dashStepFirstStudentDesc.
  ///
  /// In pt, this message translates to:
  /// **'Adicione alunos e matricule nas turmas.'**
  String get dashStepFirstStudentDesc;

  /// No description provided for @dashAttendanceWatch.
  ///
  /// In pt, this message translates to:
  /// **'Risco de evasão'**
  String get dashAttendanceWatch;

  /// No description provided for @dashWatchRedSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, one{1 aluno sem treinar há 7+ dias} other{{count} alunos sem treinar há 7+ dias}}'**
  String dashWatchRedSubtitle(int count);

  /// No description provided for @dashWatchYellowSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, one{1 aluno com 7–13 dias de ausência} other{{count} alunos com 7–13 dias de ausência}}'**
  String dashWatchYellowSubtitle(int count);

  /// No description provided for @dashDaysCount.
  ///
  /// In pt, this message translates to:
  /// **'{days, plural, one{1 dia} other{{days} dias}}'**
  String dashDaysCount(int days);

  /// No description provided for @dashSeeAllStudents.
  ///
  /// In pt, this message translates to:
  /// **'Ver todos os {count} alunos'**
  String dashSeeAllStudents(int count);

  /// No description provided for @dashOpenListWhatsapp.
  ///
  /// In pt, this message translates to:
  /// **'Abrir lista (chamar no WhatsApp)'**
  String get dashOpenListWhatsapp;

  /// No description provided for @dashBirthdays.
  ///
  /// In pt, this message translates to:
  /// **'Aniversariantes'**
  String get dashBirthdays;

  /// No description provided for @dashThisMonth.
  ///
  /// In pt, this message translates to:
  /// **'Este mês'**
  String get dashThisMonth;

  /// No description provided for @dashNearingPromotion.
  ///
  /// In pt, this message translates to:
  /// **'Próximos de graduar'**
  String get dashNearingPromotion;

  /// No description provided for @dashNearingPromotionSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Alunos próximos do mínimo de aulas'**
  String get dashNearingPromotionSubtitle;

  /// No description provided for @dashNoOneNearingPromotion.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum aluno próximo da graduação'**
  String get dashNoOneNearingPromotion;

  /// No description provided for @dashClassesProgress.
  ///
  /// In pt, this message translates to:
  /// **'{done}/{needed} aulas'**
  String dashClassesProgress(int done, int needed);

  /// No description provided for @dashEligible.
  ///
  /// In pt, this message translates to:
  /// **'Apto!'**
  String get dashEligible;

  /// No description provided for @dashLatestNews.
  ///
  /// In pt, this message translates to:
  /// **'Últimas notícias'**
  String get dashLatestNews;

  /// No description provided for @dashNewModalityTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nova modalidade'**
  String get dashNewModalityTitle;

  /// No description provided for @dashNewModalityHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Jiu-Jitsu, Muay Thai, Boxe, Luta Livre'**
  String get dashNewModalityHint;

  /// No description provided for @dashModalityNameField.
  ///
  /// In pt, this message translates to:
  /// **'Nome da modalidade'**
  String get dashModalityNameField;

  /// No description provided for @dashCreateModality.
  ///
  /// In pt, this message translates to:
  /// **'Criar modalidade'**
  String get dashCreateModality;

  /// No description provided for @dashNewPlanTitle.
  ///
  /// In pt, this message translates to:
  /// **'Novo plano de mensalidade'**
  String get dashNewPlanTitle;

  /// No description provided for @dashNewPlanSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Defina o valor que seus alunos pagarão.'**
  String get dashNewPlanSubtitle;

  /// No description provided for @dashPlanNameField.
  ///
  /// In pt, this message translates to:
  /// **'Nome do plano (ex: Mensal, Trimestral)'**
  String get dashPlanNameField;

  /// No description provided for @dashPlanMonthlyValueField.
  ///
  /// In pt, this message translates to:
  /// **'Valor mensal (R\$)'**
  String get dashPlanMonthlyValueField;

  /// No description provided for @dashPlanEnrollmentFeeField.
  ///
  /// In pt, this message translates to:
  /// **'Taxa de matrícula (opcional)'**
  String get dashPlanEnrollmentFeeField;

  /// No description provided for @dashCreatePlan.
  ///
  /// In pt, this message translates to:
  /// **'Criar plano'**
  String get dashCreatePlan;

  /// No description provided for @dashWeeklyFrequency.
  ///
  /// In pt, this message translates to:
  /// **'Frequência semanal'**
  String get dashWeeklyFrequency;

  /// No description provided for @dashLast7Days.
  ///
  /// In pt, this message translates to:
  /// **'Últimos 7 dias'**
  String get dashLast7Days;

  /// No description provided for @dashNoAttendance7Days.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma presença registrada nos últimos 7 dias.'**
  String get dashNoAttendance7Days;

  /// No description provided for @dashTotalCount.
  ///
  /// In pt, this message translates to:
  /// **'{count} total'**
  String dashTotalCount(int count);

  /// No description provided for @navHome.
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get navHome;

  /// No description provided for @navDashboard.
  ///
  /// In pt, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navStudents.
  ///
  /// In pt, this message translates to:
  /// **'Alunos'**
  String get navStudents;

  /// No description provided for @navClasses.
  ///
  /// In pt, this message translates to:
  /// **'Turmas'**
  String get navClasses;

  /// No description provided for @navStaff.
  ///
  /// In pt, this message translates to:
  /// **'Equipe'**
  String get navStaff;

  /// No description provided for @navBilling.
  ///
  /// In pt, this message translates to:
  /// **'Financeiro'**
  String get navBilling;

  /// No description provided for @navRanking.
  ///
  /// In pt, this message translates to:
  /// **'Ranking'**
  String get navRanking;

  /// No description provided for @navMore.
  ///
  /// In pt, this message translates to:
  /// **'Mais'**
  String get navMore;

  /// No description provided for @menuSectionMain.
  ///
  /// In pt, this message translates to:
  /// **'PRINCIPAL'**
  String get menuSectionMain;

  /// No description provided for @menuSectionOther.
  ///
  /// In pt, this message translates to:
  /// **'OUTROS'**
  String get menuSectionOther;

  /// No description provided for @menuSectionAccount.
  ///
  /// In pt, this message translates to:
  /// **'CONTA'**
  String get menuSectionAccount;

  /// No description provided for @menuNews.
  ///
  /// In pt, this message translates to:
  /// **'Notícias'**
  String get menuNews;

  /// No description provided for @menuSettings.
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get menuSettings;

  /// No description provided for @menuSignOut.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get menuSignOut;

  /// No description provided for @roleAdmin.
  ///
  /// In pt, this message translates to:
  /// **'Administrador'**
  String get roleAdmin;

  /// No description provided for @roleStudent.
  ///
  /// In pt, this message translates to:
  /// **'Aluno'**
  String get roleStudent;

  /// No description provided for @roleTeacher.
  ///
  /// In pt, this message translates to:
  /// **'Professor'**
  String get roleTeacher;

  /// No description provided for @roleSecretary.
  ///
  /// In pt, this message translates to:
  /// **'Secretaria'**
  String get roleSecretary;

  /// No description provided for @psTitle.
  ///
  /// In pt, this message translates to:
  /// **'Trocar perfil'**
  String get psTitle;

  /// No description provided for @psSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Escolha quem está usando o app agora'**
  String get psSubtitle;

  /// No description provided for @psInUse.
  ///
  /// In pt, this message translates to:
  /// **'Em uso'**
  String get psInUse;

  /// No description provided for @psAccess.
  ///
  /// In pt, this message translates to:
  /// **'Acessar'**
  String get psAccess;

  /// No description provided for @adminPanelSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Painel de Gestão'**
  String get adminPanelSubtitle;

  /// No description provided for @signOutConfirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sair da conta?'**
  String get signOutConfirmTitle;

  /// No description provided for @signOutConfirmBody.
  ///
  /// In pt, this message translates to:
  /// **'Você precisará entrar novamente para acessar o app.'**
  String get signOutConfirmBody;

  /// No description provided for @settingsAppearanceSection.
  ///
  /// In pt, this message translates to:
  /// **'Aparência e idioma'**
  String get settingsAppearanceSection;

  /// No description provided for @settingsAppearanceSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Ajuste o tema e o idioma do aplicativo.'**
  String get settingsAppearanceSubtitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get settingsLanguage;

  /// No description provided for @settingsTheme.
  ///
  /// In pt, this message translates to:
  /// **'Tema'**
  String get settingsTheme;

  /// No description provided for @settingsLanguageSheetTitle.
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get settingsLanguageSheetTitle;

  /// No description provided for @settingsThemeSheetTitle.
  ///
  /// In pt, this message translates to:
  /// **'Tema'**
  String get settingsThemeSheetTitle;

  /// No description provided for @settingsOptionSystem.
  ///
  /// In pt, this message translates to:
  /// **'Automático'**
  String get settingsOptionSystem;

  /// No description provided for @settingsOptionSystemLanguageHint.
  ///
  /// In pt, this message translates to:
  /// **'Segue o idioma do dispositivo'**
  String get settingsOptionSystemLanguageHint;

  /// No description provided for @settingsOptionSystemThemeHint.
  ///
  /// In pt, this message translates to:
  /// **'Segue o tema do dispositivo'**
  String get settingsOptionSystemThemeHint;

  /// No description provided for @settingsLanguagePt.
  ///
  /// In pt, this message translates to:
  /// **'Português (Brasil)'**
  String get settingsLanguagePt;

  /// No description provided for @settingsLanguageEn.
  ///
  /// In pt, this message translates to:
  /// **'English'**
  String get settingsLanguageEn;

  /// No description provided for @settingsThemeLight.
  ///
  /// In pt, this message translates to:
  /// **'Claro'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In pt, this message translates to:
  /// **'Escuro'**
  String get settingsThemeDark;

  /// No description provided for @authWelcomeChooseAccess.
  ///
  /// In pt, this message translates to:
  /// **'Bem-vindo, escolha sua forma de acesso'**
  String get authWelcomeChooseAccess;

  /// No description provided for @authIAmStudentOrGuardianTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sou Aluno ou Responsável'**
  String get authIAmStudentOrGuardianTitle;

  /// No description provided for @authIAmStudentOrGuardianSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Treinos, graduações, financeiro e carteirinha'**
  String get authIAmStudentOrGuardianSubtitle;

  /// No description provided for @authIAmAcademyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sou uma Academia'**
  String get authIAmAcademyTitle;

  /// No description provided for @authIAmAcademySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Gerencie alunos, turmas, equipe e financeiro'**
  String get authIAmAcademySubtitle;

  /// No description provided for @authEmailOrPhone.
  ///
  /// In pt, this message translates to:
  /// **'E-mail ou Telefone'**
  String get authEmailOrPhone;

  /// No description provided for @authPassword.
  ///
  /// In pt, this message translates to:
  /// **'Senha'**
  String get authPassword;

  /// No description provided for @authSignIn.
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get authSignIn;

  /// No description provided for @authForgotPassword.
  ///
  /// In pt, this message translates to:
  /// **'Esqueci minha senha'**
  String get authForgotPassword;

  /// No description provided for @authFirstTimeAccess.
  ///
  /// In pt, this message translates to:
  /// **'Primeiro acesso'**
  String get authFirstTimeAccess;

  /// No description provided for @authCreateAcademy.
  ///
  /// In pt, this message translates to:
  /// **'Criar uma academia'**
  String get authCreateAcademy;

  /// No description provided for @authAccessAcademyPanel.
  ///
  /// In pt, this message translates to:
  /// **'Acesse o painel da sua academia'**
  String get authAccessAcademyPanel;

  /// No description provided for @authAccessStudentAccount.
  ///
  /// In pt, this message translates to:
  /// **'Acesse sua conta de aluno ou responsável'**
  String get authAccessStudentAccount;

  /// No description provided for @authEnterEmailOrPhone.
  ///
  /// In pt, this message translates to:
  /// **'Informe seu e-mail ou telefone.'**
  String get authEnterEmailOrPhone;

  /// No description provided for @authInvalidEmailShort.
  ///
  /// In pt, this message translates to:
  /// **'E-mail inválido.'**
  String get authInvalidEmailShort;

  /// No description provided for @authInvalidPhoneExample.
  ///
  /// In pt, this message translates to:
  /// **'Telefone inválido. Ex: (11) 99999-0000'**
  String get authInvalidPhoneExample;

  /// No description provided for @authWhichProfile.
  ///
  /// In pt, this message translates to:
  /// **'Qual perfil deseja acessar?'**
  String get authWhichProfile;

  /// No description provided for @authSigningIn.
  ///
  /// In pt, this message translates to:
  /// **'Autenticando...'**
  String get authSigningIn;

  /// No description provided for @authLoadingYourData.
  ///
  /// In pt, this message translates to:
  /// **'Carregando seus dados...'**
  String get authLoadingYourData;

  /// No description provided for @authAlmostThere.
  ///
  /// In pt, this message translates to:
  /// **'Quase lá...'**
  String get authAlmostThere;

  /// No description provided for @authErrWrongCredentials.
  ///
  /// In pt, this message translates to:
  /// **'E-mail ou senha incorretos. Se nunca acessou pelo app, use \"Esqueci minha senha\" para definir sua senha.'**
  String get authErrWrongCredentials;

  /// No description provided for @authErrAccountDisabled.
  ///
  /// In pt, this message translates to:
  /// **'Esta conta está desativada.'**
  String get authErrAccountDisabled;

  /// No description provided for @authErrTooManyRequests.
  ///
  /// In pt, this message translates to:
  /// **'Muitas tentativas. Aguarde alguns minutos e tente novamente.'**
  String get authErrTooManyRequests;

  /// No description provided for @authErrNetwork.
  ///
  /// In pt, this message translates to:
  /// **'Sem conexão com a internet.'**
  String get authErrNetwork;

  /// No description provided for @authErrGenericSignIn.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao autenticar. Verifique seus dados e tente novamente.'**
  String get authErrGenericSignIn;

  /// No description provided for @authErrTimeout.
  ///
  /// In pt, this message translates to:
  /// **'Tempo esgotado. Verifique sua conexão e tente novamente.'**
  String get authErrTimeout;

  /// No description provided for @authErrProfileNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Perfil de aluno não encontrado.'**
  String get authErrProfileNotFound;

  /// No description provided for @authErrAccountInactive.
  ///
  /// In pt, this message translates to:
  /// **'Seu cadastro está inativo. Entre em contato com a secretaria.'**
  String get authErrAccountInactive;

  /// No description provided for @authErrAppAccessSuspended.
  ///
  /// In pt, this message translates to:
  /// **'Seu acesso ao app está suspenso. Entre em contato com a secretaria.'**
  String get authErrAppAccessSuspended;

  /// No description provided for @authErrBlockedOverdue.
  ///
  /// In pt, this message translates to:
  /// **'Acesso bloqueado: mensalidade vencida. Regularize seu pagamento e tente novamente.'**
  String get authErrBlockedOverdue;

  /// No description provided for @forgotTitle.
  ///
  /// In pt, this message translates to:
  /// **'Esqueci minha senha'**
  String get forgotTitle;

  /// No description provided for @forgotHeadline.
  ///
  /// In pt, this message translates to:
  /// **'Recuperar acesso'**
  String get forgotHeadline;

  /// No description provided for @forgotInstruction.
  ///
  /// In pt, this message translates to:
  /// **'Informe seu e-mail e enviaremos um link para você criar uma nova senha.'**
  String get forgotInstruction;

  /// No description provided for @forgotEmailLabel.
  ///
  /// In pt, this message translates to:
  /// **'E-mail'**
  String get forgotEmailLabel;

  /// No description provided for @forgotEmailHint.
  ///
  /// In pt, this message translates to:
  /// **'seu@email.com'**
  String get forgotEmailHint;

  /// No description provided for @forgotSendButton.
  ///
  /// In pt, this message translates to:
  /// **'Enviar link de recuperação'**
  String get forgotSendButton;

  /// No description provided for @forgotSentTitle.
  ///
  /// In pt, this message translates to:
  /// **'E-mail enviado!'**
  String get forgotSentTitle;

  /// No description provided for @forgotSentBody.
  ///
  /// In pt, this message translates to:
  /// **'Verifique sua caixa de entrada (e spam). Clique no link recebido para criar sua nova senha.'**
  String get forgotSentBody;

  /// No description provided for @forgotErrEmailNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma conta encontrada com esse e-mail.'**
  String get forgotErrEmailNotFound;

  /// No description provided for @forgotErrInvalidEmail.
  ///
  /// In pt, this message translates to:
  /// **'E-mail inválido.'**
  String get forgotErrInvalidEmail;

  /// No description provided for @forgotErrTooManyRequests.
  ///
  /// In pt, this message translates to:
  /// **'Muitas tentativas. Aguarde alguns minutos.'**
  String get forgotErrTooManyRequests;

  /// No description provided for @forgotErrSendFailed.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao enviar e-mail. Tente novamente.'**
  String get forgotErrSendFailed;

  /// No description provided for @forgotErrUnexpected.
  ///
  /// In pt, this message translates to:
  /// **'Erro inesperado. Tente novamente.'**
  String get forgotErrUnexpected;

  /// No description provided for @changePwTitle.
  ///
  /// In pt, this message translates to:
  /// **'Alterar Senha'**
  String get changePwTitle;

  /// No description provided for @changePwHint.
  ///
  /// In pt, this message translates to:
  /// **'Use no mínimo 6 caracteres com letras e números.'**
  String get changePwHint;

  /// No description provided for @changePwCurrentLabel.
  ///
  /// In pt, this message translates to:
  /// **'Senha atual'**
  String get changePwCurrentLabel;

  /// No description provided for @changePwCurrentHint.
  ///
  /// In pt, this message translates to:
  /// **'Digite sua senha atual'**
  String get changePwCurrentHint;

  /// No description provided for @changePwNewLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nova senha'**
  String get changePwNewLabel;

  /// No description provided for @changePwNewHint.
  ///
  /// In pt, this message translates to:
  /// **'Digite a nova senha'**
  String get changePwNewHint;

  /// No description provided for @changePwConfirmLabel.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar nova senha'**
  String get changePwConfirmLabel;

  /// No description provided for @changePwConfirmHint.
  ///
  /// In pt, this message translates to:
  /// **'Repita a nova senha'**
  String get changePwConfirmHint;

  /// No description provided for @changePwMustBeDifferent.
  ///
  /// In pt, this message translates to:
  /// **'A nova senha deve ser diferente da atual'**
  String get changePwMustBeDifferent;

  /// No description provided for @changePwSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Senha alterada com sucesso!'**
  String get changePwSuccess;

  /// No description provided for @changePwErrWrongCurrent.
  ///
  /// In pt, this message translates to:
  /// **'Senha atual incorreta.'**
  String get changePwErrWrongCurrent;

  /// No description provided for @changePwErrWeak.
  ///
  /// In pt, this message translates to:
  /// **'A nova senha é muito fraca.'**
  String get changePwErrWeak;

  /// No description provided for @changePwErrGeneric.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao alterar senha. Tente novamente.'**
  String get changePwErrGeneric;

  /// No description provided for @studentsSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar aluno...'**
  String get studentsSearchHint;

  /// No description provided for @studentsEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum aluno encontrado.'**
  String get studentsEmpty;

  /// No description provided for @studentsLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os alunos.'**
  String get studentsLoadError;

  /// No description provided for @studentNoBelt.
  ///
  /// In pt, this message translates to:
  /// **'Sem graduação'**
  String get studentNoBelt;

  /// No description provided for @statusActive.
  ///
  /// In pt, this message translates to:
  /// **'Ativo'**
  String get statusActive;

  /// No description provided for @statusInactive.
  ///
  /// In pt, this message translates to:
  /// **'Inativo'**
  String get statusInactive;

  /// No description provided for @finUpToDate.
  ///
  /// In pt, this message translates to:
  /// **'Em dia'**
  String get finUpToDate;

  /// No description provided for @finPending.
  ///
  /// In pt, this message translates to:
  /// **'Pendente'**
  String get finPending;

  /// No description provided for @finOverdue.
  ///
  /// In pt, this message translates to:
  /// **'Inadimplente'**
  String get finOverdue;

  /// No description provided for @medicalCertificateShort.
  ///
  /// In pt, this message translates to:
  /// **'Atestado'**
  String get medicalCertificateShort;

  /// No description provided for @stripeLabel.
  ///
  /// In pt, this message translates to:
  /// **'{count}º Grau'**
  String stripeLabel(int count);

  /// No description provided for @sdTitleFallback.
  ///
  /// In pt, this message translates to:
  /// **'Aluno'**
  String get sdTitleFallback;

  /// No description provided for @sdActivate.
  ///
  /// In pt, this message translates to:
  /// **'Ativar'**
  String get sdActivate;

  /// No description provided for @sdDeactivate.
  ///
  /// In pt, this message translates to:
  /// **'Desativar'**
  String get sdDeactivate;

  /// No description provided for @sdNoAccessTitle.
  ///
  /// In pt, this message translates to:
  /// **'Você não tem acesso a este aluno.'**
  String get sdNoAccessTitle;

  /// No description provided for @sdNoAccessBody.
  ///
  /// In pt, this message translates to:
  /// **'Só é possível abrir alunos das suas turmas.'**
  String get sdNoAccessBody;

  /// No description provided for @sdNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Aluno não encontrado.'**
  String get sdNotFound;

  /// No description provided for @sdLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar aluno.'**
  String get sdLoadError;

  /// No description provided for @sdName.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get sdName;

  /// No description provided for @sdEmail.
  ///
  /// In pt, this message translates to:
  /// **'E-mail'**
  String get sdEmail;

  /// No description provided for @sdPhone.
  ///
  /// In pt, this message translates to:
  /// **'Telefone'**
  String get sdPhone;

  /// No description provided for @sdBirthDate.
  ///
  /// In pt, this message translates to:
  /// **'Nascimento'**
  String get sdBirthDate;

  /// No description provided for @sdBeltSection.
  ///
  /// In pt, this message translates to:
  /// **'Graduação'**
  String get sdBeltSection;

  /// No description provided for @sdPromote.
  ///
  /// In pt, this message translates to:
  /// **'Graduar'**
  String get sdPromote;

  /// No description provided for @sdCurrentBelt.
  ///
  /// In pt, this message translates to:
  /// **'Faixa atual'**
  String get sdCurrentBelt;

  /// No description provided for @sdNoGraduation.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma graduação'**
  String get sdNoGraduation;

  /// No description provided for @sdLevelXp.
  ///
  /// In pt, this message translates to:
  /// **'Nível / XP'**
  String get sdLevelXp;

  /// No description provided for @sdPlanSection.
  ///
  /// In pt, this message translates to:
  /// **'Plano'**
  String get sdPlanSection;

  /// No description provided for @sdNoPlan.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum plano vinculado.'**
  String get sdNoPlan;

  /// No description provided for @sdMonthlyValue.
  ///
  /// In pt, this message translates to:
  /// **'Valor mensal'**
  String get sdMonthlyValue;

  /// No description provided for @sdDueDate.
  ///
  /// In pt, this message translates to:
  /// **'Vencimento'**
  String get sdDueDate;

  /// No description provided for @sdEveryDayN.
  ///
  /// In pt, this message translates to:
  /// **'Todo dia {day}'**
  String sdEveryDayN(Object day);

  /// No description provided for @sdAppAccessSection.
  ///
  /// In pt, this message translates to:
  /// **'Acesso ao App'**
  String get sdAppAccessSection;

  /// No description provided for @sdAccessBlocked.
  ///
  /// In pt, this message translates to:
  /// **'Acesso bloqueado'**
  String get sdAccessBlocked;

  /// No description provided for @sdAccessAllowed.
  ///
  /// In pt, this message translates to:
  /// **'Acesso liberado'**
  String get sdAccessAllowed;

  /// No description provided for @sdAccessBlockedHint.
  ///
  /// In pt, this message translates to:
  /// **'Aluno não consegue entrar no app.'**
  String get sdAccessBlockedHint;

  /// No description provided for @sdAccessAllowedHint.
  ///
  /// In pt, this message translates to:
  /// **'Aluno pode usar o app normalmente.'**
  String get sdAccessAllowedHint;

  /// No description provided for @sdResetPassword.
  ///
  /// In pt, this message translates to:
  /// **'Redefinir senha'**
  String get sdResetPassword;

  /// No description provided for @sdGenerateAccess.
  ///
  /// In pt, this message translates to:
  /// **'Gerar acesso ao app'**
  String get sdGenerateAccess;

  /// No description provided for @sdGenerateAccessHint.
  ///
  /// In pt, this message translates to:
  /// **'Gere a senha temporária para o aluno entrar direto pelo telefone ou e-mail cadastrado, sem \"primeiro acesso\".'**
  String get sdGenerateAccessHint;

  /// No description provided for @sdThisStudent.
  ///
  /// In pt, this message translates to:
  /// **'este aluno'**
  String get sdThisStudent;

  /// No description provided for @sdMedicalCertSection.
  ///
  /// In pt, this message translates to:
  /// **'Atestado Médico'**
  String get sdMedicalCertSection;

  /// No description provided for @sdCertNone.
  ///
  /// In pt, this message translates to:
  /// **'Sem atestado'**
  String get sdCertNone;

  /// No description provided for @sdCertPending.
  ///
  /// In pt, this message translates to:
  /// **'Aguardando aprovação'**
  String get sdCertPending;

  /// No description provided for @sdCertApproved.
  ///
  /// In pt, this message translates to:
  /// **'Aprovado'**
  String get sdCertApproved;

  /// No description provided for @sdCertRejected.
  ///
  /// In pt, this message translates to:
  /// **'Rejeitado'**
  String get sdCertRejected;

  /// No description provided for @sdCertExpired.
  ///
  /// In pt, this message translates to:
  /// **'Expirado'**
  String get sdCertExpired;

  /// No description provided for @sdCertUnknown.
  ///
  /// In pt, this message translates to:
  /// **'Desconhecido'**
  String get sdCertUnknown;

  /// No description provided for @sdValidity.
  ///
  /// In pt, this message translates to:
  /// **'Validade'**
  String get sdValidity;

  /// No description provided for @sdReason.
  ///
  /// In pt, this message translates to:
  /// **'Motivo'**
  String get sdReason;

  /// No description provided for @sdViewCert.
  ///
  /// In pt, this message translates to:
  /// **'Ver Atestado'**
  String get sdViewCert;

  /// No description provided for @sdApprove.
  ///
  /// In pt, this message translates to:
  /// **'Aprovar'**
  String get sdApprove;

  /// No description provided for @sdReject.
  ///
  /// In pt, this message translates to:
  /// **'Rejeitar'**
  String get sdReject;

  /// No description provided for @sdAttach.
  ///
  /// In pt, this message translates to:
  /// **'Anexar'**
  String get sdAttach;

  /// No description provided for @sdRemind.
  ///
  /// In pt, this message translates to:
  /// **'Lembrar'**
  String get sdRemind;

  /// No description provided for @sdRejectReasonTitle.
  ///
  /// In pt, this message translates to:
  /// **'Motivo da rejeição'**
  String get sdRejectReasonTitle;

  /// No description provided for @sdRejectReasonHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: atestado inválido, fora da validade...'**
  String get sdRejectReasonHint;

  /// No description provided for @sdFileUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Arquivo não disponível.'**
  String get sdFileUnavailable;

  /// No description provided for @sdFileOpenFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir o arquivo.'**
  String get sdFileOpenFailed;

  /// No description provided for @sdFileOpenError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao abrir o arquivo.'**
  String get sdFileOpenError;

  /// No description provided for @sdCertApprovedToast.
  ///
  /// In pt, this message translates to:
  /// **'Atestado aprovado!'**
  String get sdCertApprovedToast;

  /// No description provided for @sdCertRejectedToast.
  ///
  /// In pt, this message translates to:
  /// **'Atestado rejeitado.'**
  String get sdCertRejectedToast;

  /// No description provided for @sdCertReminderTitle.
  ///
  /// In pt, this message translates to:
  /// **'Atestado médico pendente'**
  String get sdCertReminderTitle;

  /// No description provided for @sdCertReminderBody.
  ///
  /// In pt, this message translates to:
  /// **'Apresente seu atestado médico à academia para regularizar sua situação.'**
  String get sdCertReminderBody;

  /// No description provided for @sdReminderSent.
  ///
  /// In pt, this message translates to:
  /// **'Lembrete enviado ao aluno!'**
  String get sdReminderSent;

  /// No description provided for @sdReminderError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao enviar lembrete.'**
  String get sdReminderError;

  /// No description provided for @sdFileTooLarge.
  ///
  /// In pt, this message translates to:
  /// **'Arquivo muito grande. Máx 5 MB.'**
  String get sdFileTooLarge;

  /// No description provided for @sdCertAttached.
  ///
  /// In pt, this message translates to:
  /// **'Atestado anexado e aprovado!'**
  String get sdCertAttached;

  /// No description provided for @sdCertAttachError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao anexar atestado.'**
  String get sdCertAttachError;

  /// No description provided for @sdFamilySection.
  ///
  /// In pt, this message translates to:
  /// **'Grupo Familiar'**
  String get sdFamilySection;

  /// No description provided for @sdAdd.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar'**
  String get sdAdd;

  /// No description provided for @sdLeave.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get sdLeave;

  /// No description provided for @sdNoFamily.
  ///
  /// In pt, this message translates to:
  /// **'Não vinculado a nenhum grupo familiar.'**
  String get sdNoFamily;

  /// No description provided for @sdCreateGroup.
  ///
  /// In pt, this message translates to:
  /// **'Criar grupo'**
  String get sdCreateGroup;

  /// No description provided for @sdLinkExisting.
  ///
  /// In pt, this message translates to:
  /// **'Vincular existente'**
  String get sdLinkExisting;

  /// No description provided for @sdGuardian.
  ///
  /// In pt, this message translates to:
  /// **'Responsável'**
  String get sdGuardian;

  /// No description provided for @sdNoOtherMembers.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum outro membro no grupo.'**
  String get sdNoOtherMembers;

  /// No description provided for @sdCreateFamilyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Criar Grupo Familiar'**
  String get sdCreateFamilyTitle;

  /// No description provided for @sdCreateFamilyHint.
  ///
  /// In pt, this message translates to:
  /// **'O aluno será adicionado automaticamente ao grupo.'**
  String get sdCreateFamilyHint;

  /// No description provided for @sdFamilyNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Família Silva'**
  String get sdFamilyNameHint;

  /// No description provided for @sdCreate.
  ///
  /// In pt, this message translates to:
  /// **'Criar'**
  String get sdCreate;

  /// No description provided for @sdCreateGroupError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao criar grupo.'**
  String get sdCreateGroupError;

  /// No description provided for @sdNoGroupsYet.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum grupo cadastrado ainda.'**
  String get sdNoGroupsYet;

  /// No description provided for @sdSelectGroup.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar Grupo'**
  String get sdSelectGroup;

  /// No description provided for @sdMemberCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, one{1 membro} other{{count} membros}}'**
  String sdMemberCount(int count);

  /// No description provided for @sdLinkGroupError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao vincular grupo.'**
  String get sdLinkGroupError;

  /// No description provided for @sdAddMember.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Membro'**
  String get sdAddMember;

  /// No description provided for @sdAddMemberError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao adicionar membro.'**
  String get sdAddMemberError;

  /// No description provided for @sdRemoveMember.
  ///
  /// In pt, this message translates to:
  /// **'Remover membro'**
  String get sdRemoveMember;

  /// No description provided for @sdRemoveMemberBody.
  ///
  /// In pt, this message translates to:
  /// **'Remover {name} do grupo?'**
  String sdRemoveMemberBody(String name);

  /// No description provided for @sdRemoveMemberError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao remover membro.'**
  String get sdRemoveMemberError;

  /// No description provided for @sdLeaveGroup.
  ///
  /// In pt, this message translates to:
  /// **'Sair do grupo'**
  String get sdLeaveGroup;

  /// No description provided for @sdLeaveGroupBody.
  ///
  /// In pt, this message translates to:
  /// **'Remover este aluno do grupo \"{name}\"?'**
  String sdLeaveGroupBody(String name);

  /// No description provided for @sdLeaveGroupError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao sair do grupo.'**
  String get sdLeaveGroupError;

  /// No description provided for @sdSetGuardian.
  ///
  /// In pt, this message translates to:
  /// **'Definir responsável'**
  String get sdSetGuardian;

  /// No description provided for @sdSetGuardianBody.
  ///
  /// In pt, this message translates to:
  /// **'Definir {name} como responsável financeiro do grupo?'**
  String sdSetGuardianBody(String name);

  /// No description provided for @sdSetGuardianError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao definir responsável.'**
  String get sdSetGuardianError;

  /// No description provided for @sdView.
  ///
  /// In pt, this message translates to:
  /// **'Visualizar'**
  String get sdView;

  /// No description provided for @sdFill.
  ///
  /// In pt, this message translates to:
  /// **'Preencher'**
  String get sdFill;

  /// No description provided for @sdParqEmpty.
  ///
  /// In pt, this message translates to:
  /// **'PAR-Q não preenchido.'**
  String get sdParqEmpty;

  /// No description provided for @sdParqMedicalRecommended.
  ///
  /// In pt, this message translates to:
  /// **'Avaliação médica recomendada'**
  String get sdParqMedicalRecommended;

  /// No description provided for @sdParqNoRisk.
  ///
  /// In pt, this message translates to:
  /// **'Sem indicações de risco'**
  String get sdParqNoRisk;

  /// No description provided for @sdParqFilledOn.
  ///
  /// In pt, this message translates to:
  /// **'Preenchido em {date}'**
  String sdParqFilledOn(String date);

  /// No description provided for @sdParqFillTitle.
  ///
  /// In pt, this message translates to:
  /// **'Preencher PAR-Q'**
  String get sdParqFillTitle;

  /// No description provided for @sdParqEditTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar PAR-Q'**
  String get sdParqEditTitle;

  /// No description provided for @sdParqInstruction.
  ///
  /// In pt, this message translates to:
  /// **'Responda \"Sim\" ou \"Não\" a cada pergunta. Preenchimento feito pela academia em nome do aluno.'**
  String get sdParqInstruction;

  /// No description provided for @sdParqQuestionnaire.
  ///
  /// In pt, this message translates to:
  /// **'QUESTIONÁRIO'**
  String get sdParqQuestionnaire;

  /// No description provided for @sdParqTerm.
  ///
  /// In pt, this message translates to:
  /// **'TERMO DE RESPONSABILIDADE'**
  String get sdParqTerm;

  /// No description provided for @sdParqTermBody.
  ///
  /// In pt, this message translates to:
  /// **'Declaro que estou ciente de que é recomendável conversar com um médico, antes de iniciar ou aumentar o nível de atividade física pretendido, assumindo plena responsabilidade pela realização de qualquer atividade física sem o atendimento desta recomendação.'**
  String get sdParqTermBody;

  /// No description provided for @sdFullNameRequired.
  ///
  /// In pt, this message translates to:
  /// **'Nome completo *'**
  String get sdFullNameRequired;

  /// No description provided for @sdParqFillNameCpf.
  ///
  /// In pt, this message translates to:
  /// **'Preencha nome e CPF.'**
  String get sdParqFillNameCpf;

  /// No description provided for @sdParqSaved.
  ///
  /// In pt, this message translates to:
  /// **'PAR-Q salvo com sucesso!'**
  String get sdParqSaved;

  /// No description provided for @sdParqSaveError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar PAR-Q.'**
  String get sdParqSaveError;

  /// No description provided for @sdParqSaveBtn.
  ///
  /// In pt, this message translates to:
  /// **'Salvar PAR-Q'**
  String get sdParqSaveBtn;

  /// No description provided for @sdParqUpdateBtn.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar PAR-Q'**
  String get sdParqUpdateBtn;

  /// No description provided for @sdParqQ1.
  ///
  /// In pt, this message translates to:
  /// **'Algum médico já disse que você possui algum problema de coração ou pressão arterial, e que somente deveria realizar atividade física supervisionado por profissionais de saúde?'**
  String get sdParqQ1;

  /// No description provided for @sdParqQ2.
  ///
  /// In pt, this message translates to:
  /// **'Você sente dores no peito quando pratica atividade física?'**
  String get sdParqQ2;

  /// No description provided for @sdParqQ3.
  ///
  /// In pt, this message translates to:
  /// **'No último mês, você sentiu dores no peito ao praticar atividade física?'**
  String get sdParqQ3;

  /// No description provided for @sdParqQ4.
  ///
  /// In pt, this message translates to:
  /// **'Você apresenta algum desequilíbrio devido à tontura e/ou perda momentânea da consciência?'**
  String get sdParqQ4;

  /// No description provided for @sdParqQ5.
  ///
  /// In pt, this message translates to:
  /// **'Você possui algum problema ósseo ou articular, que pode ser afetado ou agravado pela atividade física?'**
  String get sdParqQ5;

  /// No description provided for @sdParqQ6.
  ///
  /// In pt, this message translates to:
  /// **'Você toma atualmente algum tipo de medicação de uso contínuo?'**
  String get sdParqQ6;

  /// No description provided for @sdParqQ7.
  ///
  /// In pt, this message translates to:
  /// **'Você realiza algum tipo de tratamento médico para pressão arterial ou problemas cardíacos?'**
  String get sdParqQ7;

  /// No description provided for @sdParqQ8.
  ///
  /// In pt, this message translates to:
  /// **'Você realiza algum tratamento médico contínuo, que possa ser afetado ou prejudicado com a atividade física?'**
  String get sdParqQ8;

  /// No description provided for @sdParqQ9.
  ///
  /// In pt, this message translates to:
  /// **'Você já se submeteu a algum tipo de cirurgia, que comprometa de alguma forma a atividade física?'**
  String get sdParqQ9;

  /// No description provided for @sdParqQ10.
  ///
  /// In pt, this message translates to:
  /// **'Sabe de alguma outra razão pela qual a atividade física possa eventualmente comprometer sua saúde?'**
  String get sdParqQ10;

  /// No description provided for @sdGradWhat.
  ///
  /// In pt, this message translates to:
  /// **'O que deseja fazer?'**
  String get sdGradWhat;

  /// No description provided for @sdGiveStripe.
  ///
  /// In pt, this message translates to:
  /// **'Dar Grau'**
  String get sdGiveStripe;

  /// No description provided for @sdGiveStripeHint.
  ///
  /// In pt, this message translates to:
  /// **'Incrementar grau na mesma faixa atual'**
  String get sdGiveStripeHint;

  /// No description provided for @sdNewBelt.
  ///
  /// In pt, this message translates to:
  /// **'Nova Faixa'**
  String get sdNewBelt;

  /// No description provided for @sdNewBeltHint.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar uma faixa diferente'**
  String get sdNewBeltHint;

  /// No description provided for @sdSelectModality.
  ///
  /// In pt, this message translates to:
  /// **'Selecione a modalidade'**
  String get sdSelectModality;

  /// No description provided for @sdSelectBelt.
  ///
  /// In pt, this message translates to:
  /// **'Selecione a faixa — {mod}'**
  String sdSelectBelt(Object mod);

  /// No description provided for @sdNoBeltsAvailable.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma faixa disponível.'**
  String get sdNoBeltsAvailable;

  /// No description provided for @sdNext.
  ///
  /// In pt, this message translates to:
  /// **'Próximo'**
  String get sdNext;

  /// No description provided for @sdStripe.
  ///
  /// In pt, this message translates to:
  /// **'Grau'**
  String get sdStripe;

  /// No description provided for @sdNoStripe.
  ///
  /// In pt, this message translates to:
  /// **'Sem grau'**
  String get sdNoStripe;

  /// No description provided for @sdObsOptional.
  ///
  /// In pt, this message translates to:
  /// **'Observação (opcional)'**
  String get sdObsOptional;

  /// No description provided for @sdGenerateCharge.
  ///
  /// In pt, this message translates to:
  /// **'Gerar cobrança financeira'**
  String get sdGenerateCharge;

  /// No description provided for @sdChargeAmount.
  ///
  /// In pt, this message translates to:
  /// **'Valor da cobrança (R\$)'**
  String get sdChargeAmount;

  /// No description provided for @sdPromoteStudent.
  ///
  /// In pt, this message translates to:
  /// **'Graduar Aluno'**
  String get sdPromoteStudent;

  /// No description provided for @sdConfirmPromotion.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar Graduação'**
  String get sdConfirmPromotion;

  /// No description provided for @sdPromotedToast.
  ///
  /// In pt, this message translates to:
  /// **'{name} graduado para {belt}!'**
  String sdPromotedToast(Object name, Object belt);

  /// No description provided for @sdPromoteError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao graduar.'**
  String get sdPromoteError;

  /// No description provided for @sdLinkToClass.
  ///
  /// In pt, this message translates to:
  /// **'Vincular a uma Turma'**
  String get sdLinkToClass;

  /// No description provided for @sdAlreadyLinked.
  ///
  /// In pt, this message translates to:
  /// **'Já vinculado'**
  String get sdAlreadyLinked;

  /// No description provided for @sdLinkedToast.
  ///
  /// In pt, this message translates to:
  /// **'Vinculado à {turma}!'**
  String sdLinkedToast(Object turma);

  /// No description provided for @sdLinkError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao vincular.'**
  String get sdLinkError;

  /// No description provided for @sdLink.
  ///
  /// In pt, this message translates to:
  /// **'Vincular'**
  String get sdLink;

  /// No description provided for @sdEditStudent.
  ///
  /// In pt, this message translates to:
  /// **'Editar Aluno'**
  String get sdEditStudent;

  /// No description provided for @sdPersonalData.
  ///
  /// In pt, this message translates to:
  /// **'Dados pessoais'**
  String get sdPersonalData;

  /// No description provided for @sdEditAccessWarning.
  ///
  /// In pt, this message translates to:
  /// **'Este aluno já tem acesso ativo ao app. Alterar e-mail/telefone aqui NÃO muda a senha nem o login dele. Use \"Redefinir senha\" se for necessário.'**
  String get sdEditAccessWarning;

  /// No description provided for @sdCpfOptional.
  ///
  /// In pt, this message translates to:
  /// **'CPF (opcional)'**
  String get sdCpfOptional;

  /// No description provided for @sdBirthDateField.
  ///
  /// In pt, this message translates to:
  /// **'Data de nascimento (DD/MM/AAAA)'**
  String get sdBirthDateField;

  /// No description provided for @sdGuardianEmergency.
  ///
  /// In pt, this message translates to:
  /// **'Responsável / Emergência'**
  String get sdGuardianEmergency;

  /// No description provided for @sdContactName.
  ///
  /// In pt, this message translates to:
  /// **'Nome do contato'**
  String get sdContactName;

  /// No description provided for @sdContactPhone.
  ///
  /// In pt, this message translates to:
  /// **'Telefone do contato'**
  String get sdContactPhone;

  /// No description provided for @sdBillingPlan.
  ///
  /// In pt, this message translates to:
  /// **'Plano financeiro'**
  String get sdBillingPlan;

  /// No description provided for @sdSelectPlan.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar Plano'**
  String get sdSelectPlan;

  /// No description provided for @sdNoPlanOption.
  ///
  /// In pt, this message translates to:
  /// **'Sem plano'**
  String get sdNoPlanOption;

  /// No description provided for @sdPerMonth.
  ///
  /// In pt, this message translates to:
  /// **'R\$ {value} / mês'**
  String sdPerMonth(String value);

  /// No description provided for @sdSelectPlanPlaceholder.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar plano'**
  String get sdSelectPlanPlaceholder;

  /// No description provided for @sdDueDayField.
  ///
  /// In pt, this message translates to:
  /// **'Dia de vencimento (1-31)'**
  String get sdDueDayField;

  /// No description provided for @sdNameRequired.
  ///
  /// In pt, this message translates to:
  /// **'Nome é obrigatório.'**
  String get sdNameRequired;

  /// No description provided for @sdPhoneInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Telefone inválido.'**
  String get sdPhoneInvalid;

  /// No description provided for @sdStudentUpdated.
  ///
  /// In pt, this message translates to:
  /// **'Aluno atualizado com sucesso!'**
  String get sdStudentUpdated;

  /// No description provided for @sdStudentUpdateError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao atualizar aluno.'**
  String get sdStudentUpdateError;

  /// No description provided for @sdSaveChanges.
  ///
  /// In pt, this message translates to:
  /// **'Salvar alterações'**
  String get sdSaveChanges;

  /// No description provided for @sdPoints.
  ///
  /// In pt, this message translates to:
  /// **'Pontos'**
  String get sdPoints;

  /// No description provided for @sdRankingsHint.
  ///
  /// In pt, this message translates to:
  /// **'Toque em \"Pontos\" para lançar pontos em um ranking personalizado.'**
  String get sdRankingsHint;

  /// No description provided for @sdAddPoints.
  ///
  /// In pt, this message translates to:
  /// **'Lançar Pontos'**
  String get sdAddPoints;

  /// No description provided for @sdNoManualRankings.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum ranking com pontos manuais ativo.'**
  String get sdNoManualRankings;

  /// No description provided for @sdPointsAmount.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade de pontos'**
  String get sdPointsAmount;

  /// No description provided for @sdPointsAddedToast.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, one{1 ponto lançado com sucesso!} other{{count} pontos lançados com sucesso!}}'**
  String sdPointsAddedToast(int count);

  /// No description provided for @sdPointsError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao lançar pontos.'**
  String get sdPointsError;

  /// No description provided for @sdEmergencyContact.
  ///
  /// In pt, this message translates to:
  /// **'Contato de Emergência'**
  String get sdEmergencyContact;

  /// No description provided for @sdNoClasses.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma turma vinculada.'**
  String get sdNoClasses;

  /// No description provided for @sdBeltHistory.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de Graduações'**
  String get sdBeltHistory;

  /// No description provided for @sdNoBeltHistory.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma graduação registrada.'**
  String get sdNoBeltHistory;

  /// No description provided for @sdRemovePromotionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Remover graduação?'**
  String get sdRemovePromotionTitle;

  /// No description provided for @sdRemovePromotionBody.
  ///
  /// In pt, this message translates to:
  /// **'Esta ação remove \"{label}\" do histórico de graduações e não pode ser desfeita.'**
  String sdRemovePromotionBody(String label);

  /// No description provided for @sdPromotionRemoved.
  ///
  /// In pt, this message translates to:
  /// **'Graduação removida.'**
  String get sdPromotionRemoved;

  /// No description provided for @sdPromotionRemoveError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao remover graduação.'**
  String get sdPromotionRemoveError;

  /// No description provided for @sdEditPromotion.
  ///
  /// In pt, this message translates to:
  /// **'Editar graduação'**
  String get sdEditPromotion;

  /// No description provided for @sdBelt.
  ///
  /// In pt, this message translates to:
  /// **'Faixa'**
  String get sdBelt;

  /// No description provided for @sdExamDate.
  ///
  /// In pt, this message translates to:
  /// **'Data do exame'**
  String get sdExamDate;

  /// No description provided for @sdDateMask.
  ///
  /// In pt, this message translates to:
  /// **'DD/MM/AAAA'**
  String get sdDateMask;

  /// No description provided for @sdNotesOptional.
  ///
  /// In pt, this message translates to:
  /// **'Observações (opcional)'**
  String get sdNotesOptional;

  /// No description provided for @sdNotes.
  ///
  /// In pt, this message translates to:
  /// **'Observações'**
  String get sdNotes;

  /// No description provided for @sdDateFormatError.
  ///
  /// In pt, this message translates to:
  /// **'Informe a data no formato DD/MM/AAAA.'**
  String get sdDateFormatError;

  /// No description provided for @sdPromotionUpdated.
  ///
  /// In pt, this message translates to:
  /// **'Graduação atualizada.'**
  String get sdPromotionUpdated;

  /// No description provided for @sdCheckHistory.
  ///
  /// In pt, this message translates to:
  /// **'Verifique o histórico'**
  String get sdCheckHistory;

  /// No description provided for @sdPromotionEditError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao editar graduação.'**
  String get sdPromotionEditError;

  /// No description provided for @sdSaveCorrection.
  ///
  /// In pt, this message translates to:
  /// **'Salvar correção'**
  String get sdSaveCorrection;

  /// No description provided for @sdPhotoError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar foto.'**
  String get sdPhotoError;

  /// No description provided for @sdActivateConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Deseja ativar {name}?'**
  String sdActivateConfirm(Object name);

  /// No description provided for @sdDeactivateConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Deseja desativar {name}?'**
  String sdDeactivateConfirm(Object name);

  /// No description provided for @sdStatusChangeError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao alterar status.'**
  String get sdStatusChangeError;

  /// No description provided for @sdAllowAccessConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Liberar o acesso ao app de {name}?'**
  String sdAllowAccessConfirm(Object name);

  /// No description provided for @sdBlockAccessConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Bloquear o acesso ao app de {name}?'**
  String sdBlockAccessConfirm(Object name);

  /// No description provided for @sdAccessChangeError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao alterar acesso.'**
  String get sdAccessChangeError;

  /// No description provided for @sdBeltsLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar as faixas dessa modalidade.'**
  String get sdBeltsLoadError;

  /// No description provided for @commonMenu.
  ///
  /// In pt, this message translates to:
  /// **'Menu'**
  String get commonMenu;

  /// No description provided for @classesSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Gerencie suas turmas e acompanhe a evolução dos alunos.'**
  String get classesSubtitle;

  /// No description provided for @classesSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar turma...'**
  String get classesSearchHint;

  /// No description provided for @attendanceReport.
  ///
  /// In pt, this message translates to:
  /// **'Relatório de presenças'**
  String get attendanceReport;

  /// No description provided for @classesEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma turma encontrada.'**
  String get classesEmpty;

  /// No description provided for @classesMoreTitle.
  ///
  /// In pt, this message translates to:
  /// **'Mais turmas, mais histórias'**
  String get classesMoreTitle;

  /// No description provided for @classesMoreSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Cadastre novas turmas e mantenha toda a sua academia organizada.'**
  String get classesMoreSubtitle;

  /// No description provided for @classesEmptyState.
  ///
  /// In pt, this message translates to:
  /// **'Você ainda não possui turmas cadastradas.'**
  String get classesEmptyState;

  /// No description provided for @classesCreateFirst.
  ///
  /// In pt, this message translates to:
  /// **'Criar primeira turma'**
  String get classesCreateFirst;

  /// No description provided for @classesLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar as informações.'**
  String get classesLoadError;

  /// No description provided for @classStatusActive.
  ///
  /// In pt, this message translates to:
  /// **'Ativa'**
  String get classStatusActive;

  /// No description provided for @classStatusInactive.
  ///
  /// In pt, this message translates to:
  /// **'Inativa'**
  String get classStatusInactive;

  /// No description provided for @classInstructorPrefix.
  ///
  /// In pt, this message translates to:
  /// **'Prof. {name}'**
  String classInstructorPrefix(String name);

  /// No description provided for @classCapacitySuffix.
  ///
  /// In pt, this message translates to:
  /// **' / {cap} alunos'**
  String classCapacitySuffix(String cap);

  /// No description provided for @takeAttendance.
  ///
  /// In pt, this message translates to:
  /// **'Fazer chamada'**
  String get takeAttendance;

  /// No description provided for @viewDetails.
  ///
  /// In pt, this message translates to:
  /// **'Ver detalhes'**
  String get viewDetails;

  /// No description provided for @editClass.
  ///
  /// In pt, this message translates to:
  /// **'Editar turma'**
  String get editClass;

  /// No description provided for @noSchedule.
  ///
  /// In pt, this message translates to:
  /// **'Sem horários definidos'**
  String get noSchedule;

  /// No description provided for @scheduleCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, one{1 horário} other{{count} horários}}'**
  String scheduleCount(int count);

  /// No description provided for @editClassTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar Turma'**
  String get editClassTitle;

  /// No description provided for @newClassTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nova Turma'**
  String get newClassTitle;

  /// No description provided for @classNameField.
  ///
  /// In pt, this message translates to:
  /// **'Nome da Turma'**
  String get classNameField;

  /// No description provided for @modality.
  ///
  /// In pt, this message translates to:
  /// **'Modalidade'**
  String get modality;

  /// No description provided for @level.
  ///
  /// In pt, this message translates to:
  /// **'Nível'**
  String get level;

  /// No description provided for @instructorOptional.
  ///
  /// In pt, this message translates to:
  /// **'Professor (opcional)'**
  String get instructorOptional;

  /// No description provided for @noInstructor.
  ///
  /// In pt, this message translates to:
  /// **'Sem professor'**
  String get noInstructor;

  /// No description provided for @maxCapacity.
  ///
  /// In pt, this message translates to:
  /// **'Capacidade máxima'**
  String get maxCapacity;

  /// No description provided for @invalidNumber.
  ///
  /// In pt, this message translates to:
  /// **'Número inválido'**
  String get invalidNumber;

  /// No description provided for @classActiveToggle.
  ///
  /// In pt, this message translates to:
  /// **'Turma ativa'**
  String get classActiveToggle;

  /// No description provided for @classEditError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao editar turma'**
  String get classEditError;

  /// No description provided for @classCreateError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao criar turma'**
  String get classCreateError;

  /// No description provided for @levelBeginner.
  ///
  /// In pt, this message translates to:
  /// **'Iniciante'**
  String get levelBeginner;

  /// No description provided for @levelIntermediate.
  ///
  /// In pt, this message translates to:
  /// **'Intermediário'**
  String get levelIntermediate;

  /// No description provided for @levelAdvanced.
  ///
  /// In pt, this message translates to:
  /// **'Avançado'**
  String get levelAdvanced;

  /// No description provided for @levelAll.
  ///
  /// In pt, this message translates to:
  /// **'Todos os níveis'**
  String get levelAll;

  /// No description provided for @dowSun.
  ///
  /// In pt, this message translates to:
  /// **'Dom'**
  String get dowSun;

  /// No description provided for @dowMon.
  ///
  /// In pt, this message translates to:
  /// **'Seg'**
  String get dowMon;

  /// No description provided for @dowTue.
  ///
  /// In pt, this message translates to:
  /// **'Ter'**
  String get dowTue;

  /// No description provided for @dowWed.
  ///
  /// In pt, this message translates to:
  /// **'Qua'**
  String get dowWed;

  /// No description provided for @dowThu.
  ///
  /// In pt, this message translates to:
  /// **'Qui'**
  String get dowThu;

  /// No description provided for @dowFri.
  ///
  /// In pt, this message translates to:
  /// **'Sex'**
  String get dowFri;

  /// No description provided for @dowSat.
  ///
  /// In pt, this message translates to:
  /// **'Sáb'**
  String get dowSat;

  /// No description provided for @attendanceReportTitle.
  ///
  /// In pt, this message translates to:
  /// **'Relatório de Presenças'**
  String get attendanceReportTitle;

  /// No description provided for @noClassesRegistered.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma turma cadastrada.'**
  String get noClassesRegistered;

  /// No description provided for @periodLabel.
  ///
  /// In pt, this message translates to:
  /// **'Período'**
  String get periodLabel;

  /// No description provided for @periodDaysCount.
  ///
  /// In pt, this message translates to:
  /// **'{count} dias'**
  String periodDaysCount(int count);

  /// No description provided for @periodCustom.
  ///
  /// In pt, this message translates to:
  /// **'Personalizado'**
  String get periodCustom;

  /// No description provided for @totalSessions.
  ///
  /// In pt, this message translates to:
  /// **'Total de Aulas'**
  String get totalSessions;

  /// No description provided for @avgAttendance.
  ///
  /// In pt, this message translates to:
  /// **'Frequência média'**
  String get avgAttendance;

  /// No description provided for @studentAttendanceCount.
  ///
  /// In pt, this message translates to:
  /// **'Frequência dos alunos ({count})'**
  String studentAttendanceCount(int count);

  /// No description provided for @noSessionsInPeriod.
  ///
  /// In pt, this message translates to:
  /// **'Não há aulas registradas neste período.\nSelecione outro intervalo para ver a frequência.'**
  String get noSessionsInPeriod;

  /// No description provided for @noStudentsInClass.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum aluno matriculado nesta turma.'**
  String get noStudentsInClass;

  /// No description provided for @sortBy.
  ///
  /// In pt, this message translates to:
  /// **'Ordenar por'**
  String get sortBy;

  /// No description provided for @sortAttendanceDesc.
  ///
  /// In pt, this message translates to:
  /// **'Maior frequência'**
  String get sortAttendanceDesc;

  /// No description provided for @sortAttendanceAsc.
  ///
  /// In pt, this message translates to:
  /// **'Menor frequência'**
  String get sortAttendanceAsc;

  /// No description provided for @sortNameAsc.
  ///
  /// In pt, this message translates to:
  /// **'Nome (A–Z)'**
  String get sortNameAsc;

  /// No description provided for @sortNameDesc.
  ///
  /// In pt, this message translates to:
  /// **'Nome (Z–A)'**
  String get sortNameDesc;

  /// No description provided for @presentCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, one{1 presença} other{{count} presenças}}'**
  String presentCount(int count);

  /// No description provided for @absentCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, one{1 falta} other{{count} faltas}}'**
  String absentCount(int count);

  /// No description provided for @attendanceA11y.
  ///
  /// In pt, this message translates to:
  /// **'{name}, {pct}% de frequência, {present} presenças, {absent} faltas'**
  String attendanceA11y(String name, String pct, int present, int absent);

  /// No description provided for @dowFullSun.
  ///
  /// In pt, this message translates to:
  /// **'Domingo'**
  String get dowFullSun;

  /// No description provided for @dowFullMon.
  ///
  /// In pt, this message translates to:
  /// **'Segunda'**
  String get dowFullMon;

  /// No description provided for @dowFullTue.
  ///
  /// In pt, this message translates to:
  /// **'Terça'**
  String get dowFullTue;

  /// No description provided for @dowFullWed.
  ///
  /// In pt, this message translates to:
  /// **'Quarta'**
  String get dowFullWed;

  /// No description provided for @dowFullThu.
  ///
  /// In pt, this message translates to:
  /// **'Quinta'**
  String get dowFullThu;

  /// No description provided for @dowFullFri.
  ///
  /// In pt, this message translates to:
  /// **'Sexta'**
  String get dowFullFri;

  /// No description provided for @dowFullSat.
  ///
  /// In pt, this message translates to:
  /// **'Sábado'**
  String get dowFullSat;

  /// No description provided for @tdTabAttendance.
  ///
  /// In pt, this message translates to:
  /// **'Presença'**
  String get tdTabAttendance;

  /// No description provided for @tdTabSchedule.
  ///
  /// In pt, this message translates to:
  /// **'Horários'**
  String get tdTabSchedule;

  /// No description provided for @tdDeleteClass.
  ///
  /// In pt, this message translates to:
  /// **'Excluir turma'**
  String get tdDeleteClass;

  /// No description provided for @tdClassNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Turma não encontrada'**
  String get tdClassNotFound;

  /// No description provided for @tdClassLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar turma'**
  String get tdClassLoadError;

  /// No description provided for @tdClassFallback.
  ///
  /// In pt, this message translates to:
  /// **'Turma'**
  String get tdClassFallback;

  /// No description provided for @tdEnrolledStudents.
  ///
  /// In pt, this message translates to:
  /// **'Alunos matriculados'**
  String get tdEnrolledStudents;

  /// No description provided for @tdSortPrefix.
  ///
  /// In pt, this message translates to:
  /// **'Ordenar: '**
  String get tdSortPrefix;

  /// No description provided for @tdAddStudent.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar aluno'**
  String get tdAddStudent;

  /// No description provided for @tdDragToReorder.
  ///
  /// In pt, this message translates to:
  /// **'Segure e arraste para reordenar'**
  String get tdDragToReorder;

  /// No description provided for @tdEligibleToPromote.
  ///
  /// In pt, this message translates to:
  /// **'Apto para graduar'**
  String get tdEligibleToPromote;

  /// No description provided for @tdAttendancesLabel.
  ///
  /// In pt, this message translates to:
  /// **'presenças'**
  String get tdAttendancesLabel;

  /// No description provided for @tdSortStudents.
  ///
  /// In pt, this message translates to:
  /// **'Ordenar alunos'**
  String get tdSortStudents;

  /// No description provided for @tdReorderByDrag.
  ///
  /// In pt, this message translates to:
  /// **'Reordenar arrastando'**
  String get tdReorderByDrag;

  /// No description provided for @tdReorderHint.
  ///
  /// In pt, this message translates to:
  /// **'Segure e arraste os alunos para montar a ordem da turma'**
  String get tdReorderHint;

  /// No description provided for @tdOrderSaved.
  ///
  /// In pt, this message translates to:
  /// **'Ordem da turma salva.'**
  String get tdOrderSaved;

  /// No description provided for @tdOrderSaveError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar a ordem.'**
  String get tdOrderSaveError;

  /// No description provided for @tdOrdManual.
  ///
  /// In pt, this message translates to:
  /// **'Ordem personalizada'**
  String get tdOrdManual;

  /// No description provided for @tdOrdBeltDesc.
  ///
  /// In pt, this message translates to:
  /// **'Graduação (mais alta)'**
  String get tdOrdBeltDesc;

  /// No description provided for @tdOrdBeltAsc.
  ///
  /// In pt, this message translates to:
  /// **'Graduação (mais baixa)'**
  String get tdOrdBeltAsc;

  /// No description provided for @tdOrdEnrollOld.
  ///
  /// In pt, this message translates to:
  /// **'Matrícula (mais antiga)'**
  String get tdOrdEnrollOld;

  /// No description provided for @tdOrdEnrollNew.
  ///
  /// In pt, this message translates to:
  /// **'Matrícula (mais recente)'**
  String get tdOrdEnrollNew;

  /// No description provided for @tdOrdAttendDesc.
  ///
  /// In pt, this message translates to:
  /// **'Mais presenças'**
  String get tdOrdAttendDesc;

  /// No description provided for @tdOrdAttendAsc.
  ///
  /// In pt, this message translates to:
  /// **'Menos presenças'**
  String get tdOrdAttendAsc;

  /// No description provided for @tdPresentToday.
  ///
  /// In pt, this message translates to:
  /// **'Presentes hoje'**
  String get tdPresentToday;

  /// No description provided for @tdDayAttendanceRate.
  ///
  /// In pt, this message translates to:
  /// **'Frequência do dia'**
  String get tdDayAttendanceRate;

  /// No description provided for @tdMarkAll.
  ///
  /// In pt, this message translates to:
  /// **'Marcar todos'**
  String get tdMarkAll;

  /// No description provided for @tdNoStudentsForAttendance.
  ///
  /// In pt, this message translates to:
  /// **'Não há alunos matriculados para realizar a chamada.'**
  String get tdNoStudentsForAttendance;

  /// No description provided for @tdOffScheduleDay.
  ///
  /// In pt, this message translates to:
  /// **'Dia fora do horário'**
  String get tdOffScheduleDay;

  /// No description provided for @tdOffScheduleAllBody.
  ///
  /// In pt, this message translates to:
  /// **'Hoje não é o dia de treino cadastrado para essa turma. Marcar presença de todos para {day}?'**
  String tdOffScheduleAllBody(String day);

  /// No description provided for @tdOffScheduleOneBody.
  ///
  /// In pt, this message translates to:
  /// **'Hoje não é o dia de treino cadastrado para essa turma. Deseja mesmo confirmar presença para {day}?'**
  String tdOffScheduleOneBody(String day);

  /// No description provided for @tdConfirmAnyway.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar assim mesmo'**
  String get tdConfirmAnyway;

  /// No description provided for @tdAttendanceAllMarked.
  ///
  /// In pt, this message translates to:
  /// **'Presença registrada para todos.'**
  String get tdAttendanceAllMarked;

  /// No description provided for @tdAttendanceSomeFailed.
  ///
  /// In pt, this message translates to:
  /// **'Alguns não foram registrados ({count}). Tente novamente.'**
  String tdAttendanceSomeFailed(int count);

  /// No description provided for @tdEnrollIdNotFound.
  ///
  /// In pt, this message translates to:
  /// **'ID de matrícula não encontrado.'**
  String get tdEnrollIdNotFound;

  /// No description provided for @tdRemoveStudent.
  ///
  /// In pt, this message translates to:
  /// **'Remover aluno'**
  String get tdRemoveStudent;

  /// No description provided for @tdRemoveStudentBody.
  ///
  /// In pt, this message translates to:
  /// **'Deseja remover {name} desta turma?'**
  String tdRemoveStudentBody(String name);

  /// No description provided for @tdStudentRemoved.
  ///
  /// In pt, this message translates to:
  /// **'{name} removido da turma.'**
  String tdStudentRemoved(String name);

  /// No description provided for @tdRemoveStudentError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao remover aluno.'**
  String get tdRemoveStudentError;

  /// No description provided for @tdPresent.
  ///
  /// In pt, this message translates to:
  /// **'Presente'**
  String get tdPresent;

  /// No description provided for @tdMark.
  ///
  /// In pt, this message translates to:
  /// **'Marcar'**
  String get tdMark;

  /// No description provided for @tdAttendanceMarked.
  ///
  /// In pt, this message translates to:
  /// **'Presença registrada!'**
  String get tdAttendanceMarked;

  /// No description provided for @tdAttendanceMarkError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao registrar presença.'**
  String get tdAttendanceMarkError;

  /// No description provided for @tdUndoAttendance.
  ///
  /// In pt, this message translates to:
  /// **'Desfazer presença'**
  String get tdUndoAttendance;

  /// No description provided for @tdUndoAttendanceBody.
  ///
  /// In pt, this message translates to:
  /// **'Deseja remover a presença de {name} nesta data?'**
  String tdUndoAttendanceBody(String name);

  /// No description provided for @tdAttendanceRemoved.
  ///
  /// In pt, this message translates to:
  /// **'Presença removida.'**
  String get tdAttendanceRemoved;

  /// No description provided for @tdAttendanceRemoveError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao remover presença.'**
  String get tdAttendanceRemoveError;

  /// No description provided for @tdToday.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get tdToday;

  /// No description provided for @tdYesterday.
  ///
  /// In pt, this message translates to:
  /// **'Ontem'**
  String get tdYesterday;

  /// No description provided for @tdWeeklyScheduleCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, one{1 horário semanal} other{{count} horários semanais}}'**
  String tdWeeklyScheduleCount(int count);

  /// No description provided for @tdClassSchedule.
  ///
  /// In pt, this message translates to:
  /// **'Horários da turma'**
  String get tdClassSchedule;

  /// No description provided for @tdNewSchedule.
  ///
  /// In pt, this message translates to:
  /// **'Novo horário'**
  String get tdNewSchedule;

  /// No description provided for @tdNoSchedules.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum horário cadastrado.'**
  String get tdNoSchedules;

  /// No description provided for @tdAddFirstSchedule.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar primeiro horário'**
  String get tdAddFirstSchedule;

  /// No description provided for @tdRoomN.
  ///
  /// In pt, this message translates to:
  /// **'Sala {room}'**
  String tdRoomN(String room);

  /// No description provided for @tdListAnd.
  ///
  /// In pt, this message translates to:
  /// **' e '**
  String get tdListAnd;

  /// No description provided for @tdDeleteScheduleTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir horário?'**
  String get tdDeleteScheduleTitle;

  /// No description provided for @tdDeleteScheduleBody.
  ///
  /// In pt, this message translates to:
  /// **'Este horário será removido da turma.'**
  String get tdDeleteScheduleBody;

  /// No description provided for @tdScheduleRemoveError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao remover horário.'**
  String get tdScheduleRemoveError;

  /// No description provided for @tdEditScheduleTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar Horário'**
  String get tdEditScheduleTitle;

  /// No description provided for @tdNewScheduleTitle.
  ///
  /// In pt, this message translates to:
  /// **'Novo Horário'**
  String get tdNewScheduleTitle;

  /// No description provided for @tdWeekday.
  ///
  /// In pt, this message translates to:
  /// **'Dia da semana'**
  String get tdWeekday;

  /// No description provided for @tdWeekdays.
  ///
  /// In pt, this message translates to:
  /// **'Dias da semana'**
  String get tdWeekdays;

  /// No description provided for @tdStart.
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get tdStart;

  /// No description provided for @tdRoomOptional.
  ///
  /// In pt, this message translates to:
  /// **'Sala (opcional)'**
  String get tdRoomOptional;

  /// No description provided for @tdSelectDayAndTime.
  ///
  /// In pt, this message translates to:
  /// **'Selecione ao menos um dia e os horários.'**
  String get tdSelectDayAndTime;

  /// No description provided for @tdScheduleEditError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao editar horário.'**
  String get tdScheduleEditError;

  /// No description provided for @tdScheduleCreateError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao criar horário.'**
  String get tdScheduleCreateError;

  /// No description provided for @tdEnrollStudent.
  ///
  /// In pt, this message translates to:
  /// **'Matricular aluno'**
  String get tdEnrollStudent;

  /// No description provided for @tdNoStudentsAvailable.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum aluno disponível.'**
  String get tdNoStudentsAvailable;

  /// No description provided for @tdEnrollError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao matricular aluno.'**
  String get tdEnrollError;

  /// No description provided for @tdThisClass.
  ///
  /// In pt, this message translates to:
  /// **'esta turma'**
  String get tdThisClass;

  /// No description provided for @tdDeleteClassConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Excluir \"{name}\"?'**
  String tdDeleteClassConfirm(String name);

  /// No description provided for @tdDeleteClassBody.
  ///
  /// In pt, this message translates to:
  /// **'A turma some das listagens ativas e as matrículas em aberto são encerradas. Alunos, presenças e graduações continuam no histórico — nada é apagado.'**
  String get tdDeleteClassBody;

  /// No description provided for @tdClassDeletedWithEnroll.
  ///
  /// In pt, this message translates to:
  /// **'Turma excluída. {count} matrícula(s) encerrada(s).'**
  String tdClassDeletedWithEnroll(int count);

  /// No description provided for @tdClassDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Turma excluída.'**
  String get tdClassDeleted;

  /// No description provided for @tdClassDeleteError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao excluir turma.'**
  String get tdClassDeleteError;

  /// No description provided for @tdClassQrTitle.
  ///
  /// In pt, this message translates to:
  /// **'QR Code da Turma'**
  String get tdClassQrTitle;

  /// No description provided for @tdQrSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Alunos escaneiam para registrar presença'**
  String get tdQrSubtitle;

  /// No description provided for @tdQrValidity.
  ///
  /// In pt, this message translates to:
  /// **'Válido apenas no horário da aula'**
  String get tdQrValidity;

  /// No description provided for @caTitle.
  ///
  /// In pt, this message translates to:
  /// **'Contas da Academia'**
  String get caTitle;

  /// No description provided for @caLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar contas.'**
  String get caLoadError;

  /// No description provided for @caMarkPaidError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao marcar como paga.'**
  String get caMarkPaidError;

  /// No description provided for @caDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir conta'**
  String get caDeleteTitle;

  /// No description provided for @caDeleteBody.
  ///
  /// In pt, this message translates to:
  /// **'Deseja excluir \"{desc}\"?'**
  String caDeleteBody(String desc);

  /// No description provided for @caNewBill.
  ///
  /// In pt, this message translates to:
  /// **'Nova conta'**
  String get caNewBill;

  /// No description provided for @caEditBill.
  ///
  /// In pt, this message translates to:
  /// **'Editar conta'**
  String get caEditBill;

  /// No description provided for @caDescHint.
  ///
  /// In pt, this message translates to:
  /// **'Descrição (ex: Conta de luz)'**
  String get caDescHint;

  /// No description provided for @caAmountHint.
  ///
  /// In pt, this message translates to:
  /// **'Valor (R\$)'**
  String get caAmountHint;

  /// No description provided for @caDueOn.
  ///
  /// In pt, this message translates to:
  /// **'Vencimento: {date}'**
  String caDueOn(String date);

  /// No description provided for @caRecurring.
  ///
  /// In pt, this message translates to:
  /// **'Conta recorrente (todo mês)'**
  String get caRecurring;

  /// No description provided for @caSaveBill.
  ///
  /// In pt, this message translates to:
  /// **'Salvar conta'**
  String get caSaveBill;

  /// No description provided for @caToPay.
  ///
  /// In pt, this message translates to:
  /// **'A pagar'**
  String get caToPay;

  /// No description provided for @caOverdue.
  ///
  /// In pt, this message translates to:
  /// **'Atrasado'**
  String get caOverdue;

  /// No description provided for @caFilterAll.
  ///
  /// In pt, this message translates to:
  /// **'Todas'**
  String get caFilterAll;

  /// No description provided for @caFilterPending.
  ///
  /// In pt, this message translates to:
  /// **'Pendentes'**
  String get caFilterPending;

  /// No description provided for @caFilterOverdue.
  ///
  /// In pt, this message translates to:
  /// **'Atrasadas'**
  String get caFilterOverdue;

  /// No description provided for @caFilterPaid.
  ///
  /// In pt, this message translates to:
  /// **'Pagas'**
  String get caFilterPaid;

  /// No description provided for @caEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma conta cadastrada'**
  String get caEmpty;

  /// No description provided for @caStPaid.
  ///
  /// In pt, this message translates to:
  /// **'Paga'**
  String get caStPaid;

  /// No description provided for @caStOverdue.
  ///
  /// In pt, this message translates to:
  /// **'Atrasada'**
  String get caStOverdue;

  /// No description provided for @caStCancelled.
  ///
  /// In pt, this message translates to:
  /// **'Cancelada'**
  String get caStCancelled;

  /// No description provided for @caStPending.
  ///
  /// In pt, this message translates to:
  /// **'Pendente'**
  String get caStPending;

  /// No description provided for @caCategoryDueOn.
  ///
  /// In pt, this message translates to:
  /// **'{cat} · vence em {date}'**
  String caCategoryDueOn(String cat, String date);

  /// No description provided for @caMarkAsPaid.
  ///
  /// In pt, this message translates to:
  /// **'Marcar como paga'**
  String get caMarkAsPaid;

  /// No description provided for @caCatWater.
  ///
  /// In pt, this message translates to:
  /// **'Água'**
  String get caCatWater;

  /// No description provided for @caCatPower.
  ///
  /// In pt, this message translates to:
  /// **'Luz'**
  String get caCatPower;

  /// No description provided for @caCatRent.
  ///
  /// In pt, this message translates to:
  /// **'Aluguel'**
  String get caCatRent;

  /// No description provided for @caCatInternet.
  ///
  /// In pt, this message translates to:
  /// **'Internet'**
  String get caCatInternet;

  /// No description provided for @caCatOther.
  ///
  /// In pt, this message translates to:
  /// **'Outros'**
  String get caCatOther;

  /// No description provided for @raTitle.
  ///
  /// In pt, this message translates to:
  /// **'Relatório Anual'**
  String get raTitle;

  /// No description provided for @raLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar o relatório.'**
  String get raLoadError;

  /// No description provided for @raYearOverview.
  ///
  /// In pt, this message translates to:
  /// **'Visão geral do ano'**
  String get raYearOverview;

  /// No description provided for @raNoMovement.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma movimentação financeira encontrada em {year}.'**
  String raNoMovement(int year);

  /// No description provided for @raMonthlyRevenue.
  ///
  /// In pt, this message translates to:
  /// **'Receita mensal'**
  String get raMonthlyRevenue;

  /// No description provided for @raOverdueCount.
  ///
  /// In pt, this message translates to:
  /// **'Inadimplentes ({count})'**
  String raOverdueCount(int count);

  /// No description provided for @raNoOverdue.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum inadimplente neste período.'**
  String get raNoOverdue;

  /// No description provided for @raPrevYear.
  ///
  /// In pt, this message translates to:
  /// **'Ano anterior'**
  String get raPrevYear;

  /// No description provided for @raNextYear.
  ///
  /// In pt, this message translates to:
  /// **'Próximo ano'**
  String get raNextYear;

  /// No description provided for @raReceivedYear.
  ///
  /// In pt, this message translates to:
  /// **'Recebido no ano'**
  String get raReceivedYear;

  /// No description provided for @raChargesCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, one{1 cobrança} other{{count} cobranças}}'**
  String raChargesCount(int count);

  /// No description provided for @raOverdue.
  ///
  /// In pt, this message translates to:
  /// **'Inadimplentes'**
  String get raOverdue;

  /// No description provided for @raOutstanding.
  ///
  /// In pt, this message translates to:
  /// **'Em aberto'**
  String get raOutstanding;

  /// No description provided for @raReceived.
  ///
  /// In pt, this message translates to:
  /// **'Recebido'**
  String get raReceived;

  /// No description provided for @raNoRevenueYear.
  ///
  /// In pt, this message translates to:
  /// **'Sem receita registrada em {year}.'**
  String raNoRevenueYear(int year);

  /// No description provided for @raDaysOverdue.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, one{1 dia de atraso} other{{count} dias de atraso}}'**
  String raDaysOverdue(int count);

  /// No description provided for @raUnknownStudent.
  ///
  /// In pt, this message translates to:
  /// **'Aluno não identificado'**
  String get raUnknownStudent;

  /// No description provided for @raBarTooltip.
  ///
  /// In pt, this message translates to:
  /// **'{month} {year}\nRecebido: {received}\nPendente: {pending}\nTotal: {total}'**
  String raBarTooltip(
    String month,
    int year,
    String received,
    String pending,
    String total,
  );

  /// No description provided for @fiStPending.
  ///
  /// In pt, this message translates to:
  /// **'Pendente'**
  String get fiStPending;

  /// No description provided for @fiStPaid.
  ///
  /// In pt, this message translates to:
  /// **'Pago'**
  String get fiStPaid;

  /// No description provided for @fiStOverdue.
  ///
  /// In pt, this message translates to:
  /// **'Atrasado'**
  String get fiStOverdue;

  /// No description provided for @fiStForecast.
  ///
  /// In pt, this message translates to:
  /// **'Previsto'**
  String get fiStForecast;

  /// No description provided for @fiStDismissed.
  ///
  /// In pt, this message translates to:
  /// **'Desconsiderado'**
  String get fiStDismissed;

  /// No description provided for @fiTypeMonthly.
  ///
  /// In pt, this message translates to:
  /// **'Mensalidade'**
  String get fiTypeMonthly;

  /// No description provided for @fiTypeEnrollment.
  ///
  /// In pt, this message translates to:
  /// **'Taxa de Matrícula'**
  String get fiTypeEnrollment;

  /// No description provided for @fiReportTab.
  ///
  /// In pt, this message translates to:
  /// **'Relatório'**
  String get fiReportTab;

  /// No description provided for @fiGenerateCharges.
  ///
  /// In pt, this message translates to:
  /// **'Gerar cobranças'**
  String get fiGenerateCharges;

  /// No description provided for @fiGenerateCharge.
  ///
  /// In pt, this message translates to:
  /// **'Gerar cobrança'**
  String get fiGenerateCharge;

  /// No description provided for @fiNewCharge.
  ///
  /// In pt, this message translates to:
  /// **'Nova cobrança'**
  String get fiNewCharge;

  /// No description provided for @fiCurrentMonth.
  ///
  /// In pt, this message translates to:
  /// **'Mês atual'**
  String get fiCurrentMonth;

  /// No description provided for @fiBackToCurrentMonth.
  ///
  /// In pt, this message translates to:
  /// **'Voltar ao mês atual'**
  String get fiBackToCurrentMonth;

  /// No description provided for @fiNoCharges.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma cobrança.'**
  String get fiNoCharges;

  /// No description provided for @fiChargesCount.
  ///
  /// In pt, this message translates to:
  /// **'Cobranças · {count}'**
  String fiChargesCount(int count);

  /// No description provided for @fiTabAll.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get fiTabAll;

  /// No description provided for @fiTabPending.
  ///
  /// In pt, this message translates to:
  /// **'Pendentes'**
  String get fiTabPending;

  /// No description provided for @fiTabOverdue.
  ///
  /// In pt, this message translates to:
  /// **'Atrasados'**
  String get fiTabOverdue;

  /// No description provided for @fiTabPaid.
  ///
  /// In pt, this message translates to:
  /// **'Pagos'**
  String get fiTabPaid;

  /// No description provided for @fiTabDismissed.
  ///
  /// In pt, this message translates to:
  /// **'Desconsiderados'**
  String get fiTabDismissed;

  /// No description provided for @fiDueOn.
  ///
  /// In pt, this message translates to:
  /// **'Venc. {date}'**
  String fiDueOn(String date);

  /// No description provided for @fiLateFee.
  ///
  /// In pt, this message translates to:
  /// **'+ Taxa de atraso: {value}'**
  String fiLateFee(String value);

  /// No description provided for @fiDiscount.
  ///
  /// In pt, this message translates to:
  /// **'- Desconto: {value}'**
  String fiDiscount(String value);

  /// No description provided for @fiReceivedAmount.
  ///
  /// In pt, this message translates to:
  /// **'Recebido: {value}'**
  String fiReceivedAmount(String value);

  /// No description provided for @fiMarkPaid.
  ///
  /// In pt, this message translates to:
  /// **'Marcar como pago'**
  String get fiMarkPaid;

  /// No description provided for @fiRefund.
  ///
  /// In pt, this message translates to:
  /// **'Estornar pagamento'**
  String get fiRefund;

  /// No description provided for @fiRefundTitle.
  ///
  /// In pt, this message translates to:
  /// **'Estornar pagamento?'**
  String get fiRefundTitle;

  /// No description provided for @fiRefundBody.
  ///
  /// In pt, this message translates to:
  /// **'Isso vai marcar o pagamento de {name} como pendente novamente.'**
  String fiRefundBody(String name);

  /// No description provided for @fiRefundDone.
  ///
  /// In pt, this message translates to:
  /// **'Pagamento estornado.'**
  String get fiRefundDone;

  /// No description provided for @fiRestoreCharge.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar cobrança'**
  String get fiRestoreCharge;

  /// No description provided for @fiDismissTitle.
  ///
  /// In pt, this message translates to:
  /// **'Desconsiderar cobrança?'**
  String get fiDismissTitle;

  /// No description provided for @fiDismissBody.
  ///
  /// In pt, this message translates to:
  /// **'A cobrança de {name} não será mais cobrada e sai dos totais do financeiro. Você pode restaurá-la depois.'**
  String fiDismissBody(String name);

  /// No description provided for @fiDeleteCharge.
  ///
  /// In pt, this message translates to:
  /// **'Excluir cobrança'**
  String get fiDeleteCharge;

  /// No description provided for @fiDeleteChargeBody.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza que deseja excluir esta cobrança? Esta ação não pode ser desfeita.'**
  String get fiDeleteChargeBody;

  /// No description provided for @fiMarkedPaid.
  ///
  /// In pt, this message translates to:
  /// **'{name} marcado como pago!'**
  String fiMarkedPaid(String name);

  /// No description provided for @fiUpdateError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao atualizar pagamento.'**
  String get fiUpdateError;

  /// No description provided for @fiConfirmPayment.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar pagamento'**
  String get fiConfirmPayment;

  /// No description provided for @fiBaseValue.
  ///
  /// In pt, this message translates to:
  /// **'Valor base'**
  String get fiBaseValue;

  /// No description provided for @fiToReceive.
  ///
  /// In pt, this message translates to:
  /// **'A receber'**
  String get fiToReceive;

  /// No description provided for @fiDiscountOptional.
  ///
  /// In pt, this message translates to:
  /// **'Desconto (opcional)'**
  String get fiDiscountOptional;

  /// No description provided for @fiLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar dados.'**
  String get fiLoadError;

  /// No description provided for @fiProcessError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao processar cobranças.'**
  String get fiProcessError;

  /// No description provided for @fiCreateError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao criar cobrança.'**
  String get fiCreateError;

  /// No description provided for @fiChargeCreated.
  ///
  /// In pt, this message translates to:
  /// **'Cobrança criada!'**
  String get fiChargeCreated;

  /// No description provided for @fiChargeViaWhatsapp.
  ///
  /// In pt, this message translates to:
  /// **'Cobrar via WhatsApp'**
  String get fiChargeViaWhatsapp;

  /// No description provided for @fiChargeViaWhatsappN.
  ///
  /// In pt, this message translates to:
  /// **'Cobrar via WhatsApp ({count})'**
  String fiChargeViaWhatsappN(int count);

  /// No description provided for @fiGenerateNCharges.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, one{Gerar 1 cobrança} other{Gerar {count} cobranças}}'**
  String fiGenerateNCharges(int count);

  /// No description provided for @fiAffectedStudents.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, one{1 aluno afetado} other{{count} alunos afetados}}'**
  String fiAffectedStudents(int count);

  /// No description provided for @fiSeeAffected.
  ///
  /// In pt, this message translates to:
  /// **'Ver alunos afetados'**
  String get fiSeeAffected;

  /// No description provided for @fiNoStudentsForFilter.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum aluno corresponde a este filtro.'**
  String get fiNoStudentsForFilter;

  /// No description provided for @fiNChargesGenerated.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, one{1 cobrança gerada} other{{count} cobranças geradas}}'**
  String fiNChargesGenerated(int count);

  /// No description provided for @fiReadyForWhatsapp.
  ///
  /// In pt, this message translates to:
  /// **'Pronto para cobrar via WhatsApp!'**
  String get fiReadyForWhatsapp;

  /// No description provided for @fiTapEachStudent.
  ///
  /// In pt, this message translates to:
  /// **'Toque em cada aluno para abrir o WhatsApp com uma mensagem pronta.'**
  String get fiTapEachStudent;

  /// No description provided for @fiNoPhone.
  ///
  /// In pt, this message translates to:
  /// **'Sem telefone'**
  String get fiNoPhone;

  /// No description provided for @fiSelectClass.
  ///
  /// In pt, this message translates to:
  /// **'Selecione a turma'**
  String get fiSelectClass;

  /// No description provided for @fiFilterBySituation.
  ///
  /// In pt, this message translates to:
  /// **'Filtrar por situação'**
  String get fiFilterBySituation;

  /// No description provided for @fiSelectStudent.
  ///
  /// In pt, this message translates to:
  /// **'Selecione o aluno'**
  String get fiSelectStudent;

  /// No description provided for @fiWhatsappGreeting.
  ///
  /// In pt, this message translates to:
  /// **'Olá {name}, '**
  String fiWhatsappGreeting(String name);

  /// No description provided for @fiOptNoChargeMonth.
  ///
  /// In pt, this message translates to:
  /// **'Sem cobrança este mês'**
  String get fiOptNoChargeMonth;

  /// No description provided for @fiOptDueWithin7.
  ///
  /// In pt, this message translates to:
  /// **'Venc. em até 7 dias'**
  String get fiOptDueWithin7;

  /// No description provided for @fiChooseWhoToCharge.
  ///
  /// In pt, this message translates to:
  /// **'Escolha quem deve ser cobrado:'**
  String get fiChooseWhoToCharge;

  /// No description provided for @fiByClass.
  ///
  /// In pt, this message translates to:
  /// **'Por turma'**
  String get fiByClass;

  /// No description provided for @fiByClassHint.
  ///
  /// In pt, this message translates to:
  /// **'Cobrar alunos de uma turma específica'**
  String get fiByClassHint;

  /// No description provided for @fiAllActive.
  ///
  /// In pt, this message translates to:
  /// **'Todos os ativos'**
  String get fiAllActive;

  /// No description provided for @fiAllActiveHint.
  ///
  /// In pt, this message translates to:
  /// **'Cobrar todos os alunos ativos da academia'**
  String get fiAllActiveHint;

  /// No description provided for @fiRefundShort.
  ///
  /// In pt, this message translates to:
  /// **'Estornar'**
  String get fiRefundShort;

  /// No description provided for @fiDismiss.
  ///
  /// In pt, this message translates to:
  /// **'Desconsiderar'**
  String get fiDismiss;

  /// No description provided for @fiBillsShort.
  ///
  /// In pt, this message translates to:
  /// **'Contas'**
  String get fiBillsShort;

  /// No description provided for @fiType.
  ///
  /// In pt, this message translates to:
  /// **'Tipo'**
  String get fiType;

  /// No description provided for @rkNoData.
  ///
  /// In pt, this message translates to:
  /// **'Sem dados no ranking'**
  String get rkNoData;

  /// No description provided for @rkNoCustom.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum ranking personalizado'**
  String get rkNoCustom;

  /// No description provided for @rkCreateHint.
  ///
  /// In pt, this message translates to:
  /// **'Crie um ranking por presença ou pontos.'**
  String get rkCreateHint;

  /// No description provided for @rkCreate.
  ///
  /// In pt, this message translates to:
  /// **'Criar ranking'**
  String get rkCreate;

  /// No description provided for @rkNewRanking.
  ///
  /// In pt, this message translates to:
  /// **'Novo ranking'**
  String get rkNewRanking;

  /// No description provided for @rkEditRanking.
  ///
  /// In pt, this message translates to:
  /// **'Editar ranking'**
  String get rkEditRanking;

  /// No description provided for @rkAskAdmin.
  ///
  /// In pt, this message translates to:
  /// **'Peça ao administrador que crie rankings personalizados.'**
  String get rkAskAdmin;

  /// No description provided for @rkGeneralRanking.
  ///
  /// In pt, this message translates to:
  /// **'Ranking Geral'**
  String get rkGeneralRanking;

  /// No description provided for @rkCustomTab.
  ///
  /// In pt, this message translates to:
  /// **'Personalizados'**
  String get rkCustomTab;

  /// No description provided for @rkWeightAttendance.
  ///
  /// In pt, this message translates to:
  /// **'Presenças ×{n}'**
  String rkWeightAttendance(Object n);

  /// No description provided for @rkWeightManual.
  ///
  /// In pt, this message translates to:
  /// **'Manual ×{n}'**
  String rkWeightManual(Object n);

  /// No description provided for @rkWithPeriod.
  ///
  /// In pt, this message translates to:
  /// **'📅 Com período'**
  String get rkWithPeriod;

  /// No description provided for @rkAddPoints.
  ///
  /// In pt, this message translates to:
  /// **'Lançar pontos'**
  String get rkAddPoints;

  /// No description provided for @rkNoParticipants.
  ///
  /// In pt, this message translates to:
  /// **'Sem participantes'**
  String get rkNoParticipants;

  /// No description provided for @rkNobodyScored.
  ///
  /// In pt, this message translates to:
  /// **'Ninguém pontuou neste ranking ainda.'**
  String get rkNobodyScored;

  /// No description provided for @rkAddPointsError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao lançar pontos'**
  String get rkAddPointsError;

  /// No description provided for @rkInvalidValue.
  ///
  /// In pt, this message translates to:
  /// **'Valor inválido'**
  String get rkInvalidValue;

  /// No description provided for @rkReasonOptional.
  ///
  /// In pt, this message translates to:
  /// **'Motivo (opcional)'**
  String get rkReasonOptional;

  /// No description provided for @rkReasonHint1.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Vitória no campeonato'**
  String get rkReasonHint1;

  /// No description provided for @rkUpdateError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao atualizar'**
  String get rkUpdateError;

  /// No description provided for @rkTapPlus.
  ///
  /// In pt, this message translates to:
  /// **'Toque em + para criar seu primeiro ranking'**
  String get rkTapPlus;

  /// No description provided for @rkAcademyNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Academia não encontrada.'**
  String get rkAcademyNotFound;

  /// No description provided for @rkNameRequired.
  ///
  /// In pt, this message translates to:
  /// **'Nome do ranking *'**
  String get rkNameRequired;

  /// No description provided for @rkPointsComposition.
  ///
  /// In pt, this message translates to:
  /// **'Composição dos pontos'**
  String get rkPointsComposition;

  /// No description provided for @rkIncludeAttendance.
  ///
  /// In pt, this message translates to:
  /// **'Incluir presenças'**
  String get rkIncludeAttendance;

  /// No description provided for @rkEachAttendanceCounts.
  ///
  /// In pt, this message translates to:
  /// **'Cada presença conta como pontos'**
  String get rkEachAttendanceCounts;

  /// No description provided for @rkAttendanceWeight.
  ///
  /// In pt, this message translates to:
  /// **'Peso de cada presença:'**
  String get rkAttendanceWeight;

  /// No description provided for @rkIncludeManual.
  ///
  /// In pt, this message translates to:
  /// **'Incluir pontos manuais'**
  String get rkIncludeManual;

  /// No description provided for @rkManualHint.
  ///
  /// In pt, this message translates to:
  /// **'Pontos lançados manualmente pelo professor/admin'**
  String get rkManualHint;

  /// No description provided for @rkManualWeight.
  ///
  /// In pt, this message translates to:
  /// **'Peso dos pontos manuais:'**
  String get rkManualWeight;

  /// No description provided for @rkValidityPeriod.
  ///
  /// In pt, this message translates to:
  /// **'Período de validade'**
  String get rkValidityPeriod;

  /// No description provided for @rkOutsidePeriodIgnored.
  ///
  /// In pt, this message translates to:
  /// **'Presenças fora deste período serão ignoradas no cálculo.'**
  String get rkOutsidePeriodIgnored;

  /// No description provided for @rkStartDate.
  ///
  /// In pt, this message translates to:
  /// **'Data início'**
  String get rkStartDate;

  /// No description provided for @rkEndDate.
  ///
  /// In pt, this message translates to:
  /// **'Data fim'**
  String get rkEndDate;

  /// No description provided for @rkRemoveEntryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Remover lançamento?'**
  String get rkRemoveEntryTitle;

  /// No description provided for @rkRemoveEntryBody.
  ///
  /// In pt, this message translates to:
  /// **'Este lançamento será removido permanentemente.'**
  String get rkRemoveEntryBody;

  /// No description provided for @rkEntries.
  ///
  /// In pt, this message translates to:
  /// **'Lançamentos'**
  String get rkEntries;

  /// No description provided for @rkNoParticipantsYet.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum participante ainda'**
  String get rkNoParticipantsYet;

  /// No description provided for @rkPtsAttendance.
  ///
  /// In pt, this message translates to:
  /// **'{n}pts presenças'**
  String rkPtsAttendance(Object n);

  /// No description provided for @rkPtsManual.
  ///
  /// In pt, this message translates to:
  /// **'{n}pts manuais'**
  String rkPtsManual(Object n);

  /// No description provided for @rkNoPointsYet.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum ponto lançado ainda'**
  String get rkNoPointsYet;

  /// No description provided for @rkUseButtonBelow.
  ///
  /// In pt, this message translates to:
  /// **'Use o botão abaixo para lançar pontos'**
  String get rkUseButtonBelow;

  /// No description provided for @rkEnterPoints.
  ///
  /// In pt, this message translates to:
  /// **'Informe a quantidade de pontos'**
  String get rkEnterPoints;

  /// No description provided for @rkMustNotBeZero.
  ///
  /// In pt, this message translates to:
  /// **'Deve ser diferente de zero'**
  String get rkMustNotBeZero;

  /// No description provided for @rkPointsHint.
  ///
  /// In pt, this message translates to:
  /// **'Pontos (ex: 10, -5)'**
  String get rkPointsHint;

  /// No description provided for @rkDescribeReason.
  ///
  /// In pt, this message translates to:
  /// **'Descreva o motivo'**
  String get rkDescribeReason;

  /// No description provided for @rkReasonHint2.
  ///
  /// In pt, this message translates to:
  /// **'Motivo (ex: 1º lugar no torneio X)'**
  String get rkReasonHint2;

  /// No description provided for @rkConfirmEntry.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar lançamento'**
  String get rkConfirmEntry;

  /// No description provided for @rkViewLeaderboardAddPoints.
  ///
  /// In pt, this message translates to:
  /// **'Ver leaderboard e lançar pontos'**
  String get rkViewLeaderboardAddPoints;

  /// No description provided for @rkNoRankings.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum ranking criado'**
  String get rkNoRankings;

  /// No description provided for @rkVisibleStudentShort.
  ///
  /// In pt, this message translates to:
  /// **'Visível aluno'**
  String get rkVisibleStudentShort;

  /// No description provided for @rkVisibleToStudents.
  ///
  /// In pt, this message translates to:
  /// **'Visível para os alunos'**
  String get rkVisibleToStudents;

  /// No description provided for @rkVisibleHint.
  ///
  /// In pt, this message translates to:
  /// **'Os alunos poderão ver este ranking no app'**
  String get rkVisibleHint;

  /// No description provided for @rkByOn.
  ///
  /// In pt, this message translates to:
  /// **'por {name} • {date}'**
  String rkByOn(String name, String date);

  /// No description provided for @rkManage.
  ///
  /// In pt, this message translates to:
  /// **'Gerenciar'**
  String get rkManage;

  /// No description provided for @rkVisibility.
  ///
  /// In pt, this message translates to:
  /// **'Visibilidade'**
  String get rkVisibility;

  /// No description provided for @newsNew.
  ///
  /// In pt, this message translates to:
  /// **'Nova notícia'**
  String get newsNew;

  /// No description provided for @newsPublished.
  ///
  /// In pt, this message translates to:
  /// **'Notícia publicada!'**
  String get newsPublished;

  /// No description provided for @newsPublishError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao publicar.'**
  String get newsPublishError;

  /// No description provided for @newsDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir notícia?'**
  String get newsDeleteTitle;

  /// No description provided for @newsDeleteBody.
  ///
  /// In pt, this message translates to:
  /// **'Esta ação não pode ser desfeita.'**
  String get newsDeleteBody;

  /// No description provided for @newsDeleteError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao excluir.'**
  String get newsDeleteError;

  /// No description provided for @newsEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma notícia cadastrada.'**
  String get newsEmpty;

  /// No description provided for @newsStatusPublished.
  ///
  /// In pt, this message translates to:
  /// **'Publicada'**
  String get newsStatusPublished;

  /// No description provided for @newsStatusDraft.
  ///
  /// In pt, this message translates to:
  /// **'Rascunho'**
  String get newsStatusDraft;

  /// No description provided for @newsPublish.
  ///
  /// In pt, this message translates to:
  /// **'Publicar'**
  String get newsPublish;

  /// No description provided for @newsEditTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar Notícia'**
  String get newsEditTitle;

  /// No description provided for @newsNewTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nova Notícia'**
  String get newsNewTitle;

  /// No description provided for @newsImageTooLarge.
  ///
  /// In pt, this message translates to:
  /// **'Imagem muito grande. Máximo 3MB.'**
  String get newsImageTooLarge;

  /// No description provided for @newsTitleSummaryRequired.
  ///
  /// In pt, this message translates to:
  /// **'Título e resumo são obrigatórios.'**
  String get newsTitleSummaryRequired;

  /// No description provided for @newsSaveError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar notícia.'**
  String get newsSaveError;

  /// No description provided for @newsAddImage.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar imagem (opcional)'**
  String get newsAddImage;

  /// No description provided for @newsFieldTitle.
  ///
  /// In pt, this message translates to:
  /// **'Título'**
  String get newsFieldTitle;

  /// No description provided for @newsFieldSummary.
  ///
  /// In pt, this message translates to:
  /// **'Resumo (exibido na lista)'**
  String get newsFieldSummary;

  /// No description provided for @newsFieldContent.
  ///
  /// In pt, this message translates to:
  /// **'Conteúdo completo (opcional)'**
  String get newsFieldContent;

  /// No description provided for @newsPublishNow.
  ///
  /// In pt, this message translates to:
  /// **'Publicar agora e notificar'**
  String get newsPublishNow;

  /// No description provided for @newsCreate.
  ///
  /// In pt, this message translates to:
  /// **'Criar notícia'**
  String get newsCreate;

  /// No description provided for @newsNonePublished.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma notícia publicada ainda.'**
  String get newsNonePublished;

  /// No description provided for @newsDetailTitle.
  ///
  /// In pt, this message translates to:
  /// **'Notícia'**
  String get newsDetailTitle;

  /// No description provided for @commonNew.
  ///
  /// In pt, this message translates to:
  /// **'Novo'**
  String get commonNew;

  /// No description provided for @commonPreview.
  ///
  /// In pt, this message translates to:
  /// **'Prévia'**
  String get commonPreview;

  /// No description provided for @plnTitle.
  ///
  /// In pt, this message translates to:
  /// **'Planos de Pagamento'**
  String get plnTitle;

  /// No description provided for @plnLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar planos.'**
  String get plnLoadError;

  /// No description provided for @plnEditTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar Plano'**
  String get plnEditTitle;

  /// No description provided for @plnNewTitle.
  ///
  /// In pt, this message translates to:
  /// **'Novo Plano'**
  String get plnNewTitle;

  /// No description provided for @plnNameField.
  ///
  /// In pt, this message translates to:
  /// **'Nome do plano *'**
  String get plnNameField;

  /// No description provided for @plnMonthlyValueField.
  ///
  /// In pt, this message translates to:
  /// **'Valor mensal (R\$) *'**
  String get plnMonthlyValueField;

  /// No description provided for @plnNameRequired.
  ///
  /// In pt, this message translates to:
  /// **'Nome é obrigatório.'**
  String get plnNameRequired;

  /// No description provided for @plnInvalidValue.
  ///
  /// In pt, this message translates to:
  /// **'Informe um valor mensal válido.'**
  String get plnInvalidValue;

  /// No description provided for @plnUpdated.
  ///
  /// In pt, this message translates to:
  /// **'Plano atualizado!'**
  String get plnUpdated;

  /// No description provided for @plnCreated.
  ///
  /// In pt, this message translates to:
  /// **'Plano criado!'**
  String get plnCreated;

  /// No description provided for @plnSaveError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar plano.'**
  String get plnSaveError;

  /// No description provided for @plnCreateBtn.
  ///
  /// In pt, this message translates to:
  /// **'Criar plano'**
  String get plnCreateBtn;

  /// No description provided for @plnDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir plano'**
  String get plnDeleteTitle;

  /// No description provided for @plnDeleteBody.
  ///
  /// In pt, this message translates to:
  /// **'Excluir o plano \"{name}\"?\nAlunos vinculados não serão afetados.'**
  String plnDeleteBody(String name);

  /// No description provided for @plnDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Plano excluído.'**
  String get plnDeleted;

  /// No description provided for @plnDeleteError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao excluir plano.'**
  String get plnDeleteError;

  /// No description provided for @plnEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum plano cadastrado.'**
  String get plnEmpty;

  /// No description provided for @plnEmptyHint.
  ///
  /// In pt, this message translates to:
  /// **'Crie planos para vincular aos alunos.'**
  String get plnEmptyHint;

  /// No description provided for @plnCreateFirst.
  ///
  /// In pt, this message translates to:
  /// **'Criar primeiro plano'**
  String get plnCreateFirst;

  /// No description provided for @plnPerMonth.
  ///
  /// In pt, this message translates to:
  /// **'R\$ {value} / mês'**
  String plnPerMonth(String value);

  /// No description provided for @psvManageTitle.
  ///
  /// In pt, this message translates to:
  /// **'Gerenciar Pesquisas'**
  String get psvManageTitle;

  /// No description provided for @psvSatisfactionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisa de Satisfação'**
  String get psvSatisfactionTitle;

  /// No description provided for @psvFallbackTitle.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisa'**
  String get psvFallbackTitle;

  /// No description provided for @psvEditTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar pesquisa'**
  String get psvEditTitle;

  /// No description provided for @psvNewTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nova pesquisa'**
  String get psvNewTitle;

  /// No description provided for @psvTitleField.
  ///
  /// In pt, this message translates to:
  /// **'Título da pesquisa *'**
  String get psvTitleField;

  /// No description provided for @psvCreateBtn.
  ///
  /// In pt, this message translates to:
  /// **'Criar pesquisa'**
  String get psvCreateBtn;

  /// No description provided for @psvSaveError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar pesquisa.'**
  String get psvSaveError;

  /// No description provided for @psvStatusError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao alterar status.'**
  String get psvStatusError;

  /// No description provided for @psvDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir pesquisa?'**
  String get psvDeleteTitle;

  /// No description provided for @psvDeleteBody.
  ///
  /// In pt, this message translates to:
  /// **'Ao excluir \"{title}\", os dados de resposta desta pesquisa serão mantidos no histórico, mas o template não estará mais disponível.'**
  String psvDeleteBody(String title);

  /// No description provided for @psvDeleteError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao excluir pesquisa.'**
  String get psvDeleteError;

  /// No description provided for @psvLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar.'**
  String get psvLoadError;

  /// No description provided for @psvEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma pesquisa criada ainda'**
  String get psvEmpty;

  /// No description provided for @psvEmptyHint.
  ///
  /// In pt, this message translates to:
  /// **'Toque em \"Nova pesquisa\" para começar'**
  String get psvEmptyHint;

  /// No description provided for @psvActiveInfo.
  ///
  /// In pt, this message translates to:
  /// **'Apenas uma pesquisa pode estar ativa por vez. A pesquisa ativa é exibida para os alunos no mês corrente.'**
  String get psvActiveInfo;

  /// No description provided for @psvUntitled.
  ///
  /// In pt, this message translates to:
  /// **'Sem título'**
  String get psvUntitled;

  /// No description provided for @psvActiveBadge.
  ///
  /// In pt, this message translates to:
  /// **'ATIVA'**
  String get psvActiveBadge;

  /// No description provided for @psvViewResponses.
  ///
  /// In pt, this message translates to:
  /// **'Ver respostas'**
  String get psvViewResponses;

  /// No description provided for @psvResponsesLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar respostas.'**
  String get psvResponsesLoadError;

  /// No description provided for @psvNoResponsesIn.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma resposta em {month}'**
  String psvNoResponsesIn(String month);

  /// No description provided for @psvOverallAverage.
  ///
  /// In pt, this message translates to:
  /// **'Média geral'**
  String get psvOverallAverage;

  /// No description provided for @psvResponsesCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{{count} resposta} other{{count} respostas}}'**
  String psvResponsesCount(int count);

  /// No description provided for @psvDistribution.
  ///
  /// In pt, this message translates to:
  /// **'Distribuição'**
  String get psvDistribution;

  /// No description provided for @psvRate1.
  ///
  /// In pt, this message translates to:
  /// **'Muito ruim'**
  String get psvRate1;

  /// No description provided for @psvRate2.
  ///
  /// In pt, this message translates to:
  /// **'Ruim'**
  String get psvRate2;

  /// No description provided for @psvRate3.
  ///
  /// In pt, this message translates to:
  /// **'Regular'**
  String get psvRate3;

  /// No description provided for @psvRate4.
  ///
  /// In pt, this message translates to:
  /// **'Bom'**
  String get psvRate4;

  /// No description provided for @psvRate5.
  ///
  /// In pt, this message translates to:
  /// **'Excelente'**
  String get psvRate5;

  /// No description provided for @psvCommentsCount.
  ///
  /// In pt, this message translates to:
  /// **'Comentários ({count})'**
  String psvCommentsCount(int count);

  /// No description provided for @ctTitle.
  ///
  /// In pt, this message translates to:
  /// **'Modelos de Contrato'**
  String get ctTitle;

  /// No description provided for @ctNew.
  ///
  /// In pt, this message translates to:
  /// **'Novo Modelo'**
  String get ctNew;

  /// No description provided for @ctRemoveTitle.
  ///
  /// In pt, this message translates to:
  /// **'Remover Modelo'**
  String get ctRemoveTitle;

  /// No description provided for @ctRemoveBody.
  ///
  /// In pt, this message translates to:
  /// **'Deseja remover \"{name}\"?'**
  String ctRemoveBody(String name);

  /// No description provided for @ctRemoveError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao remover modelo'**
  String get ctRemoveError;

  /// No description provided for @ctLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar'**
  String get ctLoadError;

  /// No description provided for @ctEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum modelo cadastrado'**
  String get ctEmpty;

  /// No description provided for @ctEmptyHint.
  ///
  /// In pt, this message translates to:
  /// **'Toque em + para criar'**
  String get ctEmptyHint;

  /// No description provided for @ctEditTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar Modelo'**
  String get ctEditTitle;

  /// No description provided for @ctNewTitle.
  ///
  /// In pt, this message translates to:
  /// **'Novo Modelo de Contrato'**
  String get ctNewTitle;

  /// No description provided for @ctPreview.
  ///
  /// In pt, this message translates to:
  /// **'Preview'**
  String get ctPreview;

  /// No description provided for @ctNameField.
  ///
  /// In pt, this message translates to:
  /// **'Nome do Modelo'**
  String get ctNameField;

  /// No description provided for @ctHtmlField.
  ///
  /// In pt, this message translates to:
  /// **'Conteúdo HTML'**
  String get ctHtmlField;

  /// No description provided for @ctSaveError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar modelo'**
  String get ctSaveError;

  /// No description provided for @ctCreateBtn.
  ///
  /// In pt, this message translates to:
  /// **'Criar Modelo'**
  String get ctCreateBtn;

  /// No description provided for @mdlActivate.
  ///
  /// In pt, this message translates to:
  /// **'Ativar'**
  String get mdlActivate;

  /// No description provided for @mdlDeactivate.
  ///
  /// In pt, this message translates to:
  /// **'Desativar'**
  String get mdlDeactivate;

  /// No description provided for @mdlDeactivateBody.
  ///
  /// In pt, this message translates to:
  /// **'Ela deixará de aparecer nas telas de turmas, faixas e cadastro de alunos, mas não será excluída.'**
  String get mdlDeactivateBody;

  /// No description provided for @mdlActivateBody.
  ///
  /// In pt, this message translates to:
  /// **'Esta modalidade voltará a aparecer em todas as telas operacionais.'**
  String get mdlActivateBody;

  /// No description provided for @mdlToggleError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível alterar a modalidade.'**
  String get mdlToggleError;

  /// No description provided for @mdlLinksCheckError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível verificar os vínculos da modalidade.'**
  String get mdlLinksCheckError;

  /// No description provided for @mdlCannotDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Não é possível excluir'**
  String get mdlCannotDeleteTitle;

  /// No description provided for @mdlCannotDeleteBody.
  ///
  /// In pt, this message translates to:
  /// **'A modalidade \"{name}\" possui turmas ou faixas vinculadas. Você pode desativá-la — assim ela some das telas operacionais sem apagar o histórico.'**
  String mdlCannotDeleteBody(String name);

  /// No description provided for @mdlDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir \"{name}\"?'**
  String mdlDeleteTitle(String name);

  /// No description provided for @mdlDeleteBody.
  ///
  /// In pt, this message translates to:
  /// **'Essa ação não poderá ser desfeita.'**
  String get mdlDeleteBody;

  /// No description provided for @mdlDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Modalidade excluída.'**
  String get mdlDeleted;

  /// No description provided for @mdlDeleteError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível excluir a modalidade.'**
  String get mdlDeleteError;

  /// No description provided for @mdlTitle.
  ///
  /// In pt, this message translates to:
  /// **'Modalidades'**
  String get mdlTitle;

  /// No description provided for @mdlSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Gerencie as modalidades da sua academia.'**
  String get mdlSubtitle;

  /// No description provided for @mdlNew.
  ///
  /// In pt, this message translates to:
  /// **'Nova modalidade'**
  String get mdlNew;

  /// No description provided for @mdlInfoBanner.
  ///
  /// In pt, this message translates to:
  /// **'Modalidades ativas aparecem na gestão de faixas, turmas e demais telas operacionais.'**
  String get mdlInfoBanner;

  /// No description provided for @mdlFilterActive.
  ///
  /// In pt, this message translates to:
  /// **'Ativas'**
  String get mdlFilterActive;

  /// No description provided for @mdlFilterInactive.
  ///
  /// In pt, this message translates to:
  /// **'Inativas'**
  String get mdlFilterInactive;

  /// No description provided for @mdlFilterAllCount.
  ///
  /// In pt, this message translates to:
  /// **'Todas ({count})'**
  String mdlFilterAllCount(int count);

  /// No description provided for @mdlFilterActiveCount.
  ///
  /// In pt, this message translates to:
  /// **'Ativas ({count})'**
  String mdlFilterActiveCount(int count);

  /// No description provided for @mdlFilterInactiveCount.
  ///
  /// In pt, this message translates to:
  /// **'Inativas ({count})'**
  String mdlFilterInactiveCount(int count);

  /// No description provided for @mdlSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar modalidade...'**
  String get mdlSearchHint;

  /// No description provided for @mdlSortAZ.
  ///
  /// In pt, this message translates to:
  /// **'A–Z'**
  String get mdlSortAZ;

  /// No description provided for @mdlSortZA.
  ///
  /// In pt, this message translates to:
  /// **'Z–A'**
  String get mdlSortZA;

  /// No description provided for @mdlStatusActive.
  ///
  /// In pt, this message translates to:
  /// **'Ativa'**
  String get mdlStatusActive;

  /// No description provided for @mdlStatusInactive.
  ///
  /// In pt, this message translates to:
  /// **'Inativa'**
  String get mdlStatusInactive;

  /// No description provided for @mdlA11yDeactivate.
  ///
  /// In pt, this message translates to:
  /// **'Desativar modalidade {name}'**
  String mdlA11yDeactivate(String name);

  /// No description provided for @mdlA11yActivate.
  ///
  /// In pt, this message translates to:
  /// **'Ativar modalidade {name}'**
  String mdlA11yActivate(String name);

  /// No description provided for @mdlEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma modalidade cadastrada.'**
  String get mdlEmpty;

  /// No description provided for @mdlEmptyHint.
  ///
  /// In pt, this message translates to:
  /// **'Adicione a primeira modalidade da sua academia.'**
  String get mdlEmptyHint;

  /// No description provided for @mdlNoResults.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma modalidade encontrada.'**
  String get mdlNoResults;

  /// No description provided for @mdlLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar as modalidades.'**
  String get mdlLoadError;

  /// No description provided for @mdlImageTooLarge.
  ///
  /// In pt, this message translates to:
  /// **'Imagem muito grande (máximo 8 MB).'**
  String get mdlImageTooLarge;

  /// No description provided for @mdlImageProcessError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível processar a imagem.'**
  String get mdlImageProcessError;

  /// No description provided for @mdlImagePickError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível selecionar a imagem.'**
  String get mdlImagePickError;

  /// No description provided for @mdlSaveError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar a modalidade.'**
  String get mdlSaveError;

  /// No description provided for @mdlEditTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar Modalidade'**
  String get mdlEditTitle;

  /// No description provided for @mdlNewTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nova Modalidade'**
  String get mdlNewTitle;

  /// No description provided for @mdlNameField.
  ///
  /// In pt, this message translates to:
  /// **'Nome da modalidade'**
  String get mdlNameField;

  /// No description provided for @mdlNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex.: Jiu-Jitsu Adulto'**
  String get mdlNameHint;

  /// No description provided for @mdlActiveToggle.
  ///
  /// In pt, this message translates to:
  /// **'Modalidade ativa'**
  String get mdlActiveToggle;

  /// No description provided for @mdlActiveToggleSub.
  ///
  /// In pt, this message translates to:
  /// **'Modalidades inativas não aparecem nas telas operacionais.'**
  String get mdlActiveToggleSub;

  /// No description provided for @mdlVisualId.
  ///
  /// In pt, this message translates to:
  /// **'Identificação visual'**
  String get mdlVisualId;

  /// No description provided for @mdlDefaultIcon.
  ///
  /// In pt, this message translates to:
  /// **'Ícone padrão'**
  String get mdlDefaultIcon;

  /// No description provided for @mdlUploadImage.
  ///
  /// In pt, this message translates to:
  /// **'Enviar imagem'**
  String get mdlUploadImage;

  /// No description provided for @mdlCreateBtn.
  ///
  /// In pt, this message translates to:
  /// **'Criar Modalidade'**
  String get mdlCreateBtn;

  /// No description provided for @mdlChangeImage.
  ///
  /// In pt, this message translates to:
  /// **'Trocar imagem'**
  String get mdlChangeImage;

  /// No description provided for @mdlChooseGallery.
  ///
  /// In pt, this message translates to:
  /// **'Escolher da galeria'**
  String get mdlChooseGallery;

  /// No description provided for @mdlImageHint.
  ///
  /// In pt, this message translates to:
  /// **'JPG ou PNG. A imagem é recortada em quadrado.'**
  String get mdlImageHint;

  /// No description provided for @fxDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir faixa?'**
  String get fxDeleteTitle;

  /// No description provided for @fxDeleteBody.
  ///
  /// In pt, this message translates to:
  /// **'A faixa \"{name}\" será removida.'**
  String fxDeleteBody(String name);

  /// No description provided for @fxDeleteError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível excluir a faixa.'**
  String get fxDeleteError;

  /// No description provided for @fxAboutTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sobre as faixas'**
  String get fxAboutTitle;

  /// No description provided for @fxAboutBody.
  ///
  /// In pt, this message translates to:
  /// **'Cada modalidade pode possuir suas próprias faixas e critérios de graduação.'**
  String get fxAboutBody;

  /// No description provided for @fxSelectModality.
  ///
  /// In pt, this message translates to:
  /// **'Selecione a modalidade'**
  String get fxSelectModality;

  /// No description provided for @fxNewBelt.
  ///
  /// In pt, this message translates to:
  /// **'Nova Faixa'**
  String get fxNewBelt;

  /// No description provided for @fxLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar as faixas.'**
  String get fxLoadError;

  /// No description provided for @fxNoModalities.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma modalidade cadastrada'**
  String get fxNoModalities;

  /// No description provided for @fxNoModalitiesHint.
  ///
  /// In pt, this message translates to:
  /// **'Cadastre uma modalidade antes de configurar faixas.'**
  String get fxNoModalitiesHint;

  /// No description provided for @fxEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma faixa cadastrada'**
  String get fxEmpty;

  /// No description provided for @fxEmptyHint.
  ///
  /// In pt, this message translates to:
  /// **'Cadastre a primeira faixa desta modalidade.'**
  String get fxEmptyHint;

  /// No description provided for @fxCreateFirst.
  ///
  /// In pt, this message translates to:
  /// **'Criar primeira faixa'**
  String get fxCreateFirst;

  /// No description provided for @fxTitle.
  ///
  /// In pt, this message translates to:
  /// **'Gestão de Faixas'**
  String get fxTitle;

  /// No description provided for @fxSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Cadastre e organize as faixas de cada modalidade.'**
  String get fxSubtitle;

  /// No description provided for @fxHelp.
  ///
  /// In pt, this message translates to:
  /// **'Ajuda'**
  String get fxHelp;

  /// No description provided for @fxModality.
  ///
  /// In pt, this message translates to:
  /// **'Modalidade'**
  String get fxModality;

  /// No description provided for @fxBeltsCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{{count} faixa cadastrada} other{{count} faixas cadastradas}}'**
  String fxBeltsCount(int count);

  /// No description provided for @fxStudentsInModality.
  ///
  /// In pt, this message translates to:
  /// **'Alunos nesta modalidade'**
  String get fxStudentsInModality;

  /// No description provided for @fxMinMonths.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{Mín. {count} mês} other{Mín. {count} meses}}'**
  String fxMinMonths(int count);

  /// No description provided for @fxMinAttendances.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{Mín. {count} presença} other{Mín. {count} presenças}}'**
  String fxMinAttendances(int count);

  /// No description provided for @fxNoMinReq.
  ///
  /// In pt, this message translates to:
  /// **'Sem exigência mínima'**
  String get fxNoMinReq;

  /// No description provided for @fxSaveError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar a faixa.'**
  String get fxSaveError;

  /// No description provided for @fxEnterZeroOrMore.
  ///
  /// In pt, this message translates to:
  /// **'Informe 0 ou mais'**
  String get fxEnterZeroOrMore;

  /// No description provided for @fxNumbersOnly.
  ///
  /// In pt, this message translates to:
  /// **'Somente números'**
  String get fxNumbersOnly;

  /// No description provided for @fxNotNegative.
  ///
  /// In pt, this message translates to:
  /// **'Não pode ser negativo'**
  String get fxNotNegative;

  /// No description provided for @fxEditTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar Faixa'**
  String get fxEditTitle;

  /// No description provided for @fxNameField.
  ///
  /// In pt, this message translates to:
  /// **'Nome da Faixa'**
  String get fxNameField;

  /// No description provided for @fxNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex.: Branca, Azul, Roxa...'**
  String get fxNameHint;

  /// No description provided for @fxOrder.
  ///
  /// In pt, this message translates to:
  /// **'Ordem'**
  String get fxOrder;

  /// No description provided for @fxInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Inválido'**
  String get fxInvalid;

  /// No description provided for @fxMin1.
  ///
  /// In pt, this message translates to:
  /// **'Mínimo 1'**
  String get fxMin1;

  /// No description provided for @fxOrderHint.
  ///
  /// In pt, this message translates to:
  /// **'Posição da faixa na progressão da modalidade.'**
  String get fxOrderHint;

  /// No description provided for @fxGradCriteria.
  ///
  /// In pt, this message translates to:
  /// **'Critérios para graduação'**
  String get fxGradCriteria;

  /// No description provided for @fxMinTimeMonths.
  ///
  /// In pt, this message translates to:
  /// **'Tempo mínimo (meses)'**
  String get fxMinTimeMonths;

  /// No description provided for @fxMinTimeMonthsHint.
  ///
  /// In pt, this message translates to:
  /// **'Meses de treino antes de graduar.'**
  String get fxMinTimeMonthsHint;

  /// No description provided for @fxMinAttendancesField.
  ///
  /// In pt, this message translates to:
  /// **'Presenças mínimas'**
  String get fxMinAttendancesField;

  /// No description provided for @fxMinAttendancesHint.
  ///
  /// In pt, this message translates to:
  /// **'Treinos necessários para graduar.'**
  String get fxMinAttendancesHint;

  /// No description provided for @fxDescHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex.: Observações sobre a faixa...'**
  String get fxDescHint;

  /// No description provided for @fxBeltColor.
  ///
  /// In pt, this message translates to:
  /// **'Cor da Faixa'**
  String get fxBeltColor;

  /// No description provided for @fxCreateBtn.
  ///
  /// In pt, this message translates to:
  /// **'Criar Faixa'**
  String get fxCreateBtn;

  /// No description provided for @cfgTitle.
  ///
  /// In pt, this message translates to:
  /// **'Configurações da Academia'**
  String get cfgTitle;

  /// No description provided for @cfgSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Gerencie as informações e preferências da sua academia.'**
  String get cfgSubtitle;

  /// No description provided for @cfgIdentitySection.
  ///
  /// In pt, this message translates to:
  /// **'Identidade da Academia'**
  String get cfgIdentitySection;

  /// No description provided for @cfgIdentitySub.
  ///
  /// In pt, this message translates to:
  /// **'Personalize as informações da sua academia.'**
  String get cfgIdentitySub;

  /// No description provided for @cfgLogo.
  ///
  /// In pt, this message translates to:
  /// **'Logo da Academia'**
  String get cfgLogo;

  /// No description provided for @cfgLogoHasSub.
  ///
  /// In pt, this message translates to:
  /// **'Toque para alterar ou remover'**
  String get cfgLogoHasSub;

  /// No description provided for @cfgLogoEmptySub.
  ///
  /// In pt, this message translates to:
  /// **'Adicione a logo da academia'**
  String get cfgLogoEmptySub;

  /// No description provided for @cfgGeneralInfo.
  ///
  /// In pt, this message translates to:
  /// **'Informações Gerais'**
  String get cfgGeneralInfo;

  /// No description provided for @cfgGeneralInfoSub.
  ///
  /// In pt, this message translates to:
  /// **'Nome, e-mail, telefone, CNPJ'**
  String get cfgGeneralInfoSub;

  /// No description provided for @cfgStudentsSection.
  ///
  /// In pt, this message translates to:
  /// **'Alunos'**
  String get cfgStudentsSection;

  /// No description provided for @cfgStudentsSub.
  ///
  /// In pt, this message translates to:
  /// **'Configure opções relacionadas aos alunos.'**
  String get cfgStudentsSub;

  /// No description provided for @cfgBlockCheckin.
  ///
  /// In pt, this message translates to:
  /// **'Bloquear check-in por mensalidade vencida'**
  String get cfgBlockCheckin;

  /// No description provided for @cfgBlockCheckinSub.
  ///
  /// In pt, this message translates to:
  /// **'Impede check-in de alunos com pagamento vencido'**
  String get cfgBlockCheckinSub;

  /// No description provided for @cfgGraceDays.
  ///
  /// In pt, this message translates to:
  /// **'Dias de carência'**
  String get cfgGraceDays;

  /// No description provided for @cfgGraceDaysSub.
  ///
  /// In pt, this message translates to:
  /// **'Bloqueia após os dias definidos do vencimento'**
  String get cfgGraceDaysSub;

  /// No description provided for @cfgDaysCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{{count} dia} other{{count} dias}}'**
  String cfgDaysCount(int count);

  /// No description provided for @cfgCommSection.
  ///
  /// In pt, this message translates to:
  /// **'Comunicação'**
  String get cfgCommSection;

  /// No description provided for @cfgCommSub.
  ///
  /// In pt, this message translates to:
  /// **'Personalize as mensagens enviadas aos alunos.'**
  String get cfgCommSub;

  /// No description provided for @cfgReturnMsg.
  ///
  /// In pt, this message translates to:
  /// **'Mensagem de retorno (WhatsApp)'**
  String get cfgReturnMsg;

  /// No description provided for @cfgReturnMsgSub.
  ///
  /// In pt, this message translates to:
  /// **'Mensagem para alunos em risco de evasão'**
  String get cfgReturnMsgSub;

  /// No description provided for @cfgNewsSub.
  ///
  /// In pt, this message translates to:
  /// **'Publicar notícias e comunicados'**
  String get cfgNewsSub;

  /// No description provided for @cfgFinanceSection.
  ///
  /// In pt, this message translates to:
  /// **'Financeiro'**
  String get cfgFinanceSection;

  /// No description provided for @cfgFinanceSub.
  ///
  /// In pt, this message translates to:
  /// **'Configure cobranças e opções financeiras.'**
  String get cfgFinanceSub;

  /// No description provided for @cfgPlansSub.
  ///
  /// In pt, this message translates to:
  /// **'Criar, editar e excluir planos de mensalidade'**
  String get cfgPlansSub;

  /// No description provided for @cfgLateFee.
  ///
  /// In pt, this message translates to:
  /// **'Taxa de atraso'**
  String get cfgLateFee;

  /// No description provided for @cfgLateFeeSub.
  ///
  /// In pt, this message translates to:
  /// **'Valor extra exibido em cobranças vencidas'**
  String get cfgLateFeeSub;

  /// No description provided for @cfgConfigFee.
  ///
  /// In pt, this message translates to:
  /// **'Configurar taxa'**
  String get cfgConfigFee;

  /// No description provided for @cfgFeePercentSub.
  ///
  /// In pt, this message translates to:
  /// **'Percentual sobre cobranças vencidas'**
  String get cfgFeePercentSub;

  /// No description provided for @cfgFeeFixedSub.
  ///
  /// In pt, this message translates to:
  /// **'Valor fixo em cobranças vencidas'**
  String get cfgFeeFixedSub;

  /// No description provided for @cfgGradSection.
  ///
  /// In pt, this message translates to:
  /// **'Graduações e Modalidades'**
  String get cfgGradSection;

  /// No description provided for @cfgGradSub.
  ///
  /// In pt, this message translates to:
  /// **'Configure faixas, graduações e modalidades.'**
  String get cfgGradSub;

  /// No description provided for @cfgBeltsSub.
  ///
  /// In pt, this message translates to:
  /// **'Cadastrar e editar graduações por modalidade'**
  String get cfgBeltsSub;

  /// No description provided for @cfgModalitiesMgmt.
  ///
  /// In pt, this message translates to:
  /// **'Gestão de Modalidades'**
  String get cfgModalitiesMgmt;

  /// No description provided for @cfgModalitiesSub.
  ///
  /// In pt, this message translates to:
  /// **'Ativar, desativar ou criar modalidades'**
  String get cfgModalitiesSub;

  /// No description provided for @cfgContractsSub.
  ///
  /// In pt, this message translates to:
  /// **'Criar e editar modelos de contrato'**
  String get cfgContractsSub;

  /// No description provided for @cfgSurveySub.
  ///
  /// In pt, this message translates to:
  /// **'Configure pesquisas e acompanhe as respostas dos alunos.'**
  String get cfgSurveySub;

  /// No description provided for @cfgSurveyConfig.
  ///
  /// In pt, this message translates to:
  /// **'Configurações da pesquisa'**
  String get cfgSurveyConfig;

  /// No description provided for @cfgSurveyActiveSub.
  ///
  /// In pt, this message translates to:
  /// **'Ativa · {xp} XP por resposta'**
  String cfgSurveyActiveSub(int xp);

  /// No description provided for @cfgSurveyInactiveSub.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisa mensal desativada'**
  String get cfgSurveyInactiveSub;

  /// No description provided for @cfgSurveyManageSub.
  ///
  /// In pt, this message translates to:
  /// **'Criar, ativar e acompanhar pesquisas'**
  String get cfgSurveyManageSub;

  /// No description provided for @cfgSurveyAllResponses.
  ///
  /// In pt, this message translates to:
  /// **'Ver todas as respostas'**
  String get cfgSurveyAllResponses;

  /// No description provided for @cfgSurveyAllResponsesSub.
  ///
  /// In pt, this message translates to:
  /// **'Avaliações e comentários dos alunos'**
  String get cfgSurveyAllResponsesSub;

  /// No description provided for @cfgSystemSection.
  ///
  /// In pt, this message translates to:
  /// **'Sistema e Legal'**
  String get cfgSystemSection;

  /// No description provided for @cfgSystemSub.
  ///
  /// In pt, this message translates to:
  /// **'Informações do sistema e documentos legais.'**
  String get cfgSystemSub;

  /// No description provided for @cfgSubdomain.
  ///
  /// In pt, this message translates to:
  /// **'Subdomínio'**
  String get cfgSubdomain;

  /// No description provided for @cfgPrivacy.
  ///
  /// In pt, this message translates to:
  /// **'Política de Privacidade'**
  String get cfgPrivacy;

  /// No description provided for @cfgPrivacySub.
  ///
  /// In pt, this message translates to:
  /// **'Como tratamos seus dados (LGPD)'**
  String get cfgPrivacySub;

  /// No description provided for @cfgTerms.
  ///
  /// In pt, this message translates to:
  /// **'Termos de Uso'**
  String get cfgTerms;

  /// No description provided for @cfgTermsSub.
  ///
  /// In pt, this message translates to:
  /// **'Condições de uso do Sensei Manager'**
  String get cfgTermsSub;

  /// No description provided for @cfgAccountSection.
  ///
  /// In pt, this message translates to:
  /// **'Conta'**
  String get cfgAccountSection;

  /// No description provided for @cfgDangerSection.
  ///
  /// In pt, this message translates to:
  /// **'Zona de Perigo'**
  String get cfgDangerSection;

  /// No description provided for @cfgSaveToggleError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar a alteração.'**
  String get cfgSaveToggleError;

  /// No description provided for @cfgInfoSaved.
  ///
  /// In pt, this message translates to:
  /// **'Informações salvas.'**
  String get cfgInfoSaved;

  /// No description provided for @cfgLogoSaved.
  ///
  /// In pt, this message translates to:
  /// **'Logo atualizada.'**
  String get cfgLogoSaved;

  /// No description provided for @cfgMsgSaved.
  ///
  /// In pt, this message translates to:
  /// **'Mensagem salva.'**
  String get cfgMsgSaved;

  /// No description provided for @cfgFeeSaved.
  ///
  /// In pt, this message translates to:
  /// **'Taxa de atraso salva.'**
  String get cfgFeeSaved;

  /// No description provided for @cfgGraceSaved.
  ///
  /// In pt, this message translates to:
  /// **'Carência atualizada.'**
  String get cfgGraceSaved;

  /// No description provided for @cfgSurveySaved.
  ///
  /// In pt, this message translates to:
  /// **'Configurações da pesquisa salvas.'**
  String get cfgSurveySaved;

  /// No description provided for @cfgSubdomainCopied.
  ///
  /// In pt, this message translates to:
  /// **'Subdomínio copiado.'**
  String get cfgSubdomainCopied;

  /// No description provided for @cfgLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar as configurações.'**
  String get cfgLoadError;

  /// No description provided for @cfgSaveError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar as alterações.'**
  String get cfgSaveError;

  /// No description provided for @cfgAcademyName.
  ///
  /// In pt, this message translates to:
  /// **'Nome da Academia'**
  String get cfgAcademyName;

  /// No description provided for @cfgEmail.
  ///
  /// In pt, this message translates to:
  /// **'E-mail'**
  String get cfgEmail;

  /// No description provided for @cfgPhone.
  ///
  /// In pt, this message translates to:
  /// **'Telefone'**
  String get cfgPhone;

  /// No description provided for @cfgCnpj.
  ///
  /// In pt, this message translates to:
  /// **'CNPJ'**
  String get cfgCnpj;

  /// No description provided for @cfgChangeImage.
  ///
  /// In pt, this message translates to:
  /// **'Trocar imagem'**
  String get cfgChangeImage;

  /// No description provided for @cfgChooseImage.
  ///
  /// In pt, this message translates to:
  /// **'Escolher imagem'**
  String get cfgChooseImage;

  /// No description provided for @cfgReturnMsgTitle.
  ///
  /// In pt, this message translates to:
  /// **'Mensagem de retorno'**
  String get cfgReturnMsgTitle;

  /// No description provided for @cfgReturnMsgDesc.
  ///
  /// In pt, this message translates to:
  /// **'Usada ao entrar em contato com alunos que estão há alguns dias sem treinar. Deixe em branco para usar a mensagem padrão do sistema.'**
  String get cfgReturnMsgDesc;

  /// No description provided for @cfgReturnMsgDefault.
  ///
  /// In pt, this message translates to:
  /// **'Oi {nome}! Sentimos sua falta — faz {dias} dias sem treino. Está tudo bem? Qualquer coisa a gente ajuda pra você voltar. 🥋'**
  String cfgReturnMsgDefault(String nome, String dias);

  /// No description provided for @cfgReturnMsgHint.
  ///
  /// In pt, this message translates to:
  /// **'Oi {nome}! Sentimos sua falta — faz {dias} dias sem treino...'**
  String cfgReturnMsgHint(String nome, String dias);

  /// No description provided for @cfgRestoreDefault.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar padrão'**
  String get cfgRestoreDefault;

  /// No description provided for @cfgSaveMsg.
  ///
  /// In pt, this message translates to:
  /// **'Salvar mensagem'**
  String get cfgSaveMsg;

  /// No description provided for @cfgLateFeeToggle.
  ///
  /// In pt, this message translates to:
  /// **'Cobrar taxa em cobranças vencidas'**
  String get cfgLateFeeToggle;

  /// No description provided for @cfgPercent.
  ///
  /// In pt, this message translates to:
  /// **'Percentual (%)'**
  String get cfgPercent;

  /// No description provided for @cfgFixedValue.
  ///
  /// In pt, this message translates to:
  /// **'Valor fixo (R\$)'**
  String get cfgFixedValue;

  /// No description provided for @cfgFeePercentDesc.
  ///
  /// In pt, this message translates to:
  /// **'Será adicionado {value}% às cobranças vencidas.'**
  String cfgFeePercentDesc(String value);

  /// No description provided for @cfgFeeFixedDesc.
  ///
  /// In pt, this message translates to:
  /// **'Será adicionado R\$ {value} às cobranças vencidas.'**
  String cfgFeeFixedDesc(String value);

  /// No description provided for @cfgFeePercentLabel.
  ///
  /// In pt, this message translates to:
  /// **'Percentual de atraso'**
  String get cfgFeePercentLabel;

  /// No description provided for @cfgFeeFixedLabel.
  ///
  /// In pt, this message translates to:
  /// **'Valor fixo de atraso'**
  String get cfgFeeFixedLabel;

  /// No description provided for @cfgGraceDaysDesc.
  ///
  /// In pt, this message translates to:
  /// **'O check-in do aluno é bloqueado somente após este número de dias do vencimento da mensalidade.'**
  String get cfgGraceDaysDesc;

  /// No description provided for @cfgSurveyEnable.
  ///
  /// In pt, this message translates to:
  /// **'Ativar pesquisa mensal'**
  String get cfgSurveyEnable;

  /// No description provided for @cfgSurveyEnableSub.
  ///
  /// In pt, this message translates to:
  /// **'Alunos serão convidados a avaliar a academia 1x/mês.'**
  String get cfgSurveyEnableSub;

  /// No description provided for @cfgSurveyXp.
  ///
  /// In pt, this message translates to:
  /// **'XP por resposta'**
  String get cfgSurveyXp;

  /// No description provided for @cfgSurveyXpSub.
  ///
  /// In pt, this message translates to:
  /// **'Pontos concedidos ao aluno após responder.'**
  String get cfgSurveyXpSub;

  /// No description provided for @cfgLogout.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get cfgLogout;

  /// No description provided for @cfgLogoutConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Deseja encerrar sua sessão?'**
  String get cfgLogoutConfirm;

  /// No description provided for @cfgLogoutBtn.
  ///
  /// In pt, this message translates to:
  /// **'Sair da conta'**
  String get cfgLogoutBtn;

  /// No description provided for @cfgDeleteAccountTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir conta?'**
  String get cfgDeleteAccountTitle;

  /// No description provided for @cfgDeleteAccountBody.
  ///
  /// In pt, this message translates to:
  /// **'Seus dados pessoais serão removidos permanentemente. Esta ação não pode ser desfeita.'**
  String get cfgDeleteAccountBody;

  /// No description provided for @cfgDeleteAccountError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao excluir conta. Tente novamente.'**
  String get cfgDeleteAccountError;

  /// No description provided for @cfgDeleteAccountBtn.
  ///
  /// In pt, this message translates to:
  /// **'Excluir minha conta'**
  String get cfgDeleteAccountBtn;

  /// No description provided for @cfgPlanActive.
  ///
  /// In pt, this message translates to:
  /// **'Plano Ativo'**
  String get cfgPlanActive;

  /// No description provided for @cfgPlanTrial.
  ///
  /// In pt, this message translates to:
  /// **'Trial'**
  String get cfgPlanTrial;

  /// No description provided for @cfgPlanFree.
  ///
  /// In pt, this message translates to:
  /// **'Gratuito'**
  String get cfgPlanFree;

  /// No description provided for @cfgPlanProDesc.
  ///
  /// In pt, this message translates to:
  /// **'Acesso completo sem anúncios'**
  String get cfgPlanProDesc;

  /// No description provided for @cfgPlanTrialLastDay.
  ///
  /// In pt, this message translates to:
  /// **'Último dia do trial!'**
  String get cfgPlanTrialLastDay;

  /// No description provided for @cfgPlanTrialDaysLeft.
  ///
  /// In pt, this message translates to:
  /// **'{days} dias restantes no trial'**
  String cfgPlanTrialDaysLeft(int days);

  /// No description provided for @cfgPlanFreeDesc.
  ///
  /// In pt, this message translates to:
  /// **'3 turmas · 10 alunos/turma · anúncios'**
  String get cfgPlanFreeDesc;

  /// No description provided for @fxStudentsCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{{count} aluno} other{{count} alunos}}'**
  String fxStudentsCount(int count);

  /// No description provided for @fxZeroNoMin.
  ///
  /// In pt, this message translates to:
  /// **'0 = sem exigência mínima.'**
  String get fxZeroNoMin;

  /// No description provided for @authEnterPassword.
  ///
  /// In pt, this message translates to:
  /// **'Informe sua senha.'**
  String get authEnterPassword;

  /// No description provided for @authErrUserNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Usuário não encontrado no sistema. Contate o administrador.'**
  String get authErrUserNotFound;

  /// No description provided for @authErrDbNotConfigured.
  ///
  /// In pt, this message translates to:
  /// **'Banco de dados ainda não configurado. Contate o administrador.'**
  String get authErrDbNotConfigured;

  /// No description provided for @authErrNoPermission.
  ///
  /// In pt, this message translates to:
  /// **'Sem permissão para acessar os dados. Contate o administrador.'**
  String get authErrNoPermission;

  /// No description provided for @authFirstTimeUsingApp.
  ///
  /// In pt, this message translates to:
  /// **'Acessando o app pela primeira vez'**
  String get authFirstTimeUsingApp;

  /// No description provided for @authErrFirebaseCode.
  ///
  /// In pt, this message translates to:
  /// **'Erro do Firebase ({code})'**
  String authErrFirebaseCode(String code);

  /// No description provided for @profMyProfile.
  ///
  /// In pt, this message translates to:
  /// **'Meu Perfil'**
  String get profMyProfile;

  /// No description provided for @profUpdated.
  ///
  /// In pt, this message translates to:
  /// **'Perfil atualizado!'**
  String get profUpdated;

  /// No description provided for @profYourNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Seu nome'**
  String get profYourNameHint;

  /// No description provided for @profChangePassword.
  ///
  /// In pt, this message translates to:
  /// **'Alterar senha'**
  String get profChangePassword;

  /// No description provided for @apPhotoSaveError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar foto.'**
  String get apPhotoSaveError;

  /// No description provided for @apPrimaryBelt.
  ///
  /// In pt, this message translates to:
  /// **'Faixa Principal'**
  String get apPrimaryBelt;

  /// No description provided for @apPrimaryBeltHint.
  ///
  /// In pt, this message translates to:
  /// **'Escolha qual graduação exibir no seu perfil'**
  String get apPrimaryBeltHint;

  /// No description provided for @apThanksFeedback.
  ///
  /// In pt, this message translates to:
  /// **'Obrigado pelo feedback!'**
  String get apThanksFeedback;

  /// No description provided for @apRatingRecorded.
  ///
  /// In pt, this message translates to:
  /// **'Sua avaliação foi registrada.'**
  String get apRatingRecorded;

  /// No description provided for @apSurveyQuestion.
  ///
  /// In pt, this message translates to:
  /// **'Como está sendo sua experiência?'**
  String get apSurveyQuestion;

  /// No description provided for @apTapToRate.
  ///
  /// In pt, this message translates to:
  /// **'Toque para avaliar'**
  String get apTapToRate;

  /// No description provided for @apCommentHint.
  ///
  /// In pt, this message translates to:
  /// **'Deixe um comentário (opcional)'**
  String get apCommentHint;

  /// No description provided for @apSurveySendError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao enviar resposta. Verifique sua conexão.'**
  String get apSurveySendError;

  /// No description provided for @apSendAndEarnXp.
  ///
  /// In pt, this message translates to:
  /// **'Enviar e ganhar +{xp} XP'**
  String apSendAndEarnXp(int xp);

  /// No description provided for @apSendRating.
  ///
  /// In pt, this message translates to:
  /// **'Enviar avaliação'**
  String get apSendRating;

  /// No description provided for @apEditProfile.
  ///
  /// In pt, this message translates to:
  /// **'Editar Perfil'**
  String get apEditProfile;

  /// No description provided for @apFullName.
  ///
  /// In pt, this message translates to:
  /// **'Nome completo'**
  String get apFullName;

  /// No description provided for @apCertPending.
  ///
  /// In pt, this message translates to:
  /// **'Atestado médico pendente'**
  String get apCertPending;

  /// No description provided for @apCertRejected.
  ///
  /// In pt, this message translates to:
  /// **'Atestado rejeitado — envie um novo'**
  String get apCertRejected;

  /// No description provided for @apCertExpired.
  ///
  /// In pt, this message translates to:
  /// **'Atestado expirado — envie um novo'**
  String get apCertExpired;

  /// No description provided for @apCertExpiringSoon.
  ///
  /// In pt, this message translates to:
  /// **'Atestado vencendo em breve'**
  String get apCertExpiringSoon;

  /// No description provided for @apLogoutTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sair da conta?'**
  String get apLogoutTitle;

  /// No description provided for @apLogoutBody.
  ///
  /// In pt, this message translates to:
  /// **'Você precisará entrar novamente para acessar o app.'**
  String get apLogoutBody;

  /// No description provided for @apQrAttendance.
  ///
  /// In pt, this message translates to:
  /// **'QR Presença'**
  String get apQrAttendance;

  /// No description provided for @apSwitchProfile.
  ///
  /// In pt, this message translates to:
  /// **'Trocar perfil'**
  String get apSwitchProfile;

  /// No description provided for @apSwitchShort.
  ///
  /// In pt, this message translates to:
  /// **'Trocar'**
  String get apSwitchShort;

  /// No description provided for @apOverdueCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, one{1 atrasada} other{{count} atrasadas}}'**
  String apOverdueCount(num count);

  /// No description provided for @apPendingCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, one{1 pendente} other{{count} pendentes}}'**
  String apPendingCount(num count);

  /// No description provided for @apTapToChoose.
  ///
  /// In pt, this message translates to:
  /// **'Toque para escolher'**
  String get apTapToChoose;

  /// No description provided for @apTuitionOverdue.
  ///
  /// In pt, this message translates to:
  /// **'Mensalidade em atraso'**
  String get apTuitionOverdue;

  /// No description provided for @apTuitionOverdueHint.
  ///
  /// In pt, this message translates to:
  /// **'Toque para ver detalhes e regularizar.'**
  String get apTuitionOverdueHint;

  /// No description provided for @apTapToResolve.
  ///
  /// In pt, this message translates to:
  /// **'Toque para resolver'**
  String get apTapToResolve;

  /// No description provided for @apRateYourExperience.
  ///
  /// In pt, this message translates to:
  /// **'Avalie sua experiência!'**
  String get apRateYourExperience;

  /// No description provided for @apEarnXpMonthlySurvey.
  ///
  /// In pt, this message translates to:
  /// **'Ganhe +{xp} XP respondendo a pesquisa do mês'**
  String apEarnXpMonthlySurvey(int xp);

  /// No description provided for @apMyClasses.
  ///
  /// In pt, this message translates to:
  /// **'Minhas turmas'**
  String get apMyClasses;

  /// No description provided for @apNoClasses.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma turma matriculada.'**
  String get apNoClasses;

  /// No description provided for @apAttendancesCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{{count} presença} other{{count} presenças}}'**
  String apAttendancesCount(int count);

  /// No description provided for @apEditData.
  ///
  /// In pt, this message translates to:
  /// **'Editar dados'**
  String get apEditData;

  /// No description provided for @apEditDataHint.
  ///
  /// In pt, this message translates to:
  /// **'Nome, contato e informações pessoais'**
  String get apEditDataHint;

  /// No description provided for @apResetPasswordHint.
  ///
  /// In pt, this message translates to:
  /// **'Trocar sua senha de acesso'**
  String get apResetPasswordHint;

  /// No description provided for @apParqDone.
  ///
  /// In pt, this message translates to:
  /// **'Questionário de saúde respondido'**
  String get apParqDone;

  /// No description provided for @apParqPending.
  ///
  /// In pt, this message translates to:
  /// **'Questionário de saúde pendente'**
  String get apParqPending;

  /// No description provided for @apLogoutHint.
  ///
  /// In pt, this message translates to:
  /// **'Encerrar a sessão neste dispositivo'**
  String get apLogoutHint;

  /// No description provided for @apLegal.
  ///
  /// In pt, this message translates to:
  /// **'Legal'**
  String get apLegal;

  /// No description provided for @apPrivacyHint.
  ///
  /// In pt, this message translates to:
  /// **'Como seus dados são tratados'**
  String get apPrivacyHint;

  /// No description provided for @apTermsHint.
  ///
  /// In pt, this message translates to:
  /// **'Regras e condições de uso do app'**
  String get apTermsHint;

  /// No description provided for @apDeleteAccountSection.
  ///
  /// In pt, this message translates to:
  /// **'Excluir conta'**
  String get apDeleteAccountSection;

  /// No description provided for @apDeleteAccountHint.
  ///
  /// In pt, this message translates to:
  /// **'Remove seus dados permanentemente'**
  String get apDeleteAccountHint;

  /// No description provided for @apXpAdded.
  ///
  /// In pt, this message translates to:
  /// **'+{xp} XP adicionados ao seu perfil.'**
  String apXpAdded(int xp);

  /// No description provided for @navLessons.
  ///
  /// In pt, this message translates to:
  /// **'Aulas'**
  String get navLessons;

  /// No description provided for @navPromotions.
  ///
  /// In pt, this message translates to:
  /// **'Graduações'**
  String get navPromotions;

  /// No description provided for @navProfile.
  ///
  /// In pt, this message translates to:
  /// **'Perfil'**
  String get navProfile;

  /// No description provided for @peseiTagline.
  ///
  /// In pt, this message translates to:
  /// **'Seu parceiro de saúde e bem-estar'**
  String get peseiTagline;

  /// No description provided for @peseiFreeBadge.
  ///
  /// In pt, this message translates to:
  /// **'Gratuito · iOS & Android'**
  String get peseiFreeBadge;

  /// No description provided for @peseiFeatWeightTitle.
  ///
  /// In pt, this message translates to:
  /// **'Controle de Peso'**
  String get peseiFeatWeightTitle;

  /// No description provided for @peseiFeatWeightSub.
  ///
  /// In pt, this message translates to:
  /// **'Acompanhe ganhos e perdas com gráficos e histórico'**
  String get peseiFeatWeightSub;

  /// No description provided for @peseiFeatWaterTitle.
  ///
  /// In pt, this message translates to:
  /// **'Hidratação Diária'**
  String get peseiFeatWaterTitle;

  /// No description provided for @peseiFeatWaterSub.
  ///
  /// In pt, this message translates to:
  /// **'Meta de consumo de água personalizada com alertas'**
  String get peseiFeatWaterSub;

  /// No description provided for @peseiFeatMedsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Medicamentos'**
  String get peseiFeatMedsTitle;

  /// No description provided for @peseiFeatMedsSub.
  ///
  /// In pt, this message translates to:
  /// **'Lembretes para não esquecer seus remédios e suplementos'**
  String get peseiFeatMedsSub;

  /// No description provided for @peseiFeatProgressTitle.
  ///
  /// In pt, this message translates to:
  /// **'Evolução Visual'**
  String get peseiFeatProgressTitle;

  /// No description provided for @peseiFeatProgressSub.
  ///
  /// In pt, this message translates to:
  /// **'Gráficos de progresso para manter o foco nos seus objetivos'**
  String get peseiFeatProgressSub;

  /// No description provided for @peseiDownloadFree.
  ///
  /// In pt, this message translates to:
  /// **'Baixar gratuitamente'**
  String get peseiDownloadFree;

  /// No description provided for @peseiFreeShort.
  ///
  /// In pt, this message translates to:
  /// **'GRÁTIS'**
  String get peseiFreeShort;

  /// No description provided for @peseiCardTagline.
  ///
  /// In pt, this message translates to:
  /// **'Controle de peso, água e saúde'**
  String get peseiCardTagline;

  /// No description provided for @peseiSeeApp.
  ///
  /// In pt, this message translates to:
  /// **'Ver app'**
  String get peseiSeeApp;

  /// No description provided for @commonTomorrow.
  ///
  /// In pt, this message translates to:
  /// **'Amanhã'**
  String get commonTomorrow;

  /// No description provided for @apClassFallback.
  ///
  /// In pt, this message translates to:
  /// **'Aula'**
  String get apClassFallback;

  /// No description provided for @apMyLessons.
  ///
  /// In pt, this message translates to:
  /// **'Minhas aulas'**
  String get apMyLessons;

  /// No description provided for @apMyAttendance.
  ///
  /// In pt, this message translates to:
  /// **'Minha frequência'**
  String get apMyAttendance;

  /// No description provided for @apMyPromotions.
  ///
  /// In pt, this message translates to:
  /// **'Minhas graduações'**
  String get apMyPromotions;

  /// No description provided for @apAttendanceQr.
  ///
  /// In pt, this message translates to:
  /// **'QR de presença'**
  String get apAttendanceQr;

  /// No description provided for @apNextClass.
  ///
  /// In pt, this message translates to:
  /// **'Próxima aula'**
  String get apNextClass;

  /// No description provided for @apCurrentGrad.
  ///
  /// In pt, this message translates to:
  /// **'Graduação atual'**
  String get apCurrentGrad;

  /// No description provided for @apJourneyStarts.
  ///
  /// In pt, this message translates to:
  /// **'Sua trajetória começa aqui.'**
  String get apJourneyStarts;

  /// No description provided for @apJourneyContinues.
  ///
  /// In pt, this message translates to:
  /// **'Sua jornada continua aqui.'**
  String get apJourneyContinues;

  /// No description provided for @apHello.
  ///
  /// In pt, this message translates to:
  /// **'Olá!'**
  String get apHello;

  /// No description provided for @apHelloName.
  ///
  /// In pt, this message translates to:
  /// **'Olá, {name}!'**
  String apHelloName(String name);

  /// No description provided for @apNotifications.
  ///
  /// In pt, this message translates to:
  /// **'Notificações'**
  String get apNotifications;

  /// No description provided for @apNoClassToday.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma aula programada para hoje.'**
  String get apNoClassToday;

  /// No description provided for @apProfPrefix.
  ///
  /// In pt, this message translates to:
  /// **'Prof. {name}'**
  String apProfPrefix(String name);

  /// No description provided for @apWeekAttendance.
  ///
  /// In pt, this message translates to:
  /// **'Frequência esta semana'**
  String get apWeekAttendance;

  /// No description provided for @apTuitionOk.
  ///
  /// In pt, this message translates to:
  /// **'Mensalidade em dia'**
  String get apTuitionOk;

  /// No description provided for @apTuitionOkSub.
  ///
  /// In pt, this message translates to:
  /// **'Sem pendências no momento.'**
  String get apTuitionOkSub;

  /// No description provided for @apTuitionPending.
  ///
  /// In pt, this message translates to:
  /// **'Mensalidade pendente'**
  String get apTuitionPending;

  /// No description provided for @apTuitionNeedsAttention.
  ///
  /// In pt, this message translates to:
  /// **'Há uma mensalidade que precisa de atenção.'**
  String get apTuitionNeedsAttention;

  /// No description provided for @apNoCharges.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma cobrança'**
  String get apNoCharges;

  /// No description provided for @apNoChargesSub.
  ///
  /// In pt, this message translates to:
  /// **'Nada em aberto por aqui.'**
  String get apNoChargesSub;

  /// No description provided for @apWorkoutsCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 treino} other{{count} treinos}}'**
  String apWorkoutsCount(int count);

  /// No description provided for @apAbsencesCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 falta} other{{count} faltas}}'**
  String apAbsencesCount(int count);

  /// No description provided for @apNoClassOnDay.
  ///
  /// In pt, this message translates to:
  /// **'Sem aulas nesse dia'**
  String get apNoClassOnDay;

  /// No description provided for @apMyLessonsUpper.
  ///
  /// In pt, this message translates to:
  /// **'MINHAS AULAS'**
  String get apMyLessonsUpper;

  /// No description provided for @apOtherLessonsUpper.
  ///
  /// In pt, this message translates to:
  /// **'OUTRAS AULAS'**
  String get apOtherLessonsUpper;

  /// No description provided for @apExamApproved.
  ///
  /// In pt, this message translates to:
  /// **'Aprovado'**
  String get apExamApproved;

  /// No description provided for @apExamFailed.
  ///
  /// In pt, this message translates to:
  /// **'Reprovado'**
  String get apExamFailed;

  /// No description provided for @apPromotionHistory.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de Graduações'**
  String get apPromotionHistory;

  /// No description provided for @apCurrentBeltsUpper.
  ///
  /// In pt, this message translates to:
  /// **'FAIXAS ATUAIS'**
  String get apCurrentBeltsUpper;

  /// No description provided for @apHistoryUpper.
  ///
  /// In pt, this message translates to:
  /// **'HISTÓRICO'**
  String get apHistoryUpper;

  /// No description provided for @apNoPromotions.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma graduação registrada'**
  String get apNoPromotions;

  /// No description provided for @apNoPromotionsSub.
  ///
  /// In pt, this message translates to:
  /// **'Seu histórico de faixas aparecerá aqui.'**
  String get apNoPromotionsSub;

  /// No description provided for @apChargeFallback.
  ///
  /// In pt, this message translates to:
  /// **'Cobrança'**
  String get apChargeFallback;

  /// No description provided for @apOutstanding.
  ///
  /// In pt, this message translates to:
  /// **'Em aberto'**
  String get apOutstanding;

  /// No description provided for @apAllPaid.
  ///
  /// In pt, this message translates to:
  /// **'Em dia!'**
  String get apAllPaid;

  /// No description provided for @apAmountToSettle.
  ///
  /// In pt, this message translates to:
  /// **'{value} a regularizar'**
  String apAmountToSettle(String value);

  /// No description provided for @apNoPendingNow.
  ///
  /// In pt, this message translates to:
  /// **'Sem pendências no momento'**
  String get apNoPendingNow;

  /// No description provided for @apChargesUpper.
  ///
  /// In pt, this message translates to:
  /// **'COBRANÇAS'**
  String get apChargesUpper;

  /// No description provided for @apDueDatePrefix.
  ///
  /// In pt, this message translates to:
  /// **'Vencimento: {date}'**
  String apDueDatePrefix(String date);

  /// No description provided for @apContactSecretary.
  ///
  /// In pt, this message translates to:
  /// **'Entre em contato com a secretaria para regularizar.'**
  String get apContactSecretary;

  /// No description provided for @apNoChargesInCategory.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma cobrança nessa categoria'**
  String get apNoChargesInCategory;

  /// No description provided for @apNoChargesThisMonth.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma cobrança em {month}'**
  String apNoChargesThisMonth(String month);

  /// No description provided for @apTotalOpenAllMonths.
  ///
  /// In pt, this message translates to:
  /// **'{amount} em aberto no total'**
  String apTotalOpenAllMonths(String amount);

  /// No description provided for @apViewAllOverdue.
  ///
  /// In pt, this message translates to:
  /// **'Ver todas as atrasadas'**
  String get apViewAllOverdue;

  /// No description provided for @apAllOverdueTitle.
  ///
  /// In pt, this message translates to:
  /// **'Mensalidades atrasadas'**
  String get apAllOverdueTitle;

  /// No description provided for @apPrevMonth.
  ///
  /// In pt, this message translates to:
  /// **'Mês anterior'**
  String get apPrevMonth;

  /// No description provided for @apNextMonth.
  ///
  /// In pt, this message translates to:
  /// **'Próximo mês'**
  String get apNextMonth;

  /// No description provided for @apAttendanceTitle.
  ///
  /// In pt, this message translates to:
  /// **'Presenças'**
  String get apAttendanceTitle;

  /// No description provided for @apTrainingHistory.
  ///
  /// In pt, this message translates to:
  /// **'Seu histórico de treinos'**
  String get apTrainingHistory;

  /// No description provided for @apTotalWorkouts.
  ///
  /// In pt, this message translates to:
  /// **'Total de treinos'**
  String get apTotalWorkouts;

  /// No description provided for @apAttendanceLabel.
  ///
  /// In pt, this message translates to:
  /// **'Presenças'**
  String get apAttendanceLabel;

  /// No description provided for @apAbsencesLabel.
  ///
  /// In pt, this message translates to:
  /// **'Faltas'**
  String get apAbsencesLabel;

  /// No description provided for @apNoAbsences.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma falta registrada. Mandou bem!'**
  String get apNoAbsences;

  /// No description provided for @apNoAttendanceYet.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma presença registrada ainda'**
  String get apNoAttendanceYet;

  /// No description provided for @apNothingHereYet.
  ///
  /// In pt, this message translates to:
  /// **'Nada por aqui ainda'**
  String get apNothingHereYet;

  /// No description provided for @apAbsence.
  ///
  /// In pt, this message translates to:
  /// **'Falta'**
  String get apAbsence;

  /// No description provided for @apPresent.
  ///
  /// In pt, this message translates to:
  /// **'Presente'**
  String get apPresent;

  /// No description provided for @apCertTitle.
  ///
  /// In pt, this message translates to:
  /// **'Atestado Médico'**
  String get apCertTitle;

  /// No description provided for @apCertNoneSent.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum atestado enviado'**
  String get apCertNoneSent;

  /// No description provided for @apCertSendHint.
  ///
  /// In pt, this message translates to:
  /// **'Envie seu atestado médico para que a academia possa verificar.'**
  String get apCertSendHint;

  /// No description provided for @apCertValidUntil.
  ///
  /// In pt, this message translates to:
  /// **'Válido até: {date}'**
  String apCertValidUntil(String date);

  /// No description provided for @apCertReasonPrefix.
  ///
  /// In pt, this message translates to:
  /// **'Motivo: {reason}'**
  String apCertReasonPrefix(String reason);

  /// No description provided for @apCertExpiringSoonSendNew.
  ///
  /// In pt, this message translates to:
  /// **'Vencendo em breve! Envie um novo.'**
  String get apCertExpiringSoonSendNew;

  /// No description provided for @apCertSendNew.
  ///
  /// In pt, this message translates to:
  /// **'Enviar novo atestado'**
  String get apCertSendNew;

  /// No description provided for @apCertSend.
  ///
  /// In pt, this message translates to:
  /// **'Enviar atestado'**
  String get apCertSend;

  /// No description provided for @apCertSentToast.
  ///
  /// In pt, this message translates to:
  /// **'Atestado enviado! Aguarde a aprovação da academia.'**
  String get apCertSentToast;

  /// No description provided for @apCertSendError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao enviar. Tente novamente.'**
  String get apCertSendError;

  /// No description provided for @apNotAuthenticated.
  ///
  /// In pt, this message translates to:
  /// **'Usuário não autenticado.'**
  String get apNotAuthenticated;

  /// No description provided for @apParqInstruction.
  ///
  /// In pt, this message translates to:
  /// **'Questionário de Prontidão para Atividade Física. Por favor responda \"Sim\" ou \"Não\" às perguntas abaixo.'**
  String get apParqInstruction;

  /// No description provided for @apParqFullNameReq.
  ///
  /// In pt, this message translates to:
  /// **'Nome completo *'**
  String get apParqFullNameReq;

  /// No description provided for @apParqSignSend.
  ///
  /// In pt, this message translates to:
  /// **'Assinar e enviar PAR-Q'**
  String get apParqSignSend;

  /// No description provided for @apAchievements.
  ///
  /// In pt, this message translates to:
  /// **'Conquistas'**
  String get apAchievements;

  /// No description provided for @apNoAchievements.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma conquista ainda.'**
  String get apNoAchievements;

  /// No description provided for @apLevel.
  ///
  /// In pt, this message translates to:
  /// **'Nível'**
  String get apLevel;

  /// No description provided for @apStreak.
  ///
  /// In pt, this message translates to:
  /// **'Sequência'**
  String get apStreak;

  /// No description provided for @apThisMonthXp.
  ///
  /// In pt, this message translates to:
  /// **'Este mês: {xp} XP'**
  String apThisMonthXp(int xp);

  /// No description provided for @apNextLevelXp.
  ///
  /// In pt, this message translates to:
  /// **'Próx. nível: {xp} XP'**
  String apNextLevelXp(int xp);

  /// No description provided for @apMyProfile.
  ///
  /// In pt, this message translates to:
  /// **'Meu Perfil'**
  String get apMyProfile;

  /// No description provided for @apRankNoPeriodData.
  ///
  /// In pt, this message translates to:
  /// **'Sem dados para este período'**
  String get apRankNoPeriodData;

  /// No description provided for @apRankTrainMore.
  ///
  /// In pt, this message translates to:
  /// **'Treine mais para aparecer no ranking!'**
  String get apRankTrainMore;

  /// No description provided for @apRankingsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Rankings'**
  String get apRankingsTitle;

  /// No description provided for @apQrMyCode.
  ///
  /// In pt, this message translates to:
  /// **'Meu QR Code'**
  String get apQrMyCode;

  /// No description provided for @apQrScanAcademy.
  ///
  /// In pt, this message translates to:
  /// **'Escanear Academia'**
  String get apQrScanAcademy;

  /// No description provided for @apQrShowInstructor.
  ///
  /// In pt, this message translates to:
  /// **'Apresente ao professor na entrada'**
  String get apQrShowInstructor;

  /// No description provided for @apQrGenFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível gerar o QR Code'**
  String get apQrGenFailed;

  /// No description provided for @apQrShowInstructorLong.
  ///
  /// In pt, this message translates to:
  /// **'Apresente este QR Code ao professor para registrar sua presença.'**
  String get apQrShowInstructorLong;

  /// No description provided for @apQrCheckinSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Presença registrada com sucesso!'**
  String get apQrCheckinSuccess;

  /// No description provided for @apQrCheckinError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao registrar presença.'**
  String get apQrCheckinError;

  /// No description provided for @apQrCheckingIn.
  ///
  /// In pt, this message translates to:
  /// **'Registrando presença...'**
  String get apQrCheckingIn;

  /// No description provided for @apQrScanAgain.
  ///
  /// In pt, this message translates to:
  /// **'Escanear novamente'**
  String get apQrScanAgain;

  /// No description provided for @apQrPointAtAcademy.
  ///
  /// In pt, this message translates to:
  /// **'Aponte para o QR Code da academia na entrada'**
  String get apQrPointAtAcademy;

  /// No description provided for @apYourBeltHistory.
  ///
  /// In pt, this message translates to:
  /// **'Seu histórico de faixas'**
  String get apYourBeltHistory;

  /// No description provided for @navSchedule.
  ///
  /// In pt, this message translates to:
  /// **'Horários'**
  String get navSchedule;

  /// No description provided for @profNewsAcademy.
  ///
  /// In pt, this message translates to:
  /// **'Notícias da Academia'**
  String get profNewsAcademy;

  /// No description provided for @profAreaTitle.
  ///
  /// In pt, this message translates to:
  /// **'Área do Professor'**
  String get profAreaTitle;

  /// No description provided for @profPanelSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Painel do professor'**
  String get profPanelSubtitle;

  /// No description provided for @profQuickAccess.
  ///
  /// In pt, this message translates to:
  /// **'Acessos rápidos'**
  String get profQuickAccess;

  /// No description provided for @profTodayClasses.
  ///
  /// In pt, this message translates to:
  /// **'Aulas de hoje'**
  String get profTodayClasses;

  /// No description provided for @profNoClassToday.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma aula hoje.'**
  String get profNoClassToday;

  /// No description provided for @profSeeMyClasses.
  ///
  /// In pt, this message translates to:
  /// **'Ver minhas turmas'**
  String get profSeeMyClasses;

  /// No description provided for @profAlsoTrainsIn.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{Você também treina em 1 turma} other{Você também treina em {count} turmas}}'**
  String profAlsoTrainsIn(int count);

  /// No description provided for @profMySchedule.
  ///
  /// In pt, this message translates to:
  /// **'Meus Horários'**
  String get profMySchedule;

  /// No description provided for @profNoScheduleFound.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum horário encontrado.'**
  String get profNoScheduleFound;

  /// No description provided for @profMyClasses.
  ///
  /// In pt, this message translates to:
  /// **'Minhas Turmas'**
  String get profMyClasses;

  /// No description provided for @profNoClassesAssigned.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma turma atribuída'**
  String get profNoClassesAssigned;

  /// No description provided for @profNoStudentsEnrolled.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum aluno matriculado'**
  String get profNoStudentsEnrolled;

  /// No description provided for @profPromotionRecorded.
  ///
  /// In pt, this message translates to:
  /// **'Graduação registrada!'**
  String get profPromotionRecorded;

  /// No description provided for @profPromotion.
  ///
  /// In pt, this message translates to:
  /// **'Graduação'**
  String get profPromotion;

  /// No description provided for @profAttendanceError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao registrar.'**
  String get profAttendanceError;

  /// No description provided for @profRemoveAttendance.
  ///
  /// In pt, this message translates to:
  /// **'Remover presença'**
  String get profRemoveAttendance;

  /// No description provided for @profRemoveAttendanceBody.
  ///
  /// In pt, this message translates to:
  /// **'Deseja remover a presença de {name} em {date}?'**
  String profRemoveAttendanceBody(String name, String date);

  /// No description provided for @profScanQr.
  ///
  /// In pt, this message translates to:
  /// **'Escanear QR Code'**
  String get profScanQr;

  /// No description provided for @profMarkWhoPresent.
  ///
  /// In pt, this message translates to:
  /// **'Marque quem esteve presente'**
  String get profMarkWhoPresent;

  /// No description provided for @profAttendanceMarkedTapRemove.
  ///
  /// In pt, this message translates to:
  /// **'Presença registrada · toque para remover'**
  String get profAttendanceMarkedTapRemove;

  /// No description provided for @profRegisterNAttendance.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{Registrar 1 presença} other{Registrar {count} presenças}}'**
  String profRegisterNAttendance(int count);

  /// No description provided for @profManual.
  ///
  /// In pt, this message translates to:
  /// **'Manual'**
  String get profManual;

  /// No description provided for @profRemoveAttendanceThisClass.
  ///
  /// In pt, this message translates to:
  /// **'Deseja remover a presença de {name} nesta aula?'**
  String profRemoveAttendanceThisClass(String name);

  /// No description provided for @profChange.
  ///
  /// In pt, this message translates to:
  /// **'Alterar'**
  String get profChange;

  /// No description provided for @profNoAttendanceThisClass.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma presença nesta aula'**
  String get profNoAttendanceThisClass;

  /// No description provided for @profTapChangeDate.
  ///
  /// In pt, this message translates to:
  /// **'Toque em \"Alterar\" para mudar a data'**
  String get profTapChangeDate;

  /// No description provided for @profAbsentPending.
  ///
  /// In pt, this message translates to:
  /// **'Pendente'**
  String get profAbsentPending;

  /// No description provided for @rkStudentsAppearHere.
  ///
  /// In pt, this message translates to:
  /// **'Alunos aparecem aqui conforme registram presenças.'**
  String get rkStudentsAppearHere;

  /// No description provided for @commonCantOpenWhatsapp.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir o WhatsApp.'**
  String get commonCantOpenWhatsapp;

  /// No description provided for @evasaoRiskTitle.
  ///
  /// In pt, this message translates to:
  /// **'Risco de evasão'**
  String get evasaoRiskTitle;

  /// No description provided for @evasaoNobodyAtRisk.
  ///
  /// In pt, this message translates to:
  /// **'Ninguém em risco de evasão agora. 🎉'**
  String get evasaoNobodyAtRisk;

  /// No description provided for @evasaoCallWhatsapp.
  ///
  /// In pt, this message translates to:
  /// **'Chamar no WhatsApp'**
  String get evasaoCallWhatsapp;

  /// No description provided for @evasaoDefaultMsg.
  ///
  /// In pt, this message translates to:
  /// **'Oi {nome}! Sentimos sua falta nos treinos — faz {dias} dias que você não aparece. Está tudo bem? Qualquer coisa que a gente possa fazer pra te ajudar a voltar, é só falar. 🥋'**
  String evasaoDefaultMsg(String nome, String dias);

  /// No description provided for @birthdaysTitle.
  ///
  /// In pt, this message translates to:
  /// **'Aniversariantes'**
  String get birthdaysTitle;

  /// No description provided for @birthdaysCurrentMonth.
  ///
  /// In pt, this message translates to:
  /// **'Mês atual'**
  String get birthdaysCurrentMonth;

  /// No description provided for @birthdaysNoneInMonth.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum aniversariante em {month}'**
  String birthdaysNoneInMonth(String month);

  /// No description provided for @stfEditMember.
  ///
  /// In pt, this message translates to:
  /// **'Editar membro'**
  String get stfEditMember;

  /// No description provided for @stfRoleOptional.
  ///
  /// In pt, this message translates to:
  /// **'Cargo (opcional)'**
  String get stfRoleOptional;

  /// No description provided for @stfProfile.
  ///
  /// In pt, this message translates to:
  /// **'Perfil'**
  String get stfProfile;

  /// No description provided for @stfScreens.
  ///
  /// In pt, this message translates to:
  /// **'Telas'**
  String get stfScreens;

  /// No description provided for @stfActions.
  ///
  /// In pt, this message translates to:
  /// **'Ações'**
  String get stfActions;

  /// No description provided for @stfAdvancedAccess.
  ///
  /// In pt, this message translates to:
  /// **'Acesso avançado'**
  String get stfAdvancedAccess;

  /// No description provided for @stfMemberUpdated.
  ///
  /// In pt, this message translates to:
  /// **'Membro atualizado!'**
  String get stfMemberUpdated;

  /// No description provided for @stfUpdateError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao atualizar.'**
  String get stfUpdateError;

  /// No description provided for @stfRemoveFromTeam.
  ///
  /// In pt, this message translates to:
  /// **'Remover da equipe'**
  String get stfRemoveFromTeam;

  /// No description provided for @stfRemoveConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Remover {name} da equipe?'**
  String stfRemoveConfirm(String name);

  /// No description provided for @stfMemberRemoved.
  ///
  /// In pt, this message translates to:
  /// **'Funcionário removido.'**
  String get stfMemberRemoved;

  /// No description provided for @stfRemoveError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível remover.'**
  String get stfRemoveError;

  /// No description provided for @stfEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum funcionário cadastrado.'**
  String get stfEmpty;

  /// No description provided for @stfLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar equipe.'**
  String get stfLoadError;

  /// No description provided for @stfActiveAccessWarning.
  ///
  /// In pt, this message translates to:
  /// **'Este membro já tem acesso ativo ao app. Alterar e-mail/telefone aqui NÃO muda a senha nem o login dele. Use \"Redefinir senha\" se for necessário.'**
  String get stfActiveAccessWarning;

  /// No description provided for @stfCreateError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao cadastrar funcionário.'**
  String get stfCreateError;

  /// No description provided for @stfLinkProfiles.
  ///
  /// In pt, this message translates to:
  /// **'Vincular perfis?'**
  String get stfLinkProfiles;

  /// No description provided for @stfPhoneBelongsTo.
  ///
  /// In pt, this message translates to:
  /// **'Esse telefone já pertence a:'**
  String get stfPhoneBelongsTo;

  /// No description provided for @stfLinkStaffQuestion.
  ///
  /// In pt, this message translates to:
  /// **'Deseja vincular esse cadastro de funcionário ao mesmo contato? A pessoa poderá trocar entre os dois perfis dentro do app, pelo menu lateral.'**
  String get stfLinkStaffQuestion;

  /// No description provided for @stfLinkAlso.
  ///
  /// In pt, this message translates to:
  /// **'Vincular também'**
  String get stfLinkAlso;

  /// No description provided for @stfNewStaff.
  ///
  /// In pt, this message translates to:
  /// **'Novo Funcionário'**
  String get stfNewStaff;

  /// No description provided for @stfPersonalData.
  ///
  /// In pt, this message translates to:
  /// **'Dados pessoais'**
  String get stfPersonalData;

  /// No description provided for @stfFullNameReq.
  ///
  /// In pt, this message translates to:
  /// **'Nome completo *'**
  String get stfFullNameReq;

  /// No description provided for @stfPhoneReq.
  ///
  /// In pt, this message translates to:
  /// **'Telefone *'**
  String get stfPhoneReq;

  /// No description provided for @stfTempPasswordNote.
  ///
  /// In pt, this message translates to:
  /// **'Ao cadastrar, geramos uma senha temporária para você repassar. A pessoa entra com o telefone ou e-mail + essa senha e o app pede para criar a senha definitiva — sem \"primeiro acesso\".'**
  String get stfTempPasswordNote;

  /// No description provided for @stfRoleAndProfile.
  ///
  /// In pt, this message translates to:
  /// **'Cargo e perfil'**
  String get stfRoleAndProfile;

  /// No description provided for @stfRoleExample.
  ///
  /// In pt, this message translates to:
  /// **'Cargo (ex: Professor de BJJ)'**
  String get stfRoleExample;

  /// No description provided for @stfPermissions.
  ///
  /// In pt, this message translates to:
  /// **'Permissões'**
  String get stfPermissions;

  /// No description provided for @stfPermissionsHint.
  ///
  /// In pt, this message translates to:
  /// **'Defina o que esse funcionário pode acessar e fazer no aplicativo.'**
  String get stfPermissionsHint;

  /// No description provided for @stfCreateStaff.
  ///
  /// In pt, this message translates to:
  /// **'Cadastrar funcionário'**
  String get stfCreateStaff;

  /// No description provided for @stfVisibleScreens.
  ///
  /// In pt, this message translates to:
  /// **'Telas visíveis'**
  String get stfVisibleScreens;

  /// No description provided for @stfAllowedActions.
  ///
  /// In pt, this message translates to:
  /// **'Ações permitidas'**
  String get stfAllowedActions;

  /// No description provided for @stfRequiredField.
  ///
  /// In pt, this message translates to:
  /// **'Campo obrigatório'**
  String get stfRequiredField;

  /// No description provided for @famLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar grupos.'**
  String get famLoadError;

  /// No description provided for @famNewGroup.
  ///
  /// In pt, this message translates to:
  /// **'Novo Grupo Familiar'**
  String get famNewGroup;

  /// No description provided for @famGroupNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Nome do grupo (ex: Família Silva)'**
  String get famGroupNameHint;

  /// No description provided for @famCreate.
  ///
  /// In pt, this message translates to:
  /// **'Criar'**
  String get famCreate;

  /// No description provided for @famCreateError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao criar grupo.'**
  String get famCreateError;

  /// No description provided for @famRename.
  ///
  /// In pt, this message translates to:
  /// **'Renomear Grupo'**
  String get famRename;

  /// No description provided for @famRenameError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao renomear.'**
  String get famRenameError;

  /// No description provided for @famDeleteTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir grupo?'**
  String get famDeleteTitle;

  /// No description provided for @famDeleteBody.
  ///
  /// In pt, this message translates to:
  /// **'Os membros serão desvinculados mas não excluídos.'**
  String get famDeleteBody;

  /// No description provided for @famDeleteError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao excluir.'**
  String get famDeleteError;

  /// No description provided for @famRemoveMemberError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao remover membro.'**
  String get famRemoveMemberError;

  /// No description provided for @famTitle.
  ///
  /// In pt, this message translates to:
  /// **'Grupos Familiares'**
  String get famTitle;

  /// No description provided for @famNewGroupShort.
  ///
  /// In pt, this message translates to:
  /// **'Novo grupo'**
  String get famNewGroupShort;

  /// No description provided for @famEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum grupo familiar criado.'**
  String get famEmpty;

  /// No description provided for @famEmptyHint.
  ///
  /// In pt, this message translates to:
  /// **'Crie grupos para vincular membros da mesma família.'**
  String get famEmptyHint;

  /// No description provided for @famCreateGroup.
  ///
  /// In pt, this message translates to:
  /// **'Criar grupo'**
  String get famCreateGroup;

  /// No description provided for @famRenameShort.
  ///
  /// In pt, this message translates to:
  /// **'Renomear'**
  String get famRenameShort;

  /// No description provided for @famRemoveFromGroup.
  ///
  /// In pt, this message translates to:
  /// **'Remover do grupo'**
  String get famRemoveFromGroup;

  /// No description provided for @famNoMembers.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum membro. Adicione via detalhes do aluno.'**
  String get famNoMembers;

  /// No description provided for @acCreateError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao cadastrar aluno. Verifique os dados.'**
  String get acCreateError;

  /// No description provided for @acCreateAnywayBody.
  ///
  /// In pt, this message translates to:
  /// **'Deseja cadastrar mesmo assim?\nAo fazer o primeiro acesso com esse contato, o aluno poderá escolher entre os perfis (grupo familiar).'**
  String get acCreateAnywayBody;

  /// No description provided for @acCreateAnyway.
  ///
  /// In pt, this message translates to:
  /// **'Cadastrar mesmo assim'**
  String get acCreateAnyway;

  /// No description provided for @acLinkStudentQuestion.
  ///
  /// In pt, this message translates to:
  /// **'Deseja vincular esse cadastro de Aluno ao mesmo contato? A pessoa poderá trocar entre os perfis dentro do app.'**
  String get acLinkStudentQuestion;

  /// No description provided for @acNewStudent.
  ///
  /// In pt, this message translates to:
  /// **'Novo Aluno'**
  String get acNewStudent;

  /// No description provided for @acFullNameReq.
  ///
  /// In pt, this message translates to:
  /// **'Nome completo *'**
  String get acFullNameReq;

  /// No description provided for @acBirthDate.
  ///
  /// In pt, this message translates to:
  /// **'Data de nascimento'**
  String get acBirthDate;

  /// No description provided for @acMinor.
  ///
  /// In pt, this message translates to:
  /// **'Menor de idade'**
  String get acMinor;

  /// No description provided for @acGuardianName.
  ///
  /// In pt, this message translates to:
  /// **'Nome do responsável'**
  String get acGuardianName;

  /// No description provided for @acGuardianPhone.
  ///
  /// In pt, this message translates to:
  /// **'Telefone do responsável'**
  String get acGuardianPhone;

  /// No description provided for @acSelectPlanOptional.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar plano (opcional)'**
  String get acSelectPlanOptional;

  /// No description provided for @acAppAccessNote.
  ///
  /// In pt, this message translates to:
  /// **'Ao cadastrar (com acesso liberado e telefone ou e-mail), geramos uma senha temporária para você repassar ao aluno. Ele entra digitando o telefone ou e-mail cadastrado + essa senha, e o app pede para criar a senha definitiva. Não é necessário \"primeiro acesso\".'**
  String get acAppAccessNote;

  /// No description provided for @acAccessAllowed.
  ///
  /// In pt, this message translates to:
  /// **'Acesso ao app liberado'**
  String get acAccessAllowed;

  /// No description provided for @acAccessBlocked.
  ///
  /// In pt, this message translates to:
  /// **'Acesso ao app bloqueado'**
  String get acAccessBlocked;

  /// No description provided for @acCanLogin.
  ///
  /// In pt, this message translates to:
  /// **'Aluno poderá fazer login normalmente'**
  String get acCanLogin;

  /// No description provided for @acCannotLogin.
  ///
  /// In pt, this message translates to:
  /// **'Aluno não conseguirá entrar no app'**
  String get acCannotLogin;

  /// No description provided for @acCreateStudent.
  ///
  /// In pt, this message translates to:
  /// **'Cadastrar aluno'**
  String get acCreateStudent;

  /// No description provided for @acRequiredField.
  ///
  /// In pt, this message translates to:
  /// **'Campo obrigatório'**
  String get acRequiredField;

  /// No description provided for @rnBadgeVersion.
  ///
  /// In pt, this message translates to:
  /// **'VERSÃO {version}'**
  String rnBadgeVersion(String version);

  /// No description provided for @rnTitle.
  ///
  /// In pt, this message translates to:
  /// **'Novidades do Sensei Manager!'**
  String get rnTitle;

  /// No description provided for @rnSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Confira o que chegou nesta versão.'**
  String get rnSubtitle;

  /// No description provided for @rnCta.
  ///
  /// In pt, this message translates to:
  /// **'Entendi'**
  String get rnCta;

  /// No description provided for @rnClose.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get rnClose;

  /// No description provided for @rnA11yTitle.
  ///
  /// In pt, this message translates to:
  /// **'Novidades da versão {version}'**
  String rnA11yTitle(String version);

  /// No description provided for @rnTagNew.
  ///
  /// In pt, this message translates to:
  /// **'NOVO'**
  String get rnTagNew;

  /// No description provided for @rnTagImprovement.
  ///
  /// In pt, this message translates to:
  /// **'MELHORIA'**
  String get rnTagImprovement;

  /// No description provided for @rnTagFix.
  ///
  /// In pt, this message translates to:
  /// **'CORREÇÃO'**
  String get rnTagFix;

  /// No description provided for @rnFooterTitle.
  ///
  /// In pt, this message translates to:
  /// **'Estamos sempre evoluindo!'**
  String get rnFooterTitle;

  /// No description provided for @rnFooterBody.
  ///
  /// In pt, this message translates to:
  /// **'Obrigado por ajudar o Sensei Manager a ficar cada vez melhor.'**
  String get rnFooterBody;

  /// No description provided for @rnMenuEntry.
  ///
  /// In pt, this message translates to:
  /// **'Novidades da versão'**
  String get rnMenuEntry;

  /// No description provided for @rnNewsCardHint.
  ///
  /// In pt, this message translates to:
  /// **'Toque para rever o que mudou nesta versão.'**
  String get rnNewsCardHint;

  /// No description provided for @rnLightThemeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Agora também em tema claro'**
  String get rnLightThemeTitle;

  /// No description provided for @rnLightThemeDesc.
  ///
  /// In pt, this message translates to:
  /// **'Escolha entre tema claro, escuro ou seguir automaticamente o tema do seu dispositivo.'**
  String get rnLightThemeDesc;

  /// No description provided for @rnLanguageTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sensei Manager agora também em inglês'**
  String get rnLanguageTitle;

  /// No description provided for @rnLanguageDesc.
  ///
  /// In pt, this message translates to:
  /// **'Escolha entre Português e English nas preferências do aplicativo.'**
  String get rnLanguageDesc;

  /// No description provided for @rnRedesignStudentTitle.
  ///
  /// In pt, this message translates to:
  /// **'Interface repaginada'**
  String get rnRedesignStudentTitle;

  /// No description provided for @rnRedesignStudentDesc.
  ///
  /// In pt, this message translates to:
  /// **'Início, aulas, graduações e financeiro foram redesenhados para ficar mais claros e fáceis de navegar.'**
  String get rnRedesignStudentDesc;

  /// No description provided for @rnRedesignAcademyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Interface repaginada'**
  String get rnRedesignAcademyTitle;

  /// No description provided for @rnRedesignAcademyDesc.
  ///
  /// In pt, this message translates to:
  /// **'Dashboard, turmas, configurações, faixas e relatórios foram redesenhados para facilitar a navegação e destacar o que importa.'**
  String get rnRedesignAcademyDesc;

  /// No description provided for @rnSignInTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nova experiência de entrada'**
  String get rnSignInTitle;

  /// No description provided for @rnSignInDesc.
  ///
  /// In pt, this message translates to:
  /// **'Você escolhe se é aluno/responsável ou academia antes de entrar, com primeiro acesso e recuperação de senha mais claros.'**
  String get rnSignInDesc;

  /// No description provided for @rnPasswordTitle.
  ///
  /// In pt, this message translates to:
  /// **'Redefinição de senha pelo app'**
  String get rnPasswordTitle;

  /// No description provided for @rnPasswordDesc.
  ///
  /// In pt, this message translates to:
  /// **'Gestores autorizados geram uma senha temporária para alunos e funcionários, com troca obrigatória no próximo acesso.'**
  String get rnPasswordDesc;

  /// No description provided for @rnClassesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Turmas e graduações'**
  String get rnClassesTitle;

  /// No description provided for @rnClassesDesc.
  ///
  /// In pt, this message translates to:
  /// **'Graduações lançadas por engano podem ser corrigidas sem refazer o histórico, e excluir uma turma não apaga mais alunos, presenças ou registros.'**
  String get rnClassesDesc;

  /// No description provided for @rnBillingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Financeiro automático'**
  String get rnBillingTitle;

  /// No description provided for @rnBillingDesc.
  ///
  /// In pt, this message translates to:
  /// **'As mensalidades do mês aparecem sozinhas, dá para receber pagamentos antecipados e o relatório anual foi renovado.'**
  String get rnBillingDesc;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
