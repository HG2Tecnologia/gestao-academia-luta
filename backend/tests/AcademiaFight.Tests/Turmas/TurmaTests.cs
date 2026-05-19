using System.Net;
using System.Net.Http.Json;
using AcademiaFight.Tests.Setup;
using Xunit;

namespace AcademiaFight.Tests.Turmas;

[Collection("Integration")]
public class TurmaTests
{
    private readonly ApiFactory _factory;

    public TurmaTests(ApiFactory factory)
    {
        _factory = factory;
        factory.EnsureSeeded();
    }

    // ── Listagem ───────────────────────────────────────────────────────────

    [Fact]
    public async Task ListarTurmas_SemToken_Retorna401()
    {
        using var client = _factory.CreateClient();
        var res = await client.GetAsync("/api/turmas");
        Assert.Equal(HttpStatusCode.Unauthorized, res.StatusCode);
    }

    [Fact]
    public async Task ListarTurmas_ComoAdmin_Retorna200()
    {
        using var client = _factory.CreateAdminClient();
        var res = await client.GetAsync("/api/turmas");
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);
    }

    [Fact]
    public async Task ListarTurmas_ComoAluno_Retorna200()
    {
        using var client = _factory.CreateAlunoClient();
        var res = await client.GetAsync("/api/turmas");
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);
    }

    [Fact]
    public async Task ListarTurmas_ComoAdmin_RetornaListaComTurmaSeeded()
    {
        using var client = _factory.CreateAdminClient();
        var res = await client.GetAsync("/api/turmas");
        res.EnsureSuccessStatusCode();

        var body = await res.Content.ReadFromJsonAsync<ResponseWrapper<List<dynamic>>>();
        Assert.NotNull(body?.Dados);
        Assert.NotEmpty(body.Dados);
    }

    // ── Obter Detalhe ──────────────────────────────────────────────────────

    [Fact]
    public async Task ObterTurma_ComIdValido_Retorna200()
    {
        using var client = _factory.CreateAdminClient();
        var res = await client.GetAsync($"/api/turmas/{ApiFactory.TurmaId}");
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);
    }

    [Fact]
    public async Task ObterTurma_ComIdInexistente_Retorna404()
    {
        using var client = _factory.CreateAdminClient();
        var res = await client.GetAsync($"/api/turmas/{Guid.NewGuid()}");
        Assert.Equal(HttpStatusCode.NotFound, res.StatusCode);
    }

    // ── Criar ──────────────────────────────────────────────────────────────

    [Fact]
    public async Task CriarTurma_ComoAdmin_ComDadosValidos_Retorna201()
    {
        using var client = _factory.CreateAdminClient();

        var res = await client.PostAsJsonAsync("/api/turmas", new
        {
            modalidadeId     = ApiFactory.ModalidadeId,
            professorId      = ApiFactory.ProfessorId,
            nome             = $"Nova Turma {Guid.NewGuid():N}",
            nivel            = "Intermediário",
            capacidadeMaxima = 15,
        });

        Assert.Equal(HttpStatusCode.Created, res.StatusCode);
    }

    [Fact]
    public async Task CriarTurma_SemToken_Retorna401()
    {
        using var client = _factory.CreateClient();

        var res = await client.PostAsJsonAsync("/api/turmas", new
        {
            modalidadeId     = ApiFactory.ModalidadeId,
            professorId      = ApiFactory.ProfessorId,
            nome             = "Turma Sem Auth",
            capacidadeMaxima = 10,
        });

        Assert.Equal(HttpStatusCode.Unauthorized, res.StatusCode);
    }

    // ── Atualizar ──────────────────────────────────────────────────────────

    [Fact]
    public async Task AtualizarTurma_ComoAdmin_ComDadosValidos_Retorna200()
    {
        using var client = _factory.CreateAdminClient();

        var res = await client.PutAsJsonAsync($"/api/turmas/{ApiFactory.TurmaId}", new
        {
            modalidadeId     = ApiFactory.ModalidadeId,
            professorId      = ApiFactory.ProfessorId,
            nome             = "Turma Iniciante Atualizada",
            nivel            = "Avançado",
            capacidadeMaxima = 25,
            ativo            = true,
        });

        Assert.Equal(HttpStatusCode.OK, res.StatusCode);
    }

    [Fact]
    public async Task AtualizarTurma_ComIdInexistente_Retorna404()
    {
        using var client = _factory.CreateAdminClient();

        var res = await client.PutAsJsonAsync($"/api/turmas/{Guid.NewGuid()}", new
        {
            modalidadeId     = ApiFactory.ModalidadeId,
            professorId      = ApiFactory.ProfessorId,
            nome             = "Inexistente",
            capacidadeMaxima = 10,
            ativo            = true,
        });

        Assert.Equal(HttpStatusCode.NotFound, res.StatusCode);
    }

    // ── Remover ────────────────────────────────────────────────────────────

    [Fact]
    public async Task RemoverTurma_ComoAdmin_Retorna200()
    {
        // Cria uma turma exclusiva para deletar (não afeta outros testes)
        using var client = _factory.CreateAdminClient();

        var createRes = await client.PostAsJsonAsync("/api/turmas", new
        {
            modalidadeId     = ApiFactory.ModalidadeId,
            professorId      = ApiFactory.ProfessorId,
            nome             = $"Turma Para Deletar {Guid.NewGuid():N}",
            capacidadeMaxima = 5,
        });
        Assert.Equal(HttpStatusCode.Created, createRes.StatusCode);

        var created = await createRes.Content.ReadFromJsonAsync<ResponseWrapper<TurmaIdDto>>();
        var turmaId = created?.Dados?.Id;
        Assert.NotNull(turmaId);

        var deleteRes = await client.DeleteAsync($"/api/turmas/{turmaId}");
        Assert.Equal(HttpStatusCode.OK, deleteRes.StatusCode);
    }

    // ── Alunos da Turma ────────────────────────────────────────────────────

    [Fact]
    public async Task GetAlunosDaTurma_ComIdValido_Retorna200()
    {
        using var client = _factory.CreateAdminClient();
        var res = await client.GetAsync($"/api/turmas/{ApiFactory.TurmaId}/alunos");
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);
    }
}

file class ResponseWrapper<T>
{
    public T? Dados { get; set; }
    public bool Sucesso { get; set; }
}

file class TurmaIdDto
{
    public Guid Id { get; set; }
}
