using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Dashboard;
using AcademiaFight.Application.DTOs.Graduacao;

namespace AcademiaFight.Application.Interfaces;

public interface IDashboardService
{
    Task<BaseResponse<DashboardResumoDto>> GetResumoAsync(CancellationToken ct = default);
    Task<BaseResponse<IEnumerable<FrequenciaDiariaDto>>> GetFrequenciaDiariaAsync(int dias, CancellationToken ct = default);
    Task<BaseResponse<IEnumerable<AlunoProximoGraduacaoDto>>> GetAlunosProximosGraduacaoAsync(CancellationToken ct = default);
}
