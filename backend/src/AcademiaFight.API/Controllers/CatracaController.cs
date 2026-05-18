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
    /// Chamado pelo hardware da catraca ao receber um identificador (e-mail, CPF ou matrícula).
    /// Autenticado via API Key no header X-Catraca-Key (configurado em appsettings.json).
    /// TODO: ajustar o campo identificador conforme o protocolo do hardware escolhido.
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
    /// Libera a catraca manualmente — acionado pelo botão na tela da secretaria.
    /// Requer autenticação JWT (qualquer perfil).
    /// TODO: quando a catraca estiver conectada, o service enviará o comando ao hardware.
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
}

public record ValidarAcessoRequest(string Identificador);
