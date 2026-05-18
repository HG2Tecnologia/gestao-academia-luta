using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Matricula;

namespace AcademiaFight.Application.Interfaces;

public interface IMatriculaService
{
    Task<BaseResponse<IEnumerable<MatriculaDto>>> GetByAlunoAsync(Guid alunoId, CancellationToken ct = default);
    Task<BaseResponse<IEnumerable<MatriculaDto>>> GetByTurmaAsync(Guid turmaId, CancellationToken ct = default);
    Task<BaseResponse<MatriculaDto>> CreateAsync(CreateMatriculaRequest request, CancellationToken ct = default);
    Task<BaseResponse> DeleteAsync(Guid matriculaId, CancellationToken ct = default);
}
