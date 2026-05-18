using AcademiaFight.Application.DTOs.Matricula;
using AcademiaFight.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AcademiaFight.API.Controllers;

[ApiController]
[Route("api/matriculas")]
[Authorize]
public class MatriculaController : ControllerBase
{
    private readonly IMatriculaService _matriculaService;

    public MatriculaController(IMatriculaService matriculaService)
    {
        _matriculaService = matriculaService;
    }

    [HttpGet]
    public async Task<IActionResult> GetByAluno([FromQuery] Guid alunoId, CancellationToken ct)
    {
        var resultado = await _matriculaService.GetByAlunoAsync(alunoId, ct);
        return Ok(resultado);
    }

    [HttpPost]
    public async Task<IActionResult> Criar([FromBody] CreateMatriculaRequest request, CancellationToken ct)
    {
        var resultado = await _matriculaService.CreateAsync(request, ct);
        if (!resultado.Sucesso)
            return BadRequest(resultado);
        return Created($"/api/matriculas/{resultado.Dados!.Id}", resultado);
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Encerrar(Guid id, CancellationToken ct)
    {
        var resultado = await _matriculaService.DeleteAsync(id, ct);
        if (!resultado.Sucesso)
            return resultado.Mensagem?.Contains("não encontrada") == true ? NotFound(resultado) : BadRequest(resultado);
        return Ok(resultado);
    }
}
