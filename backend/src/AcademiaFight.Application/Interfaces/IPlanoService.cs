using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Plano;

namespace AcademiaFight.Application.Interfaces;

public interface IPlanoService
{
    Task<BaseResponse<IEnumerable<PlanoDto>>> ListarAsync(CancellationToken ct = default);
    Task<BaseResponse<PlanoDto>> ObterPorIdAsync(Guid id, CancellationToken ct = default);
    Task<BaseResponse<PlanoDto>> CriarAsync(CreatePlanoDto dto, CancellationToken ct = default);
    Task<BaseResponse<PlanoDto>> AtualizarAsync(Guid id, UpdatePlanoDto dto, CancellationToken ct = default);
    Task<BaseResponse<bool>> DeletarAsync(Guid id, CancellationToken ct = default);
}
