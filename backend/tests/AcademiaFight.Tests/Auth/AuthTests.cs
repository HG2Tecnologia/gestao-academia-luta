using System.Net;
using System.Net.Http.Json;
using AcademiaFight.Tests.Setup;
using Xunit;

namespace AcademiaFight.Tests.Auth;

[Collection("Integration")]
public class AuthTests
{
    private readonly ApiFactory _factory;
    private readonly HttpClient _anonClient;

    public AuthTests(ApiFactory factory)
    {
        _factory = factory;
        factory.EnsureSeeded();
        _anonClient = factory.CreateClient();
    }

    // ── Login ──────────────────────────────────────────────────────────────

    [Fact]
    public async Task Login_ComCredenciaisValidas_Retorna200ComToken()
    {
        var res = await _anonClient.PostAsJsonAsync("/api/auth/login", new
        {
            emailOuTelefone = ApiFactory.AdminEmail,
            senha = ApiFactory.SenhaPadrao,
        });

        Assert.Equal(HttpStatusCode.OK, res.StatusCode);

        var body = await res.Content.ReadFromJsonAsync<dynamic>();
        Assert.NotNull(body);
    }

    [Fact]
    public async Task Login_ComSenhaErrada_Retorna401()
    {
        var res = await _anonClient.PostAsJsonAsync("/api/auth/login", new
        {
            emailOuTelefone = ApiFactory.AdminEmail,
            senha = "senha_errada",
        });

        Assert.Equal(HttpStatusCode.Unauthorized, res.StatusCode);
    }

    [Fact]
    public async Task Login_ComEmailInexistente_Retorna401()
    {
        var res = await _anonClient.PostAsJsonAsync("/api/auth/login", new
        {
            emailOuTelefone = "naoexiste@academia-test.com",
            senha = ApiFactory.SenhaPadrao,
        });

        Assert.Equal(HttpStatusCode.Unauthorized, res.StatusCode);
    }

    [Fact]
    public async Task Login_ComoAluno_Retorna200()
    {
        var res = await _anonClient.PostAsJsonAsync("/api/auth/login", new
        {
            emailOuTelefone = ApiFactory.AlunoEmail,
            senha = ApiFactory.SenhaPadrao,
        });

        Assert.Equal(HttpStatusCode.OK, res.StatusCode);
    }

    // ── Alterar Senha ──────────────────────────────────────────────────────

    [Fact]
    public async Task AlterarSenha_SemToken_Retorna401()
    {
        var res = await _anonClient.PostAsJsonAsync("/api/auth/alterar-senha", new
        {
            senhaAtual = ApiFactory.SenhaPadrao,
            novaSenha  = "NovaSenha456",
        });

        Assert.Equal(HttpStatusCode.Unauthorized, res.StatusCode);
    }

    [Fact]
    public async Task AlterarSenha_ComSenhaAtualErrada_Retorna400()
    {
        using var client = _factory.CreateAdminClient();

        var res = await client.PostAsJsonAsync("/api/auth/alterar-senha", new
        {
            senhaAtual = "SenhaErrada999",
            novaSenha  = "NovaSenha456",
        });

        Assert.Equal(HttpStatusCode.BadRequest, res.StatusCode);
    }

    [Fact]
    public async Task AlterarSenha_ComNovaSenhaMuitoCurta_Retorna400()
    {
        using var client = _factory.CreateAdminClient();

        var res = await client.PostAsJsonAsync("/api/auth/alterar-senha", new
        {
            senhaAtual = ApiFactory.SenhaPadrao,
            novaSenha  = "abc",
        });

        Assert.Equal(HttpStatusCode.BadRequest, res.StatusCode);
    }

    [Fact]
    public async Task AlterarSenha_ComoAluno_ComDadosValidos_Retorna200()
    {
        // Muda e restaura a senha para não afetar outros testes
        using var client = _factory.CreateAlunoClient();

        var trocar = await client.PostAsJsonAsync("/api/auth/alterar-senha", new
        {
            senhaAtual = ApiFactory.SenhaPadrao,
            novaSenha  = "NovaSenhaAluno2024",
        });
        Assert.Equal(HttpStatusCode.OK, trocar.StatusCode);

        // Restaura para não quebrar Login_ComoAluno
        await client.PostAsJsonAsync("/api/auth/alterar-senha", new
        {
            senhaAtual = "NovaSenhaAluno2024",
            novaSenha  = ApiFactory.SenhaPadrao,
        });
    }

    [Fact]
    public async Task AlterarSenha_ComoProfessor_ComDadosValidos_Retorna200()
    {
        using var client = _factory.CreateProfessorClient();

        var trocar = await client.PostAsJsonAsync("/api/auth/alterar-senha", new
        {
            senhaAtual = ApiFactory.SenhaPadrao,
            novaSenha  = "NovaSenhaProfessor2024",
        });
        Assert.Equal(HttpStatusCode.OK, trocar.StatusCode);

        // Restaura
        await client.PostAsJsonAsync("/api/auth/alterar-senha", new
        {
            senhaAtual = "NovaSenhaProfessor2024",
            novaSenha  = ApiFactory.SenhaPadrao,
        });
    }
}
