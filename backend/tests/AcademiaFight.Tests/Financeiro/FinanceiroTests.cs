using System.Net;
using System.Net.Http.Json;
using AcademiaFight.Tests.Setup;
using Xunit;

namespace AcademiaFight.Tests.Financeiro;

[Collection("Integration")]
public class FinanceiroTests
{
    private readonly ApiFactory _factory;

    public FinanceiroTests(ApiFactory factory)
    {
        _factory = factory;
        factory.EnsureSeeded();
    }

    // ── Resumo ─────────────────────────────────────────────────────────────

    [Fact]
    public async Task Resumo_SemToken_Retorna401()
    {
        using var client = _factory.CreateClient();
        var res = await client.GetAsync("/api/financeiro/resumo");
        Assert.Equal(HttpStatusCode.Unauthorized, res.StatusCode);
    }

    [Fact]
    public async Task Resumo_ComoAdmin_Retorna200()
    {
        using var client = _factory.CreateAdminClient();
        var res = await client.GetAsync("/api/financeiro/resumo");
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);
    }

    [Fact]
    public async Task Resumo_ComoAdmin_RetornaEstrutura()
    {
        using var client = _factory.CreateAdminClient();
        var res = await client.GetAsync("/api/financeiro/resumo");
        res.EnsureSuccessStatusCode();

        var body = await res.Content.ReadFromJsonAsync<ResumoWrapper>();
        Assert.NotNull(body?.Dados);
    }

    // ── Listagem ───────────────────────────────────────────────────────────

    [Fact]
    public async Task ListarCobranças_ComoAdmin_Retorna200()
    {
        using var client = _factory.CreateAdminClient();
        var res = await client.GetAsync("/api/financeiro");
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);
    }

    [Fact]
    public async Task ListarCobranças_SemToken_Retorna401()
    {
        using var client = _factory.CreateClient();
        var res = await client.GetAsync("/api/financeiro");
        Assert.Equal(HttpStatusCode.Unauthorized, res.StatusCode);
    }

    [Fact]
    public async Task ListarPorAluno_ComoAdmin_Retorna200()
    {
        using var client = _factory.CreateAdminClient();
        var res = await client.GetAsync($"/api/financeiro/aluno/{ApiFactory.AlunoId}");
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);
    }

    // ── Minhas Cobranças (aluno) ───────────────────────────────────────────

    [Fact]
    public async Task MinhasCobranças_SemToken_Retorna401()
    {
        using var client = _factory.CreateClient();
        var res = await client.GetAsync("/api/financeiro/minhas");
        Assert.Equal(HttpStatusCode.Unauthorized, res.StatusCode);
    }

    [Fact]
    public async Task MinhasCobranças_ComoAluno_Retorna200()
    {
        using var client = _factory.CreateAlunoClient();
        var res = await client.GetAsync("/api/financeiro/minhas");
        Assert.Equal(HttpStatusCode.OK, res.StatusCode);
    }

    [Fact]
    public async Task MinhasCobranças_ComoAluno_RetornaCobrançaSeeded()
    {
        using var client = _factory.CreateAlunoClient();
        var res = await client.GetAsync("/api/financeiro/minhas");
        res.EnsureSuccessStatusCode();

        var body = await res.Content.ReadFromJsonAsync<ListWrapper>();
        Assert.NotNull(body?.Dados);
        Assert.NotEmpty(body.Dados);
    }

    // ── Criar ──────────────────────────────────────────────────────────────

    [Fact]
    public async Task CriarPagamento_ComoAdmin_ComDadosValidos_Retorna201()
    {
        using var client = _factory.CreateAdminClient();

        var res = await client.PostAsJsonAsync("/api/financeiro", new
        {
            alunoId        = ApiFactory.AlunoId,
            tipo           = 1,  // Mensalidade
            status         = 1,  // Pendente
            valor          = 200.00m,
            descricao      = "Mensalidade Teste QA",
            dataVencimento = DateTime.UtcNow.AddDays(10).ToString("yyyy-MM-dd"),
        });

        Assert.Equal(HttpStatusCode.Created, res.StatusCode);
    }

    [Fact]
    public async Task CriarPagamento_SemToken_Retorna401()
    {
        using var client = _factory.CreateClient();

        var res = await client.PostAsJsonAsync("/api/financeiro", new
        {
            alunoId = ApiFactory.AlunoId,
            tipo    = 1,
            valor   = 100m,
        });

        Assert.Equal(HttpStatusCode.Unauthorized, res.StatusCode);
    }

    // ── Atualizar Status ───────────────────────────────────────────────────

    [Fact]
    public async Task AtualizarStatusPagamento_ComoAdmin_Retorna200()
    {
        using var client = _factory.CreateAdminClient();

        var res = await client.PatchAsJsonAsync($"/api/financeiro/{ApiFactory.PagamentoId}", new
        {
            status         = 2,  // Pago
            dataPagamento  = DateTime.UtcNow.ToString("yyyy-MM-dd"),
            formaPagamento = "PIX",
        });

        Assert.Equal(HttpStatusCode.OK, res.StatusCode);
    }

    [Fact]
    public async Task AtualizarStatusPagamento_ComIdInexistente_Retorna404()
    {
        using var client = _factory.CreateAdminClient();

        var res = await client.PatchAsJsonAsync($"/api/financeiro/{Guid.NewGuid()}", new
        {
            status = 2,
        });

        Assert.Equal(HttpStatusCode.NotFound, res.StatusCode);
    }
}

file class ResumoWrapper
{
    public ResumoDto? Dados { get; set; }
}

file class ResumoDto
{
    public decimal TotalRecebidoMes { get; set; }
}

file class ListWrapper
{
    public List<object>? Dados { get; set; }
}
