using AcademiaFight.Application.DTOs.Ranking;

namespace AcademiaFight.Application.Interfaces;

public interface IRankingService
{
    Task<LeaderboardDto> GetLeaderboardTurmaAsync(Guid turmaId, string periodo, int pagina = 1, CancellationToken ct = default);
    Task<LeaderboardDto> GetLeaderboardAcademiaAsync(string periodo, int pagina = 1, CancellationToken ct = default);
    Task<LeaderboardPresencaDto?> GetLeaderboardModalidadeAsync(Guid modalidadeId, int pagina = 1, DateOnly? dataInicio = null, DateOnly? dataFim = null, CancellationToken ct = default);
    Task<LeaderboardPresencaDto> GetLeaderboardPresencasTurmaAsync(Guid turmaId, int pagina = 1, DateOnly? dataInicio = null, DateOnly? dataFim = null, CancellationToken ct = default);
    Task<PerfilGamificadoDto?> GetPerfilGamificadoAsync(Guid alunoId, CancellationToken ct = default);
}
