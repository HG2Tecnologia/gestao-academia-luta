namespace AcademiaFight.Application.Interfaces;

/// <summary>
/// Envia comandos ao agente local da catraca via SignalR.
/// Implementado em AcademiaFight.API.Services.CatracaAgentNotifier.
/// </summary>
public interface ICatracaAgentNotifier
{
    Task EnviarAbrirPortaAsync(Guid academiaId, CancellationToken ct = default);
    Task EnviarCadastrarUsuarioAsync(Guid academiaId, int deviceUserId, CancellationToken ct = default);
    Task EnviarRemoverUsuarioAsync(Guid academiaId, int deviceUserId, CancellationToken ct = default);
}
