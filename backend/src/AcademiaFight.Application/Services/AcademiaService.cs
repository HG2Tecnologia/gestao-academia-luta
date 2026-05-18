using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Academia;
using AcademiaFight.Application.Interfaces;
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

            return BaseResponse<AcademiaDto>.Ok(new AcademiaDto
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
                TemplateContrato = academia.TemplateContrato
            });
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

            return BaseResponse<AcademiaDto>.Ok(new AcademiaDto
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
                TemplateContrato = academia.TemplateContrato
            }, "Academia atualizada com sucesso.");
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
}
