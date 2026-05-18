using AcademiaFight.Application.DTOs.Financeiro;
using AcademiaFight.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AcademiaFight.API.Controllers;

[ApiController]
[Route("api/financeiro")]
[Authorize]
public class FinanceiroController : ControllerBase
{
    private readonly IFinanceiroService _financeiroService;

    public FinanceiroController(IFinanceiroService financeiroService)
    {
        _financeiroService = financeiroService;
    }

    [HttpGet("resumo")]
    public async Task<IActionResult> Resumo([FromQuery] int? ano, [FromQuery] int? mes, CancellationToken ct)
    {
        var resultado = await _financeiroService.GetResumoAsync(ano, mes, ct);
        return Ok(resultado);
    }

    [HttpGet]
    public async Task<IActionResult> Listar(
        [FromQuery] Guid? alunoId,
        [FromQuery] string? status,
        [FromQuery] int? ano,
        [FromQuery] int? mes,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50,
        CancellationToken ct = default)
    {
        var resultado = await _financeiroService.ListarAsync(alunoId, status, ano, mes, page, pageSize, ct);
        return Ok(resultado);
    }

    [HttpGet("aluno/{alunoId:guid}")]
    public async Task<IActionResult> ListarPorAluno(Guid alunoId, CancellationToken ct)
    {
        var resultado = await _financeiroService.ListarPorAlunoAsync(alunoId, ct);
        return Ok(resultado);
    }

    [HttpPost]
    public async Task<IActionResult> Criar([FromBody] CreatePagamentoDto dto, CancellationToken ct)
    {
        var resultado = await _financeiroService.CriarAsync(dto, ct);
        if (!resultado.Sucesso) return BadRequest(resultado);
        return Created($"/api/financeiro/{resultado.Dados!.Id}", resultado);
    }

    [HttpPatch("{id:guid}")]
    public async Task<IActionResult> Atualizar(Guid id, [FromBody] UpdatePagamentoDto dto, CancellationToken ct)
    {
        var resultado = await _financeiroService.AtualizarAsync(id, dto, ct);
        if (!resultado.Sucesso) return NotFound(resultado);
        return Ok(resultado);
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Deletar(Guid id, CancellationToken ct)
    {
        var resultado = await _financeiroService.DeletarAsync(id, ct);
        if (!resultado.Sucesso) return NotFound(resultado);
        return Ok(resultado);
    }

    [HttpPost("gerar-cobrancas")]
    public async Task<IActionResult> GerarCobrancas(CancellationToken ct)
    {
        var resultado = await _financeiroService.GerarCobrancasMensaisAsync(ct);
        return Ok(resultado);
    }

    [HttpGet("relatorio-anual")]
    public async Task<IActionResult> RelatorioAnual([FromQuery] int? ano, CancellationToken ct)
    {
        var anoRef = ano ?? DateTime.UtcNow.Year;
        var resultado = await _financeiroService.GetRelatorioAnualAsync(anoRef, ct);
        return Ok(resultado);
    }
}
