using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.AtestadoMedico;
using AcademiaFight.Application.Interfaces;
using AcademiaFight.Domain.Entities;
using AcademiaFight.Domain.Enums;
using AcademiaFight.Domain.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace AcademiaFight.Application.Services;

public class AtestadoService : IAtestadoService
{
    private readonly IAppDbContext _db;
    private readonly ITenantContext _tenant;

    public AtestadoService(IAppDbContext db, ITenantContext tenant)
    {
        _db = db;
        _tenant = tenant;
    }

    public async Task<BaseResponse<AtestadoMedicoDto>> UploadAlunoAsync(
        UploadAtestadoRequest request,
        Guid alunoId,
        CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(request.ArquivoBase64))
            return BaseResponse<AtestadoMedicoDto>.Falha("Arquivo obrigatório.");

        if (request.ArquivoBase64.Length > 7_000_000)
            return BaseResponse<AtestadoMedicoDto>.Falha("Arquivo muito grande. Máximo 5 MB.");

        var existente = await _db.AtestadosMedicos
            .FirstOrDefaultAsync(a => a.AlunoId == alunoId, ct);

        if (existente is not null)
        {
            existente.ArquivoBase64 = request.ArquivoBase64;
            existente.ArquivoMimeType = request.ArquivoMimeType;
            existente.ArquivoNome = request.ArquivoNome;
            existente.Status = StatusAtestado.Pendente;
            existente.MotivoRejeicao = null;
            existente.DataUpload = DateTime.UtcNow;
            existente.DataValidade = DateTime.UtcNow.AddYears(1);
            existente.AnexadoPorAcademia = false;
            existente.AnexadoPorId = null;
            existente.AlertaVencimentoEnviado = false;
        }
        else
        {
            existente = new AtestadoMedico
            {
                AcademiaId = _tenant.AcademiaId,
                AlunoId = alunoId,
                ArquivoBase64 = request.ArquivoBase64,
                ArquivoMimeType = request.ArquivoMimeType,
                ArquivoNome = request.ArquivoNome,
                Status = StatusAtestado.Pendente,
                DataUpload = DateTime.UtcNow,
                DataValidade = DateTime.UtcNow.AddYears(1),
            };
            await _db.AtestadosMedicos.AddAsync(existente, ct);
        }

        await _db.SaveChangesAsync(ct);
        return BaseResponse<AtestadoMedicoDto>.Ok(MapDto(existente, null));
    }

    public async Task<BaseResponse<AtestadoMedicoDto>> UploadAcademiaAsync(
        UploadAtestadoPorAcademiaRequest request,
        Guid responsavelId,
        CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(request.ArquivoBase64))
            return BaseResponse<AtestadoMedicoDto>.Falha("Arquivo obrigatório.");

        if (request.ArquivoBase64.Length > 7_000_000)
            return BaseResponse<AtestadoMedicoDto>.Falha("Arquivo muito grande. Máximo 5 MB.");

        var aluno = await _db.Usuarios
            .FirstOrDefaultAsync(u => u.Id == request.AlunoId && u.Perfil == PerfilUsuario.Aluno, ct);

        if (aluno is null)
            return BaseResponse<AtestadoMedicoDto>.Falha("Aluno não encontrado.");

        var existente = await _db.AtestadosMedicos
            .FirstOrDefaultAsync(a => a.AlunoId == request.AlunoId, ct);

        if (existente is not null)
        {
            existente.ArquivoBase64 = request.ArquivoBase64;
            existente.ArquivoMimeType = request.ArquivoMimeType;
            existente.ArquivoNome = request.ArquivoNome;
            existente.Status = StatusAtestado.Aprovado;
            existente.MotivoRejeicao = null;
            existente.DataUpload = DateTime.UtcNow;
            existente.DataValidade = DateTime.UtcNow.AddYears(1);
            existente.AnexadoPorAcademia = true;
            existente.AnexadoPorId = responsavelId;
            existente.AlertaVencimentoEnviado = false;
        }
        else
        {
            existente = new AtestadoMedico
            {
                AcademiaId = _tenant.AcademiaId,
                AlunoId = request.AlunoId,
                ArquivoBase64 = request.ArquivoBase64,
                ArquivoMimeType = request.ArquivoMimeType,
                ArquivoNome = request.ArquivoNome,
                Status = StatusAtestado.Aprovado,
                DataUpload = DateTime.UtcNow,
                DataValidade = DateTime.UtcNow.AddYears(1),
                AnexadoPorAcademia = true,
                AnexadoPorId = responsavelId,
            };
            await _db.AtestadosMedicos.AddAsync(existente, ct);
        }

        await _db.SaveChangesAsync(ct);
        return BaseResponse<AtestadoMedicoDto>.Ok(MapDto(existente, aluno.Nome));
    }

    public async Task<BaseResponse<AtestadoMedicoComArquivoDto?>> ObterMeuAtestadoAsync(
        Guid alunoId,
        CancellationToken ct = default)
    {
        var atestado = await _db.AtestadosMedicos
            .Include(a => a.Aluno)
            .FirstOrDefaultAsync(a => a.AlunoId == alunoId, ct);

        if (atestado is null)
            return BaseResponse<AtestadoMedicoComArquivoDto?>.Ok(null);

        return BaseResponse<AtestadoMedicoComArquivoDto?>.Ok(MapDtoComArquivo(atestado));
    }

    public async Task<BaseResponse<AtestadoMedicoComArquivoDto?>> ObterAtestadoDoAlunoAsync(
        Guid alunoId,
        CancellationToken ct = default)
    {
        var atestado = await _db.AtestadosMedicos
            .Include(a => a.Aluno)
            .FirstOrDefaultAsync(a => a.AlunoId == alunoId, ct);

        if (atestado is null)
            return BaseResponse<AtestadoMedicoComArquivoDto?>.Ok(null);

        return BaseResponse<AtestadoMedicoComArquivoDto?>.Ok(MapDtoComArquivo(atestado));
    }

    public async Task<BaseResponse<IEnumerable<AtestadoMedicoDto>>> ListarStatusAtestadosAsync(
        CancellationToken ct = default)
    {
        var atestados = await _db.AtestadosMedicos
            .Include(a => a.Aluno)
            .OrderByDescending(a => a.CriadoEm)
            .ToListAsync(ct);

        return BaseResponse<IEnumerable<AtestadoMedicoDto>>.Ok(
            atestados.Select(a => MapDto(a, a.Aluno?.Nome)));
    }

    public async Task<BaseResponse> AvaliarAsync(
        Guid id,
        AvaliarAtestadoRequest request,
        CancellationToken ct = default)
    {
        var atestado = await _db.AtestadosMedicos
            .FirstOrDefaultAsync(a => a.Id == id, ct);

        if (atestado is null)
            return BaseResponse.Falha("Atestado não encontrado.");

        if (request.Aprovado)
        {
            atestado.Status = StatusAtestado.Aprovado;
            atestado.MotivoRejeicao = null;
        }
        else
        {
            if (string.IsNullOrWhiteSpace(request.MotivoRejeicao))
                return BaseResponse.Falha("Informe o motivo da rejeição.");

            atestado.Status = StatusAtestado.Rejeitado;
            atestado.MotivoRejeicao = request.MotivoRejeicao;
        }

        // Notificação interna ao aluno
        await _db.Notificacoes.AddAsync(new Notificacao
        {
            AcademiaId = _tenant.AcademiaId,
            Titulo = request.Aprovado ? "Atestado aprovado ✅" : "Atestado rejeitado ❌",
            Mensagem = request.Aprovado
                ? "Seu atestado médico foi aprovado pela academia."
                : $"Seu atestado médico foi rejeitado. Motivo: {request.MotivoRejeicao}",
            Tipo = TipoNotificacao.Info,
            ChaveDedup = $"atestado-avaliado-{id}",
        }, ct);

        await _db.SaveChangesAsync(ct);
        return BaseResponse.Ok();
    }

    public async Task<BaseResponse> EnviarLembreteAsync(Guid alunoId, CancellationToken ct = default)
    {
        var aluno = await _db.Usuarios
            .FirstOrDefaultAsync(u => u.Id == alunoId && u.Perfil == PerfilUsuario.Aluno, ct);

        if (aluno is null)
            return BaseResponse.Falha("Aluno não encontrado.");

        var atestado = await _db.AtestadosMedicos
            .FirstOrDefaultAsync(a => a.AlunoId == alunoId, ct);

        var msg = atestado is null
            ? "A academia solicita que você envie seu atestado médico pelo app."
            : atestado.Status == StatusAtestado.Rejeitado
                ? "Seu atestado foi rejeitado. Por favor, envie um novo atestado válido pelo app."
                : "Seu atestado médico está próximo do vencimento. Envie um novo pelo app.";

        await _db.Notificacoes.AddAsync(new Notificacao
        {
            AcademiaId = _tenant.AcademiaId,
            Titulo = "Atenção: Atestado Médico",
            Mensagem = msg,
            Tipo = TipoNotificacao.Info,
            ChaveDedup = $"lembrete-atestado-{alunoId}-{DateTime.UtcNow:yyyy-MM-dd}",
        }, ct);

        await _db.SaveChangesAsync(ct);
        return BaseResponse.Ok("Lembrete enviado.");
    }

    public async Task VerificarVencimentosAsync(CancellationToken ct = default)
    {
        var agora = DateTime.UtcNow;
        var em7Dias = agora.AddDays(7);

        // Marcar como Expirado
        var expirados = await _db.AtestadosMedicos
            .IgnoreQueryFilters()
            .Where(a => a.Status == StatusAtestado.Aprovado && a.DataValidade < agora)
            .ToListAsync(ct);

        foreach (var a in expirados)
            a.Status = StatusAtestado.Expirado;

        // Alerta de vencimento próximo (dentro de 7 dias)
        var vencendoEmBreve = await _db.AtestadosMedicos
            .IgnoreQueryFilters()
            .Where(a => a.Status == StatusAtestado.Aprovado
                     && a.DataValidade <= em7Dias
                     && a.DataValidade >= agora
                     && !a.AlertaVencimentoEnviado)
            .Include(a => a.Aluno)
            .ToListAsync(ct);

        foreach (var a in vencendoEmBreve)
        {
            a.AlertaVencimentoEnviado = true;

            await _db.Notificacoes.AddAsync(new Notificacao
            {
                AcademiaId = a.AcademiaId,
                Titulo = "Atestado próximo do vencimento ⚠️",
                Mensagem = $"O atestado de {a.Aluno?.Nome ?? "um aluno"} vence em {(a.DataValidade - agora).Days + 1} dia(s).",
                Tipo = TipoNotificacao.Info,
                ChaveDedup = $"vencimento-atestado-{a.Id}",
            }, ct);
        }

        if (expirados.Count > 0 || vencendoEmBreve.Count > 0)
            await _db.SaveChangesAsync(ct);
    }

    private static AtestadoMedicoDto MapDto(AtestadoMedico a, string? nomeAluno) => new()
    {
        Id = a.Id,
        AlunoId = a.AlunoId,
        AlunoNome = nomeAluno ?? a.Aluno?.Nome ?? string.Empty,
        Status = a.Status,
        MotivoRejeicao = a.MotivoRejeicao,
        DataUpload = a.DataUpload,
        DataValidade = a.DataValidade,
        AnexadoPorAcademia = a.AnexadoPorAcademia,
        ArquivoMimeType = a.ArquivoMimeType,
        ArquivoNome = a.ArquivoNome,
        CriadoEm = a.CriadoEm,
    };

    private static AtestadoMedicoComArquivoDto MapDtoComArquivo(AtestadoMedico a) => new()
    {
        Id = a.Id,
        AlunoId = a.AlunoId,
        AlunoNome = a.Aluno?.Nome ?? string.Empty,
        Status = a.Status,
        MotivoRejeicao = a.MotivoRejeicao,
        DataUpload = a.DataUpload,
        DataValidade = a.DataValidade,
        AnexadoPorAcademia = a.AnexadoPorAcademia,
        ArquivoMimeType = a.ArquivoMimeType,
        ArquivoNome = a.ArquivoNome,
        ArquivoBase64 = a.ArquivoBase64,
        CriadoEm = a.CriadoEm,
    };
}
