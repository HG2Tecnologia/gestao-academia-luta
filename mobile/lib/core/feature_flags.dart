/// Recursos em desenvolvimento, já implementados mas ainda não prontos pra
/// usuários finais (falta testar/ajustar). Ligar quando estiverem prontos —
/// basta trocar pra `true`, nenhum outro código precisa mudar.
library;

/// Notificações push de "aluno sumindo" / "próximo de graduar".
const bool kFeatureNotificacoesEngajamentoAtiva = false;

/// Chamada por reconhecimento facial (beta). Testada de ponta a ponta em
/// aparelho físico (iOS) e aprovada pra ir pra loja — decisão consciente de
/// exigir iOS 15.5+ (google_mlkit_face_detection não roda em versão
/// anterior). Fica ligada só pra quem a academia ativar em Configurações
/// (`reconhecimento_facial_ativo`); essa flag global é só o "disjuntor"
/// geral do app.
const bool kFeatureReconhecimentoFacialAtiva = true;
