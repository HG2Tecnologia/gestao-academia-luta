using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.GrupoFamiliar;

namespace AcademiaFight.Application.Interfaces;

public interface IGrupoFamiliarService
{
    Task<BaseResponse<IEnumerable<GrupoFamiliarDto>>> ListarAsync(CancellationToken ct = default);
    Task<BaseResponse<GrupoFamiliarDto>> CriarAsync(string nome, CancellationToken ct = default);
    Task<BaseResponse<GrupoFamiliarDto>> RenomearAsync(Guid id, string nome, CancellationToken ct = default);
    Task<BaseResponse> ExcluirAsync(Guid id, CancellationToken ct = default);
    Task<BaseResponse<GrupoFamiliarDto>> AdicionarMembroAsync(Guid grupoId, Guid alunoId, CancellationToken ct = default);
    Task<BaseResponse<GrupoFamiliarDto>> RemoverMembroAsync(Guid grupoId, Guid alunoId, CancellationToken ct = default);
    Task<BaseResponse<GrupoFamiliarDto?>> ObterPorAlunoAsync(Guid alunoId, CancellationToken ct = default);
}
