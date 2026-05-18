using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Horario;
using AcademiaFight.Application.Interfaces;
using AcademiaFight.Domain.Entities;
using AcademiaFight.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace AcademiaFight.Application.Services;

public class HorarioService : IHorarioService
{
    private readonly IAppDbContext _db;
    private readonly ILogger<HorarioService> _logger;

    private static readonly string[] DiasLabels =
        ["Domingo", "Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado"];

    public HorarioService(IAppDbContext db, ILogger<HorarioService> logger)
    {
        _db = db;
        _logger = logger;
    }

    public async Task<BaseResponse<GradeHorariosDto>> GetGradeAsync(CancellationToken ct = default)
    {
        var horarios = await _db.Horarios
            .Include(h => h.Turma).ThenInclude(t => t.Modalidade)
            .Include(h => h.Turma).ThenInclude(t => t.Professor)
            .Include(h => h.Turma).ThenInclude(t => t.Matriculas.Where(m => m.Ativo))
            .OrderBy(h => h.DiaSemana).ThenBy(h => h.HoraInicio)
            .ToListAsync(ct);

        var grade = new Dictionary<string, List<HorarioDto>>();

        foreach (DiaSemana dia in Enum.GetValues<DiaSemana>())
        {
            var label = DiasLabels[(int)dia];
            var doDia = horarios
                .Where(h => h.DiaSemana == dia)
                .Select(MapearDto)
                .ToList();

            if (doDia.Count > 0)
                grade[label] = doDia;
        }

        return BaseResponse<GradeHorariosDto>.Ok(new GradeHorariosDto { Grade = grade });
    }

    public async Task<BaseResponse<IEnumerable<HorarioDto>>> GetByTurmaAsync(Guid turmaId, CancellationToken ct = default)
    {
        var horarios = await _db.Horarios
            .Include(h => h.Turma).ThenInclude(t => t.Modalidade)
            .Include(h => h.Turma).ThenInclude(t => t.Professor)
            .Include(h => h.Turma).ThenInclude(t => t.Matriculas.Where(m => m.Ativo))
            .Where(h => h.TurmaId == turmaId)
            .OrderBy(h => h.DiaSemana).ThenBy(h => h.HoraInicio)
            .ToListAsync(ct);

        return BaseResponse<IEnumerable<HorarioDto>>.Ok(horarios.Select(MapearDto));
    }

    public async Task<BaseResponse<HorarioDto>> CreateAsync(CreateHorarioRequest request, CancellationToken ct = default)
    {
        var turma = await _db.Turmas
            .Include(t => t.Modalidade)
            .Include(t => t.Professor)
            .Include(t => t.Matriculas.Where(m => m.Ativo))
            .FirstOrDefaultAsync(t => t.Id == request.TurmaId, ct);

        if (turma is null)
            return BaseResponse<HorarioDto>.Falha("Turma não encontrada.");

        var dia = (DiaSemana)request.DiaSemana;
        var conflito = await VerificarConflitoAsync(request.TurmaId, turma.ProfessorId, request.Sala,
            dia, request.HoraInicio, request.HoraFim, null, ct);

        if (conflito is not null)
            return BaseResponse<HorarioDto>.Falha(conflito);

        var horario = new Horario
        {
            TurmaId = request.TurmaId,
            DiaSemana = dia,
            HoraInicio = request.HoraInicio,
            HoraFim = request.HoraFim,
            Sala = request.Sala
        };

        await _db.Horarios.AddAsync(horario, ct);
        await _db.SaveChangesAsync(ct);

        horario.Turma = turma;

        _logger.LogInformation("Horário criado para turma {TurmaId}", request.TurmaId);
        return BaseResponse<HorarioDto>.Ok(MapearDto(horario), "Horário criado com sucesso.");
    }

    public async Task<BaseResponse<HorarioDto>> UpdateAsync(Guid id, CreateHorarioRequest request, CancellationToken ct = default)
    {
        var horario = await _db.Horarios
            .Include(h => h.Turma).ThenInclude(t => t.Modalidade)
            .Include(h => h.Turma).ThenInclude(t => t.Professor)
            .Include(h => h.Turma).ThenInclude(t => t.Matriculas.Where(m => m.Ativo))
            .FirstOrDefaultAsync(h => h.Id == id, ct);

        if (horario is null)
            return BaseResponse<HorarioDto>.Falha("Horário não encontrado.");

        var turma = horario.TurmaId != request.TurmaId
            ? await _db.Turmas
                .Include(t => t.Modalidade)
                .Include(t => t.Professor)
                .Include(t => t.Matriculas.Where(m => m.Ativo))
                .FirstOrDefaultAsync(t => t.Id == request.TurmaId, ct)
            : horario.Turma;

        if (turma is null)
            return BaseResponse<HorarioDto>.Falha("Turma não encontrada.");

        var dia = (DiaSemana)request.DiaSemana;
        var conflito = await VerificarConflitoAsync(request.TurmaId, turma.ProfessorId, request.Sala,
            dia, request.HoraInicio, request.HoraFim, id, ct);

        if (conflito is not null)
            return BaseResponse<HorarioDto>.Falha(conflito);

        horario.TurmaId = request.TurmaId;
        horario.DiaSemana = dia;
        horario.HoraInicio = request.HoraInicio;
        horario.HoraFim = request.HoraFim;
        horario.Sala = request.Sala;
        horario.Turma = turma;

        await _db.SaveChangesAsync(ct);
        return BaseResponse<HorarioDto>.Ok(MapearDto(horario), "Horário atualizado com sucesso.");
    }

    public async Task<BaseResponse> DeleteAsync(Guid id, CancellationToken ct = default)
    {
        var horario = await _db.Horarios.FirstOrDefaultAsync(h => h.Id == id, ct);
        if (horario is null)
            return BaseResponse.Falha("Horário não encontrado.");

        _db.Horarios.Remove(horario);
        await _db.SaveChangesAsync(ct);
        return BaseResponse.Ok("Horário removido com sucesso.");
    }

    private async Task<string?> VerificarConflitoAsync(
        Guid turmaId, Guid professorId, string? sala,
        DiaSemana dia, TimeOnly inicio, TimeOnly fim,
        Guid? ignorarId, CancellationToken ct)
    {
        var query = _db.Horarios
            .Include(h => h.Turma).ThenInclude(t => t.Professor)
            .Where(h => h.DiaSemana == dia && h.Id != (ignorarId ?? Guid.Empty)
                && h.HoraInicio < fim && h.HoraFim > inicio);

        // Conflito de professor
        var conflitoProfessor = await query
            .Where(h => h.Turma.ProfessorId == professorId && h.TurmaId != turmaId)
            .FirstOrDefaultAsync(ct);

        if (conflitoProfessor is not null)
            return $"Professor já tem aula das {conflitoProfessor.HoraInicio:HH\\:mm} às {conflitoProfessor.HoraFim:HH\\:mm} na {DiasLabels[(int)dia]}.";

        // Conflito de sala
        if (!string.IsNullOrWhiteSpace(sala))
        {
            var conflitoSala = await query
                .Where(h => h.Sala == sala && h.TurmaId != turmaId)
                .FirstOrDefaultAsync(ct);

            if (conflitoSala is not null)
                return $"Sala '{sala}' já está ocupada das {conflitoSala.HoraInicio:HH\\:mm} às {conflitoSala.HoraFim:HH\\:mm} na {DiasLabels[(int)dia]}.";
        }

        return null;
    }

    private static HorarioDto MapearDto(Horario h) => new()
    {
        Id = h.Id,
        TurmaId = h.TurmaId,
        NomeTurma = h.Turma?.Nome ?? string.Empty,
        NomeModalidade = h.Turma?.Modalidade?.Nome ?? string.Empty,
        NomeProfessor = h.Turma?.Professor?.Nome ?? string.Empty,
        DiaSemana = (int)h.DiaSemana,
        DiaSemanaLabel = DiasLabels[(int)h.DiaSemana],
        HoraInicio = h.HoraInicio,
        HoraFim = h.HoraFim,
        Sala = h.Sala,
        TotalAlunos = h.Turma?.Matriculas?.Count(m => m.Ativo) ?? 0,
        CapacidadeMaxima = h.Turma?.CapacidadeMaxima ?? 0
    };
}
