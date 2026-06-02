using AcademiaFight.Application.DTOs.RankingCustom;
using AcademiaFight.Application.Interfaces;
using AcademiaFight.Domain.Entities;
using AcademiaFight.Domain.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace AcademiaFight.Application.Services;

public class RankingCustomService : IRankingCustomService
{
    private const int PageSize = 20;
    private readonly IAppDbContext _db;
    private readonly ITenantContext _tenant;

    public RankingCustomService(IAppDbContext db, ITenantContext tenant)
    {
        _db = db;
        _tenant = tenant;
    }

    public async Task<IEnumerable<RankingCustomDto>> ListarAsync(bool incluirInativos = false, CancellationToken ct = default)
    {
        var query = _db.RankingsCustom.AsQueryable();
        if (!incluirInativos) query = query.Where(r => r.Ativo);

        return await query
            .OrderBy(r => r.Nome)
            .Select(r => ToDto(r))
            .ToListAsync(ct);
    }

    public async Task<RankingCustomDto?> ObterAsync(Guid id, CancellationToken ct = default)
    {
        var r = await _db.RankingsCustom.FirstOrDefaultAsync(x => x.Id == id, ct);
        return r is null ? null : ToDto(r);
    }

    public async Task<RankingCustomDto> CriarAsync(CriarRankingCustomRequest req, CancellationToken ct = default)
    {
        var ranking = new RankingCustom
        {
            AcademiaId = _tenant.AcademiaId,
            Nome = req.Nome,
            Descricao = req.Descricao,
            IncluirPresencas = req.IncluirPresencas,
            IncluirPontosManuais = req.IncluirPontosManuais,
            PesoPresencas = Math.Max(1, req.PesoPresencas),
            PesoManuais = Math.Max(1, req.PesoManuais),
            VisivelParaAluno = req.VisivelParaAluno,
            DataInicio = req.DataInicio,
            DataFim = req.DataFim,
            Ativo = true
        };

        _db.RankingsCustom.Add(ranking);
        await _db.SaveChangesAsync(ct);
        return ToDto(ranking);
    }

    public async Task<RankingCustomDto?> AtualizarAsync(Guid id, AtualizarRankingCustomRequest req, CancellationToken ct = default)
    {
        var ranking = await _db.RankingsCustom.FirstOrDefaultAsync(x => x.Id == id, ct);
        if (ranking is null) return null;

        ranking.Nome = req.Nome;
        ranking.Descricao = req.Descricao;
        ranking.IncluirPresencas = req.IncluirPresencas;
        ranking.IncluirPontosManuais = req.IncluirPontosManuais;
        ranking.PesoPresencas = Math.Max(1, req.PesoPresencas);
        ranking.PesoManuais = Math.Max(1, req.PesoManuais);
        ranking.VisivelParaAluno = req.VisivelParaAluno;
        ranking.DataInicio = req.DataInicio;
        ranking.DataFim = req.DataFim;
        ranking.Ativo = req.Ativo;

        await _db.SaveChangesAsync(ct);
        return ToDto(ranking);
    }

    public async Task<bool> DesativarAsync(Guid id, CancellationToken ct = default)
    {
        var ranking = await _db.RankingsCustom.FirstOrDefaultAsync(x => x.Id == id, ct);
        if (ranking is null) return false;

        ranking.Ativo = false;
        await _db.SaveChangesAsync(ct);
        return true;
    }

    public async Task<LeaderboardCustomDto?> GetLeaderboardAsync(Guid rankingId, int pagina = 1, CancellationToken ct = default)
    {
        var ranking = await _db.RankingsCustom.FirstOrDefaultAsync(r => r.Id == rankingId, ct);
        if (ranking is null) return null;

        // Todos os alunos ativos da academia
        var alunos = await _db.Usuarios
            .Where(u => u.Ativo && u.Perfil == Domain.Enums.PerfilUsuario.Aluno)
            .Select(u => new { u.Id, u.Nome })
            .ToListAsync(ct);

        // Presenças por aluno (se configurado), respeitando o intervalo de datas do ranking
        Dictionary<Guid, int> presencasPorAluno = [];
        if (ranking.IncluirPresencas)
        {
            var alunoIdSet = alunos.Select(a => a.Id).ToList();
            var qPresencas = _db.Presencas.Where(p => alunoIdSet.Contains(p.AlunoId));
            if (ranking.DataInicio.HasValue) qPresencas = qPresencas.Where(p => p.Data >= ranking.DataInicio.Value);
            if (ranking.DataFim.HasValue)   qPresencas = qPresencas.Where(p => p.Data <= ranking.DataFim.Value);

            presencasPorAluno = await qPresencas
                .GroupBy(p => p.AlunoId)
                .Select(g => new { AlunoId = g.Key, Total = g.Count() })
                .ToDictionaryAsync(x => x.AlunoId, x => x.Total, ct);
        }

        // Pontos manuais por aluno (se configurado)
        Dictionary<Guid, int> manuaisPorAluno = [];
        if (ranking.IncluirPontosManuais)
        {
            manuaisPorAluno = await _db.LancamentosPonto
                .Where(l => l.RankingCustomId == rankingId)
                .GroupBy(l => l.AlunoId)
                .Select(g => new { AlunoId = g.Key, Total = g.Sum(l => l.Pontos) })
                .ToDictionaryAsync(x => x.AlunoId, x => x.Total, ct);
        }

        var total = alunos.Count;
        var totalPaginas = (int)Math.Ceiling((double)total / PageSize);

        var items = alunos
            .Select(a =>
            {
                var presencas = presencasPorAluno.GetValueOrDefault(a.Id, 0);
                var manuais = manuaisPorAluno.GetValueOrDefault(a.Id, 0);
                var totalPontos = (presencas * ranking.PesoPresencas) + (manuais * ranking.PesoManuais);
                return new { a.Id, a.Nome, PontosPresencas = presencas * ranking.PesoPresencas, PontosManuais = manuais * ranking.PesoManuais, TotalPontos = totalPontos };
            })
            .OrderByDescending(x => x.TotalPontos)
            .ThenBy(x => x.Nome)
            .Skip((pagina - 1) * PageSize)
            .Take(PageSize)
            .Select((x, i) => new LeaderboardCustomItemDto
            {
                Posicao = (pagina - 1) * PageSize + i + 1,
                AlunoId = x.Id,
                NomeAluno = x.Nome,
                PontosPresencas = x.PontosPresencas,
                PontosManuais = x.PontosManuais,
                TotalPontos = x.TotalPontos
            })
            .ToList();

        return new LeaderboardCustomDto
        {
            RankingId = ranking.Id,
            NomeRanking = ranking.Nome,
            Descricao = ranking.Descricao,
            IncluirPresencas = ranking.IncluirPresencas,
            IncluirPontosManuais = ranking.IncluirPontosManuais,
            PesoPresencas = ranking.PesoPresencas,
            PesoManuais = ranking.PesoManuais,
            DataInicio = ranking.DataInicio,
            DataFim = ranking.DataFim,
            TotalParticipantes = total,
            Pagina = pagina,
            TamanhoPagina = PageSize,
            TotalPaginas = totalPaginas,
            Items = items
        };
    }

    public async Task<LancamentoPontoDto> LancarPontosAsync(Guid rankingId, LancarPontosRequest req, Guid registradoPorId, CancellationToken ct = default)
    {
        var lancamento = new LancamentoPonto
        {
            RankingCustomId = rankingId,
            AlunoId = req.AlunoId,
            AcademiaId = _tenant.AcademiaId,
            Pontos = req.Pontos,
            Descricao = req.Descricao,
            RegistradoPorId = registradoPorId,
            Data = req.Data ?? DateOnly.FromDateTime(DateTime.UtcNow)
        };

        _db.LancamentosPonto.Add(lancamento);
        await _db.SaveChangesAsync(ct);

        var aluno = await _db.Usuarios.FirstOrDefaultAsync(u => u.Id == req.AlunoId, ct);
        var registrador = await _db.Usuarios.FirstOrDefaultAsync(u => u.Id == registradoPorId, ct);

        return new LancamentoPontoDto
        {
            Id = lancamento.Id,
            AlunoId = lancamento.AlunoId,
            NomeAluno = aluno?.Nome ?? string.Empty,
            Pontos = lancamento.Pontos,
            Descricao = lancamento.Descricao,
            NomeRegistradoPor = registrador?.Nome ?? string.Empty,
            Data = lancamento.Data,
            CriadoEm = lancamento.CriadoEm
        };
    }

    public async Task<bool> RemoverLancamentoAsync(Guid lancamentoId, CancellationToken ct = default)
    {
        var lancamento = await _db.LancamentosPonto.FirstOrDefaultAsync(l => l.Id == lancamentoId, ct);
        if (lancamento is null) return false;

        _db.LancamentosPonto.Remove(lancamento);
        await _db.SaveChangesAsync(ct);
        return true;
    }

    public async Task<IEnumerable<LancamentoPontoDto>> ListarLancamentosAsync(Guid rankingId, Guid? alunoId = null, CancellationToken ct = default)
    {
        var query = _db.LancamentosPonto
            .Include(l => l.Aluno)
            .Include(l => l.RegistradoPor)
            .Where(l => l.RankingCustomId == rankingId);

        if (alunoId.HasValue)
            query = query.Where(l => l.AlunoId == alunoId.Value);

        return await query
            .OrderByDescending(l => l.Data)
            .ThenByDescending(l => l.CriadoEm)
            .Select(l => new LancamentoPontoDto
            {
                Id = l.Id,
                AlunoId = l.AlunoId,
                NomeAluno = l.Aluno.Nome,
                Pontos = l.Pontos,
                Descricao = l.Descricao,
                NomeRegistradoPor = l.RegistradoPor.Nome,
                Data = l.Data,
                CriadoEm = l.CriadoEm
            })
            .ToListAsync(ct);
    }

    private static RankingCustomDto ToDto(RankingCustom r) => new()
    {
        Id = r.Id,
        Nome = r.Nome,
        Descricao = r.Descricao,
        IncluirPresencas = r.IncluirPresencas,
        IncluirPontosManuais = r.IncluirPontosManuais,
        PesoPresencas = r.PesoPresencas,
        PesoManuais = r.PesoManuais,
        VisivelParaAluno = r.VisivelParaAluno,
        Ativo = r.Ativo,
        DataInicio = r.DataInicio,
        DataFim = r.DataFim,
        CriadoEm = r.CriadoEm
    };
}
