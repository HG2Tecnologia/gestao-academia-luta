using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Presenca;
using AcademiaFight.Application.Helpers;
using AcademiaFight.Application.Interfaces;
using AcademiaFight.Domain.Entities;
using AcademiaFight.Domain.Enums;
using AcademiaFight.Domain.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;


namespace AcademiaFight.Application.Services;

public class PresencaService : IPresencaService
{
    private readonly IAppDbContext _db;
    private readonly IQrTokenService _qrToken;
    private readonly ITenantContext _tenant;
    private readonly IXpService _xp;
    private readonly ILogger<PresencaService> _logger;

    public PresencaService(IAppDbContext db, IQrTokenService qrToken, ITenantContext tenant, IXpService xp, ILogger<PresencaService> logger)
    {
        _db = db;
        _qrToken = qrToken;
        _tenant = tenant;
        _xp = xp;
        _logger = logger;
    }

    private static readonly DiaSemana[] _diasDow =
        [DiaSemana.Domingo, DiaSemana.Segunda, DiaSemana.Terca, DiaSemana.Quarta, DiaSemana.Quinta, DiaSemana.Sexta, DiaSemana.Sabado];

    public async Task<BaseResponse<PresencaDto>> RegistrarAsync(RegistrarPresencaRequest request, CancellationToken ct = default)
    {
        var data = request.Data ?? DateTimeHelper.Hoje();

        Horario? horario = null;

        if (request.HorarioId.HasValue && request.HorarioId.Value != Guid.Empty)
        {
            horario = await _db.Horarios.Include(h => h.Turma)
                .FirstOrDefaultAsync(h => h.Id == request.HorarioId.Value, ct);
        }
        else if (request.TurmaId.HasValue && request.TurmaId.Value != Guid.Empty)
        {
            var diaHoje = _diasDow[(int)DateTime.Now.DayOfWeek];
            horario = await _db.Horarios.Include(h => h.Turma)
                .Where(h => h.TurmaId == request.TurmaId.Value && h.DiaSemana == diaHoje)
                .FirstOrDefaultAsync(ct)
                ?? await _db.Horarios.Include(h => h.Turma)
                    .Where(h => h.TurmaId == request.TurmaId.Value)
                    .FirstOrDefaultAsync(ct);
        }

        if (horario is null)
            return BaseResponse<PresencaDto>.Falha("Horário não encontrado.");

        var turmaId = horario.TurmaId;
        var horarioId = horario.Id;

        var matriculado = await _db.Matriculas
            .AnyAsync(m => m.AlunoId == request.AlunoId && m.TurmaId == turmaId && m.Ativo, ct);

        if (!matriculado)
            return BaseResponse<PresencaDto>.Falha("Aluno não está matriculado nesta turma.");

        var jaRegistrado = await _db.Presencas
            .AnyAsync(p => p.AlunoId == request.AlunoId && p.HorarioId == horarioId && p.Data == data, ct);

        if (jaRegistrado)
            return BaseResponse<PresencaDto>.Falha("Presença já registrada para este aluno nesta aula.");

        var presenca = new Presenca
        {
            AlunoId = request.AlunoId,
            HorarioId = horarioId,
            Data = data,
            HoraCheckin = DateTimeHelper.HoraAgora(),
            MetodoCheckin = (MetodoCheckin)request.MetodoCheckin,
            Confirmado = true,
            ObservacoesProfessor = request.ObservacoesProfessor
        };

        await _db.Presencas.AddAsync(presenca, ct);
        await _db.SaveChangesAsync(ct);

        // XP por presença
        await _xp.AdicionarXpAsync(request.AlunoId, TipoEventoXp.Presenca, 10, presenca.Id, ct);

        // Bônus de sequência (5 dias consecutivos)
        var cincoAgo = data.AddDays(-4);
        var diasComPresenca = await _db.Presencas
            .Where(p => p.AlunoId == request.AlunoId && p.Data >= cincoAgo && p.Data <= data)
            .Select(p => p.Data)
            .Distinct()
            .CountAsync(ct);
        if (diasComPresenca >= 5)
            await _xp.AdicionarXpAsync(request.AlunoId, TipoEventoXp.SequenciaPresenca, 25, presenca.Id, ct);

        // Bônus primeiro check-in do mês
        var inicioMes = new DateOnly(data.Year, data.Month, 1);
        var outrasPresencasMes = await _db.Presencas
            .AnyAsync(p => p.AlunoId == request.AlunoId && p.Data >= inicioMes && p.Data < data, ct);
        if (!outrasPresencasMes)
            await _xp.AdicionarXpAsync(request.AlunoId, TipoEventoXp.PrimeiroCheckinMes, 5, presenca.Id, ct);

        var completa = await _db.Presencas
            .Include(p => p.Aluno)
            .Include(p => p.Horario).ThenInclude(h => h.Turma)
            .FirstAsync(p => p.Id == presenca.Id, ct);

        return BaseResponse<PresencaDto>.Ok(MapearDto(completa), "Presença registrada com sucesso.");
    }

    public async Task<BaseResponse<PresencaDto>> RegistrarPorQrCodeAsync(string tokenQr, CancellationToken ct = default)
    {
        var alunoId = _qrToken.ValidarToken(tokenQr);
        if (alunoId is null)
            return BaseResponse<PresencaDto>.Falha("Token QR inválido ou expirado.");

        var agora = DateTimeHelper.Agora();
        var horaAgora = TimeOnly.FromDateTime(agora);
        var hoje = DateOnly.FromDateTime(agora);

        var horario = await _db.Horarios
            .Include(h => h.Turma)
            .Where(h => h.DiaSemana == (DiaSemana)((int)agora.DayOfWeek)
                && h.HoraInicio <= horaAgora.AddMinutes(30)
                && h.HoraFim >= horaAgora.AddMinutes(-30))
            .FirstOrDefaultAsync(ct);

        if (horario is null)
            return BaseResponse<PresencaDto>.Falha("Nenhuma aula ativa no momento para este check-in.");

        return await RegistrarAsync(new RegistrarPresencaRequest
        {
            AlunoId = alunoId.Value,
            HorarioId = horario.Id,
            Data = hoje,
            MetodoCheckin = (int)MetodoCheckin.QrCode
        }, ct);
    }

    public async Task<BaseResponse<IEnumerable<PresencaDto>>> GetHistoricoAlunoAsync(
        Guid alunoId, DateOnly de, DateOnly ate, CancellationToken ct = default)
    {
        var presencas = await _db.Presencas
            .Include(p => p.Aluno)
            .Include(p => p.Horario).ThenInclude(h => h.Turma)
            .Where(p => p.AlunoId == alunoId && p.Data >= de && p.Data <= ate)
            .OrderByDescending(p => p.Data).ThenBy(p => p.HoraCheckin)
            .ToListAsync(ct);

        return BaseResponse<IEnumerable<PresencaDto>>.Ok(presencas.Select(MapearDto));
    }

    public async Task<BaseResponse<IEnumerable<PresencaDto>>> GetPresencasAulaAsync(
        Guid horarioId, DateOnly data, CancellationToken ct = default)
    {
        var presencas = await _db.Presencas
            .Include(p => p.Aluno)
            .Include(p => p.Horario).ThenInclude(h => h.Turma)
            .Where(p => p.HorarioId == horarioId && p.Data == data)
            .OrderBy(p => p.Aluno.Nome)
            .ToListAsync(ct);

        return BaseResponse<IEnumerable<PresencaDto>>.Ok(presencas.Select(MapearDto));
    }

    public async Task<BaseResponse<PresencaRelatorioDto>> GetRelatorioFrequenciaAsync(
        Guid turmaId, DateOnly de, DateOnly ate, CancellationToken ct = default)
    {
        var horarioIds = await _db.Horarios
            .Where(h => h.TurmaId == turmaId)
            .Select(h => h.Id)
            .ToListAsync(ct);

        var matriculas = await _db.Matriculas
            .Include(m => m.Aluno)
            .Where(m => m.TurmaId == turmaId && m.Ativo)
            .ToListAsync(ct);

        var presencas = await _db.Presencas
            .Where(p => horarioIds.Contains(p.HorarioId) && p.Data >= de && p.Data <= ate)
            .ToListAsync(ct);

        var totalAulas = horarioIds.Count * (int)Math.Round((ate.DayNumber - de.DayNumber + 1) / 7.0);

        var alunosFreq = matriculas.Select(m =>
        {
            var presAluno = presencas.Count(p => p.AlunoId == m.AlunoId);
            var faltas = Math.Max(0, totalAulas - presAluno);
            return new AlunoFrequenciaDto
            {
                AlunoId = m.AlunoId,
                NomeAluno = m.Aluno?.Nome ?? string.Empty,
                Presencas = presAluno,
                Faltas = faltas,
                Percentual = totalAulas > 0 ? Math.Round((double)presAluno / totalAulas * 100, 1) : 0
            };
        }).OrderBy(a => a.NomeAluno).ToList();

        var media = alunosFreq.Count > 0 ? alunosFreq.Average(a => a.Percentual) : 0;

        return BaseResponse<PresencaRelatorioDto>.Ok(new PresencaRelatorioDto
        {
            TotalAulas = totalAulas,
            MediaFrequencia = Math.Round(media, 1),
            Alunos = alunosFreq
        });
    }

    public async Task<BaseResponse<QrTokenResponse>> GerarTokenQrAlunoAsync(Guid alunoId, CancellationToken ct = default)
    {
        var aluno = await _db.Usuarios.FirstOrDefaultAsync(u => u.Id == alunoId && u.Ativo, ct);
        if (aluno is null)
            return BaseResponse<QrTokenResponse>.Falha("Aluno não encontrado.");

        var token = _qrToken.GerarToken(alunoId, _tenant.AcademiaId);
        return BaseResponse<QrTokenResponse>.Ok(token);
    }

    public async Task<BaseResponse<AlunoQrInfoDto>> GetAlunoQrInfoAsync(string tokenQr, CancellationToken ct = default)
    {
        var alunoId = _qrToken.ValidarToken(tokenQr);
        if (alunoId is null)
            return BaseResponse<AlunoQrInfoDto>.Falha("Token QR inválido ou expirado.");

        var aluno = await _db.Usuarios
            .FirstOrDefaultAsync(u => u.Id == alunoId.Value && u.Ativo, ct);

        if (aluno is null)
            return BaseResponse<AlunoQrInfoDto>.Falha("Aluno não encontrado.");

        var faixa = await _db.Graduacoes
            .Include(g => g.Faixa)
            .Where(g => g.AlunoId == alunoId.Value)
            .OrderByDescending(g => g.Faixa.Ordem).ThenByDescending(g => g.Grau)
            .Select(g => new { g.Faixa.Nome, g.Faixa.Cor })
            .FirstOrDefaultAsync(ct);

        var turmas = await _db.Matriculas
            .Include(m => m.Turma)
            .Where(m => m.AlunoId == alunoId.Value && m.Ativo)
            .Select(m => m.Turma.Nome)
            .ToListAsync(ct);

        var inicioMes = new DateOnly(DateTimeHelper.Hoje().Year, DateTimeHelper.Hoje().Month, 1);
        var totalMes = await _db.Presencas
            .CountAsync(p => p.AlunoId == alunoId.Value && p.Data >= inicioMes, ct);

        var agora = DateTimeHelper.Agora();
        var horaAgora = TimeOnly.FromDateTime(agora);
        var horarioAtivo = await _db.Horarios
            .Where(h => h.DiaSemana == (DiaSemana)((int)agora.DayOfWeek)
                && h.HoraInicio <= horaAgora.AddMinutes(30)
                && h.HoraFim >= horaAgora.AddMinutes(-30))
            .FirstOrDefaultAsync(ct);

        return BaseResponse<AlunoQrInfoDto>.Ok(new AlunoQrInfoDto
        {
            AlunoId = aluno.Id,
            Nome = aluno.Nome,
            FaixaNome = faixa?.Nome ?? "Sem faixa",
            FaixaCor = faixa?.Cor ?? "#888888",
            Turmas = turmas,
            TotalPresencasMes = totalMes,
            TemAulaAgora = horarioAtivo is not null,
            HorarioAtivoId = horarioAtivo?.Id,
        });
    }

    public async Task<BaseResponse<PresencaDto>> CheckinSelfAsync(Guid alunoId, CancellationToken ct = default)
    {
        var agora = DateTimeHelper.Agora();
        var horaAgora = TimeOnly.FromDateTime(agora);
        var hoje = DateOnly.FromDateTime(agora);

        var horario = await _db.Horarios
            .Include(h => h.Turma)
            .Where(h => h.DiaSemana == (DiaSemana)((int)agora.DayOfWeek)
                && h.HoraInicio <= horaAgora.AddMinutes(30)
                && h.HoraFim >= horaAgora.AddMinutes(-30))
            .FirstOrDefaultAsync(ct);

        if (horario is null)
            return BaseResponse<PresencaDto>.Falha("Nenhuma aula ativa no momento para check-in.");

        return await RegistrarAsync(new RegistrarPresencaRequest
        {
            AlunoId = alunoId,
            HorarioId = horario.Id,
            Data = hoje,
            MetodoCheckin = (int)MetodoCheckin.QrCode
        }, ct);
    }

    public async Task<BaseResponse<PresencaDto>> CheckinTurmaAsync(Guid alunoId, Guid turmaId, CancellationToken ct = default)
    {
        var agora = DateTimeHelper.Agora();
        var horaAgora = TimeOnly.FromDateTime(agora);
        var hoje = DateOnly.FromDateTime(agora);

        var horario = await _db.Horarios
            .Include(h => h.Turma)
            .Where(h => h.TurmaId == turmaId
                && h.DiaSemana == (DiaSemana)((int)agora.DayOfWeek)
                && h.HoraInicio <= horaAgora.AddMinutes(30)
                && h.HoraFim >= horaAgora.AddMinutes(-30))
            .FirstOrDefaultAsync(ct);

        if (horario is null)
            return BaseResponse<PresencaDto>.Falha("Nenhuma aula ativa no momento para esta turma.");

        return await RegistrarAsync(new RegistrarPresencaRequest
        {
            AlunoId = alunoId,
            HorarioId = horario.Id,
            Data = hoje,
            MetodoCheckin = (int)MetodoCheckin.QrCode
        }, ct);
    }

    public async Task<BaseResponse<string>> GetQrCodeTurmaAsync(Guid turmaId, CancellationToken ct = default)
    {
        var turma = await _db.Turmas.FirstOrDefaultAsync(t => t.Id == turmaId, ct);
        if (turma is null)
            return BaseResponse<string>.Falha("Turma não encontrada.");
        return BaseResponse<string>.Ok(turmaId.ToString());
    }

    private static PresencaDto MapearDto(Presenca p) => new()
    {
        Id = p.Id,
        AlunoId = p.AlunoId,
        NomeAluno = p.Aluno?.Nome ?? string.Empty,
        HorarioId = p.HorarioId,
        NomeTurma = p.Horario?.Turma?.Nome ?? string.Empty,
        Data = p.Data,
        HoraCheckin = p.HoraCheckin,
        MetodoCheckin = p.MetodoCheckin.ToString(),
        Confirmado = p.Confirmado,
        ObservacoesProfessor = p.ObservacoesProfessor
    };
}
