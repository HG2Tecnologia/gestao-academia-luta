using AcademiaFight.Application.DTOs.Horario;
using AcademiaFight.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AcademiaFight.API.Controllers;

[ApiController]
[Route("api/horarios")]
[Authorize]
public class HorarioController : ControllerBase
{
    private readonly IHorarioService _horarioService;

    public HorarioController(IHorarioService horarioService)
    {
        _horarioService = horarioService;
    }

    [HttpGet("grade")]
    public async Task<IActionResult> GetGrade(CancellationToken ct)
    {
        var resultado = await _horarioService.GetGradeAsync(ct);
        return Ok(resultado);
    }

    [HttpGet]
    public async Task<IActionResult> GetByTurma([FromQuery] Guid turmaId, CancellationToken ct)
    {
        var resultado = await _horarioService.GetByTurmaAsync(turmaId, ct);
        return Ok(resultado);
    }

    [HttpPost]
    public async Task<IActionResult> Criar([FromBody] CreateHorarioRequest request, CancellationToken ct)
    {
        var resultado = await _horarioService.CreateAsync(request, ct);
        if (!resultado.Sucesso)
            return resultado.Mensagem?.Contains("conflito") == true || resultado.Mensagem?.Contains("já tem") == true || resultado.Mensagem?.Contains("já está") == true
                ? Conflict(resultado)
                : BadRequest(resultado);
        return Created($"/api/horarios/{resultado.Dados!.Id}", resultado);
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Atualizar(Guid id, [FromBody] CreateHorarioRequest request, CancellationToken ct)
    {
        var resultado = await _horarioService.UpdateAsync(id, request, ct);
        if (!resultado.Sucesso)
            return resultado.Mensagem?.Contains("não encontrado") == true ? NotFound(resultado) : BadRequest(resultado);
        return Ok(resultado);
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Remover(Guid id, CancellationToken ct)
    {
        var resultado = await _horarioService.DeleteAsync(id, ct);
        if (!resultado.Sucesso)
            return resultado.Mensagem?.Contains("não encontrado") == true ? NotFound(resultado) : BadRequest(resultado);
        return Ok(resultado);
    }
}
