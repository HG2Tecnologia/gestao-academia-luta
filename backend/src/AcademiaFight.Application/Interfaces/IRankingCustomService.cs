using AcademiaFight.Application.DTOs.RankingCustom;

namespace AcademiaFight.Application.Interfaces;

public interface IRankingCustomService
{
    Task<IEnumerable<RankingCustomDto>> ListarAsync(bool incluirInativos = false, CancellationToken ct = default);
    Task<RankingCustomDto?> ObterAsync(Guid id, CancellationToken ct = default);
    Task<RankingCustomDto> CriarAsync(CriarRankingCustomRequest request, CancellationToken ct = default);
    Task<RankingCustomDto?> AtualizarAsync(Guid id, AtualizarRankingCustomRequest request, CancellationToken ct = default);
    Task<bool> DesativarAsync(Guid id, CancellationToken ct = default);

    Task<LeaderboardCustomDto?> GetLeaderboardAsync(Guid rankingId, int pagina = 1, CancellationToken ct = default);

    Task<LancamentoPontoDto> LancarPontosAsync(Guid rankingId, LancarPontosRequest request, Guid registradoPorId, CancellationToken ct = default);
    Task<bool> RemoverLancamentoAsync(Guid lancamentoId, CancellationToken ct = default);
    Task<IEnumerable<LancamentoPontoDto>> ListarLancamentosAsync(Guid rankingId, Guid? alunoId = null, CancellationToken ct = default);
}

public record CriarRankingCustomRequest(
    string Nome,
    string? Descricao,
    bool IncluirPresencas,
    bool IncluirPontosManuais,
    int PesoPresencas,
    int PesoManuais,
    bool VisivelParaAluno,
    DateOnly? DataInicio,
    DateOnly? DataFim
);

public record AtualizarRankingCustomRequest(
    string Nome,
    string? Descricao,
    bool IncluirPresencas,
    bool IncluirPontosManuais,
    int PesoPresencas,
    int PesoManuais,
    bool VisivelParaAluno,
    bool Ativo,
    DateOnly? DataInicio,
    DateOnly? DataFim
);

public record LancarPontosRequest(
    Guid AlunoId,
    int Pontos,
    string Descricao,
    DateOnly? Data
);
