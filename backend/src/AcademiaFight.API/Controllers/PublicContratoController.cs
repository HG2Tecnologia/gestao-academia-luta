using AcademiaFight.Application.DTOs.Contrato;
using AcademiaFight.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace AcademiaFight.API.Controllers;

[ApiController]
[Route("api/public/contratos")]
public class PublicContratoController : ControllerBase
{
    private readonly IContratoService _service;

    public PublicContratoController(IContratoService service) => _service = service;

    [HttpGet("{token:guid}")]
    public async Task<IActionResult> Obter(Guid token, CancellationToken ct)
        => Ok(await _service.ObterPorTokenAsync(token, ct));

    [HttpPost("{token:guid}/assinar")]
    public async Task<IActionResult> Assinar(Guid token, [FromBody] AssinarContratoRequest request, CancellationToken ct)
    {
        var ip = HttpContext.Connection.RemoteIpAddress?.ToString();
        return Ok(await _service.AssinarPorTokenAsync(token, request, ip, ct));
    }
}
