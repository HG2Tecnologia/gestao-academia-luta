using System.Text.Json;
using AcademiaFight.Application.Finance;
using Xunit;

namespace AcademiaFight.Tests.Domain;

public class BillingPeriodTests
{
    [Fact]
    public void Periodo_NavegaEntreAnosEFormataCompetencia()
    {
        var january = BillingPeriod.Parse("2026-01");
        Assert.Equal("2025-12", january.AddMonths(-1).Value);
        Assert.Equal("2027-01", new BillingPeriod(2026, 12).AddMonths(1).Value);
    }

    [Fact]
    public void Vencimento_RespeitaUltimoDiaDoMes()
    {
        Assert.Equal(new DateOnly(2027, 2, 28), new BillingPeriod(2027, 2).DueDate(31));
    }

    [Fact]
    public void IdMensal_EhDeterministico()
    {
        var studentId = Guid.Parse("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa");
        Assert.Equal(
            "mensalidade__aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa__2026-09",
            ChargeStatusResolver.MonthlyDocumentId(studentId, new BillingPeriod(2026, 9)));
    }

    public static IEnumerable<object[]> StatusCases()
    {
        var path = Path.Combine(AppContext.BaseDirectory, "Fixtures", "billing_cases.json");
        var cases = JsonSerializer.Deserialize<List<BillingCase>>(
            File.ReadAllText(path),
            new JsonSerializerOptions { PropertyNameCaseInsensitive = true })!;

        return cases.Select(item => new object[] { item });
    }

    [Theory]
    [MemberData(nameof(StatusCases))]
    public void Status_ObedeceContratoCompartilhado(BillingCase item)
    {
        var actual = ChargeStatusResolver.Resolve(
            DateOnly.Parse(item.DueDate),
            DateOnly.Parse(item.Today),
            item.Paid,
            item.Disregarded);

        Assert.Equal(item.Expected, actual.ToString(), ignoreCase: true);
    }

    public sealed record BillingCase(
        string Name,
        string DueDate,
        string Today,
        bool Paid,
        bool Disregarded,
        string Expected);
}
