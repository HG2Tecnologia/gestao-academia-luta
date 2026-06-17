using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Modalidade;

namespace AcademiaFight.Application.Interfaces;

public interface IModalidadeService
{
    Task<BaseResponse<IEnumerable<ModalidadeDto>>> ListarAsync(bool? ativo = null, CancellationToken ct = default);
    Task<BaseResponse<ModalidadeDto>> ToggleAtivoAsync(Guid id, CancellationToken ct = default);
    Task<BaseResponse<ModalidadeDto>> ObterPorIdAsync(Guid id, CancellationToken ct = default);
    Task<BaseResponse<ModalidadeDto>> CriarAsync(CreateModalidadeRequest request, CancellationToken ct = default);
    Task<BaseResponse<ModalidadeDto>> AtualizarAsync(Guid id, UpdateModalidadeRequest request, CancellationToken ct = default);
    Task<BaseResponse> RemoverAsync(Guid id, CancellationToken ct = default);
}
