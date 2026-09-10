// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTagline => 'Gestão inteligente para academia de lutas';

  @override
  String get commonSave => 'Salvar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonDelete => 'Excluir';

  @override
  String get commonRemove => 'Remover';

  @override
  String get commonEdit => 'Editar';

  @override
  String get commonBack => 'Voltar';

  @override
  String get commonNext => 'Avançar';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonConfirm => 'Confirmar';

  @override
  String get commonClose => 'Fechar';

  @override
  String get commonRetry => 'Tentar novamente';

  @override
  String get commonUnderstood => 'Entendi';

  @override
  String get commonRequiredField => 'Obrigatório';

  @override
  String get commonLoading => 'Carregando...';

  @override
  String get commonGenericError => 'Algo deu errado. Tente novamente.';

  @override
  String get commonNoConnection => 'Sem conexão com a internet.';

  @override
  String commonMinChars(int count) {
    return 'Mínimo $count caracteres';
  }

  @override
  String get commonPasswordsDontMatch => 'As senhas não coincidem';

  @override
  String get commonInvalidEmail => 'E-mail inválido';

  @override
  String get commonYes => 'Sim';

  @override
  String get commonNo => 'Não';

  @override
  String get commonSeeAll => 'Ver todos';

  @override
  String get commonSeeAllFem => 'Ver todas';

  @override
  String get commonDescriptionOptional => 'Descrição (opcional)';

  @override
  String get commonSaveError => 'Erro ao salvar. Tente novamente.';

  @override
  String get commonEnterValidValue => 'Informe um valor válido';

  @override
  String get dashHello => 'Olá!';

  @override
  String dashHelloName(String name) {
    return 'Olá, $name!';
  }

  @override
  String get dashYourAcademyToday => 'Sua academia hoje';

  @override
  String get dashActiveStudents => 'Alunos ativos';

  @override
  String get dashActiveClasses => 'Turmas ativas';

  @override
  String get dashAttendanceToday => 'Presenças hoje';

  @override
  String get dashOverdueAccounts => 'Inadimplentes';

  @override
  String get dashQuickActions => 'Ações rápidas';

  @override
  String get dashNewStudent => 'Novo aluno';

  @override
  String get dashNewClass => 'Nova turma';

  @override
  String get dashMarkAttendance => 'Registrar presença';

  @override
  String get dashTrialActive => 'Trial gratuito ativo';

  @override
  String get dashTrialLastDay => 'Último dia do trial!';

  @override
  String dashTrialDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dias restantes',
      one: '1 dia restante',
    );
    return '$_temp0';
  }

  @override
  String get dashSeePlans => 'Ver planos';

  @override
  String get dashFreePlan => 'Plano Gratuito';

  @override
  String get dashFreePlanLimits =>
      'Limite: 3 turmas · 10 alunos/turma · anúncios';

  @override
  String get dashSubscribePro => 'Assinar PRO';

  @override
  String get dashGettingStarted => 'Primeiros passos';

  @override
  String get dashGettingStartedSubtitle => 'Configure sua academia em ordem';

  @override
  String get dashStepModality => 'Crie uma modalidade';

  @override
  String get dashStepModalityDesc => 'Ex: Jiu-Jitsu, Muay Thai, Boxe.';

  @override
  String get dashStepPlan => 'Crie um plano de mensalidade';

  @override
  String get dashStepPlanDesc => 'Defina valores e periodicidade.';

  @override
  String get dashStepInstructor => 'Cadastre um professor';

  @override
  String get dashStepInstructorDesc =>
      'Turmas precisam de um professor responsável.';

  @override
  String get dashStepClass => 'Monte uma turma';

  @override
  String get dashStepClassDesc => 'Agrupe alunos por modalidade e horário.';

  @override
  String get dashStepFirstStudent => 'Cadastre seu primeiro aluno';

  @override
  String get dashStepFirstStudentDesc =>
      'Adicione alunos e matricule nas turmas.';

  @override
  String get dashAttendanceWatch => 'Risco de evasão';

  @override
  String dashWatchRedSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alunos sem treinar há 7+ dias',
      one: '1 aluno sem treinar há 7+ dias',
    );
    return '$_temp0';
  }

  @override
  String dashWatchYellowSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alunos com 7–13 dias de ausência',
      one: '1 aluno com 7–13 dias de ausência',
    );
    return '$_temp0';
  }

  @override
  String dashDaysCount(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dias',
      one: '1 dia',
    );
    return '$_temp0';
  }

  @override
  String dashSeeAllStudents(int count) {
    return 'Ver todos os $count alunos';
  }

  @override
  String get dashOpenListWhatsapp => 'Abrir lista (chamar no WhatsApp)';

  @override
  String get dashBirthdays => 'Aniversariantes';

  @override
  String get dashThisMonth => 'Este mês';

  @override
  String get dashNearingPromotion => 'Próximos de graduar';

  @override
  String get dashNearingPromotionSubtitle =>
      'Alunos próximos do mínimo de aulas';

  @override
  String get dashNoOneNearingPromotion => 'Nenhum aluno próximo da graduação';

  @override
  String dashClassesProgress(int done, int needed) {
    return '$done/$needed aulas';
  }

  @override
  String get dashEligible => 'Apto!';

  @override
  String get dashLatestNews => 'Últimas notícias';

  @override
  String get dashNewModalityTitle => 'Nova modalidade';

  @override
  String get dashNewModalityHint =>
      'Ex: Jiu-Jitsu, Muay Thai, Boxe, Luta Livre';

  @override
  String get dashModalityNameField => 'Nome da modalidade';

  @override
  String get dashCreateModality => 'Criar modalidade';

  @override
  String get dashNewPlanTitle => 'Novo plano de mensalidade';

  @override
  String get dashNewPlanSubtitle => 'Defina o valor que seus alunos pagarão.';

  @override
  String get dashPlanNameField => 'Nome do plano (ex: Mensal, Trimestral)';

  @override
  String get dashPlanMonthlyValueField => 'Valor mensal (R\$)';

  @override
  String get dashPlanEnrollmentFeeField => 'Taxa de matrícula (opcional)';

  @override
  String get dashCreatePlan => 'Criar plano';

  @override
  String get dashWeeklyFrequency => 'Frequência semanal';

  @override
  String get dashLast7Days => 'Últimos 7 dias';

  @override
  String get dashNoAttendance7Days =>
      'Nenhuma presença registrada nos últimos 7 dias.';

  @override
  String dashTotalCount(int count) {
    return '$count total';
  }

  @override
  String get navHome => 'Início';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navStudents => 'Alunos';

  @override
  String get navClasses => 'Turmas';

  @override
  String get navStaff => 'Equipe';

  @override
  String get navBilling => 'Financeiro';

  @override
  String get navRanking => 'Ranking';

  @override
  String get navMore => 'Mais';

  @override
  String get menuSectionMain => 'PRINCIPAL';

  @override
  String get menuSectionOther => 'OUTROS';

  @override
  String get menuSectionAccount => 'CONTA';

  @override
  String get menuNews => 'Notícias';

  @override
  String get menuSettings => 'Configurações';

  @override
  String get menuSignOut => 'Sair';

  @override
  String get roleAdmin => 'Administrador';

  @override
  String get roleStudent => 'Aluno';

  @override
  String get roleTeacher => 'Professor';

  @override
  String get roleSecretary => 'Secretaria';

  @override
  String get psTitle => 'Trocar perfil';

  @override
  String get psSubtitle => 'Escolha quem está usando o app agora';

  @override
  String get psInUse => 'Em uso';

  @override
  String get psAccess => 'Acessar';

  @override
  String get adminPanelSubtitle => 'Painel de Gestão';

  @override
  String get signOutConfirmTitle => 'Sair da conta?';

  @override
  String get signOutConfirmBody =>
      'Você precisará entrar novamente para acessar o app.';

  @override
  String get settingsAppearanceSection => 'Aparência e idioma';

  @override
  String get settingsAppearanceSubtitle =>
      'Ajuste o tema e o idioma do aplicativo.';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsLanguageSheetTitle => 'Idioma';

  @override
  String get settingsThemeSheetTitle => 'Tema';

  @override
  String get settingsOptionSystem => 'Automático';

  @override
  String get settingsOptionSystemLanguageHint =>
      'Segue o idioma do dispositivo';

  @override
  String get settingsOptionSystemThemeHint => 'Segue o tema do dispositivo';

  @override
  String get settingsLanguagePt => 'Português (Brasil)';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Escuro';

  @override
  String get authWelcomeChooseAccess =>
      'Bem-vindo, escolha sua forma de acesso';

  @override
  String get authIAmStudentOrGuardianTitle => 'Sou Aluno ou Responsável';

  @override
  String get authIAmStudentOrGuardianSubtitle =>
      'Treinos, graduações, financeiro e carteirinha';

  @override
  String get authIAmAcademyTitle => 'Sou uma Academia';

  @override
  String get authIAmAcademySubtitle =>
      'Gerencie alunos, turmas, equipe e financeiro';

  @override
  String get authEmailOrPhone => 'E-mail ou Telefone';

  @override
  String get authPassword => 'Senha';

  @override
  String get authSignIn => 'Entrar';

  @override
  String get authForgotPassword => 'Esqueci minha senha';

  @override
  String get authFirstTimeAccess => 'Primeiro acesso';

  @override
  String get authCreateAcademy => 'Criar uma academia';

  @override
  String get authAccessAcademyPanel => 'Acesse o painel da sua academia';

  @override
  String get authAccessStudentAccount =>
      'Acesse sua conta de aluno ou responsável';

  @override
  String get authEnterEmailOrPhone => 'Informe seu e-mail ou telefone.';

  @override
  String get authInvalidEmailShort => 'E-mail inválido.';

  @override
  String get authInvalidPhoneExample =>
      'Telefone inválido. Ex: (11) 99999-0000';

  @override
  String get authWhichProfile => 'Qual perfil deseja acessar?';

  @override
  String get authSigningIn => 'Autenticando...';

  @override
  String get authLoadingYourData => 'Carregando seus dados...';

  @override
  String get authAlmostThere => 'Quase lá...';

  @override
  String get authErrWrongCredentials =>
      'E-mail ou senha incorretos. Se nunca acessou pelo app, use \"Esqueci minha senha\" para definir sua senha.';

  @override
  String get authErrAccountDisabled => 'Esta conta está desativada.';

  @override
  String get authErrTooManyRequests =>
      'Muitas tentativas. Aguarde alguns minutos e tente novamente.';

  @override
  String get authErrNetwork => 'Sem conexão com a internet.';

  @override
  String get authErrGenericSignIn =>
      'Erro ao autenticar. Verifique seus dados e tente novamente.';

  @override
  String get authErrTimeout =>
      'Tempo esgotado. Verifique sua conexão e tente novamente.';

  @override
  String get authErrProfileNotFound => 'Perfil de aluno não encontrado.';

  @override
  String get authErrAccountInactive =>
      'Seu cadastro está inativo. Entre em contato com a secretaria.';

  @override
  String get authErrAppAccessSuspended =>
      'Seu acesso ao app está suspenso. Entre em contato com a secretaria.';

  @override
  String get authErrBlockedOverdue =>
      'Acesso bloqueado: mensalidade vencida. Regularize seu pagamento e tente novamente.';

  @override
  String get forgotTitle => 'Esqueci minha senha';

  @override
  String get forgotHeadline => 'Recuperar acesso';

  @override
  String get forgotInstruction =>
      'Informe seu e-mail e enviaremos um link para você criar uma nova senha.';

  @override
  String get forgotEmailLabel => 'E-mail';

  @override
  String get forgotEmailHint => 'seu@email.com';

  @override
  String get forgotSendButton => 'Enviar link de recuperação';

  @override
  String get forgotSentTitle => 'E-mail enviado!';

  @override
  String get forgotSentBody =>
      'Verifique sua caixa de entrada (e spam). Clique no link recebido para criar sua nova senha.';

  @override
  String get forgotErrEmailNotFound =>
      'Nenhuma conta encontrada com esse e-mail.';

  @override
  String get forgotErrInvalidEmail => 'E-mail inválido.';

  @override
  String get forgotErrTooManyRequests =>
      'Muitas tentativas. Aguarde alguns minutos.';

  @override
  String get forgotErrSendFailed => 'Erro ao enviar e-mail. Tente novamente.';

  @override
  String get forgotErrUnexpected => 'Erro inesperado. Tente novamente.';

  @override
  String get changePwTitle => 'Alterar Senha';

  @override
  String get changePwHint => 'Use no mínimo 6 caracteres com letras e números.';

  @override
  String get changePwCurrentLabel => 'Senha atual';

  @override
  String get changePwCurrentHint => 'Digite sua senha atual';

  @override
  String get changePwNewLabel => 'Nova senha';

  @override
  String get changePwNewHint => 'Digite a nova senha';

  @override
  String get changePwConfirmLabel => 'Confirmar nova senha';

  @override
  String get changePwConfirmHint => 'Repita a nova senha';

  @override
  String get changePwMustBeDifferent =>
      'A nova senha deve ser diferente da atual';

  @override
  String get changePwSuccess => 'Senha alterada com sucesso!';

  @override
  String get changePwErrWrongCurrent => 'Senha atual incorreta.';

  @override
  String get changePwErrWeak => 'A nova senha é muito fraca.';

  @override
  String get changePwErrGeneric => 'Erro ao alterar senha. Tente novamente.';

  @override
  String get studentsSearchHint => 'Buscar aluno...';

  @override
  String get studentsEmpty => 'Nenhum aluno encontrado.';

  @override
  String get studentsLoadError => 'Não foi possível carregar os alunos.';

  @override
  String get studentNoBelt => 'Sem graduação';

  @override
  String get statusActive => 'Ativo';

  @override
  String get statusInactive => 'Inativo';

  @override
  String get finUpToDate => 'Em dia';

  @override
  String get finPending => 'Pendente';

  @override
  String get finOverdue => 'Inadimplente';

  @override
  String get medicalCertificateShort => 'Atestado';

  @override
  String stripeLabel(int count) {
    return '$countº Grau';
  }

  @override
  String get sdTitleFallback => 'Aluno';

  @override
  String get sdActivate => 'Ativar';

  @override
  String get sdDeactivate => 'Desativar';

  @override
  String get sdNoAccessTitle => 'Você não tem acesso a este aluno.';

  @override
  String get sdNoAccessBody => 'Só é possível abrir alunos das suas turmas.';

  @override
  String get sdNotFound => 'Aluno não encontrado.';

  @override
  String get sdLoadError => 'Erro ao carregar aluno.';

  @override
  String get sdName => 'Nome';

  @override
  String get sdEmail => 'E-mail';

  @override
  String get sdPhone => 'Telefone';

  @override
  String get sdBirthDate => 'Nascimento';

  @override
  String get sdBeltSection => 'Graduação';

  @override
  String get sdPromote => 'Graduar';

  @override
  String get sdCurrentBelt => 'Faixa atual';

  @override
  String get sdNoGraduation => 'Nenhuma graduação';

  @override
  String get sdLevelXp => 'Nível / XP';

  @override
  String get sdPlanSection => 'Plano';

  @override
  String get sdNoPlan => 'Nenhum plano vinculado.';

  @override
  String get sdMonthlyValue => 'Valor mensal';

  @override
  String get sdDueDate => 'Vencimento';

  @override
  String sdEveryDayN(Object day) {
    return 'Todo dia $day';
  }

  @override
  String get sdAppAccessSection => 'Acesso ao App';

  @override
  String get sdAccessBlocked => 'Acesso bloqueado';

  @override
  String get sdAccessAllowed => 'Acesso liberado';

  @override
  String get sdAccessBlockedHint => 'Aluno não consegue entrar no app.';

  @override
  String get sdAccessAllowedHint => 'Aluno pode usar o app normalmente.';

  @override
  String get sdResetPassword => 'Redefinir senha';

  @override
  String get sdGenerateAccess => 'Gerar acesso ao app';

  @override
  String get sdGenerateAccessHint =>
      'Gere a senha temporária para o aluno entrar direto pelo telefone ou e-mail cadastrado, sem \"primeiro acesso\".';

  @override
  String get sdThisStudent => 'este aluno';

  @override
  String get sdMedicalCertSection => 'Atestado Médico';

  @override
  String get sdCertNone => 'Sem atestado';

  @override
  String get sdCertPending => 'Aguardando aprovação';

  @override
  String get sdCertApproved => 'Aprovado';

  @override
  String get sdCertRejected => 'Rejeitado';

  @override
  String get sdCertExpired => 'Expirado';

  @override
  String get sdCertUnknown => 'Desconhecido';

  @override
  String get sdValidity => 'Validade';

  @override
  String get sdReason => 'Motivo';

  @override
  String get sdViewCert => 'Ver Atestado';

  @override
  String get sdApprove => 'Aprovar';

  @override
  String get sdReject => 'Rejeitar';

  @override
  String get sdAttach => 'Anexar';

  @override
  String get sdRemind => 'Lembrar';

  @override
  String get sdRejectReasonTitle => 'Motivo da rejeição';

  @override
  String get sdRejectReasonHint => 'Ex: atestado inválido, fora da validade...';

  @override
  String get sdFileUnavailable => 'Arquivo não disponível.';

  @override
  String get sdFileOpenFailed => 'Não foi possível abrir o arquivo.';

  @override
  String get sdFileOpenError => 'Erro ao abrir o arquivo.';

  @override
  String get sdCertApprovedToast => 'Atestado aprovado!';

  @override
  String get sdCertRejectedToast => 'Atestado rejeitado.';

  @override
  String get sdCertReminderTitle => 'Atestado médico pendente';

  @override
  String get sdCertReminderBody =>
      'Apresente seu atestado médico à academia para regularizar sua situação.';

  @override
  String get sdReminderSent => 'Lembrete enviado ao aluno!';

  @override
  String get sdReminderError => 'Erro ao enviar lembrete.';

  @override
  String get sdFileTooLarge => 'Arquivo muito grande. Máx 5 MB.';

  @override
  String get sdCertAttached => 'Atestado anexado e aprovado!';

  @override
  String get sdCertAttachError => 'Erro ao anexar atestado.';

  @override
  String get sdFamilySection => 'Grupo Familiar';

  @override
  String get sdAdd => 'Adicionar';

  @override
  String get sdLeave => 'Sair';

  @override
  String get sdNoFamily => 'Não vinculado a nenhum grupo familiar.';

  @override
  String get sdCreateGroup => 'Criar grupo';

  @override
  String get sdLinkExisting => 'Vincular existente';

  @override
  String get sdGuardian => 'Responsável';

  @override
  String get sdNoOtherMembers => 'Nenhum outro membro no grupo.';

  @override
  String get sdCreateFamilyTitle => 'Criar Grupo Familiar';

  @override
  String get sdCreateFamilyHint =>
      'O aluno será adicionado automaticamente ao grupo.';

  @override
  String get sdFamilyNameHint => 'Ex: Família Silva';

  @override
  String get sdCreate => 'Criar';

  @override
  String get sdCreateGroupError => 'Erro ao criar grupo.';

  @override
  String get sdNoGroupsYet => 'Nenhum grupo cadastrado ainda.';

  @override
  String get sdSelectGroup => 'Selecionar Grupo';

  @override
  String sdMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membros',
      one: '1 membro',
    );
    return '$_temp0';
  }

  @override
  String get sdLinkGroupError => 'Erro ao vincular grupo.';

  @override
  String get sdAddMember => 'Adicionar Membro';

  @override
  String get sdAddMemberError => 'Erro ao adicionar membro.';

  @override
  String get sdRemoveMember => 'Remover membro';

  @override
  String sdRemoveMemberBody(String name) {
    return 'Remover $name do grupo?';
  }

  @override
  String get sdRemoveMemberError => 'Erro ao remover membro.';

  @override
  String get sdLeaveGroup => 'Sair do grupo';

  @override
  String sdLeaveGroupBody(String name) {
    return 'Remover este aluno do grupo \"$name\"?';
  }

  @override
  String get sdLeaveGroupError => 'Erro ao sair do grupo.';

  @override
  String get sdSetGuardian => 'Definir responsável';

  @override
  String sdSetGuardianBody(String name) {
    return 'Definir $name como responsável financeiro do grupo?';
  }

  @override
  String get sdSetGuardianError => 'Erro ao definir responsável.';

  @override
  String get sdView => 'Visualizar';

  @override
  String get sdFill => 'Preencher';

  @override
  String get sdParqEmpty => 'PAR-Q não preenchido.';

  @override
  String get sdParqMedicalRecommended => 'Avaliação médica recomendada';

  @override
  String get sdParqNoRisk => 'Sem indicações de risco';

  @override
  String sdParqFilledOn(String date) {
    return 'Preenchido em $date';
  }

  @override
  String get sdParqFillTitle => 'Preencher PAR-Q';

  @override
  String get sdParqEditTitle => 'Editar PAR-Q';

  @override
  String get sdParqInstruction =>
      'Responda \"Sim\" ou \"Não\" a cada pergunta. Preenchimento feito pela academia em nome do aluno.';

  @override
  String get sdParqQuestionnaire => 'QUESTIONÁRIO';

  @override
  String get sdParqTerm => 'TERMO DE RESPONSABILIDADE';

  @override
  String get sdParqTermBody =>
      'Declaro que estou ciente de que é recomendável conversar com um médico, antes de iniciar ou aumentar o nível de atividade física pretendido, assumindo plena responsabilidade pela realização de qualquer atividade física sem o atendimento desta recomendação.';

  @override
  String get sdFullNameRequired => 'Nome completo *';

  @override
  String get sdParqFillNameCpf => 'Preencha nome e CPF.';

  @override
  String get sdParqSaved => 'PAR-Q salvo com sucesso!';

  @override
  String get sdParqSaveError => 'Erro ao salvar PAR-Q.';

  @override
  String get sdParqSaveBtn => 'Salvar PAR-Q';

  @override
  String get sdParqUpdateBtn => 'Atualizar PAR-Q';

  @override
  String get sdParqQ1 =>
      'Algum médico já disse que você possui algum problema de coração ou pressão arterial, e que somente deveria realizar atividade física supervisionado por profissionais de saúde?';

  @override
  String get sdParqQ2 =>
      'Você sente dores no peito quando pratica atividade física?';

  @override
  String get sdParqQ3 =>
      'No último mês, você sentiu dores no peito ao praticar atividade física?';

  @override
  String get sdParqQ4 =>
      'Você apresenta algum desequilíbrio devido à tontura e/ou perda momentânea da consciência?';

  @override
  String get sdParqQ5 =>
      'Você possui algum problema ósseo ou articular, que pode ser afetado ou agravado pela atividade física?';

  @override
  String get sdParqQ6 =>
      'Você toma atualmente algum tipo de medicação de uso contínuo?';

  @override
  String get sdParqQ7 =>
      'Você realiza algum tipo de tratamento médico para pressão arterial ou problemas cardíacos?';

  @override
  String get sdParqQ8 =>
      'Você realiza algum tratamento médico contínuo, que possa ser afetado ou prejudicado com a atividade física?';

  @override
  String get sdParqQ9 =>
      'Você já se submeteu a algum tipo de cirurgia, que comprometa de alguma forma a atividade física?';

  @override
  String get sdParqQ10 =>
      'Sabe de alguma outra razão pela qual a atividade física possa eventualmente comprometer sua saúde?';

  @override
  String get sdGradWhat => 'O que deseja fazer?';

  @override
  String get sdGiveStripe => 'Dar Grau';

  @override
  String get sdGiveStripeHint => 'Incrementar grau na mesma faixa atual';

  @override
  String get sdNewBelt => 'Nova Faixa';

  @override
  String get sdNewBeltHint => 'Selecionar uma faixa diferente';

  @override
  String get sdSelectModality => 'Selecione a modalidade';

  @override
  String sdSelectBelt(Object mod) {
    return 'Selecione a faixa — $mod';
  }

  @override
  String get sdNoBeltsAvailable => 'Nenhuma faixa disponível.';

  @override
  String get sdNext => 'Próximo';

  @override
  String get sdStripe => 'Grau';

  @override
  String get sdNoStripe => 'Sem grau';

  @override
  String get sdObsOptional => 'Observação (opcional)';

  @override
  String get sdGenerateCharge => 'Gerar cobrança financeira';

  @override
  String get sdChargeAmount => 'Valor da cobrança (R\$)';

  @override
  String get sdPromoteStudent => 'Graduar Aluno';

  @override
  String get sdConfirmPromotion => 'Confirmar Graduação';

  @override
  String sdPromotedToast(Object name, Object belt) {
    return '$name graduado para $belt!';
  }

  @override
  String get sdPromoteError => 'Erro ao graduar.';

  @override
  String get sdLinkToClass => 'Vincular a uma Turma';

  @override
  String get sdAlreadyLinked => 'Já vinculado';

  @override
  String sdLinkedToast(Object turma) {
    return 'Vinculado à $turma!';
  }

  @override
  String get sdLinkError => 'Erro ao vincular.';

  @override
  String get sdLink => 'Vincular';

  @override
  String get sdEditStudent => 'Editar Aluno';

  @override
  String get sdPersonalData => 'Dados pessoais';

  @override
  String get sdEditAccessWarning =>
      'Este aluno já tem acesso ativo ao app. Alterar e-mail/telefone aqui NÃO muda a senha nem o login dele. Use \"Redefinir senha\" se for necessário.';

  @override
  String get sdCpfOptional => 'CPF (opcional)';

  @override
  String get sdBirthDateField => 'Data de nascimento (DD/MM/AAAA)';

  @override
  String get sdGuardianEmergency => 'Responsável / Emergência';

  @override
  String get sdContactName => 'Nome do contato';

  @override
  String get sdContactPhone => 'Telefone do contato';

  @override
  String get sdBillingPlan => 'Plano financeiro';

  @override
  String get sdSelectPlan => 'Selecionar Plano';

  @override
  String get sdNoPlanOption => 'Sem plano';

  @override
  String sdPerMonth(String value) {
    return 'R\$ $value / mês';
  }

  @override
  String get sdSelectPlanPlaceholder => 'Selecionar plano';

  @override
  String get sdDueDayField => 'Dia de vencimento (1-31)';

  @override
  String get sdNameRequired => 'Nome é obrigatório.';

  @override
  String get sdPhoneInvalid => 'Telefone inválido.';

  @override
  String get sdStudentUpdated => 'Aluno atualizado com sucesso!';

  @override
  String get sdStudentUpdateError => 'Erro ao atualizar aluno.';

  @override
  String get sdSaveChanges => 'Salvar alterações';

  @override
  String get sdPoints => 'Pontos';

  @override
  String get sdRankingsHint =>
      'Toque em \"Pontos\" para lançar pontos em um ranking personalizado.';

  @override
  String get sdAddPoints => 'Lançar Pontos';

  @override
  String get sdNoManualRankings => 'Nenhum ranking com pontos manuais ativo.';

  @override
  String get sdPointsAmount => 'Quantidade de pontos';

  @override
  String sdPointsAddedToast(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pontos lançados com sucesso!',
      one: '1 ponto lançado com sucesso!',
    );
    return '$_temp0';
  }

  @override
  String get sdPointsError => 'Erro ao lançar pontos.';

  @override
  String get sdEmergencyContact => 'Contato de Emergência';

  @override
  String get sdNoClasses => 'Nenhuma turma vinculada.';

  @override
  String get sdBeltHistory => 'Histórico de Graduações';

  @override
  String get sdNoBeltHistory => 'Nenhuma graduação registrada.';

  @override
  String get sdRemovePromotionTitle => 'Remover graduação?';

  @override
  String sdRemovePromotionBody(String label) {
    return 'Esta ação remove \"$label\" do histórico de graduações e não pode ser desfeita.';
  }

  @override
  String get sdPromotionRemoved => 'Graduação removida.';

  @override
  String get sdPromotionRemoveError => 'Erro ao remover graduação.';

  @override
  String get sdEditPromotion => 'Editar graduação';

  @override
  String get sdBelt => 'Faixa';

  @override
  String get sdExamDate => 'Data do exame';

  @override
  String get sdDateMask => 'DD/MM/AAAA';

  @override
  String get sdNotesOptional => 'Observações (opcional)';

  @override
  String get sdNotes => 'Observações';

  @override
  String get sdDateFormatError => 'Informe a data no formato DD/MM/AAAA.';

  @override
  String get sdPromotionUpdated => 'Graduação atualizada.';

  @override
  String get sdCheckHistory => 'Verifique o histórico';

  @override
  String get sdPromotionEditError => 'Erro ao editar graduação.';

  @override
  String get sdSaveCorrection => 'Salvar correção';

  @override
  String get sdPhotoError => 'Erro ao salvar foto.';

  @override
  String sdActivateConfirm(Object name) {
    return 'Deseja ativar $name?';
  }

  @override
  String sdDeactivateConfirm(Object name) {
    return 'Deseja desativar $name?';
  }

  @override
  String get sdStatusChangeError => 'Erro ao alterar status.';

  @override
  String sdAllowAccessConfirm(Object name) {
    return 'Liberar o acesso ao app de $name?';
  }

  @override
  String sdBlockAccessConfirm(Object name) {
    return 'Bloquear o acesso ao app de $name?';
  }

  @override
  String get sdAccessChangeError => 'Erro ao alterar acesso.';

  @override
  String get sdBeltsLoadError =>
      'Não foi possível carregar as faixas dessa modalidade.';

  @override
  String get commonMenu => 'Menu';

  @override
  String get classesSubtitle =>
      'Gerencie suas turmas e acompanhe a evolução dos alunos.';

  @override
  String get classesSearchHint => 'Buscar turma...';

  @override
  String get attendanceReport => 'Relatório de presenças';

  @override
  String get classesEmpty => 'Nenhuma turma encontrada.';

  @override
  String get classesMoreTitle => 'Mais turmas, mais histórias';

  @override
  String get classesMoreSubtitle =>
      'Cadastre novas turmas e mantenha toda a sua academia organizada.';

  @override
  String get classesEmptyState => 'Você ainda não possui turmas cadastradas.';

  @override
  String get classesCreateFirst => 'Criar primeira turma';

  @override
  String get classesLoadError => 'Não foi possível carregar as informações.';

  @override
  String get classStatusActive => 'Ativa';

  @override
  String get classStatusInactive => 'Inativa';

  @override
  String classInstructorPrefix(String name) {
    return 'Prof. $name';
  }

  @override
  String classCapacitySuffix(String cap) {
    return ' / $cap alunos';
  }

  @override
  String get takeAttendance => 'Fazer chamada';

  @override
  String get viewDetails => 'Ver detalhes';

  @override
  String get editClass => 'Editar turma';

  @override
  String get noSchedule => 'Sem horários definidos';

  @override
  String scheduleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count horários',
      one: '1 horário',
    );
    return '$_temp0';
  }

  @override
  String get editClassTitle => 'Editar Turma';

  @override
  String get newClassTitle => 'Nova Turma';

  @override
  String get classNameField => 'Nome da Turma';

  @override
  String get modality => 'Modalidade';

  @override
  String get level => 'Nível';

  @override
  String get instructorOptional => 'Professor (opcional)';

  @override
  String get noInstructor => 'Sem professor';

  @override
  String get maxCapacity => 'Capacidade máxima';

  @override
  String get invalidNumber => 'Número inválido';

  @override
  String get classActiveToggle => 'Turma ativa';

  @override
  String get classEditError => 'Erro ao editar turma';

  @override
  String get classCreateError => 'Erro ao criar turma';

  @override
  String get levelBeginner => 'Iniciante';

  @override
  String get levelIntermediate => 'Intermediário';

  @override
  String get levelAdvanced => 'Avançado';

  @override
  String get levelAll => 'Todos os níveis';

  @override
  String get dowSun => 'Dom';

  @override
  String get dowMon => 'Seg';

  @override
  String get dowTue => 'Ter';

  @override
  String get dowWed => 'Qua';

  @override
  String get dowThu => 'Qui';

  @override
  String get dowFri => 'Sex';

  @override
  String get dowSat => 'Sáb';

  @override
  String get attendanceReportTitle => 'Relatório de Presenças';

  @override
  String get noClassesRegistered => 'Nenhuma turma cadastrada.';

  @override
  String get periodLabel => 'Período';

  @override
  String periodDaysCount(int count) {
    return '$count dias';
  }

  @override
  String get periodCustom => 'Personalizado';

  @override
  String get totalSessions => 'Total de Aulas';

  @override
  String get avgAttendance => 'Frequência média';

  @override
  String studentAttendanceCount(int count) {
    return 'Frequência dos alunos ($count)';
  }

  @override
  String get noSessionsInPeriod =>
      'Não há aulas registradas neste período.\nSelecione outro intervalo para ver a frequência.';

  @override
  String get noStudentsInClass => 'Nenhum aluno matriculado nesta turma.';

  @override
  String get sortBy => 'Ordenar por';

  @override
  String get sortAttendanceDesc => 'Maior frequência';

  @override
  String get sortAttendanceAsc => 'Menor frequência';

  @override
  String get sortNameAsc => 'Nome (A–Z)';

  @override
  String get sortNameDesc => 'Nome (Z–A)';

  @override
  String presentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count presenças',
      one: '1 presença',
    );
    return '$_temp0';
  }

  @override
  String absentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count faltas',
      one: '1 falta',
    );
    return '$_temp0';
  }

  @override
  String attendanceA11y(String name, String pct, int present, int absent) {
    return '$name, $pct% de frequência, $present presenças, $absent faltas';
  }

  @override
  String get dowFullSun => 'Domingo';

  @override
  String get dowFullMon => 'Segunda';

  @override
  String get dowFullTue => 'Terça';

  @override
  String get dowFullWed => 'Quarta';

  @override
  String get dowFullThu => 'Quinta';

  @override
  String get dowFullFri => 'Sexta';

  @override
  String get dowFullSat => 'Sábado';

  @override
  String get tdTabAttendance => 'Presença';

  @override
  String get tdTabSchedule => 'Horários';

  @override
  String get tdDeleteClass => 'Excluir turma';

  @override
  String get tdClassNotFound => 'Turma não encontrada';

  @override
  String get tdClassLoadError => 'Erro ao carregar turma';

  @override
  String get tdClassFallback => 'Turma';

  @override
  String get tdEnrolledStudents => 'Alunos matriculados';

  @override
  String get tdSortPrefix => 'Ordenar: ';

  @override
  String get tdAddStudent => 'Adicionar aluno';

  @override
  String get tdDragToReorder => 'Segure e arraste para reordenar';

  @override
  String get tdEligibleToPromote => 'Apto para graduar';

  @override
  String get tdAttendancesLabel => 'presenças';

  @override
  String get tdSortStudents => 'Ordenar alunos';

  @override
  String get tdReorderByDrag => 'Reordenar arrastando';

  @override
  String get tdReorderHint =>
      'Segure e arraste os alunos para montar a ordem da turma';

  @override
  String get tdOrderSaved => 'Ordem da turma salva.';

  @override
  String get tdOrderSaveError => 'Não foi possível salvar a ordem.';

  @override
  String get tdOrdManual => 'Ordem personalizada';

  @override
  String get tdOrdBeltDesc => 'Graduação (mais alta)';

  @override
  String get tdOrdBeltAsc => 'Graduação (mais baixa)';

  @override
  String get tdOrdEnrollOld => 'Matrícula (mais antiga)';

  @override
  String get tdOrdEnrollNew => 'Matrícula (mais recente)';

  @override
  String get tdOrdAttendDesc => 'Mais presenças';

  @override
  String get tdOrdAttendAsc => 'Menos presenças';

  @override
  String get tdPresentToday => 'Presentes hoje';

  @override
  String get tdDayAttendanceRate => 'Frequência do dia';

  @override
  String get tdMarkAll => 'Marcar todos';

  @override
  String get tdNoStudentsForAttendance =>
      'Não há alunos matriculados para realizar a chamada.';

  @override
  String get tdOffScheduleDay => 'Dia fora do horário';

  @override
  String tdOffScheduleAllBody(String day) {
    return 'Hoje não é o dia de treino cadastrado para essa turma. Marcar presença de todos para $day?';
  }

  @override
  String tdOffScheduleOneBody(String day) {
    return 'Hoje não é o dia de treino cadastrado para essa turma. Deseja mesmo confirmar presença para $day?';
  }

  @override
  String get tdConfirmAnyway => 'Confirmar assim mesmo';

  @override
  String get tdAttendanceAllMarked => 'Presença registrada para todos.';

  @override
  String tdAttendanceSomeFailed(int count) {
    return 'Alguns não foram registrados ($count). Tente novamente.';
  }

  @override
  String get tdEnrollIdNotFound => 'ID de matrícula não encontrado.';

  @override
  String get tdRemoveStudent => 'Remover aluno';

  @override
  String tdRemoveStudentBody(String name) {
    return 'Deseja remover $name desta turma?';
  }

  @override
  String tdStudentRemoved(String name) {
    return '$name removido da turma.';
  }

  @override
  String get tdRemoveStudentError => 'Erro ao remover aluno.';

  @override
  String get tdPresent => 'Presente';

  @override
  String get tdMark => 'Marcar';

  @override
  String get tdAttendanceMarked => 'Presença registrada!';

  @override
  String get tdAttendanceMarkError => 'Erro ao registrar presença.';

  @override
  String get tdUndoAttendance => 'Desfazer presença';

  @override
  String tdUndoAttendanceBody(String name) {
    return 'Deseja remover a presença de $name nesta data?';
  }

  @override
  String get tdAttendanceRemoved => 'Presença removida.';

  @override
  String get tdAttendanceRemoveError => 'Erro ao remover presença.';

  @override
  String get tdToday => 'Hoje';

  @override
  String get tdYesterday => 'Ontem';

  @override
  String tdWeeklyScheduleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count horários semanais',
      one: '1 horário semanal',
    );
    return '$_temp0';
  }

  @override
  String get tdClassSchedule => 'Horários da turma';

  @override
  String get tdNewSchedule => 'Novo horário';

  @override
  String get tdNoSchedules => 'Nenhum horário cadastrado.';

  @override
  String get tdAddFirstSchedule => 'Adicionar primeiro horário';

  @override
  String tdRoomN(String room) {
    return 'Sala $room';
  }

  @override
  String get tdListAnd => ' e ';

  @override
  String get tdDeleteScheduleTitle => 'Excluir horário?';

  @override
  String get tdDeleteScheduleBody => 'Este horário será removido da turma.';

  @override
  String get tdScheduleRemoveError => 'Erro ao remover horário.';

  @override
  String get tdEditScheduleTitle => 'Editar Horário';

  @override
  String get tdNewScheduleTitle => 'Novo Horário';

  @override
  String get tdWeekday => 'Dia da semana';

  @override
  String get tdWeekdays => 'Dias da semana';

  @override
  String get tdStart => 'Início';

  @override
  String get tdRoomOptional => 'Sala (opcional)';

  @override
  String get tdSelectDayAndTime => 'Selecione ao menos um dia e os horários.';

  @override
  String get tdScheduleEditError => 'Erro ao editar horário.';

  @override
  String get tdScheduleCreateError => 'Erro ao criar horário.';

  @override
  String get tdEnrollStudent => 'Matricular aluno';

  @override
  String get tdNoStudentsAvailable => 'Nenhum aluno disponível.';

  @override
  String get tdEnrollError => 'Erro ao matricular aluno.';

  @override
  String get tdThisClass => 'esta turma';

  @override
  String tdDeleteClassConfirm(String name) {
    return 'Excluir \"$name\"?';
  }

  @override
  String get tdDeleteClassBody =>
      'A turma some das listagens ativas e as matrículas em aberto são encerradas. Alunos, presenças e graduações continuam no histórico — nada é apagado.';

  @override
  String tdClassDeletedWithEnroll(int count) {
    return 'Turma excluída. $count matrícula(s) encerrada(s).';
  }

  @override
  String get tdClassDeleted => 'Turma excluída.';

  @override
  String get tdClassDeleteError => 'Erro ao excluir turma.';

  @override
  String get tdClassQrTitle => 'QR Code da Turma';

  @override
  String get tdQrSubtitle => 'Alunos escaneiam para registrar presença';

  @override
  String get tdQrValidity => 'Válido apenas no horário da aula';

  @override
  String get caTitle => 'Contas da Academia';

  @override
  String get caLoadError => 'Erro ao carregar contas.';

  @override
  String get caMarkPaidError => 'Erro ao marcar como paga.';

  @override
  String get caDeleteTitle => 'Excluir conta';

  @override
  String caDeleteBody(String desc) {
    return 'Deseja excluir \"$desc\"?';
  }

  @override
  String get caNewBill => 'Nova conta';

  @override
  String get caEditBill => 'Editar conta';

  @override
  String get caDescHint => 'Descrição (ex: Conta de luz)';

  @override
  String get caAmountHint => 'Valor (R\$)';

  @override
  String caDueOn(String date) {
    return 'Vencimento: $date';
  }

  @override
  String get caRecurring => 'Conta recorrente (todo mês)';

  @override
  String get caSaveBill => 'Salvar conta';

  @override
  String get caToPay => 'A pagar';

  @override
  String get caOverdue => 'Atrasado';

  @override
  String get caFilterAll => 'Todas';

  @override
  String get caFilterPending => 'Pendentes';

  @override
  String get caFilterOverdue => 'Atrasadas';

  @override
  String get caFilterPaid => 'Pagas';

  @override
  String get caEmpty => 'Nenhuma conta cadastrada';

  @override
  String get caStPaid => 'Paga';

  @override
  String get caStOverdue => 'Atrasada';

  @override
  String get caStCancelled => 'Cancelada';

  @override
  String get caStPending => 'Pendente';

  @override
  String caCategoryDueOn(String cat, String date) {
    return '$cat · vence em $date';
  }

  @override
  String get caMarkAsPaid => 'Marcar como paga';

  @override
  String get caCatWater => 'Água';

  @override
  String get caCatPower => 'Luz';

  @override
  String get caCatRent => 'Aluguel';

  @override
  String get caCatInternet => 'Internet';

  @override
  String get caCatOther => 'Outros';

  @override
  String get raTitle => 'Relatório Anual';

  @override
  String get raLoadError => 'Não foi possível carregar o relatório.';

  @override
  String get raYearOverview => 'Visão geral do ano';

  @override
  String raNoMovement(int year) {
    return 'Nenhuma movimentação financeira encontrada em $year.';
  }

  @override
  String get raMonthlyRevenue => 'Receita mensal';

  @override
  String raOverdueCount(int count) {
    return 'Inadimplentes ($count)';
  }

  @override
  String get raNoOverdue => 'Nenhum inadimplente neste período.';

  @override
  String get raPrevYear => 'Ano anterior';

  @override
  String get raNextYear => 'Próximo ano';

  @override
  String get raReceivedYear => 'Recebido no ano';

  @override
  String raChargesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cobranças',
      one: '1 cobrança',
    );
    return '$_temp0';
  }

  @override
  String get raOverdue => 'Inadimplentes';

  @override
  String get raOutstanding => 'Em aberto';

  @override
  String get raReceived => 'Recebido';

  @override
  String raNoRevenueYear(int year) {
    return 'Sem receita registrada em $year.';
  }

  @override
  String raDaysOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias de atraso',
      one: '1 dia de atraso',
    );
    return '$_temp0';
  }

  @override
  String get raUnknownStudent => 'Aluno não identificado';

  @override
  String raBarTooltip(
    String month,
    int year,
    String received,
    String pending,
    String total,
  ) {
    return '$month $year\nRecebido: $received\nPendente: $pending\nTotal: $total';
  }

  @override
  String get fiStPending => 'Pendente';

  @override
  String get fiStPaid => 'Pago';

  @override
  String get fiStOverdue => 'Atrasado';

  @override
  String get fiStForecast => 'Previsto';

  @override
  String get fiStDismissed => 'Desconsiderado';

  @override
  String get fiTypeMonthly => 'Mensalidade';

  @override
  String get fiTypeEnrollment => 'Taxa de Matrícula';

  @override
  String get fiReportTab => 'Relatório';

  @override
  String get fiGenerateCharges => 'Gerar cobranças';

  @override
  String get fiGenerateCharge => 'Gerar cobrança';

  @override
  String get fiNewCharge => 'Nova cobrança';

  @override
  String get fiCurrentMonth => 'Mês atual';

  @override
  String get fiNoCharges => 'Nenhuma cobrança.';

  @override
  String fiChargesCount(int count) {
    return 'Cobranças · $count';
  }

  @override
  String get fiTabAll => 'Todos';

  @override
  String get fiTabPending => 'Pendentes';

  @override
  String get fiTabOverdue => 'Atrasados';

  @override
  String get fiTabPaid => 'Pagos';

  @override
  String get fiTabDismissed => 'Desconsiderados';

  @override
  String fiDueOn(String date) {
    return 'Venc. $date';
  }

  @override
  String fiLateFee(String value) {
    return '+ Taxa de atraso: $value';
  }

  @override
  String fiDiscount(String value) {
    return '- Desconto: $value';
  }

  @override
  String fiReceivedAmount(String value) {
    return 'Recebido: $value';
  }

  @override
  String get fiMarkPaid => 'Marcar como pago';

  @override
  String get fiRefund => 'Estornar pagamento';

  @override
  String get fiRefundTitle => 'Estornar pagamento?';

  @override
  String fiRefundBody(String name) {
    return 'Isso vai marcar o pagamento de $name como pendente novamente.';
  }

  @override
  String get fiRefundDone => 'Pagamento estornado.';

  @override
  String get fiRestoreCharge => 'Restaurar cobrança';

  @override
  String get fiDismissTitle => 'Desconsiderar cobrança?';

  @override
  String fiDismissBody(String name) {
    return 'A cobrança de $name não será mais cobrada e sai dos totais do financeiro. Você pode restaurá-la depois.';
  }

  @override
  String get fiDeleteCharge => 'Excluir cobrança';

  @override
  String get fiDeleteChargeBody =>
      'Tem certeza que deseja excluir esta cobrança? Esta ação não pode ser desfeita.';

  @override
  String fiMarkedPaid(String name) {
    return '$name marcado como pago!';
  }

  @override
  String get fiUpdateError => 'Erro ao atualizar pagamento.';

  @override
  String get fiConfirmPayment => 'Confirmar pagamento';

  @override
  String get fiBaseValue => 'Valor base';

  @override
  String get fiToReceive => 'A receber';

  @override
  String get fiDiscountOptional => 'Desconto (opcional)';

  @override
  String get fiLoadError => 'Erro ao carregar dados.';

  @override
  String get fiProcessError => 'Erro ao processar cobranças.';

  @override
  String get fiCreateError => 'Erro ao criar cobrança.';

  @override
  String get fiChargeCreated => 'Cobrança criada!';

  @override
  String get fiChargeViaWhatsapp => 'Cobrar via WhatsApp';

  @override
  String fiChargeViaWhatsappN(int count) {
    return 'Cobrar via WhatsApp ($count)';
  }

  @override
  String fiGenerateNCharges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Gerar $count cobranças',
      one: 'Gerar 1 cobrança',
    );
    return '$_temp0';
  }

  @override
  String fiAffectedStudents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alunos afetados',
      one: '1 aluno afetado',
    );
    return '$_temp0';
  }

  @override
  String get fiSeeAffected => 'Ver alunos afetados';

  @override
  String get fiNoStudentsForFilter => 'Nenhum aluno corresponde a este filtro.';

  @override
  String fiNChargesGenerated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cobranças geradas',
      one: '1 cobrança gerada',
    );
    return '$_temp0';
  }

  @override
  String get fiReadyForWhatsapp => 'Pronto para cobrar via WhatsApp!';

  @override
  String get fiTapEachStudent =>
      'Toque em cada aluno para abrir o WhatsApp com uma mensagem pronta.';

  @override
  String get fiNoPhone => 'Sem telefone';

  @override
  String get fiSelectClass => 'Selecione a turma';

  @override
  String get fiFilterBySituation => 'Filtrar por situação';

  @override
  String get fiSelectStudent => 'Selecione o aluno';

  @override
  String fiWhatsappGreeting(String name) {
    return 'Olá $name, ';
  }

  @override
  String get fiOptNoChargeMonth => 'Sem cobrança este mês';

  @override
  String get fiOptDueWithin7 => 'Venc. em até 7 dias';

  @override
  String get fiChooseWhoToCharge => 'Escolha quem deve ser cobrado:';

  @override
  String get fiByClass => 'Por turma';

  @override
  String get fiByClassHint => 'Cobrar alunos de uma turma específica';

  @override
  String get fiAllActive => 'Todos os ativos';

  @override
  String get fiAllActiveHint => 'Cobrar todos os alunos ativos da academia';

  @override
  String get fiRefundShort => 'Estornar';

  @override
  String get fiDismiss => 'Desconsiderar';

  @override
  String get fiBillsShort => 'Contas';

  @override
  String get fiType => 'Tipo';

  @override
  String get rkNoData => 'Sem dados no ranking';

  @override
  String get rkNoCustom => 'Nenhum ranking personalizado';

  @override
  String get rkCreateHint => 'Crie um ranking por presença ou pontos.';

  @override
  String get rkCreate => 'Criar ranking';

  @override
  String get rkNewRanking => 'Novo ranking';

  @override
  String get rkEditRanking => 'Editar ranking';

  @override
  String get rkAskAdmin =>
      'Peça ao administrador que crie rankings personalizados.';

  @override
  String get rkGeneralRanking => 'Ranking Geral';

  @override
  String get rkCustomTab => 'Personalizados';

  @override
  String rkWeightAttendance(Object n) {
    return 'Presenças ×$n';
  }

  @override
  String rkWeightManual(Object n) {
    return 'Manual ×$n';
  }

  @override
  String get rkWithPeriod => '📅 Com período';

  @override
  String get rkAddPoints => 'Lançar pontos';

  @override
  String get rkNoParticipants => 'Sem participantes';

  @override
  String get rkNobodyScored => 'Ninguém pontuou neste ranking ainda.';

  @override
  String get rkAddPointsError => 'Erro ao lançar pontos';

  @override
  String get rkInvalidValue => 'Valor inválido';

  @override
  String get rkReasonOptional => 'Motivo (opcional)';

  @override
  String get rkReasonHint1 => 'Ex: Vitória no campeonato';

  @override
  String get rkUpdateError => 'Erro ao atualizar';

  @override
  String get rkTapPlus => 'Toque em + para criar seu primeiro ranking';

  @override
  String get rkAcademyNotFound => 'Academia não encontrada.';

  @override
  String get rkNameRequired => 'Nome do ranking *';

  @override
  String get rkPointsComposition => 'Composição dos pontos';

  @override
  String get rkIncludeAttendance => 'Incluir presenças';

  @override
  String get rkEachAttendanceCounts => 'Cada presença conta como pontos';

  @override
  String get rkAttendanceWeight => 'Peso de cada presença:';

  @override
  String get rkIncludeManual => 'Incluir pontos manuais';

  @override
  String get rkManualHint => 'Pontos lançados manualmente pelo professor/admin';

  @override
  String get rkManualWeight => 'Peso dos pontos manuais:';

  @override
  String get rkValidityPeriod => 'Período de validade';

  @override
  String get rkOutsidePeriodIgnored =>
      'Presenças fora deste período serão ignoradas no cálculo.';

  @override
  String get rkStartDate => 'Data início';

  @override
  String get rkEndDate => 'Data fim';

  @override
  String get rkRemoveEntryTitle => 'Remover lançamento?';

  @override
  String get rkRemoveEntryBody =>
      'Este lançamento será removido permanentemente.';

  @override
  String get rkEntries => 'Lançamentos';

  @override
  String get rkNoParticipantsYet => 'Nenhum participante ainda';

  @override
  String rkPtsAttendance(Object n) {
    return '${n}pts presenças';
  }

  @override
  String rkPtsManual(Object n) {
    return '${n}pts manuais';
  }

  @override
  String get rkNoPointsYet => 'Nenhum ponto lançado ainda';

  @override
  String get rkUseButtonBelow => 'Use o botão abaixo para lançar pontos';

  @override
  String get rkEnterPoints => 'Informe a quantidade de pontos';

  @override
  String get rkMustNotBeZero => 'Deve ser diferente de zero';

  @override
  String get rkPointsHint => 'Pontos (ex: 10, -5)';

  @override
  String get rkDescribeReason => 'Descreva o motivo';

  @override
  String get rkReasonHint2 => 'Motivo (ex: 1º lugar no torneio X)';

  @override
  String get rkConfirmEntry => 'Confirmar lançamento';

  @override
  String get rkViewLeaderboardAddPoints => 'Ver leaderboard e lançar pontos';

  @override
  String get rkNoRankings => 'Nenhum ranking criado';

  @override
  String get rkVisibleStudentShort => 'Visível aluno';

  @override
  String get rkVisibleToStudents => 'Visível para os alunos';

  @override
  String get rkVisibleHint => 'Os alunos poderão ver este ranking no app';

  @override
  String rkByOn(String name, String date) {
    return 'por $name • $date';
  }

  @override
  String get rkManage => 'Gerenciar';

  @override
  String get rkVisibility => 'Visibilidade';

  @override
  String get newsNew => 'Nova notícia';

  @override
  String get newsPublished => 'Notícia publicada!';

  @override
  String get newsPublishError => 'Erro ao publicar.';

  @override
  String get newsDeleteTitle => 'Excluir notícia?';

  @override
  String get newsDeleteBody => 'Esta ação não pode ser desfeita.';

  @override
  String get newsDeleteError => 'Erro ao excluir.';

  @override
  String get newsEmpty => 'Nenhuma notícia cadastrada.';

  @override
  String get newsStatusPublished => 'Publicada';

  @override
  String get newsStatusDraft => 'Rascunho';

  @override
  String get newsPublish => 'Publicar';

  @override
  String get newsEditTitle => 'Editar Notícia';

  @override
  String get newsNewTitle => 'Nova Notícia';

  @override
  String get newsImageTooLarge => 'Imagem muito grande. Máximo 3MB.';

  @override
  String get newsTitleSummaryRequired => 'Título e resumo são obrigatórios.';

  @override
  String get newsSaveError => 'Erro ao salvar notícia.';

  @override
  String get newsAddImage => 'Adicionar imagem (opcional)';

  @override
  String get newsFieldTitle => 'Título';

  @override
  String get newsFieldSummary => 'Resumo (exibido na lista)';

  @override
  String get newsFieldContent => 'Conteúdo completo (opcional)';

  @override
  String get newsPublishNow => 'Publicar agora e notificar';

  @override
  String get newsCreate => 'Criar notícia';

  @override
  String get newsNonePublished => 'Nenhuma notícia publicada ainda.';

  @override
  String get newsDetailTitle => 'Notícia';

  @override
  String get commonNew => 'Novo';

  @override
  String get commonPreview => 'Prévia';

  @override
  String get plnTitle => 'Planos de Pagamento';

  @override
  String get plnLoadError => 'Erro ao carregar planos.';

  @override
  String get plnEditTitle => 'Editar Plano';

  @override
  String get plnNewTitle => 'Novo Plano';

  @override
  String get plnNameField => 'Nome do plano *';

  @override
  String get plnMonthlyValueField => 'Valor mensal (R\$) *';

  @override
  String get plnNameRequired => 'Nome é obrigatório.';

  @override
  String get plnInvalidValue => 'Informe um valor mensal válido.';

  @override
  String get plnUpdated => 'Plano atualizado!';

  @override
  String get plnCreated => 'Plano criado!';

  @override
  String get plnSaveError => 'Erro ao salvar plano.';

  @override
  String get plnCreateBtn => 'Criar plano';

  @override
  String get plnDeleteTitle => 'Excluir plano';

  @override
  String plnDeleteBody(String name) {
    return 'Excluir o plano \"$name\"?\nAlunos vinculados não serão afetados.';
  }

  @override
  String get plnDeleted => 'Plano excluído.';

  @override
  String get plnDeleteError => 'Erro ao excluir plano.';

  @override
  String get plnEmpty => 'Nenhum plano cadastrado.';

  @override
  String get plnEmptyHint => 'Crie planos para vincular aos alunos.';

  @override
  String get plnCreateFirst => 'Criar primeiro plano';

  @override
  String plnPerMonth(String value) {
    return 'R\$ $value / mês';
  }

  @override
  String get psvManageTitle => 'Gerenciar Pesquisas';

  @override
  String get psvSatisfactionTitle => 'Pesquisa de Satisfação';

  @override
  String get psvFallbackTitle => 'Pesquisa';

  @override
  String get psvEditTitle => 'Editar pesquisa';

  @override
  String get psvNewTitle => 'Nova pesquisa';

  @override
  String get psvTitleField => 'Título da pesquisa *';

  @override
  String get psvCreateBtn => 'Criar pesquisa';

  @override
  String get psvSaveError => 'Erro ao salvar pesquisa.';

  @override
  String get psvStatusError => 'Erro ao alterar status.';

  @override
  String get psvDeleteTitle => 'Excluir pesquisa?';

  @override
  String psvDeleteBody(String title) {
    return 'Ao excluir \"$title\", os dados de resposta desta pesquisa serão mantidos no histórico, mas o template não estará mais disponível.';
  }

  @override
  String get psvDeleteError => 'Erro ao excluir pesquisa.';

  @override
  String get psvLoadError => 'Erro ao carregar.';

  @override
  String get psvEmpty => 'Nenhuma pesquisa criada ainda';

  @override
  String get psvEmptyHint => 'Toque em \"Nova pesquisa\" para começar';

  @override
  String get psvActiveInfo =>
      'Apenas uma pesquisa pode estar ativa por vez. A pesquisa ativa é exibida para os alunos no mês corrente.';

  @override
  String get psvUntitled => 'Sem título';

  @override
  String get psvActiveBadge => 'ATIVA';

  @override
  String get psvViewResponses => 'Ver respostas';

  @override
  String get psvResponsesLoadError => 'Erro ao carregar respostas.';

  @override
  String psvNoResponsesIn(String month) {
    return 'Nenhuma resposta em $month';
  }

  @override
  String get psvOverallAverage => 'Média geral';

  @override
  String psvResponsesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count respostas',
      one: '$count resposta',
    );
    return '$_temp0';
  }

  @override
  String get psvDistribution => 'Distribuição';

  @override
  String get psvRate1 => 'Muito ruim';

  @override
  String get psvRate2 => 'Ruim';

  @override
  String get psvRate3 => 'Regular';

  @override
  String get psvRate4 => 'Bom';

  @override
  String get psvRate5 => 'Excelente';

  @override
  String psvCommentsCount(int count) {
    return 'Comentários ($count)';
  }

  @override
  String get ctTitle => 'Modelos de Contrato';

  @override
  String get ctNew => 'Novo Modelo';

  @override
  String get ctRemoveTitle => 'Remover Modelo';

  @override
  String ctRemoveBody(String name) {
    return 'Deseja remover \"$name\"?';
  }

  @override
  String get ctRemoveError => 'Erro ao remover modelo';

  @override
  String get ctLoadError => 'Não foi possível carregar';

  @override
  String get ctEmpty => 'Nenhum modelo cadastrado';

  @override
  String get ctEmptyHint => 'Toque em + para criar';

  @override
  String get ctEditTitle => 'Editar Modelo';

  @override
  String get ctNewTitle => 'Novo Modelo de Contrato';

  @override
  String get ctPreview => 'Preview';

  @override
  String get ctNameField => 'Nome do Modelo';

  @override
  String get ctHtmlField => 'Conteúdo HTML';

  @override
  String get ctSaveError => 'Erro ao salvar modelo';

  @override
  String get ctCreateBtn => 'Criar Modelo';

  @override
  String get mdlActivate => 'Ativar';

  @override
  String get mdlDeactivate => 'Desativar';

  @override
  String get mdlDeactivateBody =>
      'Ela deixará de aparecer nas telas de turmas, faixas e cadastro de alunos, mas não será excluída.';

  @override
  String get mdlActivateBody =>
      'Esta modalidade voltará a aparecer em todas as telas operacionais.';

  @override
  String get mdlToggleError => 'Não foi possível alterar a modalidade.';

  @override
  String get mdlLinksCheckError =>
      'Não foi possível verificar os vínculos da modalidade.';

  @override
  String get mdlCannotDeleteTitle => 'Não é possível excluir';

  @override
  String mdlCannotDeleteBody(String name) {
    return 'A modalidade \"$name\" possui turmas ou faixas vinculadas. Você pode desativá-la — assim ela some das telas operacionais sem apagar o histórico.';
  }

  @override
  String mdlDeleteTitle(String name) {
    return 'Excluir \"$name\"?';
  }

  @override
  String get mdlDeleteBody => 'Essa ação não poderá ser desfeita.';

  @override
  String get mdlDeleted => 'Modalidade excluída.';

  @override
  String get mdlDeleteError => 'Não foi possível excluir a modalidade.';

  @override
  String get mdlTitle => 'Modalidades';

  @override
  String get mdlSubtitle => 'Gerencie as modalidades da sua academia.';

  @override
  String get mdlNew => 'Nova modalidade';

  @override
  String get mdlInfoBanner =>
      'Modalidades ativas aparecem na gestão de faixas, turmas e demais telas operacionais.';

  @override
  String get mdlFilterActive => 'Ativas';

  @override
  String get mdlFilterInactive => 'Inativas';

  @override
  String mdlFilterAllCount(int count) {
    return 'Todas ($count)';
  }

  @override
  String mdlFilterActiveCount(int count) {
    return 'Ativas ($count)';
  }

  @override
  String mdlFilterInactiveCount(int count) {
    return 'Inativas ($count)';
  }

  @override
  String get mdlSearchHint => 'Buscar modalidade...';

  @override
  String get mdlSortAZ => 'A–Z';

  @override
  String get mdlSortZA => 'Z–A';

  @override
  String get mdlStatusActive => 'Ativa';

  @override
  String get mdlStatusInactive => 'Inativa';

  @override
  String mdlA11yDeactivate(String name) {
    return 'Desativar modalidade $name';
  }

  @override
  String mdlA11yActivate(String name) {
    return 'Ativar modalidade $name';
  }

  @override
  String get mdlEmpty => 'Nenhuma modalidade cadastrada.';

  @override
  String get mdlEmptyHint => 'Adicione a primeira modalidade da sua academia.';

  @override
  String get mdlNoResults => 'Nenhuma modalidade encontrada.';

  @override
  String get mdlLoadError => 'Não foi possível carregar as modalidades.';

  @override
  String get mdlImageTooLarge => 'Imagem muito grande (máximo 8 MB).';

  @override
  String get mdlImageProcessError => 'Não foi possível processar a imagem.';

  @override
  String get mdlImagePickError => 'Não foi possível selecionar a imagem.';

  @override
  String get mdlSaveError => 'Não foi possível salvar a modalidade.';

  @override
  String get mdlEditTitle => 'Editar Modalidade';

  @override
  String get mdlNewTitle => 'Nova Modalidade';

  @override
  String get mdlNameField => 'Nome da modalidade';

  @override
  String get mdlNameHint => 'Ex.: Jiu-Jitsu Adulto';

  @override
  String get mdlActiveToggle => 'Modalidade ativa';

  @override
  String get mdlActiveToggleSub =>
      'Modalidades inativas não aparecem nas telas operacionais.';

  @override
  String get mdlVisualId => 'Identificação visual';

  @override
  String get mdlDefaultIcon => 'Ícone padrão';

  @override
  String get mdlUploadImage => 'Enviar imagem';

  @override
  String get mdlCreateBtn => 'Criar Modalidade';

  @override
  String get mdlChangeImage => 'Trocar imagem';

  @override
  String get mdlChooseGallery => 'Escolher da galeria';

  @override
  String get mdlImageHint => 'JPG ou PNG. A imagem é recortada em quadrado.';

  @override
  String get fxDeleteTitle => 'Excluir faixa?';

  @override
  String fxDeleteBody(String name) {
    return 'A faixa \"$name\" será removida.';
  }

  @override
  String get fxDeleteError => 'Não foi possível excluir a faixa.';

  @override
  String get fxAboutTitle => 'Sobre as faixas';

  @override
  String get fxAboutBody =>
      'Cada modalidade pode possuir suas próprias faixas e critérios de graduação.';

  @override
  String get fxSelectModality => 'Selecione a modalidade';

  @override
  String get fxNewBelt => 'Nova Faixa';

  @override
  String get fxLoadError => 'Não foi possível carregar as faixas.';

  @override
  String get fxNoModalities => 'Nenhuma modalidade cadastrada';

  @override
  String get fxNoModalitiesHint =>
      'Cadastre uma modalidade antes de configurar faixas.';

  @override
  String get fxEmpty => 'Nenhuma faixa cadastrada';

  @override
  String get fxEmptyHint => 'Cadastre a primeira faixa desta modalidade.';

  @override
  String get fxCreateFirst => 'Criar primeira faixa';

  @override
  String get fxTitle => 'Gestão de Faixas';

  @override
  String get fxSubtitle => 'Cadastre e organize as faixas de cada modalidade.';

  @override
  String get fxHelp => 'Ajuda';

  @override
  String get fxModality => 'Modalidade';

  @override
  String fxBeltsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count faixas cadastradas',
      one: '$count faixa cadastrada',
    );
    return '$_temp0';
  }

  @override
  String get fxStudentsInModality => 'Alunos nesta modalidade';

  @override
  String fxMinMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mín. $count meses',
      one: 'Mín. $count mês',
    );
    return '$_temp0';
  }

  @override
  String fxMinAttendances(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mín. $count presenças',
      one: 'Mín. $count presença',
    );
    return '$_temp0';
  }

  @override
  String get fxNoMinReq => 'Sem exigência mínima';

  @override
  String get fxSaveError => 'Não foi possível salvar a faixa.';

  @override
  String get fxEnterZeroOrMore => 'Informe 0 ou mais';

  @override
  String get fxNumbersOnly => 'Somente números';

  @override
  String get fxNotNegative => 'Não pode ser negativo';

  @override
  String get fxEditTitle => 'Editar Faixa';

  @override
  String get fxNameField => 'Nome da Faixa';

  @override
  String get fxNameHint => 'Ex.: Branca, Azul, Roxa...';

  @override
  String get fxOrder => 'Ordem';

  @override
  String get fxInvalid => 'Inválido';

  @override
  String get fxMin1 => 'Mínimo 1';

  @override
  String get fxOrderHint => 'Posição da faixa na progressão da modalidade.';

  @override
  String get fxGradCriteria => 'Critérios para graduação';

  @override
  String get fxMinTimeMonths => 'Tempo mínimo (meses)';

  @override
  String get fxMinTimeMonthsHint => 'Meses de treino antes de graduar.';

  @override
  String get fxMinAttendancesField => 'Presenças mínimas';

  @override
  String get fxMinAttendancesHint => 'Treinos necessários para graduar.';

  @override
  String get fxDescHint => 'Ex.: Observações sobre a faixa...';

  @override
  String get fxBeltColor => 'Cor da Faixa';

  @override
  String get fxCreateBtn => 'Criar Faixa';

  @override
  String get cfgTitle => 'Configurações da Academia';

  @override
  String get cfgSubtitle =>
      'Gerencie as informações e preferências da sua academia.';

  @override
  String get cfgIdentitySection => 'Identidade da Academia';

  @override
  String get cfgIdentitySub => 'Personalize as informações da sua academia.';

  @override
  String get cfgLogo => 'Logo da Academia';

  @override
  String get cfgLogoHasSub => 'Toque para alterar ou remover';

  @override
  String get cfgLogoEmptySub => 'Adicione a logo da academia';

  @override
  String get cfgGeneralInfo => 'Informações Gerais';

  @override
  String get cfgGeneralInfoSub => 'Nome, e-mail, telefone, CNPJ';

  @override
  String get cfgStudentsSection => 'Alunos';

  @override
  String get cfgStudentsSub => 'Configure opções relacionadas aos alunos.';

  @override
  String get cfgBlockCheckin => 'Bloquear check-in por mensalidade vencida';

  @override
  String get cfgBlockCheckinSub =>
      'Impede check-in de alunos com pagamento vencido';

  @override
  String get cfgGraceDays => 'Dias de carência';

  @override
  String get cfgGraceDaysSub => 'Bloqueia após os dias definidos do vencimento';

  @override
  String cfgDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias',
      one: '$count dia',
    );
    return '$_temp0';
  }

  @override
  String get cfgCommSection => 'Comunicação';

  @override
  String get cfgCommSub => 'Personalize as mensagens enviadas aos alunos.';

  @override
  String get cfgReturnMsg => 'Mensagem de retorno (WhatsApp)';

  @override
  String get cfgReturnMsgSub => 'Mensagem para alunos em risco de evasão';

  @override
  String get cfgNewsSub => 'Publicar notícias e comunicados';

  @override
  String get cfgFinanceSection => 'Financeiro';

  @override
  String get cfgFinanceSub => 'Configure cobranças e opções financeiras.';

  @override
  String get cfgPlansSub => 'Criar, editar e excluir planos de mensalidade';

  @override
  String get cfgLateFee => 'Taxa de atraso';

  @override
  String get cfgLateFeeSub => 'Valor extra exibido em cobranças vencidas';

  @override
  String get cfgConfigFee => 'Configurar taxa';

  @override
  String get cfgFeePercentSub => 'Percentual sobre cobranças vencidas';

  @override
  String get cfgFeeFixedSub => 'Valor fixo em cobranças vencidas';

  @override
  String get cfgGradSection => 'Graduações e Modalidades';

  @override
  String get cfgGradSub => 'Configure faixas, graduações e modalidades.';

  @override
  String get cfgBeltsSub => 'Cadastrar e editar graduações por modalidade';

  @override
  String get cfgModalitiesMgmt => 'Gestão de Modalidades';

  @override
  String get cfgModalitiesSub => 'Ativar, desativar ou criar modalidades';

  @override
  String get cfgContractsSub => 'Criar e editar modelos de contrato';

  @override
  String get cfgSurveySub =>
      'Configure pesquisas e acompanhe as respostas dos alunos.';

  @override
  String get cfgSurveyConfig => 'Configurações da pesquisa';

  @override
  String cfgSurveyActiveSub(int xp) {
    return 'Ativa · $xp XP por resposta';
  }

  @override
  String get cfgSurveyInactiveSub => 'Pesquisa mensal desativada';

  @override
  String get cfgSurveyManageSub => 'Criar, ativar e acompanhar pesquisas';

  @override
  String get cfgSurveyAllResponses => 'Ver todas as respostas';

  @override
  String get cfgSurveyAllResponsesSub => 'Avaliações e comentários dos alunos';

  @override
  String get cfgSystemSection => 'Sistema e Legal';

  @override
  String get cfgSystemSub => 'Informações do sistema e documentos legais.';

  @override
  String get cfgSubdomain => 'Subdomínio';

  @override
  String get cfgPrivacy => 'Política de Privacidade';

  @override
  String get cfgPrivacySub => 'Como tratamos seus dados (LGPD)';

  @override
  String get cfgTerms => 'Termos de Uso';

  @override
  String get cfgTermsSub => 'Condições de uso do Sensei Manager';

  @override
  String get cfgAccountSection => 'Conta';

  @override
  String get cfgDangerSection => 'Zona de Perigo';

  @override
  String get cfgSaveToggleError => 'Não foi possível salvar a alteração.';

  @override
  String get cfgInfoSaved => 'Informações salvas.';

  @override
  String get cfgLogoSaved => 'Logo atualizada.';

  @override
  String get cfgMsgSaved => 'Mensagem salva.';

  @override
  String get cfgFeeSaved => 'Taxa de atraso salva.';

  @override
  String get cfgGraceSaved => 'Carência atualizada.';

  @override
  String get cfgSurveySaved => 'Configurações da pesquisa salvas.';

  @override
  String get cfgSubdomainCopied => 'Subdomínio copiado.';

  @override
  String get cfgLoadError => 'Não foi possível carregar as configurações.';

  @override
  String get cfgSaveError => 'Não foi possível salvar as alterações.';

  @override
  String get cfgAcademyName => 'Nome da Academia';

  @override
  String get cfgEmail => 'E-mail';

  @override
  String get cfgPhone => 'Telefone';

  @override
  String get cfgCnpj => 'CNPJ';

  @override
  String get cfgChangeImage => 'Trocar imagem';

  @override
  String get cfgChooseImage => 'Escolher imagem';

  @override
  String get cfgReturnMsgTitle => 'Mensagem de retorno';

  @override
  String get cfgReturnMsgDesc =>
      'Usada ao entrar em contato com alunos que estão há alguns dias sem treinar. Deixe em branco para usar a mensagem padrão do sistema.';

  @override
  String cfgReturnMsgDefault(String nome, String dias) {
    return 'Oi $nome! Sentimos sua falta — faz $dias dias sem treino. Está tudo bem? Qualquer coisa a gente ajuda pra você voltar. 🥋';
  }

  @override
  String cfgReturnMsgHint(String nome, String dias) {
    return 'Oi $nome! Sentimos sua falta — faz $dias dias sem treino...';
  }

  @override
  String get cfgRestoreDefault => 'Restaurar padrão';

  @override
  String get cfgSaveMsg => 'Salvar mensagem';

  @override
  String get cfgLateFeeToggle => 'Cobrar taxa em cobranças vencidas';

  @override
  String get cfgPercent => 'Percentual (%)';

  @override
  String get cfgFixedValue => 'Valor fixo (R\$)';

  @override
  String cfgFeePercentDesc(String value) {
    return 'Será adicionado $value% às cobranças vencidas.';
  }

  @override
  String cfgFeeFixedDesc(String value) {
    return 'Será adicionado R\$ $value às cobranças vencidas.';
  }

  @override
  String get cfgFeePercentLabel => 'Percentual de atraso';

  @override
  String get cfgFeeFixedLabel => 'Valor fixo de atraso';

  @override
  String get cfgGraceDaysDesc =>
      'O check-in do aluno é bloqueado somente após este número de dias do vencimento da mensalidade.';

  @override
  String get cfgSurveyEnable => 'Ativar pesquisa mensal';

  @override
  String get cfgSurveyEnableSub =>
      'Alunos serão convidados a avaliar a academia 1x/mês.';

  @override
  String get cfgSurveyXp => 'XP por resposta';

  @override
  String get cfgSurveyXpSub => 'Pontos concedidos ao aluno após responder.';

  @override
  String get cfgLogout => 'Sair';

  @override
  String get cfgLogoutConfirm => 'Deseja encerrar sua sessão?';

  @override
  String get cfgLogoutBtn => 'Sair da conta';

  @override
  String get cfgDeleteAccountTitle => 'Excluir conta?';

  @override
  String get cfgDeleteAccountBody =>
      'Seus dados pessoais serão removidos permanentemente. Esta ação não pode ser desfeita.';

  @override
  String get cfgDeleteAccountError => 'Erro ao excluir conta. Tente novamente.';

  @override
  String get cfgDeleteAccountBtn => 'Excluir minha conta';

  @override
  String get cfgPlanActive => 'Plano Ativo';

  @override
  String get cfgPlanTrial => 'Trial';

  @override
  String get cfgPlanFree => 'Gratuito';

  @override
  String get cfgPlanProDesc => 'Acesso completo sem anúncios';

  @override
  String get cfgPlanTrialLastDay => 'Último dia do trial!';

  @override
  String cfgPlanTrialDaysLeft(int days) {
    return '$days dias restantes no trial';
  }

  @override
  String get cfgPlanFreeDesc => '3 turmas · 10 alunos/turma · anúncios';

  @override
  String fxStudentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alunos',
      one: '$count aluno',
    );
    return '$_temp0';
  }

  @override
  String get fxZeroNoMin => '0 = sem exigência mínima.';

  @override
  String get authEnterPassword => 'Informe sua senha.';

  @override
  String get authErrUserNotFound =>
      'Usuário não encontrado no sistema. Contate o administrador.';

  @override
  String get authErrDbNotConfigured =>
      'Banco de dados ainda não configurado. Contate o administrador.';

  @override
  String get authErrNoPermission =>
      'Sem permissão para acessar os dados. Contate o administrador.';

  @override
  String get authFirstTimeUsingApp => 'Acessando o app pela primeira vez';

  @override
  String authErrFirebaseCode(String code) {
    return 'Erro do Firebase ($code)';
  }

  @override
  String get profMyProfile => 'Meu Perfil';

  @override
  String get profUpdated => 'Perfil atualizado!';

  @override
  String get profYourNameHint => 'Seu nome';

  @override
  String get profChangePassword => 'Alterar senha';

  @override
  String get apPhotoSaveError => 'Erro ao salvar foto.';

  @override
  String get apPrimaryBelt => 'Faixa Principal';

  @override
  String get apPrimaryBeltHint => 'Escolha qual graduação exibir no seu perfil';

  @override
  String get apThanksFeedback => 'Obrigado pelo feedback!';

  @override
  String get apRatingRecorded => 'Sua avaliação foi registrada.';

  @override
  String get apSurveyQuestion => 'Como está sendo sua experiência?';

  @override
  String get apTapToRate => 'Toque para avaliar';

  @override
  String get apCommentHint => 'Deixe um comentário (opcional)';

  @override
  String get apSurveySendError =>
      'Erro ao enviar resposta. Verifique sua conexão.';

  @override
  String apSendAndEarnXp(int xp) {
    return 'Enviar e ganhar +$xp XP';
  }

  @override
  String get apSendRating => 'Enviar avaliação';

  @override
  String get apEditProfile => 'Editar Perfil';

  @override
  String get apFullName => 'Nome completo';

  @override
  String get apCertPending => 'Atestado médico pendente';

  @override
  String get apCertRejected => 'Atestado rejeitado — envie um novo';

  @override
  String get apCertExpired => 'Atestado expirado — envie um novo';

  @override
  String get apCertExpiringSoon => 'Atestado vencendo em breve';

  @override
  String get apLogoutTitle => 'Sair da conta?';

  @override
  String get apLogoutBody =>
      'Você precisará entrar novamente para acessar o app.';

  @override
  String get apQrAttendance => 'QR Presença';

  @override
  String get apSwitchProfile => 'Trocar perfil';

  @override
  String get apSwitchShort => 'Trocar';

  @override
  String apOverdueCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count atrasadas',
      one: '1 atrasada',
    );
    return '$_temp0';
  }

  @override
  String apPendingCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pendentes',
      one: '1 pendente',
    );
    return '$_temp0';
  }

  @override
  String get apTapToChoose => 'Toque para escolher';

  @override
  String get apTuitionOverdue => 'Mensalidade em atraso';

  @override
  String get apTuitionOverdueHint => 'Toque para ver detalhes e regularizar.';

  @override
  String get apTapToResolve => 'Toque para resolver';

  @override
  String get apRateYourExperience => 'Avalie sua experiência!';

  @override
  String apEarnXpMonthlySurvey(int xp) {
    return 'Ganhe +$xp XP respondendo a pesquisa do mês';
  }

  @override
  String get apMyClasses => 'Minhas turmas';

  @override
  String get apNoClasses => 'Nenhuma turma matriculada.';

  @override
  String apAttendancesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count presenças',
      one: '$count presença',
    );
    return '$_temp0';
  }

  @override
  String get apEditData => 'Editar dados';

  @override
  String get apEditDataHint => 'Nome, contato e informações pessoais';

  @override
  String get apResetPasswordHint => 'Trocar sua senha de acesso';

  @override
  String get apParqDone => 'Questionário de saúde respondido';

  @override
  String get apParqPending => 'Questionário de saúde pendente';

  @override
  String get apLogoutHint => 'Encerrar a sessão neste dispositivo';

  @override
  String get apLegal => 'Legal';

  @override
  String get apPrivacyHint => 'Como seus dados são tratados';

  @override
  String get apTermsHint => 'Regras e condições de uso do app';

  @override
  String get apDeleteAccountSection => 'Excluir conta';

  @override
  String get apDeleteAccountHint => 'Remove seus dados permanentemente';

  @override
  String apXpAdded(int xp) {
    return '+$xp XP adicionados ao seu perfil.';
  }

  @override
  String get navLessons => 'Aulas';

  @override
  String get navPromotions => 'Graduações';

  @override
  String get navProfile => 'Perfil';

  @override
  String get peseiTagline => 'Seu parceiro de saúde e bem-estar';

  @override
  String get peseiFreeBadge => 'Gratuito · iOS & Android';

  @override
  String get peseiFeatWeightTitle => 'Controle de Peso';

  @override
  String get peseiFeatWeightSub =>
      'Acompanhe ganhos e perdas com gráficos e histórico';

  @override
  String get peseiFeatWaterTitle => 'Hidratação Diária';

  @override
  String get peseiFeatWaterSub =>
      'Meta de consumo de água personalizada com alertas';

  @override
  String get peseiFeatMedsTitle => 'Medicamentos';

  @override
  String get peseiFeatMedsSub =>
      'Lembretes para não esquecer seus remédios e suplementos';

  @override
  String get peseiFeatProgressTitle => 'Evolução Visual';

  @override
  String get peseiFeatProgressSub =>
      'Gráficos de progresso para manter o foco nos seus objetivos';

  @override
  String get peseiDownloadFree => 'Baixar gratuitamente';

  @override
  String get peseiFreeShort => 'GRÁTIS';

  @override
  String get peseiCardTagline => 'Controle de peso, água e saúde';

  @override
  String get peseiSeeApp => 'Ver app';

  @override
  String get commonTomorrow => 'Amanhã';

  @override
  String get apClassFallback => 'Aula';

  @override
  String get apMyLessons => 'Minhas aulas';

  @override
  String get apMyAttendance => 'Minha frequência';

  @override
  String get apMyPromotions => 'Minhas graduações';

  @override
  String get apAttendanceQr => 'QR de presença';

  @override
  String get apNextClass => 'Próxima aula';

  @override
  String get apCurrentGrad => 'Graduação atual';

  @override
  String get apJourneyStarts => 'Sua trajetória começa aqui.';

  @override
  String get apJourneyContinues => 'Sua jornada continua aqui.';

  @override
  String get apHello => 'Olá!';

  @override
  String apHelloName(String name) {
    return 'Olá, $name!';
  }

  @override
  String get apNotifications => 'Notificações';

  @override
  String get apNoClassToday => 'Nenhuma aula programada para hoje.';

  @override
  String apProfPrefix(String name) {
    return 'Prof. $name';
  }

  @override
  String get apWeekAttendance => 'Frequência esta semana';

  @override
  String get apTuitionOk => 'Mensalidade em dia';

  @override
  String get apTuitionOkSub => 'Sem pendências no momento.';

  @override
  String get apTuitionPending => 'Mensalidade pendente';

  @override
  String get apTuitionNeedsAttention =>
      'Há uma mensalidade que precisa de atenção.';

  @override
  String get apNoCharges => 'Nenhuma cobrança';

  @override
  String get apNoChargesSub => 'Nada em aberto por aqui.';

  @override
  String apWorkoutsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count treinos',
      one: '1 treino',
    );
    return '$_temp0';
  }

  @override
  String apAbsencesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count faltas',
      one: '1 falta',
    );
    return '$_temp0';
  }

  @override
  String get apNoClassOnDay => 'Sem aulas nesse dia';

  @override
  String get apMyLessonsUpper => 'MINHAS AULAS';

  @override
  String get apOtherLessonsUpper => 'OUTRAS AULAS';

  @override
  String get apExamApproved => 'Aprovado';

  @override
  String get apExamFailed => 'Reprovado';

  @override
  String get apPromotionHistory => 'Histórico de Graduações';

  @override
  String get apCurrentBeltsUpper => 'FAIXAS ATUAIS';

  @override
  String get apHistoryUpper => 'HISTÓRICO';

  @override
  String get apNoPromotions => 'Nenhuma graduação registrada';

  @override
  String get apNoPromotionsSub => 'Seu histórico de faixas aparecerá aqui.';

  @override
  String get apChargeFallback => 'Cobrança';

  @override
  String get apOutstanding => 'Em aberto';

  @override
  String get apAllPaid => 'Em dia!';

  @override
  String apAmountToSettle(String value) {
    return '$value a regularizar';
  }

  @override
  String get apNoPendingNow => 'Sem pendências no momento';

  @override
  String get apChargesUpper => 'COBRANÇAS';

  @override
  String apDueDatePrefix(String date) {
    return 'Vencimento: $date';
  }

  @override
  String get apContactSecretary =>
      'Entre em contato com a secretaria para regularizar.';

  @override
  String get apNoChargesInCategory => 'Nenhuma cobrança nessa categoria';

  @override
  String get apAttendanceTitle => 'Presenças';

  @override
  String get apTrainingHistory => 'Seu histórico de treinos';

  @override
  String get apTotalWorkouts => 'Total de treinos';

  @override
  String get apAttendanceLabel => 'Presenças';

  @override
  String get apAbsencesLabel => 'Faltas';

  @override
  String get apNoAbsences => 'Nenhuma falta registrada. Mandou bem!';

  @override
  String get apNoAttendanceYet => 'Nenhuma presença registrada ainda';

  @override
  String get apNothingHereYet => 'Nada por aqui ainda';

  @override
  String get apAbsence => 'Falta';

  @override
  String get apPresent => 'Presente';

  @override
  String get apCertTitle => 'Atestado Médico';

  @override
  String get apCertNoneSent => 'Nenhum atestado enviado';

  @override
  String get apCertSendHint =>
      'Envie seu atestado médico para que a academia possa verificar.';

  @override
  String apCertValidUntil(String date) {
    return 'Válido até: $date';
  }

  @override
  String apCertReasonPrefix(String reason) {
    return 'Motivo: $reason';
  }

  @override
  String get apCertExpiringSoonSendNew => 'Vencendo em breve! Envie um novo.';

  @override
  String get apCertSendNew => 'Enviar novo atestado';

  @override
  String get apCertSend => 'Enviar atestado';

  @override
  String get apCertSentToast =>
      'Atestado enviado! Aguarde a aprovação da academia.';

  @override
  String get apCertSendError => 'Erro ao enviar. Tente novamente.';

  @override
  String get apNotAuthenticated => 'Usuário não autenticado.';

  @override
  String get apParqInstruction =>
      'Questionário de Prontidão para Atividade Física. Por favor responda \"Sim\" ou \"Não\" às perguntas abaixo.';

  @override
  String get apParqFullNameReq => 'Nome completo *';

  @override
  String get apParqSignSend => 'Assinar e enviar PAR-Q';

  @override
  String get apAchievements => 'Conquistas';

  @override
  String get apNoAchievements => 'Nenhuma conquista ainda.';

  @override
  String get apLevel => 'Nível';

  @override
  String get apStreak => 'Sequência';

  @override
  String apThisMonthXp(int xp) {
    return 'Este mês: $xp XP';
  }

  @override
  String apNextLevelXp(int xp) {
    return 'Próx. nível: $xp XP';
  }

  @override
  String get apMyProfile => 'Meu Perfil';

  @override
  String get apRankNoPeriodData => 'Sem dados para este período';

  @override
  String get apRankTrainMore => 'Treine mais para aparecer no ranking!';

  @override
  String get apRankingsTitle => 'Rankings';

  @override
  String get apQrMyCode => 'Meu QR Code';

  @override
  String get apQrScanAcademy => 'Escanear Academia';

  @override
  String get apQrShowInstructor => 'Apresente ao professor na entrada';

  @override
  String get apQrGenFailed => 'Não foi possível gerar o QR Code';

  @override
  String get apQrShowInstructorLong =>
      'Apresente este QR Code ao professor para registrar sua presença.';

  @override
  String get apQrCheckinSuccess => 'Presença registrada com sucesso!';

  @override
  String get apQrCheckinError => 'Erro ao registrar presença.';

  @override
  String get apQrCheckingIn => 'Registrando presença...';

  @override
  String get apQrScanAgain => 'Escanear novamente';

  @override
  String get apQrPointAtAcademy =>
      'Aponte para o QR Code da academia na entrada';

  @override
  String get apYourBeltHistory => 'Seu histórico de faixas';

  @override
  String get navSchedule => 'Horários';

  @override
  String get profNewsAcademy => 'Notícias da Academia';

  @override
  String get profAreaTitle => 'Área do Professor';

  @override
  String get profPanelSubtitle => 'Painel do professor';

  @override
  String get profQuickAccess => 'Acessos rápidos';

  @override
  String get profTodayClasses => 'Aulas de hoje';

  @override
  String get profNoClassToday => 'Nenhuma aula hoje.';

  @override
  String get profSeeMyClasses => 'Ver minhas turmas';

  @override
  String profAlsoTrainsIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Você também treina em $count turmas',
      one: 'Você também treina em 1 turma',
    );
    return '$_temp0';
  }

  @override
  String get profMySchedule => 'Meus Horários';

  @override
  String get profNoScheduleFound => 'Nenhum horário encontrado.';

  @override
  String get profMyClasses => 'Minhas Turmas';

  @override
  String get profNoClassesAssigned => 'Nenhuma turma atribuída';

  @override
  String get profNoStudentsEnrolled => 'Nenhum aluno matriculado';

  @override
  String get profPromotionRecorded => 'Graduação registrada!';

  @override
  String get profPromotion => 'Graduação';

  @override
  String get profAttendanceError => 'Erro ao registrar.';

  @override
  String get profRemoveAttendance => 'Remover presença';

  @override
  String profRemoveAttendanceBody(String name, String date) {
    return 'Deseja remover a presença de $name em $date?';
  }

  @override
  String get profScanQr => 'Escanear QR Code';

  @override
  String get profMarkWhoPresent => 'Marque quem esteve presente';

  @override
  String get profAttendanceMarkedTapRemove =>
      'Presença registrada · toque para remover';

  @override
  String profRegisterNAttendance(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Registrar $count presenças',
      one: 'Registrar 1 presença',
    );
    return '$_temp0';
  }

  @override
  String get profManual => 'Manual';

  @override
  String profRemoveAttendanceThisClass(String name) {
    return 'Deseja remover a presença de $name nesta aula?';
  }

  @override
  String get profChange => 'Alterar';

  @override
  String get profNoAttendanceThisClass => 'Nenhuma presença nesta aula';

  @override
  String get profTapChangeDate => 'Toque em \"Alterar\" para mudar a data';

  @override
  String get profAbsentPending => 'Pendente';

  @override
  String get rkStudentsAppearHere =>
      'Alunos aparecem aqui conforme registram presenças.';

  @override
  String get commonCantOpenWhatsapp => 'Não foi possível abrir o WhatsApp.';

  @override
  String get evasaoRiskTitle => 'Risco de evasão';

  @override
  String get evasaoNobodyAtRisk => 'Ninguém em risco de evasão agora. 🎉';

  @override
  String get evasaoCallWhatsapp => 'Chamar no WhatsApp';

  @override
  String evasaoDefaultMsg(String nome, String dias) {
    return 'Oi $nome! Sentimos sua falta nos treinos — faz $dias dias que você não aparece. Está tudo bem? Qualquer coisa que a gente possa fazer pra te ajudar a voltar, é só falar. 🥋';
  }

  @override
  String get birthdaysTitle => 'Aniversariantes';

  @override
  String get birthdaysCurrentMonth => 'Mês atual';

  @override
  String birthdaysNoneInMonth(String month) {
    return 'Nenhum aniversariante em $month';
  }

  @override
  String get stfEditMember => 'Editar membro';

  @override
  String get stfRoleOptional => 'Cargo (opcional)';

  @override
  String get stfProfile => 'Perfil';

  @override
  String get stfScreens => 'Telas';

  @override
  String get stfActions => 'Ações';

  @override
  String get stfAdvancedAccess => 'Acesso avançado';

  @override
  String get stfMemberUpdated => 'Membro atualizado!';

  @override
  String get stfUpdateError => 'Erro ao atualizar.';

  @override
  String get stfRemoveFromTeam => 'Remover da equipe';

  @override
  String stfRemoveConfirm(String name) {
    return 'Remover $name da equipe?';
  }

  @override
  String get stfMemberRemoved => 'Funcionário removido.';

  @override
  String get stfRemoveError => 'Não foi possível remover.';

  @override
  String get stfEmpty => 'Nenhum funcionário cadastrado.';

  @override
  String get stfLoadError => 'Erro ao carregar equipe.';

  @override
  String get stfActiveAccessWarning =>
      'Este membro já tem acesso ativo ao app. Alterar e-mail/telefone aqui NÃO muda a senha nem o login dele. Use \"Redefinir senha\" se for necessário.';

  @override
  String get stfCreateError => 'Erro ao cadastrar funcionário.';

  @override
  String get stfLinkProfiles => 'Vincular perfis?';

  @override
  String get stfPhoneBelongsTo => 'Esse telefone já pertence a:';

  @override
  String get stfLinkStaffQuestion =>
      'Deseja vincular esse cadastro de funcionário ao mesmo contato? A pessoa poderá trocar entre os dois perfis dentro do app, pelo menu lateral.';

  @override
  String get stfLinkAlso => 'Vincular também';

  @override
  String get stfNewStaff => 'Novo Funcionário';

  @override
  String get stfPersonalData => 'Dados pessoais';

  @override
  String get stfFullNameReq => 'Nome completo *';

  @override
  String get stfPhoneReq => 'Telefone *';

  @override
  String get stfTempPasswordNote =>
      'Ao cadastrar, geramos uma senha temporária para você repassar. A pessoa entra com o telefone ou e-mail + essa senha e o app pede para criar a senha definitiva — sem \"primeiro acesso\".';

  @override
  String get stfRoleAndProfile => 'Cargo e perfil';

  @override
  String get stfRoleExample => 'Cargo (ex: Professor de BJJ)';

  @override
  String get stfPermissions => 'Permissões';

  @override
  String get stfPermissionsHint =>
      'Defina o que esse funcionário pode acessar e fazer no aplicativo.';

  @override
  String get stfCreateStaff => 'Cadastrar funcionário';

  @override
  String get stfVisibleScreens => 'Telas visíveis';

  @override
  String get stfAllowedActions => 'Ações permitidas';

  @override
  String get stfRequiredField => 'Campo obrigatório';

  @override
  String get famLoadError => 'Erro ao carregar grupos.';

  @override
  String get famNewGroup => 'Novo Grupo Familiar';

  @override
  String get famGroupNameHint => 'Nome do grupo (ex: Família Silva)';

  @override
  String get famCreate => 'Criar';

  @override
  String get famCreateError => 'Erro ao criar grupo.';

  @override
  String get famRename => 'Renomear Grupo';

  @override
  String get famRenameError => 'Erro ao renomear.';

  @override
  String get famDeleteTitle => 'Excluir grupo?';

  @override
  String get famDeleteBody =>
      'Os membros serão desvinculados mas não excluídos.';

  @override
  String get famDeleteError => 'Erro ao excluir.';

  @override
  String get famRemoveMemberError => 'Erro ao remover membro.';

  @override
  String get famTitle => 'Grupos Familiares';

  @override
  String get famNewGroupShort => 'Novo grupo';

  @override
  String get famEmpty => 'Nenhum grupo familiar criado.';

  @override
  String get famEmptyHint =>
      'Crie grupos para vincular membros da mesma família.';

  @override
  String get famCreateGroup => 'Criar grupo';

  @override
  String get famRenameShort => 'Renomear';

  @override
  String get famRemoveFromGroup => 'Remover do grupo';

  @override
  String get famNoMembers => 'Nenhum membro. Adicione via detalhes do aluno.';

  @override
  String get acCreateError => 'Erro ao cadastrar aluno. Verifique os dados.';

  @override
  String get acCreateAnywayBody =>
      'Deseja cadastrar mesmo assim?\nAo fazer o primeiro acesso com esse contato, o aluno poderá escolher entre os perfis (grupo familiar).';

  @override
  String get acCreateAnyway => 'Cadastrar mesmo assim';

  @override
  String get acLinkStudentQuestion =>
      'Deseja vincular esse cadastro de Aluno ao mesmo contato? A pessoa poderá trocar entre os perfis dentro do app.';

  @override
  String get acNewStudent => 'Novo Aluno';

  @override
  String get acFullNameReq => 'Nome completo *';

  @override
  String get acBirthDate => 'Data de nascimento';

  @override
  String get acMinor => 'Menor de idade';

  @override
  String get acGuardianName => 'Nome do responsável';

  @override
  String get acGuardianPhone => 'Telefone do responsável';

  @override
  String get acSelectPlanOptional => 'Selecionar plano (opcional)';

  @override
  String get acAppAccessNote =>
      'Ao cadastrar (com acesso liberado e telefone ou e-mail), geramos uma senha temporária para você repassar ao aluno. Ele entra digitando o telefone ou e-mail cadastrado + essa senha, e o app pede para criar a senha definitiva. Não é necessário \"primeiro acesso\".';

  @override
  String get acAccessAllowed => 'Acesso ao app liberado';

  @override
  String get acAccessBlocked => 'Acesso ao app bloqueado';

  @override
  String get acCanLogin => 'Aluno poderá fazer login normalmente';

  @override
  String get acCannotLogin => 'Aluno não conseguirá entrar no app';

  @override
  String get acCreateStudent => 'Cadastrar aluno';

  @override
  String get acRequiredField => 'Campo obrigatório';
}
