using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Matricula;
using AcademiaFight.Application.DTOs.Turma;
using AcademiaFight.Application.Helpers;
using AcademiaFight.Application.Interfaces;
using AcademiaFight.Domain.Entities;
using AcademiaFight.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace AcademiaFight.Application.Services;

public class TurmaService : ITurmaService
{
    private static readonly string[] DiasLabels =
        ["Domingo", "Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado"];

    private readonly IAppDbContext _db;
    private readonly ILogger<TurmaService> _logger;

    public TurmaService(IAppDbContext db, ILogger<TurmaService> logger)
    {
        _db = db;
        _logger = logger;
    }

    public async Task<BaseResponse<IEnumerable<TurmaDto>>> ListarAsync(CancellationToken ct = default)
    {
        var turmas = await _db.Turmas
            .Include(t => t.Modalidade)
            .Include(t => t.Professor)
            .OrderBy(t => t.Nome)
            .Select(t => new TurmaDto
            {
                Id = t.Id,
                Nome = t.Nome,
                ModalidadeId = t.ModalidadeId,
                ModalidadeNome = t.Modalidade.Nome,
                ProfessorId = t.ProfessorId,
                ProfessorNome = t.Professor.Nome,
                Nivel = t.Nivel,
                CapacidadeMaxima = t.CapacidadeMaxima,
                Ativo = t.Ativo
            })
            .ToListAsync(ct);

        return BaseResponse<IEnumerable<TurmaDto>>.Ok(turmas);
    }

    public async Task<BaseResponse<TurmaDto>> ObterPorIdAsync(Guid id, CancellationToken ct = default)
    {
        var turma = await _db.Turmas
            .Include(t => t.Modalidade)
            .Include(t => t.Professor)
            .FirstOrDefaultAsync(t => t.Id == id, ct);

        if (turma is null)
            return BaseResponse<TurmaDto>.Falha("Turma não encontrada.");

        return BaseResponse<TurmaDto>.Ok(MapearDto(turma));
    }

    public async Task<BaseResponse<TurmaDetalheDto>> GetDetalheAsync(Guid turmaId, CancellationToken ct = default)
    {
        var turma = await _db.Turmas
            .Include(t => t.Modalidade)
            .Include(t => t.Professor)
            .Include(t => t.Horarios)
            .Include(t => t.Matriculas.Where(m => m.Ativo)).ThenInclude(m => m.Aluno)
            .FirstOrDefaultAsync(t => t.Id == turmaId, ct);

        if (turma is null)
            return BaseResponse<TurmaDetalheDto>.Falha("Turma não encontrada.");

        var detalhe = new TurmaDetalheDto
        {
            Id = turma.Id,
            Nome = turma.Nome,
            ModalidadeId = turma.ModalidadeId,
            ModalidadeNome = turma.Modalidade?.Nome ?? string.Empty,
            ProfessorId = turma.ProfessorId,
            ProfessorNome = turma.Professor?.Nome ?? string.Empty,
            Nivel = turma.Nivel,
            CapacidadeMaxima = turma.CapacidadeMaxima,
            Ativo = turma.Ativo,
            TotalAlunos = turma.Matriculas.Count(m => m.Ativo),
            Alunos = turma.Matriculas.Where(m => m.Ativo).Select(m => new MatriculaDto
            {
                Id = m.Id,
                AlunoId = m.AlunoId,
                NomeAluno = m.Aluno?.Nome ?? string.Empty,
                EmailAluno = m.Aluno?.Email ?? string.Empty,
                TurmaId = m.TurmaId,
                NomeTurma = turma.Nome,
                DataInicio = m.DataInicio,
                DataFim = m.DataFim,
                Ativo = m.Ativo
            }),
            Horarios = turma.Horarios.Select(h => new HorarioResumoDto
            {
                Id = h.Id,
                DiaSemana = (int)h.DiaSemana,
                DiaSemanaLabel = DiasLabels[(int)h.DiaSemana],
                HoraInicio = h.HoraInicio,
                HoraFim = h.HoraFim,
                Sala = h.Sala
            })
        };

        return BaseResponse<TurmaDetalheDto>.Ok(detalhe);
    }

    public async Task<BaseResponse<TurmaDto>> CriarAsync(CreateTurmaRequest request, CancellationToken ct = default)
    {
        var modalidadeExiste = await _db.Modalidades
            .AnyAsync(m => m.Id == request.ModalidadeId && m.Ativo, ct);

        if (!modalidadeExiste)
            return BaseResponse<TurmaDto>.Falha("Modalidade não encontrada ou inativa.");

        var professorExiste = await _db.Usuarios
            .AnyAsync(u => u.Id == request.ProfessorId && u.Ativo, ct);

        if (!professorExiste)
            return BaseResponse<TurmaDto>.Falha("Professor não encontrado.");

        var turma = new Turma
        {
            ModalidadeId = request.ModalidadeId,
            ProfessorId = request.ProfessorId,
            Nome = request.Nome,
            Nivel = request.Nivel,
            CapacidadeMaxima = request.CapacidadeMaxima,
            Ativo = true
        };

        await _db.Turmas.AddAsync(turma, ct);
        await _db.SaveChangesAsync(ct);

        var turmaCompleta = await _db.Turmas
            .Include(t => t.Modalidade)
            .Include(t => t.Professor)
            .FirstAsync(t => t.Id == turma.Id, ct);

        _logger.LogInformation("Turma criada: {Nome}", turma.Nome);
        return BaseResponse<TurmaDto>.Ok(MapearDto(turmaCompleta), "Turma criada com sucesso.");
    }

    public async Task<BaseResponse<TurmaDto>> AtualizarAsync(Guid id, UpdateTurmaRequest request, CancellationToken ct = default)
    {
        var turma = await _db.Turmas
            .Include(t => t.Modalidade)
            .Include(t => t.Professor)
            .FirstOrDefaultAsync(t => t.Id == id, ct);

        if (turma is null)
            return BaseResponse<TurmaDto>.Falha("Turma não encontrada.");

        turma.ModalidadeId = request.ModalidadeId;
        turma.ProfessorId = request.ProfessorId;
        turma.Nome = request.Nome;
        turma.Nivel = request.Nivel;
        turma.CapacidadeMaxima = request.CapacidadeMaxima;
        turma.Ativo = request.Ativo;

        await _db.SaveChangesAsync(ct);

        await _db.Turmas.Entry(turma).Reference(t => t.Modalidade).LoadAsync(ct);
        await _db.Turmas.Entry(turma).Reference(t => t.Professor).LoadAsync(ct);

        _logger.LogInformation("Turma {Id} atualizada", id);
        return BaseResponse<TurmaDto>.Ok(MapearDto(turma), "Turma atualizada com sucesso.");
    }

    public async Task<BaseResponse> RemoverAsync(Guid id, CancellationToken ct = default)
    {
        var turma = await _db.Turmas.FirstOrDefaultAsync(t => t.Id == id, ct);
        if (turma is null)
            return BaseResponse.Falha("Turma não encontrada.");

        turma.Ativo = false;
        await _db.SaveChangesAsync(ct);

        _logger.LogInformation("Turma {Id} arquivada", id);
        return BaseResponse.Ok("Turma arquivada com sucesso.");
    }

    public async Task<BaseResponse<IEnumerable<MatriculaDto>>> GetAlunosDaTurmaAsync(Guid turmaId, CancellationToken ct = default)
    {
        var matriculas = await _db.Matriculas
            .Include(m => m.Aluno)
            .Include(m => m.Turma)
            .Where(m => m.TurmaId == turmaId && m.Ativo)
            .OrderBy(m => m.Aluno.Nome)
            .ToListAsync(ct);

        return BaseResponse<IEnumerable<MatriculaDto>>.Ok(matriculas.Select(MapearMatriculaDto));
    }

    public async Task<BaseResponse<MatriculaDto>> MatricularAlunoAsync(Guid turmaId, Guid alunoId, CancellationToken ct = default)
    {
        var turma = await _db.Turmas
            .Include(t => t.Matriculas.Where(m => m.Ativo))
            .FirstOrDefaultAsync(t => t.Id == turmaId, ct);

        if (turma is null)
            return BaseResponse<MatriculaDto>.Falha("Turma não encontrada.");

        var alunoExiste = await _db.Usuarios.AnyAsync(u => u.Id == alunoId && u.Ativo, ct);
        if (!alunoExiste)
            return BaseResponse<MatriculaDto>.Falha("Aluno não encontrado.");

        var jaMatriculado = turma.Matriculas.Any(m => m.AlunoId == alunoId);
        if (jaMatriculado)
            return BaseResponse<MatriculaDto>.Falha("Aluno já está matriculado nesta turma.");

        if (turma.Matriculas.Count >= turma.CapacidadeMaxima)
            return BaseResponse<MatriculaDto>.Falha($"Capacidade máxima da turma atingida ({turma.CapacidadeMaxima} alunos).");

        var matricula = new Matricula
        {
            AlunoId = alunoId,
            TurmaId = turmaId,
            DataInicio = DateTimeHelper.Hoje(),
            Ativo = true
        };

        await _db.Matriculas.AddAsync(matricula, ct);
        await _db.SaveChangesAsync(ct);

        var completa = await _db.Matriculas
            .Include(m => m.Aluno)
            .Include(m => m.Turma)
            .FirstAsync(m => m.Id == matricula.Id, ct);

        return BaseResponse<MatriculaDto>.Ok(MapearMatriculaDto(completa), "Aluno matriculado com sucesso.");
    }

    public async Task<BaseResponse> DesmatricularAlunoAsync(Guid turmaId, Guid alunoId, CancellationToken ct = default)
    {
        var matricula = await _db.Matriculas
            .FirstOrDefaultAsync(m => m.TurmaId == turmaId && m.AlunoId == alunoId && m.Ativo, ct);

        if (matricula is null)
            return BaseResponse.Falha("Matrícula ativa não encontrada para este aluno nesta turma.");

        matricula.Ativo = false;
        matricula.DataFim = DateTimeHelper.Hoje();
        await _db.SaveChangesAsync(ct);

        return BaseResponse.Ok("Aluno desmatriculado com sucesso.");
    }

    private static TurmaDto MapearDto(Turma t) => new()
    {
        Id = t.Id,
        Nome = t.Nome,
        ModalidadeId = t.ModalidadeId,
        ModalidadeNome = t.Modalidade?.Nome ?? string.Empty,
        ProfessorId = t.ProfessorId,
        ProfessorNome = t.Professor?.Nome ?? string.Empty,
        Nivel = t.Nivel,
        CapacidadeMaxima = t.CapacidadeMaxima,
        Ativo = t.Ativo
    };

    private static MatriculaDto MapearMatriculaDto(Matricula m) => new()
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
