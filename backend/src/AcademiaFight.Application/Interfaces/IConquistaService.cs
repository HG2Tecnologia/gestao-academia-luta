using AcademiaFight.Application.DTOs.Ranking;

namespace AcademiaFight.Application.Interfaces;

public interface IConquistaService
{
    Task<IEnumerable<ConquistaDto>> VerificarEDesbloquerarAsync(Guid alunoId, Guid academiaId, CancellationToken ct = default);
    Task<IEnumerable<ConquistaDto>> GetConquistasAlunoAsync(Guid alunoId, CancellationToken ct = default);
    Task<IEnumerable<ConquistaDto>> GetNovasConquistasAsync(Guid alunoId, CancellationToken ct = default);
    Task MarcarComoVistasAsync(Guid alunoId, CancellationToken ct = default);
}
