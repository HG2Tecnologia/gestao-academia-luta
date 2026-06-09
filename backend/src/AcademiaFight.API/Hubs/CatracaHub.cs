using Microsoft.AspNetCore.SignalR;

namespace AcademiaFight.API.Hubs;

/// <summary>
/// Hub SignalR para comunicação com o agente local da catraca.
///
/// O agente (.exe) se conecta a este hub passando apiKey e academiaId como query params.
/// Após autenticar, entra no grupo "catraca-{academiaId}" e aguarda comandos.
///
/// Quando o backend precisa abrir a porta, chama:
///   _hubContext.Clients.Group("catraca-{academiaId}").SendAsync("AbrirPorta")
/// O agente recebe e faz o HTTP call para o dispositivo Toletus local (169.254.x.x).
/// </summary>
public class CatracaHub : Hub
{
    private readonly IConfiguration _config;
    private readonly ILogger<CatracaHub> _logger;

    public CatracaHub(IConfiguration config, ILogger<CatracaHub> logger)
    {
        _config = config;
        _logger = logger;
    }

    /// <summary>
    /// Chamado pelo agente logo após conectar para se autenticar e entrar no grupo da academia.
    /// </summary>
    public async Task RegistrarAgente(string apiKey, string academiaId)
    {
        var chaveEsperada = _config["Catraca:ApiKey"];
        if (string.IsNullOrEmpty(chaveEsperada) || apiKey != chaveEsperada)
        {
            _logger.LogWarning("CatracaHub: tentativa de registro com API key inválida (academiaId={AcademiaId})", academiaId);
            await Clients.Caller.SendAsync("Erro", "API key inválida");
            Context.Abort();
            return;
        }

        var grupo = $"catraca-{academiaId}";
        await Groups.AddToGroupAsync(Context.ConnectionId, grupo);
        _logger.LogInformation("CatracaHub: agente {ConnId} registrado para academia {AcademiaId}", Context.ConnectionId, academiaId);
        await Clients.Caller.SendAsync("AgenteRegistrado", academiaId);
    }

    public override Task OnConnectedAsync()
    {
        _logger.LogDebug("CatracaHub: cliente conectado ({ConnId})", Context.ConnectionId);
        return base.OnConnectedAsync();
    }

    public override Task OnDisconnectedAsync(Exception? exception)
    {
        _logger.LogInformation("CatracaHub: agente desconectado ({ConnId})", Context.ConnectionId);
        return base.OnDisconnectedAsync(exception);
    }
}
