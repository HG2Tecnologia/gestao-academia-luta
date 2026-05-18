using AcademiaFight.Application.DTOs.Plano;
using AcademiaFight.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AcademiaFight.API.Controllers;

[ApiController]
[Route("api/planos")]
[Authorize]
public class PlanoController : ControllerBase
{
    private readonly IPlanoService _planoService;

    public PlanoController(IPlanoService planoService)
    {
        _planoService = planoService;
    }

    [HttpGet]
    public async Task<IActionResult> Listar(CancellationToken ct)
    {
        var resultado = await _planoService.ListarAsync(ct);
        return Ok(resultado);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> ObterPorId(Guid id, CancellationToken ct)
    {
        var resultado = await _planoService.ObterPorIdAsync(id, ct);
        if (!resultado.Sucesso) return NotFound(resultado);
        return Ok(resultado);
    }

    [HttpPost]
    public async Task<IActionResult> Criar([FromBody] CreatePlanoDto dto, CancellationToken ct)
    {
        var resultado = await _planoService.CriarAsync(dto, ct);
        if (!resultado.Sucesso) return BadRequest(resultado);
        return Created($"/api/planos/{resultado.Dados!.Id}", resultado);
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Atualizar(Guid id, [FromBody] UpdatePlanoDto dto, CancellationToken ct)
    {
        var resultado = await _planoService.AtualizarAsync(id, dto, ct);
        if (!resultado.Sucesso) return NotFound(resultado);
        return Ok(resultado);
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Deletar(Guid id, CancellationToken ct)
    {
        var resultado = await _planoService.DeletarAsync(id, ct);
        if (!resultado.Sucesso) return BadRequest(resultado);
        return Ok(resultado);
    }
}
