using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Contrato;
using AcademiaFight.Application.Interfaces;
using AcademiaFight.Domain.Entities;
using AcademiaFight.Domain.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace AcademiaFight.Application.Services;

public class ModeloContratoService : IModeloContratoService
{
    private readonly IAppDbContext _db;
    private readonly ITenantContext _tenant;

    public ModeloContratoService(IAppDbContext db, ITenantContext tenant)
    {
        _db = db;
        _tenant = tenant;
    }

    public async Task<BaseResponse<IEnumerable<ModeloContratoDto>>> ListarAsync(CancellationToken ct = default)
    {
        var lista = await _db.ModelosContrato
            .OrderBy(m => m.Nome)
            .ToListAsync(ct);
        return BaseResponse<IEnumerable<ModeloContratoDto>>.Ok(lista.Select(Mapear));
    }

    public async Task<BaseResponse<ModeloContratoDto>> ObterAsync(Guid id, CancellationToken ct = default)
    {
        var modelo = await _db.ModelosContrato.FirstOrDefaultAsync(m => m.Id == id, ct);
        if (modelo is null)
            return BaseResponse<ModeloContratoDto>.Falha("Modelo não encontrado.");
        return BaseResponse<ModeloContratoDto>.Ok(Mapear(modelo));
    }

    public async Task<BaseResponse<ModeloContratoDto>> CriarAsync(CreateModeloContratoRequest request, CancellationToken ct = default)
    {
        var modelo = new ModeloContrato
        {
            AcademiaId = _tenant.AcademiaId,
            Nome = request.Nome.Trim(),
            ConteudoHtml = request.ConteudoHtml,
        };

        await _db.ModelosContrato.AddAsync(modelo, ct);
        await _db.SaveChangesAsync(ct);

        return BaseResponse<ModeloContratoDto>.Ok(Mapear(modelo), "Modelo criado com sucesso.");
    }

    public async Task<BaseResponse<ModeloContratoDto>> AtualizarAsync(Guid id, UpdateModeloContratoRequest request, CancellationToken ct = default)
    {
        var modelo = await _db.ModelosContrato.FirstOrDefaultAsync(m => m.Id == id, ct);
        if (modelo is null)
            return BaseResponse<ModeloContratoDto>.Falha("Modelo não encontrado.");

        modelo.Nome = request.Nome.Trim();
        modelo.ConteudoHtml = request.ConteudoHtml;

        await _db.SaveChangesAsync(ct);

        return BaseResponse<ModeloContratoDto>.Ok(Mapear(modelo), "Modelo atualizado com sucesso.");
    }

    public async Task<BaseResponse> ExcluirAsync(Guid id, CancellationToken ct = default)
    {
        var modelo = await _db.ModelosContrato.FirstOrDefaultAsync(m => m.Id == id, ct);
        if (modelo is null)
            return BaseResponse.Falha("Modelo não encontrado.");

        _db.ModelosContrato.Remove(modelo);
        await _db.SaveChangesAsync(ct);

        return BaseResponse.Ok("Modelo excluído com sucesso.");
    }

    private static ModeloContratoDto Mapear(ModeloContrato m) => new()
    {
        Id = m.Id,
        Nome = m.Nome,
        ConteudoHtml = m.ConteudoHtml,
        CriadoEm = m.CriadoEm,
    };
}
