using System.Security.Claims;
using AcademiaFight.Application.DTOs.Noticia;
using AcademiaFight.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AcademiaFight.API.Controllers;

[ApiController]
[Route("api/noticias")]
[Authorize]
public class NoticiaController : ControllerBase
{
    private readonly INoticiaService _service;

    public NoticiaController(INoticiaService service)
    {
        _service = service;
    }

    private Guid ObterUsuarioId()
    {
        var idStr = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub");
        return Guid.TryParse(idStr, out var id) ? id : Guid.Empty;
    }

    // Público para alunos e professores — lista só publicadas
    [HttpGet]
    public async Task<IActionResult> ListarPublicadas([FromQuery] int pagina = 1, [FromQuery] int tamanhoPagina = 10, CancellationToken ct = default)
    {
        var resultado = await _service.ListarPublicadasAsync(pagina, tamanhoPagina, ct);
        return Ok(resultado);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> ObterPorId(Guid id, CancellationToken ct = default)
    {
        var resultado = await _service.ObterPorIdAsync(id, ct);
        if (!resultado.Sucesso) return NotFound(resultado);
        return Ok(resultado);
    }

    // Admin — lista todas (incluindo rascunhos)
    [HttpGet("admin")]
    [Authorize(Roles = "Admin,Professor")]
    public async Task<IActionResult> ListarAdmin([FromQuery] int pagina = 1, [FromQuery] int tamanhoPagina = 20, CancellationToken ct = default)
    {
        var resultado = await _service.ListarTodasAdminAsync(pagina, tamanhoPagina, ct);
        return Ok(resultado);
    }

    [HttpPost]
    [Authorize(Roles = "Admin,Professor")]
    public async Task<IActionResult> Criar([FromBody] CriarNoticiaRequest request, CancellationToken ct = default)
    {
        var autorId = ObterUsuarioId();
        var resultado = await _service.CriarAsync(request, autorId, ct);
        if (!resultado.Sucesso) return BadRequest(resultado);
        return Created($"/api/noticias/{resultado.Dados!.Id}", resultado);
    }

    [HttpPut("{id:guid}")]
    [Authorize(Roles = "Admin,Professor")]
    public async Task<IActionResult> Atualizar(Guid id, [FromBody] AtualizarNoticiaRequest request, CancellationToken ct = default)
    {
        var resultado = await _service.AtualizarAsync(id, request, ct);
        if (!resultado.Sucesso) return resultado.Mensagem?.Contains("não encontrada") == true ? NotFound(resultado) : BadRequest(resultado);
        return Ok(resultado);
    }

    [HttpPost("{id:guid}/publicar")]
    [Authorize(Roles = "Admin,Professor")]
    public async Task<IActionResult> Publicar(Guid id, CancellationToken ct = default)
    {
        var resultado = await _service.PublicarAsync(id, ct);
        if (!resultado.Sucesso) return resultado.Mensagem?.Contains("não encontrada") == true ? NotFound(resultado) : BadRequest(resultado);
        return Ok(resultado);
    }

    [HttpDelete("{id:guid}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Remover(Guid id, CancellationToken ct = default)
    {
        var resultado = await _service.RemoverAsync(id, ct);
        if (!resultado.Sucesso) return resultado.Mensagem?.Contains("não encontrada") == true ? NotFound(resultado) : BadRequest(resultado);
        return Ok(resultado);
    }

    [HttpPatch("toggle-ativas")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> ToggleAtivas([FromQuery] bool ativo, CancellationToken ct = default)
    {
        var resultado = await _service.ToggleNoticiasAtivasAsync(ativo, ct);
        if (!resultado.Sucesso) return BadRequest(resultado);
        return Ok(resultado);
    }
}
