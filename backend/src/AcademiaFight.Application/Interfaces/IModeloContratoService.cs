using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Contrato;

namespace AcademiaFight.Application.Interfaces;

public interface IModeloContratoService
{
    Task<BaseResponse<IEnumerable<ModeloContratoDto>>> ListarAsync(CancellationToken ct = default);
    Task<BaseResponse<ModeloContratoDto>> ObterAsync(Guid id, CancellationToken ct = default);
    Task<BaseResponse<ModeloContratoDto>> CriarAsync(CreateModeloContratoRequest request, CancellationToken ct = default);
    Task<BaseResponse<ModeloContratoDto>> AtualizarAsync(Guid id, UpdateModeloContratoRequest request, CancellationToken ct = default);
    Task<BaseResponse> ExcluirAsync(Guid id, CancellationToken ct = default);
}
