using System.Security.Claims;
using AcademiaFight.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AcademiaFight.API.Controllers;

[ApiController]
[Route("api/ranking")]
[Authorize]
public class RankingController : ControllerBase
{
    private readonly IRankingService _ranking;
    private readonly IConquistaService _conquista;
    private readonly IRankingCustomService _rankingCustom;

    public RankingController(IRankingService ranking, IConquistaService conquista, IRankingCustomService rankingCustom)
    {
        _ranking = ranking;
        _conquista = conquista;
        _rankingCustom = rankingCustom;
    }

    // ─── Leaderboards por XP (existentes) ────────────────────────────────────

    [HttpGet("leaderboard/turma/{turmaId:guid}")]
    public async Task<IActionResult> LeaderboardTurma(
        Guid turmaId,
        [FromQuery] string periodo = "mensal",
        [FromQuery] int pagina = 1,
        CancellationToken ct = default)
    {
        var result = await _ranking.GetLeaderboardTurmaAsync(turmaId, periodo, pagina, ct);
        return Ok(result);
    }

    [HttpGet("leaderboard/academia")]
    public async Task<IActionResult> LeaderboardAcademia(
        [FromQuery] string periodo = "mensal",
        [FromQuery] int pagina = 1,
        CancellationToken ct = default)
    {
        var result = await _ranking.GetLeaderboardAcademiaAsync(periodo, pagina, ct);
        return Ok(result);
    }

    // ─── Leaderboards por Presenças ───────────────────────────────────────────

    [HttpGet("leaderboard/presencas/modalidade/{modalidadeId:guid}")]
    public async Task<IActionResult> LeaderboardPresencasModalidade(
        Guid modalidadeId,
        [FromQuery] int pagina = 1,
        [FromQuery] DateOnly? dataInicio = null,
        [FromQuery] DateOnly? dataFim = null,
        CancellationToken ct = default)
    {
        var result = await _ranking.GetLeaderboardModalidadeAsync(modalidadeId, pagina, dataInicio, dataFim, ct);
        if (result is null) return NotFound();
        return Ok(result);
    }

    [HttpGet("leaderboard/presencas/turma/{turmaId:guid}")]
    public async Task<IActionResult> LeaderboardPresencasTurma(
        Guid turmaId,
        [FromQuery] int pagina = 1,
        [FromQuery] DateOnly? dataInicio = null,
        [FromQuery] DateOnly? dataFim = null,
        CancellationToken ct = default)
    {
        var result = await _ranking.GetLeaderboardPresencasTurmaAsync(turmaId, pagina, dataInicio, dataFim, ct);
        return Ok(result);
    }

    // ─── Perfil & Conquistas ──────────────────────────────────────────────────

    [HttpGet("perfil/{alunoId:guid}")]
    public async Task<IActionResult> PerfilGamificado(Guid alunoId, CancellationToken ct = default)
    {
        var result = await _ranking.GetPerfilGamificadoAsync(alunoId, ct);
        if (result is null) return NotFound();
        return Ok(result);
    }

    [HttpGet("conquistas/{alunoId:guid}")]
    public async Task<IActionResult> GetConquistas(Guid alunoId, CancellationToken ct = default)
    {
        var result = await _conquista.GetConquistasAlunoAsync(alunoId, ct);
        return Ok(result);
    }

    [HttpPost("conquistas/marcar-vistas")]
    public async Task<IActionResult> MarcarConquistasVistas([FromBody] MarcarVistasRequest request, CancellationToken ct = default)
    {
        await _conquista.MarcarComoVistasAsync(request.AlunoId, ct);
        return NoContent();
    }

    // ─── Rankings Customizados ────────────────────────────────────────────────

    [HttpGet("custom")]
    public async Task<IActionResult> ListarRankingsCustom(
        [FromQuery] bool incluirInativos = false,
        CancellationToken ct = default)
    {
        var result = await _rankingCustom.ListarAsync(incluirInativos, ct);
        return Ok(result);
    }

    [HttpGet("custom/{id:guid}")]
    public async Task<IActionResult> ObterRankingCustom(Guid id, CancellationToken ct = default)
    {
        var result = await _rankingCustom.ObterAsync(id, ct);
        if (result is null) return NotFound();
        return Ok(result);
    }

    [HttpPost("custom")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> CriarRankingCustom(
        [FromBody] Application.Interfaces.CriarRankingCustomRequest request,
        CancellationToken ct = default)
    {
        var result = await _rankingCustom.CriarAsync(request, ct);
        return CreatedAtAction(nameof(ObterRankingCustom), new { id = result.Id }, result);
    }

    [HttpPut("custom/{id:guid}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> AtualizarRankingCustom(
        Guid id,
        [FromBody] Application.Interfaces.AtualizarRankingCustomRequest request,
        CancellationToken ct = default)
    {
        var result = await _rankingCustom.AtualizarAsync(id, request, ct);
        if (result is null) return NotFound();
        return Ok(result);
    }

    [HttpDelete("custom/{id:guid}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> DesativarRankingCustom(Guid id, CancellationToken ct = default)
    {
        var ok = await _rankingCustom.DesativarAsync(id, ct);
        if (!ok) return NotFound();
        return NoContent();
    }

    [HttpGet("custom/{id:guid}/leaderboard")]
    public async Task<IActionResult> LeaderboardCustom(
        Guid id,
        [FromQuery] int pagina = 1,
        CancellationToken ct = default)
    {
        var result = await _rankingCustom.GetLeaderboardAsync(id, pagina, ct);
        if (result is null) return NotFound();
        return Ok(result);
    }

    // ─── Lançamentos de Pontos ────────────────────────────────────────────────

    [HttpGet("custom/{id:guid}/lancamentos")]
    public async Task<IActionResult> ListarLancamentos(
        Guid id,
        [FromQuery] Guid? alunoId = null,
        CancellationToken ct = default)
    {
        var result = await _rankingCustom.ListarLancamentosAsync(id, alunoId, ct);
        return Ok(result);
    }

    [HttpPost("custom/{id:guid}/pontuar")]
    [Authorize(Roles = "Admin,Professor")]
    public async Task<IActionResult> LancarPontos(
        Guid id,
        [FromBody] Application.Interfaces.LancarPontosRequest request,
        CancellationToken ct = default)
    {
        var registradoPorId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue("sub")
            ?? throw new InvalidOperationException("Usuário não identificado."));

        var result = await _rankingCustom.LancarPontosAsync(id, request, registradoPorId, ct);
        return Ok(result);
    }

    [HttpDelete("lancamentos/{lancamentoId:guid}")]
    [Authorize(Roles = "Admin,Professor")]
    public async Task<IActionResult> RemoverLancamento(Guid lancamentoId, CancellationToken ct = default)
    {
        var ok = await _rankingCustom.RemoverLancamentoAsync(lancamentoId, ct);
        if (!ok) return NotFound();
        return NoContent();
    }
}

public record MarcarVistasRequest(Guid AlunoId);
