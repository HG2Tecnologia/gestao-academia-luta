using AcademiaFight.Application.DTOs.Ranking;
using AcademiaFight.Application.Interfaces;
using AcademiaFight.Domain.Entities;
using AcademiaFight.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace AcademiaFight.Application.Services;

public class ConquistaService : IConquistaService
{
    private readonly IAppDbContext _db;
    private readonly ILogger<ConquistaService> _logger;

    public ConquistaService(IAppDbContext db, ILogger<ConquistaService> logger)
    {
        _db = db;
        _logger = logger;
    }

    public async Task<IEnumerable<ConquistaDto>> VerificarEDesbloquerarAsync(Guid alunoId, Guid academiaId, CancellationToken ct = default)
    {
        var conquistasJaDesbloqueadas = await _db.ConquistasAluno
            .Where(ca => ca.AlunoId == alunoId)
            .Select(ca => ca.ConquistaId)
            .ToListAsync(ct);

        var catalogo = await _db.Conquistas.ToListAsync(ct);
        var novasConquistas = new List<ConquistaAluno>();

        foreach (var conquista in catalogo)
        {
            if (conquistasJaDesbloqueadas.Contains(conquista.Id))
                continue;

            var desbloqueada = await VerificarCondicaoAsync(alunoId, conquista.Tipo, ct);
            if (!desbloqueada) continue;

            var novaConquista = new ConquistaAluno
            {
                AlunoId = alunoId,
                AcademiaId = academiaId,
                ConquistaId = conquista.Id,
                DesbloqueadaEm = DateTime.UtcNow,
                VistaPeloAluno = false
            };
            novasConquistas.Add(novaConquista);
        }

        if (novasConquistas.Count > 0)
        {
            await _db.ConquistasAluno.AddRangeAsync(novasConquistas, ct);
            await _db.SaveChangesAsync(ct);

            _logger.LogInformation("Aluno {AlunoId} desbloqueou {Count} conquista(s)", alunoId, novasConquistas.Count);
        }

        var conquistasComInfo = novasConquistas
            .Join(catalogo, ca => ca.ConquistaId, c => c.Id, (ca, c) => new ConquistaDto
            {
                Id = c.Id,
                Tipo = c.Tipo.ToString(),
                Nome = c.Nome,
                Descricao = c.Descricao,
                IconeUrl = c.IconeUrl,
                PontosXpBonus = c.PontosXpBonus,
                Desbloqueada = true,
                DesbloqueadaEm = ca.DesbloqueadaEm
            }).ToList();

        return conquistasComInfo;
    }

    public async Task<IEnumerable<ConquistaDto>> GetConquistasAlunoAsync(Guid alunoId, CancellationToken ct = default)
    {
        var catalogo = await _db.Conquistas.OrderBy(c => c.Tipo).ToListAsync(ct);
        var desbloqueadas = await _db.ConquistasAluno
            .Where(ca => ca.AlunoId == alunoId)
            .ToListAsync(ct);

        return catalogo.Select(c =>
        {
            var desbloqueada = desbloqueadas.FirstOrDefault(ca => ca.ConquistaId == c.Id);
            return new ConquistaDto
            {
                Id = c.Id,
                Tipo = c.Tipo.ToString(),
                Nome = c.Nome,
                Descricao = c.Descricao,
                IconeUrl = c.IconeUrl,
                PontosXpBonus = c.PontosXpBonus,
                Desbloqueada = desbloqueada is not null,
                DesbloqueadaEm = desbloqueada?.DesbloqueadaEm
            };
        });
    }

    public async Task<IEnumerable<ConquistaDto>> GetNovasConquistasAsync(Guid alunoId, CancellationToken ct = default)
    {
        var novas = await _db.ConquistasAluno
            .Include(ca => ca.Conquista)
            .Where(ca => ca.AlunoId == alunoId && !ca.VistaPeloAluno)
            .ToListAsync(ct);

        return novas.Select(ca => new ConquistaDto
        {
            Id = ca.Conquista.Id,
            Tipo = ca.Conquista.Tipo.ToString(),
            Nome = ca.Conquista.Nome,
            Descricao = ca.Conquista.Descricao,
            IconeUrl = ca.Conquista.IconeUrl,
            PontosXpBonus = ca.Conquista.PontosXpBonus,
            Desbloqueada = true,
            DesbloqueadaEm = ca.DesbloqueadaEm
        });
    }

    public async Task MarcarComoVistasAsync(Guid alunoId, CancellationToken ct = default)
    {
        var novas = await _db.ConquistasAluno
            .Where(ca => ca.AlunoId == alunoId && !ca.VistaPeloAluno)
            .ToListAsync(ct);

        foreach (var ca in novas)
            ca.VistaPeloAluno = true;

        await _db.SaveChangesAsync(ct);
    }

    private async Task<bool> VerificarCondicaoAsync(Guid alunoId, TipoConquista tipo, CancellationToken ct)
    {
        switch (tipo)
        {
            case TipoConquista.PrimeiroTreino:
                return await _db.Presencas.AnyAsync(p => p.AlunoId == alunoId, ct);

            case TipoConquista.SemanaPerfeira:
            {
                var hoje = DateOnly.FromDateTime(DateTime.UtcNow);
                var seteDiasAtras = hoje.AddDays(-7);
                var presencas = await _db.Presencas
                    .Where(p => p.AlunoId == alunoId && p.Data >= seteDiasAtras && p.Data <= hoje)
                    .Select(p => p.Data)
                    .Distinct()
                    .ToListAsync(ct);
                return presencas.Count >= 5;
            }

            case TipoConquista.MesInvicto:
            {
                var hoje = DateOnly.FromDateTime(DateTime.UtcNow);
                var inicioMes = new DateOnly(hoje.Year, hoje.Month, 1);
                var totalAulas = await _db.Horarios.CountAsync(ct);
                if (totalAulas == 0) return false;
                var presencasMes = await _db.Presencas
                    .CountAsync(p => p.AlunoId == alunoId && p.Data >= inicioMes && p.Data <= hoje, ct);
                return presencasMes > 0 && presencasMes >= totalAulas;
            }

            case TipoConquista.Graduado:
                return await _db.Graduacoes.AnyAsync(g => g.AlunoId == alunoId && g.Aprovado, ct);

            case TipoConquista.Sequencia10:
            {
                var presencas = await _db.Presencas
                    .Where(p => p.AlunoId == alunoId)
                    .Select(p => p.Data)
                    .Distinct()
                    .OrderByDescending(d => d)
                    .Take(10)
                    .ToListAsync(ct);
                if (presencas.Count < 10) return false;
                for (var i = 0; i < presencas.Count - 1; i++)
                {
                    if ((presencas[i].DayNumber - presencas[i + 1].DayNumber) > 3)
                        return false;
                }
                return true;
            }

            case TipoConquista.Veterano50:
                return await _db.Presencas.CountAsync(p => p.AlunoId == alunoId, ct) >= 50;

            case TipoConquista.Lenda100:
                return await _db.Presencas.CountAsync(p => p.AlunoId == alunoId, ct) >= 100;

            default:
                return false;
        }
    }
}
