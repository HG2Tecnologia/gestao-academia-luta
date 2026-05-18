using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Plano;
using AcademiaFight.Application.Interfaces;
using AcademiaFight.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace AcademiaFight.Application.Services;

public class PlanoService : IPlanoService
{
    private readonly IAppDbContext _db;

    public PlanoService(IAppDbContext db)
    {
        _db = db;
    }

    public async Task<BaseResponse<IEnumerable<PlanoDto>>> ListarAsync(CancellationToken ct = default)
    {
        var planos = await _db.Planos
            .OrderBy(p => p.Nome)
            .ToListAsync(ct);

        var alunosPorPlano = await _db.Usuarios
            .Where(u => u.PlanoId != null)
            .GroupBy(u => u.PlanoId!.Value)
            .Select(g => new { PlanoId = g.Key, Total = g.Count() })
            .ToListAsync(ct);

        var contagem = alunosPorPlano.ToDictionary(x => x.PlanoId, x => x.Total);

        return BaseResponse<IEnumerable<PlanoDto>>.Ok(planos.Select(p => MapDto(p, contagem.GetValueOrDefault(p.Id))));
    }

    public async Task<BaseResponse<PlanoDto>> ObterPorIdAsync(Guid id, CancellationToken ct = default)
    {
        var plano = await _db.Planos.FirstOrDefaultAsync(p => p.Id == id, ct);
        if (plano is null) return BaseResponse<PlanoDto>.Falha("Plano não encontrado.");
        return BaseResponse<PlanoDto>.Ok(MapDto(plano, 0));
    }

    public async Task<BaseResponse<PlanoDto>> CriarAsync(CreatePlanoDto dto, CancellationToken ct = default)
    {
        var plano = new Plano
        {
            Nome = dto.Nome,
            Descricao = dto.Descricao,
            ValorMensal = dto.ValorMensal,
            TaxaMatricula = dto.TaxaMatricula,
            Ativo = true,
        };

        _db.Planos.Add(plano);
        await _db.SaveChangesAsync(ct);
        return BaseResponse<PlanoDto>.Ok(MapDto(plano, 0));
    }

    public async Task<BaseResponse<PlanoDto>> AtualizarAsync(Guid id, UpdatePlanoDto dto, CancellationToken ct = default)
    {
        var plano = await _db.Planos.FirstOrDefaultAsync(p => p.Id == id, ct);
        if (plano is null) return BaseResponse<PlanoDto>.Falha("Plano não encontrado.");

        plano.Nome = dto.Nome;
        plano.Descricao = dto.Descricao;
        plano.ValorMensal = dto.ValorMensal;
        plano.TaxaMatricula = dto.TaxaMatricula;
        plano.Ativo = dto.Ativo;

        await _db.SaveChangesAsync(ct);
        return BaseResponse<PlanoDto>.Ok(MapDto(plano, 0));
    }

    public async Task<BaseResponse<bool>> DeletarAsync(Guid id, CancellationToken ct = default)
    {
        var plano = await _db.Planos.FirstOrDefaultAsync(p => p.Id == id, ct);
        if (plano is null) return BaseResponse<bool>.Falha("Plano não encontrado.");

        var temAlunos = await _db.Usuarios.AnyAsync(u => u.PlanoId == id, ct);
        if (temAlunos) return BaseResponse<bool>.Falha("Não é possível excluir um plano com alunos vinculados.");

        _db.Planos.Remove(plano);
        await _db.SaveChangesAsync(ct);
        return BaseResponse<bool>.Ok(true);
    }

    private static PlanoDto MapDto(Plano p, int totalAlunos) => new()
    {
        Id = p.Id,
        Nome = p.Nome,
        Descricao = p.Descricao,
        ValorMensal = p.ValorMensal,
        TaxaMatricula = p.TaxaMatricula,
        Ativo = p.Ativo,
        TotalAlunos = totalAlunos,
    };
}
