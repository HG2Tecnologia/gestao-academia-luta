using System.Globalization;

namespace AcademiaFight.Application.Finance;

public readonly record struct BillingPeriod : IComparable<BillingPeriod>
{
    public BillingPeriod(int year, int month)
    {
        if (month is < 1 or > 12)
            throw new ArgumentOutOfRangeException(nameof(month), "O mês deve estar entre 1 e 12.");

        Year = year;
        Month = month;
    }

    public int Year { get; }
    public int Month { get; }

    public string Value => $"{Year:D4}-{Month:D2}";

    public static BillingPeriod Parse(string value)
    {
        if (!DateOnly.TryParseExact(
                $"{value}-01",
                "yyyy-MM-dd",
                CultureInfo.InvariantCulture,
                DateTimeStyles.None,
                out var date))
            throw new FormatException($"Competência inválida: {value}");

        return new BillingPeriod(date.Year, date.Month);
    }

    public BillingPeriod AddMonths(int amount)
    {
        var date = new DateOnly(Year, Month, 1).AddMonths(amount);
        return new BillingPeriod(date.Year, date.Month);
    }

    public DateOnly DueDate(int preferredDay)
    {
        var lastDay = DateTime.DaysInMonth(Year, Month);
        return new DateOnly(Year, Month, Math.Clamp(preferredDay, 1, lastDay));
    }

    public int CompareTo(BillingPeriod other) =>
        (Year * 12 + Month).CompareTo(other.Year * 12 + other.Month);

    public override string ToString() => Value;
}

public enum EffectiveChargeStatus
{
    Pending,
    Overdue,
    Paid,
    Disregarded,
}

public static class ChargeStatusResolver
{
    public static EffectiveChargeStatus Resolve(
        DateOnly dueDate,
        DateOnly today,
        bool paid,
        bool disregarded = false)
    {
        if (paid) return EffectiveChargeStatus.Paid;
        if (disregarded) return EffectiveChargeStatus.Disregarded;
        return dueDate < today ? EffectiveChargeStatus.Overdue : EffectiveChargeStatus.Pending;
    }

    public static string MonthlyDocumentId(Guid studentId, BillingPeriod period) =>
        $"mensalidade__{studentId:D}__{period.Value}";
}
