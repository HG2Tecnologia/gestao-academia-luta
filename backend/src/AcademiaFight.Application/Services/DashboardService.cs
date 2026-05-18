using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Dashboard;
using AcademiaFight.Application.Helpers;
using AcademiaFight.Application.Interfaces;
using AcademiaFight.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

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
}
