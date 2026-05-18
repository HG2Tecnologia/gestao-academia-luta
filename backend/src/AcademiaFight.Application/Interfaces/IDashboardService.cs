using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Dashboard;

namespace AcademiaFight.Application.Interfaces;

public interface IDashboardService
{
    Task<BaseResponse<DashboardResumoDto>> GetResumoAsync(CancellationToken ct = default);
}
