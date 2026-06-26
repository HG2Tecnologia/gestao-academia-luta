using AcademiaFight.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AcademiaFight.API.Controllers;

[ApiController]
[Route("api/grupos-familiares")]
[Authorize]
public class GrupoFamiliarController : ControllerBase
{
    private readonly IGrupoFamiliarService _service;

    public GrupoFamiliarController(IGrupoFamiliarService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<IActionResult> Listar(CancellationToken ct)
    {
        var r = await _service.ListarAsync(ct);
        return r.Sucesso ? Ok(r) : BadRequest(r);
    }

    [HttpPost]
    public async Task<IActionResult> Criar([FromBody] NomeRequest req, CancellationToken ct)
    {
        var r = await _service.CriarAsync(req.Nome, ct);
        return r.Sucesso ? Created($"/api/grupos-familiares/{r.Dados!.Id}", r) : BadRequest(r);
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Renomear(Guid id, [FromBody] NomeRequest req, CancellationToken ct)
    {
        var r = await _service.RenomearAsync(id, req.Nome, ct);
        return r.Sucesso ? Ok(r) : BadRequest(r);
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Excluir(Guid id, CancellationToken ct)
    {
        var r = await _service.ExcluirAsync(id, ct);
        return r.Sucesso ? Ok(r) : BadRequest(r);
    }

    [HttpPost("{id:guid}/membros/{alunoId:guid}")]
    public async Task<IActionResult> AdicionarMembro(Guid id, Guid alunoId, CancellationToken ct)
    {
        var r = await _service.AdicionarMembroAsync(id, alunoId, ct);
        return r.Sucesso ? Ok(r) : BadRequest(r);
    }

    [HttpDelete("{id:guid}/membros/{alunoId:guid}")]
    public async Task<IActionResult> RemoverMembro(Guid id, Guid alunoId, CancellationToken ct)
    {
        var r = await _service.RemoverMembroAsync(id, alunoId, ct);
        return r.Sucesso ? Ok(r) : BadRequest(r);
    }

    [HttpGet("aluno/{alunoId:guid}")]
    public async Task<IActionResult> ObterPorAluno(Guid alunoId, CancellationToken ct)
    {
        var r = await _service.ObterPorAlunoAsync(alunoId, ct);
        return Ok(r);
    }
}

public record NomeRequest(string Nome);
