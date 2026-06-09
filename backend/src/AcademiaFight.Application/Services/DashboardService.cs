using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Dashboard;
using AcademiaFight.Application.Helpers;
using AcademiaFight.Application.Interfaces;
using AcademiaFight.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using AcademiaFight.Application.DTOs.Graduacao;

namespace AcademiaFight.Application.Services;

public class DashboardService : IDashboardService
{
    private readonly IAppDbContext _db;
    private readonly ILogger<DashboardService> _logger;

    public DashboardService(IAppDbContext db, ILogger<DashboardService> logger)
    {
        _db = db;
        _logger = logger;
    }

    public async Task<BaseResponse<DashboardResumoDto>> GetResumoAsync(CancellationToken ct = default)
    {
        var hoje = DateTimeHelper.Hoje();
        var horaAgora = DateTimeHelper.HoraAgora();
        var diaSemanaHoje = (DiaSemana)(int)DateTime.Today.DayOfWeek;

        var totalAlunos = await _db.Usuarios
            .CountAsync(u => u.Perfil == PerfilUsuario.Aluno && u.Ativo, ct);

        var turmasAtivas = await _db.Turmas.CountAsync(t => t.Ativo, ct);
        var presencasHoje = await _db.Presencas.CountAsync(p => p.Data == hoje, ct);

        var alunosSemTurma = await _db.Usuarios
            .Where(u => u.Perfil == PerfilUsuario.Aluno && u.Ativo)
            .CountAsync(u => !_db.Matriculas.Any(m => m.AlunoId == u.Id && m.Ativo), ct);

        var proximasAulas = await _db.Horarios
            .Include(h => h.Turma).ThenInclude(t => t.Modalidade)
            .Include(h => h.Turma).ThenInclude(t => t.Matriculas.Where(m => m.Ativo))
            .Where(h => h.DiaSemana == diaSemanaHoje && h.HoraInicio >= horaAgora)
            .OrderBy(h => h.HoraInicio)
            .Take(3)
            .ToListAsync(ct);

        return BaseResponse<DashboardResumoDto>.Ok(new DashboardResumoDto
        {
            TotalAlunos = totalAlunos,
            TurmasAtivas = turmasAtivas,
            PresencasHoje = presencasHoje,
            AlunosInadimplentes = alunosSemTurma,
            ProximasAulas = proximasAulas.Select(h => new ProximaAulaDto
            {
                HorarioId = h.Id,
                Turma = h.Turma?.Nome ?? string.Empty,
                Modalidade = h.Turma?.Modalidade?.Nome ?? string.Empty,
                HoraInicio = h.HoraInicio,
                HoraFim = h.HoraFim,
                Sala = h.Sala,
                TotalAlunos = h.Turma?.Matriculas?.Count(m => m.Ativo) ?? 0,
                CapacidadeMaxima = h.Turma?.CapacidadeMaxima ?? 0
            })
        });
    }

    public async Task<BaseResponse<IEnumerable<FrequenciaDiariaDto>>> GetFrequenciaDiariaAsync(int dias, CancellationToken ct = default)
    {
        var hoje = DateTimeHelper.Hoje();
        var inicio = hoje.AddDays(-(dias - 1));

        var dados = await _db.Presencas
            .Where(p => p.Data >= inicio && p.Data <= hoje)
            .GroupBy(p => p.Data)
            .Select(g => new FrequenciaDiariaDto { Data = g.Key, Total = g.Count() })
            .ToListAsync(ct);

        // Preenche dias sem presenças com zero
        var resultado = Enumerable.Range(0, dias)
            .Select(i => inicio.AddDays(i))
            .Select(d => dados.FirstOrDefault(x => x.Data == d) ?? new FrequenciaDiariaDto { Data = d, Total = 0 })
            .ToList();

        return BaseResponse<IEnumerable<FrequenciaDiariaDto>>.Ok(resultado);
    }

    public async Task<BaseResponse<IEnumerable<AlunoProximoGraduacaoDto>>> GetAlunosProximosGraduacaoAsync(CancellationToken ct = default)
    {
        // Para cada faixa com requisito de presença > 0, encontra alunos que têm >= 60% do mínimo
        var faixas = await _db.Faixas
            .Where(f => f.RequisitosPresencasMinimas > 0)
            .Include(f => f.Modalidade)
            .ToListAsync(ct);

        var resultado = new List<AlunoProximoGraduacaoDto>();

        foreach (var faixa in faixas)
        {
            var matriculas = await _db.Matriculas
                .Include(m => m.Aluno)
                .Where(m => m.Ativo && m.Turma.ModalidadeId == faixa.ModalidadeId)
                .ToListAsync(ct);

            var alunoIds = matriculas.Select(m => m.AlunoId).Distinct().ToList();

            // Exclui quem já tem faixa igual ou superior
            var comFaixaSuperior = await _db.Graduacoes
                .Include(g => g.Faixa)
                .Where(g => alunoIds.Contains(g.AlunoId)
                    && g.Aprovado
                    && g.Faixa.ModalidadeId == faixa.ModalidadeId
                    && g.Faixa.Ordem >= faixa.Ordem)
                .Select(g => g.AlunoId)
                .Distinct()
                .ToListAsync(ct);

            // Faixa atual de cada aluno (mais alta aprovada nesta modalidade)
            var faixaAtualDict = await _db.Graduacoes
                .Include(g => g.Faixa)
                .Where(g => alunoIds.Contains(g.AlunoId)
                    && g.Aprovado
                    && g.Faixa.ModalidadeId == faixa.ModalidadeId)
                .GroupBy(g => g.AlunoId)
                .Select(g => new { AlunoId = g.Key, Faixa = g.OrderByDescending(x => x.Faixa.Ordem).First() })
                .ToDictionaryAsync(x => x.AlunoId, x => x.Faixa, ct);

            var candidatos = matriculas
                .Where(m => !comFaixaSuperior.Contains(m.AlunoId))
                .GroupBy(m => m.AlunoId)
                .Select(g => g.OrderBy(m => m.DataInicio).First())
                .ToList();

            var presencas = await _db.Presencas
                .Where(p => candidatos.Select(c => c.AlunoId).Contains(p.AlunoId))
                .GroupBy(p => p.AlunoId)
                .Select(g => new { AlunoId = g.Key, Total = g.Count() })
                .ToDictionaryAsync(x => x.AlunoId, x => x.Total, ct);

            foreach (var m in candidatos)
            {
                var total = presencas.GetValueOrDefault(m.AlunoId, 0);
                var pct = faixa.RequisitosPresencasMinimas > 0
                    ? (int)Math.Round((double)total / faixa.RequisitosPresencasMinimas * 100)
                    : 0;

                if (pct >= 60)
                {
                    var faixaAtualInfo = faixaAtualDict.TryGetValue(m.AlunoId, out var fa) ? fa : null;
                    resultado.Add(new AlunoProximoGraduacaoDto
                    {
                        AlunoId = m.AlunoId,
                        NomeAluno = m.Aluno?.Nome ?? string.Empty,
                        NomeModalidade = faixa.Modalidade?.Nome ?? string.Empty,
                        NomeFaixaAtual = faixaAtualInfo?.Faixa?.Nome ?? "Sem faixa",
                        CorFaixaAtual = faixaAtualInfo?.Faixa?.Cor ?? "#888888",
                        TotalPresencas = total,
                        PresencasNecessarias = faixa.RequisitosPresencasMinimas,
                        JaApto = total >= faixa.RequisitosPresencasMinimas,
                        Percentual = Math.Min(pct, 100),
                    });
                }
            }
        }

        return BaseResponse<IEnumerable<AlunoProximoGraduacaoDto>>.Ok(
            resultado.OrderByDescending(a => a.JaApto).ThenByDescending(a => a.Percentual).Take(15));
    }
}
