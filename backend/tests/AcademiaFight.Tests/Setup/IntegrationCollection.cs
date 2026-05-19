using Xunit;

namespace AcademiaFight.Tests.Setup;

/// <summary>
/// Define uma collection xUnit para compartilhar uma única ApiFactory entre todas as classes de teste.
/// Isso evita conflito com o JobStorage.Current estático do Hangfire.
/// </summary>
[CollectionDefinition("Integration")]
public class IntegrationCollection : ICollectionFixture<ApiFactory>
{
    // Marker class — nenhum código necessário aqui.
}
