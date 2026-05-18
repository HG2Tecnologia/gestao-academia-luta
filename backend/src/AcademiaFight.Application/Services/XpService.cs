using AcademiaFight.Application.DTOs.Ranking;
using AcademiaFight.Application.Interfaces;
using AcademiaFight.Domain.Entities;
using AcademiaFight.Domain.Enums;
using AcademiaFight.Domain.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace AcademiaFight.Application.Services;

public class XpService : IXpService
{
    private readonly IAppDbContext _db;
    private readonly ITenantContext _tenant;
    private readonly IConquistaService _conquistaService;
    private readonly IRankingNotifier _notifier;
    private readonly ILogger<XpService> _logger;

    public XpService(
        IAppDbContext db,
        ITenantContext tenant,
        IConquistaService conquistaService,
        IRankingNotifier notifier,
        ILogger<XpService> logger)
    {
        _db = db;
        _tenant = tenant;
        _conquistaService = conquistaService;
        _notifier = notifier;
        _logger = logger;
    }

    public async Task AdicionarXpAsync(Guid alunoId, TipoEventoXp tipo, int pontos, Guid? referenciaId = null, CancellationToken ct = default)
    {
        var ponto = new PontoRanking
        {
            AlunoId = alunoId,
            TipoEvento = tipo,
            Pontos = pontos,
            ReferenciaId = referenciaId,
            Data = DateOnly.FromDateTime(DateTime.UtcNow)
        };

        await _db.PontosRanking.AddAsync(ponto, ct);

        var xpExistente = await _db.PontosRanking
            .Where(p => p.AlunoId == alunoId)
            .SumAsync(p => p.Pontos, ct);
        var xpTotal = xpExistente + pontos;

        var inicioMes = new DateOnly(DateTime.UtcNow.Year, DateTime.UtcNow.Month, 1);
        var xpMensalExistente = await _db.PontosRanking
            .Where(p => p.AlunoId == alunoId && p.Data >= inicioMes)
            .SumAsync(p => p.Pontos, ct);
        var xpMensal = xpMensalExistente + pontos;

        var novoNivel = CalcularNivel(xpTotal);

        var aluno = await _db.Usuarios.FirstOrDefaultAsync(u => u.Id == alunoId, ct);
        if (aluno is not null)
        {
            var nivelAnterior = aluno.Nivel;
            aluno.XpTotal = xpTotal;
            aluno.XpMensal = xpMensal;
            aluno.Nivel = novoNivel;
            if (novoNivel != nivelAnterior)
                aluno.NivelAtualizadoEm = DateTime.UtcNow;
        }

        await _db.SaveChangesAsync(ct);

        var academiaId = _tenant.IsSet ? _tenant.AcademiaId : aluno?.AcademiaId ?? Guid.Empty;
        if (academiaId == Guid.Empty) return;

        var novasConquistas = await _conquistaService.VerificarEDesbloquerarAsync(alunoId, academiaId, ct);

        try
        {
            if (aluno is not null)
            {
                var item = new LeaderboardItemDto
                {
                    AlunoId = alunoId,
                    NomeAluno = aluno.Nome,
                    Nivel = novoNivel.ToString(),
                    XpTotal = xpTotal,
                    XpPeriodo = xpMensal
                };
                await _notifier.NotificarAtualizacaoRankingAsync(academiaId, item, ct);
            }

            foreach (var conquista in novasConquistas)
                await _notifier.NotificarNovaConquistaAsync(academiaId, conquista, ct);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Falha ao emitir evento SignalR para aluno {AlunoId}", alunoId);
        }
    }

    public async Task<int> GetXpTotalAsync(Guid alunoId, CancellationToken ct = default) =>
        await _db.PontosRanking.Where(p => p.AlunoId == alunoId).SumAsync(p => p.Pontos, ct);

    public async Task<NivelAluno> GetNivelAsync(Guid alunoId, CancellationToken ct = default) =>
        CalcularNivel(await GetXpTotalAsync(alunoId, ct));

    public async Task<IEnumerable<HistoricoXpItemDto>> GetHistoricoXpAsync(Guid alunoId, CancellationToken ct = default)
    {
        var historico = await _db.PontosRanking
            .Where(p => p.AlunoId == alunoId)
            .OrderByDescending(p => p.CriadoEm)
            .Take(30)
            .ToListAsync(ct);

        return historico.Select(p => new HistoricoXpItemDto
        {
            Id = p.Id,
            TipoEvento = p.TipoEvento.ToString(),
            Pontos = p.Pontos,
            Data = p.Data,
            CriadoEm = p.CriadoEm
        });
    }

    public static NivelAluno CalcularNivel(int xp) => xp switch
    {
        < 200 => NivelAluno.Iniciante,
        < 500 => NivelAluno.Guerreiro,
        < 1000 => NivelAluno.Veterano,
        < 2000 => NivelAluno.Elite,
        _ => NivelAluno.Mestre
    };

    public static int XpParaProximoNivel(int xpAtual) => CalcularNivel(xpAtual) switch
    {
        NivelAluno.Iniciante => 200 - xpAtual,
        NivelAluno.Guerreiro => 500 - xpAtual,
        NivelAluno.Veterano => 1000 - xpAtual,
        NivelAluno.Elite => 2000 - xpAtual,
        _ => 0
    };
}
