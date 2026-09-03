namespace AcademiaFight.Application.Identity;

public static class PhoneNormalizer
{
    public static string? Canonicalize(string? value)
    {
        var raw = value?.Trim() ?? string.Empty;
        if (raw.Length == 0) return null;

        var digits = new string(raw.Where(char.IsDigit).ToArray());
        if (digits.StartsWith("00", StringComparison.Ordinal))
            digits = digits[2..];

        if (raw.StartsWith('+'))
            return IsE164Length(digits) ? $"+{digits}" : null;

        if ((digits.Length is 12 or 13) && digits.StartsWith("55", StringComparison.Ordinal))
            return $"+{digits}";

        if (digits.Length is 10 or 11)
            return $"+55{digits}";

        return null;
    }

    public static string? CanonicalDigits(string? value) => Canonicalize(value)?[1..];

    private static bool IsE164Length(string digits) => digits.Length is >= 8 and <= 15;
}
