/// Normalização canônica de telefone usada pelos fluxos de identidade.
///
/// Telefones brasileiros nacionais recebem o DDI +55. Números que já chegam
/// em E.164 são preservados. Retorna `null` quando não há dígitos suficientes
/// para identificar um telefone válido.
abstract final class PhoneNormalizer {
  static String? canonicalize(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return null;

    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00')) digits = digits.substring(2);

    if (raw.startsWith('+')) {
      return _isE164Length(digits) ? '+$digits' : null;
    }

    if ((digits.length == 12 || digits.length == 13) &&
        digits.startsWith('55')) {
      return '+$digits';
    }

    if (digits.length == 10 || digits.length == 11) {
      return '+55$digits';
    }

    return null;
  }

  static String? digits(String? value) => canonicalize(value)?.substring(1);

  static bool _isE164Length(String digits) =>
      digits.length >= 8 && digits.length <= 15;
}
