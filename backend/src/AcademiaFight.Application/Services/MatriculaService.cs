using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Matricula;
using AcademiaFight.Application.Helpers;
using AcademiaFight.Application.Interfaces;
using AcademiaFight.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace AcademiaFight.Application.Services;

public class MatriculaService : IMatriculaService
{
    private readonly IAppDbContext _db;
    private readonly ILogger<MatriculaService> _logger;

    public MatriculaService(IAppDbContext db, ILogger<MatriculaService> logger)
    {
        _db = db;
        _logger = logger;
    }

    public async Task<BaseResponse<IEnumerable<MatriculaDto>>> GetByAlunoAsync(Guid alunoId, CancellationToken ct = default)
    {
        var matriculas = await _db.Matriculas
            .Include(m => m.Turma).ThenInclude(t => t.Modalidade)
            .Include(m => m.Aluno)
            .Where(m => m.AlunoId == alunoId)
            .OrderByDescending(m => m.DataInicio)
            .ToListAsync(ct);

        return BaseResponse<IEnumerable<MatriculaDto>>.Ok(matriculas.Select(MapearDto));
    }

    public async Task<BaseResponse<IEnumerable<MatriculaDto>>> GetByTurmaAsync(Guid turmaId, CancellationToken ct = default)
    {
        var matriculas = await _db.Matriculas
            .Include(m => m.Aluno)
            .Include(m => m.Turma)
            .Where(m => m.TurmaId == turmaId && m.Ativo)
            .OrderBy(m => m.Aluno.Nome)
            .ToListAsync(ct);

        return BaseResponse<IEnumerable<MatriculaDto>>.Ok(matriculas.Select(MapearDto));
    }

    public async Task<BaseResponse<MatriculaDto>> CreateAsync(CreateMatriculaRequest request, CancellationToken ct = default)
    {
        var turma = await _db.Turmas
            .Include(t => t.Matriculas.Where(m => m.Ativo))
            .FirstOrDefaultAsync(t => t.Id == request.TurmaId, ct);

        if (turma is null)
            return BaseResponse<MatriculaDto>.Falha("Turma não encontrada.");

        var alunoExiste = await _db.Usuarios.AnyAsync(u => u.Id == request.AlunoId && u.Ativo, ct);
        if (!alunoExiste)
            return BaseResponse<MatriculaDto>.Falha("Aluno não encontrado.");

        var jaMatriculado = await _db.Matriculas
            .AnyAsync(m => m.AlunoId == request.AlunoId && m.TurmaId == request.TurmaId && m.Ativo, ct);
        if (jaMatriculado)
            return BaseResponse<MatriculaDto>.Falha("Aluno já está matriculado nesta turma.");

        if (turma.Matriculas.Count >= turma.CapacidadeMaxima)
            return BaseResponse<MatriculaDto>.Falha($"Turma com capacidade máxima atingida ({turma.CapacidadeMaxima} alunos).");

        var matricula = new Matricula
        {
            AlunoId = request.AlunoId,
            TurmaId = request.TurmaId,
            DataInicio = request.DataInicio ?? DateTimeHelper.Hoje(),
            Ativo = true
        };

        await _db.Matriculas.AddAsync(matricula, ct);
        await _db.SaveChangesAsync(ct);

        var completa = await _db.Matriculas
            .Include(m => m.Aluno)
            .Include(m => m.Turma)
            .FirstAsync(m => m.Id == matricula.Id, ct);

        _logger.LogInformation("Aluno {AlunoId} matriculado na turma {TurmaId}", request.AlunoId, request.TurmaId);
        return BaseResponse<MatriculaDto>.Ok(MapearDto(completa), "Matrícula realizada com sucesso.");
    }

    public async Task<BaseResponse> DeleteAsync(Guid matriculaId, CancellationToken ct = default)
    {
        var matricula = await _db.Matriculas.FirstOrDefaultAsync(m => m.Id == matriculaId, ct);
        if (matricula is null)
            return BaseResponse.Falha("Matrícula não encontrada.");

        matricula.Ativo = false;
        matricula.DataFim = DateTimeHelper.Hoje();
        await _db.SaveChangesAsync(ct);

        return BaseResponse.Ok("Matrícula encerrada com sucesso.");
    }

    private static MatriculaDto MapearDto(Matricula m) => new()
    {
        Id = m.Id,
        AlunoId = m.AlunoId,
        NomeAluno = m.Aluno?.Nome ?? string.Empty,
        EmailAluno = m.Aluno?.Email ?? string.Empty,
        TurmaId = m.TurmaId,
        NomeTurma = m.Turma?.Nome ?? string.Empty,
        DataInicio = m.DataInicio,
        DataFim = m.DataFim,
        Ativo = m.Ativo
    };
}
