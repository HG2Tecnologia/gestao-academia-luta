using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace AcademiaFight.API.Hubs;

[Authorize]
public class RankingHub : Hub
{
    public async Task EntrarGrupoTenant(string academiaId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"ranking-{academiaId}");
    }

    public async Task SairGrupoTenant(string academiaId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"ranking-{academiaId}");
    }

    public override async Task OnConnectedAsync()
    {
        // O cliente deve chamar EntrarGrupoTenant após conectar
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        await base.OnDisconnectedAsync(exception);
    }
}
