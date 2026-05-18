namespace AcademiaFight.Application.Helpers;

public static class DateTimeHelper
{
    private static readonly TimeZoneInfo BrasiliaZone =
        TimeZoneInfo.FindSystemTimeZoneById(
            OperatingSystem.IsWindows() ? "E. South America Standard Time" : "America/Sao_Paulo");

    public static DateTime Agora() =>
        TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, BrasiliaZone);

    public static DateOnly Hoje() => DateOnly.FromDateTime(Agora());

    public static TimeOnly HoraAgora() => TimeOnly.FromDateTime(Agora());
}
