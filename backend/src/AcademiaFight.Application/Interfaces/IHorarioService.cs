using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Horario;

namespace AcademiaFight.Application.Interfaces;

public interface IHorarioService
{
    Task<BaseResponse<GradeHorariosDto>> GetGradeAsync(CancellationToken ct = default);
    Task<BaseResponse<IEnumerable<HorarioDto>>> GetByTurmaAsync(Guid turmaId, CancellationToken ct = default);
    Task<BaseResponse<HorarioDto>> CreateAsync(CreateHorarioRequest request, CancellationToken ct = default);
    Task<BaseResponse<HorarioDto>> UpdateAsync(Guid id, CreateHorarioRequest request, CancellationToken ct = default);
    Task<BaseResponse> DeleteAsync(Guid id, CancellationToken ct = default);
}
