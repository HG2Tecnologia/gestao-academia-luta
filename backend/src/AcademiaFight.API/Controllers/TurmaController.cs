using AcademiaFight.Application.DTOs.Turma;
using AcademiaFight.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AcademiaFight.API.Controllers;

[ApiController]
[Route("api/turmas")]
[Authorize]
public class TurmaController : ControllerBase
{
    private readonly ITurmaService _turmaService;

    public TurmaController(ITurmaService turmaService)
    {
        _turmaService = turmaService;
    }

    [HttpGet]
    public async Task<IActionResult> Listar(CancellationToken ct)
    {
        var resultado = await _turmaService.ListarAsync(ct);
        return Ok(resultado);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> ObterDetalhe(Guid id, CancellationToken ct)
    {
        var resultado = await _turmaService.GetDetalheAsync(id, ct);
        if (!resultado.Sucesso)
            return NotFound(resultado);
        return Ok(resultado);
    }

    [HttpPost]
    public async Task<IActionResult> Criar([FromBody] CreateTurmaRequest request, CancellationToken ct)
    {
        var resultado = await _turmaService.CriarAsync(request, ct);
        if (!resultado.Sucesso)
            return BadRequest(resultado);
        return Created($"/api/turmas/{resultado.Dados!.Id}", resultado);
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Atualizar(Guid id, [FromBody] UpdateTurmaRequest request, CancellationToken ct)
    {
        var resultado = await _turmaService.AtualizarAsync(id, request, ct);
        if (!resultado.Sucesso)
            return resultado.Mensagem?.Contains("não encontrada") == true ? NotFound(resultado) : BadRequest(resultado);
        return Ok(resultado);
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Arquivar(Guid id, CancellationToken ct)
    {
        var resultado = await _turmaService.RemoverAsync(id, ct);
        if (!resultado.Sucesso)
            return resultado.Mensagem?.Contains("não encontrada") == true ? NotFound(resultado) : BadRequest(resultado);
        return Ok(resultado);
    }

    [HttpGet("{id:guid}/alunos")]
    public async Task<IActionResult> GetAlunos(Guid id, CancellationToken ct)
    {
        var resultado = await _turmaService.GetAlunosDaTurmaAsync(id, ct);
        return Ok(resultado);
    }

    [HttpPost("{id:guid}/matricular")]
    public async Task<IActionResult> Matricular(Guid id, [FromBody] MatricularRequest request, CancellationToken ct)
    {
        var resultado = await _turmaService.MatricularAlunoAsync(id, request.AlunoId, ct);
        if (!resultado.Sucesso)
            return BadRequest(resultado);
        return Ok(resultado);
    }

    [HttpDelete("{id:guid}/matricular/{alunoId:guid}")]
    public async Task<IActionResult> Desmatricular(Guid id, Guid alunoId, CancellationToken ct)
    {
        var resultado = await _turmaService.DesmatricularAlunoAsync(id, alunoId, ct);
        if (!resultado.Sucesso)
            return resultado.Mensagem?.Contains("não encontrada") == true ? NotFound(resultado) : BadRequest(resultado);
        return Ok(resultado);
    }
}

public class MatricularRequest
{
    public Guid AlunoId { get; set; }
}
