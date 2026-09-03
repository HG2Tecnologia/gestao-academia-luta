using System.Text.Json;
using AcademiaFight.Application.Identity;
using Xunit;

namespace AcademiaFight.Tests.Domain;

public class PhoneNormalizerTests
{
    public static IEnumerable<object?[]> Cases()
    {
        var path = Path.Combine(AppContext.BaseDirectory, "Fixtures", "phone_normalization_cases.json");
        var cases = JsonSerializer.Deserialize<List<PhoneCase>>(
            File.ReadAllText(path),
            new JsonSerializerOptions { PropertyNameCaseInsensitive = true })!;

        return cases.Select(item => new object?[] { item.Name, item.Input, item.Expected });
    }

    [Theory]
    [MemberData(nameof(Cases))]
    public void Canonicalize_ObedeceContratoCompartilhado(
        string _,
        string? input,
        string? expected)
    {
        Assert.Equal(expected, PhoneNormalizer.Canonicalize(input));
    }

    [Fact]
    public void CanonicalDigits_RemoveSomenteOSinalDoCanonico()
    {
        Assert.Equal("5521999999999", PhoneNormalizer.CanonicalDigits("(21) 99999-9999"));
    }

    private sealed record PhoneCase(string Name, string? Input, string? Expected);
}
