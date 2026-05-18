using AcademiaFight.Application.DTOs.Usuario;
using AcademiaFight.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AcademiaFight.API.Controllers;

[ApiController]
[Route("api/usuarios")]
[Authorize]
public class UsuariosController : ControllerBase
{
    private readonly IUsuarioService _usuarioService;

    public UsuariosController(IUsuarioService usuarioService)
    {
        _usuarioService = usuarioService;
    }

    [HttpGet("professores")]
    public async Task<IActionResult> ListarProfessores(CancellationToken ct)
    {
        var resultado = await _usuarioService.ListarProfessoresAsync(ct);
        return Ok(resultado);
    }

    [HttpGet("me")]
    public async Task<IActionResult> ObterMeuPerfil(CancellationToken ct)
    {
        var sub = User.FindFirst(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub)?.Value
                  ?? User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (!Guid.TryParse(sub, out var usuarioId)) return Unauthorized();
        var resultado = await _usuarioService.ObterMeuPerfilAsync(usuarioId, ct);
        return Ok(resultado);
    }

    [HttpPut("me")]
    public async Task<IActionResult> AtualizarMeuPerfil([FromBody] AtualizarMeuPerfilRequest request, CancellationToken ct)
    {
        var sub = User.FindFirst(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub)?.Value
                  ?? User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (!Guid.TryParse(sub, out var usuarioId)) return Unauthorized();
        var resultado = await _usuarioService.AtualizarMeuPerfilAsync(usuarioId, request, ct);
        return Ok(resultado);
    }
}
