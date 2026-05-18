using AcademiaFight.Application.DTOs.Graduacao;
using AcademiaFight.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AcademiaFight.API.Controllers;

[ApiController]
[Route("api/graduacoes")]
[Authorize]
public class GraduacaoController : ControllerBase
{
    private readonly IGraduacaoService _graduacaoService;

    public GraduacaoController(IGraduacaoService graduacaoService)
    {
        _graduacaoService = graduacaoService;
    }

    [HttpGet]
    public async Task<IActionResult> GetHistorico([FromQuery] Guid alunoId, CancellationToken ct)
    {
        var resultado = await _graduacaoService.GetHistoricoAlunoAsync(alunoId, ct);
        return Ok(resultado);
    }

    [HttpGet("aptos")]
    public async Task<IActionResult> GetAptos([FromQuery] Guid faixaId, CancellationToken ct)
    {
        var resultado = await _graduacaoService.GetAlunosAptosFaixaAsync(faixaId, ct);
        if (!resultado.Sucesso)
            return BadRequest(resultado);
        return Ok(resultado);
    }

    [HttpPost]
    public async Task<IActionResult> Registrar([FromBody] RegistrarGraduacaoRequest request, CancellationToken ct)
    {
        var resultado = await _graduacaoService.RegistrarAsync(request, ct);
        if (!resultado.Sucesso)
            return resultado.Mensagem?.Contains("já possui") == true ? Conflict(resultado) : BadRequest(resultado);
        return Ok(resultado);
    }
}
