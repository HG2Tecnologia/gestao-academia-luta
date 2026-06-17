using System.Security.Claims;
using AcademiaFight.Application.DTOs.ParQ;
using AcademiaFight.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AcademiaFight.API.Controllers;

[ApiController]
[Route("api/parq")]
[Authorize]
public class ParQController : ControllerBase
{
    private readonly ParQService _service;

    public ParQController(ParQService service) => _service = service;

    private Guid ObterUsuarioId()
    {
        var idStr = User.FindFirstValue(ClaimTypes.NameIdentifier)
                    ?? User.FindFirstValue("sub");
        return Guid.TryParse(idStr, out var id) ? id : Guid.Empty;
    }

    // ── Aluno: consulta e preenche o próprio PAR-Q ──────────────────────────
    [HttpGet("meu")]
    public async Task<IActionResult> ObterMeu(CancellationToken ct)
    {
        var alunoId = ObterUsuarioId();
        if (alunoId == Guid.Empty) return Unauthorized();
        return Ok(await _service.ObterMeuAsync(alunoId, ct));
    }

    [HttpPost("meu")]
    public async Task<IActionResult> Preencher([FromBody] PreencherParQRequest request, CancellationToken ct)
    {
        var alunoId = ObterUsuarioId();
        if (alunoId == Guid.Empty) return Unauthorized();
        var result = await _service.PreencherAsync(request, alunoId, ct);
        if (!result.Sucesso) return BadRequest(result);
        return Ok(result);
    }

    // ── Gestor: consulta PAR-Q de um aluno específico ──────────────────────
    [HttpGet("aluno/{alunoId:guid}")]
    [Authorize(Roles = "Admin,Professor")]
    public async Task<IActionResult> ObterDoAluno(Guid alunoId, CancellationToken ct)
    {
        return Ok(await _service.ObterDoAlunoAsync(alunoId, ct));
    }

    // ── Gestor: preenche/atualiza PAR-Q de um aluno específico ───────────
    [HttpPost("aluno/{alunoId:guid}")]
    [Authorize(Roles = "Admin,Professor")]
    public async Task<IActionResult> PreencherParaAluno(Guid alunoId, [FromBody] PreencherParQRequest request, CancellationToken ct)
    {
        var result = await _service.PreencherAsync(request, alunoId, ct);
        if (!result.Sucesso) return BadRequest(result);
        return Ok(result);
    }

    // ── Gestor: lista todos os PAR-Qs da academia ──────────────────────────
    [HttpGet]
    [Authorize(Roles = "Admin,Professor")]
    public async Task<IActionResult> Listar(CancellationToken ct)
    {
        return Ok(await _service.ListarAsync(ct));
    }
}
