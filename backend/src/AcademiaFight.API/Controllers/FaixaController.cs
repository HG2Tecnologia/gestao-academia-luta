using AcademiaFight.Application.DTOs.Faixa;
using AcademiaFight.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AcademiaFight.API.Controllers;

[ApiController]
[Route("api/faixas")]
[Authorize]
public class FaixaController : ControllerBase
{
    private readonly IFaixaService _faixaService;

    public FaixaController(IFaixaService faixaService)
    {
        _faixaService = faixaService;
    }

    [HttpGet]
    public async Task<IActionResult> GetByModalidade([FromQuery] Guid? modalidadeId, CancellationToken ct)
    {
        var resultado = await _faixaService.GetByModalidadeAsync(modalidadeId, ct);
        return Ok(resultado);
    }

    [HttpPost]
    public async Task<IActionResult> Criar([FromBody] CreateFaixaRequest request, CancellationToken ct)
    {
        var resultado = await _faixaService.CreateAsync(request, ct);
        if (!resultado.Sucesso)
            return BadRequest(resultado);
        return Created($"/api/faixas/{resultado.Dados!.Id}", resultado);
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Atualizar(Guid id, [FromBody] CreateFaixaRequest request, CancellationToken ct)
    {
        var resultado = await _faixaService.UpdateAsync(id, request, ct);
        if (!resultado.Sucesso)
            return resultado.Mensagem?.Contains("não encontrada") == true ? NotFound(resultado) : BadRequest(resultado);
        return Ok(resultado);
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Remover(Guid id, CancellationToken ct)
    {
        var resultado = await _faixaService.DeleteAsync(id, ct);
        if (!resultado.Sucesso)
            return resultado.Mensagem?.Contains("não encontrada") == true ? NotFound(resultado) : BadRequest(resultado);
        return Ok(resultado);
    }

    [HttpPatch("reordenar")]
    public async Task<IActionResult> Reordenar([FromBody] ReordenarFaixasRequest request, CancellationToken ct)
    {
        var resultado = await _faixaService.ReordenarAsync(request, ct);
        if (!resultado.Sucesso)
            return BadRequest(resultado);
        return Ok(resultado);
    }
}
