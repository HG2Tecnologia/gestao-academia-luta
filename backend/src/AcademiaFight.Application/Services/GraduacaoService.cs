using AcademiaFight.Application.Common;
using AcademiaFight.Application.DTOs.Graduacao;
using AcademiaFight.Application.Interfaces;
using AcademiaFight.Domain.Entities;
using AcademiaFight.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace AcademiaFight.Application.Services;

public class GraduacaoService : IGraduacaoService
{
    private readonly IAppDbContext _db;
    private readonly IXpService _xp;
    private readonly ILogger<GraduacaoService> _logger;

    public GraduacaoService(IAppDbContext db, IXpService xp, ILogger<GraduacaoService> logger)
    {
        _db = db;
        _xp = xp;
        _logger = logger;
    }

    public async Task<BaseResponse<IEnumerable<GraduacaoDto>>> GetHistoricoAlunoAsync(Guid alunoId, CancellationToken ct = default)
    {
        var graduacoes = await _db.Graduacoes
            .Include(g => g.Aluno)
            .Include(g => g.Faixa).ThenInclude(f => f.Modalidade)
            .Include(g => g.Professor)
            .Where(g => g.AlunoId == alunoId)
            .OrderByDescending(g => g.DataExame)
            .ToListAsync(ct);

        return BaseResponse<IEnumerable<GraduacaoDto>>.Ok(graduacoes.Select(MapearDto));
    }

    public async Task<BaseResponse<GraduacaoDto?>> GetFaixaAtualAsync(Guid alunoId, Guid modalidadeId, CancellationToken ct = default)
    {
        var graduacao = await _db.Graduacoes
            .Include(g => g.Aluno)
            .Include(g => g.Faixa).ThenInclude(f => f.Modalidade)
            .Include(g => g.Professor)
            .Where(g => g.AlunoId == alunoId && g.Faixa.ModalidadeId == modalidadeId && g.Aprovado)
            .OrderByDescending(g => g.Faixa.Ordem)
            .FirstOrDefaultAsync(ct);

        return BaseResponse<GraduacaoDto?>.Ok(graduacao is null ? null : MapearDto(graduacao));
    }

    public async Task<BaseResponse<GraduacaoDto>> RegistrarAsync(RegistrarGraduacaoRequest request, CancellationToken ct = default)
    {
        var faixa = await _db.Faixas
            .Include(f => f.Modalidade)
            .FirstOrDefaultAsync(f => f.Id == request.FaixaId, ct);

        if (faixa is null)
            return BaseResponse<GraduacaoDto>.Falha("Faixa não encontrada.");

        var alunoExiste = await _db.Usuarios.AnyAsync(u => u.Id == request.AlunoId && u.Ativo, ct);
        if (!alunoExiste)
            return BaseResponse<GraduacaoDto>.Falha("Aluno não encontrado.");

        if (request.Aprovado)
        {
            // Verificar se aluno já tem faixa igual ou superior
            var faixaAtual = await _db.Graduacoes
                .Include(g => g.Faixa)
                .Where(g => g.AlunoId == request.AlunoId && g.Faixa.ModalidadeId == faixa.ModalidadeId && g.Aprovado)
                .OrderByDescending(g => g.Faixa.Ordem)
                .FirstOrDefaultAsync(ct);

            if (faixaAtual is not null && faixaAtual.Faixa.Ordem >= faixa.Ordem)
                return BaseResponse<GraduacaoDto>.Falha(
                    $"Aluno já possui faixa igual ou superior ({faixaAtual.Faixa.Nome}) nesta modalidade.");
        }

        var graduacao = new Graduacao
        {
            AlunoId = request.AlunoId,
            FaixaId = request.FaixaId,
            DataExame = request.DataExame,
            Aprovado = request.Aprovado,
            ProfessorId = request.ProfessorId,
            Observacoes = request.Observacoes
        };

        await _db.Graduacoes.AddAsync(graduacao, ct);
        await _db.SaveChangesAsync(ct);

        if (request.Aprovado)
            await _xp.AdicionarXpAsync(request.AlunoId, TipoEventoXp.Graduacao, 100, graduacao.Id, ct);

        var completa = await _db.Graduacoes
            .Include(g => g.Aluno)
            .Include(g => g.Faixa).ThenInclude(f => f.Modalidade)
            .Include(g => g.Professor)
            .FirstAsync(g => g.Id == graduacao.Id, ct);

        return BaseResponse<GraduacaoDto>.Ok(MapearDto(completa), "Graduação registrada com sucesso.");
    }

    public async Task<BaseResponse<IEnumerable<AlunoAptoDto>>> GetAlunosAptosFaixaAsync(Guid faixaId, CancellationToken ct = default)
    {
        var faixa = await _db.Faixas.FirstOrDefaultAsync(f => f.Id == faixaId, ct);
        if (faixa is null)
            return BaseResponse<IEnumerable<AlunoAptoDto>>.Falha("Faixa não encontrada.");

        // Alunos matriculados em turmas desta modalidade
        var matriculas = await _db.Matriculas
            .Include(m => m.Aluno)
            .Include(m => m.Turma)
            .Where(m => m.Ativo && m.Turma.ModalidadeId == faixa.ModalidadeId)
            .ToListAsync(ct);

        var alunoIds = matriculas.Select(m => m.AlunoId).Distinct().ToList();

        // Alunos que já têm faixa igual ou superior
        var alunosComFaixaSuperior = await _db.Graduacoes
            .Include(g => g.Faixa)
            .Where(g => alunoIds.Contains(g.AlunoId)
                && g.Faixa.ModalidadeId == faixa.ModalidadeId
                && g.Aprovado && g.Faixa.Ordem >= faixa.Ordem)
            .Select(g => g.AlunoId)
            .Distinct()
            .ToListAsync(ct);

        var candidatos = matriculas
            .Where(m => !alunosComFaixaSuperior.Contains(m.AlunoId))
            .GroupBy(m => m.AlunoId)
            .Select(g => g.OrderBy(m => m.DataInicio).First())
            .ToList();

        var presencas = await _db.Presencas
            .Where(p => alunoIds.Contains(p.AlunoId))
            .GroupBy(p => p.AlunoId)
            .Select(g => new { AlunoId = g.Key, Total = g.Count() })
            .ToListAsync(ct);

        var hoje = DateOnly.FromDateTime(DateTime.Today);
        var aptos = candidatos
            .Select(m =>
            {
                var meses = (hoje.Year - m.DataInicio.Year) * 12 + hoje.Month - m.DataInicio.Month;
                var totalPres = presencas.FirstOrDefault(p => p.AlunoId == m.AlunoId)?.Total ?? 0;
                return new AlunoAptoDto
                {
                    AlunoId = m.AlunoId,
                    NomeAluno = m.Aluno?.Nome ?? string.Empty,
                    EmailAluno = m.Aluno?.Email ?? string.Empty,
                    MesesMatriculado = meses,
                    TotalPresencas = totalPres,
                    MesesNecessarios = faixa.RequisitosMesesMinimos,
                    PresencasNecessarias = faixa.RequisitosPresencasMinimas
                };
            })
            .Where(a => a.MesesMatriculado >= faixa.RequisitosMesesMinimos
                && a.TotalPresencas >= faixa.RequisitosPresencasMinimas)
            .OrderBy(a => a.NomeAluno)
            .ToList();

        return BaseResponse<IEnumerable<AlunoAptoDto>>.Ok(aptos);
    }

    private static GraduacaoDto MapearDto(Graduacao g) => new()
    {
        Id = g.Id,
        AlunoId = g.AlunoId,
        NomeAluno = g.Aluno?.Nome ?? string.Empty,
        FaixaId = g.FaixaId,
        NomeFaixa = g.Faixa?.Nome ?? string.Empty,
        CorFaixa = g.Faixa?.Cor ?? "#FFFFFF",
        ModalidadeId = g.Faixa?.ModalidadeId ?? Guid.Empty,
        NomeModalidade = g.Faixa?.Modalidade?.Nome ?? string.Empty,
        DataExame = g.DataExame,
        Aprovado = g.Aprovado,
        ProfessorId = g.ProfessorId,
        NomeProfessor = g.Professor?.Nome ?? string.Empty,
        Observacoes = g.Observacoes,
        CertificadoUrl = g.CertificadoUrl
    };
}
