using AcademiaFight.Application.Interfaces;
using AcademiaFight.Domain.Entities;
using AcademiaFight.Domain.Enums;
using AcademiaFight.Infrastructure.Data;
using Hangfire;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;

namespace AcademiaFight.Tests.Setup;

public class ApiFactory : WebApplicationFactory<Program>
{
    // IDs fixos para uso nos testes
    public static readonly Guid AcademiaId    = Guid.Parse("a0000000-0000-0000-0000-000000000001");
    public static readonly Guid AdminId       = Guid.Parse("a0000000-0000-0000-0000-000000000002");
    public static readonly Guid AlunoId       = Guid.Parse("a0000000-0000-0000-0000-000000000003");
    public static readonly Guid ProfessorId   = Guid.Parse("a0000000-0000-0000-0000-000000000004");
    public static readonly Guid ModalidadeId  = Guid.Parse("a0000000-0000-0000-0000-000000000005");
    public static readonly Guid TurmaId       = Guid.Parse("a0000000-0000-0000-0000-000000000006");
    public static readonly Guid PagamentoId   = Guid.Parse("a0000000-0000-0000-0000-000000000007");
    public static readonly Guid FuncionarioId = Guid.Parse("a0000000-0000-0000-0000-000000000008");

    public const string AdminEmail     = "admin@academia-test.com";
    public const string AlunoEmail     = "aluno@academia-test.com";
    public const string ProfessorEmail = "professor@academia-test.com";
    public const string SenhaPadrao    = "Senha123";

    // Nome único por instância para não compartilhar banco entre factories paralelas
    private readonly string _dbName = $"AcademiaFightTest_{Guid.NewGuid()}";

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");

        builder.ConfigureAppConfiguration((_, cfg) =>
        {
            cfg.AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["ConnectionStrings:DefaultConnection"] = "Host=localhost;Database=testdb;Username=test;Password=test",
                ["Jwt:SecretKey"]  = "CHAVE_DEV_APENAS_NAO_USAR_EM_PRODUCAO_32_CHARS_OK",
                ["Jwt:Issuer"]     = "AcademiaFightAPI",
                ["Jwt:Audience"]   = "AcademiaFightApp",
                ["Smtp:Host"]      = "localhost",
                ["Smtp:Port"]      = "25",
                ["Smtp:User"]      = "test",
                ["Smtp:Pass"]      = "test",
                ["Smtp:From"]      = "test@test.com",
            });
        });

        builder.ConfigureTestServices(services =>
        {
            // Remove DbContext Npgsql e re-registra com InMemory.
            // Usa UseInternalServiceProvider para evitar conflito de provider
            // (Npgsql ainda está registrado no DI raiz).
            var descriptors = services
                .Where(d => d.ServiceType == typeof(DbContextOptions<AppDbContext>)
                         || d.ServiceType == typeof(AppDbContext)
                         || (d.ImplementationType != null && d.ImplementationType == typeof(AppDbContext)))
                .ToList();
            foreach (var d in descriptors) services.Remove(d);

            var inMemoryProvider = new ServiceCollection()
                .AddEntityFrameworkInMemoryDatabase()
                .BuildServiceProvider();

            services.AddDbContext<AppDbContext>((_, opt) =>
                opt.UseInMemoryDatabase(_dbName)
                   .UseInternalServiceProvider(inMemoryProvider)
                   .EnableSensitiveDataLogging());

            services.AddScoped<IAppDbContext>(sp => sp.GetRequiredService<AppDbContext>());

            // Substitui storage do Hangfire por InMemory (sem conexão real)
            services.AddHangfire(cfg => cfg.UseInMemoryStorage());
        });
    }

    private bool _seeded;

    public void EnsureSeeded()
    {
        if (_seeded) return;
        _seeded = true;

        using var scope = Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        db.Database.EnsureCreated();

        if (db.Academias.Any()) return;

        // BCrypt hash gerado com workFactor 4 (rápido para testes)
        var senhaHash = BCrypt.Net.BCrypt.HashPassword(SenhaPadrao, workFactor: 4);

        var academia = new Academia
        {
            Nome       = "Academia Teste",
            Subdominio = "academia-test",
            Email      = "contato@academia-test.com",
            Ativo      = true,
        };
        SetId(academia, AcademiaId);
        db.Academias.Add(academia);

        var admin = new Usuario
        {
            AcademiaId = AcademiaId,
            Nome       = "Admin Teste",
            Email      = AdminEmail,
            SenhaHash  = senhaHash,
            Perfil     = PerfilUsuario.Admin,
            Ativo      = true,
        };
        SetId(admin, AdminId);
        db.Usuarios.Add(admin);

        var aluno = new Usuario
        {
            AcademiaId = AcademiaId,
            Nome       = "Aluno Teste",
            Email      = AlunoEmail,
            SenhaHash  = senhaHash,
            Perfil     = PerfilUsuario.Aluno,
            Ativo      = true,
        };
        SetId(aluno, AlunoId);
        db.Usuarios.Add(aluno);

        var professor = new Usuario
        {
            AcademiaId = AcademiaId,
            Nome       = "Professor Teste",
            Email      = ProfessorEmail,
            SenhaHash  = senhaHash,
            Perfil     = PerfilUsuario.Professor,
            Ativo      = true,
        };
        SetId(professor, ProfessorId);
        db.Usuarios.Add(professor);

        var funcionario = new Funcionario
        {
            AcademiaId    = AcademiaId,
            UsuarioId     = ProfessorId,
            Cargo         = "Professor",
            DataAdmissao  = DateTime.UtcNow.AddYears(-1),
        };
        SetId(funcionario, FuncionarioId);
        db.Funcionarios.Add(funcionario);

        var modalidade = new Modalidade
        {
            AcademiaId = AcademiaId,
            Nome       = "Jiu-Jitsu",
            Descricao  = "Arte marcial brasileira",
            Ativo      = true,
        };
        SetId(modalidade, ModalidadeId);
        db.Modalidades.Add(modalidade);

        var turma = new Turma
        {
            AcademiaId      = AcademiaId,
            ModalidadeId    = ModalidadeId,
            ProfessorId     = ProfessorId,
            Nome            = "Turma Iniciante",
            Nivel           = "Iniciante",
            CapacidadeMaxima = 20,
            Ativo           = true,
        };
        SetId(turma, TurmaId);
        db.Turmas.Add(turma);

        var pagamento = new Pagamento
        {
            AcademiaId     = AcademiaId,
            AlunoId        = AlunoId,
            Tipo           = TipoPagamento.Mensalidade,
            Status         = StatusPagamento.Pendente,
            Valor          = 150m,
            Descricao      = "Mensalidade Teste",
            DataVencimento = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(5)),
        };
        SetId(pagamento, PagamentoId);
        db.Pagamentos.Add(pagamento);

        db.SaveChanges();
    }

    // EntityBase.Id tem protected setter — precisamos usar reflexão para setar nos testes
    private static void SetId(object entity, Guid id)
    {
        var prop = entity.GetType().GetProperty("Id",
            System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Instance);
        prop?.SetValue(entity, id);
    }

    public HttpClient CreateAdminClient()
    {
        var client = CreateClient();
        var token = TestAuthHelper.GerarToken(AdminId, AcademiaId, AdminEmail, "Admin Teste", PerfilUsuario.Admin);
        client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);
        return client;
    }

    public HttpClient CreateAlunoClient()
    {
        var client = CreateClient();
        var token = TestAuthHelper.GerarToken(AlunoId, AcademiaId, AlunoEmail, "Aluno Teste", PerfilUsuario.Aluno);
        client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);
        return client;
    }

    public HttpClient CreateProfessorClient()
    {
        var client = CreateClient();
        var token = TestAuthHelper.GerarToken(ProfessorId, AcademiaId, ProfessorEmail, "Professor Teste", PerfilUsuario.Professor);
        client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);
        return client;
    }
}
