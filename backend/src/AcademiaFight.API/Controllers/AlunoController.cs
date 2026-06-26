using AcademiaFight.Application.DTOs.Aluno;
using AcademiaFight.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AcademiaFight.API.Controllers;

[ApiController]
[Route("api/alunos")]
[Authorize]
public class AlunoController : ControllerBase
{
    private readonly IUsuarioService _usuarioService;

    public AlunoController(IUsuarioService usuarioService)
    {
        _usuarioService = usuarioService;
    }

    [HttpGet]
    public async Task<IActionResult> Listar(
        [FromQuery] string? nome,
        [FromQuery] bool? ativo,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken ct = default)
    {
        var resultado = await _usuarioService.ListarAlunosAsync(nome, ativo, page, pageSize, ct);
        return Ok(resultado);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> ObterPorId(Guid id, CancellationToken ct)
    {
        var resultado = await _usuarioService.ObterAlunoPorIdAsync(id, ct);
        if (!resultado.Sucesso) return NotFound(resultado);
        return Ok(resultado);
    }

    [HttpPost]
    public async Task<IActionResult> Criar([FromBody] CreateAlunoDto request, CancellationToken ct)
    {
        var academiaIdStr = User.FindFirst("academia_id")?.Value;
        if (!Guid.TryParse(academiaIdStr, out var academiaId))
            return Unauthorized();

        var resultado = await _usuarioService.CriarAlunoAsync(request, academiaId, ct);
        if (!resultado.Sucesso) return BadRequest(resultado);
        return Created($"/api/alunos/{resultado.Dados!.Id}", resultado);
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Atualizar(Guid id, [FromBody] UpdateAlunoDto request, CancellationToken ct)
    {
        var resultado = await _usuarioService.AtualizarAlunoAsync(id, request, ct);
        if (!resultado.Sucesso) return resultado.Mensagem?.Contains("não encontrado") == true
            ? NotFound(resultado) : BadRequest(resultado);
        return Ok(resultado);
    }

    [HttpPatch("{id:guid}/status")]
    public async Task<IActionResult> ToggleAtivo(Guid id, [FromBody] ToggleAtivoRequest request, CancellationToken ct)
    {
        var resultado = await _usuarioService.ToggleAtivoAlunoAsync(id, request.Ativo, ct);
        if (!resultado.Sucesso) return NotFound(resultado);
        return Ok(resultado);
    }

    [HttpGet("me")]
    public async Task<IActionResult> Me(CancellationToken ct)
    {
        var idStr = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
                    ?? User.FindFirst("sub")?.Value;
        if (!Guid.TryParse(idStr, out var id))
            return Unauthorized();

        var resultado = await _usuarioService.ObterAlunoPorIdAsync(id, ct);
        if (!resultado.Sucesso) return NotFound(resultado);
        return Ok(resultado);
    }

    [HttpGet("aniversariantes")]
    public async Task<IActionResult> Aniversariantes([FromQuery] int? mes, CancellationToken ct)
    {
        var mesAtual = mes ?? DateTime.Now.Month;
        var resultado = await _usuarioService.ListarAniversariantesAsync(mesAtual, ct);
        return Ok(resultado);
    }

    [HttpPatch("{id:guid}/foto")]
    public async Task<IActionResult> AtualizarFoto(Guid id, [FromBody] AtualizarFotoRequest request, CancellationToken ct)
    {
        var resultado = await _usuarioService.AtualizarFotoAlunoAsync(id, request.FotoBase64, ct);
        if (!resultado.Sucesso) return NotFound(resultado);
        return Ok(resultado);
    }
}

public record ToggleAtivoRequest(bool Ativo);
public record AtualizarFotoRequest(string? FotoBase64);
