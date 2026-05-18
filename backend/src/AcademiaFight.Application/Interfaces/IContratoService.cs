using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Contrato;

namespace AcademiaFight.Application.Interfaces;

public interface IContratoService
{
    Task<BaseResponse<IEnumerable<ContratoDto>>> ListarAsync(Guid? alunoId = null, CancellationToken ct = default);
    Task<BaseResponse<ContratoDetalheDto>> ObterAsync(Guid id, CancellationToken ct = default);
    Task<BaseResponse<ContratoPublicoDto>> ObterPorTokenAsync(Guid token, CancellationToken ct = default);
    Task<BaseResponse<ContratoDto>> CriarAsync(CreateContratoRequest request, CancellationToken ct = default);
    Task<BaseResponse<ContratoDto>> AssinarAsync(Guid id, AssinarContratoRequest request, string? ipAddress, CancellationToken ct = default);
    Task<BaseResponse<ContratoDto>> AssinarPorTokenAsync(Guid token, AssinarContratoRequest request, string? ipAddress, CancellationToken ct = default);
    Task<BaseResponse> CancelarAsync(Guid id, CancellationToken ct = default);
}
