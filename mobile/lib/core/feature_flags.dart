/// Recursos em desenvolvimento, já implementados mas ainda não prontos pra
/// usuários finais (falta testar/ajustar). Ligar quando estiverem prontos —
/// basta trocar pra `true`, nenhum outro código precisa mudar.
library;

/// Notificações push de "aluno sumindo" / "próximo de graduar".
const bool kFeatureNotificacoesEngajamentoAtiva = false;

/// Chamada por reconhecimento facial (beta).
/// Ligada temporariamente pra teste local — desligar antes de qualquer
/// release pra loja (lib exige iOS 15.5+, ver commit 656dd8d6).
const bool kFeatureReconhecimentoFacialAtiva = true;
