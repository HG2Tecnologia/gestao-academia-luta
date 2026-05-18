using System.Net;
using System.Text.Json;

namespace AcademiaFight.API.Middleware;

public class ExceptionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionMiddleware> _logger;

    public ExceptionMiddleware(RequestDelegate next, ILogger<ExceptionMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (UnauthorizedAccessException ex)
        {
            _logger.LogWarning(ex, "Acesso não autorizado: {Mensagem}", ex.Message);
            await EscreverResposta(context, HttpStatusCode.Unauthorized, ex.Message);
        }
        catch (KeyNotFoundException ex)
        {
            _logger.LogWarning(ex, "Recurso não encontrado: {Mensagem}", ex.Message);
            await EscreverResposta(context, HttpStatusCode.NotFound, ex.Message);
        }
        catch (ArgumentException ex)
        {
            _logger.LogWarning(ex, "Argumento inválido: {Mensagem}", ex.Message);
            await EscreverResposta(context, HttpStatusCode.BadRequest, ex.Message);
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Operação inválida: {Mensagem}", ex.Message);
            await EscreverResposta(context, HttpStatusCode.BadRequest, ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Erro interno não tratado na requisição {Metodo} {Caminho}",
                context.Request.Method, context.Request.Path);

            await EscreverResposta(context, HttpStatusCode.InternalServerError,
                "Ocorreu um erro interno no servidor. Tente novamente ou contate o suporte.");
        }
    }

    private static async Task EscreverResposta(HttpContext context, HttpStatusCode statusCode, string mensagem)
    {
        context.Response.StatusCode = (int)statusCode;
        context.Response.ContentType = "application/json";

        var resposta = JsonSerializer.Serialize(new
        {
            sucesso = false,
            mensagem,
            timestamp = DateTime.UtcNow
        });

        await context.Response.WriteAsync(resposta);
    }
}
