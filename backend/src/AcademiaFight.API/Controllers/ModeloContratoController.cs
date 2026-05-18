using AcademiaFight.Application.DTOs.Contrato;
using AcademiaFight.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AcademiaFight.API.Controllers;

[ApiController]
[Route("api/contratos/modelos")]
[Authorize]
public class ModeloContratoController : ControllerBase
{
    private readonly IModeloContratoService _service;

    public ModeloContratoController(IModeloContratoService service) => _service = service;

    [HttpGet]
    public async Task<IActionResult> Listar(CancellationToken ct)
        => Ok(await _service.ListarAsync(ct));

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> Obter(Guid id, CancellationToken ct)
        => Ok(await _service.ObterAsync(id, ct));

    [HttpPost]
    public async Task<IActionResult> Criar([FromBody] CreateModeloContratoRequest request, CancellationToken ct)
        => Ok(await _service.CriarAsync(request, ct));

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Atualizar(Guid id, [FromBody] UpdateModeloContratoRequest request, CancellationToken ct)
        => Ok(await _service.AtualizarAsync(id, request, ct));

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Excluir(Guid id, CancellationToken ct)
        => Ok(await _service.ExcluirAsync(id, ct));
}
