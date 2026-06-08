using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Academia;

namespace AcademiaFight.Application.Interfaces;

public interface IAcademiaService
{
    Task<BaseResponse<AcademiaDto>> ObterTenantAtualAsync(CancellationToken ct = default);
    Task<BaseResponse<AcademiaDto>> AtualizarAsync(UpdateAcademiaRequest request, CancellationToken ct = default);
    Task<BaseResponse> AtualizarTemplateContratoAsync(string? template, CancellationToken ct = default);
    Task<BaseResponse<AcademiaDto>> AtivarPlanoProAsync(DateTime? expiracao, CancellationToken ct = default);
}
