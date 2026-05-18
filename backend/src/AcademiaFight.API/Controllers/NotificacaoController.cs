using AcademiaFight.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AcademiaFight.API.Controllers;

[Authorize]
[ApiController]
[Route("api/notificacoes")]
public class NotificacaoController : ControllerBase
{
    private readonly INotificacaoService _service;
    public NotificacaoController(INotificacaoService service) => _service = service;

    [HttpGet]
    public async Task<IActionResult> Listar(CancellationToken ct)
        => Ok(await _service.ListarAsync(ct));

    [HttpPatch("{id:guid}/lida")]
    public async Task<IActionResult> MarcarLida(Guid id, CancellationToken ct)
        => Ok(await _service.MarcarLidaAsync(id, ct));

    [HttpPost("marcar-todas-lidas")]
    public async Task<IActionResult> MarcarTodasLidas(CancellationToken ct)
        => Ok(await _service.MarcarTodasLidasAsync(ct));

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Excluir(Guid id, CancellationToken ct)
        => Ok(await _service.ExcluirAsync(id, ct));
}
