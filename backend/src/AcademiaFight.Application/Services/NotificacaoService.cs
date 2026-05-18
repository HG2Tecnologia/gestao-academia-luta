using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Notificacao;
using AcademiaFight.Application.Interfaces;
using AcademiaFight.Domain.Entities;
using AcademiaFight.Domain.Enums;
using AcademiaFight.Domain.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace AcademiaFight.Application.Services;

public class NotificacaoService : INotificacaoService
{
    private readonly IAppDbContext _db;
    private readonly ITenantContext _tenant;

    public NotificacaoService(IAppDbContext db, ITenantContext tenant)
    {
        _db = db;
        _tenant = tenant;
    }

    public async Task<BaseResponse<IEnumerable<NotificacaoDto>>> ListarAsync(CancellationToken ct = default)
    {
        await GerarAniversariosHojeAsync(ct);

        var notifs = await _db.Notificacoes
            .OrderByDescending(n => n.CriadoEm)
            .Take(50)
            .ToListAsync(ct);

        return BaseResponse<IEnumerable<NotificacaoDto>>.Ok(notifs.Select(MapearDto));
    }

    public async Task<BaseResponse> MarcarLidaAsync(Guid id, CancellationToken ct = default)
    {
        var n = await _db.Notificacoes.FirstOrDefaultAsync(x => x.Id == id, ct);
        if (n is null) return BaseResponse.Falha("Notificação não encontrada.");
        n.Lida = true;
        await _db.SaveChangesAsync(ct);
        return BaseResponse.Ok();
    }

    public async Task<BaseResponse> MarcarTodasLidasAsync(CancellationToken ct = default)
    {
        var naolidas = await _db.Notificacoes.Where(n => !n.Lida).ToListAsync(ct);
        foreach (var n in naolidas) n.Lida = true;
        await _db.SaveChangesAsync(ct);
        return BaseResponse.Ok();
    }

    public async Task<BaseResponse> ExcluirAsync(Guid id, CancellationToken ct = default)
    {
        var n = await _db.Notificacoes.FirstOrDefaultAsync(x => x.Id == id, ct);
        if (n is null) return BaseResponse.Falha("Notificação não encontrada.");
        _db.Notificacoes.Remove(n);
        await _db.SaveChangesAsync(ct);
        return BaseResponse.Ok();
    }

    private async Task GerarAniversariosHojeAsync(CancellationToken ct)
    {
        var hoje = DateTime.Today;
        var chave = $"aniv-{hoje:yyyy-MM-dd}";

        var jaGerou = await _db.Notificacoes
            .AnyAsync(n => n.ChaveDedup == chave, ct);

        if (jaGerou) return;

        var aniversariantes = await _db.Usuarios
            .Where(u => u.DataNascimento.HasValue
                     && u.DataNascimento.Value.Month == hoje.Month
                     && u.DataNascimento.Value.Day == hoje.Day
                     && u.Ativo)
            .Select(u => u.Nome)
            .ToListAsync(ct);

        if (aniversariantes.Count == 0)
        {
            // Still create a dedup marker so we don't check again today
            await _db.Notificacoes.AddAsync(new Notificacao
            {
                AcademiaId = _tenant.AcademiaId,
                Titulo = "_dedup",
                Mensagem = "",
                Tipo = TipoNotificacao.Info,
                Lida = true,
                ChaveDedup = chave,
            }, ct);
            await _db.SaveChangesAsync(ct);
            return;
        }

        var nomes = string.Join(", ", aniversariantes);
        var plural = aniversariantes.Count > 1;
        await _db.Notificacoes.AddAsync(new Notificacao
        {
            AcademiaId = _tenant.AcademiaId,
            Titulo = plural ? $"🎂 {aniversariantes.Count} aniversariantes hoje!" : $"🎂 Aniversário hoje!",
            Mensagem = plural
                ? $"{nomes} fazem aniversário hoje. Aproveite para parabenizá-los!"
                : $"{nomes} faz aniversário hoje. Aproveite para parabenizá-lo(a)!",
            Tipo = TipoNotificacao.Aniversario,
            Lida = false,
            ChaveDedup = chave,
        }, ct);

        await _db.SaveChangesAsync(ct);
    }

    private static NotificacaoDto MapearDto(Notificacao n) => new()
    {
        Id = n.Id,
        Titulo = n.Titulo,
        Mensagem = n.Mensagem,
        Tipo = n.Tipo,
        Lida = n.Lida,
        CriadoEm = n.CriadoEm,
    };
}
