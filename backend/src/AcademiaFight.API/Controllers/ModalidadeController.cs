using AcademiaFight.Application.DTOs.Modalidade;
using AcademiaFight.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AcademiaFight.API.Controllers;

[ApiController]
[Route("api/modalidades")]
[Authorize]
public class ModalidadeController : ControllerBase
{
    private readonly IModalidadeService _modalidadeService;

    public ModalidadeController(IModalidadeService modalidadeService)
    {
        _modalidadeService = modalidadeService;
    }

    [HttpGet]
    public async Task<IActionResult> Listar(CancellationToken ct)
    {
        var resultado = await _modalidadeService.ListarAsync(ct);
        return Ok(resultado);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> ObterPorId(Guid id, CancellationToken ct)
    {
        var resultado = await _modalidadeService.ObterPorIdAsync(id, ct);

        if (!resultado.Sucesso)
            return NotFound(resultado);

        return Ok(resultado);
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Criar([FromBody] CreateModalidadeRequest request, CancellationToken ct)
    {
        var resultado = await _modalidadeService.CriarAsync(request, ct);

        if (!resultado.Sucesso)
            return BadRequest(resultado);

        return Created($"/api/modalidades/{resultado.Dados!.Id}", resultado);
    }

    [HttpPut("{id:guid}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Atualizar(Guid id, [FromBody] UpdateModalidadeRequest request, CancellationToken ct)
    {
        var resultado = await _modalidadeService.AtualizarAsync(id, request, ct);

        if (!resultado.Sucesso)
            return resultado.Mensagem?.Contains("não encontrada") == true
                ? NotFound(resultado)
                : BadRequest(resultado);

        return Ok(resultado);
    }

    [HttpDelete("{id:guid}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Remover(Guid id, CancellationToken ct)
    {
        var resultado = await _modalidadeService.RemoverAsync(id, ct);

        if (!resultado.Sucesso)
            return resultado.Mensagem?.Contains("não encontrada") == true
                ? NotFound(resultado)
                : BadRequest(resultado);

        return Ok(resultado);
    }
}
