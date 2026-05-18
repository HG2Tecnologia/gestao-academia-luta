using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Faixa;

namespace AcademiaFight.Application.Interfaces;

public interface IFaixaService
{
    Task<BaseResponse<IEnumerable<FaixaDto>>> GetByModalidadeAsync(Guid? modalidadeId, CancellationToken ct = default);
    Task<BaseResponse<FaixaDto>> CreateAsync(CreateFaixaRequest request, CancellationToken ct = default);
    Task<BaseResponse<FaixaDto>> UpdateAsync(Guid id, CreateFaixaRequest request, CancellationToken ct = default);
    Task<BaseResponse> DeleteAsync(Guid id, CancellationToken ct = default);
    Task<BaseResponse> ReordenarAsync(ReordenarFaixasRequest request, CancellationToken ct = default);
}
