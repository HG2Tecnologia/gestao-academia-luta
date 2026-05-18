using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Catraca;
using AcademiaFight.Application.Interfaces;
using AcademiaFight.Domain.Entities;
using AcademiaFight.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace AcademiaFight.Application.Services;

public class CatracaService : ICatracaService
{
    private readonly IAppDbContext _db;
    private readonly IXpService _xp;
    private readonly ILogger<CatracaService> _logger;

    public CatracaService(IAppDbContext db, IXpService xp, ILogger<CatracaService> logger)
    {
        _db = db;
        _xp = xp;
        _logger = logger;
    }

    public async Task<BaseResponse<CatracaValidacaoDto>> ValidarAcessoAsync(
        string identificador, Guid academiaId, CancellationToken ct = default)
    {
        var id = identificador.Trim();

        // Busca por e-mail (exato) ou por nome (contém, case-insensitive)
        var query = _db.Usuarios
            .Where(u => u.AcademiaId == academiaId && u.Perfil == PerfilUsuario.Aluno);

        List<Usuario> candidatos;
        if (id.Contains('@'))
        {
            candidatos = await query.Where(u => u.Email == id).ToListAsync(ct);
        }
        else
        {
            var idLower = id.ToLower();
            candidatos = await query
                .Where(u => u.Nome.ToLower().Contains(idLower))
                .Take(5)
                .ToListAsync(ct);
        }

        if (candidatos.Count == 0)
        {
            _logger.LogWarning("Catraca: nenhum aluno encontrado para '{Id}' na academia {AcademiaId}", id, academiaId);
            return BaseResponse<CatracaValidacaoDto>.Ok(
                new CatracaValidacaoDto(false, null, "Aluno não encontrado"));
        }

        if (candidatos.Count > 1)
        {
            var nomes = string.Join(", ", candidatos.Select(c => c.Nome));
            _logger.LogInformation("Catraca: múltiplos alunos encontrados para '{Id}': {Nomes}", id, nomes);
            return BaseResponse<CatracaValidacaoDto>.Ok(
                new CatracaValidacaoDto(false, null, $"Múltiplos alunos encontrados: {nomes}. Use o e-mail para identificar."));
        }

        var aluno = candidatos[0];

        if (!aluno.Ativo)
        {
            _logger.LogInformation("Catraca: aluno '{Nome}' está inativo — acesso negado", aluno.Nome);
            return BaseResponse<CatracaValidacaoDto>.Ok(
                new CatracaValidacaoDto(false, aluno.Nome, "Aluno inativo"));
        }

        _logger.LogInformation("Catraca: acesso liberado para '{Nome}'", aluno.Nome);

        // Registra presença automaticamente no horário mais próximo do dia atual
        var (presencaRegistrada, turmaNome) = await RegistrarPresencaAutomaticaAsync(aluno.Id, academiaId, ct);

        return BaseResponse<CatracaValidacaoDto>.Ok(
            new CatracaValidacaoDto(true, aluno.Nome, null, presencaRegistrada, turmaNome));
    }

    private async Task<(bool registrada, string? turmaNome)> RegistrarPresencaAutomaticaAsync(
        Guid alunoId, Guid academiaId, CancellationToken ct)
    {
        try
        {
            var hoje = DateOnly.FromDateTime(DateTime.UtcNow);
            var agora = TimeOnly.FromDateTime(DateTime.UtcNow);
            var diaSemana = (DiaSemana)(int)DateTime.UtcNow.DayOfWeek;

            // Busca horários de hoje onde o aluno está matriculado
            var horariosDoDia = await _db.Horarios
                .Include(h => h.Turma)
                .Where(h => h.AcademiaId == academiaId
                         && h.DiaSemana == diaSemana
                         && _db.Matriculas.Any(m => m.AlunoId == alunoId && m.TurmaId == h.TurmaId && m.Ativo))
                .OrderBy(h => h.HoraInicio)
                .ToListAsync(ct);

            if (horariosDoDia.Count == 0)
                return (false, null);

            // Pega o horário mais próximo (em andamento ou o próximo a começar)
            var horario = horariosDoDia
                .OrderBy(h => Math.Abs((h.HoraInicio - agora).TotalMinutes))
                .First();

            // Evita presença duplicada
            var jaRegistrado = await _db.Presencas
                .AnyAsync(p => p.AlunoId == alunoId && p.HorarioId == horario.Id && p.Data == hoje, ct);

            if (jaRegistrado)
                return (false, horario.Turma.Nome);

            var presenca = new Presenca
            {
                AcademiaId = academiaId,
                AlunoId = alunoId,
                HorarioId = horario.Id,
                Data = hoje,
                HoraCheckin = agora,
            };

            await _db.Presencas.AddAsync(presenca, ct);
            await _db.SaveChangesAsync(ct);

            await _xp.AdicionarXpAsync(alunoId, TipoEventoXp.Presenca, 10, presenca.Id, ct);

            _logger.LogInformation("Catraca: presença auto-registrada para aluno {AlunoId} na turma '{Turma}'", alunoId, horario.Turma.Nome);
            return (true, horario.Turma.Nome);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Catraca: erro ao registrar presença automática para aluno {AlunoId}", alunoId);
            return (false, null);
        }
    }

    public async Task<BaseResponse<CatracaAberturaManuaDto>> AbrirManualmenteAsync(
        Guid academiaId, Guid operadorId, CancellationToken ct = default)
    {
        var operador = await _db.Usuarios
            .FirstOrDefaultAsync(u => u.Id == operadorId && u.AcademiaId == academiaId, ct);

        var nomeOperador = operador?.Nome ?? "Desconhecido";
        var agora = DateTime.UtcNow;

        _logger.LogInformation("Catraca: abertura manual por '{Operador}' às {Hora} na academia {AcademiaId}",
            nomeOperador, agora, academiaId);

        // TODO: quando a catraca estiver conectada, enviar comando HTTP/TCP aqui.
        // Exemplo para catraca Control iD:
        //   await _httpClient.PostAsync("http://<ip-catraca>/access/open", ...);

        return BaseResponse<CatracaAberturaManuaDto>.Ok(
            new CatracaAberturaManuaDto(true, agora, nomeOperador),
            "Catraca liberada");
    }
}
