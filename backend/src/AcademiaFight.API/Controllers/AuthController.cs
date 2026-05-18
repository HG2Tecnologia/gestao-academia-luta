using AcademiaFight.Application.DTOs.Auth;
using AcademiaFight.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AcademiaFight.API.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;

    public AuthController(IAuthService authService)
    {
        _authService = authService;
    }

    [HttpPost("login")]
    [AllowAnonymous]
    public async Task<IActionResult> Login([FromBody] LoginRequest request, CancellationToken ct)
    {
        var resultado = await _authService.LoginAsync(request, ct);

        if (!resultado.Sucesso)
            return Unauthorized(resultado);

        return Ok(resultado);
    }

    [HttpPost("register")]
    [AllowAnonymous]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request, CancellationToken ct)
    {
        var resultado = await _authService.RegisterAsync(request, ct);

        if (!resultado.Sucesso)
            return BadRequest(resultado);

        return Created(string.Empty, resultado);
    }

    [HttpPost("refresh")]
    [AllowAnonymous]
    public async Task<IActionResult> Refresh([FromBody] RefreshTokenRequest request, CancellationToken ct)
    {
        var resultado = await _authService.RefreshTokenAsync(request, ct);

        if (!resultado.Sucesso)
            return Unauthorized(resultado);

        return Ok(resultado);
    }

    [HttpPost("logout")]
    [Authorize]
    public async Task<IActionResult> Logout([FromBody] string refreshToken, CancellationToken ct)
    {
        var resultado = await _authService.LogoutAsync(refreshToken, ct);
        return Ok(resultado);
    }

    [HttpPost("alterar-senha")]
    [Authorize]
    public async Task<IActionResult> AlterarSenha([FromBody] AlterarSenhaRequest request, CancellationToken ct)
    {
        var subClaim = User.FindFirst(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub)?.Value
                       ?? User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;

        if (!Guid.TryParse(subClaim, out var usuarioId))
            return Unauthorized();

        var resultado = await _authService.AlterarSenhaAsync(usuarioId, request, ct);
        if (!resultado.Sucesso) return BadRequest(resultado);
        return Ok(resultado);
    }

    [HttpPost("forgot-password")]
    [AllowAnonymous]
    public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequest request, CancellationToken ct)
    {
        var resultado = await _authService.SolicitarRecuperacaoSenhaAsync(request.Email, ct);
        return Ok(resultado);
    }

    [HttpPost("reset-password")]
    [AllowAnonymous]
    public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequest request, CancellationToken ct)
    {
        var resultado = await _authService.RedefinirSenhaAsync(request.Token, request.NovaSenha, ct);
        if (!resultado.Sucesso) return BadRequest(resultado);
        return Ok(resultado);
    }
}
