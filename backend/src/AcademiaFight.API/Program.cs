using System.Text;
using AcademiaFight.API.Hubs;
using AcademiaFight.API.Middleware;
using AcademiaFight.API.Services;
using AcademiaFight.Application.Interfaces;
using AcademiaFight.Application.Services;
using AcademiaFight.Domain.Interfaces;
using AcademiaFight.Infrastructure.Data;
using AcademiaFight.Infrastructure.Jobs;
using AcademiaFight.Infrastructure.Services;
using AcademiaFight.Infrastructure.Tenant;
using Hangfire;
using Hangfire.PostgreSql;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

var connStr = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? throw new InvalidOperationException("ConnectionStrings:DefaultConnection não configurado.");

// 1. DbContext
builder.Services.AddDbContext<AppDbContext>((_, options) =>
    options.UseNpgsql(connStr, npgsql =>
        npgsql.MigrationsAssembly("AcademiaFight.Infrastructure")));

// 2. Hangfire
builder.Services.AddHangfire(config => config
    .SetDataCompatibilityLevel(CompatibilityLevel.Version_180)
    .UseSimpleAssemblyNameTypeSerializer()
    .UseRecommendedSerializerSettings()
    .UsePostgreSqlStorage(o => o.UseNpgsqlConnection(connStr)));

builder.Services.AddHangfireServer();

// 3. SignalR
builder.Services.AddSignalR();

// 4. Repositórios e serviços (Scoped)
builder.Services.AddScoped<IAppDbContext>(sp => sp.GetRequiredService<AppDbContext>());
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IAcademiaService, AcademiaService>();
builder.Services.AddScoped<IModalidadeService, ModalidadeService>();
builder.Services.AddScoped<ITurmaService, TurmaService>();
builder.Services.AddScoped<IHorarioService, HorarioService>();
builder.Services.AddScoped<IMatriculaService, MatriculaService>();
builder.Services.AddScoped<IPresencaService, PresencaService>();
builder.Services.AddScoped<IFaixaService, FaixaService>();
builder.Services.AddScoped<IGraduacaoService, GraduacaoService>();
builder.Services.AddScoped<IModalidadeSeedService, ModalidadeSeedService>();
builder.Services.AddScoped<IDashboardService, DashboardService>();
builder.Services.AddScoped<IUsuarioService, UsuarioService>();
builder.Services.AddScoped<IFuncionarioService, FuncionarioService>();
builder.Services.AddScoped<IXpService, XpService>();
builder.Services.AddScoped<IConquistaService, ConquistaService>();
builder.Services.AddScoped<IRankingService, RankingService>();
builder.Services.AddScoped<IRankingCustomService, RankingCustomService>();
builder.Services.AddScoped<IFinanceiroService, FinanceiroService>();
builder.Services.AddScoped<IPlanoService, PlanoService>();
builder.Services.AddScoped<IContratoService, ContratoService>();
builder.Services.AddScoped<IModeloContratoService, ModeloContratoService>();
builder.Services.AddScoped<INotificacaoService, NotificacaoService>();
builder.Services.AddScoped<IRankingNotifier, RankingNotifier>();
builder.Services.AddScoped<ICatracaAgentNotifier, CatracaAgentNotifier>();
builder.Services.AddScoped<IPasswordHasher, BCryptPasswordHasher>();
builder.Services.AddScoped<IEmailService, SmtpEmailService>();
builder.Services.AddScoped<RankingMensalResetJob>();
builder.Services.AddScoped<IAtestadoService, AtestadoService>();
builder.Services.AddScoped<AtestadoVencimentoJob>();
builder.Services.AddScoped<INoticiaService, NoticiaService>();
builder.Services.AddScoped<IGrupoFamiliarService, GrupoFamiliarService>();
builder.Services.AddScoped<ParQService>();
builder.Services.AddScoped<ICatracaService, CatracaService>();
builder.Services.AddScoped<IToletusCatracaClient, ToletusCatracaClient>();
builder.Services.AddHttpClient("toletus");  // HttpClient nomeado para chamadas ao dispositivo Toletus

// 5. TenantContext (Scoped)
builder.Services.AddScoped<ITenantContext, TenantContext>();

// 6. TokenService e QrTokenService (Singleton — sem estado)
builder.Services.AddSingleton<ITokenService, TokenService>();
builder.Services.AddSingleton<IQrTokenService, QrTokenService>();

// 7. JWT Authentication
var jwtSecretKey = builder.Configuration["Jwt:SecretKey"]
    ?? throw new InvalidOperationException("Jwt:SecretKey não configurado.");

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"],
        ValidateAudience = true,
        ValidAudience = builder.Configuration["Jwt:Audience"],
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecretKey)),
        ValidateLifetime = true,
        ClockSkew = TimeSpan.Zero
    };

    // Permitir token via query string para SignalR
    options.Events = new JwtBearerEvents
    {
        OnMessageReceived = context =>
        {
            var accessToken = context.Request.Query["access_token"];
            var path = context.HttpContext.Request.Path;
            if (!string.IsNullOrEmpty(accessToken) && path.StartsWithSegments("/hubs"))
                context.Token = accessToken;
            return Task.CompletedTask;
        }
    };
});

// 8. Authorization
builder.Services.AddAuthorization();

// 9. CORS
var origensPermitidas = builder.Configuration.GetSection("AllowedOrigins").Get<string[]>()
    ?? ["http://localhost:4200", "http://localhost:64661"];

builder.Services.AddCors(options =>
{
    options.AddPolicy("PoliticaPadrao", policy =>
    {
        if (builder.Environment.IsDevelopment())
        {
            policy.SetIsOriginAllowed(origin => new Uri(origin).Host == "localhost")
                  .AllowAnyHeader()
                  .AllowAnyMethod()
                  .AllowCredentials();
        }
        else
        {
            policy.WithOrigins(origensPermitidas)
                  .AllowAnyHeader()
                  .AllowAnyMethod()
                  .AllowCredentials();
        }
    });
});

// 10. Swagger
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "Academia Fight API",
        Version = "v1",
        Description = "API para gestão de academias de luta — multi-tenant SaaS"
    });

    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "JWT Authorization: Bearer {token}",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" }
            },
            Array.Empty<string>()
        }
    });
});

builder.Services.AddControllers();

var app = builder.Build();

app.UseCors("PoliticaPadrao");
app.UseStaticFiles();

app.UseMiddleware<ExceptionMiddleware>();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c => c.SwaggerEndpoint("/swagger/v1/swagger.json", "Academia Fight API v1"));
}

app.UseAuthentication();
app.UseMiddleware<TenantMiddleware>();
app.UseAuthorization();

app.MapControllers();
app.MapHub<RankingHub>("/hubs/ranking");
app.MapHub<CatracaHub>("/hubs/catraca");
app.MapMethods("/health", ["GET", "HEAD"], () => Results.Ok(new { status = "healthy", timestamp = DateTime.UtcNow }));

app.UseHangfireDashboard("/hangfire", new DashboardOptions
{
    Authorization = [new HangfireAuthorizationFilter()]
});

// Rodar migrations automaticamente no startup
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    db.Database.Migrate();
}

// Registrar job recorrente: reset XP mensal no dia 1 de cada mês às 00:01 (UTC)
RecurringJob.AddOrUpdate<RankingMensalResetJob>(
    "ranking-reset-mensal",
    job => job.ExecutarAsync(),
    "1 0 1 * *",
    new RecurringJobOptions { TimeZone = TimeZoneInfo.Utc });

// Verificar vencimentos de atestados médicos diariamente às 08:00 (UTC)
RecurringJob.AddOrUpdate<AtestadoVencimentoJob>(
    "atestado-vencimento-diario",
    job => job.ExecutarAsync(),
    "0 8 * * *",
    new RecurringJobOptions { TimeZone = TimeZoneInfo.Utc });

app.Run();

// Necessário para WebApplicationFactory nos testes de integração
public partial class Program { }
