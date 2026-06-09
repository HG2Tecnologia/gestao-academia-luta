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
    private readonly ICatracaAgentNotifier _agentNotifier;

    public CatracaService(
        IAppDbContext db,
        IXpService xp,
        ILogger<CatracaService> logger,
        ICatracaAgentNotifier agentNotifier)
    {
        _db = db;
        _xp = xp;
        _logger = logger;
        _agentNotifier = agentNotifier;
    }

    // ── Validar acesso ────────────────────────────────────────────────────────

    public async Task<BaseResponse<CatracaValidacaoDto>> ValidarAcessoAsync(
        string identificador, Guid academiaId, CancellationToken ct = default)
    {
        var id = identificador.Trim();

        var query = _db.Usuarios
            .Where(u => u.AcademiaId == academiaId && u.Perfil == PerfilUsuario.Aluno);

        List<Usuario> candidatos;

        // 1. ID numérico do dispositivo (digital ou teclado Toletus → envia o CatracaDeviceUserId)
        if (int.TryParse(id, out var deviceId))
        {
            candidatos = await query.Where(u => u.CatracaDeviceUserId == deviceId).ToListAsync(ct);
        }
        // 2. E-mail exato
        else if (id.Contains('@'))
        {
            candidatos = await query.Where(u => u.Email == id).ToListAsync(ct);
        }
        // 3. Nome (substring, case-insensitive — fallback)
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
            return BaseResponse<CatracaValidacaoDto>.Ok(
                new CatracaValidacaoDto(false, null, $"Múltiplos alunos: {nomes}. Use o e-mail ou cadastre a digital."));
        }

        var aluno = candidatos[0];

        if (!aluno.Ativo)
        {
            _logger.LogInformation("Catraca: aluno '{Nome}' inativo — acesso negado", aluno.Nome);
            return BaseResponse<CatracaValidacaoDto>.Ok(
                new CatracaValidacaoDto(false, aluno.Nome, "Aluno inativo"));
        }

        _logger.LogInformation("Catraca: acesso liberado para '{Nome}'", aluno.Nome);
        var (presencaRegistrada, turmaNome) = await RegistrarPresencaAutomaticaAsync(aluno.Id, academiaId, ct);

        return BaseResponse<CatracaValidacaoDto>.Ok(
            new CatracaValidacaoDto(true, aluno.Nome, null, presencaRegistrada, turmaNome));
    }

    // ── Abrir manualmente ─────────────────────────────────────────────────────

    public async Task<BaseResponse<CatracaAberturaManuaDto>> AbrirManualmenteAsync(
        Guid academiaId, Guid operadorId, CancellationToken ct = default)
    {
        var operador = await _db.Usuarios
            .FirstOrDefaultAsync(u => u.Id == operadorId && u.AcademiaId == academiaId, ct);

        var nomeOperador = operador?.Nome ?? "Desconhecido";
        var agora = DateTime.UtcNow;

        await _agentNotifier.EnviarAbrirPortaAsync(academiaId, ct);
        _logger.LogInformation("Catraca: comando AbrirPorta enviado por '{Operador}'", nomeOperador);

        return BaseResponse<CatracaAberturaManuaDto>.Ok(
            new CatracaAberturaManuaDto(true, agora, nomeOperador),
            "Comando enviado ao agente local");
    }

    // ── Vínculos aluno ↔ dispositivo ──────────────────────────────────────────

    public async Task<BaseResponse<List<CatracaAlunoVinculoDto>>> ListarVinculosAsync(
        Guid academiaId, CancellationToken ct = default)
    {
        var alunos = await _db.Usuarios
            .Where(u => u.AcademiaId == academiaId && u.Perfil == PerfilUsuario.Aluno && u.Ativo)
            .OrderBy(u => u.Nome)
            .Select(u => new CatracaAlunoVinculoDto(
                u.Id, u.Nome, u.Email, u.CatracaDeviceUserId, u.CatracaDeviceUserId.HasValue))
            .ToListAsync(ct);

        return BaseResponse<List<CatracaAlunoVinculoDto>>.Ok(alunos);
    }

    public async Task<BaseResponse<CatracaAlunoVinculoDto>> VincularAlunoAsync(
        Guid alunoId, Guid academiaId, int? deviceUserId, CancellationToken ct = default)
    {
        var aluno = await _db.Usuarios
            .FirstOrDefaultAsync(u => u.Id == alunoId && u.AcademiaId == academiaId, ct);

        if (aluno == null)
            return BaseResponse<CatracaAlunoVinculoDto>.Falha("Aluno não encontrado");

        // Gerar próximo ID disponível se não foi informado
        if (!deviceUserId.HasValue)
        {
            var maxExistente = await _db.Usuarios
                .Where(u => u.AcademiaId == academiaId && u.CatracaDeviceUserId.HasValue)
                .MaxAsync(u => (int?)u.CatracaDeviceUserId, ct);
            deviceUserId = (maxExistente ?? 0) + 1;
        }
        else
        {
            var conflito = await _db.Usuarios
                .AnyAsync(u => u.AcademiaId == academiaId && u.CatracaDeviceUserId == deviceUserId && u.Id != alunoId, ct);
            if (conflito)
                return BaseResponse<CatracaAlunoVinculoDto>.Falha($"ID {deviceUserId} já está em uso por outro aluno");
        }

        aluno.CatracaDeviceUserId = deviceUserId;
        await _db.SaveChangesAsync(ct);

        // Enviar comando de enrollment ao agente
        await _agentNotifier.EnviarCadastrarUsuarioAsync(academiaId, deviceUserId.Value, ct);
        _logger.LogInformation("Catraca: aluno '{Nome}' vinculado com DeviceUserId={Id}", aluno.Nome, deviceUserId);

        var dto = new CatracaAlunoVinculoDto(aluno.Id, aluno.Nome, aluno.Email, deviceUserId, true);
        return BaseResponse<CatracaAlunoVinculoDto>.Ok(dto,
            $"Aluno vinculado com ID {deviceUserId}. Solicite ao aluno que escaneie a digital no dispositivo.");
    }

    public async Task<BaseResponse<bool>> DesvincularAlunoAsync(
        Guid alunoId, Guid academiaId, CancellationToken ct = default)
    {
        var aluno = await _db.Usuarios
            .FirstOrDefaultAsync(u => u.Id == alunoId && u.AcademiaId == academiaId, ct);

        if (aluno == null)
            return BaseResponse<bool>.Falha("Aluno não encontrado");

        var deviceUserId = aluno.CatracaDeviceUserId;
        aluno.CatracaDeviceUserId = null;
        await _db.SaveChangesAsync(ct);

        if (deviceUserId.HasValue)
            await _agentNotifier.EnviarRemoverUsuarioAsync(academiaId, deviceUserId.Value, ct);

        _logger.LogInformation("Catraca: aluno '{Nome}' desvinculado (DeviceUserId={Id})", aluno.Nome, deviceUserId);
        return BaseResponse<bool>.Ok(true, "Aluno desvinculado da catraca");
    }

    // ── Presença automática ────────────────────────────────────────────────────

    private async Task<(bool registrada, string? turmaNome)> RegistrarPresencaAutomaticaAsync(
        Guid alunoId, Guid academiaId, CancellationToken ct)
    {
        try
        {
            var hoje = DateOnly.FromDateTime(DateTime.UtcNow);
            var agora = TimeOnly.FromDateTime(DateTime.UtcNow);
            var diaSemana = (DiaSemana)(int)DateTime.UtcNow.DayOfWeek;

            var horariosDoDia = await _db.Horarios
                .Include(h => h.Turma)
                .Where(h => h.AcademiaId == academiaId
                         && h.DiaSemana == diaSemana
                         && _db.Matriculas.Any(m => m.AlunoId == alunoId && m.TurmaId == h.TurmaId && m.Ativo))
                .OrderBy(h => h.HoraInicio)
                .ToListAsync(ct);

            if (horariosDoDia.Count == 0)
                return (false, null);

            var horario = horariosDoDia
                .OrderBy(h => Math.Abs((h.HoraInicio - agora).TotalMinutes))
                .First();

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

            return (true, horario.Turma.Nome);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Catraca: erro ao registrar presença automática para aluno {AlunoId}", alunoId);
            return (false, null);
        }
    }
}
