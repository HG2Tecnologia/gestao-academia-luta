using AcademiaFight.Application.DTOs.Catraca;
using AcademiaFight.Application.Interfaces;
using AcademiaFight.Domain.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AcademiaFight.API.Controllers;

[ApiController]
[Route("api/catraca")]
public class CatracaController : ControllerBase
{
    private readonly ICatracaService _catracaService;
    private readonly ITenantContext _tenant;
    private readonly IConfiguration _config;

    public CatracaController(ICatracaService catracaService, ITenantContext tenant, IConfiguration config)
    {
        _catracaService = catracaService;
        _tenant = tenant;
        _config = config;
    }

    /// <summary>
    /// Chamado pelo hardware Toletus ao identificar um usuário (digital, PIN ou RFID).
    /// Autenticado via API Key no header X-Catraca-Key.
    /// </summary>
    [HttpPost("validar")]
    [AllowAnonymous]
    public async Task<IActionResult> Validar([FromBody] ValidarAcessoRequest request, CancellationToken ct)
    {
        var chaveEsperada = _config["Catraca:ApiKey"];
        var chaveEnviada = Request.Headers["X-Catraca-Key"].FirstOrDefault();

        if (string.IsNullOrEmpty(chaveEsperada) || chaveEnviada != chaveEsperada)
            return Unauthorized(new { mensagem = "API Key inválida ou não configurada." });

        if (string.IsNullOrWhiteSpace(request.Identificador))
            return BadRequest(new { mensagem = "Identificador é obrigatório." });

        var resultado = await _catracaService.ValidarAcessoAsync(request.Identificador, _tenant.AcademiaId, ct);
        return Ok(resultado);
    }

    /// <summary>
    /// Libera a catraca manualmente — botão na secretaria.
    /// Envia comando via SignalR ao agente local que aciona o dispositivo Toletus.
    /// </summary>
    [HttpPost("abrir")]
    [Authorize]
    public async Task<IActionResult> AbrirManualmente(CancellationToken ct)
    {
        var subStr = User.FindFirst(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub)?.Value
                  ?? User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        Guid.TryParse(subStr, out var operadorId);
        var resultado = await _catracaService.AbrirManualmenteAsync(_tenant.AcademiaId, operadorId, ct);
        return Ok(resultado);
    }

    // ── Vínculos aluno ↔ dispositivo ──────────────────────────────────────────

    /// <summary>Lista todos os alunos ativos com status de vínculo no dispositivo.</summary>
    [HttpGet("vinculos")]
    [Authorize]
    public async Task<IActionResult> ListarVinculos(CancellationToken ct)
    {
        var resultado = await _catracaService.ListarVinculosAsync(_tenant.AcademiaId, ct);
        return Ok(resultado);
    }

    /// <summary>
    /// Vincula um aluno ao dispositivo Toletus.
    /// Atribui um DeviceUserId e envia comando de enrollment ao agente local.
    /// O aluno deve então escanear a digital no dispositivo físico.
    /// </summary>
    [HttpPost("vincular")]
    [Authorize]
    public async Task<IActionResult> Vincular([FromBody] CatracaVincularRequest request, CancellationToken ct)
    {
        var resultado = await _catracaService.VincularAlunoAsync(
            request.AlunoId, _tenant.AcademiaId, request.DeviceUserId, ct);
        return Ok(resultado);
    }

    /// <summary>Remove o vínculo do aluno com o dispositivo e apaga do hardware.</summary>
    [HttpDelete("vincular/{alunoId:guid}")]
    [Authorize]
    public async Task<IActionResult> Desvincular(Guid alunoId, CancellationToken ct)
    {
        var resultado = await _catracaService.DesvincularAlunoAsync(alunoId, _tenant.AcademiaId, ct);
        return Ok(resultado);
    }

    // ── Agente local ──────────────────────────────────────────────────────────

    /// <summary>
    /// Retorna a configuração para o agente local (SenseiManagerAgent.exe).
    /// O agente usa esses dados para conectar ao backend e identificar a academia.
    /// </summary>
    [HttpGet("agent/config")]
    [Authorize]
    public IActionResult GetAgentConfig()
    {
        var backendUrl = $"{Request.Scheme}://{Request.Host}";
        var apiKey = _config["Catraca:ApiKey"] ?? "";
        var toletus = _config["Catraca:ToletusCatracaIp"] ?? "169.254.37.21";

        var config = new CatracaAgentConfigDto(
            BackendUrl: backendUrl,
            ApiKey: apiKey,
            AcademiaId: _tenant.AcademiaId.ToString(),
            ToletusCatracaIp: toletus
        );

        return Ok(config);
    }
}

public record ValidarAcessoRequest(string Identificador);
