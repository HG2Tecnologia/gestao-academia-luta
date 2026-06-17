using AcademiaFight.Application.DTOs.Modalidade;
using AcademiaFight.Application.Interfaces;
using AcademiaFight.Application.Services;
using AcademiaFight.Domain.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AcademiaFight.API.Controllers;

[ApiController]
[Route("api/modalidades")]
[Authorize]
public class ModalidadeController : ControllerBase
{
    private readonly IModalidadeService _modalidadeService;
    private readonly IModalidadeSeedService _seedService;
    private readonly ITenantContext _tenant;

    public ModalidadeController(
        IModalidadeService modalidadeService,
        IModalidadeSeedService seedService,
        ITenantContext tenant)
    {
        _modalidadeService = modalidadeService;
        _seedService = seedService;
        _tenant = tenant;
    }

    [HttpGet]
    public async Task<IActionResult> Listar([FromQuery] bool? ativo, CancellationToken ct)
    {
        var resultado = await _modalidadeService.ListarAsync(ativo, ct);
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

    [HttpPatch("{id:guid}/toggle-ativo")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> ToggleAtivo(Guid id, CancellationToken ct)
    {
        var resultado = await _modalidadeService.ToggleAtivoAsync(id, ct);
        if (!resultado.Sucesso) return resultado.Mensagem?.Contains("não encontrada") == true ? NotFound(resultado) : BadRequest(resultado);
        return Ok(resultado);
    }

    /// <summary>
    /// Popula as modalidades pré-definidas do sistema para a academia atual.
    /// Idempotente: não faz nada se a academia já possui modalidades cadastradas.
    /// </summary>
    [HttpPost("seed")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Seed(CancellationToken ct)
    {
        await _seedService.SeedParaAcademiaAsync(_tenant.AcademiaId, ct);
        return Ok(new { sucesso = true, mensagem = "Modalidades pré-definidas carregadas com sucesso." });
    }
}
