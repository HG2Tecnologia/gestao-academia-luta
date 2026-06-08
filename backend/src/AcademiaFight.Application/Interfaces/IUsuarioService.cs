using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Aluno;
using AcademiaFight.Application.DTOs.Usuario;

namespace AcademiaFight.Application.Interfaces;

public interface IUsuarioService
{
    Task<BaseResponse<IEnumerable<UsuarioResumoDto>>> ListarProfessoresAsync(CancellationToken ct = default);
    Task<BaseResponse<PagedResult<AlunoDto>>> ListarAlunosAsync(string? nome, bool? ativo, int page, int pageSize, CancellationToken ct = default);
    Task<BaseResponse<AlunoDto>> ObterAlunoPorIdAsync(Guid id, CancellationToken ct = default);
    Task<BaseResponse<AlunoDto>> CriarAlunoAsync(CreateAlunoDto request, Guid academiaId, CancellationToken ct = default);
    Task<BaseResponse<AlunoDto>> AtualizarAlunoAsync(Guid id, UpdateAlunoDto request, CancellationToken ct = default);
    Task<BaseResponse<AlunoDto>> ToggleAtivoAlunoAsync(Guid id, bool ativo, CancellationToken ct = default);
    Task<BaseResponse<IEnumerable<AniversarianteDto>>> ListarAniversariantesAsync(int mes, CancellationToken ct = default);
    Task<BaseResponse<MeuPerfilDto>> ObterMeuPerfilAsync(Guid usuarioId, CancellationToken ct = default);
    Task<BaseResponse<MeuPerfilDto>> AtualizarMeuPerfilAsync(Guid usuarioId, AtualizarMeuPerfilRequest request, CancellationToken ct = default);
    Task<BaseResponse> RegistrarFcmTokenAsync(Guid usuarioId, string token, CancellationToken ct = default);
    Task<BaseResponse> ExcluirMinhaContaAsync(Guid usuarioId, CancellationToken ct = default);
}
