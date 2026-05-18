using AcademiaFight.API.Hubs;
using AcademiaFight.Application.DTOs.Ranking;
using AcademiaFight.Application.Interfaces;
using Microsoft.AspNetCore.SignalR;

namespace AcademiaFight.API.Services;

public class RankingNotifier : IRankingNotifier
{
    private readonly IHubContext<RankingHub> _hub;

    public RankingNotifier(IHubContext<RankingHub> hub)
    {
        _hub = hub;
    }

    public async Task NotificarAtualizacaoRankingAsync(Guid academiaId, LeaderboardItemDto item, CancellationToken ct = default)
    {
        await _hub.Clients.Group($"ranking-{academiaId}")
            .SendAsync("ReceberAtualizacaoRanking", item, ct);
    }

    public async Task NotificarNovaConquistaAsync(Guid academiaId, ConquistaDto conquista, CancellationToken ct = default)
    {
        await _hub.Clients.Group($"ranking-{academiaId}")
            .SendAsync("ReceberNovaConquista", conquista, ct);
    }

    public async Task NotificarNovaNotificacaoAsync(Guid academiaId, CancellationToken ct = default)
    {
        await _hub.Clients.Group($"ranking-{academiaId}")
            .SendAsync("ReceberNovaNotificacao", ct);
    }
}
