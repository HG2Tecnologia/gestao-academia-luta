using AcademiaFight.Application.DTOs.Ranking;
using AcademiaFight.Domain.Enums;

namespace AcademiaFight.Application.Interfaces;

public interface IXpService
{
    Task AdicionarXpAsync(Guid alunoId, TipoEventoXp tipo, int pontos, Guid? referenciaId = null, CancellationToken ct = default);
    Task<int> GetXpTotalAsync(Guid alunoId, CancellationToken ct = default);
    Task<NivelAluno> GetNivelAsync(Guid alunoId, CancellationToken ct = default);
    Task<IEnumerable<HistoricoXpItemDto>> GetHistoricoXpAsync(Guid alunoId, CancellationToken ct = default);
}
