using AcademiaFight.Domain.Entities.Base;

namespace AcademiaFight.Domain.Entities;

public class Matricula : EntityBase
{
    public Guid AcademiaId { get; set; }
    public Guid AlunoId { get; set; }
    public Guid TurmaId { get; set; }
    public DateOnly DataInicio { get; set; }
    public DateOnly? DataFim { get; set; }
    public bool Ativo { get; set; } = true;

    public Academia Academia { get; set; } = null!;
    public Turma Turma { get; set; } = null!;
    public Usuario Aluno { get; set; } = null!;
}
