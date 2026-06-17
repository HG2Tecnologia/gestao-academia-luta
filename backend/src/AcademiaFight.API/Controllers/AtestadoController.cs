using System.Security.Claims;
using AcademiaFight.Application.DTOs.AtestadoMedico;
using AcademiaFight.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AcademiaFight.API.Controllers;

[ApiController]
[Route("api/atestados")]
[Authorize]
public class AtestadoController : ControllerBase
{
    private readonly IAtestadoService _service;

    public AtestadoController(IAtestadoService service) => _service = service;

    private Guid ObterUsuarioId()
    {
        var idStr = User.FindFirstValue(ClaimTypes.NameIdentifier)
                    ?? User.FindFirstValue("sub");
        return Guid.TryParse(idStr, out var id) ? id : Guid.Empty;
    }

    // ── Aluno: faz upload do próprio atestado ────────────────────────────────
    [HttpPost("meu")]
    public async Task<IActionResult> UploadMeu([FromBody] UploadAtestadoRequest request, CancellationToken ct)
    {
        var alunoId = ObterUsuarioId();
        if (alunoId == Guid.Empty) return Unauthorized();

        var resultado = await _service.UploadAlunoAsync(request, alunoId, ct);
        if (!resultado.Sucesso) return BadRequest(resultado);
        return Ok(resultado);
    }

    // ── Aluno: consulta o próprio atestado ───────────────────────────────────
    [HttpGet("meu")]
    public async Task<IActionResult> ObterMeu(CancellationToken ct)
    {
        var alunoId = ObterUsuarioId();
        if (alunoId == Guid.Empty) return Unauthorized();

        var resultado = await _service.ObterMeuAtestadoAsync(alunoId, ct);
        return Ok(resultado);
    }

    // ── Gestor: lista todos os alunos com status de atestado ─────────────────
    [HttpGet]
    public async Task<IActionResult> Listar(CancellationToken ct)
    {
        var resultado = await _service.ListarStatusAtestadosAsync(ct);
        return Ok(resultado);
    }

    // ── Gestor: consulta atestado de um aluno específico (com arquivo) ────────
    [HttpGet("aluno/{alunoId:guid}")]
    public async Task<IActionResult> ObterDoAluno(Guid alunoId, CancellationToken ct)
    {
        var resultado = await _service.ObterAtestadoDoAlunoAsync(alunoId, ct);
        return Ok(resultado);
    }

    // ── Gestor/Professor: anexa atestado por conta da academia (auto-aprovado) ─
    [HttpPost("academia")]
    public async Task<IActionResult> UploadAcademia([FromBody] UploadAtestadoPorAcademiaRequest request, CancellationToken ct)
    {
        var responsavelId = ObterUsuarioId();
        if (responsavelId == Guid.Empty) return Unauthorized();

        var resultado = await _service.UploadAcademiaAsync(request, responsavelId, ct);
        if (!resultado.Sucesso) return BadRequest(resultado);
        return Ok(resultado);
    }

    // ── Gestor: aprova ou rejeita um atestado ────────────────────────────────
    [HttpPatch("{id:guid}/avaliar")]
    public async Task<IActionResult> Avaliar(Guid id, [FromBody] AvaliarAtestadoRequest request, CancellationToken ct)
    {
        var resultado = await _service.AvaliarAsync(id, request, ct);
        if (!resultado.Sucesso) return BadRequest(resultado);
        return Ok(resultado);
    }

    // ── Gestor: envia lembrete ao aluno ──────────────────────────────────────
    [HttpPost("aluno/{alunoId:guid}/lembrete")]
    public async Task<IActionResult> EnviarLembrete(Guid alunoId, CancellationToken ct)
    {
        var resultado = await _service.EnviarLembreteAsync(alunoId, ct);
        if (!resultado.Sucesso) return BadRequest(resultado);
        return Ok(resultado);
    }
}
