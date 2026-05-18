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

    public RankingController(IRankingService ranking, IConquistaService conquista)
    {
        _ranking = ranking;
        _conquista = conquista;
    }

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
}

public record MarcarVistasRequest(Guid AlunoId);
