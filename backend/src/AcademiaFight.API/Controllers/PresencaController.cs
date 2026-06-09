using AcademiaFight.Application.DTOs.Presenca;
using AcademiaFight.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AcademiaFight.API.Controllers;

[ApiController]
[Route("api/presencas")]
[Authorize]
public class PresencaController : ControllerBase
{
    private readonly IPresencaService _presencaService;

    public PresencaController(IPresencaService presencaService)
    {
        _presencaService = presencaService;
    }

    [HttpPost]
    public async Task<IActionResult> Registrar([FromBody] RegistrarPresencaRequest request, CancellationToken ct)
    {
        var resultado = await _presencaService.RegistrarAsync(request, ct);
        if (!resultado.Sucesso)
            return BadRequest(resultado);
        return Ok(resultado);
    }

    [HttpPost("qrcode")]
    public async Task<IActionResult> RegistrarQrCode([FromBody] QrCodeRequest request, CancellationToken ct)
    {
        var resultado = await _presencaService.RegistrarPorQrCodeAsync(request.Token, ct);
        if (!resultado.Sucesso)
            return BadRequest(resultado);
        return Ok(resultado);
    }

    [HttpGet]
    public async Task<IActionResult> GetHistorico(
        [FromQuery] Guid alunoId,
        [FromQuery] DateOnly de,
        [FromQuery] DateOnly ate,
        CancellationToken ct)
    {
        var resultado = await _presencaService.GetHistoricoAlunoAsync(alunoId, de, ate, ct);
        return Ok(resultado);
    }

    [HttpGet("aula")]
    public async Task<IActionResult> GetPresencasAula(
        [FromQuery] Guid horarioId,
        [FromQuery] DateOnly data,
        CancellationToken ct)
    {
        var resultado = await _presencaService.GetPresencasAulaAsync(horarioId, data, ct);
        return Ok(resultado);
    }

    [HttpGet("relatorio")]
    public async Task<IActionResult> GetRelatorio(
        [FromQuery] Guid turmaId,
        [FromQuery] DateOnly de,
        [FromQuery] DateOnly ate,
        CancellationToken ct)
    {
        var resultado = await _presencaService.GetRelatorioFrequenciaAsync(turmaId, de, ate, ct);
        return Ok(resultado);
    }

    [HttpGet("qr/{alunoId:guid}")]
    public async Task<IActionResult> GerarQrToken(Guid alunoId, CancellationToken ct)
    {
        var resultado = await _presencaService.GerarTokenQrAlunoAsync(alunoId, ct);
        if (!resultado.Sucesso)
            return BadRequest(resultado);
        return Ok(resultado);
    }

    [HttpGet("qr-info")]
    public async Task<IActionResult> GetAlunoQrInfo([FromQuery] string token, CancellationToken ct)
    {
        var resultado = await _presencaService.GetAlunoQrInfoAsync(token, ct);
        if (!resultado.Sucesso)
            return BadRequest(resultado);
        return Ok(resultado);
    }

    [HttpPost("checkin-self")]
    public async Task<IActionResult> CheckinSelf(CancellationToken ct)
    {
        var idStr = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
                 ?? User.FindFirst(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub)?.Value;
        if (!Guid.TryParse(idStr, out var alunoId))
            return Unauthorized();
        var resultado = await _presencaService.CheckinSelfAsync(alunoId, ct);
        if (!resultado.Sucesso)
            return BadRequest(resultado);
        return Ok(resultado);
    }
}

public class QrCodeRequest
{
    public string Token { get; set; } = string.Empty;
}
