using AcademiaFight.Domain.Interfaces;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;

namespace AcademiaFight.Infrastructure.Tenant;

public class TenantMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<TenantMiddleware> _logger;

    private static readonly string[] RotasPublicas =
    [
        "/api/auth/login",
        "/api/auth/register",
        "/api/auth/refresh",
        "/api/auth/logout",
        "/api/public/",
        "/swagger",
        "/health"
    ];

    public TenantMiddleware(RequestDelegate next, ILogger<TenantMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context, ITenantContext tenantContext)
    {
        var caminho = context.Request.Path.Value ?? string.Empty;

        // Rotas públicas não precisam de tenant
        if (RotasPublicas.Any(r => caminho.StartsWith(r, StringComparison.OrdinalIgnoreCase)))
        {
            await _next(context);
            return;
        }

        // Prioridade 1: claim academia_id do JWT já autenticado
        if (context.User?.Identity?.IsAuthenticated == true)
        {
            var claimAcademiaId = context.User.FindFirst("academia_id")?.Value;
            if (Guid.TryParse(claimAcademiaId, out var academiaIdDoJwt))
            {
                tenantContext.SetTenant(academiaIdDoJwt);
                _logger.LogDebug("Tenant resolvido via JWT: {AcademiaId}", academiaIdDoJwt);
                await _next(context);
                return;
            }
        }

        // Prioridade 2: header X-Tenant-ID
        var headerTenant = context.Request.Headers["X-Tenant-ID"].FirstOrDefault();
        if (Guid.TryParse(headerTenant, out var academiaIdDoHeader))
        {
            tenantContext.SetTenant(academiaIdDoHeader);
            _logger.LogDebug("Tenant resolvido via header: {AcademiaId}", academiaIdDoHeader);
            await _next(context);
            return;
        }

        _logger.LogWarning("Requisição sem tenant identificado para {Caminho}", caminho);

        context.Response.StatusCode = StatusCodes.Status401Unauthorized;
        context.Response.ContentType = "application/json";

        await context.Response.WriteAsJsonAsync(new
        {
            sucesso = false,
            mensagem = "Tenant não identificado. Informe o cabeçalho X-Tenant-ID ou realize login com um token válido."
        });
    }
}
