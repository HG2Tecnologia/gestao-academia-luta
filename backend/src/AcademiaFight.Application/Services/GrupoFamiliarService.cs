using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.GrupoFamiliar;
using AcademiaFight.Application.Interfaces;
using AcademiaFight.Domain.Entities;
using AcademiaFight.Domain.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace AcademiaFight.Application.Services;

public class GrupoFamiliarService : IGrupoFamiliarService
{
    private readonly IAppDbContext _db;
    private readonly ITenantContext _tenant;

    public GrupoFamiliarService(IAppDbContext db, ITenantContext tenant)
    {
        _db = db;
        _tenant = tenant;
    }

    public async Task<BaseResponse<IEnumerable<GrupoFamiliarDto>>> ListarAsync(CancellationToken ct = default)
    {
        var grupos = await _db.GruposFamiliares
            .Where(g => g.AcademiaId == _tenant.AcademiaId)
            .Include(g => g.Membros)
            .OrderBy(g => g.Nome)
            .ToListAsync(ct);

        return BaseResponse<IEnumerable<GrupoFamiliarDto>>.Ok(grupos.Select(Mapear));
    }

    public async Task<BaseResponse<GrupoFamiliarDto>> CriarAsync(string nome, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(nome))
            return BaseResponse<GrupoFamiliarDto>.Falha("Nome do grupo é obrigatório.");

        var grupo = new GrupoFamiliar
        {
            AcademiaId = _tenant.AcademiaId,
            Nome = nome.Trim(),
        };

        await _db.GruposFamiliares.AddAsync(grupo, ct);
        await _db.SaveChangesAsync(ct);

        var criado = await _db.GruposFamiliares.Include(g => g.Membros).FirstAsync(g => g.Id == grupo.Id, ct);
        return BaseResponse<GrupoFamiliarDto>.Ok(Mapear(criado), "Grupo familiar criado.");
    }

    public async Task<BaseResponse<GrupoFamiliarDto>> RenomearAsync(Guid id, string nome, CancellationToken ct = default)
    {
        var grupo = await _db.GruposFamiliares.Include(g => g.Membros)
            .FirstOrDefaultAsync(g => g.Id == id && g.AcademiaId == _tenant.AcademiaId, ct);
        if (grupo is null) return BaseResponse<GrupoFamiliarDto>.Falha("Grupo não encontrado.");

        grupo.Nome = nome.Trim();
        await _db.SaveChangesAsync(ct);
        return BaseResponse<GrupoFamiliarDto>.Ok(Mapear(grupo));
    }

    public async Task<BaseResponse> ExcluirAsync(Guid id, CancellationToken ct = default)
    {
        var grupo = await _db.GruposFamiliares.Include(g => g.Membros)
            .FirstOrDefaultAsync(g => g.Id == id && g.AcademiaId == _tenant.AcademiaId, ct);
        if (grupo is null) return BaseResponse.Falha("Grupo não encontrado.");

        foreach (var m in grupo.Membros)
            m.GrupoFamiliarId = null;

        _db.GruposFamiliares.Remove(grupo);
        await _db.SaveChangesAsync(ct);
        return BaseResponse.Ok("Grupo excluído.");
    }

    public async Task<BaseResponse<GrupoFamiliarDto>> AdicionarMembroAsync(Guid grupoId, Guid alunoId, CancellationToken ct = default)
    {
        var grupo = await _db.GruposFamiliares.Include(g => g.Membros)
            .FirstOrDefaultAsync(g => g.Id == grupoId && g.AcademiaId == _tenant.AcademiaId, ct);
        if (grupo is null) return BaseResponse<GrupoFamiliarDto>.Falha("Grupo não encontrado.");

        var aluno = await _db.Usuarios.IgnoreQueryFilters()
            .FirstOrDefaultAsync(u => u.Id == alunoId && u.AcademiaId == _tenant.AcademiaId, ct);
        if (aluno is null) return BaseResponse<GrupoFamiliarDto>.Falha("Aluno não encontrado.");

        aluno.GrupoFamiliarId = grupoId;
        await _db.SaveChangesAsync(ct);

        var atualizado = await _db.GruposFamiliares.Include(g => g.Membros)
            .FirstAsync(g => g.Id == grupoId, ct);
        return BaseResponse<GrupoFamiliarDto>.Ok(Mapear(atualizado), "Membro adicionado.");
    }

    public async Task<BaseResponse<GrupoFamiliarDto>> RemoverMembroAsync(Guid grupoId, Guid alunoId, CancellationToken ct = default)
    {
        var aluno = await _db.Usuarios.IgnoreQueryFilters()
            .FirstOrDefaultAsync(u => u.Id == alunoId && u.GrupoFamiliarId == grupoId && u.AcademiaId == _tenant.AcademiaId, ct);
        if (aluno is null) return BaseResponse<GrupoFamiliarDto>.Falha("Membro não encontrado no grupo.");

        aluno.GrupoFamiliarId = null;
        await _db.SaveChangesAsync(ct);

        var atualizado = await _db.GruposFamiliares.Include(g => g.Membros)
            .FirstOrDefaultAsync(g => g.Id == grupoId, ct);
        return atualizado is null
            ? BaseResponse<GrupoFamiliarDto>.Falha("Grupo não encontrado.")
            : BaseResponse<GrupoFamiliarDto>.Ok(Mapear(atualizado), "Membro removido.");
    }

    public async Task<BaseResponse<GrupoFamiliarDto?>> ObterPorAlunoAsync(Guid alunoId, CancellationToken ct = default)
    {
        var aluno = await _db.Usuarios.IgnoreQueryFilters()
            .FirstOrDefaultAsync(u => u.Id == alunoId && u.AcademiaId == _tenant.AcademiaId, ct);
        if (aluno?.GrupoFamiliarId is null)
            return BaseResponse<GrupoFamiliarDto?>.Ok(null);

        var grupo = await _db.GruposFamiliares.Include(g => g.Membros)
            .FirstOrDefaultAsync(g => g.Id == aluno.GrupoFamiliarId, ct);
        return BaseResponse<GrupoFamiliarDto?>.Ok(grupo is null ? null : Mapear(grupo));
    }

    private static GrupoFamiliarDto Mapear(GrupoFamiliar g) => new()
    {
        Id = g.Id,
        Nome = g.Nome,
        CriadoEm = g.CriadoEm,
        Membros = g.Membros.Select(m => new MembroDto
        {
            Id = m.Id,
            Nome = m.Nome,
            Email = m.Email,
            Perfil = m.Perfil.ToString(),
        }).ToList(),
    };
}
