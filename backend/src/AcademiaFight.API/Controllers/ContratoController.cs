using AcademiaFight.Application.DTOs.Contrato;
using AcademiaFight.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AcademiaFight.API.Controllers;

[ApiController]
[Route("api/contratos")]
[Authorize]
public class ContratoController : ControllerBase
{
    private readonly IContratoService _contratoService;

    public ContratoController(IContratoService contratoService)
    {
        _contratoService = contratoService;
    }

    [HttpGet]
    public async Task<IActionResult> Listar([FromQuery] Guid? alunoId, CancellationToken ct)
    {
        var resultado = await _contratoService.ListarAsync(alunoId, ct);
        return Ok(resultado);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> Obter(Guid id, CancellationToken ct)
    {
        var resultado = await _contratoService.ObterAsync(id, ct);
        return Ok(resultado);
    }

    [HttpPost]
    public async Task<IActionResult> Criar([FromBody] CreateContratoRequest request, CancellationToken ct)
    {
        var resultado = await _contratoService.CriarAsync(request, ct);
        return Ok(resultado);
    }

    [HttpPost("{id:guid}/assinar")]
    public async Task<IActionResult> Assinar(Guid id, [FromBody] AssinarContratoRequest request, CancellationToken ct)
    {
        var ip = HttpContext.Connection.RemoteIpAddress?.ToString();
        var resultado = await _contratoService.AssinarAsync(id, request, ip, ct);
        return Ok(resultado);
    }

    [HttpPost("{id:guid}/cancelar")]
    public async Task<IActionResult> Cancelar(Guid id, CancellationToken ct)
    {
        var resultado = await _contratoService.CancelarAsync(id, ct);
        return Ok(resultado);
    }
}
