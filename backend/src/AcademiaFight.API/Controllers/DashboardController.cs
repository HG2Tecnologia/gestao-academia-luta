using AcademiaFight.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AcademiaFight.API.Controllers;

[ApiController]
[Route("api/dashboard")]
[Authorize]
public class DashboardController : ControllerBase
{
    private readonly IDashboardService _dashboardService;

    public DashboardController(IDashboardService dashboardService)
    {
        _dashboardService = dashboardService;
    }

    [HttpGet("resumo")]
    public async Task<IActionResult> GetResumo(CancellationToken ct)
    {
        var resultado = await _dashboardService.GetResumoAsync(ct);
        return Ok(resultado);
    }

    [HttpGet("frequencia")]
    public async Task<IActionResult> GetFrequencia([FromQuery] int dias = 14, CancellationToken ct = default)
    {
        if (dias < 7) dias = 7;
        if (dias > 90) dias = 90;
        var resultado = await _dashboardService.GetFrequenciaDiariaAsync(dias, ct);
        return Ok(resultado);
    }

    [HttpGet("proximos-graduacao")]
    public async Task<IActionResult> GetProximosGraduacao(CancellationToken ct)
    {
        var resultado = await _dashboardService.GetAlunosProximosGraduacaoAsync(ct);
        return Ok(resultado);
    }
}
