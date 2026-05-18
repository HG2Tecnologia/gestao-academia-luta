using AcademiaFight.Application.DTOs.Academia;
using AcademiaFight.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AcademiaFight.API.Controllers;

[ApiController]
[Route("api/academia")]
[Authorize]
public class AcademiaController : ControllerBase
{
    private readonly IAcademiaService _academiaService;

    public AcademiaController(IAcademiaService academiaService)
    {
        _academiaService = academiaService;
    }

    [HttpGet]
    public async Task<IActionResult> ObterTenantAtual(CancellationToken ct)
    {
        var resultado = await _academiaService.ObterTenantAtualAsync(ct);

        if (!resultado.Sucesso)
            return NotFound(resultado);

        return Ok(resultado);
    }

    [HttpPut]
    public async Task<IActionResult> Atualizar([FromBody] UpdateAcademiaRequest request, CancellationToken ct)
    {
        var resultado = await _academiaService.AtualizarAsync(request, ct);

        if (!resultado.Sucesso)
            return BadRequest(resultado);

        return Ok(resultado);
    }

    [HttpPut("template-contrato")]
    public async Task<IActionResult> AtualizarTemplate([FromBody] UpdateTemplateContratoRequest request, CancellationToken ct)
    {
        var resultado = await _academiaService.AtualizarTemplateContratoAsync(request.Template, ct);
        return Ok(resultado);
    }
}
