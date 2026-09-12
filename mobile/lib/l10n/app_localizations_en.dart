// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTagline => 'Smart management for martial arts academies';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonBack => 'Back';

  @override
  String get commonNext => 'Next';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonClose => 'Close';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonUnderstood => 'Got it';

  @override
  String get commonRequiredField => 'Required';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonGenericError => 'Something went wrong. Please try again.';

  @override
  String get commonNoConnection => 'No internet connection.';

  @override
  String commonMinChars(int count) {
    return 'At least $count characters';
  }

  @override
  String get commonPasswordsDontMatch => 'Passwords don\'t match';

  @override
  String get commonInvalidEmail => 'Invalid email address';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get commonSeeAll => 'See all';

  @override
  String get commonSeeAllFem => 'See all';

  @override
  String get commonDescriptionOptional => 'Description (optional)';

  @override
  String get commonSaveError => 'Couldn\'t save. Please try again.';

  @override
  String get commonEnterValidValue => 'Enter a valid amount';

  @override
  String get dashHello => 'Hello!';

  @override
  String dashHelloName(String name) {
    return 'Hi, $name!';
  }

  @override
  String get dashYourAcademyToday => 'Your academy today';

  @override
  String get dashActiveStudents => 'Active students';

  @override
  String get dashActiveClasses => 'Active classes';

  @override
  String get dashAttendanceToday => 'Check-ins today';

  @override
  String get dashOverdueAccounts => 'Overdue';

  @override
  String get dashQuickActions => 'Quick actions';

  @override
  String get dashNewStudent => 'New student';

  @override
  String get dashNewClass => 'New class';

  @override
  String get dashMarkAttendance => 'Mark attendance';

  @override
  String get dashTrialActive => 'Free trial active';

  @override
  String get dashTrialLastDay => 'Last day of the trial!';

  @override
  String dashTrialDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days left',
      one: '1 day left',
    );
    return '$_temp0';
  }

  @override
  String get dashSeePlans => 'View plans';

  @override
  String get dashFreePlan => 'Free plan';

  @override
  String get dashFreePlanLimits => 'Limit: 3 classes · 10 students/class · ads';

  @override
  String get dashSubscribePro => 'Get PRO';

  @override
  String get dashGettingStarted => 'Getting started';

  @override
  String get dashGettingStartedSubtitle => 'Set up your academy step by step';

  @override
  String get dashStepModality => 'Create a discipline';

  @override
  String get dashStepModalityDesc => 'E.g. Jiu-Jitsu, Muay Thai, Boxing.';

  @override
  String get dashStepPlan => 'Create a membership plan';

  @override
  String get dashStepPlanDesc => 'Set amounts and billing period.';

  @override
  String get dashStepInstructor => 'Add an instructor';

  @override
  String get dashStepInstructorDesc => 'Classes need an instructor in charge.';

  @override
  String get dashStepClass => 'Set up a class';

  @override
  String get dashStepClassDesc => 'Group students by discipline and schedule.';

  @override
  String get dashStepFirstStudent => 'Add your first student';

  @override
  String get dashStepFirstStudentDesc =>
      'Add students and enroll them in classes.';

  @override
  String get dashAttendanceWatch => 'Attendance Watch';

  @override
  String dashWatchRedSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count students haven\'t trained in 7+ days',
      one: '1 student hasn\'t trained in 7+ days',
    );
    return '$_temp0';
  }

  @override
  String dashWatchYellowSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count students absent for 7–13 days',
      one: '1 student absent for 7–13 days',
    );
    return '$_temp0';
  }

  @override
  String dashDaysCount(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String dashSeeAllStudents(int count) {
    return 'See all $count students';
  }

  @override
  String get dashOpenListWhatsapp => 'Open list (message on WhatsApp)';

  @override
  String get dashBirthdays => 'Birthdays';

  @override
  String get dashThisMonth => 'This month';

  @override
  String get dashNearingPromotion => 'Students nearing promotion';

  @override
  String get dashNearingPromotionSubtitle =>
      'Students close to the minimum class count';

  @override
  String get dashNoOneNearingPromotion => 'No students close to a promotion';

  @override
  String dashClassesProgress(int done, int needed) {
    return '$done/$needed classes';
  }

  @override
  String get dashEligible => 'Eligible!';

  @override
  String get dashLatestNews => 'Latest news';

  @override
  String get dashNewModalityTitle => 'New discipline';

  @override
  String get dashNewModalityHint =>
      'E.g. Jiu-Jitsu, Muay Thai, Boxing, Submission';

  @override
  String get dashModalityNameField => 'Discipline name';

  @override
  String get dashCreateModality => 'Create discipline';

  @override
  String get dashNewPlanTitle => 'New membership plan';

  @override
  String get dashNewPlanSubtitle => 'Set the amount your students will pay.';

  @override
  String get dashPlanNameField => 'Plan name (e.g. Monthly, Quarterly)';

  @override
  String get dashPlanMonthlyValueField => 'Monthly amount (R\$)';

  @override
  String get dashPlanEnrollmentFeeField => 'Enrollment fee (optional)';

  @override
  String get dashCreatePlan => 'Create plan';

  @override
  String get dashWeeklyFrequency => 'Weekly attendance';

  @override
  String get dashLast7Days => 'Last 7 days';

  @override
  String get dashNoAttendance7Days =>
      'No attendance recorded in the last 7 days.';

  @override
  String dashTotalCount(int count) {
    return '$count total';
  }

  @override
  String get navHome => 'Home';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navStudents => 'Students';

  @override
  String get navClasses => 'Classes';

  @override
  String get navStaff => 'Staff';

  @override
  String get navBilling => 'Billing';

  @override
  String get navRanking => 'Ranking';

  @override
  String get navMore => 'More';

  @override
  String get menuSectionMain => 'MAIN';

  @override
  String get menuSectionOther => 'OTHER';

  @override
  String get menuSectionAccount => 'ACCOUNT';

  @override
  String get menuNews => 'News';

  @override
  String get menuSettings => 'Settings';

  @override
  String get menuSignOut => 'Sign out';

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get roleStudent => 'Student';

  @override
  String get roleTeacher => 'Instructor';

  @override
  String get roleSecretary => 'Front desk';

  @override
  String get psTitle => 'Switch profile';

  @override
  String get psSubtitle => 'Choose who\'s using the app right now';

  @override
  String get psInUse => 'In use';

  @override
  String get psAccess => 'Open';

  @override
  String get adminPanelSubtitle => 'Management panel';

  @override
  String get signOutConfirmTitle => 'Sign out?';

  @override
  String get signOutConfirmBody =>
      'You\'ll need to sign in again to use the app.';

  @override
  String get settingsAppearanceSection => 'Appearance & language';

  @override
  String get settingsAppearanceSubtitle => 'Adjust the app theme and language.';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsLanguageSheetTitle => 'Language';

  @override
  String get settingsThemeSheetTitle => 'Theme';

  @override
  String get settingsOptionSystem => 'Automatic';

  @override
  String get settingsOptionSystemLanguageHint => 'Follows the device language';

  @override
  String get settingsOptionSystemThemeHint => 'Follows the device theme';

  @override
  String get settingsLanguagePt => 'Português (Brasil)';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get authWelcomeChooseAccess =>
      'Welcome — choose how you\'d like to sign in';

  @override
  String get authIAmStudentOrGuardianTitle => 'I\'m a student or guardian';

  @override
  String get authIAmStudentOrGuardianSubtitle =>
      'Training, belt promotions, billing and ID card';

  @override
  String get authIAmAcademyTitle => 'I\'m an academy';

  @override
  String get authIAmAcademySubtitle =>
      'Manage students, classes, staff and billing';

  @override
  String get authEmailOrPhone => 'Email or phone';

  @override
  String get authPassword => 'Password';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authForgotPassword => 'Forgot password';

  @override
  String get authFirstTimeAccess => 'First-time access';

  @override
  String get authCreateAcademy => 'Create an academy';

  @override
  String get authAccessAcademyPanel => 'Access your academy dashboard';

  @override
  String get authAccessStudentAccount =>
      'Access your student or guardian account';

  @override
  String get authEnterEmailOrPhone => 'Enter your email or phone number.';

  @override
  String get authInvalidEmailShort => 'Invalid email address.';

  @override
  String get authInvalidPhoneExample =>
      'Invalid phone number. Ex: (11) 99999-0000';

  @override
  String get authWhichProfile => 'Which profile would you like to open?';

  @override
  String get authSigningIn => 'Signing in...';

  @override
  String get authLoadingYourData => 'Loading your data...';

  @override
  String get authAlmostThere => 'Almost there...';

  @override
  String get authErrWrongCredentials =>
      'Incorrect email or password. If you\'ve never signed in through the app, use \"Forgot password\" to set your password.';

  @override
  String get authErrAccountDisabled => 'This account is disabled.';

  @override
  String get authErrTooManyRequests =>
      'Too many attempts. Please wait a few minutes and try again.';

  @override
  String get authErrNetwork => 'No internet connection.';

  @override
  String get authErrGenericSignIn =>
      'Sign-in error. Check your details and try again.';

  @override
  String get authErrTimeout =>
      'Request timed out. Check your connection and try again.';

  @override
  String get authErrProfileNotFound => 'Student profile not found.';

  @override
  String get authErrAccountInactive =>
      'Your account is inactive. Please contact the front desk.';

  @override
  String get authErrAppAccessSuspended =>
      'Your app access is suspended. Please contact the front desk.';

  @override
  String get authErrBlockedOverdue =>
      'Access blocked: overdue membership fee. Settle your payment and try again.';

  @override
  String get forgotTitle => 'Forgot password';

  @override
  String get forgotHeadline => 'Recover access';

  @override
  String get forgotInstruction =>
      'Enter your email and we\'ll send a link to create a new password.';

  @override
  String get forgotEmailLabel => 'Email';

  @override
  String get forgotEmailHint => 'you@email.com';

  @override
  String get forgotSendButton => 'Send recovery link';

  @override
  String get forgotSentTitle => 'Email sent!';

  @override
  String get forgotSentBody =>
      'Check your inbox (and spam folder). Tap the link to create your new password.';

  @override
  String get forgotErrEmailNotFound => 'No account found with that email.';

  @override
  String get forgotErrInvalidEmail => 'Invalid email address.';

  @override
  String get forgotErrTooManyRequests =>
      'Too many attempts. Please wait a few minutes.';

  @override
  String get forgotErrSendFailed =>
      'Couldn\'t send the email. Please try again.';

  @override
  String get forgotErrUnexpected => 'Unexpected error. Please try again.';

  @override
  String get changePwTitle => 'Change Password';

  @override
  String get changePwHint =>
      'Use at least 6 characters with letters and numbers.';

  @override
  String get changePwCurrentLabel => 'Current password';

  @override
  String get changePwCurrentHint => 'Enter your current password';

  @override
  String get changePwNewLabel => 'New password';

  @override
  String get changePwNewHint => 'Enter the new password';

  @override
  String get changePwConfirmLabel => 'Confirm new password';

  @override
  String get changePwConfirmHint => 'Repeat the new password';

  @override
  String get changePwMustBeDifferent =>
      'The new password must be different from the current one';

  @override
  String get changePwErrMinLength => 'Minimum 6 characters';

  @override
  String get changePwErrMismatch => 'Passwords don\'t match';

  @override
  String get changePwSuccess => 'Password changed successfully!';

  @override
  String get changePwErrWrongCurrent => 'Current password is incorrect.';

  @override
  String get changePwErrWeak => 'The new password is too weak.';

  @override
  String get changePwErrGeneric =>
      'Couldn\'t change the password. Please try again.';

  @override
  String get tsoTitle => 'Set your permanent password';

  @override
  String get tsoSubtitle =>
      'Your gym generated a temporary password for you. Before continuing, set a permanent password that only you know.';

  @override
  String get tsoNewPasswordHint => 'New password';

  @override
  String get tsoConfirmPasswordHint => 'Confirm the new password';

  @override
  String get tsoConfirmButton => 'Save and continue';

  @override
  String get tsoErrSessionExpired => 'Session expired.';

  @override
  String get tsoErrRequiresRecentLogin =>
      'For security, sign out and sign back in with the temporary password before changing it.';

  @override
  String tsoErrGeneric(String codigo) {
    return 'Error setting the new password ($codigo).';
  }

  @override
  String get tsoErrUnexpected => 'Unexpected error. Please try again.';

  @override
  String get fpTitle => 'Forgot my password';

  @override
  String get fpHeading => 'Recover access';

  @override
  String get fpSubtitle =>
      'Enter your email and we\'ll send you a link to create a new password.';

  @override
  String get fpEmailLabel => 'Email';

  @override
  String get fpEmailHint => 'you@email.com';

  @override
  String get fpErrInvalidEmail => 'Enter a valid email.';

  @override
  String get fpErrTooManyRequests =>
      'Too many attempts. Please wait a few minutes.';

  @override
  String get fpErrGeneric => 'Error sending email. Please try again.';

  @override
  String get fpErrUnexpected => 'Unexpected error. Please try again.';

  @override
  String get fpSendButton => 'Send recovery link';

  @override
  String get fpSentTitle => 'Email sent!';

  @override
  String get fpSentBody =>
      'Check your inbox (and spam folder). Click the link you received to create your new password.';

  @override
  String get fpBackToLogin => 'Back to login';

  @override
  String get fpAlunoSubtitle =>
      'Enter your registered phone or email. Your gym will get an alert and generate a new password for you.';

  @override
  String get fpIdentifierLabel => 'Phone or email';

  @override
  String get fpIdentifierHint => '(11) 99999-0000 or you@email.com';

  @override
  String get fpErrInvalidIdentifier => 'Enter a valid phone number or email.';

  @override
  String get fpAlunoSendButton => 'Send request';

  @override
  String get fpRequestSentTitle => 'Request sent!';

  @override
  String get fpRequestSentBody =>
      'If we find your record, your gym has been notified and will generate a new access password for you shortly.';

  @override
  String resetPwDialogTitle(String nome) {
    return 'Reset $nome\'s password?';
  }

  @override
  String get resetPwDialogBody =>
      'A new temporary password will be generated and this person\'s current session will be ended. They\'ll need to use the temporary password to sign in and set a permanent one.';

  @override
  String get resetPwDialogConfirm => 'Reset';

  @override
  String resetPwErrReset(String erro) {
    return 'Couldn\'t reset the password: $erro';
  }

  @override
  String resetPwErrProvision(String erro) {
    return 'Couldn\'t generate access: $erro';
  }

  @override
  String get conflictDialogTitle => 'This phone or email is already in use';

  @override
  String conflictDialogBody(String nome) {
    return 'There\'s already another registration with the same phone/email as $nome, and that person has already signed in and set their own password.\n\n• Keep current password: $nome will sign in with the same password that person already set — nothing changes for whoever already uses the app.\n• Generate new temporary password: replaces access for everyone using that phone/email. Whoever already had their own password will need to set it again on their next login.';
  }

  @override
  String get conflictDialogKeepCurrent => 'Keep current password';

  @override
  String get conflictDialogGenerateNew => 'Generate new temporary';

  @override
  String get linkedDialogTitle => 'Linked';

  @override
  String linkedDialogBody(String nome, String comoEntrar) {
    return '$nome will access the app with $comoEntrar and the password already set by whoever uses this contact. No new password was generated.';
  }

  @override
  String tempPwTitle(String nome) {
    return '$nome\'s temporary password';
  }

  @override
  String get tempPwHint =>
      'Copy or share it now. You can also see this password on the student\'s profile (App Access) until they sign in for the first time.';

  @override
  String tempPwExplainTitle(String nome) {
    return 'Explain to $nome:';
  }

  @override
  String get tempPwStep1 =>
      'Open the app and tap \"I\'m a student or guardian\".';

  @override
  String tempPwStep2(String comoEntrar) {
    return 'Enter $comoEntrar + this temporary password.';
  }

  @override
  String get tempPwStep3 =>
      'The app asks them to set a permanent password — done, no \"first access\" needed.';

  @override
  String get tempPwCopy => 'Copy';

  @override
  String get tempPwShare => 'Share';

  @override
  String get tempPwCopied => 'Password copied.';

  @override
  String tempPwShareText(String nome, String comoEntrar, String senha) {
    return 'Sensei Manager — $nome\'s access\nSign in with $comoEntrar and the temporary password: $senha\nThe app will ask you to set your permanent password.';
  }

  @override
  String get tempPwBoxTitle =>
      'Temporary password — hasn\'t signed in for the first time yet';

  @override
  String get tempPwBoxViewSend => 'View / send';

  @override
  String get tempPwLoginHintFallback => 'the registered phone or email';

  @override
  String tempPwLoginHintWith(String loginHint) {
    return 'the $loginHint';
  }

  @override
  String get studentsSearchHint => 'Search students...';

  @override
  String get studentsEmpty => 'No students found.';

  @override
  String get studentsLoadError => 'Couldn\'t load students.';

  @override
  String get studentNoBelt => 'No belt yet';

  @override
  String get statusActive => 'Active';

  @override
  String get statusInactive => 'Inactive';

  @override
  String get studentsFilterLabel => 'Filter by status';

  @override
  String get studentsFilterAll => 'All';

  @override
  String get notifTitle => 'Notifications';

  @override
  String notifUnreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread',
      one: '1 unread',
    );
    return '$_temp0';
  }

  @override
  String get notifMarkAllRead => 'Mark all';

  @override
  String get notifEmptyTitle => 'No notifications';

  @override
  String get notifEmptySubtitle => 'You\'re all caught up!';

  @override
  String get finUpToDate => 'Up to date';

  @override
  String get finPending => 'Pending';

  @override
  String get finOverdue => 'Overdue';

  @override
  String get medicalCertificateShort => 'Certificate';

  @override
  String stripeLabel(int count) {
    return 'Stripe $count';
  }

  @override
  String get sdTitleFallback => 'Student';

  @override
  String get sdActivate => 'Activate';

  @override
  String get sdDeactivate => 'Deactivate';

  @override
  String get sdNoAccessTitle => 'You don\'t have access to this student.';

  @override
  String get sdNoAccessBody =>
      'You can only open students from your own classes.';

  @override
  String get sdNotFound => 'Student not found.';

  @override
  String get sdLoadError => 'Couldn\'t load the student.';

  @override
  String get sdName => 'Name';

  @override
  String get sdEmail => 'Email';

  @override
  String get sdPhone => 'Phone';

  @override
  String get sdBirthDate => 'Date of birth';

  @override
  String get sdBeltSection => 'Belt';

  @override
  String get sdPromote => 'Promote';

  @override
  String get sdCurrentBelt => 'Current belt';

  @override
  String get sdNoGraduation => 'No promotions yet';

  @override
  String get sdLevelXp => 'Level / XP';

  @override
  String get sdPlanSection => 'Plan';

  @override
  String get sdNoPlan => 'No plan linked.';

  @override
  String get sdMonthlyValue => 'Monthly amount';

  @override
  String get sdDueDate => 'Due date';

  @override
  String sdEveryDayN(Object day) {
    return 'On day $day each month';
  }

  @override
  String get sdAppAccessSection => 'App Access';

  @override
  String get sdAccessBlocked => 'Access blocked';

  @override
  String get sdAccessAllowed => 'Access allowed';

  @override
  String get sdAccessBlockedHint => 'The student can\'t sign in to the app.';

  @override
  String get sdAccessAllowedHint => 'The student can use the app normally.';

  @override
  String get sdResetPassword => 'Reset password';

  @override
  String get sdGenerateAccess => 'Set up app access';

  @override
  String get sdGenerateAccessHint =>
      'Generate a temporary password so the student can sign in directly with their registered phone or email, without first-time access.';

  @override
  String get sdThisStudent => 'this student';

  @override
  String get sdMedicalCertSection => 'Medical Certificate';

  @override
  String get sdCertNone => 'No certificate';

  @override
  String get sdCertPending => 'Awaiting approval';

  @override
  String get sdCertApproved => 'Approved';

  @override
  String get sdCertRejected => 'Rejected';

  @override
  String get sdCertExpired => 'Expired';

  @override
  String get sdCertUnknown => 'Unknown';

  @override
  String get sdValidity => 'Valid until';

  @override
  String get sdReason => 'Reason';

  @override
  String get sdViewCert => 'View certificate';

  @override
  String get sdApprove => 'Approve';

  @override
  String get sdReject => 'Reject';

  @override
  String get sdAttach => 'Attach';

  @override
  String get sdRemind => 'Remind';

  @override
  String get sdRejectReasonTitle => 'Rejection reason';

  @override
  String get sdRejectReasonHint =>
      'e.g. invalid certificate, past its validity...';

  @override
  String get sdFileUnavailable => 'File not available.';

  @override
  String get sdFileOpenFailed => 'Couldn\'t open the file.';

  @override
  String get sdFileOpenError => 'Error opening the file.';

  @override
  String get sdCertApprovedToast => 'Certificate approved!';

  @override
  String get sdCertRejectedToast => 'Certificate rejected.';

  @override
  String get sdCertReminderTitle => 'Medical certificate pending';

  @override
  String get sdCertReminderBody =>
      'Please bring your medical certificate to the academy to settle your enrollment.';

  @override
  String get sdReminderSent => 'Reminder sent to the student!';

  @override
  String get sdReminderError => 'Error sending the reminder.';

  @override
  String get sdFileTooLarge => 'File too large. Max 5 MB.';

  @override
  String get sdCertAttached => 'Certificate attached and approved!';

  @override
  String get sdCertAttachError => 'Error attaching the certificate.';

  @override
  String get sdFamilySection => 'Family Group';

  @override
  String get sdAdd => 'Add';

  @override
  String get sdLeave => 'Leave';

  @override
  String get sdNoFamily => 'Not linked to any family group.';

  @override
  String get sdCreateGroup => 'Create group';

  @override
  String get sdLinkExisting => 'Link existing';

  @override
  String get sdGuardian => 'Guardian';

  @override
  String get sdNoOtherMembers => 'No other members in the group.';

  @override
  String get sdCreateFamilyTitle => 'Create Family Group';

  @override
  String get sdCreateFamilyHint =>
      'The student will be added to the group automatically.';

  @override
  String get sdFamilyNameHint => 'e.g. Silva Family';

  @override
  String get sdCreate => 'Create';

  @override
  String get sdCreateGroupError => 'Error creating the group.';

  @override
  String get sdNoGroupsYet => 'No groups registered yet.';

  @override
  String get sdSelectGroup => 'Select Group';

  @override
  String sdMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get sdLinkGroupError => 'Error linking the group.';

  @override
  String get sdAddMember => 'Add Member';

  @override
  String get sdAddMemberError => 'Error adding the member.';

  @override
  String get sdRemoveMember => 'Remove member';

  @override
  String sdRemoveMemberBody(String name) {
    return 'Remove $name from the group?';
  }

  @override
  String get sdRemoveMemberError => 'Error removing the member.';

  @override
  String get sdLeaveGroup => 'Leave group';

  @override
  String sdLeaveGroupBody(String name) {
    return 'Remove this student from the group \"$name\"?';
  }

  @override
  String get sdLeaveGroupError => 'Error leaving the group.';

  @override
  String get sdSetGuardian => 'Set guardian';

  @override
  String sdSetGuardianBody(String name) {
    return 'Set $name as the group\'s billing guardian?';
  }

  @override
  String get sdSetGuardianError => 'Error setting the guardian.';

  @override
  String get sdView => 'View';

  @override
  String get sdFill => 'Fill out';

  @override
  String get sdParqEmpty => 'PAR-Q not completed.';

  @override
  String get sdParqMedicalRecommended => 'Medical evaluation recommended';

  @override
  String get sdParqNoRisk => 'No risk indicators';

  @override
  String sdParqFilledOn(String date) {
    return 'Completed on $date';
  }

  @override
  String get sdParqFillTitle => 'Complete PAR-Q';

  @override
  String get sdParqEditTitle => 'Edit PAR-Q';

  @override
  String get sdParqInstruction =>
      'Answer \"Yes\" or \"No\" to each question. Completed by the academy on behalf of the student.';

  @override
  String get sdParqQuestionnaire => 'QUESTIONNAIRE';

  @override
  String get sdParqTerm => 'LIABILITY STATEMENT';

  @override
  String get sdParqTermBody =>
      'I declare that I am aware it is advisable to consult a doctor before starting or increasing the intended level of physical activity, and I take full responsibility for engaging in any physical activity without following this recommendation.';

  @override
  String get sdFullNameRequired => 'Full name *';

  @override
  String get sdParqFillNameCpf => 'Fill in name and CPF.';

  @override
  String get sdParqSaved => 'PAR-Q saved successfully!';

  @override
  String get sdParqSaveError => 'Error saving the PAR-Q.';

  @override
  String get sdParqSaveBtn => 'Save PAR-Q';

  @override
  String get sdParqUpdateBtn => 'Update PAR-Q';

  @override
  String get sdParqQ1 =>
      'Has a doctor ever said that you have a heart or blood pressure condition, and that you should only do physical activity supervised by health professionals?';

  @override
  String get sdParqQ2 =>
      'Do you feel chest pain when you do physical activity?';

  @override
  String get sdParqQ3 =>
      'In the past month, have you felt chest pain during physical activity?';

  @override
  String get sdParqQ4 =>
      'Do you experience loss of balance due to dizziness and/or momentary loss of consciousness?';

  @override
  String get sdParqQ5 =>
      'Do you have a bone or joint problem that could be worsened by physical activity?';

  @override
  String get sdParqQ6 =>
      'Are you currently taking any ongoing prescription medication?';

  @override
  String get sdParqQ7 =>
      'Are you receiving any medical treatment for blood pressure or heart conditions?';

  @override
  String get sdParqQ8 =>
      'Are you under any ongoing medical treatment that could be affected by physical activity?';

  @override
  String get sdParqQ9 =>
      'Have you had any surgery that could in some way compromise physical activity?';

  @override
  String get sdParqQ10 =>
      'Do you know of any other reason why physical activity could harm your health?';

  @override
  String get sdGradWhat => 'What would you like to do?';

  @override
  String get sdGiveStripe => 'Add Stripe';

  @override
  String get sdGiveStripeHint => 'Add a stripe on the current belt';

  @override
  String get sdNewBelt => 'New Belt';

  @override
  String get sdNewBeltHint => 'Select a different belt';

  @override
  String get sdSelectModality => 'Select the discipline';

  @override
  String sdSelectBelt(Object mod) {
    return 'Select the belt — $mod';
  }

  @override
  String get sdNoBeltsAvailable => 'No belts available.';

  @override
  String get sdNext => 'Next';

  @override
  String get sdStripe => 'Stripe';

  @override
  String get sdNoStripe => 'No stripe';

  @override
  String get sdObsOptional => 'Note (optional)';

  @override
  String get sdGenerateCharge => 'Create a charge';

  @override
  String get sdChargeAmount => 'Charge amount (R\$)';

  @override
  String get sdPromoteStudent => 'Promote Student';

  @override
  String get sdConfirmPromotion => 'Confirm Promotion';

  @override
  String sdPromotedToast(Object name, Object belt) {
    return '$name promoted to $belt!';
  }

  @override
  String get sdPromoteError => 'Error promoting the student.';

  @override
  String get sdLinkToClass => 'Enroll in a Class';

  @override
  String get sdAlreadyLinked => 'Already enrolled';

  @override
  String sdLinkedToast(Object turma) {
    return 'Enrolled in $turma!';
  }

  @override
  String get sdLinkError => 'Error enrolling.';

  @override
  String get sdLink => 'Enroll';

  @override
  String get sdEditStudent => 'Edit Student';

  @override
  String get sdPersonalData => 'Personal details';

  @override
  String get sdEditAccessWarning =>
      'This student already has active app access. Changing the email/phone here does NOT change their password or login. Use \"Reset password\" if needed.';

  @override
  String get sdCpfOptional => 'CPF (optional)';

  @override
  String get sdBirthDateField => 'Date of birth (DD/MM/YYYY)';

  @override
  String get sdGuardianEmergency => 'Guardian / Emergency';

  @override
  String get sdContactName => 'Contact name';

  @override
  String get sdContactPhone => 'Contact phone';

  @override
  String get sdBillingPlan => 'Billing plan';

  @override
  String get sdSelectPlan => 'Select Plan';

  @override
  String get sdNoPlanOption => 'No plan';

  @override
  String sdPerMonth(String value) {
    return 'R\$ $value / month';
  }

  @override
  String get sdSelectPlanPlaceholder => 'Select a plan';

  @override
  String get sdDueDayField => 'Billing day (1-31)';

  @override
  String get sdNameRequired => 'Name is required.';

  @override
  String get sdPhoneInvalid => 'Invalid phone number.';

  @override
  String get sdStudentUpdated => 'Student updated successfully!';

  @override
  String get sdStudentUpdateError => 'Error updating the student.';

  @override
  String get sdSaveChanges => 'Save changes';

  @override
  String get sdPoints => 'Points';

  @override
  String get sdRankingsHint =>
      'Tap \"Points\" to add points on a custom ranking.';

  @override
  String get sdAddPoints => 'Add Points';

  @override
  String get sdNoManualRankings => 'No ranking with manual points is active.';

  @override
  String get sdPointsAmount => 'Number of points';

  @override
  String sdPointsAddedToast(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count points added successfully!',
      one: '1 point added successfully!',
    );
    return '$_temp0';
  }

  @override
  String get sdPointsError => 'Error adding points.';

  @override
  String get sdEmergencyContact => 'Emergency Contact';

  @override
  String get sdNoClasses => 'Not enrolled in any class.';

  @override
  String get sdBeltHistory => 'Promotion History';

  @override
  String get sdNoBeltHistory => 'No promotions on record.';

  @override
  String get sdRemovePromotionTitle => 'Remove promotion?';

  @override
  String sdRemovePromotionBody(String label) {
    return 'This removes \"$label\" from the promotion history and can\'t be undone.';
  }

  @override
  String get sdPromotionRemoved => 'Promotion removed.';

  @override
  String get sdPromotionRemoveError => 'Error removing the promotion.';

  @override
  String get sdEditPromotion => 'Edit promotion';

  @override
  String get sdBelt => 'Belt';

  @override
  String get sdExamDate => 'Exam date';

  @override
  String get sdDateMask => 'DD/MM/YYYY';

  @override
  String get sdNotesOptional => 'Notes (optional)';

  @override
  String get sdNotes => 'Notes';

  @override
  String get sdDateFormatError => 'Enter the date in DD/MM/YYYY format.';

  @override
  String get sdPromotionUpdated => 'Promotion updated.';

  @override
  String get sdCheckHistory => 'Check the history';

  @override
  String get sdPromotionEditError => 'Error editing the promotion.';

  @override
  String get sdSaveCorrection => 'Save correction';

  @override
  String get sdPhotoError => 'Error saving the photo.';

  @override
  String sdActivateConfirm(Object name) {
    return 'Activate $name?';
  }

  @override
  String sdDeactivateConfirm(Object name) {
    return 'Deactivate $name?';
  }

  @override
  String get sdStatusChangeError => 'Error changing the status.';

  @override
  String sdAllowAccessConfirm(Object name) {
    return 'Allow app access for $name?';
  }

  @override
  String sdBlockAccessConfirm(Object name) {
    return 'Block app access for $name?';
  }

  @override
  String get sdAccessChangeError => 'Error changing access.';

  @override
  String get sdBeltsLoadError =>
      'Couldn\'t load the belts for this discipline.';

  @override
  String get commonMenu => 'Menu';

  @override
  String get classesSubtitle =>
      'Manage your classes and follow your students\' progress.';

  @override
  String get classesSearchHint => 'Search classes...';

  @override
  String get attendanceReport => 'Attendance report';

  @override
  String get classesEmpty => 'No classes found.';

  @override
  String get classesMoreTitle => 'More classes, more stories';

  @override
  String get classesMoreSubtitle =>
      'Add new classes and keep your whole academy organized.';

  @override
  String get classesEmptyState => 'You don\'t have any classes yet.';

  @override
  String get classesCreateFirst => 'Create your first class';

  @override
  String get classesLoadError => 'Couldn\'t load the information.';

  @override
  String get classStatusActive => 'Active';

  @override
  String get classStatusInactive => 'Inactive';

  @override
  String classInstructorPrefix(String name) {
    return 'Instr. $name';
  }

  @override
  String classCapacitySuffix(String cap) {
    return ' / $cap students';
  }

  @override
  String get takeAttendance => 'Take attendance';

  @override
  String get viewDetails => 'View details';

  @override
  String get editClass => 'Edit class';

  @override
  String get noSchedule => 'No schedule set';

  @override
  String scheduleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions',
      one: '1 session',
    );
    return '$_temp0';
  }

  @override
  String get editClassTitle => 'Edit Class';

  @override
  String get newClassTitle => 'New Class';

  @override
  String get classNameField => 'Class name';

  @override
  String get modality => 'Discipline';

  @override
  String get level => 'Level';

  @override
  String get instructorOptional => 'Instructor (optional)';

  @override
  String get noInstructor => 'No instructor';

  @override
  String get maxCapacity => 'Maximum capacity';

  @override
  String get invalidNumber => 'Invalid number';

  @override
  String get classActiveToggle => 'Class active';

  @override
  String get classEditError => 'Error editing the class';

  @override
  String get classCreateError => 'Error creating the class';

  @override
  String get levelBeginner => 'Beginner';

  @override
  String get levelIntermediate => 'Intermediate';

  @override
  String get levelAdvanced => 'Advanced';

  @override
  String get levelAll => 'All levels';

  @override
  String get dowSun => 'Sun';

  @override
  String get dowMon => 'Mon';

  @override
  String get dowTue => 'Tue';

  @override
  String get dowWed => 'Wed';

  @override
  String get dowThu => 'Thu';

  @override
  String get dowFri => 'Fri';

  @override
  String get dowSat => 'Sat';

  @override
  String get attendanceReportTitle => 'Attendance Report';

  @override
  String get noClassesRegistered => 'No classes registered.';

  @override
  String get periodLabel => 'Period';

  @override
  String periodDaysCount(int count) {
    return '$count days';
  }

  @override
  String get periodCustom => 'Custom';

  @override
  String get totalSessions => 'Total sessions';

  @override
  String get avgAttendance => 'Average attendance';

  @override
  String studentAttendanceCount(int count) {
    return 'Student attendance ($count)';
  }

  @override
  String get noSessionsInPeriod =>
      'No sessions recorded in this period.\nSelect another range to see the attendance rate.';

  @override
  String get noStudentsInClass => 'No students enrolled in this class.';

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortAttendanceDesc => 'Highest attendance';

  @override
  String get sortAttendanceAsc => 'Lowest attendance';

  @override
  String get sortNameAsc => 'Name (A–Z)';

  @override
  String get sortNameDesc => 'Name (Z–A)';

  @override
  String presentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count check-ins',
      one: '1 check-in',
    );
    return '$_temp0';
  }

  @override
  String absentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count absences',
      one: '1 absence',
    );
    return '$_temp0';
  }

  @override
  String attendanceA11y(String name, String pct, int present, int absent) {
    return '$name, $pct% attendance, $present check-ins, $absent absences';
  }

  @override
  String get dowFullSun => 'Sunday';

  @override
  String get dowFullMon => 'Monday';

  @override
  String get dowFullTue => 'Tuesday';

  @override
  String get dowFullWed => 'Wednesday';

  @override
  String get dowFullThu => 'Thursday';

  @override
  String get dowFullFri => 'Friday';

  @override
  String get dowFullSat => 'Saturday';

  @override
  String get tdTabAttendance => 'Attendance';

  @override
  String get tdTabSchedule => 'Schedule';

  @override
  String get tdDeleteClass => 'Delete class';

  @override
  String get tdClassNotFound => 'Class not found';

  @override
  String get tdClassLoadError => 'Error loading the class';

  @override
  String get tdClassFallback => 'Class';

  @override
  String get tdEnrolledStudents => 'Enrolled students';

  @override
  String get tdSortPrefix => 'Sort: ';

  @override
  String get tdAddStudent => 'Add student';

  @override
  String get tdDragToReorder => 'Press and drag to reorder';

  @override
  String get tdEligibleToPromote => 'Ready for promotion';

  @override
  String get tdAttendancesLabel => 'check-ins';

  @override
  String get tdSortStudents => 'Sort students';

  @override
  String get tdReorderByDrag => 'Reorder by dragging';

  @override
  String get tdReorderHint => 'Press and drag students to set the class order';

  @override
  String get tdOrderSaved => 'Class order saved.';

  @override
  String get tdOrderSaveError => 'Couldn\'t save the order.';

  @override
  String get tdOrdManual => 'Custom order';

  @override
  String get tdOrdBeltDesc => 'Belt (highest)';

  @override
  String get tdOrdBeltAsc => 'Belt (lowest)';

  @override
  String get tdOrdEnrollOld => 'Enrollment (oldest)';

  @override
  String get tdOrdEnrollNew => 'Enrollment (newest)';

  @override
  String get tdOrdAttendDesc => 'Most check-ins';

  @override
  String get tdOrdAttendAsc => 'Fewest check-ins';

  @override
  String get tdPresentToday => 'Present today';

  @override
  String get tdDayAttendanceRate => 'Attendance rate today';

  @override
  String get tdMarkAll => 'Mark all';

  @override
  String get tdNoStudentsForAttendance =>
      'No students enrolled to take attendance.';

  @override
  String get tdOffScheduleDay => 'Off-schedule day';

  @override
  String tdOffScheduleAllBody(String day) {
    return 'Today isn\'t a scheduled training day for this class. Mark everyone present for $day?';
  }

  @override
  String tdOffScheduleOneBody(String day) {
    return 'Today isn\'t a scheduled training day for this class. Mark attendance for $day anyway?';
  }

  @override
  String get tdConfirmAnyway => 'Confirm anyway';

  @override
  String get tdAttendanceAllMarked => 'Attendance recorded for everyone.';

  @override
  String tdAttendanceSomeFailed(int count) {
    return 'Some weren\'t recorded ($count). Please try again.';
  }

  @override
  String get tdEnrollIdNotFound => 'Enrollment ID not found.';

  @override
  String get tdRemoveStudent => 'Remove student';

  @override
  String tdRemoveStudentBody(String name) {
    return 'Remove $name from this class?';
  }

  @override
  String tdStudentRemoved(String name) {
    return '$name removed from the class.';
  }

  @override
  String get tdRemoveStudentError => 'Error removing the student.';

  @override
  String get tdPresent => 'Present';

  @override
  String get tdMark => 'Mark';

  @override
  String get tdAttendanceMarked => 'Attendance recorded!';

  @override
  String get tdAttendanceMarkError => 'Error recording attendance.';

  @override
  String get tdUndoAttendance => 'Undo attendance';

  @override
  String tdUndoAttendanceBody(String name) {
    return 'Remove $name\'s attendance on this date?';
  }

  @override
  String get tdAttendanceRemoved => 'Attendance removed.';

  @override
  String get tdAttendanceRemoveError => 'Error removing the attendance.';

  @override
  String get tdToday => 'Today';

  @override
  String get tdYesterday => 'Yesterday';

  @override
  String tdWeeklyScheduleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weekly sessions',
      one: '1 weekly session',
    );
    return '$_temp0';
  }

  @override
  String get tdClassSchedule => 'Class schedule';

  @override
  String get tdNewSchedule => 'New session';

  @override
  String get tdNoSchedules => 'No sessions set.';

  @override
  String get tdAddFirstSchedule => 'Add first session';

  @override
  String tdRoomN(String room) {
    return 'Room $room';
  }

  @override
  String get tdListAnd => ' and ';

  @override
  String get tdDeleteScheduleTitle => 'Delete session?';

  @override
  String get tdDeleteScheduleBody =>
      'This session will be removed from the class.';

  @override
  String get tdScheduleRemoveError => 'Error removing the session.';

  @override
  String get tdEditScheduleTitle => 'Edit Session';

  @override
  String get tdNewScheduleTitle => 'New Session';

  @override
  String get tdWeekday => 'Day of the week';

  @override
  String get tdWeekdays => 'Days of the week';

  @override
  String get tdStart => 'Start';

  @override
  String get tdRoomOptional => 'Room (optional)';

  @override
  String get tdSelectDayAndTime => 'Select at least one day and the times.';

  @override
  String get tdScheduleEditError => 'Error editing the session.';

  @override
  String get tdScheduleCreateError => 'Error creating the session.';

  @override
  String get tdEnrollStudent => 'Enroll student';

  @override
  String get tdNoStudentsAvailable => 'No students available.';

  @override
  String get tdEnrollError => 'Error enrolling the student.';

  @override
  String get tdThisClass => 'this class';

  @override
  String tdDeleteClassConfirm(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get tdDeleteClassBody =>
      'The class disappears from active lists and open enrollments are closed. Students, attendance and promotions stay in the history — nothing is deleted.';

  @override
  String tdClassDeletedWithEnroll(int count) {
    return 'Class deleted. $count enrollment(s) closed.';
  }

  @override
  String get tdClassDeleted => 'Class deleted.';

  @override
  String get tdClassDeleteError => 'Error deleting the class.';

  @override
  String get tdClassQrTitle => 'Class QR Code';

  @override
  String get tdQrSubtitle => 'Students scan it to check in';

  @override
  String get tdQrValidity => 'Valid only during class time';

  @override
  String get caTitle => 'Academy Bills';

  @override
  String get caLoadError => 'Error loading bills.';

  @override
  String get caMarkPaidError => 'Error marking as paid.';

  @override
  String get caDeleteTitle => 'Delete bill';

  @override
  String caDeleteBody(String desc) {
    return 'Delete \"$desc\"?';
  }

  @override
  String get caNewBill => 'New bill';

  @override
  String get caEditBill => 'Edit bill';

  @override
  String get caDescHint => 'Description (e.g. Power bill)';

  @override
  String get caAmountHint => 'Amount (R\$)';

  @override
  String caDueOn(String date) {
    return 'Due date: $date';
  }

  @override
  String get caRecurring => 'Recurring bill (monthly)';

  @override
  String get caSaveBill => 'Save bill';

  @override
  String get caToPay => 'To pay';

  @override
  String get caOverdue => 'Overdue';

  @override
  String get caFilterAll => 'All';

  @override
  String get caFilterPending => 'Pending';

  @override
  String get caFilterOverdue => 'Overdue';

  @override
  String get caFilterPaid => 'Paid';

  @override
  String get caEmpty => 'No bills registered';

  @override
  String get caStPaid => 'Paid';

  @override
  String get caStOverdue => 'Overdue';

  @override
  String get caStCancelled => 'Cancelled';

  @override
  String get caStPending => 'Pending';

  @override
  String caCategoryDueOn(String cat, String date) {
    return '$cat · due $date';
  }

  @override
  String get caMarkAsPaid => 'Mark as paid';

  @override
  String get caCatWater => 'Water';

  @override
  String get caCatPower => 'Power';

  @override
  String get caCatRent => 'Rent';

  @override
  String get caCatInternet => 'Internet';

  @override
  String get caCatOther => 'Other';

  @override
  String get raTitle => 'Annual Report';

  @override
  String get raLoadError => 'Couldn\'t load the report.';

  @override
  String get raYearOverview => 'Year overview';

  @override
  String raNoMovement(int year) {
    return 'No financial activity found in $year.';
  }

  @override
  String get raMonthlyRevenue => 'Monthly revenue';

  @override
  String raOverdueCount(int count) {
    return 'Overdue ($count)';
  }

  @override
  String get raNoOverdue => 'No overdue students in this period.';

  @override
  String get raPrevYear => 'Previous year';

  @override
  String get raNextYear => 'Next year';

  @override
  String get raReceivedYear => 'Received this year';

  @override
  String raChargesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count charges',
      one: '1 charge',
    );
    return '$_temp0';
  }

  @override
  String get raOverdue => 'Overdue';

  @override
  String get raOutstanding => 'Outstanding';

  @override
  String get raReceived => 'Received';

  @override
  String raNoRevenueYear(int year) {
    return 'No revenue recorded in $year.';
  }

  @override
  String raDaysOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days overdue',
      one: '1 day overdue',
    );
    return '$_temp0';
  }

  @override
  String get raUnknownStudent => 'Unidentified student';

  @override
  String raBarTooltip(
    String month,
    int year,
    String received,
    String pending,
    String total,
  ) {
    return '$month $year\nReceived: $received\nPending: $pending\nTotal: $total';
  }

  @override
  String get fiStPending => 'Pending';

  @override
  String get fiStPaid => 'Paid';

  @override
  String get fiStOverdue => 'Overdue';

  @override
  String get fiStForecast => 'Forecast';

  @override
  String get fiStDismissed => 'Dismissed';

  @override
  String get fiTypeMonthly => 'Monthly fee';

  @override
  String get fiTypeEnrollment => 'Enrollment fee';

  @override
  String get fiReportTab => 'Report';

  @override
  String get fiGenerateCharges => 'Generate charges';

  @override
  String get fiGenerateCharge => 'Generate charge';

  @override
  String get fiNewCharge => 'New charge';

  @override
  String get fiCurrentMonth => 'Current month';

  @override
  String get fiBackToCurrentMonth => 'Back to current month';

  @override
  String get fiMoreActions => 'More';

  @override
  String get fiCleanupRetroactive => 'Clean up backdated';

  @override
  String get fiCleanupRetroactiveTitle => 'Clean up backdated charges';

  @override
  String get fiCleanupRetroactiveExplain =>
      'Dismisses (does not delete) every pending or overdue charge due BEFORE the chosen month, for ALL students. Already-paid charges are never affected, and none of this counts as revenue.';

  @override
  String get fiCleanupRetroactiveCutoffLabel => 'Keep charges from';

  @override
  String get fiCleanupRetroactiveConfirmTitle => 'Confirm cleanup?';

  @override
  String fiCleanupRetroactiveConfirmBody(String mes) {
    return 'This will dismiss, all at once, every student\'s pending charges before $mes. It can\'t be undone in bulk — only one at a time, manually. Are you sure?';
  }

  @override
  String get fiCleanupRetroactiveButton => 'Dismiss backdated charges';

  @override
  String fiCleanupRetroactiveSuccess(int n) {
    return '$n backdated charge(s) dismissed.';
  }

  @override
  String get fiCleanupRetroactiveError =>
      'Couldn\'t clean up backdated charges. Please try again.';

  @override
  String get fiMergeDuplicates => 'Fix duplicates';

  @override
  String get fiMergeDuplicatesTitle => 'Fix duplicate monthly charges';

  @override
  String get fiMergeDuplicatesExplain =>
      'Scans every month for a student with more than one monthly charge for the same period. When it\'s unambiguous (one paid among the duplicates, or none paid), it keeps one and dismisses the rest — never deletes, never marks as paid. If 2 or more are already marked paid for the same month, that case is left out for you to review by hand.';

  @override
  String get fiMergeDuplicatesConfirmTitle => 'Fix duplicates now?';

  @override
  String get fiMergeDuplicatesConfirmBody =>
      'This will automatically dismiss duplicate monthly charges for every student in this school, keeping one per student/month. It can\'t be undone in bulk — only one at a time, manually. Continue?';

  @override
  String get fiMergeDuplicatesButton => 'Fix duplicates';

  @override
  String fiMergeDuplicatesSuccess(int grupos, int resolvidas, int manual) {
    return '$grupos group(s) with duplicates · $resolvidas fixed automatically · $manual left for manual review.';
  }

  @override
  String get fiMergeDuplicatesError =>
      'Couldn\'t fix the duplicate monthly charges. Please try again.';

  @override
  String get fiNoCharges => 'No charges.';

  @override
  String fiChargesCount(int count) {
    return 'Charges · $count';
  }

  @override
  String get fiTabAll => 'All';

  @override
  String get fiTabPending => 'Pending';

  @override
  String get fiTabOverdue => 'Overdue';

  @override
  String get fiTabPaid => 'Paid';

  @override
  String get fiTabDismissed => 'Dismissed';

  @override
  String fiDueOn(String date) {
    return 'Due $date';
  }

  @override
  String fiLateFee(String value) {
    return '+ Late fee: $value';
  }

  @override
  String fiDiscount(String value) {
    return '- Discount: $value';
  }

  @override
  String fiReceivedAmount(String value) {
    return 'Received: $value';
  }

  @override
  String get fiMarkPaid => 'Mark as paid';

  @override
  String get fiRefund => 'Reverse payment';

  @override
  String get fiRefundTitle => 'Reverse payment?';

  @override
  String fiRefundBody(String name) {
    return 'This will mark $name\'s payment as pending again.';
  }

  @override
  String get fiRefundDone => 'Payment reversed.';

  @override
  String get fiRestoreCharge => 'Restore charge';

  @override
  String get fiDismissTitle => 'Dismiss charge?';

  @override
  String fiDismissBody(String name) {
    return '$name\'s charge will no longer be billed and drops out of the billing totals. You can restore it later.';
  }

  @override
  String get fiDeleteCharge => 'Delete charge';

  @override
  String get fiDeleteChargeBody =>
      'Are you sure you want to delete this charge? This can\'t be undone.';

  @override
  String fiMarkedPaid(String name) {
    return '$name marked as paid!';
  }

  @override
  String get fiUpdateError => 'Error updating the payment.';

  @override
  String get fiConfirmPayment => 'Confirm payment';

  @override
  String get fiBaseValue => 'Base amount';

  @override
  String get fiToReceive => 'To receive';

  @override
  String get fiDiscountOptional => 'Discount (optional)';

  @override
  String get fiLoadError => 'Error loading data.';

  @override
  String get fiProcessError => 'Error processing charges.';

  @override
  String get fiCreateError => 'Error creating the charge.';

  @override
  String get fiChargeCreated => 'Charge created!';

  @override
  String get fiChargeViaWhatsapp => 'Charge via WhatsApp';

  @override
  String fiChargeViaWhatsappN(int count) {
    return 'Charge via WhatsApp ($count)';
  }

  @override
  String fiGenerateNCharges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Generate $count charges',
      one: 'Generate 1 charge',
    );
    return '$_temp0';
  }

  @override
  String fiAffectedStudents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count students affected',
      one: '1 student affected',
    );
    return '$_temp0';
  }

  @override
  String get fiSeeAffected => 'See affected students';

  @override
  String get fiNoStudentsForFilter => 'No students match this filter.';

  @override
  String fiNChargesGenerated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count charges generated',
      one: '1 charge generated',
    );
    return '$_temp0';
  }

  @override
  String get fiReadyForWhatsapp => 'Ready to charge via WhatsApp!';

  @override
  String get fiTapEachStudent =>
      'Tap each student to open WhatsApp with a ready-made message.';

  @override
  String get fiNoPhone => 'No phone';

  @override
  String get fiSelectClass => 'Select the class';

  @override
  String get fiFilterBySituation => 'Filter by status';

  @override
  String get fiSelectStudent => 'Select the student';

  @override
  String fiWhatsappGreeting(String name) {
    return 'Hi $name, ';
  }

  @override
  String get fiOptNoChargeMonth => 'No charge this month';

  @override
  String get fiOptDueWithin7 => 'Due within 7 days';

  @override
  String get fiChooseWhoToCharge => 'Choose who should be charged:';

  @override
  String get fiByClass => 'By class';

  @override
  String get fiByClassHint => 'Charge students from a specific class';

  @override
  String get fiAllActive => 'All active';

  @override
  String get fiAllActiveHint => 'Charge all active students in the academy';

  @override
  String get fiRefundShort => 'Reverse';

  @override
  String get fiDismiss => 'Dismiss';

  @override
  String get fiBillsShort => 'Bills';

  @override
  String get fiType => 'Type';

  @override
  String get rkNoData => 'No data in this ranking';

  @override
  String get rkNoCustom => 'No custom rankings';

  @override
  String get rkCreateHint => 'Create a ranking by attendance or points.';

  @override
  String get rkCreate => 'Create ranking';

  @override
  String get rkNewRanking => 'New ranking';

  @override
  String get rkEditRanking => 'Edit ranking';

  @override
  String get rkAskAdmin => 'Ask the administrator to create custom rankings.';

  @override
  String get rkGeneralRanking => 'General Ranking';

  @override
  String get rkCustomTab => 'Custom';

  @override
  String rkWeightAttendance(Object n) {
    return 'Attendance ×$n';
  }

  @override
  String rkWeightManual(Object n) {
    return 'Manual ×$n';
  }

  @override
  String get rkWithPeriod => '📅 Time-boxed';

  @override
  String get rkAddPoints => 'Add points';

  @override
  String get rkNoParticipants => 'No participants';

  @override
  String get rkNobodyScored => 'Nobody has scored in this ranking yet.';

  @override
  String get rkAddPointsError => 'Error adding points';

  @override
  String get rkInvalidValue => 'Invalid value';

  @override
  String get rkReasonOptional => 'Reason (optional)';

  @override
  String get rkReasonHint1 => 'e.g. Won the championship';

  @override
  String get rkUpdateError => 'Error updating';

  @override
  String get rkTapPlus => 'Tap + to create your first ranking';

  @override
  String get rkAcademyNotFound => 'Academy not found.';

  @override
  String get rkNameRequired => 'Ranking name *';

  @override
  String get rkPointsComposition => 'Points composition';

  @override
  String get rkIncludeAttendance => 'Include attendance';

  @override
  String get rkEachAttendanceCounts => 'Each check-in counts as points';

  @override
  String get rkAttendanceWeight => 'Weight per check-in:';

  @override
  String get rkIncludeManual => 'Include manual points';

  @override
  String get rkManualHint => 'Points added manually by the instructor/admin';

  @override
  String get rkManualWeight => 'Manual points weight:';

  @override
  String get rkValidityPeriod => 'Validity period';

  @override
  String get rkOutsidePeriodIgnored =>
      'Check-ins outside this period are ignored in the calculation.';

  @override
  String get rkStartDate => 'Start date';

  @override
  String get rkEndDate => 'End date';

  @override
  String get rkRemoveEntryTitle => 'Remove entry?';

  @override
  String get rkRemoveEntryBody => 'This entry will be removed permanently.';

  @override
  String get rkEntries => 'Entries';

  @override
  String get rkNoParticipantsYet => 'No participants yet';

  @override
  String rkPtsAttendance(Object n) {
    return '${n}pts attendance';
  }

  @override
  String rkPtsManual(Object n) {
    return '${n}pts manual';
  }

  @override
  String get rkNoPointsYet => 'No points added yet';

  @override
  String get rkUseButtonBelow => 'Use the button below to add points';

  @override
  String get rkEnterPoints => 'Enter the number of points';

  @override
  String get rkMustNotBeZero => 'Must not be zero';

  @override
  String get rkPointsHint => 'Points (e.g. 10, -5)';

  @override
  String get rkDescribeReason => 'Describe the reason';

  @override
  String get rkReasonHint2 => 'Reason (e.g. 1st place at tournament X)';

  @override
  String get rkConfirmEntry => 'Confirm entry';

  @override
  String get rkViewLeaderboardAddPoints => 'View leaderboard and add points';

  @override
  String get rkNoRankings => 'No rankings created';

  @override
  String get rkVisibleStudentShort => 'Student-visible';

  @override
  String get rkVisibleToStudents => 'Visible to students';

  @override
  String get rkVisibleHint =>
      'Students will be able to see this ranking in the app';

  @override
  String rkByOn(String name, String date) {
    return 'by $name • $date';
  }

  @override
  String get rkManage => 'Manage';

  @override
  String get rkVisibility => 'Visibility';

  @override
  String get newsNew => 'New post';

  @override
  String get newsPublished => 'Post published!';

  @override
  String get newsPublishError => 'Error publishing.';

  @override
  String get newsDeleteTitle => 'Delete post?';

  @override
  String get newsDeleteBody => 'This can\'t be undone.';

  @override
  String get newsDeleteError => 'Error deleting.';

  @override
  String get newsEmpty => 'No posts yet.';

  @override
  String get newsStatusPublished => 'Published';

  @override
  String get newsStatusDraft => 'Draft';

  @override
  String get newsPublish => 'Publish';

  @override
  String get newsEditTitle => 'Edit Post';

  @override
  String get newsNewTitle => 'New Post';

  @override
  String get newsImageTooLarge => 'Image too large. Maximum 3MB.';

  @override
  String get newsTitleSummaryRequired => 'Title and summary are required.';

  @override
  String get newsSaveError => 'Error saving the post.';

  @override
  String get newsAddImage => 'Add image (optional)';

  @override
  String get newsFieldTitle => 'Title';

  @override
  String get newsFieldSummary => 'Summary (shown in the list)';

  @override
  String get newsFieldContent => 'Full content (optional)';

  @override
  String get newsPublishNow => 'Publish now and notify';

  @override
  String get newsCreate => 'Create post';

  @override
  String get newsNonePublished => 'No posts published yet.';

  @override
  String get newsDetailTitle => 'Post';

  @override
  String get commonNew => 'New';

  @override
  String get commonPreview => 'Preview';

  @override
  String get plnTitle => 'Payment Plans';

  @override
  String get plnLoadError => 'Failed to load plans.';

  @override
  String get plnEditTitle => 'Edit Plan';

  @override
  String get plnNewTitle => 'New Plan';

  @override
  String get plnNameField => 'Plan name *';

  @override
  String get plnMonthlyValueField => 'Monthly amount (R\$) *';

  @override
  String get plnNameRequired => 'Name is required.';

  @override
  String get plnInvalidValue => 'Enter a valid monthly amount.';

  @override
  String get plnUpdated => 'Plan updated!';

  @override
  String get plnCreated => 'Plan created!';

  @override
  String get plnSaveError => 'Failed to save plan.';

  @override
  String get plnCreateBtn => 'Create plan';

  @override
  String get plnDeleteTitle => 'Delete plan';

  @override
  String plnDeleteBody(String name) {
    return 'Delete the plan \"$name\"?\nEnrolled students won\'t be affected.';
  }

  @override
  String get plnDeleted => 'Plan deleted.';

  @override
  String get plnDeleteError => 'Failed to delete plan.';

  @override
  String get plnEmpty => 'No plans registered.';

  @override
  String get plnEmptyHint => 'Create plans to assign to students.';

  @override
  String get plnCreateFirst => 'Create first plan';

  @override
  String plnPerMonth(String value) {
    return 'R\$ $value / month';
  }

  @override
  String get psvManageTitle => 'Manage Surveys';

  @override
  String get psvSatisfactionTitle => 'Satisfaction Survey';

  @override
  String get psvFallbackTitle => 'Survey';

  @override
  String get psvEditTitle => 'Edit survey';

  @override
  String get psvNewTitle => 'New survey';

  @override
  String get psvTitleField => 'Survey title *';

  @override
  String get psvCreateBtn => 'Create survey';

  @override
  String get psvSaveError => 'Failed to save survey.';

  @override
  String get psvStatusError => 'Failed to change status.';

  @override
  String get psvDeleteTitle => 'Delete survey?';

  @override
  String psvDeleteBody(String title) {
    return 'By deleting \"$title\", the response data for this survey stays in history, but the template will no longer be available.';
  }

  @override
  String get psvDeleteError => 'Failed to delete survey.';

  @override
  String get psvLoadError => 'Failed to load.';

  @override
  String get psvEmpty => 'No surveys created yet';

  @override
  String get psvEmptyHint => 'Tap \"New survey\" to get started';

  @override
  String get psvActiveInfo =>
      'Only one survey can be active at a time. The active survey is shown to students in the current month.';

  @override
  String get psvUntitled => 'Untitled';

  @override
  String get psvActiveBadge => 'ACTIVE';

  @override
  String get psvViewResponses => 'View responses';

  @override
  String get psvResponsesLoadError => 'Failed to load responses.';

  @override
  String psvNoResponsesIn(String month) {
    return 'No responses in $month';
  }

  @override
  String get psvOverallAverage => 'Overall average';

  @override
  String psvResponsesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count responses',
      one: '$count response',
    );
    return '$_temp0';
  }

  @override
  String get psvDistribution => 'Distribution';

  @override
  String get psvRate1 => 'Very poor';

  @override
  String get psvRate2 => 'Poor';

  @override
  String get psvRate3 => 'Fair';

  @override
  String get psvRate4 => 'Good';

  @override
  String get psvRate5 => 'Excellent';

  @override
  String psvCommentsCount(int count) {
    return 'Comments ($count)';
  }

  @override
  String get ctTitle => 'Contract Templates';

  @override
  String get ctNew => 'New Template';

  @override
  String get ctRemoveTitle => 'Remove Template';

  @override
  String ctRemoveBody(String name) {
    return 'Remove \"$name\"?';
  }

  @override
  String get ctRemoveError => 'Failed to remove template';

  @override
  String get ctLoadError => 'Couldn\'t load';

  @override
  String get ctEmpty => 'No templates registered';

  @override
  String get ctEmptyHint => 'Tap + to create';

  @override
  String get ctEditTitle => 'Edit Template';

  @override
  String get ctNewTitle => 'New Contract Template';

  @override
  String get ctPreview => 'Preview';

  @override
  String get ctNameField => 'Template Name';

  @override
  String get ctHtmlField => 'HTML Content';

  @override
  String get ctSaveError => 'Failed to save template';

  @override
  String get ctCreateBtn => 'Create Template';

  @override
  String get mdlActivate => 'Activate';

  @override
  String get mdlDeactivate => 'Deactivate';

  @override
  String get mdlDeactivateBody =>
      'It will stop appearing on the classes, belts and student registration screens, but it won\'t be deleted.';

  @override
  String get mdlActivateBody =>
      'This discipline will appear again on all operational screens.';

  @override
  String get mdlToggleError => 'Couldn\'t change the discipline.';

  @override
  String get mdlLinksCheckError => 'Couldn\'t check the discipline\'s links.';

  @override
  String get mdlCannotDeleteTitle => 'Cannot delete';

  @override
  String mdlCannotDeleteBody(String name) {
    return 'The discipline \"$name\" has classes or belts linked to it. You can deactivate it — it will disappear from operational screens without erasing history.';
  }

  @override
  String mdlDeleteTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get mdlDeleteBody => 'This action cannot be undone.';

  @override
  String get mdlDeleted => 'Discipline deleted.';

  @override
  String get mdlDeleteError => 'Couldn\'t delete the discipline.';

  @override
  String get mdlTitle => 'Disciplines';

  @override
  String get mdlSubtitle => 'Manage your academy\'s disciplines.';

  @override
  String get mdlNew => 'New discipline';

  @override
  String get mdlInfoBanner =>
      'Active disciplines appear in belt management, classes and other operational screens.';

  @override
  String get mdlFilterActive => 'Active';

  @override
  String get mdlFilterInactive => 'Inactive';

  @override
  String mdlFilterAllCount(int count) {
    return 'All ($count)';
  }

  @override
  String mdlFilterActiveCount(int count) {
    return 'Active ($count)';
  }

  @override
  String mdlFilterInactiveCount(int count) {
    return 'Inactive ($count)';
  }

  @override
  String get mdlSearchHint => 'Search discipline...';

  @override
  String get mdlSortAZ => 'A–Z';

  @override
  String get mdlSortZA => 'Z–A';

  @override
  String get mdlStatusActive => 'Active';

  @override
  String get mdlStatusInactive => 'Inactive';

  @override
  String mdlA11yDeactivate(String name) {
    return 'Deactivate discipline $name';
  }

  @override
  String mdlA11yActivate(String name) {
    return 'Activate discipline $name';
  }

  @override
  String get mdlEmpty => 'No disciplines registered.';

  @override
  String get mdlEmptyHint => 'Add your academy\'s first discipline.';

  @override
  String get mdlNoResults => 'No disciplines found.';

  @override
  String get mdlLoadError => 'Couldn\'t load disciplines.';

  @override
  String get mdlImageTooLarge => 'Image too large (max 8 MB).';

  @override
  String get mdlImageProcessError => 'Couldn\'t process the image.';

  @override
  String get mdlImagePickError => 'Couldn\'t select the image.';

  @override
  String get mdlSaveError => 'Couldn\'t save the discipline.';

  @override
  String get mdlEditTitle => 'Edit Discipline';

  @override
  String get mdlNewTitle => 'New Discipline';

  @override
  String get mdlNameField => 'Discipline name';

  @override
  String get mdlNameHint => 'e.g. Adult Jiu-Jitsu';

  @override
  String get mdlActiveToggle => 'Discipline active';

  @override
  String get mdlActiveToggleSub =>
      'Inactive disciplines don\'t appear on operational screens.';

  @override
  String get mdlVisualId => 'Visual identity';

  @override
  String get mdlDefaultIcon => 'Default icon';

  @override
  String get mdlUploadImage => 'Upload image';

  @override
  String get mdlCreateBtn => 'Create Discipline';

  @override
  String get mdlChangeImage => 'Change image';

  @override
  String get mdlChooseGallery => 'Choose from gallery';

  @override
  String get mdlImageHint => 'JPG or PNG. The image is cropped to a square.';

  @override
  String get fxDeleteTitle => 'Delete belt?';

  @override
  String fxDeleteBody(String name) {
    return 'The belt \"$name\" will be removed.';
  }

  @override
  String get fxDeleteError => 'Couldn\'t delete the belt.';

  @override
  String get fxAboutTitle => 'About belts';

  @override
  String get fxAboutBody =>
      'Each discipline can have its own belts and promotion criteria.';

  @override
  String get fxSelectModality => 'Select the discipline';

  @override
  String get fxNewBelt => 'New Belt';

  @override
  String get fxLoadError => 'Couldn\'t load belts.';

  @override
  String get fxNoModalities => 'No disciplines registered';

  @override
  String get fxNoModalitiesHint =>
      'Register a discipline before setting up belts.';

  @override
  String get fxEmpty => 'No belts registered';

  @override
  String get fxEmptyHint => 'Register the first belt for this discipline.';

  @override
  String get fxCreateFirst => 'Create first belt';

  @override
  String get fxTitle => 'Belt Management';

  @override
  String get fxSubtitle =>
      'Register and organize the belts for each discipline.';

  @override
  String get fxHelp => 'Help';

  @override
  String get fxModality => 'Discipline';

  @override
  String fxBeltsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count belts registered',
      one: '$count belt registered',
    );
    return '$_temp0';
  }

  @override
  String get fxStudentsInModality => 'Students in this discipline';

  @override
  String fxMinMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Min. $count months',
      one: 'Min. $count month',
    );
    return '$_temp0';
  }

  @override
  String fxMinAttendances(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Min. $count check-ins',
      one: 'Min. $count check-in',
    );
    return '$_temp0';
  }

  @override
  String get fxNoMinReq => 'No minimum requirement';

  @override
  String get fxSaveError => 'Couldn\'t save the belt.';

  @override
  String get fxEnterZeroOrMore => 'Enter 0 or more';

  @override
  String get fxNumbersOnly => 'Numbers only';

  @override
  String get fxNotNegative => 'Cannot be negative';

  @override
  String get fxEditTitle => 'Edit Belt';

  @override
  String get fxNameField => 'Belt Name';

  @override
  String get fxNameHint => 'e.g. White, Blue, Purple...';

  @override
  String get fxOrder => 'Order';

  @override
  String get fxInvalid => 'Invalid';

  @override
  String get fxMin1 => 'Minimum 1';

  @override
  String get fxOrderHint => 'Belt position in the discipline\'s progression.';

  @override
  String get fxGradCriteria => 'Promotion criteria';

  @override
  String get fxMinTimeMonths => 'Minimum time (months)';

  @override
  String get fxMinTimeMonthsHint => 'Months of training before promoting.';

  @override
  String get fxMinAttendancesField => 'Minimum check-ins';

  @override
  String get fxMinAttendancesHint => 'Training sessions needed to promote.';

  @override
  String get fxDescHint => 'e.g. Notes about the belt...';

  @override
  String get fxBeltColor => 'Belt Color';

  @override
  String get fxCreateBtn => 'Create Belt';

  @override
  String get cfgTitle => 'Academy Settings';

  @override
  String get cfgSubtitle =>
      'Manage your academy\'s information and preferences.';

  @override
  String get cfgIdentitySection => 'Academy Identity';

  @override
  String get cfgIdentitySub => 'Customize your academy\'s information.';

  @override
  String get cfgLogo => 'Academy Logo';

  @override
  String get cfgLogoHasSub => 'Tap to change or remove';

  @override
  String get cfgLogoEmptySub => 'Add the academy logo';

  @override
  String get cfgGeneralInfo => 'General Information';

  @override
  String get cfgGeneralInfoSub => 'Name, email, phone, tax ID';

  @override
  String get cfgStudentsSection => 'Students';

  @override
  String get cfgStudentsSub => 'Configure student-related options.';

  @override
  String get cfgBlockCheckin => 'Block check-in for overdue tuition';

  @override
  String get cfgBlockCheckinSub =>
      'Prevents check-in for students with overdue payments';

  @override
  String get cfgGraceDays => 'Grace days';

  @override
  String get cfgGraceDaysSub => 'Blocks after the set number of days past due';

  @override
  String cfgDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return '$_temp0';
  }

  @override
  String get cfgCommSection => 'Communication';

  @override
  String get cfgCommSub => 'Customize the messages sent to students.';

  @override
  String get cfgReturnMsg => 'Win-back message (WhatsApp)';

  @override
  String get cfgReturnMsgSub => 'Message for students at risk of dropping out';

  @override
  String get cfgNewsSub => 'Publish news and announcements';

  @override
  String get cfgFinanceSection => 'Billing';

  @override
  String get cfgFinanceSub => 'Configure charges and billing options.';

  @override
  String get cfgPlansSub => 'Create, edit and delete tuition plans';

  @override
  String get cfgLateFee => 'Late fee';

  @override
  String get cfgLateFeeSub => 'Extra amount shown on overdue charges';

  @override
  String get cfgConfigFee => 'Configure fee';

  @override
  String get cfgFeePercentSub => 'Percentage over overdue charges';

  @override
  String get cfgFeeFixedSub => 'Fixed amount on overdue charges';

  @override
  String get cfgGradSection => 'Belts and Disciplines';

  @override
  String get cfgGradSub => 'Configure belts, promotions and disciplines.';

  @override
  String get cfgBeltsSub => 'Register and edit promotions by discipline';

  @override
  String get cfgModalitiesMgmt => 'Discipline Management';

  @override
  String get cfgModalitiesSub => 'Activate, deactivate or create disciplines';

  @override
  String get cfgContractsSub => 'Create and edit contract templates';

  @override
  String get cfgSurveySub => 'Configure surveys and track student responses.';

  @override
  String get cfgSurveyConfig => 'Survey settings';

  @override
  String cfgSurveyActiveSub(int xp) {
    return 'Active · $xp XP per response';
  }

  @override
  String get cfgSurveyInactiveSub => 'Monthly survey disabled';

  @override
  String get cfgSurveyManageSub => 'Create, activate and track surveys';

  @override
  String get cfgSurveyAllResponses => 'See all responses';

  @override
  String get cfgSurveyAllResponsesSub => 'Student ratings and comments';

  @override
  String get cfgSystemSection => 'System and Legal';

  @override
  String get cfgSystemSub => 'System information and legal documents.';

  @override
  String get cfgSubdomain => 'Subdomain';

  @override
  String get cfgPrivacy => 'Privacy Policy';

  @override
  String get cfgPrivacySub => 'How we handle your data (LGPD)';

  @override
  String get cfgTerms => 'Terms of Use';

  @override
  String get cfgTermsSub => 'Sensei Manager terms of use';

  @override
  String get cfgAccountSection => 'Account';

  @override
  String get cfgDangerSection => 'Danger Zone';

  @override
  String get cfgSaveToggleError => 'Couldn\'t save the change.';

  @override
  String get cfgInfoSaved => 'Information saved.';

  @override
  String get cfgLogoSaved => 'Logo updated.';

  @override
  String get cfgMsgSaved => 'Message saved.';

  @override
  String get cfgFeeSaved => 'Late fee saved.';

  @override
  String get cfgGraceSaved => 'Grace period updated.';

  @override
  String get cfgSurveySaved => 'Survey settings saved.';

  @override
  String get cfgSubdomainCopied => 'Subdomain copied.';

  @override
  String get cfgLoadError => 'Couldn\'t load the settings.';

  @override
  String get cfgSaveError => 'Couldn\'t save the changes.';

  @override
  String get cfgAcademyName => 'Academy Name';

  @override
  String get cfgEmail => 'Email';

  @override
  String get cfgPhone => 'Phone';

  @override
  String get cfgCnpj => 'Tax ID (CNPJ)';

  @override
  String get cfgChangeImage => 'Change image';

  @override
  String get cfgChooseImage => 'Choose image';

  @override
  String get cfgReturnMsgTitle => 'Win-back message';

  @override
  String get cfgReturnMsgDesc =>
      'Used when reaching out to students who have gone a few days without training. Leave blank to use the system default message.';

  @override
  String cfgReturnMsgDefault(String nome, String dias) {
    return 'Hi $nome! We\'ve missed you — it\'s been $dias days without training. Is everything OK? We\'re here to help you get back. 🥋';
  }

  @override
  String cfgReturnMsgHint(String nome, String dias) {
    return 'Hi $nome! We\'ve missed you — it\'s been $dias days without training...';
  }

  @override
  String get cfgRestoreDefault => 'Restore default';

  @override
  String get cfgSaveMsg => 'Save message';

  @override
  String get cfgLateFeeToggle => 'Charge a fee on overdue charges';

  @override
  String get cfgPercent => 'Percentage (%)';

  @override
  String get cfgFixedValue => 'Fixed amount (R\$)';

  @override
  String cfgFeePercentDesc(String value) {
    return '$value% will be added to overdue charges.';
  }

  @override
  String cfgFeeFixedDesc(String value) {
    return 'R\$ $value will be added to overdue charges.';
  }

  @override
  String get cfgFeePercentLabel => 'Late percentage';

  @override
  String get cfgFeeFixedLabel => 'Fixed late amount';

  @override
  String get cfgGraceDaysDesc =>
      'The student\'s check-in is blocked only after this number of days past the tuition due date.';

  @override
  String get cfgSurveyEnable => 'Enable monthly survey';

  @override
  String get cfgSurveyEnableSub =>
      'Students will be invited to rate the academy once a month.';

  @override
  String get cfgSurveyXp => 'XP per response';

  @override
  String get cfgSurveyXpSub =>
      'Points granted to the student after responding.';

  @override
  String get cfgLogout => 'Log out';

  @override
  String get cfgLogoutConfirm => 'End your session?';

  @override
  String get cfgLogoutBtn => 'Log out of account';

  @override
  String get cfgDeleteAccountTitle => 'Delete account?';

  @override
  String get cfgDeleteAccountBody =>
      'Your personal data will be permanently removed. This action cannot be undone.';

  @override
  String get cfgDeleteAccountError => 'Error deleting account. Try again.';

  @override
  String get cfgDeleteAccountBtn => 'Delete my account';

  @override
  String get cfgPlanActive => 'Active Plan';

  @override
  String get cfgPlanTrial => 'Trial';

  @override
  String get cfgPlanFree => 'Free';

  @override
  String get cfgPlanProDesc => 'Full access with no ads';

  @override
  String get cfgPlanTrialLastDay => 'Last day of the trial!';

  @override
  String cfgPlanTrialDaysLeft(int days) {
    return '$days days left in the trial';
  }

  @override
  String get cfgPlanFreeDesc => '3 classes · 10 students/class · ads';

  @override
  String fxStudentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count students',
      one: '$count student',
    );
    return '$_temp0';
  }

  @override
  String get fxZeroNoMin => '0 = no minimum requirement.';

  @override
  String get authEnterPassword => 'Enter your password.';

  @override
  String get authErrUserNotFound =>
      'User not found in the system. Contact the administrator.';

  @override
  String get authErrDbNotConfigured =>
      'Database not configured yet. Contact the administrator.';

  @override
  String get authErrNoPermission =>
      'No permission to access the data. Contact the administrator.';

  @override
  String get authFirstTimeUsingApp => 'Using the app for the first time';

  @override
  String authErrFirebaseCode(String code) {
    return 'Firebase error ($code)';
  }

  @override
  String get profMyProfile => 'My Profile';

  @override
  String get profUpdated => 'Profile updated!';

  @override
  String get profYourNameHint => 'Your name';

  @override
  String get profChangePassword => 'Change password';

  @override
  String get apPhotoSaveError => 'Error saving photo.';

  @override
  String get apPrimaryBelt => 'Primary Belt';

  @override
  String get apPrimaryBeltHint =>
      'Choose which promotion to show on your profile';

  @override
  String get apThanksFeedback => 'Thanks for the feedback!';

  @override
  String get apRatingRecorded => 'Your rating has been recorded.';

  @override
  String get apSurveyQuestion => 'How is your experience going?';

  @override
  String get apTapToRate => 'Tap to rate';

  @override
  String get apCommentHint => 'Leave a comment (optional)';

  @override
  String get apSurveySendError =>
      'Error sending response. Check your connection.';

  @override
  String apSendAndEarnXp(int xp) {
    return 'Send and earn +$xp XP';
  }

  @override
  String get apSendRating => 'Send rating';

  @override
  String get apEditProfile => 'Edit Profile';

  @override
  String get apFullName => 'Full name';

  @override
  String get apCertPending => 'Medical certificate pending';

  @override
  String get apCertRejected => 'Certificate rejected — send a new one';

  @override
  String get apCertExpired => 'Certificate expired — send a new one';

  @override
  String get apCertExpiringSoon => 'Certificate expiring soon';

  @override
  String get apLogoutTitle => 'Log out?';

  @override
  String get apLogoutBody => 'You\'ll need to sign in again to use the app.';

  @override
  String get apQrAttendance => 'Attendance QR';

  @override
  String get apSwitchProfile => 'Switch profile';

  @override
  String get apSwitchShort => 'Switch';

  @override
  String apOverdueCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count overdue',
      one: '1 overdue',
    );
    return '$_temp0';
  }

  @override
  String apPendingCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pending',
      one: '1 pending',
    );
    return '$_temp0';
  }

  @override
  String get apTapToChoose => 'Tap to choose';

  @override
  String get apTuitionOverdue => 'Tuition overdue';

  @override
  String get apTuitionOverdueHint => 'Tap to see details and pay.';

  @override
  String get apTapToResolve => 'Tap to resolve';

  @override
  String get apRateYourExperience => 'Rate your experience!';

  @override
  String apEarnXpMonthlySurvey(int xp) {
    return 'Earn +$xp XP by answering this month\'s survey';
  }

  @override
  String get apMyClasses => 'My classes';

  @override
  String get apNoClasses => 'Not enrolled in any class.';

  @override
  String apAttendancesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count check-ins',
      one: '$count check-in',
    );
    return '$_temp0';
  }

  @override
  String get apEditData => 'Edit details';

  @override
  String get apEditDataHint => 'Name, contact and personal information';

  @override
  String get apResetPasswordHint => 'Change your access password';

  @override
  String get apParqDone => 'Health questionnaire completed';

  @override
  String get apParqPending => 'Health questionnaire pending';

  @override
  String get apLogoutHint => 'End the session on this device';

  @override
  String get apLegal => 'Legal';

  @override
  String get apPrivacyHint => 'How your data is handled';

  @override
  String get apTermsHint => 'App rules and terms of use';

  @override
  String get apDeleteAccountSection => 'Delete account';

  @override
  String get apDeleteAccountHint => 'Permanently removes your data';

  @override
  String apXpAdded(int xp) {
    return '+$xp XP added to your profile.';
  }

  @override
  String get navLessons => 'Classes';

  @override
  String get navPromotions => 'Belts';

  @override
  String get navProfile => 'Profile';

  @override
  String get peseiTagline => 'Your health and wellness partner';

  @override
  String get peseiFreeBadge => 'Free · iOS & Android';

  @override
  String get peseiFeatWeightTitle => 'Weight Tracking';

  @override
  String get peseiFeatWeightSub =>
      'Track gains and losses with charts and history';

  @override
  String get peseiFeatWaterTitle => 'Daily Hydration';

  @override
  String get peseiFeatWaterSub =>
      'Personalized water intake goal with reminders';

  @override
  String get peseiFeatMedsTitle => 'Medications';

  @override
  String get peseiFeatMedsSub =>
      'Reminders so you don\'t forget your meds and supplements';

  @override
  String get peseiFeatProgressTitle => 'Visual Progress';

  @override
  String get peseiFeatProgressSub =>
      'Progress charts to keep you focused on your goals';

  @override
  String get peseiDownloadFree => 'Download for free';

  @override
  String get peseiFreeShort => 'FREE';

  @override
  String get peseiCardTagline => 'Weight, water and health tracking';

  @override
  String get peseiSeeApp => 'See app';

  @override
  String get commonTomorrow => 'Tomorrow';

  @override
  String get apClassFallback => 'Class';

  @override
  String get apMyLessons => 'My classes';

  @override
  String get apMyAttendance => 'My attendance';

  @override
  String get apMyPromotions => 'My belts';

  @override
  String get apAttendanceQr => 'Attendance QR';

  @override
  String get apNextClass => 'Next class';

  @override
  String get apCurrentGrad => 'Current belt';

  @override
  String get apJourneyStarts => 'Your journey starts here.';

  @override
  String get apJourneyContinues => 'Your journey continues here.';

  @override
  String get apHello => 'Hello!';

  @override
  String apHelloName(String name) {
    return 'Hello, $name!';
  }

  @override
  String get apNotifications => 'Notifications';

  @override
  String get apNoClassToday => 'No classes scheduled for today.';

  @override
  String apProfPrefix(String name) {
    return 'Instr. $name';
  }

  @override
  String get apWeekAttendance => 'Attendance this week';

  @override
  String get apTuitionOk => 'Tuition up to date';

  @override
  String get apTuitionOkSub => 'No pending items right now.';

  @override
  String get apTuitionPending => 'Tuition pending';

  @override
  String get apTuitionNeedsAttention =>
      'There is a tuition charge that needs attention.';

  @override
  String get apNoCharges => 'No charges';

  @override
  String get apNoChargesSub => 'Nothing outstanding here.';

  @override
  String apWorkoutsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions',
      one: '1 session',
    );
    return '$_temp0';
  }

  @override
  String apAbsencesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count absences',
      one: '1 absence',
    );
    return '$_temp0';
  }

  @override
  String get apNoClassOnDay => 'No classes on this day';

  @override
  String get apMyLessonsUpper => 'MY CLASSES';

  @override
  String get apOtherLessonsUpper => 'OTHER CLASSES';

  @override
  String get apExamApproved => 'Passed';

  @override
  String get apExamFailed => 'Failed';

  @override
  String get apPromotionHistory => 'Promotion History';

  @override
  String get apCurrentBeltsUpper => 'CURRENT BELTS';

  @override
  String get apHistoryUpper => 'HISTORY';

  @override
  String get apNoPromotions => 'No promotions recorded';

  @override
  String get apNoPromotionsSub => 'Your belt history will appear here.';

  @override
  String get apChargeFallback => 'Charge';

  @override
  String get apOutstanding => 'Outstanding';

  @override
  String get apAllPaid => 'All paid!';

  @override
  String apAmountToSettle(String value) {
    return '$value to settle';
  }

  @override
  String get apNoPendingNow => 'No pending items right now';

  @override
  String get apChargesUpper => 'CHARGES';

  @override
  String apDueDatePrefix(String date) {
    return 'Due: $date';
  }

  @override
  String get apContactSecretary => 'Contact the front desk to settle it.';

  @override
  String get apNoChargesInCategory => 'No charges in this category';

  @override
  String apNoChargesThisMonth(String month) {
    return 'No charges in $month';
  }

  @override
  String apTotalOpenAllMonths(String amount) {
    return '$amount outstanding in total';
  }

  @override
  String get apViewAllOverdue => 'View all overdue';

  @override
  String get apAllOverdueTitle => 'Overdue charges';

  @override
  String get apPrevMonth => 'Previous month';

  @override
  String get apNextMonth => 'Next month';

  @override
  String get apAttendanceTitle => 'Attendance';

  @override
  String get apTrainingHistory => 'Your training history';

  @override
  String get apTotalWorkouts => 'Total sessions';

  @override
  String get apAttendanceLabel => 'Check-ins';

  @override
  String get apAbsencesLabel => 'Absences';

  @override
  String get apNoAbsences => 'No absences recorded. Nice work!';

  @override
  String get apNoAttendanceYet => 'No check-ins recorded yet';

  @override
  String get apNothingHereYet => 'Nothing here yet';

  @override
  String get apAbsence => 'Absent';

  @override
  String get apPresent => 'Present';

  @override
  String get apCertTitle => 'Medical Certificate';

  @override
  String get apCertNoneSent => 'No certificate sent';

  @override
  String get apCertSendHint =>
      'Send your medical certificate so the academy can verify it.';

  @override
  String apCertValidUntil(String date) {
    return 'Valid until: $date';
  }

  @override
  String apCertReasonPrefix(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get apCertExpiringSoonSendNew => 'Expiring soon! Send a new one.';

  @override
  String get apCertSendNew => 'Send new certificate';

  @override
  String get apCertSend => 'Send certificate';

  @override
  String get apCertSentToast =>
      'Certificate sent! Wait for the academy\'s approval.';

  @override
  String get apCertSendError => 'Error sending. Try again.';

  @override
  String get apNotAuthenticated => 'User not authenticated.';

  @override
  String get apParqInstruction =>
      'Physical Activity Readiness Questionnaire. Please answer \"Yes\" or \"No\" to the questions below.';

  @override
  String get apParqFullNameReq => 'Full name *';

  @override
  String get apParqSignSend => 'Sign and submit PAR-Q';

  @override
  String get apAchievements => 'Achievements';

  @override
  String get apNoAchievements => 'No achievements yet.';

  @override
  String get apLevel => 'Level';

  @override
  String get apStreak => 'Streak';

  @override
  String apThisMonthXp(int xp) {
    return 'This month: $xp XP';
  }

  @override
  String apNextLevelXp(int xp) {
    return 'Next level: $xp XP';
  }

  @override
  String get apMyProfile => 'My Profile';

  @override
  String get apRankNoPeriodData => 'No data for this period';

  @override
  String get apRankTrainMore => 'Train more to show up in the ranking!';

  @override
  String get apRankingsTitle => 'Rankings';

  @override
  String get apQrMyCode => 'My QR Code';

  @override
  String get apQrScanAcademy => 'Scan Academy';

  @override
  String get apQrShowInstructor => 'Show it to the instructor at the entrance';

  @override
  String get apQrGenFailed => 'Couldn\'t generate the QR Code';

  @override
  String get apQrShowInstructorLong =>
      'Show this QR Code to the instructor to register your attendance.';

  @override
  String get apQrCheckinSuccess => 'Attendance registered successfully!';

  @override
  String get apQrCheckinError => 'Error registering attendance.';

  @override
  String get apQrCheckingIn => 'Registering attendance...';

  @override
  String get apQrScanAgain => 'Scan again';

  @override
  String get apQrPointAtAcademy =>
      'Point at the academy\'s QR Code at the entrance';

  @override
  String get apYourBeltHistory => 'Your belt history';

  @override
  String get navSchedule => 'Schedule';

  @override
  String get profNewsAcademy => 'Academy News';

  @override
  String get profAreaTitle => 'Instructor Area';

  @override
  String get profPanelSubtitle => 'Instructor panel';

  @override
  String get profQuickAccess => 'Quick access';

  @override
  String get profTodayClasses => 'Today\'s classes';

  @override
  String get profNoClassToday => 'No classes today.';

  @override
  String get profSeeMyClasses => 'See my classes';

  @override
  String profAlsoTrainsIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You also train in $count classes',
      one: 'You also train in 1 class',
    );
    return '$_temp0';
  }

  @override
  String get profMySchedule => 'My Schedule';

  @override
  String get profNoScheduleFound => 'No schedule found.';

  @override
  String get profMyClasses => 'My Classes';

  @override
  String get profNoClassesAssigned => 'No classes assigned';

  @override
  String get profNoStudentsEnrolled => 'No students enrolled';

  @override
  String get profPromotionRecorded => 'Promotion recorded!';

  @override
  String get profPromotion => 'Promotion';

  @override
  String get profAttendanceError => 'Error registering.';

  @override
  String get profRemoveAttendance => 'Remove attendance';

  @override
  String profRemoveAttendanceBody(String name, String date) {
    return 'Remove $name\'s attendance on $date?';
  }

  @override
  String get profScanQr => 'Scan QR Code';

  @override
  String get profMarkWhoPresent => 'Mark who was present';

  @override
  String get profAttendanceMarkedTapRemove =>
      'Attendance registered · tap to remove';

  @override
  String profRegisterNAttendance(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Register $count attendances',
      one: 'Register 1 attendance',
    );
    return '$_temp0';
  }

  @override
  String get profManual => 'Manual';

  @override
  String profRemoveAttendanceThisClass(String name) {
    return 'Remove $name\'s attendance for this class?';
  }

  @override
  String get profChange => 'Change';

  @override
  String get profNoAttendanceThisClass => 'No attendance for this class';

  @override
  String get profTapChangeDate => 'Tap \"Change\" to change the date';

  @override
  String get profAbsentPending => 'Pending';

  @override
  String get rkStudentsAppearHere => 'Students appear here as they check in.';

  @override
  String get commonCantOpenWhatsapp => 'Couldn\'t open WhatsApp.';

  @override
  String get evasaoRiskTitle => 'Dropout risk';

  @override
  String get evasaoNobodyAtRisk => 'Nobody at dropout risk right now. 🎉';

  @override
  String get evasaoCallWhatsapp => 'Message on WhatsApp';

  @override
  String evasaoDefaultMsg(String nome, String dias) {
    return 'Hi $nome! We\'ve missed you at training — it\'s been $dias days since you showed up. Is everything OK? If there\'s anything we can do to help you come back, just let us know. 🥋';
  }

  @override
  String get birthdaysTitle => 'Birthdays';

  @override
  String get birthdaysCurrentMonth => 'Current month';

  @override
  String birthdaysNoneInMonth(String month) {
    return 'No birthdays in $month';
  }

  @override
  String get stfEditMember => 'Edit member';

  @override
  String get stfRoleOptional => 'Role (optional)';

  @override
  String get stfProfile => 'Profile';

  @override
  String get stfScreens => 'Screens';

  @override
  String get stfActions => 'Actions';

  @override
  String get stfAdvancedAccess => 'Advanced access';

  @override
  String get stfMemberUpdated => 'Member updated!';

  @override
  String get stfUpdateError => 'Error updating.';

  @override
  String get stfRemoveFromTeam => 'Remove from team';

  @override
  String stfRemoveConfirm(String name) {
    return 'Remove $name from the team?';
  }

  @override
  String get stfMemberRemoved => 'Staff member removed.';

  @override
  String get stfRemoveError => 'Couldn\'t remove.';

  @override
  String get stfEmpty => 'No staff members registered.';

  @override
  String get stfLoadError => 'Error loading team.';

  @override
  String get stfActiveAccessWarning =>
      'This member already has active app access. Changing email/phone here does NOT change their password or login. Use \"Reset password\" if needed.';

  @override
  String get stfCreateError => 'Error registering staff member.';

  @override
  String get stfLinkProfiles => 'Link profiles?';

  @override
  String get stfPhoneBelongsTo => 'This phone already belongs to:';

  @override
  String get stfLinkStaffQuestion =>
      'Link this staff record to the same contact? The person will be able to switch between the two profiles inside the app, from the side menu.';

  @override
  String get stfLinkAlso => 'Link too';

  @override
  String get stfNewStaff => 'New Staff Member';

  @override
  String get stfPersonalData => 'Personal data';

  @override
  String get stfFullNameReq => 'Full name *';

  @override
  String get stfPhoneReq => 'Phone *';

  @override
  String get stfTempPasswordNote =>
      'On registration, we generate a temporary password for you to share. The person signs in with their phone or email + that password and the app asks them to set a permanent password — no \"first access\".';

  @override
  String get stfRoleAndProfile => 'Role and profile';

  @override
  String get stfRoleExample => 'Role (e.g. BJJ Instructor)';

  @override
  String get stfPermissions => 'Permissions';

  @override
  String get stfPermissionsHint =>
      'Set what this staff member can access and do in the app.';

  @override
  String get stfCreateStaff => 'Register staff member';

  @override
  String get stfVisibleScreens => 'Visible screens';

  @override
  String get stfAllowedActions => 'Allowed actions';

  @override
  String get stfRequiredField => 'Required field';

  @override
  String get famLoadError => 'Error loading groups.';

  @override
  String get famNewGroup => 'New Family Group';

  @override
  String get famGroupNameHint => 'Group name (e.g. Silva Family)';

  @override
  String get famCreate => 'Create';

  @override
  String get famCreateError => 'Error creating group.';

  @override
  String get famRename => 'Rename Group';

  @override
  String get famRenameError => 'Error renaming.';

  @override
  String get famDeleteTitle => 'Delete group?';

  @override
  String get famDeleteBody => 'Members will be unlinked but not deleted.';

  @override
  String get famDeleteError => 'Error deleting.';

  @override
  String get famRemoveMemberError => 'Error removing member.';

  @override
  String get famTitle => 'Family Groups';

  @override
  String get famNewGroupShort => 'New group';

  @override
  String get famEmpty => 'No family groups created.';

  @override
  String get famEmptyHint =>
      'Create groups to link members of the same family.';

  @override
  String get famCreateGroup => 'Create group';

  @override
  String get famRenameShort => 'Rename';

  @override
  String get famRemoveFromGroup => 'Remove from group';

  @override
  String get famNoMembers => 'No members. Add via the student\'s details.';

  @override
  String get acCreateError => 'Error registering student. Check the data.';

  @override
  String get acCreateAnywayBody =>
      'Register anyway?\nOn first access with this contact, the student will be able to choose between profiles (family group).';

  @override
  String get acCreateAnyway => 'Register anyway';

  @override
  String get acLinkStudentQuestion =>
      'Link this Student record to the same contact? The person will be able to switch between profiles inside the app.';

  @override
  String get acNewStudent => 'New Student';

  @override
  String get acFullNameReq => 'Full name *';

  @override
  String get acBirthDate => 'Date of birth';

  @override
  String get acMinor => 'Minor';

  @override
  String get acGuardianName => 'Guardian\'s name';

  @override
  String get acGuardianPhone => 'Guardian\'s phone';

  @override
  String get acSelectPlanOptional => 'Select plan (optional)';

  @override
  String get acAppAccessNote =>
      'On registration (with access allowed and a phone or email), we generate a temporary password for you to share with the student. They sign in with the registered phone or email + that password, and the app asks them to set a permanent password. No \"first access\" needed.';

  @override
  String get acAccessAllowed => 'App access allowed';

  @override
  String get acAccessBlocked => 'App access blocked';

  @override
  String get acCanLogin => 'Student will be able to log in normally';

  @override
  String get acCannotLogin => 'Student won\'t be able to enter the app';

  @override
  String get acCreateStudent => 'Register student';

  @override
  String get acRequiredField => 'Required field';

  @override
  String rnBadgeVersion(String version) {
    return 'VERSION $version';
  }

  @override
  String get rnTitle => 'What\'s new in Sensei Manager!';

  @override
  String get rnSubtitle => 'See what\'s new in this release.';

  @override
  String get rnCta => 'Got it';

  @override
  String get rnClose => 'Close';

  @override
  String rnA11yTitle(String version) {
    return 'What\'s new in version $version';
  }

  @override
  String get rnTagNew => 'NEW';

  @override
  String get rnTagImprovement => 'IMPROVEMENT';

  @override
  String get rnTagFix => 'FIX';

  @override
  String get rnFooterTitle => 'We\'re always improving!';

  @override
  String get rnFooterBody =>
      'Thanks for helping us make Sensei Manager better with every release.';

  @override
  String get rnMenuEntry => 'What\'s new';

  @override
  String get rnNewsCardHint => 'Tap to review what changed in this release.';

  @override
  String get rnLightThemeTitle => 'Light theme is here';

  @override
  String get rnLightThemeDesc =>
      'Choose Light, Dark, or automatically follow your device theme.';

  @override
  String get rnLanguageTitle => 'Sensei Manager is now available in English';

  @override
  String get rnLanguageDesc =>
      'You can now switch between English and Portuguese in the app preferences.';

  @override
  String get rnRedesignStudentTitle => 'A fresh new look';

  @override
  String get rnRedesignStudentDesc =>
      'Home, classes, promotions and billing have been redesigned to be clearer and easier to navigate.';

  @override
  String get rnRedesignAcademyTitle => 'A fresh new look';

  @override
  String get rnRedesignAcademyDesc =>
      'The dashboard, classes, settings, belts and reports have been redesigned to simplify navigation and highlight what matters.';

  @override
  String get rnSignInTitle => 'New sign-in experience';

  @override
  String get rnSignInDesc =>
      'Choose whether you\'re a student/guardian or an academy before signing in, with clearer first-time access and password recovery.';

  @override
  String get rnPasswordTitle => 'Password reset from the app';

  @override
  String get rnPasswordDesc =>
      'Authorized staff can issue a temporary password for students and team members, with a required change at next sign-in.';

  @override
  String get rnClassesTitle => 'Classes and promotions';

  @override
  String get rnClassesDesc =>
      'Belt promotions entered by mistake can be corrected without rebuilding history, and removing a class no longer deletes students, attendance or records.';

  @override
  String get rnBillingTitle => 'Automatic billing';

  @override
  String get rnBillingDesc =>
      'Monthly charges now appear automatically, you can take early payments, and the annual report has been redesigned.';
}
