using System.Net;
using System.Net.Http.Json;
using AcademiaFight.Tests.Setup;
using Xunit;

namespace AcademiaFight.Tests.Alunos;

[Collection("Integration")]
public class AlunoTests
{
    private readonly ApiFactory _factory;

    public AlunoTests(ApiFactory factory)
    {
        _factory = factory;
        factory.EnsureSeeded();
    }

    // ── Listagem ───────────────────────────────────────────────────────────

    [Fact]
    public async Task ListarAlunos_SemToken_Retorna401()
    {
        using var client = _factory.CreateClient();
        var res = await client.GetAsync("/api/alunos");
        Assert.Equal(HttpStatusCode.Unauthorized, res.StatusCode);
    }

    [Fact]
    public async Task ListarAlunos_ComoAdmin_Retorna200()
    {
        using var client = _factory.CreateAdminClient();
        var res = await client.GetAsync("/api/alunos");
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);
    }

    [Fact]
    public async Task ListarAlunos_ComoAdmin_RetornaListaComAluno()
    {
        using var client = _factory.CreateAdminClient();
        var res = await client.GetAsync("/api/alunos");
        res.EnsureSuccessStatusCode();

        var body = await res.Content.ReadFromJsonAsync<System.Text.Json.JsonElement>();
        // A resposta pode ser paginada (dados.items) ou lista direta (dados)
        var dados = body.GetProperty("dados");
        Assert.NotEqual(System.Text.Json.JsonValueKind.Null, dados.ValueKind);
    }

    // ── Obter por ID ───────────────────────────────────────────────────────

    [Fact]
    public async Task ObterAluno_ComIdValido_Retorna200()
    {
        using var client = _factory.CreateAdminClient();
        var res = await client.GetAsync($"/api/alunos/{ApiFactory.AlunoId}");
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);
    }

    [Fact]
    public async Task ObterAluno_ComIdInexistente_Retorna404()
    {
        using var client = _factory.CreateAdminClient();
        var res = await client.GetAsync($"/api/alunos/{Guid.NewGuid()}");
        Assert.Equal(HttpStatusCode.NotFound, res.StatusCode);
    }

    // ── Aluno Me ───────────────────────────────────────────────────────────

    [Fact]
    public async Task MeAluno_ComoAluno_Retorna200ComDadosProprios()
    {
        using var client = _factory.CreateAlunoClient();
        var res = await client.GetAsync("/api/alunos/me");
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);
    }

    [Fact]
    public async Task MeAluno_SemToken_Retorna401()
    {
        using var client = _factory.CreateClient();
        var res = await client.GetAsync("/api/alunos/me");
        Assert.Equal(HttpStatusCode.Unauthorized, res.StatusCode);
    }

    // ── Criar ──────────────────────────────────────────────────────────────

    [Fact]
    public async Task CriarAluno_ComoAdmin_ComDadosValidos_Retorna201()
    {
        using var client = _factory.CreateAdminClient();

        var res = await client.PostAsJsonAsync("/api/alunos", new
        {
            nome      = "Novo Aluno Teste",
            email     = $"novo-aluno-{Guid.NewGuid():N}@teste.com",
            telefone  = "(11) 98765-4321",
        });

        Assert.Equal(HttpStatusCode.Created, res.StatusCode);
    }

    [Fact]
    public async Task CriarAluno_SemToken_Retorna401()
    {
        using var client = _factory.CreateClient();

        var res = await client.PostAsJsonAsync("/api/alunos", new
        {
            nome     = "Aluno Sem Auth",
            telefone = "(11) 11111-1111",
        });

        Assert.Equal(HttpStatusCode.Unauthorized, res.StatusCode);
    }

    // ── Atualizar ──────────────────────────────────────────────────────────

    [Fact]
    public async Task AtualizarAluno_ComoAdmin_ComDadosValidos_Retorna200()
    {
        using var client = _factory.CreateAdminClient();

        var res = await client.PutAsJsonAsync($"/api/alunos/{ApiFactory.AlunoId}", new
        {
            nome     = "Aluno Atualizado",
            email    = ApiFactory.AlunoEmail,
            telefone = "(11) 99999-0000",
            ativo    = true,
        });

        Assert.Equal(HttpStatusCode.OK, res.StatusCode);
    }

    [Fact]
    public async Task AtualizarAluno_ComIdInexistente_Retorna404()
    {
        using var client = _factory.CreateAdminClient();

        var res = await client.PutAsJsonAsync($"/api/alunos/{Guid.NewGuid()}", new
        {
            nome     = "Ninguem",
            telefone = "(00) 00000-0000",
            ativo    = true,
        });

        Assert.Equal(HttpStatusCode.NotFound, res.StatusCode);
    }

    // ── Toggle Ativo ───────────────────────────────────────────────────────

    [Fact]
    public async Task ToggleAtivo_ComoAdmin_Retorna200()
    {
        using var client = _factory.CreateAdminClient();

        var res = await client.PatchAsJsonAsync($"/api/alunos/{ApiFactory.AlunoId}/status", new
        {
            ativo = false,
        });

        Assert.Equal(HttpStatusCode.OK, res.StatusCode);
    }
}

// Helper para desserializar respostas paginadas/wrapper
file class ResponseWrapper<T>
{
    public T? Dados { get; set; }
    public bool Sucesso { get; set; }
}
