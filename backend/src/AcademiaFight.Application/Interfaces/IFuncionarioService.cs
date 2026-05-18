using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Funcionario;

namespace AcademiaFight.Application.Interfaces;

public interface IFuncionarioService
{
    Task<BaseResponse<IEnumerable<FuncionarioDto>>> ListarAsync(string? nome, string? perfil, CancellationToken ct = default);
    Task<BaseResponse<FuncionarioDto>> ObterPorIdAsync(Guid id, CancellationToken ct = default);
    Task<BaseResponse<FuncionarioDto>> CriarAsync(CreateFuncionarioDto request, Guid academiaId, CancellationToken ct = default);
    Task<BaseResponse<FuncionarioDto>> AtualizarAsync(Guid id, UpdateFuncionarioDto request, CancellationToken ct = default);
    Task<BaseResponse> RemoverAsync(Guid id, CancellationToken ct = default);
}
