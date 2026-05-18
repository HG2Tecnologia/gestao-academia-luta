using AcademiaFight.Application.DTOs.Funcionario;
using AcademiaFight.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AcademiaFight.API.Controllers;

[ApiController]
[Route("api/funcionarios")]
[Authorize(Roles = "Admin")]
public class FuncionariosController : ControllerBase
{
    private readonly IFuncionarioService _funcionarioService;

    public FuncionariosController(IFuncionarioService funcionarioService)
    {
        _funcionarioService = funcionarioService;
    }

    [HttpGet]
    public async Task<IActionResult> Listar([FromQuery] string? nome, [FromQuery] string? perfil, CancellationToken ct)
    {
        var resultado = await _funcionarioService.ListarAsync(nome, perfil, ct);
        return Ok(resultado);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> ObterPorId(Guid id, CancellationToken ct)
    {
        var resultado = await _funcionarioService.ObterPorIdAsync(id, ct);
        if (!resultado.Sucesso) return NotFound(resultado);
        return Ok(resultado);
    }

    [HttpPost]
    public async Task<IActionResult> Criar([FromBody] CreateFuncionarioDto request, CancellationToken ct)
    {
        var academiaIdStr = User.FindFirst("academia_id")?.Value;
        if (!Guid.TryParse(academiaIdStr, out var academiaId))
            return Unauthorized();

        var resultado = await _funcionarioService.CriarAsync(request, academiaId, ct);
        if (!resultado.Sucesso) return BadRequest(resultado);
        return Created($"/api/funcionarios/{resultado.Dados!.Id}", resultado);
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Atualizar(Guid id, [FromBody] UpdateFuncionarioDto request, CancellationToken ct)
    {
        var resultado = await _funcionarioService.AtualizarAsync(id, request, ct);
        if (!resultado.Sucesso) return resultado.Mensagem?.Contains("não encontrado") == true
            ? NotFound(resultado) : BadRequest(resultado);
        return Ok(resultado);
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Remover(Guid id, CancellationToken ct)
    {
        var resultado = await _funcionarioService.RemoverAsync(id, ct);
        if (!resultado.Sucesso) return NotFound(resultado);
        return Ok(resultado);
    }
}
