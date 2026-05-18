using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Graduacao;

namespace AcademiaFight.Application.Interfaces;

public interface IGraduacaoService
{
    Task<BaseResponse<IEnumerable<GraduacaoDto>>> GetHistoricoAlunoAsync(Guid alunoId, CancellationToken ct = default);
    Task<BaseResponse<GraduacaoDto?>> GetFaixaAtualAsync(Guid alunoId, Guid modalidadeId, CancellationToken ct = default);
    Task<BaseResponse<GraduacaoDto>> RegistrarAsync(RegistrarGraduacaoRequest request, CancellationToken ct = default);
    Task<BaseResponse<IEnumerable<AlunoAptoDto>>> GetAlunosAptosFaixaAsync(Guid faixaId, CancellationToken ct = default);
}
