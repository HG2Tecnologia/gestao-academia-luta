using AcademiaFight.API.Hubs;
using AcademiaFight.Application.Interfaces;
using Microsoft.AspNetCore.SignalR;

namespace AcademiaFight.API.Services;

public class CatracaAgentNotifier : ICatracaAgentNotifier
{
    private readonly IHubContext<CatracaHub> _hub;

    public CatracaAgentNotifier(IHubContext<CatracaHub> hub)
    {
        _hub = hub;
    }

    public Task EnviarAbrirPortaAsync(Guid academiaId, CancellationToken ct = default)
        => _hub.Clients.Group($"catraca-{academiaId}").SendAsync("AbrirPorta", ct);

    public Task EnviarCadastrarUsuarioAsync(Guid academiaId, int deviceUserId, CancellationToken ct = default)
        => _hub.Clients.Group($"catraca-{academiaId}").SendAsync("CadastrarUsuario", deviceUserId, ct);

    public Task EnviarRemoverUsuarioAsync(Guid academiaId, int deviceUserId, CancellationToken ct = default)
        => _hub.Clients.Group($"catraca-{academiaId}").SendAsync("RemoverUsuario", deviceUserId, ct);
}
