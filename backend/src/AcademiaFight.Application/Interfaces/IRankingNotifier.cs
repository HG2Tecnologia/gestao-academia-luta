using AcademiaFight.Application.DTOs.Ranking;

namespace AcademiaFight.Application.Interfaces;

public interface IRankingNotifier
{
    Task NotificarAtualizacaoRankingAsync(Guid academiaId, LeaderboardItemDto item, CancellationToken ct = default);
    Task NotificarNovaConquistaAsync(Guid academiaId, ConquistaDto conquista, CancellationToken ct = default);
    Task NotificarNovaNotificacaoAsync(Guid academiaId, CancellationToken ct = default);
}
