using System.Net;
using System.Net.Http.Json;
using AcademiaFight.Domain.Entities;
using AcademiaFight.Domain.Enums;
using AcademiaFight.Infrastructure.Data;
using AcademiaFight.Tests.Setup;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
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

    [Fact]
    public async Task Caracterizacao_DuasIrmasMesmoTelefone_LoginValidaApenasUmDosPerfis()
    {
        var telefone = $"(21) 9{Random.Shared.Next(1000, 9999)}-{Random.Shared.Next(1000, 9999)}";
        const string senhaA = "SenhaIrmaA123";
        const string senhaB = "SenhaIrmaB456";

        var irmaA = new Usuario
        {
            AcademiaId = ApiFactory.AcademiaId,
            Nome = "Irmã A Fixture",
            Telefone = telefone,
            SenhaHash = BCrypt.Net.BCrypt.HashPassword(senhaA, workFactor: 4),
            Perfil = PerfilUsuario.Aluno,
            Ativo = true,
        };
        var irmaB = new Usuario
        {
            AcademiaId = ApiFactory.AcademiaId,
            Nome = "Irmã B Fixture",
            Telefone = telefone,
            SenhaHash = BCrypt.Net.BCrypt.HashPassword(senhaB, workFactor: 4),
            Perfil = PerfilUsuario.Aluno,
            Ativo = true,
        };

        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.Usuarios.AddRange(irmaA, irmaB);
            await db.SaveChangesAsync();
        }

        try
        {
            var responseA = await _anonClient.PostAsJsonAsync("/api/auth/login", new
            {
                emailOuTelefone = telefone,
                senha = senhaA,
            });
            var responseB = await _anonClient.PostAsJsonAsync("/api/auth/login", new
            {
                emailOuTelefone = telefone,
                senha = senhaB,
            });

            var statuses = new[] { responseA.StatusCode, responseB.StatusCode };
            Assert.Single(statuses, status => status == HttpStatusCode.OK);
            Assert.Single(statuses, status => status == HttpStatusCode.Unauthorized);
        }
        finally
        {
            using var scope = _factory.Services.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var fixtures = await db.Usuarios
                .IgnoreQueryFilters()
                .Where(usuario => usuario.Telefone == telefone
                    && (usuario.Nome == "Irmã A Fixture" || usuario.Nome == "Irmã B Fixture"))
                .ToListAsync();
            db.Usuarios.RemoveRange(fixtures);
            await db.SaveChangesAsync();
        }
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
