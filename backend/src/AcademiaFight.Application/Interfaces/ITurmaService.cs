using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Matricula;
using AcademiaFight.Application.DTOs.Turma;

namespace AcademiaFight.Application.Interfaces;

public interface ITurmaService
{
    Task<BaseResponse<IEnumerable<TurmaDto>>> ListarAsync(CancellationToken ct = default);
    Task<BaseResponse<TurmaDto>> ObterPorIdAsync(Guid id, CancellationToken ct = default);
    Task<BaseResponse<TurmaDetalheDto>> GetDetalheAsync(Guid turmaId, CancellationToken ct = default);
    Task<BaseResponse<TurmaDto>> CriarAsync(CreateTurmaRequest request, CancellationToken ct = default);
    Task<BaseResponse<TurmaDto>> AtualizarAsync(Guid id, UpdateTurmaRequest request, CancellationToken ct = default);
    Task<BaseResponse> RemoverAsync(Guid id, CancellationToken ct = default);
    Task<BaseResponse<IEnumerable<MatriculaDto>>> GetAlunosDaTurmaAsync(Guid turmaId, CancellationToken ct = default);
    Task<BaseResponse<MatriculaDto>> MatricularAlunoAsync(Guid turmaId, Guid alunoId, CancellationToken ct = default);
    Task<BaseResponse> DesmatricularAlunoAsync(Guid turmaId, Guid alunoId, CancellationToken ct = default);
}
