using AcademiaFight.Application.DTOs.Ranking;
using AcademiaFight.Application.Interfaces;
using AcademiaFight.Domain.Interfaces;
using Microsoft.EntityFrameworkCore;
using AcademiaFight.Domain.Enums;

namespace AcademiaFight.Application.Services;

public class RankingService : IRankingService
{
    private const int PageSize = 20;
    private readonly IAppDbContext _db;
    private readonly ITenantContext _tenant;

    public RankingService(IAppDbContext db, ITenantContext tenant)
    {
        _db = db;
        _tenant = tenant;
    }

    public async Task<LeaderboardDto> GetLeaderboardTurmaAsync(Guid turmaId, string periodo, int pagina = 1, CancellationToken ct = default)
    {
        var alunoIds = await _db.Matriculas
            .Where(m => m.TurmaId == turmaId && m.Ativo)
            .Select(m => m.AlunoId)
            .ToListAsync(ct);

        return await BuildLeaderboard(alunoIds, periodo, pagina, ct);
    }

    public async Task<LeaderboardDto> GetLeaderboardAcademiaAsync(string periodo, int pagina = 1, CancellationToken ct = default)
    {
        var alunoIds = await _db.Usuarios
            .Where(u => u.Ativo && u.Perfil == AcademiaFight.Domain.Enums.PerfilUsuario.Aluno)
            .Select(u => u.Id)
            .ToListAsync(ct);

        return await BuildLeaderboard(alunoIds, periodo, pagina, ct);
    }

    public async Task<LeaderboardPresencaDto?> GetLeaderboardModalidadeAsync(Guid modalidadeId, int pagina = 1, DateOnly? dataInicio = null, DateOnly? dataFim = null, CancellationToken ct = default)
    {
        var modalidade = await _db.Modalidades.FirstOrDefaultAsync(m => m.Id == modalidadeId, ct);
        if (modalidade is null) return null;

        var alunoIds = await _db.Matriculas
            .Where(m => m.Ativo)
            .Join(_db.Turmas.Where(t => t.ModalidadeId == modalidadeId && t.Ativo),
                  m => m.TurmaId, t => t.Id, (m, t) => m.AlunoId)
            .Distinct()
            .ToListAsync(ct);

        return await BuildLeaderboardPresencas(alunoIds, "modalidade", modalidade.Nome, pagina, dataInicio, dataFim, ct);
    }

    public async Task<LeaderboardPresencaDto> GetLeaderboardPresencasTurmaAsync(Guid turmaId, int pagina = 1, DateOnly? dataInicio = null, DateOnly? dataFim = null, CancellationToken ct = default)
    {
        var turma = await _db.Turmas
            .Include(t => t.Modalidade)
            .FirstOrDefaultAsync(t => t.Id == turmaId, ct);

        var alunoIds = await _db.Matriculas
            .Where(m => m.TurmaId == turmaId && m.Ativo)
            .Select(m => m.AlunoId)
            .ToListAsync(ct);

        var nomeEscopo = turma is not null
            ? $"{turma.Modalidade?.Nome} — {turma.Nome}"
            : "Turma";

        return await BuildLeaderboardPresencas(alunoIds, "turma", nomeEscopo, pagina, dataInicio, dataFim, ct);
    }

    private async Task<LeaderboardPresencaDto> BuildLeaderboardPresencas(
        List<Guid> alunoIds, string escopo, string nomeEscopo, int pagina,
        DateOnly? dataInicio, DateOnly? dataFim, CancellationToken ct)
    {
        var alunos = await _db.Usuarios
            .Where(u => alunoIds.Contains(u.Id) && u.Ativo)
            .Select(u => new { u.Id, u.Nome })
            .ToListAsync(ct);

        var qPresencas = _db.Presencas.Where(p => alunoIds.Contains(p.AlunoId));
        if (dataInicio.HasValue) qPresencas = qPresencas.Where(p => p.Data >= dataInicio.Value);
        if (dataFim.HasValue)   qPresencas = qPresencas.Where(p => p.Data <= dataFim.Value);

        var presencas = await qPresencas
            .GroupBy(p => p.AlunoId)
            .Select(g => new { AlunoId = g.Key, Total = g.Count() })
            .ToDictionaryAsync(x => x.AlunoId, x => x.Total, ct);

        var total = alunos.Count;
        var totalPaginas = (int)Math.Ceiling((double)total / PageSize);

        var items = alunos
            .Select(a => new { a.Id, a.Nome, Total = presencas.GetValueOrDefault(a.Id, 0) })
            .OrderByDescending(x => x.Total)
            .ThenBy(x => x.Nome)
            .Skip((pagina - 1) * PageSize)
            .Take(PageSize)
            .Select((x, i) => new LeaderboardPresencaItemDto
            {
                Posicao = (pagina - 1) * PageSize + i + 1,
                AlunoId = x.Id,
                NomeAluno = x.Nome,
                TotalPresencas = x.Total
            })
            .ToList();

        return new LeaderboardPresencaDto
        {
            Escopo = escopo,
            NomeEscopo = nomeEscopo,
            DataInicio = dataInicio,
            DataFim = dataFim,
            TotalParticipantes = total,
            Pagina = pagina,
            TamanhoPagina = PageSize,
            TotalPaginas = totalPaginas,
            Items = items
        };
    }

    public async Task<PerfilGamificadoDto?> GetPerfilGamificadoAsync(Guid alunoId, CancellationToken ct = default)
    {
        var aluno = await _db.Usuarios
            .FirstOrDefaultAsync(u => u.Id == alunoId, ct);

        if (aluno is null)
            return null;

        // Conquistas desbloqueadas
        var conquistasDesbloqueadas = await _db.ConquistasAluno
            .Include(ca => ca.Conquista)
            .Where(ca => ca.AlunoId == alunoId)
            .ToListAsync(ct);

        // Histórico XP (últimos 10)
        var historicoXp = await _db.PontosRanking
            .Where(p => p.AlunoId == alunoId)
            .OrderByDescending(p => p.CriadoEm)
            .Take(10)
            .ToListAsync(ct);

        // Posição global
        var rankingGlobal = await _db.Usuarios
            .Where(u => u.Ativo && u.XpTotal > aluno.XpTotal)
            .CountAsync(ct);
        var posicaoGlobal = rankingGlobal + 1;

        // Posição na turma (primeira turma ativa)
        var turmaId = await _db.Matriculas
            .Where(m => m.AlunoId == alunoId && m.Ativo)
            .Select(m => m.TurmaId)
            .FirstOrDefaultAsync(ct);

        var posicaoTurma = 0;
        if (turmaId != Guid.Empty)
        {
            var colegasMaisXp = await _db.Matriculas
                .Where(m => m.TurmaId == turmaId && m.Ativo && m.AlunoId != alunoId)
                .Join(_db.Usuarios, m => m.AlunoId, u => u.Id, (m, u) => u.XpTotal)
                .CountAsync(x => x > aluno.XpTotal, ct);
            posicaoTurma = colegasMaisXp + 1;
        }

        // Sequência atual (dias consecutivos)
        var sequencia = await CalcularSequenciaAtualAsync(alunoId, ct);

        return new PerfilGamificadoDto
        {
            AlunoId = alunoId,
            Nome = aluno.Nome,
            Nivel = aluno.Nivel.ToString(),
            XpTotal = aluno.XpTotal,
            XpMensal = aluno.XpMensal,
            XpParaProximoNivel = XpService.XpParaProximoNivel(aluno.XpTotal),
            PosicaoGlobal = posicaoGlobal,
            PosicaoTurma = posicaoTurma,
            SequenciaAtual = sequencia,
            ConquistasDesbloqueadas = conquistasDesbloqueadas.Select(ca => new ConquistaDto
            {
                Id = ca.Conquista.Id,
                Tipo = ca.Conquista.Tipo.ToString(),
                Nome = ca.Conquista.Nome,
                Descricao = ca.Conquista.Descricao,
                IconeUrl = ca.Conquista.IconeUrl,
                PontosXpBonus = ca.Conquista.PontosXpBonus,
                Desbloqueada = true,
                DesbloqueadaEm = ca.DesbloqueadaEm
            }),
            HistoricoXp = historicoXp.Select(p => new HistoricoXpItemDto
            {
                Id = p.Id,
                TipoEvento = p.TipoEvento.ToString(),
                Pontos = p.Pontos,
                Data = p.Data,
                CriadoEm = p.CriadoEm
            })
        };
    }

    private async Task<LeaderboardDto> BuildLeaderboard(List<Guid> alunoIds, string periodo, int pagina, CancellationToken ct)
    {
        var total = alunoIds.Count;
        var totalPaginas = (int)Math.Ceiling((double)total / PageSize);

        if (periodo == "mensal")
        {
            var inicioMes = new DateOnly(DateTime.UtcNow.Year, DateTime.UtcNow.Month, 1);
            var xpMensal = await _db.PontosRanking
                .Where(p => alunoIds.Contains(p.AlunoId) && p.Data >= inicioMes)
                .GroupBy(p => p.AlunoId)
                .Select(g => new { AlunoId = g.Key, Xp = g.Sum(p => p.Pontos) })
                .ToListAsync(ct);

            var usuarios = await _db.Usuarios
                .Where(u => alunoIds.Contains(u.Id) && u.Ativo)
                .Select(u => new { u.Id, u.Nome, u.Nivel, u.XpTotal })
                .ToListAsync(ct);

            var conquistas = await _db.ConquistasAluno
                .Where(ca => alunoIds.Contains(ca.AlunoId))
                .GroupBy(ca => ca.AlunoId)
                .Select(g => new { AlunoId = g.Key, Total = g.Count() })
                .ToListAsync(ct);

            var items = usuarios
                .Select(u => new
                {
                    u.Id,
                    u.Nome,
                    Nivel = u.Nivel.ToString(),
                    XpPeriodo = xpMensal.FirstOrDefault(x => x.AlunoId == u.Id)?.Xp ?? 0,
                    u.XpTotal,
                    TotalConquistas = conquistas.FirstOrDefault(c => c.AlunoId == u.Id)?.Total ?? 0
                })
                .OrderByDescending(x => x.XpPeriodo)
                .ThenByDescending(x => x.XpTotal)
                .Skip((pagina - 1) * PageSize)
                .Take(PageSize)
                .Select((x, i) => new LeaderboardItemDto
                {
                    Posicao = (pagina - 1) * PageSize + i + 1,
                    AlunoId = x.Id,
                    NomeAluno = x.Nome,
                    Nivel = x.Nivel,
                    XpPeriodo = x.XpPeriodo,
                    XpTotal = x.XpTotal,
                    TotalConquistas = x.TotalConquistas
                })
                .ToList();

            return new LeaderboardDto
            {
                Periodo = periodo,
                TotalParticipantes = total,
                Pagina = pagina,
                TamanhoPagina = PageSize,
                TotalPaginas = totalPaginas,
                Items = items
            };
        }
        else
        {
            var usuarios = await _db.Usuarios
                .Where(u => alunoIds.Contains(u.Id) && u.Ativo)
                .Select(u => new { u.Id, u.Nome, u.Nivel, u.XpTotal })
                .ToListAsync(ct);

            var conquistas = await _db.ConquistasAluno
                .Where(ca => alunoIds.Contains(ca.AlunoId))
                .GroupBy(ca => ca.AlunoId)
                .Select(g => new { AlunoId = g.Key, Total = g.Count() })
                .ToListAsync(ct);

            var items = usuarios
                .OrderByDescending(u => u.XpTotal)
                .Skip((pagina - 1) * PageSize)
                .Take(PageSize)
                .Select((u, i) => new LeaderboardItemDto
                {
                    Posicao = (pagina - 1) * PageSize + i + 1,
                    AlunoId = u.Id,
                    NomeAluno = u.Nome,
                    Nivel = u.Nivel.ToString(),
                    XpPeriodo = u.XpTotal,
                    XpTotal = u.XpTotal,
                    TotalConquistas = conquistas.FirstOrDefault(c => c.AlunoId == u.Id)?.Total ?? 0
                })
                .ToList();

            return new LeaderboardDto
            {
                Periodo = periodo,
                TotalParticipantes = total,
                Pagina = pagina,
                TamanhoPagina = PageSize,
                TotalPaginas = totalPaginas,
                Items = items
            };
        }
    }

    private async Task<int> CalcularSequenciaAtualAsync(Guid alunoId, CancellationToken ct)
    {
        var datas = await _db.Presencas
            .Where(p => p.AlunoId == alunoId)
            .Select(p => p.Data)
            .Distinct()
            .OrderByDescending(d => d)
            .Take(60)
            .ToListAsync(ct);

        if (datas.Count == 0) return 0;

        var sequencia = 1;
        for (var i = 0; i < datas.Count - 1; i++)
        {
            if ((datas[i].DayNumber - datas[i + 1].DayNumber) <= 3)
                sequencia++;
            else
                break;
        }
        return sequencia;
    }
}
