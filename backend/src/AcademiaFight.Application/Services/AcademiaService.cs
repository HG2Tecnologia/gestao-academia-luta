using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Academia;
using AcademiaFight.Application.Interfaces;
using AcademiaFight.Domain.Enums;
using AcademiaFight.Domain.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace AcademiaFight.Application.Services;

public class AcademiaService : IAcademiaService
{
    private readonly IAppDbContext _db;
    private readonly ITenantContext _tenant;
    private readonly ILogger<AcademiaService> _logger;

    public AcademiaService(IAppDbContext db, ITenantContext tenant, ILogger<AcademiaService> logger)
    {
        _db = db;
        _tenant = tenant;
        _logger = logger;
    }

    public async Task<BaseResponse<AcademiaDto>> ObterTenantAtualAsync(CancellationToken ct = default)
    {
        try
        {
            var academia = await _db.Academias
                .FirstOrDefaultAsync(a => a.Id == _tenant.AcademiaId, ct);

            if (academia is null)
                return BaseResponse<AcademiaDto>.Falha("Academia não encontrada.");

            return BaseResponse<AcademiaDto>.Ok(await MapearDtoAsync(academia, ct));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Erro ao obter dados da academia {AcademiaId}", _tenant.AcademiaId);
            throw;
        }
    }

    public async Task<BaseResponse<AcademiaDto>> AtualizarAsync(UpdateAcademiaRequest request, CancellationToken ct = default)
    {
        try
        {
            var academia = await _db.Academias
                .FirstOrDefaultAsync(a => a.Id == _tenant.AcademiaId, ct);

            if (academia is null)
                return BaseResponse<AcademiaDto>.Falha("Academia não encontrada.");

            academia.Nome = request.Nome;
            academia.Email = request.Email.ToLower();
            academia.Telefone = request.Telefone;
            academia.LogoUrl = request.LogoUrl;
            academia.Cnpj = request.Cnpj;

            await _db.SaveChangesAsync(ct);

            _logger.LogInformation("Academia {AcademiaId} atualizada", _tenant.AcademiaId);

            return BaseResponse<AcademiaDto>.Ok(await MapearDtoAsync(academia, ct), "Academia atualizada com sucesso.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Erro ao atualizar academia {AcademiaId}", _tenant.AcademiaId);
            throw;
        }
    }

    public async Task<BaseResponse> AtualizarTemplateContratoAsync(string? template, CancellationToken ct = default)
    {
        var academia = await _db.Academias.FirstOrDefaultAsync(a => a.Id == _tenant.AcademiaId, ct);
        if (academia is null)
            return BaseResponse.Falha("Academia não encontrada.");

        academia.TemplateContrato = template;
        await _db.SaveChangesAsync(ct);

        _logger.LogInformation("Template de contrato atualizado para academia {AcademiaId}", _tenant.AcademiaId);
        return BaseResponse.Ok("Template salvo com sucesso.");
    }

    public async Task<BaseResponse<AcademiaDto>> AtivarPlanoProAsync(DateTime? expiracao, CancellationToken ct = default)
    {
        var academia = await _db.Academias.FirstOrDefaultAsync(a => a.Id == _tenant.AcademiaId, ct);
        if (academia is null)
            return BaseResponse<AcademiaDto>.Falha("Academia não encontrada.");

        academia.PlanoTipo = PlanoAcademia.Pro;
        academia.PlanoExpiracao = expiracao ?? DateTime.UtcNow.AddYears(1);
        await _db.SaveChangesAsync(ct);

        _logger.LogInformation("Plano PRO ativado para academia {AcademiaId} até {Expiracao}", _tenant.AcademiaId, academia.PlanoExpiracao);
        return BaseResponse<AcademiaDto>.Ok(await MapearDtoAsync(academia, ct), "Plano PRO ativado com sucesso.");
    }

    public async Task<BaseResponse<AcademiaDto>> AtivarPlanoIapAsync(
        string productId, string purchaseToken, string platform, CancellationToken ct = default)
    {
        var academia = await _db.Academias.FirstOrDefaultAsync(a => a.Id == _tenant.AcademiaId, ct);
        if (academia is null)
            return BaseResponse<AcademiaDto>.Falha("Academia não encontrada.");

        var expiracao = productId switch
        {
            var id when id.Contains("mensal")     => DateTime.UtcNow.AddMonths(1),
            var id when id.Contains("trimestral") => DateTime.UtcNow.AddMonths(3),
            var id when id.Contains("anual")      => DateTime.UtcNow.AddYears(1),
            _                                     => DateTime.UtcNow.AddMonths(1),
        };

        academia.PlanoTipo = PlanoAcademia.Pro;
        academia.PlanoExpiracao = expiracao;
        await _db.SaveChangesAsync(ct);

        _logger.LogInformation(
            "Plano PRO ativado via IAP ({ProductId}/{Platform}) para academia {AcademiaId} até {Expiracao}",
            productId, platform, _tenant.AcademiaId, expiracao);

        return BaseResponse<AcademiaDto>.Ok(await MapearDtoAsync(academia, ct), "Plano PRO ativado com sucesso.");
    }

    private async Task<AcademiaDto> MapearDtoAsync(Domain.Entities.Academia academia, CancellationToken ct)
    {
        var isGratuito = academia.PlanoTipo == PlanoAcademia.Gratuito;
        var totalAlunos = await _db.Usuarios
            .CountAsync(u => u.AcademiaId == academia.Id && u.Perfil == Domain.Enums.PerfilUsuario.Aluno && u.Ativo, ct);
        var totalTurmas = await _db.Turmas
            .CountAsync(t => t.AcademiaId == academia.Id && t.Ativo, ct);

        return new AcademiaDto
        {
            Id = academia.Id,
            Nome = academia.Nome,
            Subdominio = academia.Subdominio,
            LogoUrl = academia.LogoUrl,
            Email = academia.Email,
            Telefone = academia.Telefone,
            Cnpj = academia.Cnpj,
            Ativo = academia.Ativo,
            CriadoEm = academia.CriadoEm,
            TemplateContrato = academia.TemplateContrato,
            PlanoTipo = academia.PlanoTipo.ToString(),
            PlanoExpiracao = academia.PlanoExpiracao,
            LimiteAlunos = isGratuito ? PlanoLimites.MaxAlunosGratuito : int.MaxValue,
            LimiteTurmas = isGratuito ? PlanoLimites.MaxTurmasGratuito : int.MaxValue,
            TotalAlunos = totalAlunos,
            TotalTurmas = totalTurmas,
        };
    }
}
