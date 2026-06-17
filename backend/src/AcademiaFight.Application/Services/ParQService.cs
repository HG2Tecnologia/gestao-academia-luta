using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.ParQ;
using AcademiaFight.Application.Interfaces;
using AcademiaFight.Domain.Entities;
using AcademiaFight.Domain.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace AcademiaFight.Application.Services;

public class ParQService
{
    private readonly IAppDbContext _db;
    private readonly ITenantContext _tenant;

    public ParQService(IAppDbContext db, ITenantContext tenant)
    {
        _db = db;
        _tenant = tenant;
    }

    public async Task<BaseResponse<ParQDto?>> ObterMeuAsync(Guid alunoId, CancellationToken ct = default)
    {
        var parq = await _db.ParQs
            .Include(p => p.Aluno)
            .FirstOrDefaultAsync(p => p.AlunoId == alunoId, ct);

        return BaseResponse<ParQDto?>.Ok(parq is null ? null : ToDto(parq));
    }

    public async Task<BaseResponse<ParQDto?>> ObterDoAlunoAsync(Guid alunoId, CancellationToken ct = default)
    {
        var parq = await _db.ParQs
            .Include(p => p.Aluno)
            .FirstOrDefaultAsync(p => p.AlunoId == alunoId, ct);

        return BaseResponse<ParQDto?>.Ok(parq is null ? null : ToDto(parq));
    }

    public async Task<BaseResponse<ParQDto>> PreencherAsync(PreencherParQRequest request, Guid alunoId, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(request.NomeCompleto))
            return BaseResponse<ParQDto>.Falha("Nome completo é obrigatório.");
        if (string.IsNullOrWhiteSpace(request.Cpf))
            return BaseResponse<ParQDto>.Falha("CPF é obrigatório.");

        var existente = await _db.ParQs.FirstOrDefaultAsync(p => p.AlunoId == alunoId, ct);

        if (existente is not null)
        {
            // Atualiza se já existe
            existente.R1 = request.R1; existente.R2 = request.R2; existente.R3 = request.R3;
            existente.R4 = request.R4; existente.R5 = request.R5; existente.R6 = request.R6;
            existente.R7 = request.R7; existente.R8 = request.R8; existente.R9 = request.R9;
            existente.R10 = request.R10;
            existente.NomeCompleto = request.NomeCompleto.Trim();
            existente.Cpf = request.Cpf.Trim();
            existente.DataPreenchimento = DateTime.UtcNow;
            existente.AtualizadoEm = DateTime.UtcNow;
            await _db.SaveChangesAsync(ct);
            return BaseResponse<ParQDto>.Ok(ToDto(existente), "PAR-Q atualizado com sucesso.");
        }

        var parq = new ParQ
        {
            AcademiaId = _tenant.AcademiaId,
            AlunoId = alunoId,
            R1 = request.R1, R2 = request.R2, R3 = request.R3,
            R4 = request.R4, R5 = request.R5, R6 = request.R6,
            R7 = request.R7, R8 = request.R8, R9 = request.R9,
            R10 = request.R10,
            NomeCompleto = request.NomeCompleto.Trim(),
            Cpf = request.Cpf.Trim(),
            DataPreenchimento = DateTime.UtcNow,
        };
        _db.ParQs.Add(parq);
        await _db.SaveChangesAsync(ct);
        return BaseResponse<ParQDto>.Ok(ToDto(parq), "PAR-Q preenchido com sucesso.");
    }

    public async Task<BaseResponse<List<ParQDto>>> ListarAsync(CancellationToken ct = default)
    {
        var lista = await _db.ParQs
            .Include(p => p.Aluno)
            .OrderByDescending(p => p.DataPreenchimento)
            .ToListAsync(ct);

        return BaseResponse<List<ParQDto>>.Ok(lista.Select(ToDto).ToList());
    }

    private static ParQDto ToDto(ParQ p) => new()
    {
        Id = p.Id,
        AlunoId = p.AlunoId,
        AlunoNome = p.Aluno?.Nome ?? string.Empty,
        R1 = p.R1, R2 = p.R2, R3 = p.R3, R4 = p.R4, R5 = p.R5,
        R6 = p.R6, R7 = p.R7, R8 = p.R8, R9 = p.R9, R10 = p.R10,
        NomeCompleto = p.NomeCompleto,
        Cpf = p.Cpf,
        DataPreenchimento = p.DataPreenchimento,
        RequerAvaliacaoMedica = p.RequerAvaliacaoMedica,
        CriadoEm = p.CriadoEm,
    };
}
